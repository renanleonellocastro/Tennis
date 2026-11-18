import Toybox.Lang;

// A short list of choices, each one the index of an option. The texts are
// keys of the string table, so a new option is one more key in its row and
// no new code. MatchSetup and MatchTags are the two lists of the app.
class OptionList {
    hidden var _labelKeys as Array<Number>;
    hidden var _valueKeys as Array< Array<Number> >;
    hidden var _values as Array<Number>;

    // Takes what storage returned. Anything that is not a full list of valid
    // options falls back to the first option of every field.
    function initialize(labelKeys as Array<Number>, valueKeys as Array< Array<Number> >, stored as Object?) {
        _labelKeys = labelKeys;
        _valueKeys = valueKeys;
        _values = firstOptions();
        if (isValid(stored)) {
            _values = stored as Array<Number>;
        }
    }

    hidden function firstOptions() as Array<Number> {
        var values = [] as Array<Number>;
        for (var field = 0; field < _labelKeys.size(); field++) {
            values.add(0);
        }
        return values;
    }

    hidden function isValid(stored as Object?) as Boolean {
        if (!(stored instanceof Lang.Array) || stored.size() != _labelKeys.size()) {
            return false;
        }
        for (var field = 0; field < _labelKeys.size(); field++) {
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
        return _valueKeys[field].size();
    }

    // Moves a field to its next option, wrapping to the first one.
    function cycle(field as Number) as Void {
        _values[field] = (_values[field] + 1) % optionCount(field);
    }

    function labelKey(field as Number) as Number {
        return _labelKeys[field];
    }

    function valueKey(field as Number) as Number {
        return _valueKeys[field][_values[field]];
    }

    // The value to put in storage.
    function toArray() as Array<Number> {
        return _values;
    }
}
