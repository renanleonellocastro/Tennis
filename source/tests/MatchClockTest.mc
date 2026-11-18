import Toybox.Lang;
import Toybox.System;
import Toybox.Test;

// Tests for the match clock and the short notice.
module MatchClockTests {
    (:test)
    function testClockCountsWholeSecondsFromItsStart(logger as Test.Logger) as Boolean {
        var clock = new MatchClock(5000);
        Test.assert(clock.isRunning());
        Test.assertEqual(clock.seconds(5000), 0);
        Test.assertEqual(clock.seconds(5999), 0);
        Test.assertEqual(clock.seconds(65000), 60);
        return true;
    }

    (:test)
    function testClockLeavesThePausesOut(logger as Test.Logger) as Boolean {
        var clock = new MatchClock(0);
        clock.pause(10000);
        Test.assert(!clock.isRunning());
        Test.assertEqual(clock.seconds(50000), 10);
        clock.resume(60000);
        Test.assert(clock.isRunning());
        Test.assertEqual(clock.seconds(65000), 15);
        return true;
    }

    (:test)
    function testClockIgnoresARepeatedPauseOrResume(logger as Test.Logger) as Boolean {
        var clock = new MatchClock(0);
        clock.resume(4000);
        Test.assertEqual(clock.seconds(10000), 10);
        clock.pause(10000);
        clock.pause(30000);
        Test.assertEqual(clock.seconds(40000), 10);
        return true;
    }

    (:test)
    function testNoticeShowsItsKeysForFourSeconds(logger as Test.Logger) as Boolean {
        var notice = new MatchNotice();
        Test.assertEqual(notice.keys(0).size(), 0);
        notice.show([Str.NoticeGame, Str.NoticeChangeEnds] as Array<Number>, 1000);
        Test.assertEqual(joined(notice.keys(1000)), joined([Str.NoticeGame, Str.NoticeChangeEnds]));
        Test.assertEqual(notice.keys(1000 + MatchNotice.VISIBLE_MS - 1).size(), 2);
        Test.assertEqual(notice.keys(1000 + MatchNotice.VISIBLE_MS).size(), 0);
        Test.assertEqual(notice.keys(1000).size(), 0);
        return true;
    }

    (:test)
    function testNoticeCanBeCleared(logger as Test.Logger) as Boolean {
        var notice = new MatchNotice();
        notice.show([Str.NoticeSet] as Array<Number>, 0);
        notice.clear();
        Test.assertEqual(notice.keys(1).size(), 0);
        return true;
    }

    (:test)
    function testSystemTimeReadsTheSystemTimer(logger as Test.Logger) as Boolean {
        var before = System.getTimer();
        var now = new SystemTime().now();
        Test.assert(now >= before && now <= System.getTimer());
        return true;
    }

    (:test)
    function testClockGoesOnFromAnAdvance(logger as Test.Logger) as Boolean {
        var clock = new MatchClock(1000);
        clock.advance(600);
        Test.assertEqual(clock.seconds(1000), 600);
        Test.assertEqual(clock.seconds(6000), 605);
        return true;
    }
}
