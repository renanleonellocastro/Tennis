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
//
// The point log field holds three entries, so it is paced too: each value
// stays for one wait before the next one replaces it. A game given by the
// fix of the score logs four points or more at once, and they reach the
// file three at a time.
class PacedSession {
    // Longer than the second between two looks of the watch.
    const SETTLE_MS = 1500;

    hidden var _session as ActivitySession;
    hidden var _alarm as Alarm;
    hidden var _isSettling as Boolean = false;
    hidden var _isStopDue as Boolean = false;
    hidden var _isSaveDue as Boolean = false;
    // Values of the point log field that wait their turn, oldest first.
    hidden var _windows as Array< Array<Number> > = [] as Array< Array<Number> >;
    // The newest entry the file was given and that still stands.
    hidden var _given as Number = 0;

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
        _windows = [] as Array< Array<Number> >;
        _session.discard();
    }

    function addLap() as Void {
        _session.addLap();
    }

    function setField(id as Number, value as FieldValue) as Void {
        if (id == RecordingFields.POINT_LOG) {
            offer(value as Array<Number>);
        } else {
            _session.setField(id, value);
        }
    }

    // Queues a value of the point log field. It replaces the waiting ones
    // whose entries it carries as well.
    hidden function offer(window as Array<Number>) as Void {
        var newest = PointSlot.newest(window);
        _given = newest < _given ? newest : _given;
        var last = _windows.size() - 1;
        while (last >= 0 && newest - givenBefore(last) <= PointSlot.SLOTS) {
            _windows = _windows.slice(0, last);
            last--;
        }
        _windows.add(window);
        proceed();
    }

    // The newest entry the file has when the turn of a waiting value comes.
    hidden function givenBefore(index as Number) as Number {
        return index == 0 ? _given : PointSlot.newest(_windows[index - 1]);
    }

    // The alarm rings: the last start or stop is old enough.
    function onSettled() as Void {
        _isSettling = false;
        proceed();
    }

    // Carries out the next thing that waits: the point log first, then the
    // stop, then the save. A stop follows the last value of the point log
    // at once, because the record of that stop carries it.
    hidden function proceed() as Void {
        if (_isSettling) {
            return;
        }
        if (_windows.size() > 0 && isHeldByTheNextValue()) {
            settle();
        } else {
            close();
        }
    }

    // Gives the field its next value. True when what follows has to wait
    // for it: another value, or nothing at all.
    hidden function isHeldByTheNextValue() as Boolean {
        _given = PointSlot.newest(_windows[0]);
        _session.setField(RecordingFields.POINT_LOG, _windows[0]);
        _windows = _windows.slice(1, null);
        return _windows.size() > 0 || !_isStopDue;
    }

    hidden function close() as Void {
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
