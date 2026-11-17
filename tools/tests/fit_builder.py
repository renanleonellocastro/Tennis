"""Builds FIT activity files for the tests with the encoder of the Garmin SDK (real bytes, no mocks)."""

from __future__ import annotations

import math
from datetime import UTC, datetime, timedelta
from typing import TYPE_CHECKING, Any, Self

from garmin_fit_sdk import Encoder

if TYPE_CHECKING:
    from collections.abc import Sequence
    from pathlib import Path

FILE_ID = 0
SESSION = 18
LAP = 19
RECORD = 20
FIELD_DESCRIPTION = 206
DEVELOPER_DATA_ID = 207

UINT8 = 0x02
STRING = 0x07
UINT16 = 0x84
UINT32 = 0x86

START = datetime(2026, 11, 17, 10, 0, 0, tzinfo=UTC)
APPLICATION_ID = list(bytes.fromhex("44e11bf664944c749699d065b7d3378b"))
DEVELOPER: Any = {"application_id": APPLICATION_ID, "developer_data_index": 0}

# Field number, name, base type and the message that carries it, as docs/DATA_FORMAT.md lists them.
FIELDS = (
    (0, "point_log", UINT32, RECORD),
    (1, "log_size", UINT16, SESSION),
    (2, "match_setup", UINT32, SESSION),
    (3, "final_score", STRING, SESSION),
    (4, "statistics", UINT16, SESSION),
    (5, "steps", UINT32, SESSION),
    (6, "distance", UINT32, SESSION),
    (7, "set_score", UINT8, LAP),
    (8, "set_steps", UINT32, LAP),
    (9, "set_distance", UINT32, LAP),
)
FIELD_NUMBERS = {name: number for number, name, _, _ in FIELDS}


EARTH_RADIUS_M = 6_371_000.0
SEMICIRCLES_PER_RADIAN = 2**31 / math.pi
ORIGIN_LATITUDE = math.radians(-23.55)
ORIGIN_LONGITUDE = math.radians(-46.63)
SECONDS_BETWEEN_RECORDS = 20


def track_from_meters(points: Sequence[tuple[float, float]]) -> list[tuple[int, int]]:
    """Positions given in meters east and north of a fixed place, as FIT semicircles (latitude, longitude)."""
    east_scale = EARTH_RADIUS_M * math.cos(ORIGIN_LATITUDE)
    return [
        (
            round((ORIGIN_LATITUDE + north / EARTH_RADIUS_M) * SEMICIRCLES_PER_RADIAN),
            round((ORIGIN_LONGITUDE + east / east_scale) * SEMICIRCLES_PER_RADIAN),
        )
        for east, north in points
    ]


def at(seconds: float) -> datetime:
    return START + timedelta(seconds=seconds)


class FitBuilder:
    """Writes messages in call order; developer values are given by field name and None means absent.

    Every time is given in seconds from the start of the file, which is `begins` seconds after START.
    """

    def __init__(self, begins: float = 0.0) -> None:
        self._begins = begins
        self._encoder = Encoder()
        created = {"type": "activity", "manufacturer": 1, "time_created": self._at(0)}
        self._encoder.write_mesg({"mesg_num": FILE_ID, **created})
        self._encoder.write_mesg({"mesg_num": DEVELOPER_DATA_ID, **DEVELOPER})
        for number, name, base_type, message in FIELDS:
            self._describe(number, name, base_type, message)

    def _describe(self, number: int, name: str, base_type: int, message: int) -> None:
        description: Any = {
            "developer_data_index": 0,
            "field_definition_number": number,
            "fit_base_type_id": base_type,
            "field_name": name,
            "native_mesg_num": message,
        }
        self._encoder.write_mesg({"mesg_num": FIELD_DESCRIPTION, **description})
        self._encoder.add_developer_field(number, DEVELOPER, description)

    def _at(self, seconds: float) -> datetime:
        return at(self._begins + seconds)

    def _write(self, message: int, native: dict[str, Any], developer: dict[str, Any]) -> Self:
        fields = {FIELD_NUMBERS[name]: value for name, value in developer.items() if value is not None}
        self._encoder.write_mesg({"mesg_num": message, **native, "developer_fields": fields})
        return self

    def record(
        self,
        seconds: float,
        *,
        heart_rate: int | None = None,
        position: tuple[int, int] | None = None,
        point_log: list[int] | None = None,
    ) -> Self:
        latitude, longitude = position or (None, None)
        native = {"heart_rate": heart_rate, "position_lat": latitude, "position_long": longitude}
        return self._write(RECORD, {"timestamp": self._at(seconds), **native}, {"point_log": point_log})

    def lap(self, seconds: float, *, opened: float = 0.0, **developer: Any) -> Self:
        """A lap that was opened at one moment of the file and closed at another, with the timer always running."""
        times = {"timestamp": self._at(seconds), "start_time": self._at(opened)}
        return self._write(LAP, {**times, "total_timer_time": seconds - opened}, developer)

    def untimed_lap(self, seconds: float, **developer: Any) -> Self:
        """A lap that says when it was closed but not when it was opened or how long it lasted."""
        return self._write(LAP, {"timestamp": self._at(seconds)}, developer)

    def session(self, seconds: float, *, total_distance: float | None = None, **developer: Any) -> Self:
        times = {"timestamp": self._at(seconds), "start_time": self._at(0), "total_elapsed_time": seconds}
        totals = {"total_timer_time": seconds, "total_calories": 300, "total_distance": total_distance}
        return self._write(SESSION, {**times, **totals, "sport": "tennis"}, developer)

    def to_bytes(self) -> bytes:
        return self._encoder.close()

    def write(self, path: Path) -> Path:
        path.write_bytes(self.to_bytes())
        return path

    def records(self, point_logs: Sequence[list[int]], track: Sequence[tuple[int, int]] = ()) -> Self:
        """One record every twenty seconds, each with the point log of that moment and a position if one is left."""
        for index, point_log in enumerate(point_logs):
            position = track[index] if index < len(track) else None
            clock = SECONDS_BETWEEN_RECORDS * (index + 1)
            self.record(clock, heart_rate=120 + index, position=position, point_log=point_log)
        return self
