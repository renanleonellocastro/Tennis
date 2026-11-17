"""Replays a point log with the rules of the watch engine (mirrors source/engine/MatchReplay.mc)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from tennis_export.collector import Situation, StatisticsCollector, situation_before
from tennis_export.match_state import MatchState, Outcome
from tennis_export.rules import ME, OPPONENT

if TYPE_CHECKING:
    from collections.abc import Iterable

    from tennis_export.layout import Entry, Slot
    from tennis_export.rules import MatchConfig
    from tennis_export.statistics import MatchStatistics


@dataclass(frozen=True)
class ScoreAfter:
    """The score right after an entry: a closed game shows 0 and 0, a closed set shows no games."""

    display_points: tuple[str, str]
    points: tuple[int, int]
    games: tuple[int, int]
    sets: tuple[int, int]


@dataclass(frozen=True)
class Row:
    """One log entry with what was at stake before it and the score after it."""

    slot: Slot
    situation: Situation
    outcome: Outcome
    score: ScoreAfter

    @property
    def entry(self) -> Entry:
        return self.slot.entry

    @property
    def is_point(self) -> bool:
        return Outcome.POINT in self.outcome


@dataclass(frozen=True)
class Replay:
    config: MatchConfig
    rows: tuple[Row, ...]
    state: MatchState
    statistics: MatchStatistics


def score_after(state: MatchState) -> ScoreAfter:
    return ScoreAfter(
        display_points=(state.display_points(ME), state.display_points(OPPONENT)),
        points=state.points,
        games=state.games,
        sets=state.sets,
    )


def replay(config: MatchConfig, slots: Iterable[Slot]) -> Replay:
    """Entries that follow the point that ends the match are left out, as on the watch."""
    state = MatchState(config)
    collector = StatisticsCollector()
    rows: list[Row] = []
    for slot in slots:
        if state.is_finished:
            break
        rows.append(apply_slot(state, collector, slot))
    return Replay(config, tuple(rows), state, collector.statistics)


def apply_slot(state: MatchState, collector: StatisticsCollector, slot: Slot) -> Row:
    situation = situation_before(state, slot.entry)
    outcome = state.apply(slot.entry)
    collector.record(situation, slot.entry, outcome)
    return Row(slot, situation, outcome, score_after(state))
