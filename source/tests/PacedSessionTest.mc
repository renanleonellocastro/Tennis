import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

// Tests for the session that gives the watch time to write its records,
// and for the alarm it waits on.

module PacedSessionTests {
    class Bench {
        var session as FakeSession = new FakeSession();
        var alarm as FakeAlarm = new FakeAlarm();
        var paced as PacedSession;

        function initialize() {
            paced = new PacedSession(session, alarm);
        }

        // Hands over the point log field once for each entry, as a game
        // given by the fix of the score does.
        function log(first as Number, last as Number) as Void {
            for (var sequence = first; sequence <= last; sequence++) {
                paced.setField(RecordingFields.POINT_LOG, [sequence, 0, 0, 0, 0, 0, 0, 0, 0] as Array<Number>);
            }
        }
    }

    // Counts how often the alarm called, and can ask for one more ring.
    class Bell {
        var rings as Number = 0;
        var again as WatchAlarm? = null;

        function onRing() as Void {
            rings++;
            var alarm = again;
            again = null;
            if (alarm != null) {
                alarm.ring(60000, method(:onRing));
            }
        }
    }

    (:test)
    function testStartReachesTheSessionAtOnce(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.start();
        Test.assertEqual(bench.session.calls, "s");
        Test.assertEqual(bench.alarm.delays[0], bench.paced.SETTLE_MS);
        return true;
    }

    (:test)
    function testStopRightAfterTheStartWaits(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.start();
        bench.paced.stop();
        Test.assertEqual(bench.session.calls, "s");
        bench.alarm.pass();
        Test.assertEqual(bench.session.calls, "sp");
        return true;
    }

    (:test)
    function testStopOfAnOldStartIsDoneAtOnce(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.start();
        bench.alarm.pass();
        Test.assert(!bench.alarm.isWaiting());
        bench.paced.stop();
        Test.assertEqual(bench.session.calls, "sp");
        Test.assert(bench.alarm.isWaiting());
        return true;
    }

    (:test)
    function testSaveRightAfterTheStopWaits(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.start();
        bench.alarm.pass();
        bench.paced.stop();
        bench.paced.save();
        Test.assertEqual(bench.session.calls, "sp");
        bench.alarm.pass();
        Test.assertEqual(bench.session.calls, "spS");
        Test.assert(!bench.alarm.isWaiting());
        return true;
    }

    (:test)
    function testSaveOfAnOldStopIsDoneAtOnce(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.start();
        bench.alarm.pass();
        bench.paced.stop();
        bench.alarm.pass();
        bench.paced.save();
        Test.assertEqual(bench.session.calls, "spS");
        return true;
    }

    // The match is reopened, finished again and saved inside one second.
    (:test)
    function testStopAndSaveRightAfterAStartTakeTwoWaits(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.start();
        bench.paced.stop();
        bench.paced.save();
        Test.assertEqual(bench.session.calls, "s");
        bench.alarm.pass();
        Test.assertEqual(bench.session.calls, "sp");
        bench.alarm.pass();
        Test.assertEqual(bench.session.calls, "spS");
        return true;
    }

    (:test)
    function testStartWhileAStopWaitsKeepsTheTimerRunning(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.start();
        bench.paced.stop();
        bench.paced.start();
        bench.alarm.pass();
        Test.assertEqual(bench.session.calls, "s");
        Test.assert(!bench.alarm.isWaiting());
        return true;
    }

    (:test)
    function testEveryRecordCarriesTheFieldsOfItsMoment(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.setField(RecordingFields.POINT_LOG, [1] as Array<Number>);
        bench.paced.start();
        bench.paced.setField(RecordingFields.POINT_LOG, [2] as Array<Number>);
        bench.paced.stop();
        bench.paced.save();
        bench.alarm.pass();
        bench.alarm.pass();
        Test.assertEqual(bench.session.records.toString(), "[1, 2]");
        return true;
    }

    // The field holds three entries: seven entries logged at once reach
    // the file in three values, each one wait after the other.
    (:test)
    function testEntriesLoggedAtOnceReachTheFileThreeAtATime(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.log(1, 7);
        Test.assertEqual(bench.session.written.toString(), "[1]");
        bench.alarm.pass();
        Test.assertEqual(bench.session.written.toString(), "[1, 4]");
        bench.alarm.pass();
        Test.assertEqual(bench.session.written.toString(), "[1, 4, 7]");
        bench.alarm.pass();
        Test.assert(!bench.alarm.isWaiting());
        return true;
    }

    (:test)
    function testAnEntryInsideTheWaitReplacesNothingTheFileMisses(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.log(1, 1);
        bench.alarm.pass();
        bench.log(2, 3);
        Test.assertEqual(bench.session.written.toString(), "[1, 2]");
        bench.alarm.pass();
        Test.assertEqual(bench.session.written.toString(), "[1, 2, 3]");
        return true;
    }

    (:test)
    function testAnUndoDropsTheWaitingValuesItRemoves(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.log(1, 7);
        bench.log(2, 2);
        bench.alarm.pass();
        Test.assertEqual(bench.session.written.toString(), "[1, 2]");
        bench.log(3, 5);
        bench.alarm.pass();
        Test.assertEqual(bench.session.written.toString(), "[1, 2, 5]");
        return true;
    }

