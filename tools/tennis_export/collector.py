"""Counts the statistics while a log is replayed (mirrors source/engine/StatisticsCollector.mc)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from tennis_export.layout import ENDING_NAMES
from tennis_export.match_state import Outcome
from tennis_export.rules import PLAYERS, opponent_of
from tennis_export.statistics import GameRecord, MatchStatistics, Stat, stat_for_ending

if TYPE_CHECKING:
    from tennis_export.layout import Entry
    from tennis_export.match_state import MatchState

ERROR_ENDINGS = frozenset({ENDING_NAMES.index("error_net"), ENDING_NAMES.index("error_out")})
NO_ENDING = ENDING_NAMES.index("none")


@dataclass(frozen=True)
class Situation:
    """What was at stake right before an entry was applied."""

    set_number: int
    game_number: int
    point_number: int
    server: int
    game_first_server: int
    winner: int
    is_second_serve: bool
    is_tie_break: bool
    is_break_point: bool
    is_set_point: bool
    is_match_point: bool

    @property
    def is_deciding_point(self) -> bool:
        return self.is_break_point or self.is_set_point


def situation_before(state: MatchState, entry: Entry) -> Situation:
    return Situation(
        *position_before(state),
        server=state.server,
        game_first_server=state.game_first_server,
        winner=state.point_winner(entry),
        is_second_serve=state.is_second_serve,
        is_tie_break=state.is_tie_break,
        is_break_point=state.has_break_point(state.receiver),
        is_set_point=any(state.has_set_point(player) for player in PLAYERS),
        is_match_point=any(state.has_match_point(player) for player in PLAYERS),
    )


def position_before(state: MatchState) -> tuple[int, int, int]:
    """The set, the game inside the set and the point inside the game about to be played, counted from one."""
    return len(state.set_scores) + 1, sum(state.games) + 1, sum(state.points) + 1


class StatisticsCollector:
    def __init__(self) -> None:
        self.statistics = MatchStatistics()
        self._run_player: int | None = None
        self._run_length = 0
        # The match clock starts at zero, so the first game and set start there.
        self._game_start = 0
        self._set_start = 0

    def record(self, situation: Situation, entry: Entry, outcome: Outcome) -> None:
        """Counts what one applied entry did; a first fault produces no point and counts nothing."""
        if Outcome.POINT not in outcome:
            return
        self._record_serve(situation, entry)
        self._record_ending(situation, entry.ending)
        self._record_run(situation.winner)
        self._record_break_point(situation)
        self._record_deciding_heart_rate(situation, entry.heart_rate)
        self._record_times(situation, outcome, entry.time)

    def _record_serve(self, situation: Situation, entry: Entry) -> None:
        server = situation.server
        self.statistics.add(Stat.POINTS_WON, situation.winner)
        self.statistics.add(Stat.SERVICE_POINTS, server)
        if entry.is_fault:
            self.statistics.add(Stat.DOUBLE_FAULTS, server)
        if not situation.is_second_serve:
            self.statistics.add(Stat.FIRST_SERVES_IN, server)
        if situation.winner == server:
            won = Stat.SECOND_SERVE_POINTS_WON if situation.is_second_serve else Stat.FIRST_SERVE_POINTS_WON
            self.statistics.add(won, server)

    def _record_ending(self, situation: Situation, ending: int) -> None:
        """A winner or an ace belongs to the player who won the point, an error to the one who lost it."""
        if ending == NO_ENDING:
            return
        owner = opponent_of(situation.winner) if ending in ERROR_ENDINGS else situation.winner
        self.statistics.add(stat_for_ending(ending), owner)

    def _record_run(self, winner: int) -> None:
        self._run_length = self._run_length + 1 if winner == self._run_player else 1
        self._run_player = winner
        self.statistics.raise_to(Stat.LONGEST_RUN, winner, self._run_length)

    def _record_break_point(self, situation: Situation) -> None:
        if not situation.is_break_point:
            return
        holder = opponent_of(situation.server)
        self.statistics.add(Stat.BREAK_POINT_CHANCES, holder)
        if situation.winner == holder:
            self.statistics.add(Stat.BREAK_POINTS_WON, holder)

    def _record_deciding_heart_rate(self, situation: Situation, heart_rate: int | None) -> None:
        if situation.is_deciding_point and heart_rate is not None:
            self.statistics.deciding_heart_rates.append(heart_rate)

    def _record_times(self, situation: Situation, outcome: Outcome, time: int) -> None:
        self.statistics.note_point_time(time)
        if Outcome.GAME in outcome:
            self._record_game(situation, time)
        if Outcome.SET in outcome:
            self.statistics.set_durations.append(time - self._set_start)
            self._set_start = time

    def _record_game(self, situation: Situation, time: int) -> None:
        self.statistics.games.append(self._game_record(situation, time - self._game_start))
        self._game_start = time
        if not situation.is_tie_break:
            self._record_service_game(situation)

    @staticmethod
    def _game_record(situation: Situation, duration: int) -> GameRecord:
        return GameRecord(
            set_number=situation.set_number,
            game_number=situation.game_number,
            first_server=situation.game_first_server,
            winner=situation.winner,
            is_tie_break=situation.is_tie_break,
            duration_seconds=duration,
        )

    def _record_service_game(self, situation: Situation) -> None:
        self.statistics.add(Stat.SERVICE_GAMES_PLAYED, situation.server)
        if situation.winner == situation.server:
            self.statistics.add(Stat.SERVICE_GAMES_WON, situation.server)
