import Toybox.Lang;
import Toybox.Test;

// Tests for the controller: every action of the match screen in simple and
// detailed mode, the notices, the pause, the end and the corrections.
module MatchControllerTests {
    const CHANGE_ENDS = Reaction.REFRESH | Reaction.VIBRATE;

    (:test)
    function testUpAndDownScoreInSimpleMode(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(bench.play("M"), Reaction.REFRESH);
        Test.assertEqual(bench.play("O"), Reaction.REFRESH);
        Test.assertEqual(bench.score(), "0-0 0-0 15-15");
        Test.assertEqual(PointEntry.ending(bench.engine.log().at(0)), Ending.NONE);
        Test.assertEqual(bench.controller.handle(MatchAction.NONE), Reaction.NONE);
        Test.assertEqual(bench.engine.log().size(), 2);
        return true;
    }

    (:test)
    function testStartLogsAFaultAndTheSecondOneGivesThePoint(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(bench.play("F"), Reaction.REFRESH);
        Test.assert(bench.controller.state().isSecondServe());
        Test.assertEqual(bench.play("F"), Reaction.REFRESH);
        Test.assertEqual(bench.score(), "0-0 0-0 0-15");
        return true;
    }

    (:test)
    function testBackUndoesTheLastEntry(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(bench.play("U"), Reaction.NONE);
        Test.assertEqual(bench.play("MOU"), Reaction.REFRESH);
        Test.assertEqual(bench.score(), "0-0 0-0 15-0");
        Test.assertEqual(bench.play("FU"), Reaction.REFRESH);
        Test.assert(!bench.controller.state().isSecondServe());
        return true;
    }

    (:test)
    function testMenuActionAsksForTheMenu(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(bench.controller.handle(MatchAction.MENU), Reaction.OPEN_MENU);
        Test.assertEqual(bench.engine.log().size(), 0);
        return true;
    }

    (:test)
    function testEntriesCarryTheMatchClock(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.time.ms = 12000;
        bench.play("M");
        bench.time.ms = 31500;
        bench.play("F");
        Test.assertEqual(PointEntry.time(bench.engine.log().at(0)), 12);
        Test.assertEqual(PointEntry.time(bench.engine.log().at(1)), 31);
        Test.assertEqual(bench.controller.clockSeconds(), 31);
        return true;
    }

    // Detailed mode.

    (:test)
    function testDetailedPointWaitsForItsEnding(logger as Test.Logger) as Boolean {
        var bench = new MatchBench(MatchFormat.BEST_OF_3, true);
        Test.assertEqual(bench.play("O"), Reaction.ASK_ENDING);
        Test.assertEqual(bench.controller.pendingWinner(), Player.OPPONENT);
        Test.assertEqual(bench.engine.log().size(), 0);
        Test.assertEqual(bench.controller.chooseEnding(Ending.ERROR_NET), Reaction.REFRESH);
        Test.assertEqual(bench.score(), "0-0 0-0 0-15");
        Test.assertEqual(PointEntry.ending(bench.engine.log().at(0)), Ending.ERROR_NET);
        Test.assertEqual(bench.controller.pendingWinner(), Player.NONE);
        return true;
    }

    (:test)
    function testLeavingTheEndingListLogsNothing(logger as Test.Logger) as Boolean {
        var bench = new MatchBench(MatchFormat.BEST_OF_3, true);
        bench.play("M");
        bench.controller.cancelEnding();
        Test.assertEqual(bench.controller.pendingWinner(), Player.NONE);
        Test.assertEqual(bench.controller.chooseEnding(Ending.WINNER), Reaction.NONE);
        Test.assertEqual(bench.engine.log().size(), 0);
        return true;
    }

    (:test)
    function testDetailedModeRejectsAnAceByTheReceiver(logger as Test.Logger) as Boolean {
        var bench = new MatchBench(MatchFormat.BEST_OF_3, true);
        bench.play("O");
        Test.assertEqual(bench.controller.chooseEnding(Ending.ACE), Reaction.NONE);
        bench.play("M");
        Test.assertEqual(bench.controller.chooseEnding(Ending.ACE), Reaction.REFRESH);
        Test.assertEqual(bench.score(), "0-0 0-0 15-0");
        return true;
    }

    (:test)
    function testDoubleFaultNeedsNoEndingInDetailedMode(logger as Test.Logger) as Boolean {
        var bench = new MatchBench(MatchFormat.BEST_OF_3, true);
        Test.assertEqual(bench.play("FF"), Reaction.REFRESH);
        Test.assertEqual(bench.controller.pendingWinner(), Player.NONE);
        Test.assertEqual(bench.score(), "0-0 0-0 0-15");
        return true;
    }

    // Notices.

    (:test)
    function testGameNoticeComesWithAChangeOfEndsAfterOddGames(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(bench.play("MMM"), Reaction.REFRESH);
        Test.assertEqual(bench.notice(), "");
        Test.assertEqual(bench.play("M"), CHANGE_ENDS);
        Test.assertEqual(bench.notice(), "NoticeGame,NoticeChangeEnds");
        Test.assertEqual(bench.games("O"), Reaction.REFRESH);
        Test.assertEqual(bench.notice(), "NoticeGame");
        return true;
    }

    (:test)
    function testNoticeGoesAwayWithTimeOrWithTheNextPoint(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.games("M");
        bench.time.ms = MatchNotice.VISIBLE_MS;
        Test.assertEqual(bench.notice(), "");
        bench.games("O");
        bench.play("M");
        Test.assertEqual(bench.notice(), "");
        return true;
    }

