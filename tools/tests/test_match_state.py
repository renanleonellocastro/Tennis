"""Tests for tools/tennis_export/match_state.py: every format and rule of the watch engine."""

from __future__ import annotations

import pytest

from match_script import RESULTS, config, pack_entry
from tennis_export.layout import decode_entry
from tennis_export.match_state import MatchState, Outcome
from tennis_export.rules import ME, OPPONENT, MatchConfig

BEST_OF_3 = 0
MATCH_TIE_BREAK = 1
ONE_SET = 2
PRO_SET = 3
TIE_BREAK_ONLY = 4

HOLD = "mmmm"
LOSE = "oooo"
SET_FOR_ME = HOLD * 6
SET_FOR_OPPONENT = LOSE * 6
SIX_ALL = (HOLD + LOSE) * 6


def play(script: str, match_config: MatchConfig | None = None) -> tuple[MatchState, list[Outcome]]:
    state = MatchState(match_config or config())
    outcomes = [state.apply(decode_entry(pack_entry(RESULTS[letter]))) for letter in script.replace(" ", "")]
    return state, outcomes


def display(state: MatchState) -> tuple[str, str]:
    return state.display_points(ME), state.display_points(OPPONENT)


@pytest.mark.parametrize(
    ("script", "points"),
    [("", ("0", "0")), ("m", ("15", "0")), ("mo", ("15", "15")), ("mmo", ("30", "15")), ("mmm", ("40", "0"))],
)
def test_points_inside_a_game_read_as_on_a_scoreboard(script: str, points: tuple[str, str]) -> None:
    assert display(play(script)[0]) == points


def test_four_points_two_clear_win_the_game() -> None:
    state, outcomes = play(HOLD)

    assert outcomes[-1] == Outcome.POINT | Outcome.GAME
    assert (state.games, state.points) == ((1, 0), (0, 0))


def test_deuce_needs_two_points_in_a_row() -> None:
    assert display(play("mmmooo")[0]) == ("40", "40")
    assert display(play("mmmooo m")[0]) == ("AD", "40")
    assert display(play("mmmooo o")[0]) == ("40", "AD")
    assert display(play("mmmooo mo")[0]) == ("40", "40")
    assert play("mmmooo mo oo")[0].games == (0, 1)


def test_no_advantage_decides_the_game_on_the_point_after_deuce() -> None:
    no_advantage = config(no_advantage=True)
    state, _ = play("mmmooo", no_advantage)

    assert state.has_game_point(ME)
    assert state.has_game_point(OPPONENT)
    assert play("mmmooo o", no_advantage)[0].games == (0, 1)


def test_a_first_fault_gives_a_second_serve_and_a_double_fault_gives_the_point_to_the_receiver() -> None:
    state, outcomes = play("f")

    assert outcomes == [Outcome.FAULT]
    assert state.is_second_serve

    state, outcomes = play("ff")

    assert outcomes[-1] == Outcome.POINT
    assert (state.points, state.is_second_serve) == ((0, 1), False)


def test_a_second_serve_that_is_played_clears_the_fault() -> None:
    state, _ = play("fm")

    assert (state.points, state.is_second_serve) == ((1, 0), False)


@pytest.mark.parametrize(("first_server", "other"), [(ME, OPPONENT), (OPPONENT, ME)])
def test_the_serve_passes_to_the_other_player_after_each_game(first_server: int, other: int) -> None:
    match_config = config(first_server=first_server)

    assert play("", match_config)[0].server == first_server
    assert play("mmm", match_config)[0].server == first_server
    assert play(HOLD, match_config)[0].server == other
    assert play(HOLD + LOSE, match_config)[0].server == first_server
    assert play(HOLD, match_config)[0].receiver == first_server


def test_a_set_goes_to_six_games_two_clear() -> None:
    state, outcomes = play(SET_FOR_ME)

    assert outcomes[-1] == Outcome.POINT | Outcome.GAME | Outcome.SET
    assert (state.sets, state.games) == ((1, 0), (0, 0))
    assert state.set_scores[0].games == (6, 0)
    assert state.set_scores[0].tie_break_points == (0, 0)
    assert state.set_scores[0].winner == ME


def test_six_games_to_five_does_not_close_the_set_and_seven_to_five_does() -> None:
    five_all = (HOLD + LOSE) * 5

    assert play(five_all + HOLD)[0].sets == (0, 0)
    assert play(five_all + HOLD + HOLD)[0].set_scores[0].games == (7, 5)
    assert play(five_all + LOSE + LOSE)[0].set_scores[0].winner == OPPONENT


