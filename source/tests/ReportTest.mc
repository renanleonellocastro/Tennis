import Toybox.Lang;
import Toybox.Test;

// Tests for the report: the pages the presenter builds, the pager and the
// layout on the three screen shapes.
module ReportTests {
    const ROW_LABEL_KEYS = [
        "ReportSet", "ReportPoints", "ReportFirstIn", "ReportFirstWon", "ReportSecondWon", "ReportDoubleFaults",
        "ReportAces", "ReportWinners", "ReportNetErrors", "ReportOutErrors", "ReportBreaks", "ReportSaved",
        "ReportHolds", "ReportBestRun", "ReportMatchTime", "ReportAvgGame", "ReportLongGame", "ReportPerPoint",
        "ReportAvgHr", "ReportMaxHr", "ReportKeyHr", "ReportCalories"
    ];
    const TITLE_KEYS = ["ReportScore", "ReportServe", "ReportEndings", "ReportPressure", "ReportTime", "ReportBody"];
    // What fits between the two columns of values on the smallest screen.
    const LABEL_MAX_CHARS = 11;

    function pagesOf(match as MatchDriver, isDetailed as Boolean, clock as Number, sensors as FakeSensors) as Array<Array> {
        Strings.loadTables("eng");
        var presenter = new ReportPresenter(match.state(), match.statistics());
        var pages = [] as Array<Array>;
        for (var i = 0; i < presenter.pageCount(isDetailed); i++) {
            pages.add(presenter.page(i, isDetailed, clock, sensors));
        }
        return pages;
    }

    // The rows of a page as text: "label|mine|theirs" joined by commas.
    function rowsText(page as Array) as String {
        var rows = page[1] as Array<Array>;
        var texts = [] as Array<String>;
        for (var i = 0; i < rows.size(); i++) {
            var text = "";
            for (var cell = 0; cell < rows[i].size(); cell++) {
                text += (cell == 0 ? "" : "|") + (rows[i][cell] as String);
            }
            texts.add(text);
        }
        return joined(texts);
    }

    function titles(pages as Array<Array>) as String {
        var keys = [] as Array<String>;
        for (var i = 0; i < pages.size(); i++) {
            keys.add(pages[i][0] as String);
        }
        return joined(keys);
    }

