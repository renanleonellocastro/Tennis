import Toybox.Lang;

// An activity session that gives the watch time to write its records. The
// watch looks at the session about once a second: a record is written only
// when it finds the timer running or just stopped, and it carries the
// fields as they are at that moment. So a stop that follows a start too
// closely is never seen, and a save that follows a stop too closely closes
// the file before the record of that stop is written. Either way the
// newest entries of the point log would miss the file. Here a stop waits
// until the start is old enough and a save until the stop is, so every
// entry reaches a record (see RECORDING.md).
class PacedSession {
    // Longer than the second between two looks of the watch.
    const SETTLE_MS = 1500;

    hidden var _session as ActivitySession;
    hidden var _alarm as Alarm;
    hidden var _isSettling as Boolean = false;
    hidden var _isStopDue as Boolean = false;
    hidden var _isSaveDue as Boolean = false;

    function initialize(session as ActivitySession, alarm as Alarm) {
        _session = session;
        _alarm = alarm;
    }

    // A stop that still waits is dropped: the timer never stopped.
    function start() as Void {
        if (_isStopDue) {
            _isStopDue = false;
        } else {
            _session.start();
            settle();
        }
    }

    function stop() as Void {
        _isStopDue = true;
        proceed();
    }

    function save() as Void {
        _isSaveDue = true;
        proceed();
    }

    // Nothing of a discarded activity is kept, so nothing waits.
    function discard() as Void {
        _isStopDue = false;
        _isSaveDue = false;
        _session.discard();
    }

    function addLap() as Void {
        _session.addLap();
    }

    function setField(id as Number, value as FieldValue) as Void {
        _session.setField(id, value);
    }

    // The alarm rings: the last start or stop is old enough.
    function onSettled() as Void {
        _isSettling = false;
        proceed();
    }

    // Carries out the next thing that waits, the stop before the save.
    hidden function proceed() as Void {
        if (_isSettling) {
            return;
        }
        if (_isStopDue) {
            _isStopDue = false;
            _session.stop();
            settle();
        } else if (_isSaveDue) {
            _isSaveDue = false;
            _session.save();
        }
    }

    hidden function settle() as Void {
        _isSettling = true;
        _alarm.ring(SETTLE_MS, method(:onSettled));
    }
}
