"""Fits a GPS track to a tennis court without calibration (docs/DATA_FORMAT.md explains the limits)."""

from __future__ import annotations

import math
from dataclasses import dataclass
from statistics import fmean, median
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Sequence

type Point = tuple[float, float]

EARTH_RADIUS_M = 6_371_000.0
RADIANS_PER_SEMICIRCLE = math.pi / 2**31
LOW_PERCENTILE = 0.05
HIGH_PERCENTILE = 0.95
HALF_TURN_DEGREES = 180.0


@dataclass(frozen=True)
class CourtFit:
    """Track positions in court meters as (across, along), with the court center at zero."""

    points: tuple[Point, ...]
    # The direction taken as the court length, counted counterclockwise from east, from 0 up to 180.
    rotation_degrees: float


def to_local_meters(track: Sequence[tuple[int, int]]) -> list[Point]:
    """Semicircles to meters east and north of the middle of the track (flat earth, fine at court size)."""
    latitudes = [latitude * RADIANS_PER_SEMICIRCLE for latitude, _ in track]
    longitudes = [longitude * RADIANS_PER_SEMICIRCLE for _, longitude in track]
    middle = (fmean(latitudes), fmean(longitudes))
    east_scale = EARTH_RADIUS_M * math.cos(middle[0])
    return [
        ((longitude - middle[1]) * east_scale, (latitude - middle[0]) * EARTH_RADIUS_M)
        for latitude, longitude in zip(latitudes, longitudes, strict=True)
    ]


def principal_angle(points: Sequence[Point]) -> float:
    """The direction in which the points spread the most, in radians from the east axis."""
    mean_x = fmean(x for x, _ in points)
    mean_y = fmean(y for _, y in points)
    spread_x = sum((x - mean_x) ** 2 for x, _ in points)
    spread_y = sum((y - mean_y) ** 2 for _, y in points)
    spread_xy = sum((x - mean_x) * (y - mean_y) for x, y in points)
    return 0.5 * math.atan2(2 * spread_xy, spread_x - spread_y)


def rotate(points: Sequence[Point], angle: float) -> list[Point]:
    """Turns the points so the direction of the angle becomes the second coordinate (along the court)."""
    cosine, sine = math.cos(angle), math.sin(angle)
    return [(x * sine - y * cosine, x * cosine + y * sine) for x, y in points]


def percentile(values: Sequence[float], fraction: float) -> float:
    ordered = sorted(values)
    return ordered[round(fraction * (len(ordered) - 1))]


def centered(points: Sequence[Point]) -> list[Point]:
    """Across: the median sits on the center line. Along: the two ends of the track sit at equal distance."""
    across = [point[0] for point in points]
    along = [point[1] for point in points]
    center_across = median(across)
    center_along = (percentile(along, LOW_PERCENTILE) + percentile(along, HIGH_PERCENTILE)) / 2
    return [(a - center_across, b - center_along) for a, b in zip(across, along, strict=True)]


def start_at_bottom(points: Sequence[Point]) -> list[Point]:
    """Half a turn when needed, so the end where the track starts is always the bottom one."""
    if points[0][1] <= 0:
        return list(points)
    return [(-across, -along) for across, along in points]


def fit_to_court(track: Sequence[tuple[int, int]]) -> CourtFit:
    local = to_local_meters(track)
    angle = principal_angle(local)
    points = start_at_bottom(centered(rotate(local, angle)))
    return CourtFit(tuple(points), math.degrees(angle) % HALF_TURN_DEGREES)
