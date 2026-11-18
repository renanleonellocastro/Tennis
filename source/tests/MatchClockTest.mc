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
    function testNoticeShowsItsKeyForFourSeconds(logger as Test.Logger) as Boolean {
        var notice = new MatchNotice();
        Test.assert(notice.key(0) == null);
        notice.show(Str.NoticeGame, 1000, false);
        Test.assertEqual(notice.key(1000) as Number, Str.NoticeGame);
        Test.assertEqual(notice.key(1000 + MatchNotice.VISIBLE_MS - 1) as Number, Str.NoticeGame);
        Test.assert(notice.key(1000 + MatchNotice.VISIBLE_MS) == null);
        notice.show(null, 2000, false);
        Test.assert(notice.key(2000) == null);
        return true;
    }

    (:test)
    function testNoticeThatStaysOutlivesTheFourSeconds(logger as Test.Logger) as Boolean {
        var notice = new MatchNotice();
        notice.show(Str.NoticeChangeEnds, 0, true);
        Test.assertEqual(notice.key(MatchNotice.VISIBLE_MS * 100) as Number, Str.NoticeChangeEnds);
        notice.show(Str.NoticeGame, 0, false);
        Test.assert(notice.key(MatchNotice.VISIBLE_MS) == null);
        return true;
    }

    (:test)
    function testNoticeCanBeCleared(logger as Test.Logger) as Boolean {
        var notice = new MatchNotice();
        notice.show(Str.NoticeSet, 0, true);
        notice.clear();
        Test.assert(notice.key(1) == null);
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
