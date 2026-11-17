"""Finds when each entry of the point log was marked, from the time of the records that carry it."""

from __future__ import annotations

from typing import TYPE_CHECKING

from tennis_export.layout import POINT_LOG_FIELD, decode_slots, newest_sequence
from tennis_export.point_log import forget_undone

if TYPE_CHECKING:
    from collections.abc import Iterable, Sequence
    from datetime import datetime

    from tennis_export.fit_reader import Message
    from tennis_export.layout import Slot

type Sighting = tuple[Slot, datetime | None]

RECORD_TIME = "timestamp"


def entry_times(records: Iterable[Message]) -> dict[int, datetime | None]:
    """For each entry still in the log, the time of the first record that carried it as it is now.

    The time is at or after the moment the entry was marked, late by at most the gap between two records.
    """
    sightings: dict[int, Sighting] = {}
    for record in records:
        words = record.developer.get(POINT_LOG_FIELD)
        if words is not None:
            forget_undone(sightings, newest_sequence(words))
            note_first_sightings(sightings, decode_slots(words), record.native.get(RECORD_TIME))
    return {sequence: time for sequence, (_, time) in sightings.items()}


def note_first_sightings(sightings: dict[int, Sighting], slots: Sequence[Slot], time: datetime | None) -> None:
    """An entry marked again under the number of an undone one differs from it, so its time starts over."""
    for slot in slots:
        if sightings.get(slot.sequence, (None, None))[0] != slot:
            sightings[slot.sequence] = (slot, time)
