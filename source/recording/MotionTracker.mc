import Toybox.Lang;

// Adds up the steps and the distance of a match from the counters of the
// watch, which run all day. Only the change between two readings counts,
// and only while the match is not paused.
class MotionTracker {
    hidden const STEPS = 0;
    hidden const DISTANCE = 1;
    hidden const CM_PER_METER = 100;

    hidden var _last as Array<Number?> = [null, null] as Array<Number?>;
    hidden var _total as Array<Number> = [0, 0] as Array<Number>;
    hidden var _lap as Array<Number> = [0, 0] as Array<Number>;
    hidden var _isCounting as Boolean = true;

    // Takes the counters of the watch as they are now.
    function update(steps as Number?, distanceCm as Number?) as Void {
        add(STEPS, steps);
        add(DISTANCE, distanceCm);
    }

    // The first reading only sets the starting point. A reading below the
    // last one means the watch started a new day, so it counts in full.
    hidden function add(counter as Number, reading as Number?) as Void {
        var last = _last[counter];
        if (reading == null) {
            return;
        }
        _last[counter] = reading;
        if (_isCounting && last != null) {
            var change = reading >= last ? reading - last : reading;
            _total[counter] += change;
            _lap[counter] += change;
        }
    }

    // Readings taken during a pause move the starting point and add nothing.
    function pause() as Void {
        _isCounting = false;
    }

    function resume() as Void {
        _isCounting = true;
    }

    function closeLap() as Void {
        _lap = [0, 0] as Array<Number>;
    }

    function steps() as Number {
        return _total[STEPS];
    }

    function meters() as Number {
        return _total[DISTANCE] / CM_PER_METER;
    }

    function lapSteps() as Number {
        return _lap[STEPS];
    }

    function lapMeters() as Number {
        return _lap[DISTANCE] / CM_PER_METER;
    }
}
