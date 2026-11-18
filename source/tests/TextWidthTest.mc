import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Test;

// Width tests for the texts the app places itself. The longest text of each
// place, in every language and with the largest numbers a match can give,
// is measured in the fonts of the watch the tests run on and compared with
// the room of that place: the edge of the screen on its row, and the
// neighbour on the same row. The rows of the menus are drawn by the watch:
// their room is known only for the smallest round screen, where it was
// measured on screenshots of the simulator.
module TextFitTests {
    // Pixels kept free between a text and the screen edge or its neighbour.
    const CLEARANCE = 2;
    // The ink of a line is about this share of the font height above and
    // below its middle; the rest of the height is empty.
    const INK_DIVISOR = 3;

    const LONGEST_SETS = "7-6  6-7  6-6";
    const LONGEST_FINAL_SETS = "7-6  6-7  18-16";
    const LONGEST_CLOCK = "9:59:59";
    const LONGEST_GAME_TIME = "59:59";
    const LONGEST_HEART_RATE = "188";
    const BANNER_KEYS = [Str.Paused, Str.LabelMatchPoint, Str.LabelSetPoint, Str.LabelBreakPoint, Str.NoticeChangeEnds];
    const FINAL_TITLE_KEYS = [Str.FinalYouWon, Str.FinalYouLost, Str.FinalMatchEnded];
    const REPORT_TITLE_KEYS = [Str.ReportScore, Str.ReportServe, Str.ReportEndings, Str.ReportPressure, Str.ReportTime,
                               Str.ReportBody];
    const COUNT_LABEL_KEYS = [Str.ReportPoints, Str.ReportDoubleFaults, Str.ReportAces, Str.ReportWinners,
                              Str.ReportNetErrors, Str.ReportOutErrors, Str.ReportBestRun];
    const CONTROL_KEYS = [Str.ControlFault, Str.PracticeNext];
    // The lowest row a kind of value can take on a report page.
    const LAST_RATIO_ROW = 2;
    const LAST_REPORT_ROW = 3;
    // The Forerunner 55 draws the row under the chosen one of a menu in
    // FONT_TINY, where its round screen of 208 pixels is 125 pixels wide.
    const SMALL_ROUND_WIDTH = 208;
    const SMALL_ROUND_MENU_ROOM = 125 - 2 * CLEARANCE;

    var bitmap as Object? = null;

    // Something to measure texts with: the tests have no screen.
    function canvas() as Dc {
        if (bitmap == null) {
            var options = {:width => 4, :height => 4};
            if (Graphics has :createBufferedBitmap) {
                bitmap = Graphics.createBufferedBitmap(options).get();
            } else {
                bitmap = new Graphics.BufferedBitmap(options);
            }
        }
        return (bitmap as Graphics.BufferedBitmap).getDc();
    }

    function widthOf(text as String, font as Graphics.FontDefinition) as Number {
        return canvas().getTextWidthInPixels(text, font);
    }

    function inkHalf(font as Graphics.FontDefinition) as Number {
        return canvas().getFontHeight(font) / INK_DIVISOR;
    }

    function screenWidth() as Number {
        return System.getDeviceSettings().screenWidth;
    }

    // The x where the screen starts for something that reaches halfBand
    // above and below the row y. The right edge mirrors it.
    function edgeAt(y as Number, halfBand as Number) as Number {
        var settings = System.getDeviceSettings();
        if (settings.screenShape != System.SCREEN_SHAPE_ROUND) {
            return CLEARANCE;
        }
        var radius = settings.screenWidth / 2;
        var away = (y > radius ? y - radius : radius - y) + halfBand;
        if (away >= radius) {
            return radius;
        }
        return radius - Math.sqrt(radius * radius - away * away).toNumber() + CLEARANCE;
    }

    // The texts of the keys in every language.
    function textsOf(keys as Array<Number>) as Array<String> {
        var texts = [] as Array<String>;
        for (var c = 0; c < I18n.CODES.size(); c++) {
            var table = I18n.table(I18n.CODES[c] as String);
            for (var i = 0; i < keys.size(); i++) {
                texts.add(table[keys[i]]);
            }
        }
        return texts;
    }

    // Each text of the first keys followed by the tail, in every language.
    function textsWithTail(keys as Array<Number>, tail as String) as Array<String> {
        var texts = textsOf(keys);
        for (var i = 0; i < texts.size(); i++) {
            texts[i] = texts[i] + tail;
        }
        return texts;
    }

