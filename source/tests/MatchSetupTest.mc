import Toybox.Application;
import Toybox.Lang;
import Toybox.Test;

// Tests for the setup choices and how they are remembered.
module MatchSetupTests {
    function assertFallsBackToDefaults(stored as Object?) as Void {
        Test.assertEqual(joinedNumbers(new MatchSetup(stored).toArray()), "0,0,0,0,0");
    }

    (:test)
    function testSetupDefaultsWhenStorageHasNothingUsable(logger as Test.Logger) as Boolean {
        assertFallsBackToDefaults(null);
        assertFallsBackToDefaults("setup");
        assertFallsBackToDefaults([0, 0, 0, 0]);
        assertFallsBackToDefaults([5, 0, 0, 0, 0]);
        assertFallsBackToDefaults([0, 2, 0, 0, 0]);
        assertFallsBackToDefaults([0, 0, -1, 0, 0]);
        assertFallsBackToDefaults([0, 0, 0, "me", 0]);
        assertFallsBackToDefaults([0, 0, 0, 0, 2]);
        return true;
    }

    (:test)
    function testSetupKeepsValidStoredChoices(logger as Test.Logger) as Boolean {
        var setup = new MatchSetup([4, 1, 1, 1, 1]);
        Test.assertEqual(joinedNumbers(setup.toArray()), "4,1,1,1,1");
        Test.assertEqual(setup.valueKey(MatchSetup.FORMAT), Str.FormatTieBreakOnly);
        Test.assertEqual(setup.valueKey(MatchSetup.NO_ADVANTAGE), Str.ValueOff);
        Test.assertEqual(setup.valueKey(MatchSetup.DETAIL), Str.DetailDetailed);
        Test.assertEqual(setup.valueKey(MatchSetup.FIRST_SERVER), Str.PlayerOpponent);
        Test.assertEqual(setup.valueKey(MatchSetup.GPS), Str.ValueOn);
        return true;
    }

    (:test)
    function testSetupCycleVisitsEveryOptionAndWraps(logger as Test.Logger) as Boolean {
        var setup = new MatchSetup(null);
        for (var field = 0; field < MatchSetup.FIELD_COUNT; field++) {
            for (var step = 1; step < setup.optionCount(field); step++) {
                setup.cycle(field);
                Test.assertEqual(setup.toArray()[field], step);
            }
            setup.cycle(field);
            Test.assertEqual(setup.toArray()[field], 0);
        }
        return true;
    }

    (:test)
    function testSetupOffersFiveFormatsAndTwoOfTheRest(logger as Test.Logger) as Boolean {
        var setup = new MatchSetup(null);
        Test.assertEqual(setup.optionCount(MatchSetup.FORMAT), 5);
        Test.assertEqual(setup.optionCount(MatchSetup.NO_ADVANTAGE), 2);
        Test.assertEqual(setup.optionCount(MatchSetup.DETAIL), 2);
        Test.assertEqual(setup.optionCount(MatchSetup.FIRST_SERVER), 2);
        Test.assertEqual(setup.optionCount(MatchSetup.GPS), 2);
        return true;
    }

    (:test)
    function testSetupTextsExistInEveryLanguage(logger as Test.Logger) as Boolean {
        var setup = new MatchSetup(null);
        for (var field = 0; field < MatchSetup.FIELD_COUNT; field++) {
            assertKeyInEveryLanguage(setup.labelKey(field));
            for (var option = 0; option < setup.optionCount(field); option++) {
                assertKeyInEveryLanguage(setup.valueKey(field));
                setup.cycle(field);
            }
        }
        return true;
    }

    (:test)
    function testSetupDefaultIsSimpleBestOfThreeWithAdvantage(logger as Test.Logger) as Boolean {
        var setup = new MatchSetup(null);
        var config = setup.config();
        Test.assert(!setup.isDetailed());
        Test.assertEqual(config.setsToWin(), 2);
        Test.assertEqual(config.matchTieBreakPoints(), 0);
        Test.assertEqual(config.gameWinMargin(), 2);
        Test.assertEqual(config.serverAt(0), Player.ME);
        return true;
    }

    (:test)
    function testSetupBuildsTheChosenConfig(logger as Test.Logger) as Boolean {
        var setup = new MatchSetup([1, 1, 1, 1, 0]);
        var config = setup.config();
        Test.assert(setup.isDetailed());
        Test.assertEqual(config.matchTieBreakPoints(), 10);
        Test.assertEqual(config.gameWinMargin(), 1);
        Test.assertEqual(config.serverAt(0), Player.OPPONENT);
        return true;
    }

    (:test)
    function testSetupStoreRemembersTheLastChoices(logger as Test.Logger) as Boolean {
        var setup = new MatchSetup([3, 0, 1, 1, 1]);
        SetupStore.save(setup);
        Test.assertEqual(joinedNumbers(SetupStore.load().toArray()), "3,0,1,1,1");
        Application.Storage.deleteValue(SetupStore.KEY);
        Test.assertEqual(joinedNumbers(SetupStore.load().toArray()), "0,0,0,0,0");
        return true;
    }

    (:test)
    function testSetupGpsIsOffUntilChosen(logger as Test.Logger) as Boolean {
        var setup = new MatchSetup(null);
        Test.assert(!setup.usesGps());
        setup.cycle(MatchSetup.GPS);
        Test.assert(setup.usesGps());
        return true;
    }

    (:test)
    function testSetupHidesTheGpsRowOnAWatchWithoutGps(logger as Test.Logger) as Boolean {
        var setup = new MatchSetup(null);
        Test.assertEqual(joinedNumbers(setup.fields(true)), "0,1,2,3,4");
        Test.assertEqual(joinedNumbers(setup.fields(false)), "0,1,2,3");
        return true;
    }
}
