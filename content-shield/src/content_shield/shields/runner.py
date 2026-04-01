"""Shield runner that orchestrates multiple shields against content."""

from __future__ import annotations

import asyncio
from typing import Sequence

from content_shield.schema import Content, ValidationResult, ValidationSummary
from content_shield.shields.base import BaseShield


class ShieldRunner:
    """Runs a collection of shields against content and aggregates results.

    Args:
        shields: An ordered sequence of :class:`BaseShield` instances.
        parallel: If ``True`` (the default), shields are executed
            concurrently using :func:`asyncio.gather`.  Set to
            ``False`` to run shields sequentially.
    """

    def __init__(
        self,
        shields: Sequence[BaseShield],
        parallel: bool = True,
    ) -> None:
        self._shields = list(shields)
        self._parallel = parallel

    # ------------------------------------------------------------------ #
    # Public API                                                          #
    # ------------------------------------------------------------------ #

    async def run(self, content: Content) -> ValidationSummary:
        """Run every shield against *content* and return a summary.

        Args:
            content: A single content item.

        Returns:
            A :class:`ValidationSummary` aggregating all individual
            :class:`ValidationResult` objects.
        """
        if self._parallel:
            results = await asyncio.gather(
                *(shield.check(content) for shield in self._shields)
            )
        else:
            results: list[ValidationResult] = []
            for shield in self._shields:
                results.append(await shield.check(content))

        return ValidationSummary(results=list(results))

    async def run_batch(
        self, contents: Sequence[Content]
    ) -> list[ValidationSummary]:
        """Run every shield against each item in *contents*.

        Args:
            contents: A sequence of content items.

        Returns:
            A list of :class:`ValidationSummary` objects, one per
            content item, in the same order as *contents*.
        """
        return [await self.run(content) for content in contents]
