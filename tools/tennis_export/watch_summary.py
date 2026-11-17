"""The summary the watch stored in the activity, untouched: it does not depend on the point log."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from tennis_export.layout import FINAL_SCORE_FIELD, SET_SCORE_FIELD, STATISTICS_FIELD
from tennis_export.rules import PLAYER_NAMES, PLAYERS
from tennis_export.statistics import Stat

if TYPE_CHECKING:
    from collections.abc import Sequence

    from tennis_export.fit_reader import Activity, Message

type Document = dict[str, Any]

STATISTICS_COUNT = len(Stat) * len(PLAYERS)
GAMES_END = len(PLAYERS)
SET_SCORE_COUNT = GAMES_END * 2


def watch_summary_document(activity: Activity) -> Document:
    session = activity.session
    return {
        "final_score": session.developer.get(FINAL_SCORE_FIELD),
        "statistics": stored_statistics(session.developer.get(STATISTICS_FIELD)),
        "set_scores": [stored_set_score(lap) for lap in activity.laps],
    }


def stored_statistics(counts: Sequence[int] | None) -> Document | None:
    """The counters by player and name, or None when the field is missing or has another size."""
    if counts is None or len(counts) != STATISTICS_COUNT:
        return None
    return {name: player_counts(counts, player) for player, name in enumerate(PLAYER_NAMES)}


def player_counts(counts: Sequence[int], player: int) -> Document:
    return {stat.name.lower(): counts[stat * len(PLAYERS) + player] for stat in Stat}


def stored_set_score(lap: Message) -> Document | None:
    """The score the lap carries, or None for a lap without one."""
    score = lap.developer.get(SET_SCORE_FIELD)
    if score is None or len(score) != SET_SCORE_COUNT:
        return None
    return {"games": list(score[:GAMES_END]), "tie_break_points": list(score[GAMES_END:])}
