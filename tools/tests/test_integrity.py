"""Tests for tools/tennis_export/integrity.py."""

from __future__ import annotations

from dataclasses import replace
from typing import TYPE_CHECKING, Any

from match_script import WatchLog, config, pack_setup
from tennis_export.fit_reader import Activity, Message
from tennis_export.integrity import integrity_document
from tennis_export.layout import Slot, StoredScore, decode_setup
from tennis_export.match_reader import Match
from tennis_export.point_log import PointLog
from tennis_export.replay import replay

if TYPE_CHECKING:
    from collections.abc import Sequence

TIE_BREAK_ONLY = 4
TWO_SETS = "mmmm" * 12


def match_of(log: WatchLog, slots: Sequence[Slot] | None = None) -> Match:
    used = tuple(log.slots() if slots is None else slots)
    return Match(decode_setup(pack_setup()), PointLog(used, len(used), len(used), ()), replay(log.config, used))


def activity_with(session: dict[str, Any] | None = None, laps: Sequence[dict[str, Any]] = ()) -> Activity:
    lap_messages = tuple(Message(developer=lap) for lap in laps)
    return Activity(records=(), laps=lap_messages, sessions=(Message(developer=session or {}),))


def test_a_log_the_replay_agrees_with_has_nothing_to_report() -> None:
    log = WatchLog().play("fm ff mmm")

    assert integrity_document(match_of(log), activity_with()) == {
        "score_mismatches": [],
        "statistics_match": None,
        "set_scores_match": None,
    }


def test_an_entry_whose_stored_server_or_score_differs_from_the_replay_is_listed() -> None:
    log = WatchLog().play("mmmm o")
    slots = log.slots()
    slots[1] = replace(slots[1], server=1)
    slots[4] = replace(slots[4], score=StoredScore((0, 2), (1, 0), (0, 0)))

    assert integrity_document(match_of(log, slots), activity_with())["score_mismatches"] == [2, 5]


def test_point_counts_past_what_the_score_word_holds_still_agree() -> None:
    log = WatchLog(config(TIE_BREAK_ONLY)).play("mo" * 130)

    assert log.slots()[-1].score.points == (127, 127)
    assert integrity_document(match_of(log), activity_with())["score_mismatches"] == []


def test_the_statistics_of_the_watch_are_compared_with_the_replayed_ones() -> None:
    match = match_of(WatchLog().play("mmmm"))
    same = activity_with({"statistics": list(match.replay.statistics.counts)})
    different = activity_with({"statistics": [0] * 30})

    assert integrity_document(match, same)["statistics_match"] is True
    assert integrity_document(match, different)["statistics_match"] is False


def test_the_set_scores_of_the_laps_are_compared_for_closed_sets_only() -> None:
    match = match_of(WatchLog().play(TWO_SETS[: 4 * 7]))
    first_set = {"set_score": [6, 0, 0, 0]}

    assert integrity_document(match, activity_with(laps=[first_set, {"set_score": [1, 0, 0, 0]}]))["set_scores_match"]
    assert integrity_document(match, activity_with(laps=[{"set_score": [6, 1, 0, 0]}]))["set_scores_match"] is False


def test_a_closed_set_without_a_lap_score_does_not_match() -> None:
    match = match_of(WatchLog().play(TWO_SETS))
    laps: list[dict[str, Any]] = [{"set_score": [6, 0, 0, 0]}, {"set_steps": 10}]

    assert integrity_document(match, activity_with(laps=laps))["set_scores_match"] is False
    assert integrity_document(match, activity_with(laps=[{}, {}]))["set_scores_match"] is None
