"""End to end tests for a match saved as several activity files: all of them in, one export out."""

from __future__ import annotations

import csv
import json
from typing import TYPE_CHECKING, Any

from fit_builder import FitBuilder, track_from_meters
from match_script import WatchLog, pack_setup
from tennis_export.cli import main
from tennis_export.replay import replay

if TYPE_CHECKING:
    from pathlib import Path

    import pytest

PROGRAM = "tennis-export"
SET = "mmmm" * 6
# The app was closed eight points into the second set and the match was resumed 350 seconds later.
BEFORE_CLOSE = len(SET) + 8
ENTRIES = 2 * len(SET)
FIRST_LASTS = 650
SECOND_BEGINS = 1000
TRACK = track_from_meters([(index % 9 - 4.0, (index % 23) - 11.0) for index in range(ENTRIES + 1)])


def first_part(tmp_path: Path, log: WatchLog) -> Path:
    """The whole first set and the start of the second, which is still open when the file ends."""
    builder = FitBuilder().records(log.record_values()[:BEFORE_CLOSE], TRACK[:BEFORE_CLOSE])
    builder.lap(480, set_score=[6, 0, 0, 0], set_steps=400, set_distance=300)
    builder.lap(FIRST_LASTS, opened=480, set_score=[2, 0, 0, 0], set_steps=100, set_distance=80)
    builder.session(FIRST_LASTS, log_size=BEFORE_CLOSE, match_setup=pack_setup(), steps=500, distance=380)
    return builder.write(tmp_path / "first.fit")


def second_part(tmp_path: Path, log: WatchLog) -> Path:
    """Starts with the log as the first file left it, then the rest of the second set."""
    values = log.record_values()[BEFORE_CLOSE - 1 :]
    builder = FitBuilder(SECOND_BEGINS).records(values, TRACK[BEFORE_CLOSE:])
    builder.lap(340, set_score=[6, 0, 0, 0], set_steps=300, set_distance=250)
    builder.session(
        350,
        log_size=ENTRIES,
        match_setup=pack_setup(),
        final_score="6-0 6-0",
        statistics=replay(log.config, log.slots()).statistics.counts,
        steps=300,
        distance=250,
    )
    return builder.write(tmp_path / "second.fit")


def resumed_match(tmp_path: Path) -> list[str]:
    """The two files of one match, the later one first, as a careless command line would give them."""
    log = WatchLog().play(SET + SET)
    return [str(second_part(tmp_path, log)), str(first_part(tmp_path, log))]


def exported(tmp_path: Path, fit_files: list[str]) -> tuple[dict[str, Any], list[dict[str, str]]]:
    assert main([*fit_files, "--out", str(tmp_path / "out")]) == 0
    document = json.loads((tmp_path / "out" / "match.json").read_text())
    with (tmp_path / "out" / "points.csv").open(newline="") as file:
        return document, list(csv.DictReader(file))


def refused(tmp_path: Path, capsys: pytest.CaptureFixture[str], fit_files: list[Path]) -> str:
    """The message of a command that failed and wrote nothing."""
    assert main([*map(str, fit_files), "--out", str(tmp_path / "out")]) == 2
    assert not (tmp_path / "out").exists()
    return capsys.readouterr().err


def match_file(tmp_path: Path, name: str, script: str, begins: float = 0.0, setup: int | None = None) -> Path:
    """A file of its own match, lasting a hundred seconds."""
    builder = FitBuilder(begins).records(WatchLog().play(script).record_values())
    return builder.session(100, match_setup=pack_setup() if setup is None else setup).write(tmp_path / name)


def test_the_files_are_ordered_by_start_time_and_listed_with_their_own_times(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, resumed_match(tmp_path))

    assert document["source"] == "first.fit"
    assert document["source_files"] == [
        {"file": "first.fit", "start_time": "2026-11-17T10:00:00+00:00", "elapsed_seconds": FIRST_LASTS},
        {"file": "second.fit", "start_time": "2026-11-17T10:16:40+00:00", "elapsed_seconds": 350},
    ]


def test_time_calories_steps_and_distance_are_added_up(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, resumed_match(tmp_path))

    assert document["activity"] == {
        "start_time": "2026-11-17T10:00:00+00:00",
        "sport": "tennis",
        "elapsed_seconds": 1000,
        "timer_seconds": 1000,
        "calories": 600,
        "heart_rate": {"average": 133, "max": 151, "min": 120, "samples": ENTRIES + 1},
        "steps": 800,
        "distance_m": 630,
        "has_gps": True,
    }
    assert document["heat_map"]["track_points"] == ENTRIES + 1