    (:test)
    function testSetNoticeReplacesTheGameNotice(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(bench.games("MMMMMM"), Reaction.REFRESH);
        Test.assertEqual(bench.notice(), "NoticeSet");
        bench.games("MMMOOOOOO");
        Test.assertEqual(bench.notice(), "NoticeSet,NoticeChangeEnds");
        return true;
    }

    (:test)
    function testTieBreakChangesEndsEverySixPointsWithoutAGame(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.TIE_BREAK_ONLY);
        Test.assertEqual(bench.play("MMMOO"), Reaction.REFRESH);
        Test.assertEqual(bench.play("O"), CHANGE_ENDS);
        Test.assertEqual(bench.notice(), "NoticeChangeEnds");
        return true;
    }

    (:test)
    function testFaultThatClosesAGameShowsTheNotice(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(bench.play("OOOFF"), CHANGE_ENDS);
        Test.assertEqual(bench.notice(), "NoticeGame,NoticeChangeEnds");
        return true;
    }

    // End of the match.

    (:test)
    function testMatchEndStopsTheClockAndTakesNoMoreInput(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.TIE_BREAK_ONLY);
        bench.time.ms = 90000;
        Test.assertEqual(bench.play("MMMMMMM"), Reaction.REFRESH);
        Test.assert(bench.controller.isOver());
        Test.assertEqual(bench.notice(), "");
        bench.time.ms = 200000;
        Test.assertEqual(bench.controller.clockSeconds(), 90);
        Test.assertEqual(bench.play("M"), Reaction.NONE);
        Test.assertEqual(bench.play("F"), Reaction.NONE);
        Test.assert(!bench.controller.isPaused());
        return true;
    }

    (:test)
    function testReopenAfterTheMatchPointTakesItBack(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.TIE_BREAK_ONLY);
        bench.play("MMMMMMM");
        bench.time.ms = 5000;
        bench.controller.reopen();
        Test.assert(!bench.controller.isOver());
        Test.assertEqual(bench.score(), "0-0 0-0 6-0");
        bench.time.ms = 8000;
        Test.assertEqual(bench.controller.clockSeconds(), 3);
        Test.assertEqual(bench.play("O"), Reaction.REFRESH);
        return true;
    }

    (:test)
    function testEndFromTheMenuStopsTheMatchUntilReopened(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.play("MO");
        bench.controller.end();
        Test.assert(bench.controller.isOver());
        Test.assertEqual(bench.play("M"), Reaction.NONE);
        bench.controller.togglePause();
        Test.assertEqual(bench.play("F"), Reaction.NONE);
        bench.controller.reopen();
        Test.assert(!bench.controller.isOver());
        Test.assertEqual(bench.play("M"), Reaction.REFRESH);
        Test.assertEqual(bench.score(), "0-0 0-0 30-15");
        return true;
    }

    // Pause.

    (:test)
    function testPauseFreezesTheClockAndTheScore(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.play("M");
        bench.time.ms = 10000;
        bench.controller.togglePause();
        Test.assert(bench.controller.isPaused());
        bench.time.ms = 60000;
        Test.assertEqual(bench.play("M"), Reaction.NONE);
        Test.assertEqual(bench.play("O"), Reaction.NONE);
        Test.assertEqual(bench.play("U"), Reaction.NONE);
        Test.assertEqual(bench.score(), "0-0 0-0 15-0");
        Test.assertEqual(bench.controller.clockSeconds(), 10);
        return true;
    }

    (:test)
    function testStartResumesAPausedMatchWithoutLoggingAFault(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.controller.togglePause();
        Test.assertEqual(bench.play("F"), Reaction.REFRESH);
        Test.assert(!bench.controller.isPaused());
        Test.assertEqual(bench.engine.log().size(), 0);
        bench.controller.togglePause();
        bench.controller.togglePause();
        Test.assertEqual(bench.play("M"), Reaction.REFRESH);
        return true;
    }

    // Fix the score.

    (:test)
    function testUndoGameAndAwardGameGoThroughTheLog(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(bench.controller.undoGame(), Reaction.NONE);
        bench.play("MMMMO");
        Test.assertEqual(bench.controller.awardGame(Player.OPPONENT), Reaction.REFRESH);
        Test.assertEqual(bench.score(), "0-0 1-1 0-0");
        Test.assertEqual(bench.notice(), "");
        Test.assertEqual(bench.controller.undoGame(), Reaction.REFRESH);
        Test.assertEqual(bench.score(), "0-0 1-0 0-0");
        Test.assertEqual(bench.engine.log().size(), 4);
        return true;
    }

    (:test)
    function testAwardedGameCanEndTheMatchAndUndoGameReopensIt(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.ONE_SET);
        bench.games("MMMMM");
        bench.time.ms = 7000;
        Test.assertEqual(bench.controller.awardGame(Player.ME), Reaction.REFRESH);
        Test.assert(bench.controller.isOver());
        Test.assertEqual(bench.controller.awardGame(Player.ME), Reaction.NONE);
        bench.time.ms = 20000;
        Test.assertEqual(bench.controller.clockSeconds(), 7);
        Test.assertEqual(bench.controller.undoGame(), Reaction.REFRESH);
        Test.assert(!bench.controller.isOver());
        Test.assertEqual(bench.score(), "0-0 5-0 0-0");
        return true;
    }
}
