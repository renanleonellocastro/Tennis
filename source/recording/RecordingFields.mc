import Toybox.Lang;

// The developer fields this app writes to the activity file. The ids are
// shared with the converter on the computer (docs/RECORDING.md): 0 to 4
// and 7 belong to later milestones and must stay free.
module RecordingFields {
    const STEPS = 5;
    const DISTANCE = 6;
    const SET_STEPS = 8;
    const SET_DISTANCE = 9;

    const STEPS_UNIT = "steps";
    const METERS_UNIT = "m";

    // [id, name in the file, true for a lap field, unit]
    const TABLE = [
        [STEPS, "steps", false, STEPS_UNIT],
        [DISTANCE, "distance", false, METERS_UNIT],
        [SET_STEPS, "set_steps", true, STEPS_UNIT],
        [SET_DISTANCE, "set_distance", true, METERS_UNIT]
    ];
}
