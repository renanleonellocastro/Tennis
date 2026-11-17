"""Rebuilds the point log from the overlapping copies the records carry."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from tennis_export.layout import decode_slots, newest_sequence

if TYPE_CHECKING:
    from collections.abc import Iterable, Sequence

    from tennis_export.layout import Slot

FIRST_SEQUENCE = 1


@dataclass(frozen=True)
class PointLog:
    """The entries that can be trusted (an unbroken run from the first one) and what was lost."""

    slots: tuple[Slot, ...]
    expected: int
    recovered: int
    missing: tuple[int, ...]


def rebuild_point_log(values: Iterable[Sequence[int]], log_size: int | None) -> PointLog:
    """Each value is one record's copy of the newest entries; the last copy of a sequence number wins."""
    latest, newest = collect_slots(values)
    expected = newest if log_size is None else log_size
    wanted = range(FIRST_SEQUENCE, expected + 1)
    missing = tuple(sequence for sequence in wanted if sequence not in latest)
    first_gap = missing[0] if missing else expected + 1
    slots = tuple(latest[sequence] for sequence in range(FIRST_SEQUENCE, first_gap))
    return PointLog(slots, expected, len(wanted) - len(missing), missing)


def collect_slots(values: Iterable[Sequence[int]]) -> tuple[dict[int, Slot], int]:
    """The last slot seen for each sequence number, and the newest sequence number of the last record."""
    latest: dict[int, Slot] = {}
    newest = 0
    for words in values:
        newest = newest_sequence(words)
        forget_undone(latest, newest)
        latest.update({slot.sequence: slot for slot in decode_slots(words)})
    return latest, newest


def forget_undone(latest: dict[int, Slot], newest: int) -> None:
    """A record whose newest entry is older than entries seen before means those were undone."""
    for sequence in [known for known in latest if known > newest]:
        del latest[sequence]