    // "Game. Change ends" and "Set. Change ends" in every language.
    function doubleNotices() as Array<String> {
        var texts = [] as Array<String>;
        for (var c = 0; c < I18n.CODES.size(); c++) {
            var table = I18n.table(I18n.CODES[c] as String);
            var ends = MatchPresenter.NOTICE_GAP + (table[Str.NoticeChangeEnds]);
            texts.add((table[Str.NoticeGame]) + ends);
            texts.add((table[Str.NoticeSet]) + ends);
        }
        return texts;
    }

    function widest(texts as Array<String>, font as Graphics.FontDefinition) as Number {
        var most = 0;
        for (var i = 0; i < texts.size(); i++) {
            var width = widthOf(texts[i], font);
            most = width > most ? width : most;
        }
        return most;
    }

    // True when something this wide, centered on x at the row y, stays on
    // the screen.
    function isInside(width as Number, x as Number, y as Number, halfBand as Number) as Boolean {
        var edge = edgeAt(y, halfBand);
        var half = (width + 1) / 2;
        return x - half >= edge && x + half <= screenWidth() - edge;
    }

    function isLineInside(texts as Array<String>, font as Graphics.FontDefinition, percentY as Number) as Boolean {
        var y = System.getDeviceSettings().screenHeight * percentY / 100;
        return isInside(widest(texts, font), screenWidth() / 2, y, inkHalf(font));
    }

    function layout() as MatchLayout {
        return MatchFlow.deviceLayout(MatchInput.profileOfDevice());
    }

    (:test)
    function testTheTopRowsOfTheMatchScreenStayOnTheScreen(logger as Test.Logger) as Boolean {
        var font = Graphics.FONT_XTINY;
        var at = layout();
        Test.assert(isInside(widthOf(LONGEST_SETS, font), at.centerX(), at.setsY(), inkHalf(font)));
        Test.assert(isInside(widest(textsWithTail([Str.PracticeBlock], " 88"), font), at.centerX(), at.setsY(),
                             inkHalf(font)));
        Test.assert(isInside(widest(textsOf(BANNER_KEYS), font), at.centerX(), at.bannerY(), inkHalf(font)));
        Test.assert(isInside(widest(doubleNotices(), font), at.centerX(), at.bannerY(), inkHalf(font)));
        return true;
    }

    // The label of a player starts next to its serve ball and must end
    // before the marker of the player under the court.
    (:test)
    function testThePlayerLabelsStayClearOfTheCourt(logger as Test.Logger) as Boolean {
        var at = layout();
        var court = at.courtRect();
        var room = at.centerX() - court[2] / 4 - at.markerRadius() - CLEARANCE - at.labelX(Player.ME);
        Test.assert(widest(textsOf([Str.LabelMe, Str.LabelOpponent]), Graphics.FONT_XTINY) <= room);
        return true;
    }

    // The advantage is a word in a text font, between the screen edge and
    // the net line of the court.
    (:test)
    function testTheAdvantageFitsBesideTheCourt(logger as Test.Logger) as Boolean {
        var at = layout();
        var font = Graphics.FONT_LARGE;
        var half = (widest(textsOf([Str.LabelAdvantage]), font) + 1) / 2;
        var x = at.playerX(Player.ME);
        Test.assert(x - half >= edgeAt(at.pointsY(), inkHalf(font)));
        Test.assert(x + half <= at.courtRect()[0] - at.markerRadius() - CLEARANCE);
        return true;
    }

    // The labels of the practice screen sit under the counts, one on each half.
    (:test)
    function testThePracticeLabelsStayOnTheirHalf(logger as Test.Logger) as Boolean {
        var at = layout();
        var font = Graphics.FONT_XTINY;
        var half = (widest(textsOf([Str.PracticeHit, Str.PracticeMiss]), font) + 1) / 2;
        var x = at.playerX(Player.ME);
        Test.assert(x - half >= edgeAt(at.labelsY(), inkHalf(font)));
        Test.assert(x + half <= at.centerX() - CLEARANCE);
        return true;
    }

    // The clock of a long match with a heart rate of three digits. The
    // digits sit low on their line, so the row is checked a little lower.
    (:test)
    function testTheBottomRowFitsALongClockAndAFastHeart(logger as Test.Logger) as Boolean {
        var at = layout();
        var font = Graphics.FONT_TINY;
        var heart = widthOf(LONGEST_HEART_RATE, font);
        var xs = at.footerXs(widthOf(LONGEST_CLOCK, font), heart);
        var edge = edgeAt(at.clockY(), inkHalf(font) + CLEARANCE);
        Test.assert(xs[0] >= edge);
        Test.assert(xs[2] + heart <= screenWidth() - edge);
        return true;
    }

