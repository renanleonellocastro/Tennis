import Toybox.Lang;

// What the screen has to do after an input: flags, and above them the Cue
// the watch plays so the player feels what the press did.
module Reaction {
    const NONE = 0;
    const REFRESH = 1;
    const ASK_ENDING = 4;
    const OPEN_MENU = 8;
    const CUE = 16;

    function withCue(cue as Number) as Number {
        return REFRESH + CUE * cue;
    }

    function cueOf(reaction as Number) as Number {
        return reaction / CUE;
    }
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
    // A press during a pause only ends the pause, so no point is lost.
    hidden function scorePoint(winner as Number) as Number {
        if (isPaused()) {
            return wake();
        }
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
        return afterEntry(games, sets, Cue.POINT);
    }

    // Ends the pause, with a buzz that says the match is on again.
    hidden function wake() as Number {
        togglePause();
        return Reaction.withCue(Cue.GAME);
    }

    // START logs a serve fault. While paused it resumes instead, so the
    // button that started the pause from the menu also ends it.
    function fault() as Number {
        if (isPaused()) {
            return wake();
        }
        var games = ScoreFixer.gamesPlayed(state());
        var sets = state().finishedSets();
        if (!isLive() || !_engine.fault(clockSeconds(), heartRate())) {
            return Reaction.NONE;
        }
        return afterEntry(games, sets, Cue.FAULT);
    }

    // Shows what the entry closed and stops the clock when it ended the
    // match. The cue of the entry gives way to a heavier one: a game, and
    // the long one for a set, a change of ends or the end of the match.
    hidden function afterEntry(gamesBefore as Number, setsBefore as Number, cue as Number) as Number {
        var closed = closedKey(gamesBefore, setsBefore);
        writePointLog();
        persist();
        if (state().isFinished()) {
            stopClock();
        }
        if (announce(closed) || state().isFinished() || closed == Str.NoticeSet) {
            return Reaction.withCue(Cue.LONG);
        }
        return Reaction.withCue(closed == null ? cue : Cue.GAME);
    }

    // Shows the notice of what was closed and returns true when the players
    // change ends. That notice stands alone and stays until the next entry,
    // since it is read on the way to the bench. The end of the match has its
    // own screen and needs no notice.
    hidden function announce(closed as Number?) as Boolean {
        var isChange = !state().isFinished() && state().isChangeOfEndsDue();
        var key = state().isFinished() ? null : closed;
        _notice.show(isChange ? Str.NoticeChangeEnds : key, _time.now(), isChange);
        return isChange;
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
        return corrected(Cue.UNDO);
    }

    // A correction can reopen a finished match or finish an open one.
    hidden function corrected(cue as Number) as Number {
        _notice.clear();
        writePointLog();
        if (state().isFinished()) {
            stopClock();
        } else {
            runClock();
        }
        persist();
        return Reaction.withCue(cue);
    }

    function openMenu() as Number {
        return Reaction.OPEN_MENU;
    }

    // Fix the score.

    function undoGame() as Number {
        return fixed(ScoreFixer.undoGame(_engine));
    }

    function awardGame(player as Number) as Number {
        return fixed(ScoreFixer.awardGame(_engine, player, clockSeconds(), _recorder));
    }

    // A fix that worked says so with the game notice and the game cue.
    hidden function fixed(isDone as Boolean) as Number {
        if (!isDone) {
            return Reaction.NONE;
        }
        var reaction = corrected(Cue.GAME);
        announce(Str.NoticeGame);
        return reaction;
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
    function reopen() as Number {
        _isEnded = false;
        if (state().isFinished()) {
            _engine.undo();
        }
        return corrected(Cue.UNDO);
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

    function noticeKey() as Number? {
        return _notice.key(_time.now());
    }
}
