"""Reads a FIT activity file into the few messages the export needs."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any, cast

from garmin_fit_sdk import Decoder, Stream

from tennis_export.errors import ExportError

if TYPE_CHECKING:
    from collections.abc import Mapping
    from pathlib import Path

type RawMessage = dict[Any, Any]
type RawMessages = dict[str, list[RawMessage]]

DEVELOPER_FIELDS_KEY = "developer_fields"


@dataclass(frozen=True)
class Message:
    """One FIT message: the fields of the FIT profile by name, and the developer fields by name."""

    native: Mapping[str, Any] = field(default_factory=dict)
    developer: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class Activity:
    records: tuple[Message, ...]
    laps: tuple[Message, ...]
    sessions: tuple[Message, ...]

    @property
    def session(self) -> Message:
        """The first session, or an empty message when the file has none."""
        return self.sessions[0] if self.sessions else Message()


def read_activity(path: Path) -> Activity:
    messages = decode(path)
    names = developer_field_names(messages)
    return Activity(
        records=to_messages(messages, "record_mesgs", names),
        laps=to_messages(messages, "lap_mesgs", names),
        sessions=to_messages(messages, "session_mesgs", names),
    )


def decode(path: Path) -> RawMessages:
    try:
        stream = Stream.from_byte_array(bytearray(path.read_bytes()))
    except OSError as error:
        raise ExportError(f"cannot read {path}: {error.strerror}") from error
    messages, errors = Decoder(stream).read()
    if errors:
        raise ExportError(f"{path.name} is not a readable FIT file: {errors[0]}")
    return cast("RawMessages", messages)


def developer_field_names(messages: RawMessages) -> dict[Any, str]:
    """The decoder files developer values under the key of their field description, so map key to name."""
    descriptions = messages.get("field_description_mesgs", [])
    return {description["key"]: str(description["field_name"]) for description in descriptions}


def to_messages(messages: RawMessages, kind: str, names: Mapping[Any, str]) -> tuple[Message, ...]:
    return tuple(to_message(raw, names) for raw in messages.get(kind, []))


def to_message(raw: RawMessage, names: Mapping[Any, str]) -> Message:
    native = {str(key): value for key, value in raw.items() if key != DEVELOPER_FIELDS_KEY}
    developer = {names[key]: value for key, value in raw.get(DEVELOPER_FIELDS_KEY, {}).items()}
    return Message(native, developer)
