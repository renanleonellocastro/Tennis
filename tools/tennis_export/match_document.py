"""The match part of match.json: configuration, score, sets, games and statistics."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from tennis_export.layout import (
    KIND_NAMES,
    SET_DISTANCE_FIELD,
    SET_STEPS_FIELD,
    SURFACE_NAMES,
    name_at,
)
from tennis_export.rules import ME, OPPONENT, PLAYER_NAMES, PLAYERS
from tennis_export.set_laps import lap_total
from tennis_export.statistics import Stat

if TYPE_CHECKING:
    from collections.abc import Sequence

    from tennis_export.layout import Setup
    from tennis_export.match_reader import Match
    from tennis_export.match_state import MatchState, SetScore
    from tennis_export.replay import Replay
    from tennis_export.set_laps import SetLaps
    from tennis_export.statistics import GameRecord, MatchStatistics

type Document = dict[str, Any]

DETAIL_LEVELS = ("simple", "detailed")


def match_document(match: Match, set_laps: Sequence[SetLaps] | None) -> Document:
    state = match.replay.state
    return {
        "config": config_document(match),
        "tags": tags_document(match.setup),
        "finished": state.is_finished,
        "winner": None if state.winner is None else PLAYER_NAMES[state.winner],
        "score": score_document(state),
        "sets": set_documents(match.replay, set_laps),
        "games": [game_document(game) for game in match.replay.statistics.games],
        "statistics": statistics_document(match.replay.statistics),
    }


def config_document(match: Match) -> Document:
    return {
        "format": match.replay.config.rules.name,
        "no_advantage": match.setup.is_no_advantage,
        "detail_level": DETAIL_LEVELS[match.setup.is_detailed],
        "first_server": PLAYER_NAMES[match.setup.first_server],
    }


def tags_document(setup: Setup) -> Document:
    return {"surface": name_at(SURFACE_NAMES, setup.surface), "kind": name_at(KIND_NAMES, setup.kind)}


def set_text(score: SetScore) -> str:
    games = f"{score.games[ME]}-{score.games[OPPONENT]}"
    if not score.is_decided_by_tie_break:
        return games
    return f"{games}({score.tie_break_points[ME]}-{score.tie_break_points[OPPONENT]})"


def score_text(state: MatchState) -> str:
    """Closed sets as on a scoreboard, then the games of the set that was still open, when there is one."""
    parts = [set_text(score) for score in state.set_scores]
    if not state.is_finished:
        parts.append(f"{state.games[ME]}-{state.games[OPPONENT]}")
    return " ".join(parts)


def score_document(state: MatchState) -> Document:
    return {
        "sets": [list(score.games) for score in state.set_scores],
        "current_games": list(state.games),
        "current_points": [state.display_points(player) for player in PLAYERS],
        "text": score_text(state),
    }


def set_documents(replay: Replay, set_laps: Sequence[SetLaps] | None) -> list[Document]:
    durations = replay.statistics.set_durations
    scores = replay.state.set_scores
    return [
        set_document(index, scores[index], durations[index]) | motion_document(laps_at(set_laps, index))
        for index in range(len(scores))
    ]


def laps_at(set_laps: Sequence[SetLaps] | None, index: int) -> SetLaps | None:
    return None if set_laps is None else set_laps[index]


def set_document(index: int, score: SetScore, duration: int) -> Document:
    return {
        "set": index + 1,
        "games": list(score.games),
        "tie_break_points": list(score.tie_break_points) if score.is_decided_by_tie_break else None,
        "winner": PLAYER_NAMES[score.winner],
        "duration_seconds": duration,
    }


def motion_document(laps: SetLaps | None) -> Document:
    """Steps and meters add up over every lap of the set; laps is None when they could not be placed in time."""
    return {
        "steps": lap_total(laps, SET_STEPS_FIELD),
        "distance_m": lap_total(laps, SET_DISTANCE_FIELD),
        "laps": None if laps is None else len(laps),
    }


def game_document(game: GameRecord) -> Document:
    return {
        "set": game.set_number,
        "game": game.game_number,
        "server": PLAYER_NAMES[game.first_server],
        "winner": PLAYER_NAMES[game.winner],
        "tie_break": game.is_tie_break,
        "duration_seconds": game.duration_seconds,
    }


def statistics_document(statistics: MatchStatistics) -> Document:
    return {
        "me": player_statistics(statistics, ME),
        "opponent": player_statistics(statistics, OPPONENT),
        "average_seconds_between_points": one_decimal(statistics.average_seconds_between_points()),
        "average_deciding_heart_rate": statistics.average_deciding_heart_rate(),
    }


def one_decimal(value: float | None) -> float | None:
    """A ratio with nothing to divide stays unknown instead of turning into zero."""
    return None if value is None else round(value, 1)


def player_statistics(statistics: MatchStatistics, player: int) -> Document:
    counted = {stat.name.lower(): statistics.count(stat, player) for stat in Stat}
    return counted | derived_statistics(statistics, player)


def derived_statistics(statistics: MatchStatistics, player: int) -> Document:
    return {
        "first_serve_percent": statistics.first_serve_percent(player),
        "second_serve_points": statistics.second_serve_points(player),
        "return_games_played": statistics.return_games_played(player),
        "return_games_won": statistics.return_games_won(player),
        "break_points_faced": statistics.break_points_faced(player),
        "break_points_saved": statistics.break_points_saved(player),
    }
