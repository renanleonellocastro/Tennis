"""Tests for tools/tennis_export/entry_times.py."""

from __future__ import annotations

from fit_builder import at
from match_script import WatchLog
from tennis_export.entry_times import entry_times
from tennis_export.fit_reader import Message


def record(seconds: float, point_log: list[int] | None = None) -> Message:
    developer = {} if point_log is None else {"point_log": point_log}
    return Message({"timestamp": at(seconds)}, developer)


def test_an_entry_gets_the_time_of_the_first_record_that_carried_it() -> None:
    values = WatchLog().play("mo").record_values()
    records = [record(5), record(10, values[0]), record(11, values[0]), record(30, values[1]), record(31)]

    assert entry_times(records) == {1: at(10), 2: at(30)}


def test_an_entry_marked_again_after_an_undo_gets_the_time_it_was_marked_again() -> None:
    log = WatchLog().play("mmo")
    values = log.record_values()
    records = [record(20 * (index + 1), value) for index, value in enumerate(values)]
    records.append(record(80, log.undo().record_value()))
    records.append(record(100, log.play("m").record_value()))

    assert entry_times(records) == {1: at(20), 2: at(40), 3: at(100)}


def test_an_undone_entry_has_no_time_and_a_record_without_a_time_gives_none() -> None:
    log = WatchLog().play("mm")
    records = [Message(developer={"point_log": value}) for value in log.record_values()]
    records.append(record(60, log.undo().record_value()))

    assert entry_times(records) == {1: None}
