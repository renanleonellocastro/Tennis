import Toybox.Lang;
import Toybox.WatchUi;

// Delegates of the menus around a match. Each one passes the choice on to
// the setup or the controller and closes its menu; the match screen reads
// the new state when it shows again.

class SetupMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _setup as MatchSetup;

    function initialize(setup as MatchSetup) {
        Menu2InputDelegate.initialize();
        _setup = setup;
    }

    // A choice row moves to its next option; the start row starts.
    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof Lang.Number) {
            _setup.cycle(id);
            item.setSubLabel(Strings.t(_setup.valueKey(id)));
            WatchUi.requestUpdate();
        } else {
            MatchFlow.start(_setup);
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class MatchMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _controller as MatchController;

    function initialize(controller as MatchController) {
        Menu2InputDelegate.initialize();
        _controller = controller;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        method(item.getId() as Symbol).invoke();
    }

    function togglePause() as Void {
        _controller.togglePause();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function openFixMenu() as Void {
        MatchFlow.showFixMenu(_controller);
    }

    function askToEnd() as Void {
        MatchFlow.showEndConfirmation(_controller);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class FixMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _controller as MatchController;

    function initialize(controller as MatchController) {
        Menu2InputDelegate.initialize();
        _controller = controller;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        method(item.getId() as Symbol).invoke();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function undoGame() as Void {
        _controller.undoGame();
    }

    function gameForMe() as Void {
        _controller.awardGame(Player.ME);
    }

    function gameForOpponent() as Void {
        _controller.awardGame(Player.OPPONENT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// The confirmation closes itself after the answer and the match screen
// shows again, which is where an ended match moves to the final score.
class EndMatchConfirmDelegate extends WatchUi.ConfirmationDelegate {
    hidden var _controller as MatchController;

    function initialize(controller as MatchController) {
        ConfirmationDelegate.initialize();
        _controller = controller;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _controller.end();
        }
        return true;
    }
}

// Save or discard, from the final score. The menu closes after the choice
// and the final screen shows again, which is where a closed match leaves.
class FinalMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _controller as MatchController;

    function initialize(controller as MatchController) {
        Menu2InputDelegate.initialize();
        _controller = controller;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        method(item.getId() as Symbol).invoke();
    }

    function save() as Void {
        _controller.save();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function askToDiscard() as Void {
        MatchFlow.showDiscardConfirmation(_controller);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class DiscardConfirmDelegate extends WatchUi.ConfirmationDelegate {
    hidden var _controller as MatchController;

    function initialize(controller as MatchController) {
        ConfirmationDelegate.initialize();
        _controller = controller;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _controller.discard();
        }
        return true;
    }
}

// Offered at launch when the app closed during a match. BACK keeps the
// stored match for the next launch.
class ResumeMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _store as MatchStore;

    function initialize(store as MatchStore) {
        Menu2InputDelegate.initialize();
        _store = store;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        method(item.getId() as Symbol).invoke();
    }

    function resume() as Void {
        MatchFlow.resume(_store);
    }

    function discard() as Void {
        _store.clear();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class EndingMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _controller as MatchController;

    function initialize(controller as MatchController) {
        Menu2InputDelegate.initialize();
        _controller = controller;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var reaction = _controller.chooseEnding(item.getId() as Number);
        if ((reaction & Reaction.VIBRATE) != 0) {
            MatchAlert.changeEnds();
        }
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

    function onBack() as Void {
        _controller.cancelEnding();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
