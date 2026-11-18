import Toybox.Lang;
import Toybox.Test;

// Tests for the room of the texts on the screens where it is smallest.
// The limits come from looking at every screen in the six languages on the
// simulator: a longer text is cut by the edge of the screen or runs into
// the numbers next to it.
module TextFitTests {
    // The label of a menu row, including the row that is not selected.
    const MENU_ROW_KEYS = [
        Str.MenuStartMatch, Str.MenuPractice, Str.MenuAbout, Str.SetupFormat, Str.SetupNoAd, Str.SetupDetail, Str.SetupFirstServe,
        Str.SetupGps, Str.SetupStart, Str.MatchMenuPause, Str.MatchMenuResume, Str.MatchMenuFix,
        Str.MatchMenuEnd, Str.FixUndoGame, Str.FixGameMe, Str.FixGameOpponent, Str.EndingWinner, Str.EndingAce,
        Str.EndingErrorNet, Str.EndingErrorOut, Str.FinalSave, Str.FinalReport, Str.FinalDiscard, Str.TagSurface, Str.TagKind,
        Str.PracticeMenuEnd
    ];
    const MENU_ROW_MAX_CHARS = 15;

    // The smaller second line of a menu row.
    const SUB_LABEL_KEYS = [
        Str.FormatBestOf3, Str.FormatMatchTieBreak, Str.FormatOneSet, Str.FormatProSet, Str.FormatTieBreakOnly, Str.ValueOn,
        Str.ValueOff, Str.DetailSimple, Str.DetailDetailed, Str.PlayerMe, Str.PlayerOpponent, Str.TagNotSet, Str.SurfaceClay,
        Str.SurfaceHard, Str.SurfaceGrass, Str.KindMatch, Str.KindFriendly
    ];
    const SUB_LABEL_MAX_CHARS = 20;

    // A menu title: a longer one wraps and loses its second line.
    const TITLE_KEYS = [Str.AppName, Str.EndingTitle];
    const TITLE_MAX_CHARS = 8;

    // Report rows with a ratio such as 46/57 on both sides.
    const RATIO_LABEL_KEYS = [Str.ReportFirstWon, Str.ReportSecondWon, Str.ReportBreaks, Str.ReportSaved, Str.ReportHolds];
    const RATIO_LABEL_MAX_CHARS = 8;

    // Report rows of the time and body pages: the label starts at the left
    // and its number ends at the right, on the same line. The numbers are
    // as long as 1:23:45 for the match, 12:34 for a game and 1234 calories.
    const MATCH_TIME_KEYS = [Str.ReportMatchTime];
    const MATCH_TIME_MAX_CHARS = 7;
    const GAME_TIME_KEYS = [Str.ReportAvgGame, Str.ReportLongGame, Str.ReportPerPoint];
    const GAME_TIME_MAX_CHARS = 9;
    const BODY_LABEL_KEYS = [Str.ReportAvgHr, Str.ReportMaxHr, Str.ReportKeyHr, Str.ReportCalories];
    const BODY_LABEL_MAX_CHARS = 10;

    // A message screen: a longer line runs over the frame ring on the
    // rectangular screens.
    const MESSAGE_KEYS = [Str.TouchNeededMsg, Str.SavedMsg, Str.DiscardedMsg];
    const MESSAGE_LINE_MAX_CHARS = 15;

    // The texts of the message screens in every language: the messages
    // and the About text, the name of the app followed by the version.
    function messageTexts() as Array<String> {
        var texts = TextFitTests.textsOf(MESSAGE_KEYS);
        texts.addAll(TextFitTests.textsWithTail([Str.AppName], " " + MenuKit.VERSION));
        return texts;
    }

    // The first text of the keys that is longer than the limit in any
    // language, or null when all of them fit.
    function firstTooLong(keys as Array<Number>, maxChars as Number) as String? {
        for (var c = 0; c < I18n.CODES.size(); c++) {
            var table = I18n.table(I18n.CODES[c] as String);
            for (var i = 0; i < keys.size(); i++) {
                var text = table[keys[i]];
                if (text.length() > maxChars) {
                    return text;
                }
            }
        }
        return null;
    }

    (:test)
    function testMenuRowsFitTheSmallRoundScreenInEveryLanguage(logger as Test.Logger) as Boolean {
        Test.assert(firstTooLong(MENU_ROW_KEYS, MENU_ROW_MAX_CHARS) == null);
        Test.assert(firstTooLong(SUB_LABEL_KEYS, SUB_LABEL_MAX_CHARS) == null);
        return true;
    }

    (:test)
    function testMenuTitlesFitOnOneLineInEveryLanguage(logger as Test.Logger) as Boolean {
        Test.assert(firstTooLong(TITLE_KEYS, TITLE_MAX_CHARS) == null);
        return true;
    }

    (:test)
    function testRatioRowsOfTheReportLeaveRoomForTheirNumbers(logger as Test.Logger) as Boolean {
        Test.assert(firstTooLong(RATIO_LABEL_KEYS, RATIO_LABEL_MAX_CHARS) == null);
        return true;
    }

    (:test)
    function testTimeAndBodyRowsOfTheReportLeaveRoomForTheirNumbers(logger as Test.Logger) as Boolean {
        Test.assert(firstTooLong(MATCH_TIME_KEYS, MATCH_TIME_MAX_CHARS) == null);
        Test.assert(firstTooLong(GAME_TIME_KEYS, GAME_TIME_MAX_CHARS) == null);
        Test.assert(firstTooLong(BODY_LABEL_KEYS, BODY_LABEL_MAX_CHARS) == null);
        return true;
    }

    (:test)
    function testMessageLinesStayInsideTheFrameRingInEveryLanguage(logger as Test.Logger) as Boolean {
        var lineChars = new MessageView("", 0, 0).LINE_CHARS;
        var texts = messageTexts();
        for (var i = 0; i < texts.size(); i++) {
            var lines = Theme.splitTwoLines(texts[i], lineChars);
            Test.assert((lines[0] as String).length() <= MESSAGE_LINE_MAX_CHARS);
            Test.assert((lines[lines.size() - 1] as String).length() <= MESSAGE_LINE_MAX_CHARS);
        }
        return true;
    }

    (:test)
    function testATextOverTheLimitIsFound(logger as Test.Logger) as Boolean {
        Test.assertEqual(firstTooLong([Str.AppName], 5), "Tennis");
        Test.assert(firstTooLong([Str.AppName], 6) == null);
        return true;
    }
}
