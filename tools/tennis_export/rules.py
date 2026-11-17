"""Players, match presets and the choices made before the first point (mirrors source/model)."""

from __future__ import annotations

from dataclasses import dataclass

ME = 0
OPPONENT = 1
PLAYERS = (ME, OPPONENT)
PLAYER_NAMES = ("me", "opponent")

ADVANTAGE_MARGIN = 2
DECIDING_POINT_MARGIN = 1


def opponent_of(player: int) -> int:
    return OPPONENT - player


@dataclass(frozen=True)
class FormatRules:
    name: str
    sets_to_win: int
    # A set reaches its tie break at this many games all, so zero means the set is nothing but a tie break.
    games_per_set: int
    tie_break_points: int
    # Zero means the deciding set is played out as a full set.
    match_tie_break_points: int


# Indexed by the format code of source/model/MatchFormat.mc.
FORMATS = (
    FormatRules("best_of_3", 2, 6, 7, 0),
    FormatRules("best_of_3_match_tie_break", 2, 6, 7, 10),
    FormatRules("one_set", 1, 6, 7, 0),
    FormatRules("pro_set", 1, 8, 7, 0),
    FormatRules("tie_break_only", 1, 0, 7, 0),
)


@dataclass(frozen=True)
class MatchConfig:
    rules: FormatRules
    is_no_advantage: bool
    first_server: int

    @property
    def game_win_margin(self) -> int:
        return DECIDING_POINT_MARGIN if self.is_no_advantage else ADVANTAGE_MARGIN

    def server_at(self, service_turn: int) -> int:
        """The player who serves on a service turn: one game, or one point pair inside a tie break."""
        return (self.first_server + service_turn) % len(PLAYERS)
