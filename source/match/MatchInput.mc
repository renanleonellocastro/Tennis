import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// What an input on the match screen asks for. The ids index the handler
// table of MatchController.
module MatchAction {
    const NONE = 0;
    const POINT_ME = 1;
    const POINT_OPPONENT = 2;
    const FAULT = 3;
    const UNDO = 4;
    const MENU = 5;
}

// How this watch can score: with the UP and DOWN keys, by touch, or both.
class InputProfile {
    hidden var _isTouch as Boolean;
    hidden var _hasScoreKeys as Boolean;

    function initialize(isTouch as Boolean, inputButtons as Number) {
        var scoreKeys = System.BUTTON_INPUT_UP | System.BUTTON_INPUT_DOWN;
        _isTouch = isTouch;
        _hasScoreKeys = (inputButtons & scoreKeys) == scoreKeys;
    }

    function hasScoreKeys() as Boolean {
        return _hasScoreKeys;
    }

    // Watches with two buttons score by touch and have no key for the serve
    // fault or, on some, for the menu: they get both as controls on screen.
    function usesTouchControls() as Boolean {
        return _isTouch && !_hasScoreKeys;
    }

    // False on a two button watch with touch turned off in its settings.
    function canScore() as Boolean {
        return _isTouch || _hasScoreKeys;
    }
}

// Turns raw keys and taps into match actions.
module MatchInput {
    function profileOfDevice() as InputProfile {
        var settings = System.getDeviceSettings();
        return new InputProfile(settings.isTouchScreen, settings.inputButtons);
    }

    function actionForKey(key as Number) as Number {
        var actions = {
            WatchUi.KEY_UP => MatchAction.POINT_ME,
            WatchUi.KEY_DOWN => MatchAction.POINT_OPPONENT,
            WatchUi.KEY_ENTER => MatchAction.FAULT,
            WatchUi.KEY_ESC => MatchAction.UNDO
        } as Dictionary<Number, Number>;
        var action = actions.get(key);
        return action == null ? MatchAction.NONE : action;
    }

    // The left half is mine and the right half is the opponent's. Where the
    // controls are on screen, their band holds the menu and the serve fault.
    function actionForTap(x as Number, y as Number, layout as MatchLayout) as Number {
        var isLeft = x < layout.centerX();
        if (layout.isOnControls(y)) {
            return isLeft ? MatchAction.MENU : MatchAction.FAULT;
        }
        return isLeft ? MatchAction.POINT_ME : MatchAction.POINT_OPPONENT;
    }
}
