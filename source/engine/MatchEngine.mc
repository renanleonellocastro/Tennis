import Toybox.Lang;

// The scoring engine: it appends entries to the point log, removes the last
// one on undo and keeps the score that the log adds up to. The caller hands
// in the match clock and the heart rate, so the engine never touches a
// sensor, the screen or storage.
class MatchEngine {
    hidden var _config as MatchConfig;
    hidden var _log as PointLog;
    hidden var _state as MatchState;
    hidden var _slots as Array<Number> = PointSlot.none();

    // A log that already has entries resumes that match.
    function initialize(config as MatchConfig, log as PointLog) {
        _config = config;
        _log = log;
        _state = new MatchState(config);
        replay();
    }

    // Applies the log from its first entry. Entries past the end of the
    // match are ignored, so a damaged stored log cannot push the score
    // beyond the final result. Only the newest entries reach the slots.
    hidden function replay() as Void {
        _state = new MatchState(_config);
        _slots = PointSlot.none();
        var firstSlot = _log.size() - PointSlot.SLOTS;
        for (var i = 0; i < _log.size() && !_state.isFinished(); i++) {
            apply(i, i >= firstSlot);
        }
    }

    // Applies the entry at an index of the log, and keeps it as the newest
    // slot of the activity file when asked to.
    hidden function apply(index as Number, isSlot as Boolean) as Void {
        var entry = _log.at(index);
        var header = PointSlot.header(index + 1, _state);
        _state.apply(entry);
        if (isSlot) {
            _slots = PointSlot.pushed(_slots, [header, entry, PointSlot.score(_state)]);
        }
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
        apply(_log.size() - 1, true);
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
        replay();
        return true;
    }

    function state() as MatchState {
        return _state;
    }

    // The newest three entries as the point_log field holds them (see
    // PointSlot).
    function slots() as Array<Number> {
        return _slots;
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
