"""Compares what the watch stored next to each entry and in its summary with what the replay derives."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

from tennis_export.layout import MAX_STORED_POINTS, SET_SCORE_FIELD, STATISTICS_FIELD, StoredScore
from tennis_export.rules import ME, OPPONENT

if TYPE_CHECKING:
    from collections.abc import Sequence

    from tennis_export.fit_reader import Activity, Message
    from tennis_export.match_reader import Match
    from tennis_export.match_state import SetScore
    from tennis_export.replay import Row, ScoreAfter
    from tennis_export.set_laps import SetLaps


def integrity_document(match: Match, activity: Activity, set_laps: Sequence[SetLaps] | None) -> dict[str, Any]:
    """Empty list and true (or null when the watch stored nothing to compare) mean the two sides agree."""
    return {
        "score_mismatches": [row.slot.sequence for row in match.replay.rows if not agrees(row)],
        "statistics_match": statistics_match(activity.session, match.replay.statistics.counts),
        "set_scores_match": set_scores_match(set_laps, match.replay.state.set_scores),
    }


def stored_form(score: ScoreAfter) -> StoredScore:
    """The replayed score as the watch packs it: point counts stop at the largest value that fits."""
    points = (min(score.points[ME], MAX_STORED_POINTS), min(score.points[OPPONENT], MAX_STORED_POINTS))
    return StoredScore(points, score.games, score.sets)


def agrees(row: Row) -> bool:
    slot, situation = row.slot, row.situation
    stored = (slot.server, slot.is_second_serve, slot.is_tie_break, slot.score)
    return stored == (situation.server, situation.is_second_serve, situation.is_tie_break, stored_form(row.score))


def statistics_match(session: Message, counts: Sequence[int]) -> bool | None:
    stored = session.developer.get(STATISTICS_FIELD)
    return None if stored is None else list(stored) == list(counts)


def stored_set_form(score: SetScore) -> list[int]:
    return [*score.games, *score.tie_break_points]


def set_scores_match(set_laps: Sequence[SetLaps] | None, scores: Sequence[SetScore]) -> bool | None:
    """Each closed set is compared with the lap that closed it, the last of its laps."""
    closing = [laps[-1] for laps in set_laps or () if laps]
    stored = [list(lap.developer[SET_SCORE_FIELD]) for lap in closing if SET_SCORE_FIELD in lap.developer]
    return stored == [stored_set_form(score) for score in scores] if stored else None
