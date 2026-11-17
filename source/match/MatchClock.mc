import Toybox.Lang;

// The match clock: time played, without the pauses. It never reads the
// system time itself; the caller passes the current milliseconds in.
class MatchClock {
    hidden const MS_PER_SECOND = 1000;

    hidden var _playedMs as Number = 0;
    hidden var _runningSinceMs as Number;
    hidden var _isRunning as Boolean = true;

    function initialize(nowMs as Number) {
        _runningSinceMs = nowMs;
    }

    function pause(nowMs as Number) as Void {
        if (_isRunning) {
            _playedMs += nowMs - _runningSinceMs;
            _isRunning = false;
        }
    }

    function resume(nowMs as Number) as Void {
        if (!_isRunning) {
            _runningSinceMs = nowMs;
            _isRunning = true;
        }
    }

    function isRunning() as Boolean {
        return _isRunning;
    }

    function seconds(nowMs as Number) as Number {
        var runningMs = _isRunning ? nowMs - _runningSinceMs : 0;
        return (_playedMs + runningMs) / MS_PER_SECOND;
    }
}
