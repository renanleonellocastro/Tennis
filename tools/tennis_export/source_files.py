"""The activity files given on the command line, read and put in the order they were recorded."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import TYPE_CHECKING, Any

from tennis_export.errors import ExportError
from tennis_export.fit_reader import Activity, read_activity

if TYPE_CHECKING:
    from collections.abc import Sequence
    from pathlib import Path

START_TIME = "start_time"
ELAPSED_TIME = "total_elapsed_time"


@dataclass(frozen=True)
class SourceFile:
    path: Path
    activity: Activity

    @property
    def name(self) -> str:
        return self.path.name

    @property
    def start(self) -> datetime | None:
        start: datetime | None = self.activity.session.native.get(START_TIME)
        return start

    @property
    def elapsed_seconds(self) -> float | None:
        elapsed: float | None = self.activity.session.native.get(ELAPSED_TIME)
        return elapsed


def read_sources(paths: Sequence[Path]) -> list[SourceFile]:
    """One file is taken as it is; several are ordered by when they started, not by how they were given."""
    sources = [SourceFile(path, read_activity(path)) for path in paths]
    return sources if len(sources) == 1 else sorted(sources, key=start_of)


def start_of(source: SourceFile) -> datetime:
    if source.start is None:
        raise ExportError(f"{source.name} has no start time, so it cannot be put in order with the other files")
    return source.start


def end_of(source: SourceFile) -> datetime:
    """The start plus the time the file says it lasted; a file that does not say counts as lasting no time."""
    return start_of(source) + timedelta(seconds=source.elapsed_seconds or 0)


def source_documents(sources: Sequence[SourceFile]) -> list[dict[str, Any]]:
    return [source_document(source) for source in sources]


def source_document(source: SourceFile) -> dict[str, Any]:
    return {
        "file": source.name,
        "start_time": None if source.start is None else source.start.isoformat(),
        "elapsed_seconds": source.elapsed_seconds,
    }
