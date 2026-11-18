import Toybox.Lang;

// What the screen has to do after an input, as flags.
module Reaction {
    const NONE = 0;
    const REFRESH = 1;
    const VIBRATE = 2;
    const ASK_ENDING = 4;
    const OPEN_MENU = 8;
}

// Turns the actions of the match screen into engine calls and keeps what
// the engine does not: the clock, the pause, the notice and the point that
// waits for its ending in detailed mode. After every change it stores the
// log and tells the recorder, which it also pauses with the clock. It never
// draws and reaches the watch only through the recorder and the store, so
// every rule here runs in a unit test.
class MatchController {
    // Indexed by MatchAction.
    hidden const HANDLERS = [:ignore, :pointForMe, :pointForOpponent, :fault, :undo, :openMenu];

    hidden var _engine as MatchEngine;
    hidden var _setup as MatchSetup;
    hidden var _time as TimeSource;
    hidden var _clock as MatchClock;
    hidden var _notice as MatchNotice = new MatchNotice();
    hidden var _pendingWinner as Number = Player.NONE;
    hidden var _isEnded as Boolean = false;
    hidden var _recorder as MatchRecorder;
    hidden var _store as MatchStore;
    hidden var _farewellKey as Number? = null;
    hidden var _isSuspended as Boolean = false;

    // An engine that already has entries resumes that match: the clock
    // goes on from the time of the last entry.
    function initialize(engine as MatchEngine, setup as MatchSetup, time as TimeSource,
                        recorder as MatchRecorder, store as MatchStore) {
        _engine = engine;
        _setup = setup;
        _time = time;
        _recorder = recorder;
        _store = store;
        _clock = new MatchClock(time.now());
        begin();
    }

    hidden function begin() as Void {
        var log = _engine.log();
        _clock.advance(log.size() == 0 ? 0 : PointEntry.time(log.at(log.size() - 1)));
        writePointLog();
        _recorder.start(state().finishedSets(), state().isFinished());
        writeSummary(new MatchTags(null));
        if (state().isFinished()) {
            stopClock();
        }
    }

    hidden function stopClock() as Void {
        _clock.pause(_time.now());
        _recorder.pause();
    }

    hidden function runClock() as Void {
        _clock.resume(_time.now());
        _recorder.resume();
    }

    // Hands the newest entries to the activity file. It runs before the
    // session starts or stops, because the watch writes a record at both
    // and that record then carries them. On a resumed match the first
    // record so repeats the entries the file before it ended with.
    hidden function writePointLog() as Void {
        _recorder.writePointLog(_engine.slots());
    }

    // Stores the log and opens the lap of a new set.
    hidden function persist() as Void {
        _store.sync(_engine.log().toArray(), state().finishedSets(), _engine.marks());
        _recorder.closeSets(state().finishedSets(), state().isFinished(), MatchSummary.closedSetScore(state()));
    }

    // Brings the summary fields of the activity file up to date. They are
    // written when the match opens, so a file is a match of this app however
    // it ends, and again right before every save.
    hidden function writeSummary(tags as MatchTags) as Void {
        _recorder.writeSummary(MatchSummary.fields(_setup.toArray(), tags.toArray(), _engine));
    }

    // Runs one MatchAction and returns the Reaction flags.
    function handle(action as Number) as Number {
        return method(HANDLERS[action] as Symbol).invoke() as Number;
    }

    function ignore() as Number {
        return Reaction.NONE;
    }

    function pointForMe() as Number {
        return scorePoint(Player.ME);
    }

    function pointForOpponent() as Number {
        return scorePoint(Player.OPPONENT);
    }

    // In detailed mode the point waits until the player says how it ended.
    hidden function scorePoint(winner as Number) as Number {
        if (!isLive()) {
            return Reaction.NONE;
        }
        if (isDetailed()) {
            _pendingWinner = winner;
            return Reaction.ASK_ENDING;
        }
        return logPoint(winner, Ending.NONE);
    }

    // The point that waits for its ending, or Player.NONE.
    function pendingWinner() as Number {
        return _pendingWinner;
    }

    // Logs the waiting point with the ending picked from the list.
    function chooseEnding(ending as Number) as Number {
        var winner = _pendingWinner;
        _pendingWinner = Player.NONE;
        return winner == Player.NONE ? Reaction.NONE : logPoint(winner, ending);
    }

    // Leaving the list without a choice logs nothing.
    function cancelEnding() as Void {
        _pendingWinner = Player.NONE;
    }

    hidden function logPoint(winner as Number, ending as Number) as Number {
        var games = ScoreFixer.gamesPlayed(state());
        var sets = state().finishedSets();
        if (!_engine.point(winner, ending, clockSeconds(), heartRate())) {
            return Reaction.NONE;
        }
        return afterEntry(games, sets);
    }

    // START logs a serve fault. While paused it resumes instead, so the
    // button that started the pause from the menu also ends it.
    function fault() as Number {
        if (isPaused()) {
            togglePause();
            return Reaction.REFRESH;
        }
        var games = ScoreFixer.gamesPlayed(state());
        var sets = state().finishedSets();
        if (!isLive() || !_engine.fault(clockSeconds(), heartRate())) {
            return Reaction.NONE;
        }
        return afterEntry(games, sets);
    }

