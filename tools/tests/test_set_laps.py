"""Tests for tools/tennis_export/set_laps.py."""

from __future__ import annotations

from typing import Any

from fit_builder import at
from match_script import WatchLog
from tennis_export.fit_reader import Message
from tennis_export.replay import replay
from tennis_export.set_laps import lap_total, laps_by_set

SET = "mmmm" * 6
SECONDS_BETWEEN_RECORDS = 20


def lap(opened: float, closed: float, **developer: Any) -> Message:
    return Message({"start_time": at(opened), "total_timer_time": closed - opened}, developer)


def records_of(values: list[list[int]]) -> list[Message]:
    """One record for each value, twenty seconds apart."""
    clocks = [at(SECONDS_BETWEEN_RECORDS * (index + 1)) for index in range(len(values))]
    return [Message({"timestamp": clock}, {"point_log": value}) for clock, value in zip(clocks, values, strict=True)]


def placed(log: WatchLog, values: list[list[int]], laps: list[Message]) -> list[tuple[Message, ...]] | None:
    return laps_by_set(replay(log.config, log.slots()).rows, records_of(values), laps)


def test_each_set_gets_the_lap_recorded_while_it_was_played() -> None:
    log = WatchLog().play(SET + SET)
    first, second = lap(0, 480), lap(480, 960)

    assert placed(log, log.record_values(), [first, second]) == [(first,), (second,)]


def test_a_set_that_was_undone_and_played_again_keeps_both_of_its_laps() -> None:
    log = WatchLog().play(SET)
    values = log.record_values()
    values.append(log.undo().record_value())
    values += [log.play("o").record_value(), log.play("m").record_value()]
    values += [log.play(letter).record_value() for letter in SET]
    undone, played_again, second = lap(0, 480), lap(480, 540), lap(540, 1020)

    assert placed(log, values, [undone, played_again, second]) == [(undone, played_again), (second,)]


def test_the_lap_of_a_set_that_was_never_closed_belongs_to_no_set() -> None:
    log = WatchLog().play(SET + "mm")
    first = lap(0, 480)

    assert placed(log, log.record_values(), [first, lap(480, 520)]) == [(first,)]


def test_laps_that_lasted_no_time_are_left_out() -> None:
    log = WatchLog().play(SET)
    first = lap(0, 480)

    assert placed(log, log.record_values(), [lap(480, 480), first, lap(480, 480)]) == [(first,)]


def test_a_closed_set_can_be_left_without_a_lap() -> None:
    log = WatchLog().play(SET + SET)
    first = lap(0, 480)

    assert placed(log, log.record_values(), [first]) == [(first,), ()]


def test_a_lap_that_cannot_be_placed_in_time_leaves_every_set_unknown() -> None:
    log = WatchLog().play(SET)
    without_start = Message({"total_timer_time": 480.0})
    without_timer = Message({"start_time": at(0)})

    assert placed(log, log.record_values(), [lap(0, 480), without_start]) is None
    assert placed(log, log.record_values(), [without_timer]) is None


def test_a_set_whose_end_has_no_time_leaves_every_set_unknown() -> None:
    log = WatchLog().play(SET)
    records = [Message(developer={"point_log": value}) for value in log.record_values()]

    assert laps_by_set(replay(log.config, log.slots()).rows, records, [lap(0, 480)]) is None


def test_a_lap_field_adds_up_over_the_laps_of_a_set() -> None:
    assert lap_total((lap(0, 480, set_steps=400), lap(480, 540, set_steps=50)), "set_steps") == 450


def test_a_lap_field_is_unknown_without_laps_or_when_one_lap_lacks_it() -> None:
    assert lap_total((lap(0, 480, set_steps=400), lap(480, 540)), "set_steps") is None
    assert lap_total((), "set_steps") is None
    assert lap_total(None, "set_steps") is None
