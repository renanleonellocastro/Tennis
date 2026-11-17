"""Tests for tools/tennis_export/fit_reader.py, against files written by the FIT encoder."""

from __future__ import annotations

from typing import TYPE_CHECKING

import pytest

from fit_builder import START, FitBuilder, at
from tennis_export.errors import ExportError
from tennis_export.fit_reader import Message, read_activity

if TYPE_CHECKING:
    from pathlib import Path

POINT_LOG = [65537, 2, 3, 0, 0, 0, 0, 0, 0]
STATISTICS = list(range(30))


def full_file(tmp_path: Path) -> Path:
    builder = FitBuilder()
    builder.record(1, heart_rate=120, position=(1000, -2000), point_log=POINT_LOG)
    builder.record(2, heart_rate=121)
    builder.lap(600, set_score=[7, 6, 7, 5], set_steps=900, set_distance=700)
    builder.session(
        600,
        total_distance=812.5,
        log_size=1,
        match_setup=289,
        final_score="7-6(7-5)",
        statistics=STATISTICS,
        steps=1800,
        distance=1400,
    )
    return builder.write(tmp_path / "match.fit")


def test_records_carry_native_fields_by_name_and_the_point_log_as_a_list_of_words(tmp_path: Path) -> None:
    activity = read_activity(full_file(tmp_path))
    first, second = activity.records

    assert first.native["timestamp"] == at(1)
    assert (first.native["heart_rate"], first.native["position_lat"], first.native["position_long"]) == (
        120,
        1000,
        -2000,
    )
    assert first.developer == {"point_log": POINT_LOG}
    assert second.developer == {}
    assert "position_lat" not in second.native


def test_laps_carry_the_fields_of_a_set(tmp_path: Path) -> None:
    (lap,) = read_activity(full_file(tmp_path)).laps

    assert lap.developer == {"set_score": [7, 6, 7, 5], "set_steps": 900, "set_distance": 700}
    assert lap.native["total_timer_time"] == 600


def test_the_session_carries_the_summary_fields(tmp_path: Path) -> None:
    session = read_activity(full_file(tmp_path)).session

    assert session.developer == {
        "log_size": 1,
        "match_setup": 289,
        "final_score": "7-6(7-5)",
        "statistics": STATISTICS,
        "steps": 1800,
        "distance": 1400,
    }
    assert (session.native["sport"], session.native["start_time"]) == ("tennis", START)
    assert session.native["total_distance"] == 812.5


def test_a_file_without_a_session_reads_as_an_empty_one(tmp_path: Path) -> None:
    activity = read_activity(FitBuilder().record(1, heart_rate=100).write(tmp_path / "short.fit"))

    assert activity.session == Message()
    assert (len(activity.records), activity.laps) == (1, ())


def test_a_missing_file_is_reported(tmp_path: Path) -> None:
    with pytest.raises(ExportError, match=r"cannot read .*nothing\.fit: No such file"):
        read_activity(tmp_path / "nothing.fit")


def test_a_file_that_is_not_fit_is_reported(tmp_path: Path) -> None:
    path = tmp_path / "notes.fit"
    path.write_text("this is not a FIT file")

    with pytest.raises(ExportError, match=r"notes\.fit is not a readable FIT file"):
        read_activity(path)


def test_a_damaged_file_is_reported(tmp_path: Path) -> None:
    data = bytearray(full_file(tmp_path).read_bytes())
    data[-1] ^= 0xFF
    path = tmp_path / "damaged.fit"
    path.write_bytes(data)

    with pytest.raises(ExportError, match=r"damaged\.fit is not a readable FIT file"):
        read_activity(path)
