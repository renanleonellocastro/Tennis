"""Tests for tools/tennis_export/point_log.py."""

from __future__ import annotations

from match_script import WatchLog
from tennis_export.point_log import rebuild_point_log


def test_overlapping_copies_rebuild_the_log_once_in_order() -> None:
    log = WatchLog().play("mmmm oooo")

    rebuilt = rebuild_point_log(log.record_values(), None)

    assert rebuilt.slots == tuple(log.slots())
    assert (rebuilt.expected, rebuilt.recovered, rebuilt.missing) == (8, 8, ())


def test_records_that_repeat_the_same_value_change_nothing() -> None:
    log = WatchLog().play("mfom")
    repeated = [value for value in log.record_values() for _ in range(4)]

    assert rebuild_point_log(repeated, 4).slots == tuple(log.slots())


def test_a_run_of_lost_records_leaves_a_gap_and_only_the_entries_before_it_are_trusted() -> None:
    log = WatchLog().play("mmmm oooo")
    values = log.record_values()

    rebuilt = rebuild_point_log(values[:2] + values[5:], None)

    assert rebuilt.missing == (3,)
    assert (rebuilt.expected, rebuilt.recovered) == (8, 7)
    assert rebuilt.slots == tuple(log.slots()[:2])


def test_the_log_size_tells_when_the_last_entries_never_reached_a_record() -> None:
    log = WatchLog().play("mmmm")

    rebuilt = rebuild_point_log(log.record_values(), 6)

    assert rebuilt.missing == (5, 6)
    assert (rebuilt.expected, rebuilt.recovered, len(rebuilt.slots)) == (6, 4, 4)


def test_the_log_size_drops_entries_that_were_undone_after_the_last_record() -> None:
    log = WatchLog().play("mmmm")

    rebuilt = rebuild_point_log(log.record_values(), 3)

    assert (rebuilt.expected, rebuilt.missing, len(rebuilt.slots)) == (3, (), 3)


def test_an_entry_entered_again_after_an_undo_replaces_the_old_one() -> None:
    log = WatchLog().play("mmo")
    values = log.record_values()
    values.append(log.undo().record_value())
    values.append(log.play("m").record_value())

    rebuilt = rebuild_point_log(values, None)

    assert rebuilt.slots == tuple(log.slots())
    assert rebuilt.slots[2].entry.winner == 0


def test_undone_entries_are_forgotten_even_when_the_records_after_them_were_lost() -> None:
    log = WatchLog().play("mmmmo")
    values = log.record_values()
    values.append(log.undo().undo().record_value())

    rebuilt = rebuild_point_log(values, None)

    assert (rebuilt.expected, rebuilt.missing) == (3, ())
    assert rebuilt.slots == tuple(log.slots())


def test_no_records_and_empty_records_give_an_empty_log() -> None:
    assert rebuild_point_log([], None).slots == ()
    assert rebuild_point_log([WatchLog().record_value()], None).expected == 0
