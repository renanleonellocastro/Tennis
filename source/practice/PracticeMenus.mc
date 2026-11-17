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

    // The confirmation closes itself after the answer and the practice screen
    // shows again, which is where an ended practice moves to the summary.
    class EndPracticeConfirmDelegate extends WatchUi.ConfirmationDelegate {
        hidden var _controller as PracticeController;

        function initialize(controller as PracticeController) {
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

    class PracticeDiscardConfirmDelegate extends WatchUi.ConfirmationDelegate {
        hidden var _controller as PracticeController;

        function initialize(controller as PracticeController) {
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
}
