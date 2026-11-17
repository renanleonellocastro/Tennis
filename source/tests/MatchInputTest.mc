import Toybox.Lang;
import Toybox.System;
import Toybox.Test;
import Toybox.WatchUi;

// Tests for what each kind of watch can score with and for the mapping of
// keys and taps to match actions.
module MatchInputTests {
    const FIVE_BUTTONS = System.BUTTON_INPUT_SELECT | System.BUTTON_INPUT_UP | System.BUTTON_INPUT_DOWN
        | System.BUTTON_INPUT_MENU;
    const TWO_BUTTONS = System.BUTTON_INPUT_SELECT;

    (:test)
    function testFiveButtonWatchScoresWithItsKeys(logger as Test.Logger) as Boolean {
        var profile = new InputProfile(false, FIVE_BUTTONS);
        Test.assert(profile.hasScoreKeys());
        Test.assert(profile.canScore());
        Test.assert(!profile.usesTouchControls());
        return true;
    }

    (:test)
    function testTwoButtonWatchScoresByTouchWithControlsOnScreen(logger as Test.Logger) as Boolean {
        var profile = new InputProfile(true, TWO_BUTTONS);
        Test.assert(!profile.hasScoreKeys());
        Test.assert(profile.canScore());
        Test.assert(profile.usesTouchControls());
        return true;
    }

    (:test)
    function testTouchWatchWithFiveButtonsKeepsTheScreenClean(logger as Test.Logger) as Boolean {
        var profile = new InputProfile(true, FIVE_BUTTONS);
        Test.assert(profile.canScore());
        Test.assert(!profile.usesTouchControls());
        return true;
    }

    (:test)
    function testTwoButtonWatchWithTouchOffCannotScore(logger as Test.Logger) as Boolean {
        Test.assert(!new InputProfile(false, TWO_BUTTONS).canScore());
        Test.assert(!new InputProfile(false, System.BUTTON_INPUT_UP).hasScoreKeys());
        Test.assert(!new InputProfile(false, System.BUTTON_INPUT_DOWN).hasScoreKeys());
        return true;
    }

    (:test)
    function testTheDeviceUnderTestCanScore(logger as Test.Logger) as Boolean {
        Test.assert(MatchInput.profileOfDevice().canScore());
        return true;
    }

    (:test)
    function testKeysMapToTheirActions(logger as Test.Logger) as Boolean {
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_UP), MatchAction.POINT_ME);
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_DOWN), MatchAction.POINT_OPPONENT);
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_ENTER), MatchAction.FAULT);
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_ESC), MatchAction.UNDO);
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_MENU), MatchAction.NONE);
        Test.assertEqual(MatchInput.actionForKey(WatchUi.KEY_LIGHT), MatchAction.NONE);
        return true;
    }

    (:test)
    function testTapOnAHalfScoresForThatPlayer(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(416, 416, true, true);
        Test.assertEqual(MatchInput.actionForTap(100, 200, layout), MatchAction.POINT_ME);
        Test.assertEqual(MatchInput.actionForTap(207, 200, layout), MatchAction.POINT_ME);
        Test.assertEqual(MatchInput.actionForTap(208, 200, layout), MatchAction.POINT_OPPONENT);
        Test.assertEqual(MatchInput.actionForTap(400, 30, layout), MatchAction.POINT_OPPONENT);
        return true;
    }

    (:test)
    function testTapOnTheControlBandOpensTheMenuOrLogsAFault(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(416, 416, true, true);
        Test.assertEqual(MatchInput.actionForTap(100, 320, layout), MatchAction.MENU);
        Test.assertEqual(MatchInput.actionForTap(300, 320, layout), MatchAction.FAULT);
        Test.assertEqual(MatchInput.actionForTap(100, 294, layout), MatchAction.POINT_ME);
        Test.assertEqual(MatchInput.actionForTap(300, 349, layout), MatchAction.POINT_OPPONENT);
        return true;
    }

    (:test)
    function testTapScoresEverywhereWhenTheWatchHasTheKeys(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(260, 260, false, true);
        Test.assertEqual(MatchInput.actionForTap(50, 200, layout), MatchAction.POINT_ME);
        Test.assertEqual(MatchInput.actionForTap(200, 200, layout), MatchAction.POINT_OPPONENT);
        return true;
    }
}
