import Toybox.Lang;

// What an input on the practice screen asks for. Practice shares the keys,
// the taps and the layout of the match screen, so each action is the match
// action that the same input sends there.
module PracticeAction {
    const NONE = MatchAction.NONE;
    const HIT = MatchAction.POINT_ME;
    const MISS = MatchAction.POINT_OPPONENT;
    const CLOSE_BLOCK = MatchAction.FAULT;
    const UNDO = MatchAction.UNDO;
    const MENU = MatchAction.MENU;
}

// Turns the actions of the practice screen into counts and keeps the clock,
// the pause and the end. After every change it tells the recorder, which it
// also pauses with the clock. It never draws and reaches the watch only
// through the recorder, so every rule here runs in a unit test.
class PracticeController {
    // Indexed by PracticeAction.
    hidden const HANDLERS = [:ignore, :hit, :miss, :closeBlock, :undo, :openMenu];

    hidden var _log as PracticeLog = new PracticeLog();
    hidden var _time as TimeSource;
    hidden var _clock as MatchClock;
    hidden var _recorder as PracticeRecorder;
    hidden var _isEnded as Boolean = false;
    hidden var _farewellKey as Number? = null;
    hidden var _isSuspended as Boolean = false;

    function initialize(time as TimeSource, recorder as PracticeRecorder) {
        _time = time;
        _recorder = recorder;
        _clock = new MatchClock(time.now());
        _recorder.start();
    }

    hidden function stopClock() as Void {
        _clock.pause(_time.now());
        _recorder.pause();
    }

    hidden function runClock() as Void {
        _clock.resume(_time.now());
        _recorder.resume();
    }

    // Runs one PracticeAction and returns the Reaction flags.
    function handle(action as Number) as Number {
        return method(HANDLERS[action] as Symbol).invoke() as Number;
    }

    function ignore() as Number {
        return Reaction.NONE;
    }

    // Nothing is counted or undone during a pause or after the end.
    function hit() as Number {
        if (!isLive()) {
            return Reaction.NONE;
        }
        _log.hit();
        return afterEntry();
    }

    function miss() as Number {
        if (!isLive()) {
            return Reaction.NONE;
        }
        _log.miss();
        return afterEntry();
    }

    function undo() as Number {
        return isLive() && _log.undo() ? afterEntry() : Reaction.NONE;
    }

    hidden function afterEntry() as Number {
        _recorder.setBlock(_log.hits(), _log.misses());
        return Reaction.REFRESH;
    }

    // START closes the block and opens the next. While paused it resumes
    // instead, so the button that started the pause from the menu also
    // ends it. The watch vibrates, since a block is closed without looking.
    function closeBlock() as Number {
        if (isPaused()) {
            togglePause();
            return Reaction.REFRESH;
        }
        if (!isLive() || !_log.closeBlock()) {
            return Reaction.NONE;
        }
        _recorder.closeBlock();
        return Reaction.REFRESH | Reaction.VIBRATE;
    }

    function openMenu() as Number {
        return Reaction.OPEN_MENU;
    }

    // Pause and end.

    function togglePause() as Void {
        if (_clock.isRunning()) {
            stopClock();
        } else if (!isOver()) {
            runClock();
        }
    }

    // Ends the practice from the menu: the summary takes over.
    function end() as Void {
        _isEnded = true;
        stopClock();
    }

    // Goes back from the summary to the practice.
    function reopen() as Void {
        _isEnded = false;
        runClock();
    }

    // Save, discard and the app closing.

    function save() as Void {
        _farewellKey = Str.SavedMsg;
        _recorder.save();
    }

    function discard() as Void {
        _farewellKey = Str.DiscardedMsg;
        _recorder.discard();
    }

    // The message to leave with once the practice was saved or discarded.
    function farewellKey() as Number? {
        return _farewellKey;
    }

    // The app is closing with the practice still open: what was recorded so
    // far is saved. A practice cannot be resumed, its counts go with it.
    // The watch may report the closing more than once.
    function suspend() as Void {
        if (_farewellKey == null && !_isSuspended) {
            _isSuspended = true;
            _recorder.save();
        }
    }

    // Once a second while the practice screen shows.
    function tick() as Void {
        _recorder.sample();
    }

    // Readers for the screen.

    function log() as PracticeLog {
        return _log;
    }

    function heartRate() as Number? {
        return _recorder.heartRate();
    }

    function isOver() as Boolean {
        return _isEnded;
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
}
