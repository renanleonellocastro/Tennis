"""Says which laps were recorded while each closed set was played, from when the point log says the set ended.

The lap count cannot tell: a set that was undone and played again leaves two laps, and a set that was open when
the app closed has one lap in each activity file.
"""

from __future__ import annotations

from bisect import bisect_left
from datetime import timedelta
from typing import TYPE_CHECKING

from tennis_export.entry_times import entry_times
from tennis_export.match_state import Outcome

if TYPE_CHECKING:
    from collections.abc import Sequence
    from datetime import datetime

    from tennis_export.fit_reader import Message
    from tennis_export.replay import Row

type SetLaps = tuple[Message, ...]

LAP_START = "start_time"
LAP_TIMER = "total_timer_time"


def laps_by_set(rows: Sequence[Row], records: Sequence[Message], laps: Sequence[Message]) -> list[SetLaps] | None:
    """The laps of each closed set, in set order; None when a set end or a lap cannot be placed in time."""
    timed = timed_laps(laps)
    set_ends = all_known(set_end_times(rows, entry_times(records)))
    lap_moments = all_known([lap_moment(lap) for lap in timed])
    if set_ends is None or lap_moments is None:
        return None
    return grouped(timed, lap_moments, set_ends)


def timed_laps(laps: Sequence[Message]) -> list[Message]:
    """Files from the simulator repeat laps that lasted no time at all; nothing was played in those."""
    return [lap for lap in laps if lap.native.get(LAP_TIMER) != 0]


def all_known[Value](values: Sequence[Value | None]) -> list[Value] | None:
    known = [value for value in values if value is not None]
    return known if len(known) == len(values) else None


def set_end_times(rows: Sequence[Row], times: dict[int, datetime | None]) -> list[datetime | None]:
    return [times.get(row.slot.sequence) for row in rows if Outcome.SET in row.outcome]


def lap_moment(lap: Message) -> datetime | None:
    """The middle of the time the lap spent recording.

    The start and the timer time are used, not the end: the last lap ends when the activity is saved, which
    can be long after the last point.
    """
    start, timer_seconds = lap.native.get(LAP_START), lap.native.get(LAP_TIMER)
    if start is None or timer_seconds is None:
        return None
    middle: datetime = start + timedelta(seconds=timer_seconds / 2)
    return middle


def grouped(laps: Sequence[Message], moments: Sequence[datetime], set_ends: Sequence[datetime]) -> list[SetLaps]:
    """A lap belongs to the first set that ends at or after its moment; laps after the last end are left out."""
    groups: list[list[Message]] = [[] for _ in set_ends]
    for lap, moment in zip(laps, moments, strict=True):
        index = bisect_left(set_ends, moment)
        if index < len(set_ends):
            groups[index].append(lap)
    return [tuple(group) for group in groups]


def lap_total(laps: SetLaps | None, field: str) -> int | None:
    """The sum of a lap field over the laps of a set; unknown without laps or when one lap lacks the value."""
    values = all_known([lap.developer.get(field) for lap in laps or ()])
    return sum(values) if values else None