    // The outline of a touch control, as Theme.drawPill sizes it.
    function pillSize(text as String) as Array<Number> {
        var height = canvas().getFontHeight(Graphics.FONT_XTINY);
        return [widthOf(text, Graphics.FONT_XTINY) + (height / 2 + 2) * 2, height + (height / 6) * 2] as Array<Number>;
    }

    (:test)
    function testTheTouchControlsStayApartAndOnTheScreen(logger as Test.Logger) as Boolean {
        var at = layout();
        if (!at.hasTouchControls()) {
            return true;
        }
        var menus = textsOf([Str.HomeHint]);
        var others = textsOf(CONTROL_KEYS);
        for (var i = 0; i < others.size(); i++) {
            var menu = pillSize(menus[i / CONTROL_KEYS.size()]);
            var other = pillSize(others[i]);
            Test.assert(isInside(menu[0], at.menuControlX(), at.controlsY(), menu[1] / 2));
            Test.assert(isInside(other[0], at.faultControlX(), at.controlsY(), other[1] / 2));
            Test.assert(at.menuControlX() + menu[0] / 2 + CLEARANCE <= at.faultControlX() - other[0] / 2);
        }
        return true;
    }

    (:test)
    function testTheFinalScreenFitsItsLongestLines(logger as Test.Logger) as Boolean {
        var view = new FinalScoreView(new MatchBench(MatchFormat.ONE_SET, false).controller);
        Test.assert(isLineInside(textsOf(FINAL_TITLE_KEYS), Graphics.FONT_SMALL, view.TITLE_Y));
        Test.assert(isLineInside([LONGEST_FINAL_SETS, LONGEST_SETS], Graphics.FONT_MEDIUM, view.SETS_Y));
        Test.assert(isLineInside([LONGEST_CLOCK], Graphics.FONT_TINY, view.CLOCK_Y));
        return true;
    }

    function reportLayout() as ReportLayout {
        var settings = System.getDeviceSettings();
        return new ReportLayout(settings.screenWidth, settings.screenHeight);
    }

    // True when the widest label and the widest value of a row that
    // compares the players stay apart, and the value stays on the screen
    // on the lowest row it can take.
    function isPlayerRowClear(labels as Array<String>, value as String, lastRow as Number) as Boolean {
        var at = reportLayout();
        var font = Graphics.FONT_XTINY;
        var xs = at.cellXs(3);
        var valueWidth = widthOf(value, font);
        var isApart = (widest(labels, font) + 1) / 2 + (valueWidth + 1) / 2 + CLEARANCE <= xs[0] - xs[1];
        return isApart && isInside(valueWidth, xs[1], at.rowY(lastRow), inkHalf(font));
    }

    (:test)
    function testTheRowsThatCompareThePlayersKeepTheirColumnsApart(logger as Test.Logger) as Boolean {
        Test.assert(isPlayerRowClear(textsOf(RATIO_LABEL_KEYS), "88/88", LAST_RATIO_ROW));
        Test.assert(isPlayerRowClear(textsOf([Str.ReportFirstIn]), "100%", 0));
        Test.assert(isPlayerRowClear(textsOf(COUNT_LABEL_KEYS), "188", LAST_REPORT_ROW));
        Test.assert(isPlayerRowClear(textsWithTail([Str.ReportSet], " 3"), "7(18)", LAST_RATIO_ROW));
        return true;
    }

    (:test)
    function testTheReportTitleAndHeaderStayOnTheScreen(logger as Test.Logger) as Boolean {
        var at = reportLayout();
        var font = Graphics.FONT_XTINY;
        Test.assert(isInside(widest(textsOf(REPORT_TITLE_KEYS), font), at.centerX(), at.titleY(), inkHalf(font)));
        Test.assert(isInside(widest(textsOf([Str.LabelMe, Str.LabelOpponent]), font), at.cellXs(3)[1], at.headerY(),
                             inkHalf(font)));
        Test.assert(isInside(widthOf("6/6", font), at.centerX(), at.pagerY(), inkHalf(font)));
        return true;
    }

