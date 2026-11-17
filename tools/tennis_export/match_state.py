"""The score of a match, built by applying log entries in order (mirrors source/engine/MatchState.mc)."""

from __future__ import annotations

from dataclasses import dataclass
from enum import IntFlag
from typing import TYPE_CHECKING

from tennis_export.rules import ME, OPPONENT, opponent_of

if TYPE_CHECKING:
    from tennis_export.layout import Entry
    from tennis_export.rules import MatchConfig

REGULAR_GAME_POINTS = 4
DEUCE_POINTS = 3
TWO_CLEAR = 2
DISPLAY_POINTS = ("0", "15", "30", "40")
DISPLAY_ADVANTAGE = "AD"


class Outcome(IntFlag):
    """What one applied entry did; the point that ends a set reports POINT, GAME and SET together."""

    FAULT = 0
    POINT = 1
    GAME = 2
    SET = 4
    MATCH = 8


@dataclass(frozen=True)
class SetScore:
    games: tuple[int, int]
    last_game_points: tuple[int, int]

    @property
    def is_decided_by_tie_break(self) -> bool:
        return abs(self.games[ME] - self.games[OPPONENT]) < TWO_CLEAR

    @property
    def tie_break_points(self) -> tuple[int, int]:
        return self.last_game_points if self.is_decided_by_tie_break else (0, 0)

    @property
    def winner(self) -> int:
        return ME if self.games[ME] > self.games[OPPONENT] else OPPONENT


class MatchState:
    def __init__(self, config: MatchConfig) -> None:
        self._config = config
        self._points = [0, 0]
        self._games = [0, 0]
        self._sets = [0, 0]
        self._set_scores: list[SetScore] = []
        self._service_turn = 0
        self._is_second_serve = False
        self._winner: int | None = None

    def apply(self, entry: Entry) -> Outcome:
        if entry.is_fault and not self._is_second_serve:
            self._is_second_serve = True
            return Outcome.FAULT
        return self._award_point(self.point_winner(entry))

    def point_winner(self, entry: Entry) -> int:
        """Who takes the point when this entry ends one; a double fault goes to the receiver."""
        return self.receiver if entry.is_fault else entry.winner

    def _award_point(self, winner: int) -> Outcome:
        self._is_second_serve = False
        self._points[winner] += 1
        if self._wins_game_with(self._points[winner], self._lead(self._points, winner)):
            return Outcome.POINT | self._close_game(winner)
        return Outcome.POINT

    def _close_game(self, winner: int) -> Outcome:
        is_set_over = self._would_win_set(winner)
        self._games[winner] += 1
        self._service_turn += 1
        if is_set_over:
            return Outcome.GAME | self._close_set(winner)
        self._points = [0, 0]
        return Outcome.GAME

    def _close_set(self, winner: int) -> Outcome:
        self._sets[winner] += 1
        self._set_scores.append(SetScore((self._games[ME], self._games[OPPONENT]), self.points))
        self._games = [0, 0]
        self._points = [0, 0]
        if self._sets[winner] < self._config.rules.sets_to_win:
            return Outcome.SET
        self._winner = winner
        return Outcome.SET | Outcome.MATCH

    @staticmethod
    def _lead(pair: list[int], player: int) -> int:
        return pair[player] - pair[opponent_of(player)]

    @property
    def _points_played(self) -> int:
        return self._points[ME] + self._points[OPPONENT]

    @property
    def is_tie_break(self) -> bool:
        games_all = self._config.rules.games_per_set
        return self._is_match_tie_break or self._games == [games_all, games_all]

    @property
    def _is_match_tie_break(self) -> bool:
        sets_before_decider = self._config.rules.sets_to_win - 1
        has_match_tie_break = self._config.rules.match_tie_break_points > 0
        return has_match_tie_break and self._sets == [sets_before_decider, sets_before_decider]

    @property
    def _game_target(self) -> int:
        if self._is_match_tie_break:
            return self._config.rules.match_tie_break_points
        return self._config.rules.tie_break_points if self.is_tie_break else REGULAR_GAME_POINTS

    @property
    def _game_margin(self) -> int:
        return TWO_CLEAR if self.is_tie_break else self._config.game_win_margin

    def _wins_game_with(self, points: int, points_lead: int) -> bool:
        return points >= self._game_target and points_lead >= self._game_margin

    def _would_win_set(self, player: int) -> bool:
        has_enough_games = self._games[player] + 1 >= self._config.rules.games_per_set
        return self.is_tie_break or (has_enough_games and self._lead(self._games, player) + 1 >= TWO_CLEAR)

    @property
    def server(self) -> int:
        return self._config.server_at(self._service_turn + self._tie_break_serve_turns)

    @property
    def receiver(self) -> int:
        return opponent_of(self.server)

    @property
    def game_first_server(self) -> int:
        return self._config.server_at(self._service_turn)

    @property
    def _tie_break_serve_turns(self) -> int:
        """Inside a tie break the serve passes after the first point and then after every two."""
        return (self._points_played + 1) // 2 if self.is_tie_break else 0

    @property
    def is_second_serve(self) -> bool:
        return self._is_second_serve

    def display_points(self, player: int) -> str:
        points = self._points[player]
        if self.is_tie_break:
            return str(points)
        if points < DEUCE_POINTS:
            return DISPLAY_POINTS[points]
        has_advantage = self._lead(self._points, player) > 0 and points > DEUCE_POINTS
        return DISPLAY_ADVANTAGE if has_advantage else DISPLAY_POINTS[DEUCE_POINTS]

    @property
    def points(self) -> tuple[int, int]:
        return self._points[ME], self._points[OPPONENT]

    @property
    def games(self) -> tuple[int, int]:
        return self._games[ME], self._games[OPPONENT]

    @property
    def sets(self) -> tuple[int, int]:
        return self._sets[ME], self._sets[OPPONENT]

    @property
    def set_scores(self) -> tuple[SetScore, ...]:
        return tuple(self._set_scores)

    @property
    def is_finished(self) -> bool:
        return self._winner is not None

    @property
    def winner(self) -> int | None:
        return self._winner

    def has_game_point(self, player: int) -> bool:
        points_after = self._points[player] + 1
        return not self.is_finished and self._wins_game_with(points_after, self._lead(self._points, player) + 1)

    def has_break_point(self, player: int) -> bool:
        return not self.is_tie_break and player == self.receiver and self.has_game_point(player)

    def has_set_point(self, player: int) -> bool:
        return self.has_game_point(player) and self._would_win_set(player)

    def has_match_point(self, player: int) -> bool:
        return self.has_set_point(player) and self._sets[player] + 1 >= self._config.rules.sets_to_win