def test_the_point_log_is_joined_by_sequence_number_without_repeats(tmp_path: Path) -> None:
    document, rows = exported(tmp_path, resumed_match(tmp_path))

    assert [row["sequence"] for row in rows] == [str(sequence) for sequence in range(1, ENTRIES + 1)]
    assert document["point_log"] == {
        "entries_expected": ENTRIES,
        "entries_recovered": ENTRIES,
        "entries_replayed": ENTRIES,
        "missing_sequences": [],
    }
    assert document["match"]["score"]["text"] == "6-0 6-0"
    assert document["integrity"] == {"score_mismatches": [], "statistics_match": True, "set_scores_match": True}
    assert document["watch_summary"]["final_score"] == "6-0 6-0"
    assert len(document["watch_summary"]["set_scores"]) == 3


def test_a_set_split_by_the_resume_adds_up_its_lap_in_each_file(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, resumed_match(tmp_path))
    motion = [(played["steps"], played["distance_m"], played["laps"]) for played in document["match"]["sets"]]

    assert motion == [(400, 300, 1), (400, 330, 2)]


def test_the_default_directory_is_named_after_the_file_recorded_first(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    assert main(resumed_match(tmp_path)) == 0

    out = tmp_path / "first-export"
    printed = capsys.readouterr().out.splitlines()
    assert printed == [str(out / "points.csv"), str(out / "match.json"), str(out / "heatmap.png")]


def test_a_first_file_closed_before_any_point_is_joined(tmp_path: Path) -> None:
    first = FitBuilder().record(10).session(30, match_setup=pack_setup()).write(tmp_path / "first.fit")
    second = match_file(tmp_path, "second.fit", "mmmm", begins=60)

    document, rows = exported(tmp_path, [str(second), str(first)])

    assert (len(rows), document["activity"]["elapsed_seconds"]) == (4, 130)


def test_a_total_that_only_some_files_carry_is_unknown(tmp_path: Path) -> None:
    log = WatchLog().play("mmmm")
    first = FitBuilder().records(log.record_values()).session(100, match_setup=pack_setup(), steps=50)
    second = FitBuilder(200).session(40, total_distance=12.5, match_setup=pack_setup())

    document, rows = exported(tmp_path, [str(first.write(tmp_path / "a.fit")), str(second.write(tmp_path / "b.fit"))])

    assert (document["activity"]["steps"], document["activity"]["distance_m"]) == (None, None)
    assert (document["activity"]["calories"], len(rows)) == (600, 4)


def test_a_file_that_is_not_a_tennis_match_is_not_joined(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    run = FitBuilder(200).record(1, heart_rate=100).session(60).write(tmp_path / "run.fit")

    message = refused(tmp_path, capsys, [match_file(tmp_path, "match.fit", "mmmm"), run])

    problem = "run.fit carries no match of the Tennis app, so it cannot be joined with other files"
    assert message == f"{PROGRAM}: {problem}\n"


def test_files_with_different_match_settings_are_not_joined(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    other = match_file(tmp_path, "other.fit", "mmmm", begins=200, setup=pack_setup(no_advantage=True))

    message = refused(tmp_path, capsys, [match_file(tmp_path, "match.fit", "mmmm"), other])

    assert message == f"{PROGRAM}: match.fit and other.fit have different match settings, so they are not one match\n"


def test_files_that_overlap_in_time_are_not_joined(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    early = match_file(tmp_path, "early.fit", "mmmm")
    during = match_file(tmp_path, "during.fit", "mmmm", begins=50)

    assert "during.fit starts before early.fit ends" in refused(tmp_path, capsys, [during, early])
    assert "early.fit starts before early.fit ends" in refused(tmp_path, capsys, [early, early])


def test_a_later_file_with_a_point_log_of_its_own_is_not_joined(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    other = match_file(tmp_path, "other.fit", "oooo", begins=200)

    message = refused(tmp_path, capsys, [match_file(tmp_path, "match.fit", "mmmm"), other])

    assert message == (
        "tennis-export: the point log of other.fit does not continue the one of the files before it, "
        "so they are not one match\n"
    )


def test_a_file_without_a_start_time_cannot_be_ordered(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    bare = FitBuilder().record(1).write(tmp_path / "bare.fit")

    message = refused(tmp_path, capsys, [match_file(tmp_path, "match.fit", "mmmm"), bare])

    assert message == "tennis-export: bare.fit has no start time, so it cannot be put in order with the other files\n"
