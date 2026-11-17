"""Refuses to join activity files that are not parts of one match.

The watch writes no match identifier, so the files are compared by what they do carry: the match setup, when
each one was recorded, and the point log, which a resumed match goes on writing where the file before stopped.
"""

from __future__ import annotations

from itertools import pairwise
from typing import TYPE_CHECKING

from tennis_export.errors import ExportError
from tennis_export.layout import MATCH_SETUP_FIELD, SETUP_KIND, SETUP_SURFACE, decode_slots
from tennis_export.match_reader import point_log_values
from tennis_export.point_log import collect_slots
from tennis_export.source_files import end_of, start_of

if TYPE_CHECKING:
    from collections.abc import Mapping, Sequence

    from tennis_export.layout import Slot
    from tennis_export.source_files import SourceFile


def require_same_match(sources: Sequence[SourceFile]) -> None:
    """The sources are in recording order; one file alone has nothing to be compared with."""
    if len(sources) > 1:
        for source in sources:
            setup_of(source)
        for earlier, later in pairwise(sources):
            require_same_setup(earlier, later)
            require_one_after_the_other(earlier, later)
        require_one_point_log(sources)


def setup_of(source: SourceFile) -> int:
    setup: int | None = source.activity.session.developer.get(MATCH_SETUP_FIELD)
    if setup is None:
        raise ExportError(f"{source.name} carries no match of the Tennis app, so it cannot be joined with other files")
    return setup


def require_same_setup(earlier: SourceFile, later: SourceFile) -> None:
    if rules_of(setup_of(earlier)) != rules_of(setup_of(later)):
        raise ExportError(f"{earlier.name} and {later.name} have different match settings, so they are not one match")


def rules_of(setup: int) -> int:
    """The setup without the tags: they are chosen on save, so a part saved when the app closed has none."""
    return SETUP_KIND.clear(SETUP_SURFACE.clear(setup))


def require_one_after_the_other(earlier: SourceFile, later: SourceFile) -> None:
    if not start_of(earlier) < start_of(later) or start_of(later) < end_of(earlier):
        raise ExportError(f"{later.name} starts before {earlier.name} ends, so they are not parts of one match")


def require_one_point_log(sources: Sequence[SourceFile]) -> None:
    earlier_values: list[Sequence[int]] = []
    for source in sources:
        values = point_log_values(source.activity)
        if not continues(collect_slots(earlier_values)[0], values):
            raise ExportError(
                f"the point log of {source.name} does not continue the one of the files before it, "
                "so they are not one match"
            )
        earlier_values += values


def continues(known: Mapping[int, Slot], values: Sequence[Sequence[int]]) -> bool:
    """The first record of a resumed file repeats at least one entry the files before it already had.

    With no entry before it, or no point log in the file, there is nothing that could disagree.
    """
    if not known or not values:
        return True
    return any(known.get(slot.sequence) == slot for slot in decode_slots(values[0]))
