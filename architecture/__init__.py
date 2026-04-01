"""
Architecture Fixes for Faceless Shorts MCP System
===================================================

Addresses the 4 critical issues identified by multi-LLM audit:

1. bootstrap_resolver  - Breaks the circular auth dependency (cold-start)
2. bridge_router       - Working config translation across 4 agent formats
3. backbone_trigger    - Replaces the Make.com ghost with real webhooks
4. cursorrules_enforcer - Runtime enforcement, not honor-system directives
"""
