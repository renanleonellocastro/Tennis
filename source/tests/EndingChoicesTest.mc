import Toybox.Lang;
import Toybox.Test;

// Tests for the list of point endings of detailed mode.
module EndingChoicesTests {
    (:test)
    function testAceIsOfferedOnlyWhenTheServerWonThePoint(logger as Test.Logger) as Boolean {
        var served = EndingChoices.endings(Player.ME, Player.ME);
        var returned = EndingChoices.endings(Player.OPPONENT, Player.ME);
        Test.assertEqual(served.size(), 4);
        Test.assertEqual(served[1], Ending.ACE);
        Test.assertEqual(returned.size(), 3);
        Test.assert(returned.indexOf(Ending.ACE) < 0);
        Test.assertEqual(returned[0], Ending.WINNER);
        return true;
    }

    (:test)
    function testTheBallOutIsPreselected(logger as Test.Logger) as Boolean {
        var served = EndingChoices.endings(Player.OPPONENT, Player.OPPONENT);
        var returned = EndingChoices.endings(Player.ME, Player.OPPONENT);
        Test.assertEqual(served[EndingChoices.preselected(served)], Ending.ERROR_OUT);
        Test.assertEqual(returned[EndingChoices.preselected(returned)], Ending.ERROR_OUT);
        return true;
    }

    (:test)
    function testEveryEndingHasATextInEveryLanguage(logger as Test.Logger) as Boolean {
        var endings = EndingChoices.endings(Player.ME, Player.ME);
        for (var i = 0; i < endings.size(); i++) {
            assertKeyInEveryLanguage(EndingChoices.labelKey(endings[i]));
        }
        Test.assertEqual(EndingChoices.labelKey(Ending.ERROR_NET), Str.EndingErrorNet);
        assertKeyInEveryLanguage(Str.EndingTitle);
        return true;
    }

    (:test)
    function testTheLastBallBelongsToTheWinnerOrToTheLoserOnAnError(logger as Test.Logger) as Boolean {
        Test.assertEqual(EndingChoices.author(Ending.WINNER, Player.ME), Player.ME);
        Test.assertEqual(EndingChoices.author(Ending.ACE, Player.OPPONENT), Player.OPPONENT);
        Test.assertEqual(EndingChoices.author(Ending.ERROR_NET, Player.ME), Player.OPPONENT);
        Test.assertEqual(EndingChoices.author(Ending.ERROR_OUT, Player.OPPONENT), Player.ME);
        Test.assertEqual(EndingChoices.authorKey(Ending.WINNER, Player.ME), Str.PlayerMe);
        Test.assertEqual(EndingChoices.authorKey(Ending.ERROR_OUT, Player.ME), Str.PlayerOpponent);
        return true;
    }

    // UP and DOWN take the two common endings. START takes the winner, or
    // the full list when an ace is possible too. BACK leaves.
    (:test)
    function testTheCommonEndingsSitOnTheKeys(logger as Test.Logger) as Boolean {
        var returned = [Ending.ERROR_OUT, Ending.WINNER, Ending.ERROR_NET, EndingChoices.CANCEL];
        var served = [Ending.ERROR_OUT, EndingChoices.MORE, Ending.ERROR_NET, EndingChoices.CANCEL];
        Test.assertEqual(EndingChoices.keyChoices(Player.ME, Player.OPPONENT).toString(), returned.toString());
        Test.assertEqual(EndingChoices.keyChoices(Player.OPPONENT, Player.ME).toString(), returned.toString());
        Test.assertEqual(EndingChoices.keyChoices(Player.ME, Player.ME).toString(), served.toString());
        Test.assertEqual(EndingChoices.keyChoices(Player.OPPONENT, Player.OPPONENT).toString(), served.toString());
        Test.assertEqual(returned[KeySlot.UP], Ending.ERROR_OUT);
        Test.assertEqual(returned[KeySlot.DOWN], Ending.ERROR_NET);
        return true;
    }

