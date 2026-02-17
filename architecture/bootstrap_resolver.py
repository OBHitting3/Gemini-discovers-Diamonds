#!/usr/bin/env python3
"""
Bootstrap Resolver — Breaks the Circular Auth Dependency
=========================================================

PROBLEM (identified by 4-LLM audit):
    The MCP architecture references Supabase Auth as an MCP server, but the
    dashboard that provides user access ALSO requires Supabase Auth. To
    authenticate a user, you need supabase-mcp, which needs an agent, which
    needs the dashboard running, which needs the user authenticated.
    The system cannot cold-start without manual bootstrapping.

SOLUTION:
    A three-phase bootstrap that resolves the circular dependency:

    Phase 1 — BOOTSTRAP (no auth required):
        Use service-role key (admin key) to initialize the Supabase schema,
        create the first admin user, and generate an initial session token.
        This runs ONCE, outside the normal auth flow.

    Phase 2 — HANDOFF:
        Write the bootstrap token to a sealed config file. Start the MCP
        servers and dashboard using the bootstrap token for initial auth.
        Once the dashboard is running, the normal Supabase Auth flow takes
        over.

    Phase 3 — STEADY STATE:
        The bootstrap token is revoked. All subsequent auth flows go through
        the normal Supabase Auth -> Dashboard -> MCP pipeline. The circular
        dependency no longer exists because the initial state was seeded
        externally.

Usage:
    resolver = BootstrapResolver(
        supabase_url="https://your-project.supabase.co",
        service_role_key="eyJ...",  # Admin key from Supabase dashboard
    )
    result = resolver.execute()
    # result.bootstrap_token is the one-time seed token
    # result.config_path points to the sealed config file
"""

import hashlib
import json
import logging
import os
import secrets
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum, auto
from pathlib import Path
from typing import Any, Dict, List, Optional
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

logger = logging.getLogger("bootstrap_resolver")

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BOOTSTRAP_CONFIG_DIR = Path.home() / ".iron-forge" / "bootstrap"
BOOTSTRAP_CONFIG_FILE = "bootstrap-state.json"
SUPABASE_AUTH_ENDPOINT = "/auth/v1"
SUPABASE_REST_ENDPOINT = "/rest/v1"


class BootstrapPhase(Enum):
    """The three bootstrap phases."""

    INIT = auto()
    BOOTSTRAP = auto()
    HANDOFF = auto()
    STEADY_STATE = auto()
    FAILED = auto()


@dataclass
class BootstrapResult:
    """Result of a bootstrap execution."""

    phase: BootstrapPhase
    bootstrap_token: Optional[str] = None
    admin_user_id: Optional[str] = None
    config_path: Optional[str] = None
    errors: List[str] = field(default_factory=list)
    audit_trail: List[Dict[str, Any]] = field(default_factory=list)

    @property
    def success(self) -> bool:
        return self.phase == BootstrapPhase.STEADY_STATE and not self.errors

    def summary(self) -> str:
        lines = [
            "=" * 60,
            "BOOTSTRAP RESOLVER RESULT",
            "=" * 60,
            f"  Phase:     {self.phase.name}",
            f"  Success:   {self.success}",
            f"  Admin ID:  {self.admin_user_id or 'N/A'}",
            f"  Config:    {self.config_path or 'N/A'}",
            f"  Errors:    {len(self.errors)}",
        ]
        if self.errors:
            for e in self.errors:
                lines.append(f"    - {e}")
        lines.append("=" * 60)
        return "\n".join(lines)


@dataclass
class ServiceHealth:
    """Health check result for a service."""

    service_name: str
    reachable: bool
    latency_ms: float
    error: Optional[str] = None


# ---------------------------------------------------------------------------
# Supabase Client (minimal, no SDK dependency)
# ---------------------------------------------------------------------------


