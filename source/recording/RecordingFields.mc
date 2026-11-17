import Toybox.FitContributor;
import Toybox.Lang;

// The developer fields this app writes to the activity file. The ids, names
// and shapes are shared with the converter on the computer
// (docs/DATA_FORMAT.md): 0 and 1 belong to the point log of a later
// milestone and must stay free.
module RecordingFields {
    const MATCH_SETUP = 2;
    const FINAL_SCORE = 3;
    const STATISTICS = 4;
    const STEPS = 5;
    const DISTANCE = 6;
    const SET_SCORE = 7;
    const SET_STEPS = 8;
    const SET_DISTANCE = 9;

    const NO_UNIT = "";
    const COUNTS_UNIT = "counts";
    const STEPS_UNIT = "steps";
    const METERS_UNIT = "m";

    // The bytes of the score text, its closing zero byte included.
    const SCORE_BYTES = 32;
    const STATISTICS_COUNT = 30;
    const SET_SCORE_COUNT = 4;
    const SINGLE = 1;

    // [id, name in the file, true for a lap field, unit, type, count]
    const TABLE = [
        [MATCH_SETUP, "match_setup", false, NO_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE],
        [FINAL_SCORE, "final_score", false, NO_UNIT, FitContributor.DATA_TYPE_STRING, SCORE_BYTES],
        [STATISTICS, "statistics", false, COUNTS_UNIT, FitContributor.DATA_TYPE_UINT16, STATISTICS_COUNT],
        [STEPS, "steps", false, STEPS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE],
        [DISTANCE, "distance", false, METERS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE],
        [SET_SCORE, "set_score", true, NO_UNIT, FitContributor.DATA_TYPE_UINT8, SET_SCORE_COUNT],
        [SET_STEPS, "set_steps", true, STEPS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE],
        [SET_DISTANCE, "set_distance", true, METERS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE]
    ];

    // What a field holds before the match gives it a value: zero, zeros or
    // an empty text.
    function emptyValue(type as Number, count as Number) as FieldValue {
        if (type == FitContributor.DATA_TYPE_STRING) {
            return "";
        }
        return count == SINGLE ? 0 : zeros(count);
    }

    function zeros(count as Number) as Array<Number> {
        var values = [] as Array<Number>;
        for (var i = 0; i < count; i++) {
            values.add(0);
        }
        return values;
    }
}
