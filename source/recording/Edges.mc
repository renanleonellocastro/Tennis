import Toybox.Lang;

// The edges of the app that touch the watch: the activity file, the body
// sensors, the GPS and the storage. The app passes the real ones (see
// FitSession, WatchSensors, GpsLocator and AppStorage) and the tests pass
// fakes, so every rule of the recording runs in a unit test.

// A developer field holds one number, a list of numbers or a text.
typedef FieldValue as Number or Array<Number> or String;

typedef ActivitySession as interface {
    function start() as Void;
    function stop() as Void;
    function addLap() as Void;
    function save() as Void;
    function discard() as Void;
    // Writes one developer field (see RecordingFields).
    function setField(id as Number, value as FieldValue) as Void;
};

// Every reading is null when the watch has none.
typedef BodySensors as interface {
    function heartRate() as Number?;
    // Steps and centimeters walked today, as the watch counts them.
    function steps() as Number?;
    function distanceCm() as Number?;
    // Of the activity being recorded.
    function averageHeartRate() as Number?;
    function maxHeartRate() as Number?;
    function calories() as Number?;
};

typedef Locator as interface {
    function turnOn() as Void;
    function turnOff() as Void;
};

typedef KeyValueStore as interface {
    function get(key as String) as Object?;
    function put(key as String, value as Array) as Void;
    function remove(key as String) as Void;
};
