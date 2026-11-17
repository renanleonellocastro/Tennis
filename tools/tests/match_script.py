"""Plays the part of the watch in the tests: packs entries and the record field as the watch would."""

from __future__ import annotations

from typing import TYPE_CHECKING

from tennis_export import layout
from tennis_export.match_state import MatchState
from tennis_export.rules import FORMATS, ME, OPPONENT, MatchConfig

if TYPE_CHECKING:
    from tennis_export.layout import BitField, Slot

FAULT = 0
ME_WINS = 1
OPPONENT_WINS = 2
RESULTS = {"f": FAULT, "m": ME_WINS, "o": OPPONENT_WINS}

NONE = 0
WINNER = 1
ACE = 2
ERROR_NET = 3
ERROR_OUT = 4

SECONDS_BETWEEN_ENTRIES = 20
SLOTS_PER_RECORD = 3
EMPTY_SLOT = [0, 0, 0]


def put(field: BitField, value: int) -> int:
    return (value & ((1 << field.width) - 1)) << field.shift


def put_pair(fields: tuple[BitField, BitField], values: tuple[int, int]) -> int:
    return put(fields[ME], values[ME]) | put(fields[OPPONENT], values[OPPONENT])


def pack_entry(result: int, *, ending: int = NONE, heart_rate: int = 0, time: int = 0) -> int:
    packed = put(layout.ENTRY_RESULT, result) | put(layout.ENTRY_ENDING, ending)
    return packed | put(layout.ENTRY_HEART_RATE, heart_rate) | put(layout.ENTRY_TIME, time)


def pack_header(sequence: int, server: int, *, is_second_serve: bool = False, is_tie_break: bool = False) -> int:
    packed = put(layout.SLOT_SEQUENCE, sequence) | put(layout.SLOT_SERVER, server)
    return packed | put(layout.SLOT_SECOND_SERVE, is_second_serve) | put(layout.SLOT_TIE_BREAK, is_tie_break)


def pack_score(points: tuple[int, int], games: tuple[int, int], sets: tuple[int, int]) -> int:
    stored = (min(points[ME], layout.MAX_STORED_POINTS), min(points[OPPONENT], layout.MAX_STORED_POINTS))
    packed = put_pair(layout.SCORE_POINTS, stored) | put_pair(layout.SCORE_GAMES, games)
    return packed | put_pair(layout.SCORE_SETS, sets)


def pack_setup(  # noqa: PLR0913 the setup word simply has this many parts
    match_format: int = 0,
    *,
    no_advantage: bool = False,
    detailed: bool = True,
    first_server: int = ME,
    surface: int = 0,
    kind: int = 0,
    version: int = layout.FORMAT_VERSION,
) -> int:
    packed = put(layout.SETUP_VERSION, version) | put(layout.SETUP_FORMAT, match_format)
    packed |= put(layout.SETUP_NO_ADVANTAGE, no_advantage) | put(layout.SETUP_DETAILED, detailed)
    packed |= put(layout.SETUP_FIRST_SERVER, first_server) | put(layout.SETUP_SURFACE, surface)
    return packed | put(layout.SETUP_KIND, kind)


def config(match_format: int = 0, *, no_advantage: bool = False, first_server: int = ME) -> MatchConfig:
    return MatchConfig(FORMATS[match_format], no_advantage, first_server)


class WatchLog:
    """The point log of a watch; a script is a run of m (my point), o (opponent's point) and f (fault)."""

    def __init__(self, match_config: MatchConfig | None = None) -> None:
        self.config = match_config or config()
        self.entries: list[int] = []

    def add(self, result: int, *, ending: int = NONE, heart_rate: int = 0, time: int | None = None) -> WatchLog:
        """Without a time the entries are twenty seconds apart, the first one twenty seconds in."""
        clock = SECONDS_BETWEEN_ENTRIES * (len(self.entries) + 1) if time is None else time
        self.entries.append(pack_entry(result, ending=ending, heart_rate=heart_rate, time=clock))
        return self

    def play(self, script: str) -> WatchLog:
        for letter in script.replace(" ", ""):
            self.add(RESULTS[letter])
        return self

    def undo(self) -> WatchLog:
        self.entries.pop()
        return self

    def triples(self) -> list[list[int]]:
        """Header, entry and score of every entry, oldest first, as the watch engine would see them."""
        state = MatchState(self.config)
        triples = []
        for index, word in enumerate(self.entries):
            flags = {"is_second_serve": state.is_second_serve, "is_tie_break": state.is_tie_break}
            header = pack_header(index + 1, state.server, **flags)
            state.apply(layout.decode_entry(word))
            triples.append([header, word, pack_score(state.points, state.games, state.sets)])
        return triples

    @staticmethod
    def _field_value(triples: list[list[int]]) -> list[int]:
        newest_first = triples[::-1][:SLOTS_PER_RECORD]
        padding = [EMPTY_SLOT] * (SLOTS_PER_RECORD - len(newest_first))
        return [word for triple in newest_first + padding for word in triple]

    def record_value(self) -> list[int]:
        """The record field right now: the newest entry and the two before it, newest first."""
        return self._field_value(self.triples())

    def record_values(self) -> list[list[int]]:
        """The record field after each entry, as if the watch wrote one record for every entry."""
        triples = self.triples()
        return [self._field_value(triples[:count]) for count in range(1, len(triples) + 1)]

    def slots(self) -> list[Slot]:
        return [layout.decode_slot(*triple) for triple in self.triples()]