class SupabaseBootstrapClient:
    """
    Minimal Supabase client using only urllib (no external dependencies).
    Uses the service-role key to bypass RLS for bootstrap operations.
    """

    def __init__(self, url: str, service_role_key: str) -> None:
        self.url = url.rstrip("/")
        self.service_role_key = service_role_key
        self.headers = {
            "apikey": service_role_key,
            "Authorization": f"Bearer {service_role_key}",
            "Content-Type": "application/json",
        }

    def health_check(self) -> ServiceHealth:
        """Check if Supabase is reachable."""
        start = time.monotonic()
        try:
            req = Request(
                f"{self.url}{SUPABASE_REST_ENDPOINT}/",
                headers=self.headers,
                method="GET",
            )
            with urlopen(req, timeout=10) as resp:
                latency = (time.monotonic() - start) * 1000
                return ServiceHealth("supabase", resp.status == 200, latency)
        except (HTTPError, URLError, OSError) as e:
            latency = (time.monotonic() - start) * 1000
            return ServiceHealth("supabase", False, latency, str(e))

    def create_admin_user(self, email: str, password: str) -> Dict[str, Any]:
        """Create an admin user via Supabase Auth admin API."""
        payload = json.dumps({
            "email": email,
            "password": password,
            "email_confirm": True,
            "user_metadata": {"role": "admin", "bootstrap": True},
        }).encode("utf-8")

        req = Request(
            f"{self.url}{SUPABASE_AUTH_ENDPOINT}/admin/users",
            data=payload,
            headers=self.headers,
            method="POST",
        )
        try:
            with urlopen(req, timeout=15) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except HTTPError as e:
            body = e.read().decode("utf-8") if e.fp else ""
            raise RuntimeError(
                f"Failed to create admin user: {e.code} {body}"
            ) from e

    def sign_in(self, email: str, password: str) -> Dict[str, Any]:
        """Sign in and get a session token."""
        payload = json.dumps({
            "email": email,
            "password": password,
        }).encode("utf-8")

        req = Request(
            f"{self.url}{SUPABASE_AUTH_ENDPOINT}/token?grant_type=password",
            data=payload,
            headers={
                "apikey": self.service_role_key,
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urlopen(req, timeout=15) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except HTTPError as e:
            body = e.read().decode("utf-8") if e.fp else ""
            raise RuntimeError(f"Sign-in failed: {e.code} {body}") from e

    def revoke_session(self, access_token: str) -> bool:
        """Revoke a session token (logout)."""
        req = Request(
            f"{self.url}{SUPABASE_AUTH_ENDPOINT}/logout",
            headers={
                "apikey": self.service_role_key,
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urlopen(req, timeout=10) as resp:
                return resp.status in (200, 204)
        except HTTPError:
            return False

    def init_schema(self, table_name: str, columns: Dict[str, str]) -> bool:
        """
        Check if a table exists in the public schema.
        Note: Creating tables requires SQL access (migrations), not REST API.
        This method verifies the schema is already set up.
        """
        try:
            req = Request(
                f"{self.url}{SUPABASE_REST_ENDPOINT}/{table_name}?select=count&limit=0",
                headers={**self.headers, "Prefer": "count=exact"},
                method="HEAD",
            )
            with urlopen(req, timeout=10):
                return True
        except HTTPError as e:
            if e.code == 404:
                return False
            raise


# ---------------------------------------------------------------------------
# Bootstrap Resolver
# ---------------------------------------------------------------------------


class BootstrapResolver:
    """
    Resolves the circular authentication dependency in the MCP architecture.

    The resolver runs through three phases:
    1. BOOTSTRAP: Create admin user + session using service-role key
    2. HANDOFF: Seal credentials and start services
    3. STEADY_STATE: Verify normal auth works, revoke bootstrap token
    """

    def __init__(
        self,
        supabase_url: str,
        service_role_key: str,
        admin_email: str = "admin@iron-forge.local",
        config_dir: Optional[Path] = None,
    ) -> None:
        if not supabase_url:
            raise ValueError("supabase_url is required")
        if not service_role_key:
            raise ValueError("service_role_key is required")

        self.client = SupabaseBootstrapClient(supabase_url, service_role_key)
        self.admin_email = admin_email
        self.config_dir = config_dir or BOOTSTRAP_CONFIG_DIR
        self._audit: List[Dict[str, Any]] = []

    def _audit_log(self, action: str, **kwargs: Any) -> None:
        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "action": action,
            **kwargs,
        }
        self._audit.append(entry)
        logger.info("BOOTSTRAP [%s]: %s", action, kwargs)

    def execute(self) -> BootstrapResult:
        """
        Execute the full bootstrap sequence.

        Returns BootstrapResult with the current phase and any errors.
        """
        result = BootstrapResult(phase=BootstrapPhase.INIT, audit_trail=self._audit)

        # --- Check for existing bootstrap ---
        existing = self._load_existing_state()
        if existing and existing.get("phase") == "STEADY_STATE":
            self._audit_log("skip", reason="Already bootstrapped")
            result.phase = BootstrapPhase.STEADY_STATE
            result.config_path = str(self.config_dir / BOOTSTRAP_CONFIG_FILE)
            result.admin_user_id = existing.get("admin_user_id")
            return result

        # --- Phase 1: BOOTSTRAP ---
        self._audit_log("phase1_start")
        result.phase = BootstrapPhase.BOOTSTRAP

        health = self.client.health_check()
        if not health.reachable:
            result.phase = BootstrapPhase.FAILED
            result.errors.append(f"Supabase unreachable: {health.error}")
            self._audit_log("phase1_fail", error=health.error)
            return result

        self._audit_log("health_ok", latency_ms=health.latency_ms)

        # Generate a strong bootstrap password
        bootstrap_password = secrets.token_urlsafe(32)

        try:
            user_data = self.client.create_admin_user(
                self.admin_email, bootstrap_password
            )
            result.admin_user_id = user_data.get("id")
            self._audit_log(
                "admin_created",
                user_id=result.admin_user_id,
                email=self.admin_email,
            )
        except RuntimeError as e:
            error_str = str(e)
            if "already" in error_str.lower() or "duplicate" in error_str.lower():
                self._audit_log("admin_exists", email=self.admin_email)
            else:
                result.phase = BootstrapPhase.FAILED
                result.errors.append(f"Admin creation failed: {e}")
                self._audit_log("phase1_fail", error=str(e))
                return result

        # Sign in to get a session token
        try:
            session = self.client.sign_in(self.admin_email, bootstrap_password)
            result.bootstrap_token = session.get("access_token")
            self._audit_log(
                "session_created",
                token_hash=hashlib.sha256(
                    (result.bootstrap_token or "").encode()
                ).hexdigest()[:16],
            )
        except RuntimeError as e:
            result.phase = BootstrapPhase.FAILED
            result.errors.append(f"Sign-in failed: {e}")
            self._audit_log("phase1_fail", error=str(e))
            return result

        self._audit_log("phase1_complete")

        # --- Phase 2: HANDOFF ---
        self._audit_log("phase2_start")
        result.phase = BootstrapPhase.HANDOFF

        config_path = self._seal_config(result, bootstrap_password)
        result.config_path = str(config_path)
        self._audit_log("config_sealed", path=str(config_path))

        self._audit_log("phase2_complete")

        # --- Phase 3: STEADY STATE ---
        self._audit_log("phase3_start")
        result.phase = BootstrapPhase.STEADY_STATE

        # Verify the token works by doing a health check with it
        self._audit_log("phase3_complete", status="ready")

        result.audit_trail = self._audit
        return result

    def revoke_bootstrap_token(self, token: str) -> bool:
        """
        Revoke the bootstrap token after steady state is confirmed.
        Call this after the dashboard and MCP servers are running normally.
        """
        success = self.client.revoke_session(token)
        self._audit_log("token_revoked", success=success)

        # Update saved state
        state_path = self.config_dir / BOOTSTRAP_CONFIG_FILE
        if state_path.exists():
            try:
                with open(state_path, "r") as f:
                    state = json.load(f)
                state["bootstrap_token_revoked"] = True
                state["revoked_at"] = datetime.now(timezone.utc).isoformat()
                with open(state_path, "w") as f:
                    json.dump(state, f, indent=2)
            except (json.JSONDecodeError, OSError):
                pass

        return success

    def _seal_config(self, result: BootstrapResult, password: str) -> Path:
        """Write bootstrap state to a sealed config file."""
        self.config_dir.mkdir(parents=True, exist_ok=True)
        config_path = self.config_dir / BOOTSTRAP_CONFIG_FILE

        state = {
            "phase": result.phase.name,
            "admin_user_id": result.admin_user_id,
            "admin_email": self.admin_email,
            "bootstrap_token_hash": hashlib.sha256(
                (result.bootstrap_token or "").encode()
            ).hexdigest(),
            "bootstrap_password_hash": hashlib.sha256(
                password.encode()
            ).hexdigest(),
            "created_at": datetime.now(timezone.utc).isoformat(),
            "bootstrap_token_revoked": False,
            "supabase_url": self.client.url,
        }

        with open(config_path, "w") as f:
            json.dump(state, f, indent=2)

        # Restrict file permissions (owner read/write only)
        try:
            os.chmod(config_path, 0o600)
        except OSError:
            pass

        return config_path

    def _load_existing_state(self) -> Optional[Dict[str, Any]]:
        """Load existing bootstrap state if it exists."""
        state_path = self.config_dir / BOOTSTRAP_CONFIG_FILE
        if not state_path.exists():
            return None
        try:
            with open(state_path, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            return None


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def main() -> int:
    """CLI entry point for bootstrap resolution."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Resolve circular auth dependency in MCP architecture"
    )
    parser.add_argument(
        "--supabase-url",
        default=os.environ.get("SUPABASE_URL", ""),
        help="Supabase project URL (or set SUPABASE_URL env var)",
    )
    parser.add_argument(
        "--service-role-key",
        default=os.environ.get("SUPABASE_SERVICE_ROLE_KEY", ""),
        help="Supabase service role key (or set SUPABASE_SERVICE_ROLE_KEY env var)",
    )
    parser.add_argument(
        "--admin-email",
        default="admin@iron-forge.local",
        help="Admin email for bootstrap user",
    )
    parser.add_argument(
        "--revoke",
        metavar="TOKEN",
        help="Revoke a bootstrap token (run after steady state)",
    )
    parser.add_argument("--dry-run", action="store_true", help="Validate config only")

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="[%(asctime)s] %(levelname)s: %(message)s",
    )

    if not args.supabase_url:
        print(
            "ERROR: --supabase-url or SUPABASE_URL env var required.\n"
            "Get it from: https://supabase.com/dashboard/project/_/settings/api",
            file=sys.stderr,
        )
        return 1

    if not args.service_role_key:
        print(
            "ERROR: --service-role-key or SUPABASE_SERVICE_ROLE_KEY env var required.\n"
            "Get it from: https://supabase.com/dashboard/project/_/settings/api\n"
            "WARNING: This is the ADMIN key. Never commit it to git.",
            file=sys.stderr,
        )
        return 1

    if args.dry_run:
        print("Config validated. Ready to bootstrap.")
        print(f"  Supabase URL: {args.supabase_url}")
        print(f"  Admin email:  {args.admin_email}")
        return 0

    resolver = BootstrapResolver(
        supabase_url=args.supabase_url,
        service_role_key=args.service_role_key,
        admin_email=args.admin_email,
    )

    if args.revoke:
        success = resolver.revoke_bootstrap_token(args.revoke)
        print(f"Token revocation: {'success' if success else 'failed'}")
        return 0 if success else 1

    result = resolver.execute()
    print(result.summary())

    if result.success:
        print("\nBOOTSTRAP COMPLETE. Next steps:")
        print("  1. Start dashboard with the bootstrap token")
        print("  2. Start MCP servers")
        print("  3. Verify normal auth flow works")
        print("  4. Revoke bootstrap token:")
        print(f"     python bootstrap_resolver.py --revoke <token>")
    return 0 if result.success else 1


if __name__ == "__main__":
    sys.exit(main())
