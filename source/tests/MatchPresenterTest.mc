import Toybox.Lang;
import Toybox.Test;

// Tests for the texts of the match and final screens.
module MatchPresenterTests {
    function setsTextAfter(format as Number, games as String, points as String) as String {
        var match = newMatch(format);
        match.games(games);
        match.play(points);
        return MatchPresenter.setsText(match.state());
    }

    (:test)
    function testPointsReadAsNumbersOrAsTheAdvantage(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play("MMMOOOM");
        Test.assertEqual(MatchPresenter.pointsText(match.state(), Player.ME), "AD");
        Test.assert(!MatchPresenter.isPointsNumeric(match.state(), Player.ME));
        Test.assertEqual(MatchPresenter.pointsText(match.state(), Player.OPPONENT), "40");
        Test.assert(MatchPresenter.isPointsNumeric(match.state(), Player.OPPONENT));
        return true;
    }

    (:test)
    function testSetsTextShowsFinishedSetsThenTheCurrentGames(logger as Test.Logger) as Boolean {
        Test.assertEqual(setsTextAfter(MatchFormat.BEST_OF_3, "", ""), "0-0");
        Test.assertEqual(setsTextAfter(MatchFormat.BEST_OF_3, "MO", "M"), "1-1");
        Test.assertEqual(setsTextAfter(MatchFormat.BEST_OF_3, "MMMMMMO", ""), "6-0  0-1");
        Test.assertEqual(setsTextAfter(MatchFormat.BEST_OF_3, "MMMMMMOOOOOOM", ""), "6-0  0-6  1-0");
        Test.assertEqual(setsTextAfter(MatchFormat.BEST_OF_3, "MMMMMMMMMMMM", ""), "6-0  6-0");
        return true;
    }

    (:test)
    function testSetsTextShowsATieBreakSetByItsGames(logger as Test.Logger) as Boolean {
        Test.assertEqual(setsTextAfter(MatchFormat.BEST_OF_3, "MOMOMOMOMOMO", "MM"), "6-6");
        Test.assertEqual(setsTextAfter(MatchFormat.BEST_OF_3, "MOMOMOMOMOMO", "MMMMMMM"), "7-6  0-0");
        return true;
    }

    (:test)
    function testSetsTextShowsATieBreakWithoutGamesByItsPoints(logger as Test.Logger) as Boolean {
        var decider = MatchFormat.BEST_OF_3_MATCH_TIE_BREAK;
        Test.assertEqual(setsTextAfter(decider, "MMMMMMOOOOOO", "MO"), "6-0  0-6");
        Test.assertEqual(setsTextAfter(decider, "MMMMMMOOOOOO", "OOOOOOOOMOO"), "6-0  0-6  1-10");
        Test.assertEqual(setsTextAfter(MatchFormat.TIE_BREAK_ONLY, "", "MMO"), "");
        Test.assertEqual(setsTextAfter(MatchFormat.TIE_BREAK_ONLY, "", "MMMMMOMM"), "7-1");
        return true;
    }

    function pressureAfter(format as Number, games as String, points as String) as String {
        var match = newMatch(format);
        match.games(games);
        match.play(points);
        var stake = MatchPresenter.pressure(match.state());
        return stake == null ? "none" : (stake[0] as String) + " " + (stake[1] as Number);
    }

    (:test)
    function testPressureNamesTheHeaviestPointAndItsHolder(logger as Test.Logger) as Boolean {
        Test.assertEqual(pressureAfter(MatchFormat.BEST_OF_3, "", ""), "none");
        Test.assertEqual(pressureAfter(MatchFormat.BEST_OF_3, "", "MMM"), "none");
        Test.assertEqual(pressureAfter(MatchFormat.BEST_OF_3, "", "OOO"), "LabelBreakPoint 1");
        Test.assertEqual(pressureAfter(MatchFormat.BEST_OF_3, "M", "MMM"), "LabelBreakPoint 0");
        Test.assertEqual(pressureAfter(MatchFormat.BEST_OF_3, "MMMMM", "MMM"), "LabelSetPoint 0");
        Test.assertEqual(pressureAfter(MatchFormat.BEST_OF_3, "OOOOO", "OOO"), "LabelSetPoint 1");
        Test.assertEqual(pressureAfter(MatchFormat.ONE_SET, "MMMMM", "MMM"), "LabelMatchPoint 0");
        Test.assertEqual(pressureAfter(MatchFormat.BEST_OF_3, "OOOOOOOOOOO", "OOO"), "LabelMatchPoint 1");
        return true;
    }

