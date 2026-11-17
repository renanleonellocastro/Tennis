"""Builds match.json: the activity, the match, how complete the point log is and the heat map."""

from __future__ import annotations

import json
from typing import TYPE_CHECKING, Any

from tennis_export.integrity import integrity_document
from tennis_export.layout import DISTANCE_FIELD, FINAL_SCORE_FIELD, FORMAT_VERSION, STEPS_FIELD
from tennis_export.match_document import match_document

if TYPE_CHECKING:
    from collections.abc import Sequence
    from pathlib import Path

    from tennis_export.fit_reader import Activity, Message
    from tennis_export.match_reader import Match

type Document = dict[str, Any]

HEART_RATE = "heart_rate"
LATITUDE = "position_lat"
LONGITUDE = "position_long"
NO_MATCH: Document = {"match": None, "point_log": None, "integrity": None, "watch_summary": None}


def build_document(source: str, activity: Activity, match: Match | None, heat_map: Document | None) -> Document:
    return {
        "format_version": FORMAT_VERSION,
        "source": source,
        "activity": activity_document(activity),
        **(NO_MATCH if match is None else match_sections(match, activity)),
        "heat_map": heat_map,
    }


def match_sections(match: Match, activity: Activity) -> Document:
    return {
        "match": match_document(match, activity.laps),
        "point_log": point_log_document(match),
        "integrity": integrity_document(match, activity),
        "watch_summary": {"final_score": activity.session.developer.get(FINAL_SCORE_FIELD)},
    }


def point_log_document(match: Match) -> Document:
    return {
        "entries_expected": match.log.expected,
        "entries_recovered": match.log.recovered,
        "entries_replayed": len(match.replay.rows),
        "missing_sequences": list(match.log.missing),
    }


def activity_document(activity: Activity) -> Document:
    session = activity.session
    return {
        "start_time": start_time_text(session),
        "sport": session.native.get("sport"),
        "elapsed_seconds": session.native.get("total_elapsed_time"),
        "timer_seconds": session.native.get("total_timer_time"),
        "calories": session.native.get("total_calories"),
        "heart_rate": heart_rate_document(activity.records),
        "steps": session.developer.get(STEPS_FIELD),
        "distance_m": session.developer.get(DISTANCE_FIELD, session.native.get("total_distance")),
        "has_gps": bool(gps_track(activity.records)),
    }


def start_time_text(session: Message) -> str | None:
    start_time = session.native.get("start_time")
    return None if start_time is None else start_time.isoformat()


def heart_rate_document(records: Sequence[Message]) -> Document | None:
    samples = [record.native[HEART_RATE] for record in records if record.native.get(HEART_RATE) is not None]
    if not samples:
        return None
    average = round(sum(samples) / len(samples))
    return {"average": average, "max": max(samples), "min": min(samples), "samples": len(samples)}


def gps_track(records: Sequence[Message]) -> list[tuple[int, int]]:
    """The positions of the activity in recording order, as FIT stores them (semicircles)."""
    return [(record.native[LATITUDE], record.native[LONGITUDE]) for record in records if has_position(record)]


def has_position(record: Message) -> bool:
    return record.native.get(LATITUDE) is not None and record.native.get(LONGITUDE) is not None


def write_document(path: Path, document: Document) -> None:
    path.write_text(json.dumps(document, indent=2) + "\n", encoding="utf-8")