    // Shows what the entry closed and stops the clock when it ended the match.
    hidden function afterEntry(gamesBefore as Number, setsBefore as Number) as Number {
        _notice.show(noticeKeysSince(gamesBefore, setsBefore), _time.now());
        writePointLog();
        persist();
        if (state().isFinished()) {
            stopClock();
        }
        return state().isChangeOfEndsDue() ? Reaction.REFRESH | Reaction.VIBRATE : Reaction.REFRESH;
    }

    // The end of the match has its own screen, so it needs no notice, and
    // the engine never asks for a change of ends after it.
    hidden function noticeKeysSince(gamesBefore as Number, setsBefore as Number) as Array<Number> {
        var keys = [] as Array<Number>;
        var closed = closedKey(gamesBefore, setsBefore);
        if (closed != null && !state().isFinished()) {
            keys.add(closed);
        }
        if (state().isChangeOfEndsDue()) {
            keys.add(Str.NoticeChangeEnds);
        }
        return keys;
    }

    // What the last entry closed: a set, a game or nothing.
    hidden function closedKey(gamesBefore as Number, setsBefore as Number) as Number? {
        if (state().finishedSets() > setsBefore) {
            return Str.NoticeSet;
        }
        return ScoreFixer.gamesPlayed(state()) > gamesBefore ? Str.NoticeGame : null;
    }

    // Removes the last entry. Nothing is scored or undone during a pause.
    function undo() as Number {
        if (isPaused() || !_engine.undo()) {
            return Reaction.NONE;
        }
        return afterCorrection();
    }

    // A correction can reopen a finished match or finish an open one.
    hidden function afterCorrection() as Number {
        _notice.clear();
        writePointLog();
        if (state().isFinished()) {
            stopClock();
        } else {
            runClock();
        }
        persist();
        return Reaction.REFRESH;
    }

    function openMenu() as Number {
        return Reaction.OPEN_MENU;
    }

    // Fix the score.

    function undoGame() as Number {
        return ScoreFixer.undoGame(_engine) ? afterCorrection() : Reaction.NONE;
    }

    function awardGame(player as Number) as Number {
        return ScoreFixer.awardGame(_engine, player, clockSeconds(), _recorder) ? afterCorrection() : Reaction.NONE;
    }

    // Pause and end.

    function togglePause() as Void {
        if (_clock.isRunning()) {
            stopClock();
        } else if (!isOver()) {
            runClock();
        }
    }

    // Ends the match from the menu before it is decided.
    function end() as Void {
        _isEnded = true;
        stopClock();
    }

    // Save, discard and the app closing.

    // Keeps the activity, with the tags the player gave it, and forgets the
    // stored match.
    function save(tags as MatchTags) as Void {
        close(Str.SavedMsg);
        writeSummary(tags);
        _recorder.save();
    }

    function discard() as Void {
        close(Str.DiscardedMsg);
        _recorder.discard();
    }

    hidden function close(farewellKey as Number) as Void {
        _farewellKey = farewellKey;
        _store.clear();
    }

    // The message to leave with once the match was saved or discarded.
    function farewellKey() as Number? {
        return _farewellKey;
    }

    // The app is closing with the match still open. What was recorded so
    // far is saved without tags, and a match that is not over stays stored
    // to resume. The watch may report the closing more than once.
    function suspend() as Void {
        if (_farewellKey == null && !_isSuspended) {
            _isSuspended = true;
            writeSummary(new MatchTags(null));
            _recorder.save();
            if (isOver()) {
                _store.clear();
            }
        }
    }

    // Once a second while the match screen shows.
    function tick() as Void {
        _recorder.sample();
    }

    function heartRate() as Number? {
        return _recorder.heartRate();
    }

    // Goes back from the final screen to the match. A decided match gets
    // its last entry removed, since a decided match takes no more points.
    function reopen() as Void {
        _isEnded = false;
        if (state().isFinished()) {
            _engine.undo();
        }
        afterCorrection();
    }

    // Readers for the screen.

    function isDetailed() as Boolean {
        return _setup.isDetailed();
    }

    // The numbers of the report, counted from the log when asked for.
    function statistics() as MatchStatistics {
        return _engine.statistics();
    }

    function sensors() as BodySensors {
        return _recorder.sensors();
    }

    function state() as MatchState {
        return _engine.state();
    }

    // True once the match is decided or was ended from the menu: the final
    // screen takes over.
    function isOver() as Boolean {
        return _isEnded || state().isFinished();
    }

    function isPaused() as Boolean {
        return !_clock.isRunning() && !isOver();
    }

    hidden function isLive() as Boolean {
        return _clock.isRunning() && !isOver();
    }

    function clockSeconds() as Number {
        return _clock.seconds(_time.now());
    }

    function noticeKeys() as Array<Number> {
        return _notice.keys(_time.now());
    }
}
