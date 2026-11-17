"""End to end tests for tools/tennis_export/cli.py: a FIT file in, the export files out."""

from __future__ import annotations

import csv
import json
from typing import TYPE_CHECKING, Any

import pytest

from fit_builder import FitBuilder, track_from_meters
from match_script import WatchLog, config, pack_setup
from tennis_export.cli import main
from tennis_export.replay import replay

if TYPE_CHECKING:
    from pathlib import Path

ONE_SET = 2
HOLD = "mmmm"
LOSE = "oooo"
# First set seven games to six with the tie break seven to zero, second set six games to zero.
FULL_MATCH = (HOLD + LOSE) * 6 + "m" * 7 + HOLD * 6
ENTRIES = len(FULL_MATCH)


def full_match_file(tmp_path: Path) -> Path:
    log = WatchLog().play(FULL_MATCH)
    track = track_from_meters([(index % 9 - 4.0, (index % 23) - 11.0) for index in range(ENTRIES)])
    builder = FitBuilder().records(log.record_values(), track)
    builder.lap(1100, set_score=[7, 6, 7, 0], set_steps=900, set_distance=700)
    builder.lap(1580, opened=1100, set_score=[6, 0, 0, 0], set_steps=500, set_distance=400)
    builder.session(
        1600,
        log_size=ENTRIES,
        match_setup=pack_setup(surface=1, kind=1),
        final_score="7-6(7-0) 6-0",
        statistics=replay(log.config, log.slots()).statistics.counts,
        steps=1400,
        distance=1100,
    )
    return builder.write(tmp_path / "match.fit")


def exported(tmp_path: Path, fit_file: Path) -> tuple[dict[str, Any], list[dict[str, str]]]:
    assert main([str(fit_file), "--out", str(tmp_path / "out")]) == 0
    document = json.loads((tmp_path / "out" / "match.json").read_text())
    with (tmp_path / "out" / "points.csv").open(newline="") as file:
        return document, list(csv.DictReader(file))


