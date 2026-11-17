"""Tests for tools/tennis_export/layout.py."""

from __future__ import annotations

from match_script import ACE, FAULT, ME_WINS, OPPONENT_WINS, pack_entry, pack_header, pack_score, pack_setup
from tennis_export.layout import (
    KIND_NAMES,
    SURFACE_NAMES,
    Entry,
    Setup,
    StoredScore,
    decode_entry,
    decode_setup,
    decode_slots,
    name_at,
    newest_sequence,
)

FIT_INVALID_TOP_BIT = 1 << 31


def test_an_entry_unpacks_into_result_ending_heart_rate_and_time() -> None:
    entry = decode_entry(pack_entry(OPPONENT_WINS, ending=ACE, heart_rate=150, time=3600))

    assert entry == Entry(result=2, ending=2, heart_rate=150, time=3600)
    assert (entry.is_fault, entry.winner) == (False, 1)


def test_a_heart_rate_of_zero_means_none_was_read() -> None:
    entry = decode_entry(pack_entry(FAULT, time=5))

    assert entry.heart_rate is None
    assert entry.is_fault


def test_a_record_value_unpacks_into_its_filled_slots_newest_first() -> None:
    newest = [
        pack_header(2, 1, is_second_serve=True, is_tie_break=True),
        pack_entry(ME_WINS),
        pack_score((7, 5), (0, 0), (1, 0)),
    ]
    older = [pack_header(1, 0), pack_entry(FAULT), pack_score((6, 5), (6, 6), (0, 0))]

    slots = decode_slots([*newest, *older, 0, 0, 0])

    assert [slot.sequence for slot in slots] == [2, 1]
    assert (slots[0].server, slots[0].is_second_serve, slots[0].is_tie_break) == (1, True, True)
    assert slots[0].score == StoredScore(points=(7, 5), games=(0, 0), sets=(1, 0))
    assert slots[1].score == StoredScore(points=(6, 5), games=(6, 6), sets=(0, 0))
    assert newest_sequence([*newest, *older]) == 2


def test_words_that_do_not_fill_a_whole_slot_are_ignored() -> None:
    slot = [pack_header(1, 0), pack_entry(ME_WINS), pack_score((1, 0), (0, 0), (0, 0))]

    assert len(decode_slots([*slot, pack_header(2, 0)])) == 1


def test_the_setup_word_unpacks_into_the_choices_made_before_the_match() -> None:
    word = pack_setup(1, no_advantage=True, detailed=False, first_server=1, surface=2, kind=1)

    assert decode_setup(word) == Setup(
        version=1, match_format=1, is_no_advantage=True, is_detailed=False, first_server=1, surface=2, kind=1
    )


def test_the_largest_values_never_set_the_bit_that_fit_reads_as_no_value() -> None:
    words = [
        pack_header(0xFFFF, 1, is_second_serve=True, is_tie_break=True),
        pack_entry(3, ending=7, heart_rate=255, time=(1 << 18) - 1),
        pack_score((500, 500), (15, 15), (3, 3)),
        pack_setup(7, no_advantage=True, first_server=1, surface=3, kind=3, version=15),
    ]

    assert all(word < FIT_INVALID_TOP_BIT for word in words)


def test_point_counts_stop_at_the_largest_value_the_score_word_holds() -> None:
    slot = decode_slots([pack_header(1, 0), pack_entry(ME_WINS), pack_score((130, 128), (0, 0), (0, 0))])[0]

    assert slot.score.points == (127, 127)


def test_a_code_without_a_name_reads_as_none() -> None:
    assert name_at(SURFACE_NAMES, 3) == "grass"
    assert name_at(KIND_NAMES, 3) is None
