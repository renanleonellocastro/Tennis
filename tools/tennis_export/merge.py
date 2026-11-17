"""Joins the activity files of one match, given in recording order, into a single activity.

Records and laps follow each other, so the point log is rebuilt over all of them by sequence number and the
positions form one track. The session of the last file speaks for the whole match (setup, log size, final
score, statistics); what each file counted on its own is added up.
"""

from __future__ import annotations

from itertools import chain
from typing import TYPE_CHECKING, Any

from tennis_export.fit_reader import Activity, Message
from tennis_export.layout import DISTANCE_FIELD, STEPS_FIELD

if TYPE_CHECKING:
    from collections.abc import Mapping, Sequence

START_TIME = "start_time"
ADDED_NATIVE = ("total_elapsed_time", "total_timer_time", "total_calories", "total_distance")
ADDED_DEVELOPER = (STEPS_FIELD, DISTANCE_FIELD)


def merge_activities(activities: Sequence[Activity]) -> Activity:
    if len(activities) == 1:
        return activities[0]
    records = tuple(chain.from_iterable(activity.records for activity in activities))
    laps = tuple(chain.from_iterable(activity.laps for activity in activities))
    return Activity(records, laps, (merged_session([activity.session for activity in activities]),))


def merged_session(sessions: Sequence[Message]) -> Message:
    first, last = sessions[0], sessions[-1]
    start = {START_TIME: first.native.get(START_TIME)}
    native = {**last.native, **start, **totals([session.native for session in sessions], ADDED_NATIVE)}
    developer = {**last.developer, **totals([session.developer for session in sessions], ADDED_DEVELOPER)}
    return Message(native, developer)


def totals(parts: Sequence[Mapping[str, Any]], names: Sequence[str]) -> dict[str, Any]:
    """A value no part has stays absent; one that only some parts have is unknown, never a partial sum."""
    counted = {name: [part.get(name) for part in parts] for name in names}
    return {name: total(values) for name, values in counted.items() if any(value is not None for value in values)}


def total(values: Sequence[Any]) -> Any:
    return None if None in values else sum(values)
