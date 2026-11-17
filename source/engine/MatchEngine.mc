import Toybox.Lang;

// The scoring engine: it appends entries to the point log, removes the last
// one on undo and keeps the score and the statistics that the log adds up
// to. The caller hands in the match clock and the heart rate, so the engine
// never touches a sensor, the screen or storage.
//
// A watch stops an app that works too long in one go, and applying a whole
// match from its first entry is too long. So the engine counts as it goes,
// and now and then, when a game closes, it keeps a mark: everything needed
// to come back to that moment. An undo or a resumed match starts from a
// mark and applies only the entries after it.
class MatchEngine {
    // Entries between two marks, at least. A mark waits for a game to close.
    static const MARK_SPACING = 48;
    // A mark is [log size, start of the game before], the statistics and
    // then the state.
    hidden const MARK_HEAD = 2;

    hidden var _config as MatchConfig;
    hidden var _log as PointLog;
    hidden var _marks as Array< Array<Number> >;
    hidden var _state as MatchState;
    hidden var _collector as StatisticsCollector;
    hidden var _slots as Array<Number> = PointSlot.none();
    hidden var _gameStart as Number = 0;
    hidden var _previousGameStart as Number = 0;

    // A log that already has entries resumes that match, from the marks
    // that were kept with it.
    function initialize(config as MatchConfig, log as PointLog, marks as Array< Array<Number> >) {
        _config = config;
        _log = log;
        _marks = marks;
        _state = new MatchState(config);
        _collector = new StatisticsCollector(Stat.zeros());
        rebuild();
    }

    // Brings score, statistics and slots to what the log adds up to. The
    // marks past the end of the log go; the entries are applied from the
    // newest mark that leaves the slot entries after it. Entries past the
    // end of the match are ignored, so a damaged stored log cannot push
    // the score beyond the final result.
    hidden function rebuild() as Void {
        var size = _log.size();
        var firstSlot = size - PointSlot.SLOTS;
        _marks = MatchMarks.upTo(_marks, size);
        for (var i = restore(MatchMarks.newestUpTo(_marks, firstSlot)); i < size && !_state.isFinished(); i++) {
            apply(i, i >= firstSlot);
        }
    }

    // Goes back to a mark, or to the start of the match without one.
    // Returns the index of the first entry to apply.
    hidden function restore(mark as Array<Number>?) as Number {
        _state = new MatchState(_config);
        _slots = PointSlot.none();
        _gameStart = mark == null ? 0 : mark[0];
        _previousGameStart = mark == null ? 0 : mark[1];
        var statisticsEnd = MARK_HEAD + Stat.SIZE;
        if (mark != null) {
            _state.restore(mark.slice(statisticsEnd, null));
        }
        _collector = new StatisticsCollector(mark == null ? Stat.zeros() : mark.slice(MARK_HEAD, statisticsEnd));
        return _gameStart;
    }

    // Applies the entry at an index of the log, and keeps it as the newest
    // slot of the activity file when asked to.
    hidden function apply(index as Number, isSlot as Boolean) as Void {
        var entry = _log.at(index);
        var header = isSlot ? PointSlot.header(index + 1, _state) : 0;
        var outcome = _collector.record(_state, entry);
        if (isSlot) {
            _slots = PointSlot.pushed(_slots, [header, entry, PointSlot.score(_state)]);
        }
        if ((outcome & Outcome.GAME) != 0) {
            closeGame(index + 1);
        }
    }

    // A game closed and the next one starts at this index of the log.
    hidden function closeGame(next as Number) as Void {
        _previousGameStart = _gameStart;
        _gameStart = next;
        if (!_state.isFinished() && next - MatchMarks.newestIndex(_marks) >= MARK_SPACING) {
            _marks.add(mark());
        }
    }

    hidden function mark() as Array<Number> {
        var values = [_gameStart, _previousGameStart] as Array<Number>;
        return values.addAll(_collector.statistics().snapshot()).addAll(_state.toArray());
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

    // Cuts the log back to its first size entries. False when that would
    // remove nothing.
    function truncate(size as Number) as Boolean {
        if (size < 0 || size >= _log.size()) {
            return false;
        }
        _log.truncate(size);
        rebuild();
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
        return _collector.statistics();
    }

    // Where the game in progress starts in the log, or the game before it
    // when the game in progress has no entry yet.
    function gameStart() as Number {
        return _gameStart == _log.size() ? _previousGameStart : _gameStart;
    }

    // Kept in storage with the log, and handed back on resume.
    function marks() as Array< Array<Number> > {
        return _marks;
    }

    function config() as MatchConfig {
        return _config;
    }

    function log() as PointLog {
        return _log;
    }
}
