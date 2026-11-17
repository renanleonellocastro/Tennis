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

    function forEnding(ending as Number) as Number {
        return WINNERS + ending - Ending.WINNER;
    }
}

// The numbers of a match for both players. StatisticsCollector fills them in
// while the log is replayed; the report only reads them.
class MatchStatistics {
    hidden const PERCENT = 100;

    hidden var _counts as Array<Number> = [] as Array<Number>;
    hidden var _gameDurations as Array<Number> = [] as Array<Number>;
    hidden var _setDurations as Array<Number> = [] as Array<Number>;
    hidden var _pointCount as Number = 0;
    hidden var _firstPointTime as Number = 0;
    hidden var _lastPointTime as Number = 0;
    hidden var _heartRateSum as Number = 0;
    hidden var _heartRateSamples as Number = 0;

    function initialize() {
        for (var i = 0; i < Stat.COUNT * Player.COUNT; i++) {
            _counts.add(0);
        }
    }

    // Filled in by the collector.

    function add(stat as Number, player as Number) as Void {
        _counts[slot(stat, player)] += 1;
    }

    function raiseTo(stat as Number, player as Number, value as Number) as Void {
        if (value > count(stat, player)) {
            _counts[slot(stat, player)] = value;
        }
    }

    function addGameDuration(seconds as Number) as Void {
        _gameDurations.add(seconds);
    }

    function addSetDuration(seconds as Number) as Void {
        _setDurations.add(seconds);
    }

    function notePointTime(time as Number) as Void {
        if (_pointCount == 0) {
            _firstPointTime = time;
        }
        _lastPointTime = time;
        _pointCount += 1;
    }

    function addDecidingHeartRate(heartRate as Number) as Void {
        _heartRateSum += heartRate;
        _heartRateSamples += 1;
    }

    hidden function slot(stat as Number, player as Number) as Number {
        return stat * Player.COUNT + player;
    }

    // Read by the report.

    function count(stat as Number, player as Number) as Number {
        return _counts[slot(stat, player)];
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

    // Seconds of each finished game, in order, tie breaks included.
    function gameDurations() as Array<Number> {
        return _gameDurations;
    }

    // Seconds of each finished set, in order.
    function setDurations() as Array<Number> {
        return _setDurations;
    }

    // Zero until two points were played.
    function averageSecondsBetweenPoints() as Float {
        if (_pointCount < 2) {
            return 0.0;
        }
        return (_lastPointTime - _firstPointTime).toFloat() / (_pointCount - 1);
    }

    // Average over the break, set and match points that carried a heart
    // rate; null when none did.
    function averageDecidingHeartRate() as Number? {
        if (_heartRateSamples == 0) {
            return null;
        }
        return (_heartRateSum + _heartRateSamples / 2) / _heartRateSamples;
    }
}
