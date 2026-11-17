"""The wire layout of docs/DATA_FORMAT.md: developer field names and the bits packed inside them."""

from __future__ import annotations

from dataclasses import dataclass
from itertools import batched
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from collections.abc import Mapping, Sequence

FORMAT_VERSION = 1

POINT_LOG_FIELD = "point_log"
LOG_SIZE_FIELD = "log_size"
MATCH_SETUP_FIELD = "match_setup"
FINAL_SCORE_FIELD = "final_score"
STATISTICS_FIELD = "statistics"
STEPS_FIELD = "steps"
DISTANCE_FIELD = "distance"
SET_SCORE_FIELD = "set_score"
SET_STEPS_FIELD = "set_steps"
SET_DISTANCE_FIELD = "set_distance"
BLOCK_HITS_FIELD = "block_hits"
BLOCK_MISSES_FIELD = "block_misses"

RESULT_FAULT = 0
ENDING_NAMES = ("none", "winner", "ace", "error_net", "error_out")
# Code zero of a tag means the player did not set it.
SURFACE_NAMES = (None, "clay", "hard", "grass")
KIND_NAMES = (None, "match", "friendly")
WORDS_PER_SLOT = 3
EMPTY_SEQUENCE = 0
NO_VALUE = 0xFFFFFFFF


@dataclass(frozen=True)
class BitField:
    shift: int
    width: int

    def read(self, word: int) -> int:
        return (word >> self.shift) & ((1 << self.width) - 1)

    def clear(self, word: int) -> int:
        return word & ~(((1 << self.width) - 1) << self.shift)


ENTRY_RESULT = BitField(0, 2)
ENTRY_ENDING = BitField(2, 3)
ENTRY_HEART_RATE = BitField(5, 8)
ENTRY_TIME = BitField(13, 18)

SLOT_SEQUENCE = BitField(0, 16)
SLOT_SERVER = BitField(16, 1)
SLOT_SECOND_SERVE = BitField(17, 1)
SLOT_TIE_BREAK = BitField(18, 1)

SCORE_POINTS = (BitField(0, 7), BitField(7, 7))
SCORE_GAMES = (BitField(14, 4), BitField(18, 4))
SCORE_SETS = (BitField(22, 2), BitField(24, 2))
MAX_STORED_POINTS = 127

SETUP_VERSION = BitField(0, 4)
SETUP_FORMAT = BitField(4, 3)
SETUP_NO_ADVANTAGE = BitField(7, 1)
SETUP_DETAILED = BitField(8, 1)
SETUP_FIRST_SERVER = BitField(9, 1)
SETUP_SURFACE = BitField(10, 2)
SETUP_KIND = BitField(12, 2)


@dataclass(frozen=True)
class Entry:
    """One point log entry, as source/model/PointEntry.mc packs it."""

    result: int
    ending: int
    heart_rate: int | None
    time: int

    @property
    def is_fault(self) -> bool:
        return self.result == RESULT_FAULT

    @property
    def winner(self) -> int:
        return self.result - 1


@dataclass(frozen=True)
class StoredScore:
    points: tuple[int, int]
    games: tuple[int, int]
    sets: tuple[int, int]


@dataclass(frozen=True)
class Slot:
    """One entry as the record field carries it: what the watch saw around the entry, and the entry."""

    sequence: int
    server: int
    is_second_serve: bool
    is_tie_break: bool
    entry: Entry
    score: StoredScore


@dataclass(frozen=True)
class Setup:
    version: int
    match_format: int
    is_no_advantage: bool
    is_detailed: bool
    first_server: int
    surface: int
    kind: int


def name_at[Name](names: Sequence[Name], code: int) -> Name | None:
    """The name of a code, or None for a code this version does not know."""
    return names[code] if code < len(names) else None


def decode_entry(word: int) -> Entry:
    heart_rate = ENTRY_HEART_RATE.read(word)
    return Entry(
        result=ENTRY_RESULT.read(word),
        ending=ENTRY_ENDING.read(word),
        heart_rate=heart_rate or None,
        time=ENTRY_TIME.read(word),
    )


def read_pair(fields: tuple[BitField, BitField], word: int) -> tuple[int, int]:
    return fields[0].read(word), fields[1].read(word)


def decode_score(word: int) -> StoredScore:
    return StoredScore(
        points=read_pair(SCORE_POINTS, word),
        games=read_pair(SCORE_GAMES, word),
        sets=read_pair(SCORE_SETS, word),
    )


def decode_slot(header: int, entry: int, score: int) -> Slot:
    return Slot(
        sequence=SLOT_SEQUENCE.read(header),
        server=SLOT_SERVER.read(header),
        is_second_serve=bool(SLOT_SECOND_SERVE.read(header)),
        is_tie_break=bool(SLOT_TIE_BREAK.read(header)),
        entry=decode_entry(entry),
        score=decode_score(score),
    )


def written_point_log(developer: Mapping[str, Any]) -> Sequence[int] | None:
    """The point log value of a record, or None when the record has none or was written before the first one."""
    words: Sequence[int] | None = developer.get(POINT_LOG_FIELD)
    return None if words is None or words[0] == NO_VALUE else words


def newest_sequence(words: Sequence[int]) -> int:
    return SLOT_SEQUENCE.read(words[0])


def decode_slots(words: Sequence[int]) -> list[Slot]:
    """The filled slots of one record field value, newest first."""
    triples = [triple for triple in batched(words, WORDS_PER_SLOT) if len(triple) == WORDS_PER_SLOT]
    slots = [decode_slot(*triple) for triple in triples]
    return [slot for slot in slots if slot.sequence != EMPTY_SEQUENCE]


def decode_setup(word: int) -> Setup:
    return Setup(
        version=SETUP_VERSION.read(word),
        match_format=SETUP_FORMAT.read(word),
        is_no_advantage=bool(SETUP_NO_ADVANTAGE.read(word)),
        is_detailed=bool(SETUP_DETAILED.read(word)),
        first_server=SETUP_FIRST_SERVER.read(word),
        surface=SETUP_SURFACE.read(word),
        kind=SETUP_KIND.read(word),
    )
