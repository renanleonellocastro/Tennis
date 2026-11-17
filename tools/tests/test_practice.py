"""Tests for the practice export: tools/tennis_export/practice.py, practice_document.py and the command."""

from __future__ import annotations

import csv
import json
from typing import TYPE_CHECKING, Any

import pytest

from fit_builder import FitBuilder
from match_script import pack_setup
from tennis_export.cli import main
from tennis_export.fit_reader import read_activity
from tennis_export.practice import read_practice, success_percent

if TYPE_CHECKING:
    from pathlib import Path


def practice_file(tmp_path: Path, last: tuple[int, int] = (0, 0), laps: int | None = 3) -> Path:
    """Two closed blocks, then the lap that saving closed, with the counts given."""
    builder = FitBuilder().record(10, heart_rate=130)
    builder.lap(60, block_hits=8, block_misses=2, set_steps=40, set_distance=30)
    builder.lap(100, opened=60, block_hits=1, block_misses=2, set_steps=10, set_distance=5)
    builder.lap(130, opened=100, block_hits=last[0], block_misses=last[1], set_steps=0, set_distance=0)
    return builder.session(130, laps=laps, steps=50, distance=35).write(tmp_path / "practice.fit")


def exported(tmp_path: Path, fit_file: Path) -> tuple[dict[str, Any], list[list[str]]]:
    assert main([str(fit_file), "--out", str(tmp_path / "out")]) == 0
    document = json.loads((tmp_path / "out" / "practice.json").read_text())
    with (tmp_path / "out" / "blocks.csv").open(newline="") as file:
        return document, list(csv.reader(file))


def test_a_practice_is_exported_as_blocks_not_as_a_match(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    out = tmp_path / "out"

    assert main([str(practice_file(tmp_path)), "--out", str(out)]) == 0

    assert capsys.readouterr().out.splitlines() == [str(out / "blocks.csv"), str(out / "practice.json")]
    assert sorted(path.name for path in out.iterdir()) == ["blocks.csv", "practice.json"]


def test_the_document_lists_every_block_and_the_totals(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, practice_file(tmp_path))

    assert list(document) == ["format_version", "source", "source_files", "activity", "practice", "heat_map"]
    assert (document["source"], document["activity"]["steps"], document["heat_map"]) == ("practice.fit", 50, None)
    first = {"block": 1, "hits": 8, "misses": 2, "shots": 10, "success_percent": 80}
    second = {"block": 2, "hits": 1, "misses": 2, "shots": 3, "success_percent": 33}
    assert document["practice"]["blocks"] == [
        first | {"duration_seconds": 60, "steps": 40, "distance_m": 30},
        second | {"duration_seconds": 40, "steps": 10, "distance_m": 5},
    ]
    assert document["practice"]["totals"] == {
        "blocks": 2,
        "hits": 9,
        "misses": 4,
        "shots": 13,
        "success_percent": 69,
    }


def test_the_table_has_a_row_for_each_block_and_a_total_row(tmp_path: Path) -> None:
    _, rows = exported(tmp_path, practice_file(tmp_path))

    assert rows == [
        ["block", "hits", "misses", "shots", "success_percent", "duration_seconds", "steps", "distance_m"],
        ["1", "8", "2", "10", "80", "60.0", "40", "30"],
        ["2", "1", "2", "3", "33", "40.0", "10", "5"],
        ["total", "9", "4", "13", "69", "", "", ""],
    ]


def test_the_lap_closed_by_saving_is_a_block_when_something_was_counted_in_it(tmp_path: Path) -> None:
    document, rows = exported(tmp_path, practice_file(tmp_path, last=(0, 4)))

    assert document["practice"]["blocks"][2] == {
        "block": 3,
        "hits": 0,
        "misses": 4,
        "shots": 4,
        "success_percent": 0,
        "duration_seconds": 30,
        "steps": 0,
        "distance_m": 0,
    }
    assert rows[-1][:5] == ["total", "9", "8", "17", "53"]


def test_laps_of_activities_thrown_away_before_this_one_are_left_out(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, practice_file(tmp_path, last=(5, 5), laps=2))

    assert [block["hits"] for block in document["practice"]["blocks"]] == [1, 5]
    assert document["practice"]["totals"]["blocks"] == 2


def test_every_lap_counts_when_the_session_does_not_say_how_many_it_has(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, practice_file(tmp_path, last=(5, 5), laps=None))

    assert document["practice"]["totals"]["blocks"] == 3


def test_a_session_that_claims_more_laps_than_the_file_has_takes_them_all(tmp_path: Path) -> None:
    document, _ = exported(tmp_path, practice_file(tmp_path, laps=9))

    assert document["practice"]["totals"]["blocks"] == 2


def test_a_practice_saved_before_anything_was_counted_has_no_blocks(tmp_path: Path) -> None:
    builder = FitBuilder().lap(20, block_hits=0, block_misses=0)
    document, rows = exported(tmp_path, builder.session(20, laps=1).write(tmp_path / "empty.fit"))

    assert document["practice"] == {
        "blocks": [],
        "totals": {"blocks": 0, "hits": 0, "misses": 0, "shots": 0, "success_percent": None},
    }
    assert rows[1:] == [["total", "0", "0", "0", "", "", "", ""]]


def test_a_block_without_the_miss_counter_has_no_misses(tmp_path: Path) -> None:
    builder = FitBuilder().lap(20, block_hits=3)
    document, _ = exported(tmp_path, builder.session(20).write(tmp_path / "hits.fit"))

    assert document["practice"]["totals"] == {
        "blocks": 1,
        "hits": 3,
        "misses": 0,
        "shots": 3,
        "success_percent": 100,
    }


def test_a_file_whose_laps_carry_no_counters_is_not_a_practice(tmp_path: Path) -> None:
    builder = FitBuilder().lap(60, set_steps=40)
    activity = read_activity(builder.session(60, laps=1).write(tmp_path / "walk.fit"))

    assert read_practice(activity) is None
    assert read_practice(read_activity(FitBuilder().session(60).write(tmp_path / "bare.fit"))) is None


def test_a_file_with_a_match_setup_stays_a_match_even_with_counters_on_its_laps(tmp_path: Path) -> None:
    builder = FitBuilder().lap(60, block_hits=3, block_misses=1)
    fit_file = builder.session(60, match_setup=pack_setup()).write(tmp_path / "match.fit")
    out = tmp_path / "out"

    assert main([str(fit_file), "--out", str(out)]) == 0

    assert sorted(path.name for path in out.iterdir()) == ["match.json", "points.csv"]


def test_two_practice_files_are_not_joined(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    first = practice_file(tmp_path)
    second = first.with_name("second.fit")
    second.write_bytes(first.read_bytes())

    assert main([str(first), str(second), "--out", str(tmp_path / "out")]) == 2

    assert "carries no match of the Tennis app" in capsys.readouterr().err
    assert not (tmp_path / "out").exists()


@pytest.mark.parametrize(
    ("hits", "shots", "percent"),
    [(0, 0, None), (0, 5, 0), (5, 5, 100), (1, 3, 33), (2, 3, 67), (1, 8, 13), (1, 200, 1), (104, 131, 79)],
)
def test_the_success_rate_rounds_half_up_like_the_watch(hits: int, shots: int, percent: int | None) -> None:
    assert success_percent(hits, shots) == percent
