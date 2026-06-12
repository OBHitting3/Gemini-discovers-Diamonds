"""Base emitter interface for content-shield events."""

from __future__ import annotations

import abc

from content_shield.schema.event import ShieldEvent


class BaseEmitter(abc.ABC):
    """Abstract base class for all shield-event emitters.

    Subclasses must implement :meth:`emit`.  The optional :meth:`setup` and
    :meth:`teardown` lifecycle hooks can be overridden to acquire or release
    resources (network connections, file handles, etc.).
    """

    # ------------------------------------------------------------------
    # Lifecycle hooks
    # ------------------------------------------------------------------

    async def setup(self) -> None:
        """Called once before the emitter starts receiving events.

        Override to perform any asynchronous initialisation such as opening
        connections or authenticating with external services.
        """

    async def teardown(self) -> None:
        """Called once when the emitter is no longer needed.

        Override to release resources acquired in :meth:`setup`.
        """

    # ------------------------------------------------------------------
    # Core interface
    # ------------------------------------------------------------------

    @abc.abstractmethod
    async def emit(self, event: ShieldEvent) -> None:
        """Emit a single shield event.

        Parameters
        ----------
        event:
            The shield event to emit.
        """

    # ------------------------------------------------------------------
    # Context-manager support
    # ------------------------------------------------------------------

    async def __aenter__(self) -> BaseEmitter:
        await self.setup()
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb) -> None:  # noqa: ANN001
        await self.teardown()
