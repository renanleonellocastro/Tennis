import Toybox.FitContributor;
import Toybox.Lang;

// The developer fields this app writes to the activity file. The ids, names
// and shapes are shared with the converter on the computer
// (docs/DATA_FORMAT.md).
module RecordingFields {
    // The newest entries of the point log, on every record (see PointSlot),
    // and the size of the whole log.
    const POINT_LOG = 0;
    const LOG_SIZE = 1;
    const MATCH_SETUP = 2;
    const FINAL_SCORE = 3;
    const STATISTICS = 4;
    const STEPS = 5;
    const DISTANCE = 6;
    const SET_SCORE = 7;
    const SET_STEPS = 8;
    const SET_DISTANCE = 9;
    // Practice: the hits and misses of a block, on its lap.
    const BLOCK_HITS = 10;
    const BLOCK_MISSES = 11;

    const NO_UNIT = "";
    const ENTRIES_UNIT = "entries";
    const COUNTS_UNIT = "counts";
    const STEPS_UNIT = "steps";
    const METERS_UNIT = "m";
    const SHOTS_UNIT = "shots";

    // The bytes of the score text, its closing zero byte included.
    const SCORE_BYTES = 32;
    const STATISTICS_COUNT = 30;
    const SET_SCORE_COUNT = 4;
    const POINT_LOG_COUNT = 9;
    const SINGLE = 1;

    // The kind of activity a field belongs to. A file carries only the
    // fields of its kind, which is how a reader tells a practice from a
    // match.
    const MATCH = 1;
    const PRACTICE = 2;
    const BOTH = 3;

    const RECORD = FitContributor.MESG_TYPE_RECORD;
    const LAP = FitContributor.MESG_TYPE_LAP;
    const SESSION = FitContributor.MESG_TYPE_SESSION;

    // [id, name in the file, message, unit, type, count, kind]
    const TABLE = [
        [POINT_LOG, "point_log", RECORD, NO_UNIT, FitContributor.DATA_TYPE_UINT32, POINT_LOG_COUNT, MATCH],
        [LOG_SIZE, "log_size", SESSION, ENTRIES_UNIT, FitContributor.DATA_TYPE_UINT16, SINGLE, MATCH],
        [MATCH_SETUP, "match_setup", SESSION, NO_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE, MATCH],
        [FINAL_SCORE, "final_score", SESSION, NO_UNIT, FitContributor.DATA_TYPE_STRING, SCORE_BYTES, MATCH],
        [STATISTICS, "statistics", SESSION, COUNTS_UNIT, FitContributor.DATA_TYPE_UINT16, STATISTICS_COUNT, MATCH],
        [STEPS, "steps", SESSION, STEPS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE, BOTH],
        [DISTANCE, "distance", SESSION, METERS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE, BOTH],
        [SET_SCORE, "set_score", LAP, NO_UNIT, FitContributor.DATA_TYPE_UINT8, SET_SCORE_COUNT, MATCH],
        [SET_STEPS, "set_steps", LAP, STEPS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE, BOTH],
        [SET_DISTANCE, "set_distance", LAP, METERS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE, BOTH],
        [BLOCK_HITS, "block_hits", LAP, SHOTS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE, PRACTICE],
        [BLOCK_MISSES, "block_misses", LAP, SHOTS_UNIT, FitContributor.DATA_TYPE_UINT32, SINGLE, PRACTICE]
    ];

    function isOfKind(row as Array, kind as Number) as Boolean {
        return ((row[6] as Number) & kind) != 0;
    }

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
