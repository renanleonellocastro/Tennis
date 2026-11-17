import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;

// The real sensors, GPS and storage of the watch.

class WatchSensors {
    function heartRate() as Number? {
        var info = Activity.getActivityInfo() as Activity.Info?;
        if (info == null) {
            return null;
        }
        return info.currentHeartRate;
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
