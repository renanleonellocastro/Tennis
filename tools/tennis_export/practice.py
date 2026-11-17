"""Reads a practice: one lap for each block, with the hits and misses counted while it was open."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from tennis_export.layout import BLOCK_HITS_FIELD, BLOCK_MISSES_FIELD

if TYPE_CHECKING:
    from collections.abc import Sequence

    from tennis_export.fit_reader import Activity, Message

LAP_COUNT = "num_laps"


@dataclass(frozen=True)
class Block:
    number: int
    hits: int
    misses: int
    lap: Message

    @property
    def shots(self) -> int:
        return self.hits + self.misses


def read_practice(activity: Activity) -> tuple[Block, ...] | None:
    """The blocks in the order they were played; None when no lap carries the counters, so it is no practice."""
    laps = [lap for lap in session_laps(activity) if lap.developer.get(BLOCK_HITS_FIELD) is not None]
    if not laps:
        return None
    blocks = [block_of(index + 1, lap) for index, lap in enumerate(laps)]
    return tuple(without_empty_last(blocks))


def session_laps(activity: Activity) -> Sequence[Message]:
    """The last laps of the file, as many as the session says it has.

    Files from the simulator start with laps of activities that were thrown away before this one.
    """
    count = activity.session.native.get(LAP_COUNT)
    return activity.laps if count is None else activity.laps[max(len(activity.laps) - count, 0) :]


def block_of(number: int, lap: Message) -> Block:
    return Block(number, lap.developer[BLOCK_HITS_FIELD], lap.developer.get(BLOCK_MISSES_FIELD) or 0, lap)


def without_empty_last(blocks: Sequence[Block]) -> Sequence[Block]:
    """Saving closes the lap that was open; with nothing counted it is the rest after the last block, not a block."""
    return blocks[:-1] if blocks[-1].shots == 0 else blocks


def success_percent(hits: int, shots: int) -> int | None:
    """A whole percent rounded half up, as the watch shows it; None when nothing was counted."""
    return None if shots == 0 else (200 * hits + shots) // (2 * shots)
