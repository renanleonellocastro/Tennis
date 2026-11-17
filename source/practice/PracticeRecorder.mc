import Toybox.Lang;

// Records a practice as an activity. The session, the pauses, the steps and
// the distance are the work of the match recorder, which counts a closed
// block as it counts a closed set: one lap each. This class adds the two
// lap fields with the hits and misses of the block.
class PracticeRecorder {
    hidden var _session as ActivitySession;
    hidden var _recorder as MatchRecorder;
    hidden var _closedBlocks as Number = 0;

    function initialize(session as ActivitySession, sensors as BodySensors, locator as Locator) {
        _session = session;
        _recorder = new MatchRecorder(session, sensors, locator);
    }

    function start() as Void {
        setBlock(0, 0);
        _recorder.start(0, false);
    }

    // The counts of the open block. A lap takes the values its fields hold
    // when it closes, so they are written after every entry.
    function setBlock(hits as Number, misses as Number) as Void {
        _session.setField(RecordingFields.BLOCK_HITS, hits);
        _session.setField(RecordingFields.BLOCK_MISSES, misses);
    }

    // Closes the lap of the block and starts the next one from zero.
    function closeBlock() as Void {
        _closedBlocks++;
        _recorder.closeSets(_closedBlocks, false);
        setBlock(0, 0);
    }

    function pause() as Void {
        _recorder.pause();
    }

    function resume() as Void {
        _recorder.resume();
    }

    function sample() as Void {
        _recorder.sample();
    }

    function save() as Void {
        _recorder.save();
    }

    function discard() as Void {
        _recorder.discard();
    }

    function heartRate() as Number? {
        return _recorder.heartRate();
    }
}
