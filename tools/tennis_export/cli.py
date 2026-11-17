"""Command line entry: tennis-export activity.fit --out directory."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import TYPE_CHECKING

from tennis_export.document import build_document, gps_track, write_document
from tennis_export.errors import ExportError
from tennis_export.fit_reader import read_activity
from tennis_export.heatmap import write_heat_map
from tennis_export.match_reader import read_match
from tennis_export.points_csv import write_points_csv

if TYPE_CHECKING:
    from collections.abc import Sequence

POINTS_FILE = "points.csv"
MATCH_FILE = "match.json"
EXIT_OK = 0
EXIT_ERROR = 2


def parse_arguments(argv: Sequence[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tennis-export",
        description="Turn a FIT activity recorded by the Tennis watch app into points.csv, match.json and heatmap.png.",
    )
    parser.add_argument("fit_file", type=Path, help="the activity file exported from Garmin Connect")
    parser.add_argument("--out", type=Path, help="output directory (default: <fit file name>-export next to it)")
    return parser.parse_args(argv)


def export(fit_file: Path, directory: Path) -> list[Path]:
    """Writes the export files into the directory and returns the ones it wrote."""
    activity = read_activity(fit_file)
    match = read_match(activity)
    directory.mkdir(parents=True, exist_ok=True)
    heat_map = write_heat_map(directory, gps_track(activity.records))
    write_points_csv(directory / POINTS_FILE, match.replay.rows if match else ())
    write_document(directory / MATCH_FILE, build_document(fit_file.name, activity, match, heat_map))
    names = [POINTS_FILE, MATCH_FILE] + ([heat_map["file"]] if heat_map else [])
    return [directory / name for name in names]


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(argv)
    directory = arguments.out or arguments.fit_file.with_name(f"{arguments.fit_file.stem}-export")
    try:
        written = export(arguments.fit_file, directory)
    except ExportError as error:
        print(f"tennis-export: {error}", file=sys.stderr)
        return EXIT_ERROR
    print("\n".join(str(path) for path in written))
    return EXIT_OK