def test_the_command_prints_the_files_it_wrote(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    out = tmp_path / "out"

    assert main([str(full_match_file(tmp_path)), "--out", str(out)]) == 0

    assert capsys.readouterr().out.splitlines() == [
        str(out / "points.csv"),
        str(out / "match.json"),
        str(out / "heatmap.png"),
    ]
    assert (out / "heatmap.png").stat().st_size > 0


def test_the_document_describes_the_activity(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, full_match_file(tmp_path))

    assert (document["format_version"], document["source"]) == (1, "match.fit")
    assert document["activity"] == {
        "start_time": "2026-11-17T10:00:00+00:00",
        "sport": "tennis",
        "elapsed_seconds": 1600,
        "timer_seconds": 1600,
        "calories": 300,
        "heart_rate": {"average": 159, "max": 198, "min": 120, "samples": ENTRIES},
        "steps": 1400,
        "distance_m": 1100,
        "has_gps": True,
    }
    assert document["heat_map"]["track_points"] == ENTRIES


def test_the_document_describes_the_match(tmp_path: Path) -> None:
    match = exported(tmp_path, full_match_file(tmp_path))[0]["match"]

    assert match["config"] == {
        "format": "best_of_3",
        "no_advantage": False,
        "detail_level": "detailed",
        "first_server": "me",
    }
    assert match["tags"] == {"surface": "clay", "kind": "match"}
    assert (match["finished"], match["winner"]) == (True, "me")
    assert match["score"] == {
        "sets": [[7, 6], [6, 0]],
        "current_games": [0, 0],
        "current_points": ["0", "0"],
        "text": "7-6(7-0) 6-0",
    }


def test_the_document_lists_sets_and_games_with_their_durations(tmp_path: Path) -> None:
    match = exported(tmp_path, full_match_file(tmp_path))[0]["match"]

    assert match["sets"] == [
        {
            "set": 1,
            "games": [7, 6],
            "tie_break_points": [7, 0],
            "winner": "me",
            "duration_seconds": 1100,
            "steps": 900,
            "distance_m": 700,
            "laps": 1,
        },
        {
            "set": 2,
            "games": [6, 0],
            "tie_break_points": None,
            "winner": "me",
            "duration_seconds": 480,
            "steps": 500,
            "distance_m": 400,
            "laps": 1,
        },
    ]
    assert len(match["games"]) == 19
    assert match["games"][12] == {
        "set": 1,
        "game": 13,
        "server": "me",
        "winner": "me",
        "tie_break": True,
        "duration_seconds": 140,
    }


def test_the_document_carries_the_statistics_of_both_players(tmp_path: Path) -> None:
    statistics = exported(tmp_path, full_match_file(tmp_path))[0]["match"]["statistics"]

    assert statistics["me"] == {
        "service_points": 39,
        "first_serves_in": 39,
        "first_serve_points_won": 39,
        "second_serve_points_won": 0,
        "double_faults": 0,
        "service_games_played": 9,
        "service_games_won": 9,
        "break_point_chances": 3,
        "break_points_won": 3,
        "points_won": 55,
        "longest_run": 31,
        "winners": 0,
        "aces": 0,
        "errors_net": 0,
        "errors_out": 0,
        "first_serve_percent": 100,
        "second_serve_points": 0,
        "return_games_played": 9,
        "return_games_won": 3,
        "break_points_faced": 0,
        "break_points_saved": 0,
    }
    assert statistics["opponent"]["points_won"] == 24
    assert statistics["average_seconds_between_points"] == 20.0
    assert statistics["average_deciding_heart_rate"] is None


def test_the_document_says_how_complete_and_consistent_the_log_is(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, full_match_file(tmp_path))

    assert document["point_log"] == {
        "entries_expected": ENTRIES,
        "entries_recovered": ENTRIES,
        "entries_replayed": ENTRIES,
        "missing_sequences": [],
    }
    assert document["integrity"] == {"score_mismatches": [], "statistics_match": True, "set_scores_match": True}
    summary = document["watch_summary"]
    assert summary["final_score"] == "7-6(7-0) 6-0"
    assert summary["statistics"]["me"].items() <= document["match"]["statistics"]["me"].items()
    assert summary["statistics"]["opponent"].items() <= document["match"]["statistics"]["opponent"].items()
    assert summary["set_scores"] == [
        {"games": [7, 6], "tie_break_points": [7, 0]},
        {"games": [6, 0], "tie_break_points": [0, 0]},
    ]


def test_the_csv_has_one_row_for_each_entry(tmp_path: Path) -> None:
    _, rows = exported(tmp_path, full_match_file(tmp_path))

    assert len(rows) == ENTRIES
    assert rows[0] == {
        "sequence": "1",
        "time_s": "20",
        "heart_rate": "",
        "set": "1",
        "game": "1",
        "point": "1",
        "server": "me",
        "serve": "1",
        "kind": "point",
        "winner": "me",
        "ending": "none",
        "tie_break": "0",
        "break_point": "0",
        "set_point": "0",
        "match_point": "0",
        "score_me": "15",
        "score_opponent": "0",
        "games_me": "0",
        "games_opponent": "0",
        "sets_me": "0",
        "sets_opponent": "0",
        "closes": "",
    }
    assert [rows[index]["closes"] for index in (3, 54, 78)] == ["game", "set", "match"]
    assert (rows[54]["tie_break"], rows[54]["set_point"], rows[54]["sets_me"]) == ("1", "1", "1")
    assert (rows[78]["match_point"], rows[78]["server"], rows[78]["game"], rows[78]["point"]) == ("1", "me", "6", "4")


def test_faults_and_double_faults_have_their_own_kind_of_row(tmp_path: Path) -> None:
    log = WatchLog().add(0).add(1, ending=2, heart_rate=141).add(0).add(0)
    builder = FitBuilder().records(log.record_values()).session(100, match_setup=pack_setup())

    _, rows = exported(tmp_path, builder.write(tmp_path / "faults.fit"))

    assert [row["kind"] for row in rows] == ["fault", "point", "fault", "double_fault"]
    assert [row["winner"] for row in rows] == ["", "me", "", "opponent"]
    assert [row["serve"] for row in rows] == ["1", "2", "1", "2"]
    assert (rows[1]["ending"], rows[1]["heart_rate"]) == ("ace", "141")


def test_ratios_with_nothing_to_divide_are_null_and_not_zero(tmp_path: Path) -> None:
    builder = FitBuilder().records(WatchLog().add(1).record_values()).session(100, match_setup=pack_setup())

    statistics = exported(tmp_path, builder.write(tmp_path / "one_point.fit"))[0]["match"]["statistics"]

    assert (statistics["me"]["first_serve_percent"], statistics["opponent"]["first_serve_percent"]) == (100, None)
    assert statistics["average_seconds_between_points"] is None
    assert statistics["average_deciding_heart_rate"] is None


def test_a_match_that_was_stopped_early_keeps_what_was_played(tmp_path: Path) -> None:
    log = WatchLog(config(ONE_SET, no_advantage=True, first_server=1)).play(HOLD + "mm")
    setup = pack_setup(ONE_SET, no_advantage=True, detailed=False, first_server=1, surface=3, kind=2)
    builder = FitBuilder().records(log.record_values()).session(200, total_distance=512.5, match_setup=setup)

    document, _ = exported(tmp_path, builder.write(tmp_path / "early.fit"))
    match = document["match"]

    assert match["config"] == {
        "format": "one_set",
        "no_advantage": True,
        "detail_level": "simple",
        "first_server": "opponent",
    }
    assert match["tags"] == {"surface": "grass", "kind": "friendly"}
    assert (match["finished"], match["winner"], match["sets"]) == (False, None, [])
    assert match["score"] == {"sets": [], "current_games": [1, 0], "current_points": ["30", "0"], "text": "1-0"}
    assert document["integrity"] == {"score_mismatches": [], "statistics_match": None, "set_scores_match": None}
    assert document["watch_summary"] == {"final_score": None, "statistics": None, "set_scores": []}
    assert (document["activity"]["steps"], document["activity"]["distance_m"]) == (None, 512.5)
    assert (document["activity"]["has_gps"], document["heat_map"]) == (False, None)


def test_a_match_stopped_right_after_a_set_shows_no_empty_open_set(tmp_path: Path) -> None:
    log = WatchLog().play(HOLD * 6)
    builder = FitBuilder().records(log.record_values()).session(200, match_setup=pack_setup())

    document, _ = exported(tmp_path, builder.write(tmp_path / "set.fit"))

    assert (document["match"]["finished"], document["match"]["score"]["text"]) == (False, "6-0")


def test_a_set_that_has_only_points_is_an_open_set(tmp_path: Path) -> None:
    log = WatchLog().play(HOLD * 6 + "m")
    builder = FitBuilder().records(log.record_values()).session(200, match_setup=pack_setup())

    document, _ = exported(tmp_path, builder.write(tmp_path / "set.fit"))

    assert document["match"]["score"]["text"] == "6-0 0-0"


def test_a_set_without_a_lap_has_no_steps_or_distance(tmp_path: Path) -> None:
    log = WatchLog(config(ONE_SET)).play(HOLD * 6)
    builder = FitBuilder().records(log.record_values()).session(500, match_setup=pack_setup(ONE_SET))

    document, _ = exported(tmp_path, builder.write(tmp_path / "no_laps.fit"))

    first_set = document["match"]["sets"][0]
    assert (first_set["steps"], first_set["distance_m"], first_set["laps"]) == (None, None, 0)
    assert document["match"]["tags"] == {"surface": None, "kind": None}


def test_a_set_that_was_undone_and_played_again_is_still_one_set(tmp_path: Path) -> None:
    log = WatchLog().play(HOLD * 6)
    values = log.record_values()
    values.append(log.undo().record_value())
    values += [log.play(letter).record_value() for letter in "om" + HOLD * 6]
    builder = FitBuilder().records(values)
    builder.lap(480, set_score=[6, 0, 0, 0], set_steps=400, set_distance=300)
    builder.lap(540, opened=480, set_score=[6, 0, 0, 0], set_steps=50, set_distance=40)
    builder.lap(1020, opened=540, set_score=[6, 0, 0, 0], set_steps=450, set_distance=350)
    builder.session(1020, log_size=len(log.entries), match_setup=pack_setup())

    document, _ = exported(tmp_path, builder.write(tmp_path / "replayed.fit"))
    motion = [(played["steps"], played["distance_m"], played["laps"]) for played in document["match"]["sets"]]

    assert motion == [(450, 340, 2), (450, 350, 1)]
    assert document["integrity"]["set_scores_match"] is True


def test_laps_without_times_leave_the_steps_of_every_set_unknown(tmp_path: Path) -> None:
    log = WatchLog(config(ONE_SET)).play(HOLD * 6)
    builder = FitBuilder().records(log.record_values())
    builder.untimed_lap(480, set_score=[6, 0, 0, 0], set_steps=400)
    builder.session(500, match_setup=pack_setup(ONE_SET))

    document, _ = exported(tmp_path, builder.write(tmp_path / "bare_lap.fit"))
    first_set = document["match"]["sets"][0]

    assert (first_set["steps"], first_set["distance_m"], first_set["laps"]) == (None, None, None)
    assert document["integrity"]["set_scores_match"] is None


def test_lost_records_are_reported_and_only_the_start_of_the_log_is_replayed(tmp_path: Path) -> None:
    values = WatchLog().play(HOLD + LOSE).record_values()
    builder = FitBuilder().records(values[:2] + values[5:]).session(200, log_size=9, match_setup=pack_setup())

    document, rows = exported(tmp_path, builder.write(tmp_path / "gaps.fit"))

    assert document["point_log"] == {
        "entries_expected": 9,
        "entries_recovered": 7,
        "entries_replayed": 2,
        "missing_sequences": [3, 9],
    }
    assert [row["sequence"] for row in rows] == ["1", "2"]


def test_an_activity_from_another_app_exports_its_activity_data_only(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    builder = FitBuilder().record(1, heart_rate=100).record(2).session(60)
    fit_file = builder.write(tmp_path / "run.fit")

    assert main([str(fit_file)]) == 0

    out = tmp_path / "run-export"
    document = json.loads((out / "match.json").read_text())
    assert capsys.readouterr().out.splitlines() == [str(out / "points.csv"), str(out / "match.json")]
    assert (document["match"], document["point_log"], document["integrity"]) == (None, None, None)
    assert (document["watch_summary"], document["heat_map"]) == (None, None)
    assert document["activity"]["heart_rate"] == {"average": 100, "max": 100, "min": 100, "samples": 1}
    assert (out / "points.csv").read_text().splitlines() == [
        "sequence,time_s,heart_rate,set,game,point,server,serve,kind,winner,ending,tie_break,break_point,"
        "set_point,match_point,score_me,score_opponent,games_me,games_opponent,sets_me,sets_opponent,closes"
    ]


def test_a_file_without_a_session_or_heart_rate_still_exports(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, FitBuilder().record(1).write(tmp_path / "bare.fit"))

    assert document["activity"] == {
        "start_time": None,
        "sport": None,
        "elapsed_seconds": None,
        "timer_seconds": None,
        "calories": None,
        "heart_rate": None,
        "steps": None,
        "distance_m": None,
        "has_gps": False,
    }


def test_a_short_track_counts_as_gps_but_gives_no_heat_map(tmp_path: Path) -> None:
    builder = FitBuilder().record(1, position=(1000, 2000)).session(60)

    document, _ = exported(tmp_path, builder.write(tmp_path / "short.fit"))

    assert (document["activity"]["has_gps"], document["heat_map"]) == (True, None)


@pytest.mark.parametrize(
    ("setup", "message"),
    [
        (pack_setup(version=2), "tennis-export: data format version 2 is not supported (this tool reads 1)\n"),
        (pack_setup(7), "tennis-export: match format code 7 is not known\n"),
    ],
)
def test_a_setup_this_tool_does_not_understand_is_an_error(
    tmp_path: Path, capsys: pytest.CaptureFixture[str], setup: int, message: str
) -> None:
    fit_file = FitBuilder().session(60, match_setup=setup).write(tmp_path / "future.fit")

    assert main([str(fit_file), "--out", str(tmp_path / "out")]) == 2
    assert capsys.readouterr().err == message
    assert not (tmp_path / "out").exists()


def test_a_file_that_cannot_be_read_is_an_error(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    assert main([str(tmp_path / "nothing.fit")]) == 2
    assert "cannot read" in capsys.readouterr().err