    (:test)
    function testAnUndoBelowWhatTheFileHasIsWrittenInItsTurn(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.log(1, 5);
        bench.alarm.pass();
        bench.log(2, 2);
        bench.log(3, 6);
        bench.alarm.pass();
        bench.alarm.pass();
        Test.assertEqual(bench.session.written.toString(), "[1, 4, 5, 6]");
        return true;
    }

    // The record of the stop carries the last value, so the stop follows
    // it at once, and only after every value had its wait.
    (:test)
    function testStopWaitsForTheValuesAndFollowsTheLastAtOnce(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.start();
        bench.alarm.pass();
        bench.log(1, 5);
        bench.paced.stop();
        bench.paced.save();
        Test.assertEqual(bench.session.calls, "s");
        bench.alarm.pass();
        Test.assertEqual(bench.session.calls, "s");
        bench.alarm.pass();
        Test.assertEqual(bench.session.calls, "sp");
        Test.assertEqual(bench.session.records.toString(), "[0, 5]");
        Test.assertEqual(bench.session.written.toString(), "[1, 4, 5]");
        bench.alarm.pass();
        Test.assertEqual(bench.session.calls, "spS");
        return true;
    }

    (:test)
    function testDiscardDropsTheValuesThatWait(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.log(1, 7);
        bench.paced.discard();
        bench.alarm.pass();
        Test.assertEqual(bench.session.written.toString(), "[1]");
        Test.assert(!bench.alarm.isWaiting());
        return true;
    }

    // A game given from 0-0 logs four points at once. No value of the
    // field may be more than three entries ahead of the one before.
    (:test)
    function testAGameGivenByTheFixReachesTheFileWhole(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        var match = new MatchBench(MatchFormat.TIE_BREAK_ONLY, false);
        match.session = bench.session;
        var recorder = new MatchRecorder(bench.paced, match.sensors, match.locator);
        var controller = new MatchController(match.engine, match.setupOf(MatchFormat.TIE_BREAK_ONLY, false),
                                             match.time, recorder, match.store);
        controller.awardGame(Player.OPPONENT);
        while (bench.alarm.isWaiting()) {
            bench.alarm.pass();
        }
        var written = bench.session.written;
        Test.assertEqual(written[written.size() - 1], match.engine.log().size());
        for (var i = 1; i < written.size(); i++) {
            Test.assert(written[i] - written[i - 1] <= PointSlot.SLOTS);
        }
        Test.assert(written[0] <= PointSlot.SLOTS);
        return true;
    }

    (:test)
    function testDiscardDropsWhatWaits(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.start();
        bench.paced.stop();
        bench.paced.save();
        bench.paced.discard();
        bench.alarm.pass();
        Test.assertEqual(bench.session.calls, "sD");
        return true;
    }

    (:test)
    function testLapsAndFieldsPassStraightThrough(logger as Test.Logger) as Boolean {
        var bench = new Bench();
        bench.paced.setField(RecordingFields.SET_STEPS, 12);
        bench.paced.setField(RecordingFields.SET_DISTANCE, 7);
        bench.paced.addLap();
        Test.assertEqual(bench.session.calls, "l");
        Test.assertEqual(bench.session.laps[0].toString(), "[12, 7]");
        return true;
    }

    (:test)
    function testWatchAlarmRingNowCallsWhatWaits(logger as Test.Logger) as Boolean {
        var alarm = new WatchAlarm();
        var bell = new Bell();
        alarm.ring(60000, bell.method(:onRing));
        alarm.ringNow();
        Test.assertEqual(bell.rings, 1);
        alarm.ringNow();
        Test.assertEqual(bell.rings, 1);
        return true;
    }

    (:test)
    function testWatchAlarmRingNowFollowsARingMadeByTheCallback(logger as Test.Logger) as Boolean {
        var alarm = new WatchAlarm();
        var bell = new Bell();
        bell.again = alarm;
        alarm.ring(60000, bell.method(:onRing));
        alarm.ringNow();
        Test.assertEqual(bell.rings, 2);
        return true;
    }

    (:test)
    function testWatchAlarmIsWaitingUntilItRings(logger as Test.Logger) as Boolean {
        var alarm = new WatchAlarm();
        Test.assert(!alarm.isWaiting());
        alarm.ring(60000, new Bell().method(:onRing));
        Test.assert(alarm.isWaiting());
        alarm.onTimer();
        Test.assert(!alarm.isWaiting());
        return true;
    }

    (:test)
    function testFlowIsSavingWhileTheAppAlarmWaits(logger as Test.Logger) as Boolean {
        var alarm = (Application.getApp() as TennisApp).alarm;
        Test.assert(!MatchFlow.isSaving());
        alarm.ring(60000, new Bell().method(:onRing));
        Test.assert(MatchFlow.isSaving());
        alarm.ringNow();
        Test.assert(!MatchFlow.isSaving());
        return true;
    }

    (:test)
    function testWatchAlarmTimerWithNothingWaitingDoesNothing(logger as Test.Logger) as Boolean {
        new WatchAlarm().onTimer();
        return true;
    }

    (:test)
    function testWatchAlarmNewRingReplacesTheOneThatWaits(logger as Test.Logger) as Boolean {
        var alarm = new WatchAlarm();
        var first = new Bell();
        var second = new Bell();
        alarm.ring(60000, first.method(:onRing));
        alarm.ring(60000, second.method(:onRing));
        alarm.ringNow();
        Test.assertEqual(first.rings, 0);
        Test.assertEqual(second.rings, 1);
        return true;
    }
}
