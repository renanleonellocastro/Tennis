"""Finds the Tennis match inside an activity: its setup, its point log and the replay of that log."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from tennis_export.errors import ExportError
from tennis_export.layout import (
    FORMAT_VERSION,
    LOG_SIZE_FIELD,
    MATCH_SETUP_FIELD,
    POINT_LOG_FIELD,
    Setup,
    decode_setup,
)
from tennis_export.point_log import PointLog, rebuild_point_log
from tennis_export.replay import Replay, replay
from tennis_export.rules import FORMATS, MatchConfig

if TYPE_CHECKING:
    from collections.abc import Sequence

    from tennis_export.fit_reader import Activity


@dataclass(frozen=True)
class Match:
    setup: Setup
    log: PointLog
    replay: Replay


def read_match(activity: Activity) -> Match | None:
    """None for an activity the Tennis app did not record (it carries no match setup)."""
    word = activity.session.developer.get(MATCH_SETUP_FIELD)
    if word is None:
        return None
    setup = decode_setup(word)
    log = rebuild_point_log(point_log_values(activity), activity.session.developer.get(LOG_SIZE_FIELD))
    return Match(setup, log, replay(config_of(setup), log.slots))


def point_log_values(activity: Activity) -> list[Sequence[int]]:
    return [record.developer[POINT_LOG_FIELD] for record in activity.records if POINT_LOG_FIELD in record.developer]


def config_of(setup: Setup) -> MatchConfig:
    if setup.version != FORMAT_VERSION:
        raise ExportError(f"data format version {setup.version} is not supported (this tool reads {FORMAT_VERSION})")
    if setup.match_format >= len(FORMATS):
        raise ExportError(f"match format code {setup.match_format} is not known")
    return MatchConfig(FORMATS[setup.match_format], setup.is_no_advantage, setup.first_server)
