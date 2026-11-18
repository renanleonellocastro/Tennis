import Toybox.Lang;

// Fakes for the edges of the recording (see Edges.mc). Nothing here
// carries (:test).

// Writes down every call as one letter, and the last value of each field.
class FakeSession {
    var calls as String = "";
    var fields as Dictionary<Number, FieldValue> = {} as Dictionary<Number, FieldValue>;
    // The lap fields as they were when each lap closed: [steps, meters].
    var laps as Array< Array<Number> > = [] as Array< Array<Number> >;
    // The set score each lap closed with, as text: "6,4,0,0".
    var lapScores as Array<String> = [] as Array<String>;
    // The newest sequence number of the point log at each start and stop,
    // where the watch writes a record.
    var records as Array<Number> = [] as Array<Number>;
    // The newest sequence number of every value the point log field took.
    var written as Array<Number> = [] as Array<Number>;

    function start() as Void {
        calls += "s";
        writeRecord();
    }

    function stop() as Void {
        calls += "p";
        writeRecord();
    }

    function writeRecord() as Void {
        var slots = fields.get(RecordingFields.POINT_LOG);
        records.add(slots instanceof Lang.Array ? (slots as Array<Number>)[0] & PointSlot.SEQUENCE_MASK : 0);
    }

    function addLap() as Void {
        calls += "l";
        laps.add([fields[RecordingFields.SET_STEPS], fields[RecordingFields.SET_DISTANCE]] as Array<Number>);
        lapScores.add(numbers(RecordingFields.SET_SCORE));
    }

    function save() as Void {
        calls += "S";
    }

    function discard() as Void {
        calls += "D";
    }

    function setField(id as Number, value as FieldValue) as Void {
        fields.put(id, value);
        if (id == RecordingFields.POINT_LOG) {
            written.add((value as Array<Number>)[0] & PointSlot.SEQUENCE_MASK);
        }
    }

    // An array field as text, or "" when it was never written.
    function numbers(id as Number) as String {
        var value = fields.get(id);
        return value instanceof Lang.Array ? joinedNumbers(value as Array<Number>) : "";
    }
}

// Keeps the callback until the test lets the time pass.
class FakeAlarm {
    var delays as Array<Number> = [] as Array<Number>;
    hidden var _callback as (Method() as Void)? = null;

    function ring(delayMs as Number, callback as Method() as Void) as Void {
        delays.add(delayMs);
        _callback = callback;
    }

    function isWaiting() as Boolean {
        return _callback != null;
    }

    function pass() as Void {
        var callback = _callback as Method() as Void;
        _callback = null;
        callback.invoke();
    }
}

class FakeSensors {
    var beats as Number? = null;
    var stepCount as Number? = null;
    var centimeters as Number? = null;
    var averageBeats as Number? = null;
    var maxBeats as Number? = null;
    var kilocalories as Number? = null;

    function heartRate() as Number? {
        return beats;
    }

    function steps() as Number? {
        return stepCount;
    }

    function distanceCm() as Number? {
        return centimeters;
    }

    function averageHeartRate() as Number? {
        return averageBeats;
    }

    function maxHeartRate() as Number? {
        return maxBeats;
    }

    function calories() as Number? {
        return kilocalories;
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

function joinedNumbers(values as Array<Number>) as String {
    var text = "";
    for (var i = 0; i < values.size(); i++) {
        text += (i == 0 ? "" : ",") + values[i];
    }
    return text;
}
