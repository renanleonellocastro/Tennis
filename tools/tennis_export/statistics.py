"""The numbers of a match for both players (mirrors source/engine/MatchStatistics.mc)."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import IntEnum

from tennis_export.rules import PLAYERS, opponent_of

PERCENT = 100
ENDING_WINNER = 1


class Stat(IntEnum):
    """The counters kept for each player, in the order of the watch and of the statistics field."""

    SERVICE_POINTS = 0
    FIRST_SERVES_IN = 1
    FIRST_SERVE_POINTS_WON = 2
    SECOND_SERVE_POINTS_WON = 3
    DOUBLE_FAULTS = 4
    SERVICE_GAMES_PLAYED = 5
    SERVICE_GAMES_WON = 6
    BREAK_POINT_CHANCES = 7
    BREAK_POINTS_WON = 8
    POINTS_WON = 9
    LONGEST_RUN = 10
    # The next four keep the order of the ending codes, so an ending maps straight to its counter.
    WINNERS = 11
    ACES = 12
    ERRORS_NET = 13
    ERRORS_OUT = 14


def stat_for_ending(ending: int) -> Stat:
    return Stat(Stat.WINNERS + ending - ENDING_WINNER)


@dataclass(frozen=True)
class GameRecord:
    set_number: int
    game_number: int
    first_server: int
    winner: int
    is_tie_break: bool
    duration_seconds: int


@dataclass(frozen=True)
class PointTimes:
    count: int = 0
    first: int = 0
    last: int = 0

    def with_point_at(self, time: int) -> PointTimes:
        return PointTimes(self.count + 1, time if self.count == 0 else self.first, time)


@dataclass
class MatchStatistics:
    """Filled in by StatisticsCollector while the log is replayed; the exports only read it."""

    counts: list[int] = field(default_factory=lambda: [0] * (len(Stat) * len(PLAYERS)))
    games: list[GameRecord] = field(default_factory=list)
    set_durations: list[int] = field(default_factory=list)
    point_times: PointTimes = field(default_factory=PointTimes)
    deciding_heart_rates: list[int] = field(default_factory=list)

    @staticmethod
    def _slot(stat: Stat, player: int) -> int:
        return stat * len(PLAYERS) + player

    def add(self, stat: Stat, player: int) -> None:
        self.counts[self._slot(stat, player)] += 1

    def raise_to(self, stat: Stat, player: int, value: int) -> None:
        self.counts[self._slot(stat, player)] = max(value, self.count(stat, player))

    def note_point_time(self, time: int) -> None:
        self.point_times = self.point_times.with_point_at(time)

    def count(self, stat: Stat, player: int) -> int:
        return self.counts[self._slot(stat, player)]

    def first_serve_percent(self, player: int) -> int | None:
        """Rounded to a whole percent; None before the player has served, where the watch shows zero."""
        served = self.count(Stat.SERVICE_POINTS, player)
        if served == 0:
            return None
        return (self.count(Stat.FIRST_SERVES_IN, player) * PERCENT + served // 2) // served

    def second_serve_points(self, player: int) -> int:
        return self.count(Stat.SERVICE_POINTS, player) - self.count(Stat.FIRST_SERVES_IN, player)

    def return_games_played(self, player: int) -> int:
        return self.count(Stat.SERVICE_GAMES_PLAYED, opponent_of(player))

    def return_games_won(self, player: int) -> int:
        return self.return_games_played(player) - self.count(Stat.SERVICE_GAMES_WON, opponent_of(player))

    def break_points_faced(self, player: int) -> int:
        return self.count(Stat.BREAK_POINT_CHANCES, opponent_of(player))

    def break_points_saved(self, player: int) -> int:
        return self.break_points_faced(player) - self.count(Stat.BREAK_POINTS_WON, opponent_of(player))

    def average_seconds_between_points(self) -> float | None:
        """None until two points were played, where the watch shows zero."""
        times = self.point_times
        if times.count < 2:
            return None
        return (times.last - times.first) / (times.count - 1)

    def average_deciding_heart_rate(self) -> int | None:
        """Average over the break and set points that carried a heart rate; None when none did."""
        samples = len(self.deciding_heart_rates)
        if samples == 0:
            return None
        return (sum(self.deciding_heart_rates) + samples // 2) // samples
