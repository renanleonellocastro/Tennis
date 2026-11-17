import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Application entry point: opens the home screen.
class TennisApp extends Application.AppBase {
    // Shared by whatever has to wait for the watch (see PacedSession).
    var alarm as WatchAlarm = new WatchAlarm();

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [new HomeView(), new HomeDelegate()];
    }

    // A match or a practice that is still open keeps what it recorded (see
    // RECORDING.md), and a save that was waiting is done now.
    function onStop(state as Dictionary?) as Void {
        var match = MatchFlow.active;
        if (match != null) {
            match.suspend();
        }
        var practice = PracticeFlow.active;
        if (practice != null) {
            practice.suspend();
        }
        alarm.ringNow();
    }
}