    // True when the widest label and the value of a row with one value
    // stay apart, and the label starts on the screen on the lowest row.
    function isValueRowClear(labels as Array<String>, value as String) as Boolean {
        var at = reportLayout();
        var font = Graphics.FONT_XTINY;
        var xs = at.cellXs(2);
        var isApart = widest(labels, font) + widthOf(value, font) + 2 * CLEARANCE <= xs[1] - xs[0];
        return isApart && xs[0] >= edgeAt(at.rowY(LAST_REPORT_ROW), inkHalf(font));
    }

    (:test)
    function testTheTimeAndBodyRowsKeepTheLabelAndTheNumberApart(logger as Test.Logger) as Boolean {
        Test.assert(isValueRowClear(textsOf(MATCH_TIME_KEYS), LONGEST_CLOCK));
        Test.assert(isValueRowClear(textsOf(GAME_TIME_KEYS), LONGEST_GAME_TIME));
        Test.assert(isValueRowClear(textsOf(BODY_LABEL_KEYS), "1888"));
        return true;
    }

    // The two lines of a message, as MessageView places them, inside the
    // frame ring.
    (:test)
    function testTheMessageLinesStayInsideTheFrameRing(logger as Test.Logger) as Boolean {
        var font = Graphics.FONT_MEDIUM;
        var height = System.getDeviceSettings().screenHeight;
        var lineHeight = canvas().getFontHeight(font);
        var ring = Theme.FRAME_INSET + Theme.FRAME_PEN;
        var texts = messageTexts();
        for (var i = 0; i < texts.size(); i++) {
            var lines = Theme.splitTwoLines(texts[i], new MessageView("", 0, 0).LINE_CHARS);
            var y = height / 2 - (lines.size() * lineHeight) / 2 + height / 20 + lineHeight / 2;
            for (var line = 0; line < lines.size(); line++) {
                Test.assert(isInside(widthOf(lines[line] as String, font) + 2 * ring, screenWidth() / 2,
                                     y + line * lineHeight, inkHalf(font)));
            }
        }
        return true;
    }

    (:test)
    function testThePracticeSummaryFitsItsLongestLines(logger as Test.Logger) as Boolean {
        var bench = new PracticeTests.PracticeBench();
        var view = new PracticeFlow.PracticeSummaryView(bench.controller, new SummaryPager(1, 4));
        var isRound = System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND;
        Test.assert(isLineInside(textsOf([Str.PracticeTotal]), Graphics.FONT_XTINY,
                                 PracticePresenter.summaryTitleY(isRound)));
        Test.assert(isLineInside(["888/999  89%"], Graphics.FONT_SMALL, view.TOTAL_Y));
        Test.assert(isLineInside(["12  88/100  88%"], Graphics.FONT_XTINY, view.FIRST_ROW_Y));
        Test.assert(isLineInside(["12  88/100  88%"], Graphics.FONT_XTINY, view.FIRST_ROW_Y + 3 * view.ROW_STEP));
        Test.assert(isLineInside([LONGEST_CLOCK + "  3/3"], Graphics.FONT_XTINY, view.FOOTER_Y));
        return true;
    }

    // The first text wider than the room, or null when all of them fit.
    function firstWiderThan(texts as Array<String>, font as Graphics.FontDefinition, room as Number) as String? {
        for (var i = 0; i < texts.size(); i++) {
            if (widthOf(texts[i], font) > room) {
                return texts[i];
            }
        }
        return null;
    }

    (:test)
    function testMenuRowsFitTheLowestRowOfTheSmallestRoundScreen(logger as Test.Logger) as Boolean {
        var settings = System.getDeviceSettings();
        if (settings.screenShape != System.SCREEN_SHAPE_ROUND || settings.screenWidth != SMALL_ROUND_WIDTH) {
            return true;
        }
        var tooWide = firstWiderThan(textsOf(MENU_ROW_KEYS), Graphics.FONT_TINY, SMALL_ROUND_MENU_ROOM);
        logger.debug("first menu row that is too wide: " + tooWide);
        Test.assert(tooWide == null);
        return true;
    }

    (:test)
    function testTheEdgeOfARoundScreenNarrowsAwayFromTheMiddle(logger as Test.Logger) as Boolean {
        var settings = System.getDeviceSettings();
        var middle = settings.screenHeight / 2;
        Test.assert(edgeAt(middle, 0) <= edgeAt(middle / 4, 0));
        Test.assert(isInside(settings.screenWidth / 2, settings.screenWidth / 2, middle, 0));
        Test.assert(!isInside(settings.screenWidth, settings.screenWidth / 2, middle, 0));
        return true;
    }
}