    (:test)
    function testSimpleMatchHasFivePagesAndDetailedSix(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.ONE_SET);
        match.games("MMMMMM");
        Test.assertEqual(titles(pagesOf(match, false, 0, new FakeSensors())),
                         "ReportScore,ReportServe,ReportPressure,ReportTime,ReportBody");
        Test.assertEqual(titles(pagesOf(match, true, 0, new FakeSensors())),
                         "ReportScore,ReportServe,ReportEndings,ReportPressure,ReportTime,ReportBody");
        return true;
    }

    (:test)
    function testScorePageHasARowPerSetAndThePoints(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("MMMMMMOOOOOOMMMMOMM");
        var pages = pagesOf(match, false, 0, new FakeSensors());
        Test.assertEqual(rowsText(pages[0]), "Set 1|6|0,Set 2|0|6,Set 3|6|1,Points|48|28");
        return true;
    }

    (:test)
    function testScorePageShowsTieBreakPointsAndTheSetLeftOpen(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        match.play("MMO");
        Test.assertEqual(rowsText(pagesOf(match, false, 0, new FakeSensors())[0]), "Set 1|6(2)|6(1),Points|26|25");
        match.play("MMMMM");
        match.games("O");
        Test.assertEqual(rowsText(pagesOf(match, false, 0, new FakeSensors())[0]),
                         "Set 1|7(7)|6(1),Set 2|0|1,Points|31|29");
        return true;
    }

    (:test)
    function testServePageCountsServesForBothPlayers(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play("FMFFMMM");
        match.play("OOFMO");
        var pages = pagesOf(match, false, 0, new FakeSensors());
        Test.assertEqual(rowsText(pages[1]),
                         "1st in|60%|75%,1st won|3/3|3/3,2nd won|1/2|0/1,Dbl faults|1|0");
        return true;
    }

    (:test)
    function testEndingsPageCreditsWinnersAndErrors(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.detailed(Player.ME, Ending.ACE, null);
        match.detailed(Player.ME, Ending.WINNER, null);
        match.detailed(Player.ME, Ending.ERROR_NET, null);
        match.detailed(Player.OPPONENT, Ending.ERROR_OUT, null);
        match.detailed(Player.OPPONENT, Ending.WINNER, null);
        var pages = pagesOf(match, true, 0, new FakeSensors());
        Test.assertEqual(rowsText(pages[2]), "Aces|1|0,Winners|1|1,Net errors|0|1,Out errors|1|0");
        return true;
    }

    (:test)
    function testPressurePageCountsBreaksHoldsAndRuns(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("MM");
        match.play("OOOMO");
        var pages = pagesOf(match, false, 0, new FakeSensors());
        Test.assertEqual(rowsText(pages[1 + 1]), "Breaks|1/1|1/2,Saved|1/2|0/1,Holds|1/2|0/1,Best run|8|3");
        return true;
    }

    (:test)
    function testTimePageShowsTheClockAndTheGameTimes(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("M");
        match.play("MOMOMM");
        var pages = pagesOf(match, false, 3725, new FakeSensors());
        Test.assertEqual(rowsText(pages[3]), "Match|1:02:05,Avg game|0:50,Long game|1:00,Per point|0:10");
        return true;
    }

    (:test)
    function testTimeAndBodyPagesSayWhenThereIsNothingToShow(logger as Test.Logger) as Boolean {
        var pages = pagesOf(newMatch(MatchFormat.BEST_OF_3), false, 0, new FakeSensors());
        Test.assertEqual(rowsText(pages[0]), "Set 1|0|0,Points|0|0");
        Test.assertEqual(rowsText(pages[3]), "Match|0:00,Avg game|--,Long game|--,Per point|--");
        Test.assertEqual(rowsText(pages[4]), "Avg HR|--,Max HR|--,Key pts HR|--,Calories|--");
        return true;
    }

    (:test)
    function testBodyPageShowsTheHeartRatesAndTheCalories(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play("OOO");
        match.detailed(Player.ME, Ending.WINNER, 150);
        match.detailed(Player.ME, Ending.WINNER, 161);
        var sensors = new FakeSensors();
        sensors.averageBeats = 128;
        sensors.maxBeats = 171;
        sensors.kilocalories = 412;
        var pages = pagesOf(match, false, 0, sensors);
        Test.assertEqual(rowsText(pages[4]), "Avg HR|128,Max HR|171,Key pts HR|156,Calories|412");
        return true;
    }

    (:test)
    function testReportTextsExistInEveryLanguage(logger as Test.Logger) as Boolean {
        var keys = ROW_LABEL_KEYS.size() + TITLE_KEYS.size();
        for (var i = 0; i < keys; i++) {
            assertKeyInEveryLanguage(i < TITLE_KEYS.size() ? TITLE_KEYS[i] : ROW_LABEL_KEYS[i - TITLE_KEYS.size()]);
        }
        return true;
    }

    (:test)
    function testRowLabelsAreShortInEveryLanguage(logger as Test.Logger) as Boolean {
        for (var c = 0; c < I18n.CODES.size(); c++) {
            var table = I18n.table(I18n.CODES[c] as String);
            for (var i = 0; i < ROW_LABEL_KEYS.size(); i++) {
                var label = table.get(ROW_LABEL_KEYS[i]) as String;
                Test.assertMessage(label.length() <= LABEL_MAX_CHARS, label + " is too long");
            }
        }
        return true;
    }

    (:test)
    function testPagerTurnsBothWaysAndGoesAround(logger as Test.Logger) as Boolean {
        var pager = new ReportPager(3);
        Test.assertEqual(pager.index(), 0);
        Test.assertEqual(pager.label(), "1/3");
        pager.turn(1);
        Test.assertEqual(pager.label(), "2/3");
        pager.turn(1);
        pager.turn(1);
        Test.assertEqual(pager.index(), 0);
        pager.turn(-1);
        Test.assertEqual(pager.label(), "3/3");
        return true;
    }

    // Layout on the three screen shapes.

    function assertRowsGoDownTheScreen(layout as ReportLayout, height as Number) as Void {
        Test.assert(layout.titleY() > 0);
        Test.assert(layout.titleY() < layout.headerY());
        Test.assert(layout.headerY() < layout.rowY(0));
        for (var i = 0; i < 3; i++) {
            Test.assert(layout.rowY(i) < layout.rowY(i + 1));
        }
        Test.assert(layout.rowY(3) < layout.pagerY());
        Test.assert(layout.pagerY() < height);
    }

    function assertColumnsMirror(layout as ReportLayout, width as Number) as Void {
        var players = layout.cellXs(3);
        var single = layout.cellXs(2);
        Test.assertEqual(players[0], layout.centerX());
        Test.assert(players[1] > 0 && players[1] < players[0]);
        Test.assertEqual(players[2], width - players[1]);
        Test.assert(single[0] > 0 && single[0] < layout.centerX());
        Test.assertEqual(single[1], width - single[0]);
    }

    // The outer cells of the first and last rows are inside the circle.
    function assertInsideTheCircle(layout as ReportLayout, diameter as Number) as Void {
        var radius = diameter / 2;
        var xs = [layout.cellXs(3)[1], layout.cellXs(2)[0]];
        var ys = [layout.headerY(), layout.rowY(3)];
        for (var i = 0; i < xs.size(); i++) {
            for (var j = 0; j < ys.size(); j++) {
                var dx = xs[i] - radius;
                var dy = ys[j] - radius;
                Test.assert(dx * dx + dy * dy < radius * radius);
            }
        }
    }

    (:test)
    function testLayoutFitsTheThreeShapes(logger as Test.Logger) as Boolean {
        var sizes = [[208, 208], [416, 416], [320, 360]];
        for (var i = 0; i < sizes.size(); i++) {
            var layout = new ReportLayout(sizes[i][0], sizes[i][1]);
            assertRowsGoDownTheScreen(layout, sizes[i][1]);
            assertColumnsMirror(layout, sizes[i][0]);
        }
        assertInsideTheCircle(new ReportLayout(208, 208), 208);
        assertInsideTheCircle(new ReportLayout(416, 416), 416);
        return true;
    }
}
