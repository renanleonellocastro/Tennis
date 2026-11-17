import Toybox.Lang;

// Applies entries to the score and counts as it goes. For each entry that
// ends a point it notes the situation before the entry is applied (who
// serves, which serve, what is at stake) and then credits the point. A
// first serve fault only moves the score on, so it costs next to nothing.
class StatisticsCollector {
    hidden var _statistics as MatchStatistics;
    hidden var _server as Number = Player.NONE;
    hidden var _winner as Number = Player.NONE;
    hidden var _wasSecondServe as Boolean = false;
    hidden var _wasTieBreak as Boolean = false;
    hidden var _wasDecidingPoint as Boolean = false;
    hidden var _breakPointHolder as Number = Player.NONE;

    // Stat.zeros() for a new match, or the values of an earlier moment.
    function initialize(values as Array<Number>) {
        _statistics = new MatchStatistics(values);
    }

    function statistics() as MatchStatistics {
        return _statistics;
    }

    // Applies the entry to the state, counts what it did and returns its
    // Outcome flags.
    function record(state as MatchState, entry as Number) as Number {
        var endsPoint = !PointEntry.isFault(entry) || state.isSecondServe();
        if (endsPoint) {
            noteSituation(state, entry);
        }
        var outcome = state.apply(entry);
        if (endsPoint) {
            recordPoint(entry, outcome);
        }
        return outcome;
    }

    // The heart rate of a deciding point is only kept when there is one, so
    // the set and match point rules are only asked then.
    hidden function noteSituation(state as MatchState, entry as Number) as Void {
        _server = state.server();
        var receiver = Player.opponentOf(_server);
        _winner = PointEntry.isFault(entry) ? receiver : PointEntry.winner(entry);
        _wasSecondServe = state.isSecondServe();
        _wasTieBreak = state.isTieBreak();
        _breakPointHolder = !_wasTieBreak && state.hasGamePoint(receiver) ? receiver : Player.NONE;
        _wasDecidingPoint = PointEntry.heartRate(entry) != null && (_breakPointHolder != Player.NONE
            || state.hasSetPoint(Player.ME) || state.hasSetPoint(Player.OPPONENT));
    }

    hidden function recordPoint(entry as Number, outcome as Number) as Void {
        recordServe(entry);
        recordEnding(PointEntry.ending(entry));
        _statistics.noteRun(_winner);
        recordBreakPoint();
        if (_wasDecidingPoint) {
            _statistics.addDecidingHeartRate(PointEntry.heartRate(entry) as Number);
        }
        _statistics.notePointTime(PointEntry.time(entry));
        if ((outcome & Outcome.GAME) != 0) {
            recordGame(PointEntry.time(entry));
        }
    }

    hidden function recordServe(entry as Number) as Void {
        _statistics.add(Stat.POINTS_WON, _winner);
        _statistics.add(Stat.SERVICE_POINTS, _server);
        if (PointEntry.isFault(entry)) {
            _statistics.add(Stat.DOUBLE_FAULTS, _server);
        }
        if (!_wasSecondServe) {
            _statistics.add(Stat.FIRST_SERVES_IN, _server);
        }
        if (_winner == _server) {
            _statistics.add(_wasSecondServe ? Stat.SECOND_SERVE_POINTS_WON : Stat.FIRST_SERVE_POINTS_WON, _server);
        }
    }

    // A winner or an ace belongs to the player who won the point, an error
    // to the player who lost it.
    hidden function recordEnding(ending as Number) as Void {
        if (ending == Ending.NONE) {
            return;
        }
        var isError = ending == Ending.ERROR_NET || ending == Ending.ERROR_OUT;
        _statistics.add(Stat.forEnding(ending), isError ? Player.opponentOf(_winner) : _winner);
    }

    hidden function recordBreakPoint() as Void {
        if (_breakPointHolder == Player.NONE) {
            return;
        }
        _statistics.add(Stat.BREAK_POINT_CHANCES, _breakPointHolder);
        if (_winner == _breakPointHolder) {
            _statistics.add(Stat.BREAK_POINTS_WON, _breakPointHolder);
        }
    }

    hidden function recordGame(time as Number) as Void {
        _statistics.closeGame(time);
        if (!_wasTieBreak) {
            _statistics.add(Stat.SERVICE_GAMES_PLAYED, _server);
            if (_winner == _server) {
                _statistics.add(Stat.SERVICE_GAMES_WON, _server);
            }
        }
    }
}
