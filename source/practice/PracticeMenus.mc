import Toybox.Lang;
import Toybox.WatchUi;

module PracticeFlow {
    // Delegates of the menus around a practice. Each one passes the choice on
    // to the controller and closes its menu; the screen underneath reads the
    // new state when it shows again.

    class PracticeMenuDelegate extends WatchUi.Menu2InputDelegate {
        hidden var _controller as PracticeController;

        function initialize(controller as PracticeController) {
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

        function askToEnd() as Void {
            PracticeFlow.showEndConfirmation(_controller);
        }

        function onBack() as Void {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }

    // Runs an action of the practice when the answer is yes. The confirmation
    // closes itself after the answer and the screen underneath shows again:
    // the practice screen moves an ended practice to the summary and the
    // summary leaves a discarded one.
    class PracticeConfirmDelegate extends WatchUi.ConfirmationDelegate {
        hidden var _action as Method() as Void;

        function initialize(action as Method() as Void) {
            ConfirmationDelegate.initialize();
            _action = action;
        }

        function onResponse(response as WatchUi.Confirm) as Boolean {
            if (response == WatchUi.CONFIRM_YES) {
                _action.invoke();
            }
            return true;
        }
    }

    // Save or discard, from the summary. The menu closes after the choice and
    // the summary shows again, which is where a closed practice leaves.
    class PracticeSaveMenuDelegate extends WatchUi.Menu2InputDelegate {
        hidden var _controller as PracticeController;

        function initialize(controller as PracticeController) {
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
            PracticeFlow.showDiscardConfirmation(_controller);
        }

        function onBack() as Void {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}
