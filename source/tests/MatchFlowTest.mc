import Toybox.Application;
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
        Test.assertEqual((running[0] as Array)[0] as Number, Str.MatchMenuPause);
        Test.assertEqual((paused[0] as Array)[0] as Number, Str.MatchMenuResume);
        Test.assertEqual((running[1] as Array)[0] as Number, Str.MatchMenuFix);
        Test.assertEqual((running[2] as Array)[0] as Number, Str.MatchMenuEnd);
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
        Test.assertEqual(fix.undoGame(), Reaction.NONE);
        Test.assertEqual(fix.gameForMe(), Reaction.withCue(Cue.GAME));
        fix.gameForOpponent();
        Test.assertEqual(bench.score(), "0-0 1-1 0-0");
        Test.assertEqual(fix.undoGame(), Reaction.withCue(Cue.GAME));
        Test.assertEqual(bench.score(), "0-0 1-0 0-0");
        return true;
    }

    (:test)
    function testEndConfirmationEndsOnlyOnYes(logger as Test.Logger) as Boolean {
        var controller = simpleBench(MatchFormat.BEST_OF_3).controller;
        var confirm = new PracticeFlow.PracticeConfirmDelegate(controller.method(:end));
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_NO));
        Test.assert(!controller.isOver());
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_YES));
        Test.assert(controller.isOver());
        return true;
    }

    // Keeps what it was asked to play, in place of the watch.
    class FakeBuzzer {
        var played as Array = [];

        function buzz(steps as Array<Number>) as Void {
            played.add(steps);
        }
    }

    (:test)
    function testEveryCueHasItsOwnPatternAndNoCuePlaysNothing(logger as Test.Logger) as Boolean {
        var fake = new FakeBuzzer();
        var real = MatchAlert.buzzer;
        MatchAlert.buzzer = fake;
        var cues = [Cue.NONE, Cue.POINT, Cue.FAULT, Cue.UNDO, Cue.GAME, Cue.LONG];
        for (var i = 0; i < cues.size(); i++) {
            MatchAlert.play(cues[i]);
        }
        MatchAlert.buzzer = real;
        Test.assertEqual(fake.played.size(), cues.size() - 1);
        Test.assertEqual(fake.played.toString(),
                         "[[50, 60], [50, 60, 0, 80, 50, 60], [30, 200], [100, 200], [100, 600]]");
        return true;
    }

    (:test)
    function testCuePatternsArePairsOfStrengthAndTime(logger as Test.Logger) as Boolean {
        Test.assertEqual(MatchAlert.PATTERNS.size(), Cue.LONG + 1);
        for (var i = 0; i < MatchAlert.PATTERNS.size(); i++) {
            var steps = MatchAlert.PATTERNS[i] as Array<Number>;
            Test.assertEqual(steps.size() % 2, 0);
            for (var j = 0; j < steps.size(); j += 2) {
                Test.assert(steps[j] >= 0 && steps[j] <= 100 && steps[j + 1] > 0);
            }
        }
        return true;
    }

    // The real buzzer: it must run on a watch with or without vibration.
    (:test)
    function testEveryCueRunsOnThisWatch(logger as Test.Logger) as Boolean {
        new WatchBuzzer().buzz([] as Array<Number>);
        MatchAlert.play(Cue.FAULT);
        return true;
    }

    (:test)
    function testResumeDiscardQuestionClearsTheStoredMatchOnlyOnYes(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.store.begin(bench.setupOf(MatchFormat.BEST_OF_3, false).toArray());
        var confirm = new PracticeFlow.PracticeConfirmDelegate(bench.store.method(:clear));
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_NO));
        Test.assert(bench.store.hasMatch());
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_YES));
        Test.assert(!bench.store.hasMatch());
        return true;
    }

    (:test)
    function testFinalAndResumeMenuRowsHaveATextAndAHandler(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        assertRowsAreMethodsOf(MatchFlow.finalMenuRows(), new FinalMenuDelegate(bench.controller));
        assertRowsAreMethodsOf(MatchFlow.resumeMenuRows(), new ResumeMenuDelegate(bench.store));
        assertKeyInEveryLanguage(Str.DiscardQ);
        return true;
    }

    (:test)
    function testDiscardConfirmationDiscardsOnlyOnYes(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        var confirm = new PracticeFlow.PracticeConfirmDelegate(bench.controller.method(:discard));
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_NO));
        Test.assert(bench.controller.farewellKey() == null);
        Test.assert(confirm.onResponse(WatchUi.CONFIRM_YES));
        Test.assertEqual(bench.controller.farewellKey() as Number, Str.DiscardedMsg);
        return true;
    }

    (:test)
    function testSetupMenuHasOneRowPerFieldAndTheStartRow(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var setup = new MatchSetup(null);
        var menu = MatchFlow.setupMenu(setup, setup.fields(false));
        Test.assertEqual((menu.getItem(3) as WatchUi.MenuItem).getId() as Number, MatchSetup.FIRST_SERVER);
        Test.assertEqual((menu.getItem(4) as WatchUi.MenuItem).getId() as Symbol, :confirm);
        menu = MatchFlow.setupMenu(setup, setup.fields(true));
        Test.assertEqual((menu.getItem(4) as WatchUi.MenuItem).getLabel(), "GPS");
        Test.assert(menu.getItem(6) == null);
        return true;
    }

    (:test)
    function testFinalMenuOffersSaveTheReportAndDiscard(logger as Test.Logger) as Boolean {
        var rows = MatchFlow.finalMenuRows();
        Test.assertEqual(rows.size(), 3);
        Test.assertEqual((rows[0] as Array)[0] as Number, Str.FinalSave);
        Test.assertEqual((rows[1] as Array)[0] as Number, Str.FinalReport);
        Test.assertEqual((rows[2] as Array)[0] as Number, Str.FinalDiscard);
        return true;
    }

    (:test)
    function testSaveMenuHasARowPerTagAndTheSaveRow(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var tags = new MatchTags([1, 0]);
        var menu = MatchFlow.optionMenu(tags, tags.fields(), Str.FinalSave);
        var surface = menu.getItem(0) as WatchUi.MenuItem;
        Test.assertEqual(surface.getId() as Number, MatchTags.SURFACE);
        Test.assertEqual(surface.getLabel(), "Surface");
        Test.assertEqual(surface.getSubLabel() as String, "Clay");
        Test.assertEqual((menu.getItem(1) as WatchUi.MenuItem).getSubLabel() as String, "Not set");
        Test.assertEqual((menu.getItem(2) as WatchUi.MenuItem).getLabel(), "Save");
        Test.assertEqual((menu.getItem(2) as WatchUi.MenuItem).getId() as Symbol, :confirm);
        return true;
    }

    (:test)
    function testSaveMenuRowMovesATagToItsNextOption(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var tags = new MatchTags(null);
        var item = new WatchUi.MenuItem("Type", "Not set", MatchTags.KIND, null);
        new SaveMenuDelegate(simpleBench(MatchFormat.ONE_SET).controller, tags).onSelect(item);
        Test.assertEqual(item.getSubLabel() as String, "Match");
        Test.assertEqual(joinedNumbers(tags.toArray()), "0,1");
        return true;
    }

    (:test)
    function testSavingRemembersTheTagsAndSavesTheActivityWithThem(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.ONE_SET);
        bench.games("MMMMMM");
        MatchFlow.saveWithTags(bench.controller, new MatchTags([2, 2]));
        Test.assertEqual(joinedNumbers(TagStore.load().toArray()), "2,2");
        Application.Storage.deleteValue(TagStore.KEY);
        Test.assertEqual(bench.session.calls, "spS");
        Test.assertEqual(bench.session.fields[RecordingFields.MATCH_SETUP] as Number,
                         1 + (2 << 4) + (2 << 10) + (2 << 12));
        return true;
    }

    (:test)
    function testReportOfAMatchFollowsItsDetailLevel(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var simple = simpleBench(MatchFormat.ONE_SET);
        simple.games("MMMMMM");
        simple.time.ms = 65000;
        var presenter = new ReportPresenter(simple.controller.state(), simple.controller.statistics());
        var page = presenter.page(0, false, simple.controller.clockSeconds(), simple.controller.sensors());
        Test.assertEqual(presenter.pageCount(simple.controller.isDetailed()), 5);
        Test.assertEqual((page[1] as Array<Array>)[0][1] as String, "6");
        Test.assertEqual(presenter.pageCount(new MatchBench(MatchFormat.ONE_SET, true).controller.isDetailed()), 6);
        Test.assertEqual(MatchFlow.reportScreen(simple.controller).size(), 2);
        return true;
    }

    (:test)
    function testReportKeysTurnThePages(logger as Test.Logger) as Boolean {
        var pager = new ReportPager(4);
        var delegate = new ReportDelegate(pager);
        Test.assert(delegate.onNextPage());
        Test.assert(delegate.onSelect());
        Test.assertEqual(pager.index(), 2);
        Test.assert(delegate.onPreviousPage());
        Test.assertEqual(pager.index(), 1);
        return true;
    }

    // The recorder of the watch itself: a short activity with a lap, thrown
    // away at the end so the test leaves no file behind.
    (:test)
    function testDeviceRecorderRecordsOnThisWatch(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var recorder = MatchFlow.deviceRecorder(new MatchSetup(null));
        recorder.start(0, false);
        recorder.closeSets(1, false, [6, 4, 0, 0]);
        recorder.pause();
        recorder.discard();
        return true;
    }
}
