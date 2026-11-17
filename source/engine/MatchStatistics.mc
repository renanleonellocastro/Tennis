import Toybox.Lang;

// The counters kept for each player.
module Stat {
    const SERVICE_POINTS = 0;
    const FIRST_SERVES_IN = 1;
    const FIRST_SERVE_POINTS_WON = 2;
    const SECOND_SERVE_POINTS_WON = 3;
    const DOUBLE_FAULTS = 4;
    const SERVICE_GAMES_PLAYED = 5;
    const SERVICE_GAMES_WON = 6;
    const BREAK_POINT_CHANCES = 7;
    const BREAK_POINTS_WON = 8;
    const POINTS_WON = 9;
    const LONGEST_RUN = 10;
    // The next four keep the order of the Ending codes, so an ending maps
    // straight to its counter (see forEnding).
    const WINNERS = 11;
    const ACES = 12;
    const ERRORS_NET = 13;
    const ERRORS_OUT = 14;
    const COUNT = 15;

    // What the match keeps as a whole, after the counters of both players.
    const POINT_COUNT = 30;
    const FIRST_POINT_TIME = 31;
    const LAST_POINT_TIME = 32;
    const HEART_RATE_SUM = 33;
    const HEART_RATE_SAMPLES = 34;
    const GAME_COUNT = 35;
    const GAME_SECONDS = 36;
    const LONGEST_GAME = 37;
    // The run of points in progress and when the game in progress started.
    const RUN_PLAYER = 38;
    const RUN_LENGTH = 39;
    const GAME_START = 40;
    const SIZE = 41;

    // The values of a match with no entry: the match clock starts at zero,
    // so the first game starts there.
    function zeros() as Array<Number> {
        var values = [] as Array<Number>;
        for (var i = 0; i < SIZE; i++) {
            values.add(0);
        }
        values[RUN_PLAYER] = Player.NONE;
        return values;
    }

    function forEnding(ending as Number) as Number {
        return WINNERS + ending - Ending.WINNER;
    }
}

// The numbers of a match for both players. StatisticsCollector fills them in
// entry by entry; the report only reads them. Everything is kept in one
// array of numbers, so a copy of it is all it takes to come back to an
// earlier moment of the match (see MatchEngine).
class MatchStatistics {
    hidden const PERCENT = 100;

    hidden var _values as Array<Number>;

    // Stat.zeros() for a new match, or the values of an earlier moment.
    function initialize(values as Array<Number>) {
        _values = values;
    }

    // Filled in by the collector.

    function add(stat as Number, player as Number) as Void {
        _values[stat * Player.COUNT + player] += 1;
    }

    // A point for the winner: the run of points in a row and its record.
    function noteRun(winner as Number) as Void {
        var length = winner == _values[Stat.RUN_PLAYER] ? _values[Stat.RUN_LENGTH] + 1 : 1;
        _values[Stat.RUN_PLAYER] = winner;
        _values[Stat.RUN_LENGTH] = length;
        if (length > count(Stat.LONGEST_RUN, winner)) {
            _values[Stat.LONGEST_RUN * Player.COUNT + winner] = length;
        }
    }

    // A game that closed at this time of the match clock.
    function closeGame(time as Number) as Void {
        var seconds = time - _values[Stat.GAME_START];
        _values[Stat.GAME_START] = time;
        _values[Stat.GAME_COUNT] += 1;
        _values[Stat.GAME_SECONDS] += seconds;
        if (seconds > _values[Stat.LONGEST_GAME]) {
            _values[Stat.LONGEST_GAME] = seconds;
        }
    }

    function notePointTime(time as Number) as Void {
        if (_values[Stat.POINT_COUNT] == 0) {
            _values[Stat.FIRST_POINT_TIME] = time;
        }
        _values[Stat.LAST_POINT_TIME] = time;
        _values[Stat.POINT_COUNT] += 1;
    }

    function addDecidingHeartRate(heartRate as Number) as Void {
        _values[Stat.HEART_RATE_SUM] += heartRate;
        _values[Stat.HEART_RATE_SAMPLES] += 1;
    }

    // A copy of everything, to come back to later.
    function snapshot() as Array<Number> {
        return _values.slice(0, null);
    }

    // Read by the report.

    function count(stat as Number, player as Number) as Number {
        return _values[stat * Player.COUNT + player];
    }

    // Every counter in the order the activity file keeps them: statistic by
    // statistic, me and then the opponent.
    function toArray() as Array<Number> {
        return _values.slice(0, Stat.COUNT * Player.COUNT);
    }

    // Rounded to a whole percent; zero before the player has served.
    function firstServePercent(player as Number) as Number {
        var served = count(Stat.SERVICE_POINTS, player);
        if (served == 0) {
            return 0;
        }
        return (count(Stat.FIRST_SERVES_IN, player) * PERCENT + served / 2) / served;
    }

    function secondServePoints(player as Number) as Number {
        return count(Stat.SERVICE_POINTS, player) - count(Stat.FIRST_SERVES_IN, player);
    }

    function returnGamesPlayed(player as Number) as Number {
        return count(Stat.SERVICE_GAMES_PLAYED, Player.opponentOf(player));
    }

    function returnGamesWon(player as Number) as Number {
        return returnGamesPlayed(player) - count(Stat.SERVICE_GAMES_WON, Player.opponentOf(player));
    }

    function breakPointsFaced(player as Number) as Number {
        return count(Stat.BREAK_POINT_CHANCES, Player.opponentOf(player));
    }

    function breakPointsSaved(player as Number) as Number {
        return breakPointsFaced(player) - count(Stat.BREAK_POINTS_WON, Player.opponentOf(player));
    }

    // Rounded average of the finished games, tie breaks included; zero
    // before the first one closes.
    function averageGameSeconds() as Number {
        var games = _values[Stat.GAME_COUNT];
        return games == 0 ? 0 : (_values[Stat.GAME_SECONDS] + games / 2) / games;
    }

    function longestGameSeconds() as Number {
        return _values[Stat.LONGEST_GAME];
    }

    function gameCount() as Number {
        return _values[Stat.GAME_COUNT];
    }

    // Zero until two points were played.
    function averageSecondsBetweenPoints() as Float {
        var points = _values[Stat.POINT_COUNT];
        if (points < 2) {
            return 0.0;
        }
        return (_values[Stat.LAST_POINT_TIME] - _values[Stat.FIRST_POINT_TIME]).toFloat() / (points - 1);
    }

    // Average over the break, set and match points that carried a heart
    // rate; null when none did.
    function averageDecidingHeartRate() as Number? {
        var samples = _values[Stat.HEART_RATE_SAMPLES];
        return samples == 0 ? null : (_values[Stat.HEART_RATE_SUM] + samples / 2) / samples;
    }
}
