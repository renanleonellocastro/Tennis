import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

// Tests for the menu tables of a match and for the delegates that need no
// live view stack. Showing the views themselves is checked by hand on the
// simulator.
module MatchFlowTests {
    (:test)
    function testMatchMenuOffersPauseOrResumeThenFixThenEnd(logger as Test.Logger) as Boolean {
        var running = MatchFlow.matchMenuRows(false);
        var paused = MatchFlow.matchMenuRows(true);
        Test.assertEqual(running.size(), 3);
        Test.assertEqual((running[0] as Array)[0] as String, "MatchMenuPause");
        Test.assertEqual((paused[0] as Array)[0] as String, "MatchMenuResume");
        Test.assertEqual((running[1] as Array)[0] as String, "MatchMenuFix");
        Test.assertEqual((running[2] as Array)[0] as String, "MatchMenuEnd");
        return true;
    }

    (:test)
    function testEveryMenuRowHasATextAndAHandler(logger as Test.Logger) as Boolean {
        var controller = simpleBench(MatchFormat.BEST_OF_3).controller;
        assertRowsAreMethodsOf(MatchFlow.matchMenuRows(false), new MatchMenuDelegate(controller));
        assertRowsAreMethodsOf(MatchFlow.matchMenuRows(true), new MatchMenuDelegate(controller));
        assertRowsAreMethodsOf(MatchFlow.fixMenuRows(), new FixMenuDelegate(controller));
        return true;
    }

    (:test)
    function testSetupRowMovesToItsNextOption(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var setup = new MatchSetup(null);
        var item = new WatchUi.MenuItem("Point detail", "Simple", MatchSetup.DETAIL, null);
        new SetupMenuDelegate(setup).onSelect(item);
        Test.assert(setup.isDetailed());
        Test.assertEqual(item.getSubLabel() as String, "Detailed");
        return true;
    }

    (:test)
    function testFixMenuHandlersCorrectTheScore(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        var fix = new FixMenuDelegate(bench.controller);
        fix.gameForMe();
        fix.gameForOpponent();
        Test.assertEqual(bench.score(), "0-0 1-1 0-0");
        fix.undoGame();
        Test.assertEqual(bench.score(), "0-0 1-0 0-0");
        return true;
    }

    (:test)
    function testEndConfirmationEndsOnlyOnYes(logger as Test.Logger) as Boolean {
        var controller = simpleBench(MatchFormat.BEST_OF_3).controller;
        var confirm = new EndMatchConfirmDelegate(controller);
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_NO));
        Test.assert(!controller.isOver());
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_YES));
        Test.assert(controller.isOver());
        return true;
    }

    (:test)
    function testChangeOfEndsAlertRunsOnThisWatch(logger as Test.Logger) as Boolean {
        MatchAlert.changeEnds();
        return true;
    }
}
