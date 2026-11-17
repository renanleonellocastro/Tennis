import Toybox.Lang;

// The choices of the setup screen: preset, deuce scoring, detail level and
// who serves first. Each field holds the index of one option, so a new
// option is one more key in its row and no new code.
class MatchSetup {
    static const FORMAT = 0;
    static const NO_ADVANTAGE = 1;
    static const DETAIL = 2;
    static const FIRST_SERVER = 3;
    static const FIELD_COUNT = 4;

    hidden const LABEL_KEYS = ["SetupFormat", "SetupNoAd", "SetupDetail", "SetupFirstServe"];
    // Rows follow the field ids; the options of each row follow the values
    // the engine uses (MatchFormat, off then on, simple then detailed, Player).
    hidden const VALUE_KEYS = [
        ["FormatBestOf3", "FormatMatchTieBreak", "FormatOneSet", "FormatProSet", "FormatTieBreakOnly"],
        ["ValueOff", "ValueOn"],
        ["DetailSimple", "DetailDetailed"],
        ["PlayerMe", "PlayerOpponent"]
    ];

    hidden var _values as Array<Number>;

    // Takes what storage returned. Anything that is not a full list of valid
    // options falls back to the defaults.
    function initialize(stored as Object?) {
        _values = isValid(stored) ? stored as Array<Number> : [0, 0, 0, 0] as Array<Number>;
    }

    hidden function isValid(stored as Object?) as Boolean {
        if (!(stored instanceof Lang.Array) || stored.size() != FIELD_COUNT) {
            return false;
        }
        for (var field = 0; field < FIELD_COUNT; field++) {
            if (!isOption(field, stored[field] as Object?)) {
                return false;
            }
        }
        return true;
    }

    hidden function isOption(field as Number, value as Object?) as Boolean {
        return value instanceof Lang.Number && value >= 0 && value < optionCount(field);
    }

    function optionCount(field as Number) as Number {
        return (VALUE_KEYS[field] as Array<String>).size();
    }

    // Moves a field to its next option, wrapping to the first one.
    function cycle(field as Number) as Void {
        _values[field] = (_values[field] + 1) % optionCount(field);
    }

    function labelKey(field as Number) as String {
        return LABEL_KEYS[field] as String;
    }

    function valueKey(field as Number) as String {
        return (VALUE_KEYS[field] as Array<String>)[_values[field]];
    }

    // The value to put in storage.
    function toArray() as Array<Number> {
        return _values;
    }

    function isDetailed() as Boolean {
        return _values[DETAIL] == 1;
    }

    function config() as MatchConfig {
        return new MatchConfig(_values[FORMAT], _values[NO_ADVANTAGE] == 1, _values[FIRST_SERVER]);
    }
}
