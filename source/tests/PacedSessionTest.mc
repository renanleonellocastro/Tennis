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
