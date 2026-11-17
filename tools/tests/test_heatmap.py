"""Tests for tools/tennis_export/court_fit.py and heatmap.py."""

from __future__ import annotations

import math
from typing import TYPE_CHECKING

import pytest
from PIL import Image

from fit_builder import track_from_meters
from tennis_export.court_fit import fit_to_court, percentile
from tennis_export.heatmap import BACKGROUND, HOT, IMAGE_SIZE, LINE, bin_counts, write_heat_map

if TYPE_CHECKING:
    from pathlib import Path

type Point = tuple[float, float]


def court_positions() -> list[Point]:
    """Twenty places behind the bottom baseline, then their mirror images at the top end, as (across, along)."""
    bottom = [(-4 + 8 * index / 19, -12 + 0.5 * (index % 5)) for index in range(20)]
    return bottom + [(-across, -along) for across, along in bottom]


def on_the_ground(positions: list[Point], court_direction_degrees: float) -> list[tuple[int, int]]:
    """Court positions as a GPS track, for a court whose length points in the given direction from east."""
    angle = math.radians(court_direction_degrees)
    cosine, sine = math.cos(angle), math.sin(angle)
    return track_from_meters(
        [(across * sine + along * cosine, -across * cosine + along * sine) for across, along in positions]
    )


@pytest.mark.parametrize("direction", [0.0, 30.0, 90.0, 120.0])
def test_the_longest_spread_of_the_track_is_taken_as_the_court_length(direction: float) -> None:
    fit = fit_to_court(on_the_ground(court_positions(), direction))

    assert abs((fit.rotation_degrees - direction + 90) % 180 - 90) < 0.5
    for fitted, expected in zip(fit.points, court_positions(), strict=True):
        assert fitted == pytest.approx(expected, abs=0.1)


def test_the_end_where_the_track_starts_is_put_at_the_bottom() -> None:
    top_first = court_positions()[::-1]

    fit = fit_to_court(on_the_ground(top_first, 30.0))

    assert fit.points[0][1] < 0
    assert fit.points[-1][1] > 0


def test_a_percentile_picks_the_value_at_that_share_of_the_sorted_list() -> None:
    assert percentile([5.0, 1.0, 3.0, 2.0, 4.0], 0.0) == 1.0
    assert percentile([5.0, 1.0, 3.0, 2.0, 4.0], 0.5) == 3.0
    assert percentile([5.0, 1.0, 3.0, 2.0, 4.0], 1.0) == 5.0


def test_positions_are_counted_in_one_meter_bins_and_left_out_past_the_edge() -> None:
    counts = bin_counts([(0.2, 0.2), (0.8, 0.9), (-0.5, 3.0), (11.0, 0.0), (0.0, -20.5)])

    assert counts == {(0, 0): 2, (-1, 3): 1}


def test_the_picture_shows_the_density_over_the_court_lines(tmp_path: Path) -> None:
    document = write_heat_map(tmp_path, on_the_ground(court_positions(), 30.0))

    assert document == {
        "file": "heatmap.png",
        "method": "principal_axis",
        "approximate": True,
        "track_points": 40,
        "points_drawn": 40,
        "rotation_degrees": pytest.approx(30.0, abs=0.5),
    }
    with Image.open(tmp_path / "heatmap.png") as image:
        pixels = image.convert("RGB")
        colors = {pixels.getpixel((x, y)) for x in range(image.width) for y in range(image.height)}
        assert image.size == IMAGE_SIZE
    assert {BACKGROUND, HOT, LINE} <= colors


def test_a_position_far_from_the_court_is_not_drawn(tmp_path: Path) -> None:
    positions = [*court_positions(), (0.0, 80.0)]

    document = write_heat_map(tmp_path, on_the_ground(positions, 0.0))

    assert document is not None
    assert (document["track_points"], document["points_drawn"]) == (41, 40)


def test_a_track_with_only_a_few_positions_gives_no_picture(tmp_path: Path) -> None:
    assert write_heat_map(tmp_path, on_the_ground(court_positions()[:9], 0.0)) is None
    assert not (tmp_path / "heatmap.png").exists()