def test_six_games_all_starts_a_tie_break_to_seven_two_clear() -> None:
    state, _ = play(SIX_ALL + "mmm")

    assert state.is_tie_break
    assert display(state) == ("3", "0")
    assert play(SIX_ALL + "mo" * 6)[0].sets == (0, 0)

    state, outcomes = play(SIX_ALL + "mo" * 6 + "mm")

    assert outcomes[-1] == Outcome.POINT | Outcome.GAME | Outcome.SET
    assert state.set_scores[0].games == (7, 6)
    assert state.set_scores[0].tie_break_points == (8, 6)


def test_inside_a_tie_break_the_serve_passes_after_the_first_point_and_then_every_two() -> None:
    servers = [play(SIX_ALL + "m" * played)[0].server for played in range(6)]

    assert servers == [ME, OPPONENT, OPPONENT, ME, ME, OPPONENT]
    assert play(SIX_ALL + "mmm")[0].game_first_server == ME


def test_the_player_who_received_first_in_the_tie_break_serves_first_in_the_next_set() -> None:
    state, _ = play(SIX_ALL + "m" * 7)

    assert state.sets == (1, 0)
    assert state.server == OPPONENT


def test_best_of_three_ends_when_a_player_has_two_sets() -> None:
    state, outcomes = play(SET_FOR_ME + SET_FOR_OPPONENT + SET_FOR_ME)

    assert outcomes[-1] == Outcome.POINT | Outcome.GAME | Outcome.SET | Outcome.MATCH
    assert (state.is_finished, state.winner, state.sets) == (True, ME, (2, 1))
    assert play(SET_FOR_ME + SET_FOR_OPPONENT)[0].winner is None


def test_best_of_three_plays_the_third_set_as_a_full_set() -> None:
    state, _ = play(SET_FOR_ME + SET_FOR_OPPONENT + "mmm")

    assert not state.is_tie_break
    assert display(state) == ("40", "0")


def test_a_match_tie_break_replaces_the_third_set_and_goes_to_ten_two_clear() -> None:
    match_config = config(MATCH_TIE_BREAK)
    one_set_all = SET_FOR_ME + SET_FOR_OPPONENT

    assert play(one_set_all, match_config)[0].is_tie_break
    assert not play(one_set_all + "m" * 9 + "o" * 9 + "m", match_config)[0].is_finished

    state, _ = play(one_set_all + "m" * 9 + "o" * 9 + "mm", match_config)

    assert (state.winner, state.sets) == (ME, (2, 1))
    assert state.set_scores[2].games == (1, 0)
    assert state.set_scores[2].tie_break_points == (11, 9)


def test_a_match_tie_break_format_still_plays_normal_tie_breaks_to_seven() -> None:
    state, _ = play(SIX_ALL + "m" * 7, config(MATCH_TIE_BREAK))

    assert state.set_scores[0].tie_break_points == (7, 0)


def test_one_set_ends_the_match_with_the_set() -> None:
    state, _ = play(SET_FOR_OPPONENT, config(ONE_SET))

    assert (state.is_finished, state.winner) == (True, OPPONENT)


def test_a_pro_set_goes_to_eight_games_with_a_tie_break_at_eight_all() -> None:
    pro_set = config(PRO_SET)

    assert not play(HOLD * 6, pro_set)[0].is_finished
    assert play(HOLD * 8, pro_set)[0].set_scores[0].games == (8, 0)
    assert not play(SIX_ALL, pro_set)[0].is_tie_break

    state, _ = play((HOLD + LOSE) * 8 + "o" * 7, pro_set)

    assert state.set_scores[0].games == (8, 9)
    assert state.winner == OPPONENT


def test_tie_break_only_is_a_single_tie_break() -> None:
    tie_break_only = config(TIE_BREAK_ONLY)

    assert play("", tie_break_only)[0].is_tie_break

    state, _ = play("mmmooo mmmm", tie_break_only)

    assert (state.winner, state.set_scores[0].games) == (ME, (1, 0))
    assert state.set_scores[0].tie_break_points == (7, 3)


def test_a_break_point_belongs_to_the_receiver_one_point_from_the_game() -> None:
    state, _ = play("ooo")

    assert state.has_break_point(OPPONENT)
    assert not state.has_break_point(ME)
    assert not play("mmm")[0].has_break_point(ME)
    assert not play(SIX_ALL + "o" * 6)[0].has_break_point(OPPONENT)


def test_set_point_and_match_point_look_one_point_ahead() -> None:
    state, _ = play(HOLD * 5 + "mmm")

    assert state.has_set_point(ME)
    assert not state.has_match_point(ME)
    assert not state.has_set_point(OPPONENT)
    assert play(SET_FOR_ME + HOLD * 5 + "mmm")[0].has_match_point(ME)
    assert play(SIX_ALL + "m" * 6, config(ONE_SET))[0].has_match_point(ME)


def test_a_finished_match_has_nothing_left_to_win() -> None:
    state, _ = play(SET_FOR_ME, config(ONE_SET))

    assert not state.has_game_point(ME)
    assert not state.has_match_point(ME)
