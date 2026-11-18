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
}
