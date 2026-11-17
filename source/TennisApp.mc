import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Application entry point: opens the home screen.
class TennisApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new HomeView(), new HomeDelegate()];
    }
}
