"""Draws heatmap.png: where the GPS track spent its time, over a court outline. Approximate by nature."""

from __future__ import annotations

import math
from collections import Counter
from typing import TYPE_CHECKING, Any

from PIL import Image, ImageDraw

from tennis_export.court_fit import fit_to_court

if TYPE_CHECKING:
    from collections.abc import Sequence
    from pathlib import Path

    from tennis_export.court_fit import Point

type Bin = tuple[int, int]
type Color = tuple[int, int, int]
type Segment = tuple[Point, Point]

FILE_NAME = "heatmap.png"
METHOD = "principal_axis"
# Fewer positions than this say nothing about where the player stood.
MIN_TRACK_POINTS = 10

# The picture shows the court and the run back behind it, in bins of one meter.
HALF_WIDTH_M = 11
HALF_LENGTH_M = 20
PIXELS_PER_METER = 16
HEADER_PIXELS = 56
IMAGE_SIZE = (2 * HALF_WIDTH_M * PIXELS_PER_METER, HEADER_PIXELS + 2 * HALF_LENGTH_M * PIXELS_PER_METER)

HALF_COURT_LENGTH = 23.77 / 2
HALF_DOUBLES_WIDTH = 10.97 / 2
HALF_SINGLES_WIDTH = 8.23 / 2
SERVICE_LINE = 6.40

BACKGROUND: Color = (24, 44, 34)
HOT: Color = (255, 196, 0)
LINE: Color = (255, 255, 255)
LINE_WIDTH = 2
NET_WIDTH = 4
TITLE = "Approximate court heat map"
NOTE = "GPS track fitted without calibration. Start end at the bottom."
TITLE_POSITION = (8, 8)
NOTE_POSITION = (8, 34)
TITLE_SIZE = 18
NOTE_SIZE = 11

NET: Segment = ((-HALF_DOUBLES_WIDTH, 0.0), (HALF_DOUBLES_WIDTH, 0.0))
COURT_LINES: tuple[Segment, ...] = (
    ((-HALF_DOUBLES_WIDTH, -HALF_COURT_LENGTH), (HALF_DOUBLES_WIDTH, -HALF_COURT_LENGTH)),
    ((-HALF_DOUBLES_WIDTH, HALF_COURT_LENGTH), (HALF_DOUBLES_WIDTH, HALF_COURT_LENGTH)),
    ((-HALF_DOUBLES_WIDTH, -HALF_COURT_LENGTH), (-HALF_DOUBLES_WIDTH, HALF_COURT_LENGTH)),
    ((HALF_DOUBLES_WIDTH, -HALF_COURT_LENGTH), (HALF_DOUBLES_WIDTH, HALF_COURT_LENGTH)),
    ((-HALF_SINGLES_WIDTH, -HALF_COURT_LENGTH), (-HALF_SINGLES_WIDTH, HALF_COURT_LENGTH)),
    ((HALF_SINGLES_WIDTH, -HALF_COURT_LENGTH), (HALF_SINGLES_WIDTH, HALF_COURT_LENGTH)),
    ((-HALF_SINGLES_WIDTH, -SERVICE_LINE), (HALF_SINGLES_WIDTH, -SERVICE_LINE)),
    ((-HALF_SINGLES_WIDTH, SERVICE_LINE), (HALF_SINGLES_WIDTH, SERVICE_LINE)),
    ((0.0, -SERVICE_LINE), (0.0, SERVICE_LINE)),
)


def to_pixel(point: Point) -> tuple[float, float]:
    """Court meters to picture pixels; the picture grows downward, so the bottom end has the larger value."""
    across, along = point
    return (across + HALF_WIDTH_M) * PIXELS_PER_METER, HEADER_PIXELS + (HALF_LENGTH_M - along) * PIXELS_PER_METER


def bin_of(point: Point) -> Bin:
    return math.floor(point[0]), math.floor(point[1])


def is_in_view(place: Bin) -> bool:
    return -HALF_WIDTH_M <= place[0] < HALF_WIDTH_M and -HALF_LENGTH_M <= place[1] < HALF_LENGTH_M


def bin_counts(points: Sequence[Point]) -> Counter[Bin]:
    """How many positions fell in each one meter bin, leaving out the ones outside the picture."""
    return Counter(place for place in map(bin_of, points) if is_in_view(place))


def shade(share: float) -> Color:
    """From the background to the hot color; the square root keeps rarely visited bins visible."""
    weight = math.sqrt(share)
    blended = [round(cold + (hot - cold) * weight) for cold, hot in zip(BACKGROUND, HOT, strict=True)]
    return blended[0], blended[1], blended[2]


def draw_density(draw: ImageDraw.ImageDraw, counts: Counter[Bin]) -> None:
    busiest = max(counts.values(), default=1)
    for (across, along), count in counts.items():
        left, bottom = to_pixel((across, along))
        right, top = to_pixel((across + 1, along + 1))
        draw.rectangle((left, top, right, bottom), fill=shade(count / busiest))


def draw_court(draw: ImageDraw.ImageDraw) -> None:
    for start, end in COURT_LINES:
        draw.line((to_pixel(start), to_pixel(end)), fill=LINE, width=LINE_WIDTH)
    draw.line((to_pixel(NET[0]), to_pixel(NET[1])), fill=LINE, width=NET_WIDTH)


def draw_labels(draw: ImageDraw.ImageDraw) -> None:
    draw.text(TITLE_POSITION, TITLE, fill=LINE, font_size=TITLE_SIZE)
    draw.text(NOTE_POSITION, NOTE, fill=LINE, font_size=NOTE_SIZE)


def render(counts: Counter[Bin]) -> Image.Image:
    image = Image.new("RGB", IMAGE_SIZE, BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw_density(draw, counts)
    draw_court(draw)
    draw_labels(draw)
    return image


def write_heat_map(directory: Path, track: Sequence[tuple[int, int]]) -> dict[str, Any] | None:
    """Writes the picture and returns its entry for match.json; None when the track is too short."""
    if len(track) < MIN_TRACK_POINTS:
        return None
    fit = fit_to_court(track)
    counts = bin_counts(fit.points)
    render(counts).save(directory / FILE_NAME)
    return heat_map_document(len(track), counts.total(), fit.rotation_degrees)


def heat_map_document(track_points: int, points_drawn: int, rotation_degrees: float) -> dict[str, Any]:
    return {
        "file": FILE_NAME,
        "method": METHOD,
        "approximate": True,
        "track_points": track_points,
        "points_drawn": points_drawn,
        "rotation_degrees": round(rotation_degrees, 1),
    }
