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

    (:test)
    function testFinalAndResumeMenuRowsHaveATextAndAHandler(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        assertRowsAreMethodsOf(MatchFlow.finalMenuRows(), new FinalMenuDelegate(bench.controller));
        assertRowsAreMethodsOf(MatchFlow.resumeMenuRows(), new ResumeMenuDelegate(bench.store));
        assertKeyInEveryLanguage("ResumeTitle");
        assertKeyInEveryLanguage("DiscardQ");
        return true;
    }

    (:test)
    function testDiscardConfirmationDiscardsOnlyOnYes(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        var confirm = new DiscardConfirmDelegate(bench.controller);
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_NO));
        Test.assert(bench.controller.farewellKey() == null);
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_YES));
        Test.assertEqual(bench.controller.farewellKey() as String, "DiscardedMsg");
        return true;
    }

    (:test)
    function testSetupMenuHasOneRowPerFieldAndTheStartRow(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var setup = new MatchSetup(null);
        var menu = MatchFlow.setupMenu(setup, setup.fields(false));
        Test.assertEqual((menu.getItem(3) as WatchUi.MenuItem).getId() as Number, MatchSetup.FIRST_SERVER);
        Test.assertEqual((menu.getItem(4) as WatchUi.MenuItem).getId() as Symbol, :start);
        menu = MatchFlow.setupMenu(setup, setup.fields(true));
        Test.assertEqual((menu.getItem(4) as WatchUi.MenuItem).getLabel(), "GPS");
        Test.assert(menu.getItem(6) == null);
        return true;
    }

    // The recorder of the watch itself: a short activity with a lap, thrown
    // away at the end so the test leaves no file behind.
    (:test)
    function testDeviceRecorderRecordsOnThisWatch(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var recorder = MatchFlow.deviceRecorder(new MatchSetup(null));
        recorder.start(0, false);
        recorder.closeSets(1, false);
        recorder.pause();
        recorder.discard();
        return true;
    }
}
