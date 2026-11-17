import Toybox.Lang;

// Watches a replay and counts. For each entry it notes the situation before
// the entry is applied (who serves, which serve, what is at stake) and then
// credits the point the entry produced, if any.
class StatisticsCollector {
    hidden var _statistics as MatchStatistics = new MatchStatistics();
    hidden var _server as Number = Player.NONE;
    hidden var _winner as Number = Player.NONE;
    hidden var _wasSecondServe as Boolean = false;
    hidden var _wasTieBreak as Boolean = false;
    hidden var _wasDecidingPoint as Boolean = false;
    hidden var _breakPointHolder as Number = Player.NONE;
    hidden var _runPlayer as Number = Player.NONE;
    hidden var _runLength as Number = 0;
    // The match clock starts at zero, so the first game and set start there.
    hidden var _gameStart as Number = 0;
    hidden var _setStart as Number = 0;

    function statistics() as MatchStatistics {
        return _statistics;
    }

    // Applies the entry to the state and counts what it did.
    function record(state as MatchState, entry as Number) as Void {
        noteSituation(state, entry);
        var outcome = state.apply(entry);
        if ((outcome & Outcome.POINT) == 0) {
            return;
        }
        recordServe(entry);
        recordEnding(PointEntry.ending(entry));
        recordRun();
        recordBreakPoint();
        recordDecidingHeartRate(PointEntry.heartRate(entry));
        recordTimes(outcome, PointEntry.time(entry));
    }

    hidden function noteSituation(state as MatchState, entry as Number) as Void {
        _server = state.server();
        _winner = state.pointWinner(entry);
        _wasSecondServe = state.isSecondServe();
        _wasTieBreak = state.isTieBreak();
        _wasDecidingPoint = state.isDecidingPoint();
        _breakPointHolder = state.hasBreakPoint(state.receiver()) ? state.receiver() : Player.NONE;
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

    hidden function recordRun() as Void {
        _runLength = _winner == _runPlayer ? _runLength + 1 : 1;
        _runPlayer = _winner;
        _statistics.raiseTo(Stat.LONGEST_RUN, _winner, _runLength);
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

    hidden function recordDecidingHeartRate(heartRate as Number?) as Void {
        if (_wasDecidingPoint && heartRate != null) {
            _statistics.addDecidingHeartRate(heartRate);
        }
    }

    hidden function recordTimes(outcome as Number, time as Number) as Void {
        _statistics.notePointTime(time);
        if ((outcome & Outcome.GAME) != 0) {
            recordGame(time);
        }
        if ((outcome & Outcome.SET) != 0) {
            _statistics.addSetDuration(time - _setStart);
            _setStart = time;
        }
    }

    hidden function recordGame(time as Number) as Void {
        _statistics.addGameDuration(time - _gameStart);
        _gameStart = time;
        if (!_wasTieBreak) {
            recordServiceGame();
        }
    }

    hidden function recordServiceGame() as Void {
        _statistics.add(Stat.SERVICE_GAMES_PLAYED, _server);
        if (_winner == _server) {
            _statistics.add(Stat.SERVICE_GAMES_WON, _server);
        }
    }
}
