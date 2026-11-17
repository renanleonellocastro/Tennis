"""The summary of the watch reads on its own, with or without a point log next to it."""

from __future__ import annotations

from typing import Any

from tennis_export.fit_reader import Activity, Message
from tennis_export.statistics import Stat
from tennis_export.watch_summary import STATISTICS_COUNT, watch_summary_document

POINTS_WON_ME = Stat.POINTS_WON * 2
ACES_OPPONENT = Stat.ACES * 2 + 1


def activity_with(session: dict[str, Any], laps: tuple[dict[str, Any], ...] = ()) -> Activity:
    return Activity(records=(), laps=tuple(Message(developer=lap) for lap in laps), sessions=(Message({}, session),))


def counts_with(values: dict[int, int]) -> list[int]:
    return [values.get(index, 0) for index in range(STATISTICS_COUNT)]


def test_the_stored_counters_are_named_for_each_player() -> None:
    counts = counts_with({POINTS_WON_ME: 25, ACES_OPPONENT: 3})

    summary = watch_summary_document(activity_with({"final_score": "6-1", "statistics": counts}))

    assert summary["final_score"] == "6-1"
    assert list(summary["statistics"]["me"]) == [stat.name.lower() for stat in Stat]
    assert (summary["statistics"]["me"]["points_won"], summary["statistics"]["opponent"]["points_won"]) == (25, 0)
    assert (summary["statistics"]["me"]["aces"], summary["statistics"]["opponent"]["aces"]) == (0, 3)


def test_counters_of_another_size_are_not_guessed() -> None:
    assert watch_summary_document(activity_with({"statistics": [1, 2, 3]}))["statistics"] is None
    assert watch_summary_document(activity_with({}))["statistics"] is None


def test_each_lap_gives_the_score_of_its_set() -> None:
    laps = ({"set_score": [7, 6, 7, 5]}, {"set_steps": 10}, {"set_score": [6]}, {"set_score": [2, 1, 0, 0]})

    summary = watch_summary_document(activity_with({}, laps))

    assert summary["set_scores"] == [
        {"games": [7, 6], "tie_break_points": [7, 5]},
        None,
        None,
        {"games": [2, 1], "tie_break_points": [0, 0]},
    ]
