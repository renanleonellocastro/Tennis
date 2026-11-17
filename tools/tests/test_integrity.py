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

    from tennis_export.set_laps import SetLaps

TIE_BREAK_ONLY = 4
TWO_SETS = "mmmm" * 12


def match_of(log: WatchLog, slots: Sequence[Slot] | None = None) -> Match:
    used = tuple(log.slots() if slots is None else slots)
    return Match(decode_setup(pack_setup()), PointLog(used, len(used), len(used), ()), replay(log.config, used))


def activity_with(session: dict[str, Any] | None = None) -> Activity:
    return Activity(records=(), laps=(), sessions=(Message(developer=session or {}),))


def laps(*fields: dict[str, Any]) -> SetLaps:
    """The laps of one set, each given by its developer fields."""
    return tuple(Message(developer=lap) for lap in fields)


def set_scores_match(match: Match, set_laps: Sequence[SetLaps] | None) -> bool | None:
    matches: bool | None = integrity_document(match, activity_with(), set_laps)["set_scores_match"]
    return matches


def test_a_log_the_replay_agrees_with_has_nothing_to_report() -> None:
    log = WatchLog().play("fm ff mmm")

    assert integrity_document(match_of(log), activity_with(), None) == {
        "score_mismatches": [],
        "statistics_match": None,
        "set_scores_match": None,
    }


def test_an_entry_whose_stored_server_or_score_differs_from_the_replay_is_listed() -> None:
    log = WatchLog().play("mmmm o")
    slots = log.slots()
    slots[1] = replace(slots[1], server=1)
    slots[4] = replace(slots[4], score=StoredScore((0, 2), (1, 0), (0, 0)))

    assert integrity_document(match_of(log, slots), activity_with(), None)["score_mismatches"] == [2, 5]


def test_point_counts_past_what_the_score_word_holds_still_agree() -> None:
    log = WatchLog(config(TIE_BREAK_ONLY)).play("mo" * 130)

    assert log.slots()[-1].score.points == (127, 127)
    assert integrity_document(match_of(log), activity_with(), None)["score_mismatches"] == []


def test_the_statistics_of_the_watch_are_compared_with_the_replayed_ones() -> None:
    match = match_of(WatchLog().play("mmmm"))
    same = activity_with({"statistics": list(match.replay.statistics.counts)})
    different = activity_with({"statistics": [0] * 30})

    assert integrity_document(match, same, None)["statistics_match"] is True
    assert integrity_document(match, different, None)["statistics_match"] is False


def test_the_set_score_of_the_lap_that_closed_each_set_is_compared() -> None:
    match = match_of(WatchLog().play(TWO_SETS[: 4 * 7]))

    assert set_scores_match(match, [laps({"set_score": [6, 0, 0, 0]})]) is True
    assert set_scores_match(match, [laps({"set_score": [6, 1, 0, 0]})]) is False


def test_a_set_that_was_played_again_is_compared_with_its_last_lap() -> None:
    match = match_of(WatchLog().play(TWO_SETS[: 4 * 7]))
    undone, played_again = {"set_score": [6, 2, 0, 0]}, {"set_score": [6, 0, 0, 0]}

    assert set_scores_match(match, [laps(undone, played_again)]) is True
    assert set_scores_match(match, [laps(played_again, undone)]) is False


def test_a_closed_set_without_a_lap_score_does_not_match() -> None:
    match = match_of(WatchLog().play(TWO_SETS))
    first_set = laps({"set_score": [6, 0, 0, 0]})

    assert set_scores_match(match, [first_set, laps({"set_steps": 10})]) is False
    assert set_scores_match(match, [first_set, laps()]) is False


def test_without_set_scores_or_laps_placed_in_time_there_is_nothing_to_compare() -> None:
    match = match_of(WatchLog().play(TWO_SETS))

    assert set_scores_match(match, [laps({}), laps({})]) is None
    assert set_scores_match(match, None) is None
