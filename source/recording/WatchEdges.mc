import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Timer;

// The real sensors, GPS, vibration and storage of the watch.

class WatchBuzzer {
    function buzz(steps as Array<Number>) as Void {
        if (Attention has :vibrate) {
            var profiles = [] as Array<Attention.VibeProfile>;
            for (var i = 0; i < steps.size(); i += 2) {
                profiles.add(new Attention.VibeProfile(steps[i], steps[i + 1]));
            }
            Attention.vibrate(profiles);
        }
    }
}

class WatchSensors {
    function heartRate() as Number? {
        var info = Activity.getActivityInfo() as Activity.Info?;
        if (info == null) {
            return null;
        }
        return info.currentHeartRate;
    }

    function averageHeartRate() as Number? {
        var info = Activity.getActivityInfo() as Activity.Info?;
        return info == null ? null : info.averageHeartRate;
    }

    function maxHeartRate() as Number? {
        var info = Activity.getActivityInfo() as Activity.Info?;
        return info == null ? null : info.maxHeartRate;
    }

    function calories() as Number? {
        var info = Activity.getActivityInfo() as Activity.Info?;
        return info == null ? null : info.calories;
    }

    function steps() as Number? {
        return ActivityMonitor.getInfo().steps;
    }

    function distanceCm() as Number? {
        return ActivityMonitor.getInfo().distance;
    }
}

// Turns the GPS on for the match, so the watch adds the track to the
// activity. The positions themselves are not used by the app.
class GpsLocator {
    static function isAvailable() as Boolean {
        return (Toybox has :Position) && (Position has :enableLocationEvents);
    }

    function turnOn() as Void {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function turnOff() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
    }

    function onPosition(info as Position.Info) as Void {
    }
}

// Used when the GPS is off in the setup or missing on the watch.
class NoLocator {
    function turnOn() as Void {
    }

    function turnOff() as Void {
    }
}

// One timer for what has to wait (see PacedSession). When the app closes
// nothing can wait any longer, so whatever is due is called at once.
class WatchAlarm {
    hidden var _timer as Timer.Timer = new Timer.Timer();
    hidden var _callback as (Method() as Void)? = null;

    function ring(delayMs as Number, callback as Method() as Void) as Void {
        _callback = callback;
        _timer.stop();
        _timer.start(method(:onTimer), delayMs, false);
    }

    function isWaiting() as Boolean {
        return _callback != null;
    }

    function onTimer() as Void {
        var callback = _callback;
        _callback = null;
        if (callback != null) {
            callback.invoke();
        }
    }

    // A callback may ring again (a stop, then the save), so this goes on
    // until nothing waits.
    function ringNow() as Void {
        _timer.stop();
        while (_callback != null) {
            onTimer();
        }
    }
}

class AppStorage {
    function get(key as String) as Object? {
        return Application.Storage.getValue(key);
    }

    function put(key as String, value as Array) as Void {
        Application.Storage.setValue(key, value as Application.Storage.ValueType);
    }

    function remove(key as String) as Void {
        Application.Storage.deleteValue(key);
    }
}
