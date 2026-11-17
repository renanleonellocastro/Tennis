"""Command line entry: tennis-export activity.fit [more.fit ...] --out directory."""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from functools import partial
from pathlib import Path
from typing import TYPE_CHECKING, Any

from tennis_export.document import build_document, build_practice_document, gps_track, write_document
from tennis_export.errors import ExportError
from tennis_export.heatmap import write_heat_map
from tennis_export.match_reader import read_match
from tennis_export.merge import merge_activities
from tennis_export.points_csv import write_points_csv
from tennis_export.practice import read_practice
from tennis_export.practice_document import write_blocks_csv
from tennis_export.same_match import require_same_match
from tennis_export.source_files import read_sources

if TYPE_CHECKING:
    from collections.abc import Callable, Sequence

    from tennis_export.fit_reader import Activity
    from tennis_export.match_reader import Match
    from tennis_export.practice import Block
    from tennis_export.source_files import SourceFile

POINTS_FILE = "points.csv"
MATCH_FILE = "match.json"
BLOCKS_FILE = "blocks.csv"
PRACTICE_FILE = "practice.json"
FIT_FILES_HELP = (
    "an activity file exported from Garmin Connect; a match that was closed and resumed is saved as "
    "several files, give them all and they are joined into one export"
)
DESCRIPTION = (
    "Turn a FIT activity recorded by the Tennis watch app into points.csv, match.json and heatmap.png, "
    "or a practice into blocks.csv and practice.json."
)
EXIT_OK = 0
EXIT_ERROR = 2


def parse_arguments(argv: Sequence[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="tennis-export",
        description=DESCRIPTION,
    )
    parser.add_argument("fit_files", type=Path, nargs="+", metavar="fit_file", help=FIT_FILES_HELP)
    parser.add_argument("--out", type=Path, help="output directory (default: <first fit file name>-export next to it)")
    return parser.parse_args(argv)


@dataclass(frozen=True)
class Job:
    """What every kind of export starts from: the files, what they hold together and where the result goes."""

    sources: Sequence[SourceFile]
    activity: Activity
    directory: Path
    heat_map: dict[str, Any] | None


def export(fit_files: Sequence[Path], directory: Path | None) -> list[Path]:
    """Writes one set of export files for what the files hold together and returns the files it wrote."""
    sources = read_sources(fit_files)
    require_same_match(sources)
    activity = merge_activities([source.activity for source in sources])
    write_data_files = data_writer(activity)
    directory = directory or default_directory(sources[0].path)
    directory.mkdir(parents=True, exist_ok=True)
    job = Job(sources, activity, directory, write_heat_map(directory, gps_track(activity.records)))
    names = write_data_files(job) + ([job.heat_map["file"]] if job.heat_map else [])
    return [directory / name for name in names]


def data_writer(activity: Activity) -> Callable[[Job], list[str]]:
    """A file with a match setup is a match; without one, block counters on the laps make it a practice.

    The file is understood here, before anything is written, so a file that is refused leaves nothing behind.
    """
    match = read_match(activity)
    blocks = None if match else read_practice(activity)
    return partial(write_match, match=match) if blocks is None else partial(write_practice, blocks=blocks)


def write_match(job: Job, match: Match | None) -> list[str]:
    write_points_csv(job.directory / POINTS_FILE, match.replay.rows if match else ())
    document = build_document(job.sources, job.activity, match, job.heat_map)
    write_document(job.directory / MATCH_FILE, document)
    return [POINTS_FILE, MATCH_FILE]


def write_practice(job: Job, blocks: Sequence[Block]) -> list[str]:
    document = build_practice_document(job.sources, job.activity, blocks, job.heat_map)
    write_blocks_csv(job.directory / BLOCKS_FILE, document["practice"])
    write_document(job.directory / PRACTICE_FILE, document)
    return [BLOCKS_FILE, PRACTICE_FILE]


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
