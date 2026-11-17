"""Command line entry: tennis-export activity.fit [more.fit ...] --out directory."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import TYPE_CHECKING

from tennis_export.document import build_document, gps_track, write_document
from tennis_export.errors import ExportError
from tennis_export.heatmap import write_heat_map
from tennis_export.match_reader import read_match
from tennis_export.merge import merge_activities
from tennis_export.points_csv import write_points_csv
from tennis_export.same_match import require_same_match
from tennis_export.source_files import read_sources

if TYPE_CHECKING:
    from collections.abc import Sequence

POINTS_FILE = "points.csv"
MATCH_FILE = "match.json"
FIT_FILES_HELP = (
    "an activity file exported from Garmin Connect; a match that was closed and resumed is saved as "
    "several files, give them all and they are joined into one export"
)
EXIT_OK = 0
EXIT_ERROR = 2


def parse_arguments(argv: Sequence[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tennis-export",
        description="Turn a FIT activity recorded by the Tennis watch app into points.csv, match.json and heatmap.png.",
    )
    parser.add_argument("fit_files", type=Path, nargs="+", metavar="fit_file", help=FIT_FILES_HELP)
    parser.add_argument("--out", type=Path, help="output directory (default: <first fit file name>-export next to it)")
    return parser.parse_args(argv)


def export(fit_files: Sequence[Path], directory: Path | None) -> list[Path]:
    """Writes one set of export files for the match the files hold together and returns the files it wrote."""
    sources = read_sources(fit_files)
    require_same_match(sources)
    activity = merge_activities([source.activity for source in sources])
    match = read_match(activity)
    directory = directory or default_directory(sources[0].path)
    directory.mkdir(parents=True, exist_ok=True)
    heat_map = write_heat_map(directory, gps_track(activity.records))
    write_points_csv(directory / POINTS_FILE, match.replay.rows if match else ())
    write_document(directory / MATCH_FILE, build_document(sources, activity, match, heat_map))
    names = [POINTS_FILE, MATCH_FILE] + ([heat_map["file"]] if heat_map else [])
    return [directory / name for name in names]


def default_directory(first_file: Path) -> Path:
    """Next to the file that was recorded first, named after it."""
    return first_file.with_name(f"{first_file.stem}-export")


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(argv)
    try:
        written = export(arguments.fit_files, arguments.out)
    except ExportError as error:
        print(f"tennis-export: {error}", file=sys.stderr)
        return EXIT_ERROR
    print("\n".join(str(path) for path in written))
    return EXIT_OK
