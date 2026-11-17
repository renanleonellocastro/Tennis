import Toybox.Lang;

// Test helper that plays a match from a short script and prints the score as
// one line. Nothing here carries (:test), so the runner never invokes it.
class MatchDriver {
    const SECONDS_PER_ENTRY = 10;
    const POINTS_OF_A_LOVE_GAME = 4;

    var engine as MatchEngine;
    var clock as Number = 0;

    function initialize(format as Number, isNoAdvantage as Boolean, firstServer as Number) {
        engine = new MatchEngine(new MatchConfig(format, isNoAdvantage, firstServer),
                                 new PointLog([] as Array<Number>), []);
    }

    // One entry per character: 'M' a point for me, 'O' a point for the
    // opponent, 'F' a serve fault. The clock moves 10 seconds per entry.
    function play(script as String) as Void {
        var codes = script.toCharArray();
        for (var i = 0; i < codes.size(); i++) {
            step(codes[i]);
        }
    }

    // One love game per character: 'M' won by me, 'O' by the opponent.
    function games(script as String) as Void {
        var codes = script.toCharArray();
        for (var i = 0; i < codes.size(); i++) {
            for (var point = 0; point < POINTS_OF_A_LOVE_GAME; point++) {
                step(codes[i]);
            }
        }
    }

    function step(code as Char) as Boolean {
        clock += SECONDS_PER_ENTRY;
        if (code == 'F') {
            return engine.fault(clock, null);
        }
        return engine.point(code == 'M' ? Player.ME : Player.OPPONENT, Ending.NONE, clock, null);
    }

    // A detailed mode point at the next clock step.
    function detailed(winner as Number, ending as Number, heartRate as Number?) as Boolean {
        clock += SECONDS_PER_ENTRY;
        return engine.point(winner, ending, clock, heartRate);
    }

    function state() as MatchState {
        return engine.state();
    }

    function statistics() as MatchStatistics {
        return engine.statistics();
    }

    // "sets games points", me first: "1-0 2-3 40-AD".
    function score() as String {
        var state = engine.state();
        return state.sets(Player.ME) + "-" + state.sets(Player.OPPONENT) + " "
            + state.games(Player.ME) + "-" + state.games(Player.OPPONENT) + " "
            + pointText(Player.ME) + "-" + pointText(Player.OPPONENT);
    }

    function pointText(player as Number) as String {
        var points = engine.state().displayPoints(player);
        return points == MatchState.DISPLAY_ADVANTAGE ? "AD" : points.toString();
    }
}

// Shortcuts for the most common setups: advantage scoring, me serving first.
function newMatch(format as Number) as MatchDriver {
    return new MatchDriver(format, false, Player.ME);
}

// A set that stands at 6 all, so the next point opens the tie break.
function matchAtSixAll(format as Number) as MatchDriver {
    var match = newMatch(format);
    match.games("MOMOMOMOMOMO");
    return match;
}

// A best of 3 at one set all.
function matchAtOneSetAll(format as Number) as MatchDriver {
    var match = newMatch(format);
    match.games("MMMMMMOOOOOO");
    return match;
}
