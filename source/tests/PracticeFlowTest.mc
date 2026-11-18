import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

// Tests for the menu tables of a practice and for the delegates that need
// no live view stack. Showing the views themselves is checked by hand on
// the simulator.
module PracticeTests {
    (:test)
    function testPracticeMenuOffersPauseOrResumeThenEnd(logger as Test.Logger) as Boolean {
        var running = PracticeFlow.practiceMenuRows(false);
        var paused = PracticeFlow.practiceMenuRows(true);
        Test.assertEqual(running.size(), 2);
        Test.assertEqual((running[0] as Array)[0] as Number, Str.MatchMenuPause);
        Test.assertEqual((paused[0] as Array)[0] as Number, Str.MatchMenuResume);
        Test.assertEqual((running[1] as Array)[0] as Number, Str.PracticeMenuEnd);
        return true;
    }

    (:test)
    function testSaveMenuOffersSaveThenDiscard(logger as Test.Logger) as Boolean {
        var rows = PracticeFlow.saveMenuRows();
        Test.assertEqual(rows.size(), 2);
        Test.assertEqual((rows[0] as Array)[0] as Number, Str.FinalSave);
        Test.assertEqual((rows[1] as Array)[0] as Number, Str.FinalDiscard);
        return true;
    }

    (:test)
    function testEveryMenuRowHasATextAndAHandler(logger as Test.Logger) as Boolean {
        var controller = new PracticeBench().controller;
        assertRowsAreMethodsOf(PracticeFlow.practiceMenuRows(false), new PracticeFlow.PracticeMenuDelegate(controller));
        assertRowsAreMethodsOf(PracticeFlow.practiceMenuRows(true), new PracticeFlow.PracticeMenuDelegate(controller));
        assertRowsAreMethodsOf(PracticeFlow.saveMenuRows(), new PracticeFlow.PracticeSaveMenuDelegate(controller));
        return true;
    }

    (:test)
    function testEveryPracticeTextExistsInEveryLanguage(logger as Test.Logger) as Boolean {
        var keys = [Str.MenuPractice, Str.PracticeBlock, Str.PracticeHit, Str.PracticeMiss, Str.PracticeNext,
                    Str.PracticeTotal, Str.EndPracticeQ, Str.DiscardQ, Str.Paused, Str.HomeHint,
                    Str.TouchNeededMsg, Str.SavedMsg, Str.DiscardedMsg, Str.FitHitsLabel, Str.FitMissesLabel, Str.FitShotsUnit];
        for (var i = 0; i < keys.size(); i++) {
            assertKeyInEveryLanguage(keys[i]);
        }
        return true;
    }

    (:test)
    function testMainMenuPracticeRowRunsAMethod(logger as Test.Logger) as Boolean {
        var row = MenuKit.mainMenuRows()[1] as Array;
        Test.assert((row[1] as Symbol) == :practice);
        Test.assert((row[2] as Object) instanceof Lang.Method);
        Test.assert(PracticeFlow has :start);
        return true;
    }

    (:test)
    function testEndConfirmationEndsOnlyOnYes(logger as Test.Logger) as Boolean {
        var controller = new PracticeBench().controller;
        var confirm = new PracticeFlow.PracticeConfirmDelegate(controller.method(:end));
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_NO));
        Test.assert(!controller.isOver());
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_YES));
        Test.assert(controller.isOver());
        return true;
    }

    (:test)
    function testDiscardConfirmationDiscardsOnlyOnYes(logger as Test.Logger) as Boolean {
        var bench = new PracticeBench();
        var confirm = new PracticeFlow.PracticeConfirmDelegate(bench.controller.method(:discard));
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_NO));
        Test.assert(bench.controller.farewellKey() == null);
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_YES));
        Test.assertEqual(bench.controller.farewellKey() as Number, Str.DiscardedMsg);
        Test.assertEqual(bench.session.calls, "spD");
        return true;
    }

    (:test)
    function testSummaryKeysTurnThePagesAndStayInside(logger as Test.Logger) as Boolean {
        var pager = new SummaryPager(5, PracticeFlow.SUMMARY_ROWS);
        var summary = new PracticeFlow.PracticeSummaryDelegate(new PracticeBench().controller, pager);
        Test.assert(summary.onPreviousPage());
        Test.assertEqual(pager.page(), 0);
        Test.assert(summary.onNextPage());
        Test.assertEqual(pager.page(), 1);
        Test.assert(summary.onNextPage());
        Test.assertEqual(pager.page(), 1);
        Test.assert(summary.onPreviousPage());
        Test.assertEqual(pager.page(), 0);
        return true;
    }

    (:test)
    function testPracticeScreenSwallowsTheBehaviorsOfItsKeys(logger as Test.Logger) as Boolean {
        var controller = new PracticeBench().controller;
        var screen = new PracticeFlow.PracticeDelegate(controller, new MatchLayout(208, 208, false, true));
        Test.assert(screen.onSelect());
        Test.assert(screen.onNextPage());
        Test.assert(screen.onPreviousPage());
        Test.assertEqual(tallyOf(controller.log()), "1 0-0");
        return true;
    }

    // The recorder of the watch itself: a short activity with a block,
    // thrown away at the end so the test leaves no file behind.
    (:test)
    function testDeviceRecorderRecordsOnThisWatch(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var recorder = PracticeFlow.deviceRecorder();
        recorder.start();
        recorder.setBlock(3, 1);
        recorder.closeBlock();
        recorder.pause();
        recorder.discard();
        return true;
    }
}
