import Toybox.Lang;

// Records a match as an activity: it starts, pauses and closes the session,
// opens one lap per set and keeps the steps and distance fields current.
class MatchRecorder {
    hidden var _session as ActivitySession;
    hidden var _sensors as BodySensors;
    hidden var _locator as Locator;
    hidden var _motion as MotionTracker = new MotionTracker();
    hidden var _isRunning as Boolean = false;
    hidden var _laps as Number = 0;

    function initialize(session as ActivitySession, sensors as BodySensors, locator as Locator) {
        _session = session;
        _sensors = sensors;
        _locator = locator;
    }

    // The sets already closed (a resumed match) had their lap in the
    // activity recorded before, so this one opens none for them.
    function start(finishedSets as Number, isFinished as Boolean) as Void {
        _laps = lapsDue(finishedSets, isFinished);
        _locator.turnOn();
        resume();
    }

    // One lap per closed set, but none for the set that ends the match:
    // saving closes that lap.
    hidden function lapsDue(finishedSets as Number, isFinished as Boolean) as Number {
        return isFinished ? finishedSets - 1 : finishedSets;
    }

    function resume() as Void {
        if (!_isRunning) {
            sample();
            _motion.resume();
            _session.start();
            _isRunning = true;
        }
    }

    function pause() as Void {
        if (_isRunning) {
            sample();
            _motion.pause();
            _session.stop();
            _isRunning = false;
        }
    }

    // Reads the counters of the watch and writes the fields. Called once a
    // second by the match screen and before every lap, pause and save.
    function sample() as Void {
        _motion.update(_sensors.steps(), _sensors.distanceCm());
        _session.setField(RecordingFields.STEPS, _motion.steps());
        _session.setField(RecordingFields.DISTANCE, _motion.meters());
        _session.setField(RecordingFields.SET_STEPS, _motion.lapSteps());
        _session.setField(RecordingFields.SET_DISTANCE, _motion.lapMeters());
    }

    // Opens the lap of the next set once a set is closed, after giving the
    // closing lap the score of its set. A lap cannot be taken back, so a
    // set that is undone and played again keeps its first lap.
    function closeSets(finishedSets as Number, isFinished as Boolean, closedScore as Array<Number>) as Void {
        if (lapsDue(finishedSets, isFinished) > _laps) {
            _session.setField(RecordingFields.SET_SCORE, closedScore);
            closeLap();
        }
    }

    // Closes the open lap with the steps and distance it reached and
    // starts the next one from zero.
    function closeLap() as Void {
        sample();
        _session.addLap();
        _motion.closeLap();
        _laps++;
        sample();
    }

    // What the file says about the match as a whole and about the set of
    // the lap that is open: [setup word, score text, statistics, set score].
    function writeSummary(summary as Array) as Void {
        _session.setField(RecordingFields.MATCH_SETUP, summary[0] as Number);
        _session.setField(RecordingFields.FINAL_SCORE, summary[1] as String);
        _session.setField(RecordingFields.STATISTICS, summary[2] as Array<Number>);
        _session.setField(RecordingFields.SET_SCORE, summary[3] as Array<Number>);
    }

    function save() as Void {
        finish();
        _session.save();
    }

    function discard() as Void {
        finish();
        _session.discard();
    }

    hidden function finish() as Void {
        pause();
        _locator.turnOff();
    }

    function heartRate() as Number? {
        return _sensors.heartRate();
    }

    function sensors() as BodySensors {
        return _sensors;
    }
}
