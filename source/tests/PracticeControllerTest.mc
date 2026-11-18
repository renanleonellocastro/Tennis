import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

// Tests for the practice controller and its recorder: counting, blocks and
// laps, pause, end, save, discard and the app closing.
module PracticeTests {
    (:test)
    function testPracticeStartsTheRecordingWithIt(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        Test.assertEqual(bench.session.calls, "s");
        Test.assertEqual(bench.locator.calls, "+");
        Test.assertEqual(bench.field(RecordingFields.BLOCK_HITS), 0);
        Test.assertEqual(bench.field(RecordingFields.BLOCK_MISSES), 0);
        Test.assertEqual(bench.tally(), "1 0-0");
        Test.assert(!bench.controller.isPaused());
        Test.assert(!bench.controller.isOver());
        return true;
    }

    (:test)
    function testTheKeysOfTheMatchSendThePracticeActions(logger as Test.Logger) as Boolean {
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_UP), PracticeAction.HIT);
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_DOWN), PracticeAction.MISS);
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_ENTER), PracticeAction.CLOSE_BLOCK);
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_ESC), PracticeAction.UNDO);
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_LIGHT), PracticeAction.NONE);
        return true;
    }

    (:test)
    function testTheTapsOfTheMatchSendThePracticeActions(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(416, 416, true, true);
        Test.assertEqual(MatchInput.actionForTap(100, 200, layout), PracticeAction.HIT);
        Test.assertEqual(MatchInput.actionForTap(300, 200, layout), PracticeAction.MISS);
        Test.assertEqual(MatchInput.actionForTap(100, 320, layout), PracticeAction.MENU);
        Test.assertEqual(MatchInput.actionForTap(300, 320, layout), PracticeAction.CLOSE_BLOCK);
        return true;
    }

    (:test)
    function testHitAndMissCountAndRefresh(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        Test.assertEqual(bench.play("H"), Reaction.REFRESH);
        Test.assertEqual(bench.play("X"), Reaction.REFRESH);
        bench.play("H");
        Test.assertEqual(bench.tally(), "1 2-1");
        return true;
    }

    (:test)
    function testEveryEntryUpdatesTheBlockFields(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HHX");
        Test.assertEqual(bench.field(RecordingFields.BLOCK_HITS), 2);
        Test.assertEqual(bench.field(RecordingFields.BLOCK_MISSES), 1);
        return true;
    }

    (:test)
    function testUndoTakesBackTheLastEntryAndItsField(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HX");
        Test.assertEqual(bench.play("U"), Reaction.REFRESH);
        Test.assertEqual(bench.tally(), "1 1-0");
        Test.assertEqual(bench.field(RecordingFields.BLOCK_MISSES), 0);
        bench.play("U");
        Test.assertEqual(bench.play("U"), Reaction.NONE);
        Test.assertEqual(bench.field(RecordingFields.BLOCK_HITS), 0);
        return true;
    }

    (:test)
    function testClosingABlockWritesItsLapAndVibrates(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HHX");
        Test.assertEqual(bench.play("N"), Reaction.REFRESH | Reaction.VIBRATE);
        Test.assertEqual(bench.session.calls, "sl");
        Test.assertEqual(bench.session.blocks[0][0], 2);
        Test.assertEqual(bench.session.blocks[0][1], 1);
        Test.assertEqual(bench.tally(), "2 0-0");
        return true;
    }

    (:test)
    function testTheNextBlockStartsItsFieldsFromZero(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HHXN");
        Test.assertEqual(bench.field(RecordingFields.BLOCK_HITS), 0);
        Test.assertEqual(bench.field(RecordingFields.BLOCK_MISSES), 0);
        bench.play("X");
        Test.assertEqual(bench.field(RecordingFields.BLOCK_MISSES), 1);
        return true;
    }

    (:test)
    function testEveryClosedBlockHasItsOwnLap(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HNXXNHXN");
        Test.assertEqual(bench.session.calls, "slll");
        Test.assertEqual(bench.session.blocks[1][0], 0);
        Test.assertEqual(bench.session.blocks[1][1], 2);
        Test.assertEqual(bench.session.blocks[2][0], 1);
        Test.assertEqual(bench.session.blocks[2][1], 1);
        return true;
    }

    (:test)
    function testAnEmptyBlockDoesNotCloseOrAddALap(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        Test.assertEqual(bench.play("N"), Reaction.NONE);
        bench.play("HN");
        Test.assertEqual(bench.play("N"), Reaction.NONE);
        Test.assertEqual(bench.session.calls, "sl");
        Test.assertEqual(bench.tally(), "2 0-0");
        return true;
    }

    (:test)
    function testUndoDoesNotReopenAClosedBlock(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HN");
        Test.assertEqual(bench.play("U"), Reaction.NONE);
        Test.assertEqual(bench.tally(), "2 0-0");
        Test.assertEqual(bench.controller.log().hitsOf(0), 1);
        return true;
    }

    (:test)
    function testLapStepsRestartWithEachBlock(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.sensors.walk(100, 9000);
        bench.controller.tick();
        bench.sensors.walk(30, 2500);
        bench.play("HN");
        bench.sensors.walk(4, 300);
        bench.controller.tick();
        Test.assertEqual(bench.session.laps[0][0], 30);
        Test.assertEqual(bench.field(RecordingFields.STEPS), 34);
        Test.assertEqual(bench.field(RecordingFields.SET_STEPS), 4);
        Test.assertEqual(bench.field(RecordingFields.DISTANCE), 28);
        return true;
    }

    (:test)
    function testMenuActionAsksForTheMenuAndUnknownDoesNothing(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        Test.assertEqual(bench.controller.handle(PracticeAction.MENU), Reaction.OPEN_MENU);
        Test.assertEqual(bench.controller.handle(PracticeAction.NONE), Reaction.NONE);
        return true;
    }

    (:test)
    function testPauseStopsTheSessionAndTheClock(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.time.ms = 10000;
        bench.controller.togglePause();
        bench.time.ms = 70000;
        Test.assert(bench.controller.isPaused());
        Test.assertEqual(bench.session.calls, "sp");
        Test.assertEqual(bench.controller.clockSeconds(), 10);
        bench.controller.togglePause();
        bench.time.ms = 75000;
        Test.assert(!bench.controller.isPaused());
        Test.assertEqual(bench.session.calls, "sps");
        Test.assertEqual(bench.controller.clockSeconds(), 15);
        return true;
    }

    (:test)
    function testNothingCountsDuringAPause(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HX");
        bench.controller.togglePause();
        Test.assertEqual(bench.play("H"), Reaction.NONE);
        Test.assertEqual(bench.play("X"), Reaction.NONE);
        Test.assertEqual(bench.play("U"), Reaction.NONE);
        Test.assertEqual(bench.tally(), "1 1-1");
        return true;
    }

    (:test)
    function testStartResumesAPauseInsteadOfClosingTheBlock(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("H");
        bench.controller.togglePause();
        Test.assertEqual(bench.play("N"), Reaction.REFRESH);
        Test.assert(!bench.controller.isPaused());
        Test.assertEqual(bench.tally(), "1 1-0");
        Test.assertEqual(bench.session.calls, "sps");
        return true;
    }

    (:test)
    function testEndStopsTheClockAndOpensTheSummary(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HX");
        bench.time.ms = 20000;
        bench.controller.end();
        bench.time.ms = 90000;
        Test.assert(bench.controller.isOver());
        Test.assert(!bench.controller.isPaused());
        Test.assertEqual(bench.session.calls, "sp");
        Test.assertEqual(bench.controller.clockSeconds(), 20);
        return true;
    }

    (:test)
    function testNothingChangesAfterTheEnd(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HX");
        bench.controller.end();
        Test.assertEqual(bench.play("H"), Reaction.NONE);
        Test.assertEqual(bench.play("X"), Reaction.NONE);
        Test.assertEqual(bench.play("U"), Reaction.NONE);
        Test.assertEqual(bench.play("N"), Reaction.NONE);
        bench.controller.togglePause();
        Test.assertEqual(bench.session.calls, "sp");
        Test.assertEqual(bench.tally(), "1 1-1");
        return true;
    }

    (:test)
    function testEndDuringAPauseKeepsTheSessionStopped(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.controller.togglePause();
        bench.controller.end();
        Test.assert(bench.controller.isOver());
        Test.assertEqual(bench.session.calls, "sp");
        return true;
    }

    (:test)
    function testReopenGoesOnWithThePractice(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("H");
        bench.controller.end();
        bench.controller.reopen();
        Test.assert(!bench.controller.isOver());
        Test.assert(!bench.controller.isPaused());
        Test.assertEqual(bench.session.calls, "sps");
        Test.assertEqual(bench.play("X"), Reaction.REFRESH);
        Test.assertEqual(bench.tally(), "1 1-1");
        return true;
    }

    (:test)
    function testSaveKeepsTheActivityWithTheOpenBlockOnItsLap(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HNHHX");
        bench.controller.end();
        Test.assert(bench.controller.farewellKey() == null);
        bench.controller.save();
        Test.assertEqual(bench.session.calls, "slpS");
        Test.assertEqual(bench.locator.calls, "+-");
        Test.assertEqual(bench.field(RecordingFields.BLOCK_HITS), 2);
        Test.assertEqual(bench.field(RecordingFields.BLOCK_MISSES), 1);
        Test.assertEqual(bench.controller.farewellKey() as Number, Str.SavedMsg);
        return true;
    }

    (:test)
    function testDiscardThrowsTheActivityAway(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("H");
        bench.controller.end();
        bench.controller.discard();
        Test.assertEqual(bench.session.calls, "spD");
        Test.assertEqual(bench.controller.farewellKey() as Number, Str.DiscardedMsg);
        return true;
    }

    (:test)
    function testClosingTheAppSavesAnOpenPracticeOnce(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.play("HX");
        bench.controller.suspend();
        bench.controller.suspend();
        Test.assertEqual(bench.session.calls, "spS");
        Test.assert(bench.controller.farewellKey() == null);
        return true;
    }

    (:test)
    function testClosingTheAppAfterSaveOrDiscardDoesNothing(logger as Test.Logger) as Boolean {
        var saved = new PracticeBench();
        saved.controller.save();
        saved.controller.suspend();
        Test.assertEqual(saved.session.calls, "spS");
        var discarded = new PracticeBench();
        discarded.controller.discard();
        discarded.controller.suspend();
        Test.assertEqual(discarded.session.calls, "spD");
        return true;
    }

    (:test)
    function testTickKeepsTheStepsFieldCurrent(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        bench.sensors.walk(100, 9000);
        bench.controller.tick();
        bench.sensors.walk(12, 1100);
        bench.controller.tick();
        Test.assertEqual(bench.field(RecordingFields.STEPS), 12);
        Test.assertEqual(bench.field(RecordingFields.DISTANCE), 11);
        return true;
    }

    (:test)
    function testHeartRateComesFromTheWatch(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        Test.assert(bench.controller.heartRate() == null);
        bench.sensors.beats = 142;
        Test.assertEqual(bench.controller.heartRate() as Number, 142);
        return true;
    }

    // The recorder on its own.

    (:test)
    function testRecorderPausesAndResumesTheSession(logger as Test.Logger) as Boolean {
        var session = new BlockSession();
        var recorder = new PracticeRecorder(session, new FakeSensors(), new FakeLocator());
        recorder.start();
        recorder.pause();
        recorder.pause();
        recorder.resume();
        recorder.resume();
        Test.assertEqual(session.calls, "sps");
        return true;
    }

    (:test)
    function testRecorderClosesOneLapPerCall(logger as Test.Logger) as Boolean {
        var session = new BlockSession();
        var recorder = new PracticeRecorder(session, new FakeSensors(), new FakeLocator());
        recorder.start();
        recorder.setBlock(7, 3);
        recorder.closeBlock();
        recorder.setBlock(1, 0);
        recorder.closeBlock();
        Test.assertEqual(session.calls, "sll");
        Test.assertEqual(session.blocks[0][0], 7);
        Test.assertEqual(session.blocks[0][1], 3);
        Test.assertEqual(session.blocks[1][0], 1);
        Test.assertEqual(session.fields[RecordingFields.BLOCK_HITS] as Number, 0);
        return true;
    }

    (:test)
    function testRecorderSamplesStepsAndReadsTheHeartRate(logger as Test.Logger) as Boolean {
        var session = new BlockSession();
        var sensors = new FakeSensors();
        var recorder = new PracticeRecorder(session, sensors, new FakeLocator());
        recorder.start();
        sensors.walk(10, 800);
        recorder.sample();
        sensors.walk(5, 400);
        recorder.sample();
        sensors.beats = 120;
        Test.assertEqual(session.fields[RecordingFields.STEPS] as Number, 5);
        Test.assertEqual(recorder.heartRate() as Number, 120);
        return true;
    }

    (:test)
    function testRecorderSavesOrDiscardsAfterStopping(logger as Test.Logger) as Boolean {
        var saved = new BlockSession();
        var kept = new PracticeRecorder(saved, new FakeSensors(), new FakeLocator());
        kept.start();
        kept.save();
        Test.assertEqual(saved.calls, "spS");
        var dropped = new BlockSession();
        var thrown = new PracticeRecorder(dropped, new FakeSensors(), new FakeLocator());
        thrown.start();
        thrown.discard();
        Test.assertEqual(dropped.calls, "spD");
        return true;
    }
}