    (:test)
    function testEveryKeyOfTheEndingScreenHasItsText(logger as Test.Logger) as Boolean {
        var returned = EndingChoices.keyTexts(Player.ME, Player.OPPONENT);
        var served = EndingChoices.keyTexts(Player.ME, Player.ME);
        Test.assertEqual(returned.toString(),
                         [Str.EndingErrorOut, Str.EndingWinner, Str.EndingErrorNet, Str.KeyBack].toString());
        Test.assertEqual(served[KeySlot.START], Str.KeyMore);
        Test.assertEqual(EndingChoices.choiceKey(EndingChoices.CANCEL), Str.KeyBack);
        for (var slot = 0; slot < KeySlot.COUNT; slot++) {
            assertKeyInEveryLanguage(served[slot]);
        }
        return true;
    }

    (:test)
    function testAKeyPicksItsEndingWhereTheLabelsShow(logger as Test.Logger) as Boolean {
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.POINT_ME, true, Player.ME, Player.OPPONENT), Ending.ERROR_OUT);
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.POINT_OPPONENT, true, Player.ME, Player.ME), Ending.ERROR_NET);
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.FAULT, true, Player.ME, Player.OPPONENT), Ending.WINNER);
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.FAULT, true, Player.ME, Player.ME), EndingChoices.MORE);
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.UNDO, true, Player.ME, Player.ME), EndingChoices.CANCEL);
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.NONE, true, Player.ME, Player.ME), EndingChoices.NOTHING);
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.MENU, true, Player.ME, Player.ME), EndingChoices.NOTHING);
        return true;
    }

    // A touch watch shows no key labels: only the key that leaves works.
    (:test)
    function testOnlyTheKeyThatLeavesWorksWithoutLabels(logger as Test.Logger) as Boolean {
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.UNDO, false, Player.ME, Player.ME), EndingChoices.CANCEL);
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.POINT_ME, false, Player.ME, Player.ME), EndingChoices.NOTHING);
        Test.assertEqual(EndingChoices.keyChoice(MatchAction.FAULT, false, Player.ME, Player.ME), EndingChoices.NOTHING);
        return true;
    }

    // A touch screen has an area for every ending, most common first.
    (:test, :keyArc)
    function testATouchScreenOffersEveryEnding(logger as Test.Logger) as Boolean {
        Test.assertEqual(EndingChoices.tapChoices(Player.ME, Player.OPPONENT).toString(),
                         [Ending.ERROR_OUT, Ending.ERROR_NET, Ending.WINNER].toString());
        Test.assertEqual(EndingChoices.tapChoices(Player.OPPONENT, Player.OPPONENT).toString(),
                         [Ending.ERROR_OUT, Ending.ERROR_NET, Ending.WINNER, Ending.ACE].toString());
        return true;
    }

    (:test, :keyArc)
    function testTheTapAreasFormTwoRows(logger as Test.Logger) as Boolean {
        var screen = [360, 360] as Array<Number>;
        Test.assertEqual(EndingChoices.tapRect(0, 4, screen, true).toString(), "[36, 111, 136, 72]");
        Test.assertEqual(EndingChoices.tapRect(1, 4, screen, true).toString(), "[187, 111, 137, 72]");
        Test.assertEqual(EndingChoices.tapRect(2, 4, screen, true).toString(), "[36, 198, 136, 72]");
        Test.assertEqual(EndingChoices.tapRect(3, 4, screen, true).toString(), "[187, 198, 137, 72]");
        Test.assertEqual(EndingChoices.tapRect(2, 3, screen, true).toString(), "[36, 198, 288, 72]");
        Test.assertEqual(EndingChoices.textRoom([36, 111, 136, 72] as Array<Number>).toString(), "[124, 72]");
        return true;
    }

    // A flat screen has its corners to fill: wider and taller areas.
    (:test, :keyArc)
    function testTheTapAreasFillAFlatScreen(logger as Test.Logger) as Boolean {
        var screen = [320, 360] as Array<Number>;
        Test.assertEqual(EndingChoices.tapRect(0, 4, screen, false).toString(), "[19, 111, 134, 97]");
        Test.assertEqual(EndingChoices.tapRect(3, 4, screen, false).toString(), "[166, 223, 134, 97]");
        Test.assertEqual(EndingChoices.tapRect(2, 3, screen, false).toString(), "[19, 223, 281, 97]");
        Test.assertEqual(EndingChoices.tapChoice([30, 300] as Array<Number>, screen, false, Player.ME, Player.ME),
                         Ending.WINNER);
        Test.assertEqual(EndingChoices.tapChoice([30, 300] as Array<Number>, screen, true, Player.ME, Player.ME),
                         EndingChoices.NOTHING);
        return true;
    }

    // Every corner of every area is inside a round screen, with a margin.
    (:test, :keyArc)
    function testTheTapAreasStayInsideARoundScreen(logger as Test.Logger) as Boolean {
        var sizes = [218, 240, 260, 280, 360, 390, 416, 454] as Array<Number>;
        for (var s = 0; s < sizes.size(); s++) {
            for (var i = 0; i < 4; i++) {
                assertInsideRound(EndingChoices.tapRect(i, 4, [sizes[s], sizes[s]] as Array<Number>, true), sizes[s]);
            }
        }
        return true;
    }

    function assertInsideRound(box as Array<Number>, size as Number) as Void {
        var half = size / 2;
        var dx = (box[0] - half).abs() > (box[0] + box[2] - half).abs() ? box[0] - half : box[0] + box[2] - half;
        var dy = (box[1] - half).abs() > (box[1] + box[3] - half).abs() ? box[1] - half : box[1] + box[3] - half;
        var limit = half * 95 / 100;
        Test.assert(dx * dx + dy * dy <= limit * limit);
    }

    (:test, :keyArc)
    function testATapPicksTheEndingOfItsArea(logger as Test.Logger) as Boolean {
        var screen = [360, 360] as Array<Number>;
        Test.assertEqual(EndingChoices.tapChoice([50, 120] as Array<Number>, screen, true, Player.ME, Player.ME), Ending.ERROR_OUT);
        Test.assertEqual(EndingChoices.tapChoice([300, 120] as Array<Number>, screen, true, Player.ME, Player.ME), Ending.ERROR_NET);
        Test.assertEqual(EndingChoices.tapChoice([50, 260] as Array<Number>, screen, true, Player.ME, Player.ME), Ending.WINNER);
        Test.assertEqual(EndingChoices.tapChoice([300, 260] as Array<Number>, screen, true, Player.ME, Player.ME), Ending.ACE);
        Test.assertEqual(EndingChoices.tapChoice([300, 260] as Array<Number>, screen, true, Player.ME, Player.OPPONENT), Ending.WINNER);
        Test.assertEqual(EndingChoices.tapChoice([180, 120] as Array<Number>, screen, true, Player.ME, Player.ME), EndingChoices.NOTHING);
        Test.assertEqual(EndingChoices.tapChoice([180, 40] as Array<Number>, screen, true, Player.ME, Player.ME), EndingChoices.NOTHING);
        return true;
    }

    // The full list opens without touching the waiting point; leaving drops
    // it; a press that means nothing keeps it.
    (:test)
    function testAChoiceThatIsNotAnEndingLogsNothing(logger as Test.Logger) as Boolean {
        var bench = new MatchBench(MatchFormat.BEST_OF_3, true);
        bench.play("M");
        Test.assert(EndingChoices.settle(bench.controller, EndingChoices.MORE) == null);
        Test.assertEqual(EndingChoices.settle(bench.controller, EndingChoices.NOTHING), Reaction.NONE);
        Test.assertEqual(bench.controller.pendingWinner(), Player.ME);
        Test.assertEqual(EndingChoices.settle(bench.controller, EndingChoices.CANCEL), Reaction.NONE);
        Test.assertEqual(bench.controller.pendingWinner(), Player.NONE);
        Test.assertEqual(bench.engine.log().size(), 0);
        return true;
    }

    // The point log gets the same ending code as from the list.
    (:test)
    function testAnEndingFromAKeyLogsThePoint(logger as Test.Logger) as Boolean {
        var bench = new MatchBench(MatchFormat.BEST_OF_3, true);
        bench.play("O");
        var choice = EndingChoices.keyChoice(MatchAction.POINT_ME, true, Player.OPPONENT, bench.controller.state().server());
        Test.assertEqual(EndingChoices.settle(bench.controller, choice), Reaction.withCue(Cue.POINT));
        Test.assertEqual(PointEntry.ending(bench.engine.log().at(0)), Ending.ERROR_OUT);
        Test.assertEqual(bench.score(), "0-0 0-0 0-15");
        return true;
    }
}
