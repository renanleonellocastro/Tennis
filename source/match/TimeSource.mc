import Toybox.Lang;
import Toybox.System;

// Where the match reads the current time from, in milliseconds. The app
// passes the system timer and the tests pass a clock they move by hand.
typedef TimeSource as interface {
    function now() as Number;
};

class SystemTime {
    function now() as Number {
        return System.getTimer();
    }
}
