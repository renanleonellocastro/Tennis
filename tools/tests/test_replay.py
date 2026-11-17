"""Tests for tools/tennis_export/replay.py, collector.py and statistics.py."""

from __future__ import annotations

import pytest

from match_script import ACE, ERROR_NET, ERROR_OUT, FAULT, ME_WINS, OPPONENT_WINS, WINNER, WatchLog, config
from tennis_export.match_state import Outcome
from tennis_export.replay import Replay, replay
from tennis_export.rules import ME, OPPONENT
from tennis_export.statistics import MatchStatistics, Stat

ONE_SET = 2
TIE_BREAK_ONLY = 4


def replay_of(log: WatchLog) -> Replay:
    return replay(log.config, log.slots())


def two_games() -> WatchLog:
    """I hold with an ace, a second serve winner and a double fault; then I break at the second chance."""
    log = WatchLog()
    log.add(ME_WINS, ending=ACE).add(FAULT).add(ME_WINS, ending=WINNER).add(FAULT).add(FAULT)
    log.add(ME_WINS, ending=ERROR_NET).add(ME_WINS)
    log.play("mmm").add(OPPONENT_WINS, ending=ERROR_OUT, heart_rate=150).add(ME_WINS, heart_rate=161)
    return log


def counts(statistics: MatchStatistics, stat: Stat) -> tuple[int, int]:
    return statistics.count(stat, ME), statistics.count(stat, OPPONENT)


@pytest.mark.parametrize(
    ("stat", "expected"),
    [
        (Stat.SERVICE_POINTS, (5, 5)),
        (Stat.FIRST_SERVES_IN, (3, 5)),
        (Stat.FIRST_SERVE_POINTS_WON, (3, 1)),
        (Stat.SECOND_SERVE_POINTS_WON, (1, 0)),
        (Stat.DOUBLE_FAULTS, (1, 0)),
        (Stat.SERVICE_GAMES_PLAYED, (1, 1)),
        (Stat.SERVICE_GAMES_WON, (1, 0)),
        (Stat.BREAK_POINT_CHANCES, (2, 0)),
        (Stat.BREAK_POINTS_WON, (1, 0)),
        (Stat.POINTS_WON, (8, 2)),
        (Stat.LONGEST_RUN, (5, 1)),
        (Stat.WINNERS, (1, 0)),
        (Stat.ACES, (1, 0)),
        (Stat.ERRORS_NET, (0, 1)),
        (Stat.ERRORS_OUT, (1, 0)),
    ],
)
def test_every_counter_follows_the_rules_of_the_watch(stat: Stat, expected: tuple[int, int]) -> None:
    assert counts(replay_of(two_games()).statistics, stat) == expected


def test_derived_numbers_come_from_the_counters() -> None:
    statistics = replay_of(two_games()).statistics

    assert (statistics.first_serve_percent(ME), statistics.first_serve_percent(OPPONENT)) == (60, 100)
    assert statistics.second_serve_points(ME) == 2
    assert (statistics.return_games_played(ME), statistics.return_games_won(ME)) == (1, 1)
    assert (statistics.break_points_faced(OPPONENT), statistics.break_points_saved(OPPONENT)) == (2, 1)
    assert statistics.average_deciding_heart_rate() == 156
    assert statistics.average_seconds_between_points() == pytest.approx(220 / 9)


def test_numbers_that_need_data_are_empty_before_the_first_point() -> None:
    statistics = replay_of(WatchLog().add(FAULT)).statistics

    assert statistics.first_serve_percent(ME) is None
    assert statistics.average_seconds_between_points() is None
    assert statistics.average_deciding_heart_rate() is None
    assert statistics.counts == [0] * 30


def test_games_and_sets_keep_their_durations_from_the_point_times() -> None:
    statistics = replay_of(two_games()).statistics

    assert [(game.first_server, game.winner, game.duration_seconds) for game in statistics.games] == [
        (ME, ME, 140),
        (OPPONENT, ME, 100),
    ]
    assert [(game.set_number, game.game_number, game.is_tie_break) for game in statistics.games] == [
        (1, 1, False),
        (1, 2, False),
    ]

    statistics = replay_of(WatchLog(config(ONE_SET)).play("mmmm" * 6)).statistics

    assert statistics.set_durations == [480]


def test_a_tie_break_counts_as_a_game_but_not_as_a_service_game_or_a_break() -> None:
    statistics = replay_of(WatchLog(config(TIE_BREAK_ONLY)).play("ooo ooo mm o")).statistics

    assert counts(statistics, Stat.SERVICE_GAMES_PLAYED) == (0, 0)
    assert counts(statistics, Stat.BREAK_POINT_CHANCES) == (0, 0)
    assert [game.is_tie_break for game in statistics.games] == [True]


def test_set_points_count_as_deciding_points_for_the_heart_rate() -> None:
    log = WatchLog(config(TIE_BREAK_ONLY)).play("mmmmmm").add(OPPONENT_WINS, heart_rate=170).add(ME_WINS)

    assert replay_of(log).statistics.average_deciding_heart_rate() == 170


def test_each_row_carries_what_was_at_stake_and_the_score_after_it() -> None:
    rows = replay_of(two_games()).rows
    fault, second_serve, break_point = rows[1], rows[2], rows[10]

    assert (fault.is_point, fault.outcome, fault.score.display_points) == (False, Outcome.FAULT, ("15", "0"))
    assert (second_serve.situation.is_second_serve, second_serve.situation.point_number) == (True, 2)
    assert second_serve.score.display_points == ("30", "0")
    assert (break_point.situation.game_number, break_point.situation.server) == (2, OPPONENT)
    assert (break_point.situation.is_break_point, break_point.situation.is_deciding_point) == (True, True)
    assert (rows[6].score.games, rows[6].score.points) == ((1, 0), (0, 0))
    assert rows[11].entry.heart_rate == 161


def test_entries_after_the_point_that_ends_the_match_are_left_out() -> None:
    log = WatchLog(config(TIE_BREAK_ONLY)).play("mmmmmmm oo")
    result = replay_of(log)

    assert len(result.rows) == 7
    assert result.state.is_finished
    assert result.rows[-1].situation.is_match_point
    assert result.rows[-1].score.sets == (1, 0)
