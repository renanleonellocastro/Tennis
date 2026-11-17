import Toybox.Lang;

// Fakes for the edges of the recording (see Edges.mc). Nothing here
// carries (:test).

// Writes down every call as one letter, and the last value of each field.
class FakeSession {
    var calls as String = "";
    var fields as Dictionary<Number, Number> = {} as Dictionary<Number, Number>;
    // The lap fields as they were when each lap closed: [steps, meters].
    var laps as Array< Array<Number> > = [] as Array< Array<Number> >;

    function start() as Void {
        calls += "s";
    }

    function stop() as Void {
        calls += "p";
    }

    function addLap() as Void {
        calls += "l";
        laps.add([fields[RecordingFields.SET_STEPS], fields[RecordingFields.SET_DISTANCE]] as Array<Number>);
    }

    function save() as Void {
        calls += "S";
    }

    function discard() as Void {
        calls += "D";
    }

    function setField(id as Number, value as Number) as Void {
        fields.put(id, value);
    }
}

class FakeSensors {
    var beats as Number? = null;
    var stepCount as Number? = null;
    var centimeters as Number? = null;

    function heartRate() as Number? {
        return beats;
    }

    function steps() as Number? {
        return stepCount;
    }

    function distanceCm() as Number? {
        return centimeters;
    }

    function walk(newSteps as Number, newCentimeters as Number) as Void {
        stepCount = (stepCount == null ? 0 : stepCount) + newSteps;
        centimeters = (centimeters == null ? 0 : centimeters) + newCentimeters;
    }
}

class FakeLocator {
    var calls as String = "";

    function turnOn() as Void {
        calls += "+";
    }

    function turnOff() as Void {
        calls += "-";
    }
}

// Storage in memory. It keeps a copy of each value, as the watch does.
class MemoryStore {
    var values as Dictionary<String, Array> = {} as Dictionary<String, Array>;
    var writes as Number = 0;

    function get(key as String) as Object? {
        return values.get(key);
    }

    function put(key as String, value as Array) as Void {
        values.put(key, value.slice(0, null) as Array);
        writes++;
    }

    function remove(key as String) as Void {
        values.remove(key);
    }
}