    function bannerText(isPaused as Boolean, keys as Array<String>, points as String) as String {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play(points);
        var banner = MatchPresenter.banner(isPaused, keys, match.state());
        return (banner[0] as String) + "|" + (banner[1] as Number);
    }

    (:test)
    function testBannerPrefersPauseThenNoticeThenPressure(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        var notice = ["NoticeGame"] as Array<String>;
        var none = [] as Array<String>;
        Test.assertEqual(bannerText(true, notice, "OOO"), "Paused|" + BannerTone.NOTICE);
        Test.assertEqual(bannerText(false, notice, "OOO"), "Game|" + BannerTone.NOTICE);
        Test.assertEqual(bannerText(false, none, "OOO"), "BREAK POINT|" + BannerTone.OPPONENT);
        Test.assertEqual(bannerText(false, none, "O"), "|" + BannerTone.NOTICE);
        return true;
    }

    (:test)
    function testClockTextUsesHoursOnlyWhenNeeded(logger as Test.Logger) as Boolean {
        Test.assertEqual(MatchPresenter.clockText(0), "0:00");
        Test.assertEqual(MatchPresenter.clockText(9), "0:09");
        Test.assertEqual(MatchPresenter.clockText(75), "1:15");
        Test.assertEqual(MatchPresenter.clockText(3599), "59:59");
        Test.assertEqual(MatchPresenter.clockText(3600), "1:00:00");
        Test.assertEqual(MatchPresenter.clockText(3725), "1:02:05");
        return true;
    }

    (:test)
    function testNoticeTextJoinsTheTranslatedKeys(logger as Test.Logger) as Boolean {
        Strings.loadTables("eng");
        Test.assertEqual(MatchPresenter.noticeText([] as Array<String>), "");
        Test.assertEqual(MatchPresenter.noticeText(["NoticeSet"] as Array<String>), "Set");
        Test.assertEqual(MatchPresenter.noticeText(["NoticeGame", "NoticeChangeEnds"] as Array<String>),
                         "Game. Change ends");
        return true;
    }

    (:test)
    function testFinalTitleSaysWhoWonOrThatTheMatchWasEnded(logger as Test.Logger) as Boolean {
        var won = newMatch(MatchFormat.TIE_BREAK_ONLY);
        var lost = newMatch(MatchFormat.TIE_BREAK_ONLY);
        won.play("MMMMMMM");
        lost.play("OOOOOOO");
        Test.assertEqual(MatchPresenter.finalTitleKey(won.state()), "FinalYouWon");
        Test.assertEqual(MatchPresenter.finalTitleKey(lost.state()), "FinalYouLost");
        Test.assertEqual(MatchPresenter.finalTitleKey(newMatch(MatchFormat.BEST_OF_3).state()), "FinalMatchEnded");
        return true;
    }

    (:test)
    function testMatchScreenTextsExistInEveryLanguage(logger as Test.Logger) as Boolean {
        var keys = ["LabelMe", "LabelOpponent", "LabelAdvantage", "LabelBreakPoint", "LabelSetPoint",
                    "LabelMatchPoint", "NoticeGame", "NoticeSet", "NoticeChangeEnds", "Paused", "ControlFault",
                    "HomeHint", "FinalYouWon", "FinalYouLost", "FinalMatchEnded", "EndMatchQ", "TouchNeededMsg",
                    "SetupStart", "PlayerMe", "PlayerOpponent"];
        for (var i = 0; i < keys.size(); i++) {
            assertKeyInEveryLanguage(keys[i] as String);
        }
        return true;
    }

    (:test)
    function testHeartRateTextIsEmptyWithoutAReading(logger as Test.Logger) as Boolean {
        Test.assertEqual(MatchPresenter.heartRateText(null), "");
        Test.assertEqual(MatchPresenter.heartRateText(142), "142");
        return true;
    }
}
