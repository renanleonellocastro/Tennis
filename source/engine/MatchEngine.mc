import Toybox.Lang;

// The scoring engine: it appends entries to the point log, removes the last
// one on undo and keeps the score that the log adds up to. The caller hands
// in the match clock and the heart rate, so the engine never touches a
// sensor, the screen or storage.
class MatchEngine {
    hidden var _config as MatchConfig;
    hidden var _log as PointLog;
    hidden var _state as MatchState;

    // A log that already has entries resumes that match.
    function initialize(config as MatchConfig, log as PointLog) {
        _config = config;
        _log = log;
        _state = MatchReplay.state(config, log);
    }

    // Logs a missed serve. The second one in a row is a double fault and
    // gives the point to the receiver. False when the match is over.
    function fault(time as Number, heartRate as Number?) as Boolean {
        return record(PointEntry.fault(time, heartRate));
    }

    // Logs a played point. False when the match is over or when an ace is
    // claimed for the player who is not serving.
    function point(winner as Number, ending as Number, time as Number, heartRate as Number?) as Boolean {
        if (ending == Ending.ACE && winner != _state.server()) {
            return false;
        }
        return record(PointEntry.point(winner, ending, time, heartRate));
    }

    hidden function record(entry as Number) as Boolean {
        if (_state.isFinished()) {
            return false;
        }
        _log.append(entry);
        _state.apply(entry);
        return true;
    }

    // Removes the last entry. False when the log is empty.
    function undo() as Boolean {
        return truncate(_log.size() - 1);
    }

    // Cuts the log back to its first size entries and replays it once. False
    // when that would remove nothing.
    function truncate(size as Number) as Boolean {
        if (size < 0 || size >= _log.size()) {
            return false;
        }
        _log.truncate(size);
        _state = MatchReplay.state(_config, _log);
        return true;
    }

    function state() as MatchState {
        return _state;
    }

    function statistics() as MatchStatistics {
        return MatchReplay.statistics(_config, _log);
    }

    function config() as MatchConfig {
        return _config;
    }

    function log() as PointLog {
        return _log;
    }
}
