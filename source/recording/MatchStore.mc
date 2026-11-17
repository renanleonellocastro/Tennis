import Toybox.Lang;

// Keeps the match in progress in storage, so it survives the app closing:
// one value with the setup, one value per set with its log entries and one
// with the marks of the engine, which let a long match come back without
// applying its whole log.
// A value stays far below the 8 KB that every watch accepts, since a set
// would need about 1600 entries to reach it.
class MatchStore {
    hidden const VERSION = 1;
    hidden const HEADER_SIZE = 2;
    hidden const HEADER_KEY = "match";
    hidden const SET_KEY = "set";
    hidden const MARKS_KEY = "marks";

    hidden var _values as KeyValueStore;
    // Index in the log of the first entry of each stored set.
    hidden var _starts as Array<Number> = [0] as Array<Number>;
    // How many marks the stored value holds.
    hidden var _markCount as Number = 0;

    function initialize(values as KeyValueStore) {
        _values = values;
    }

    // Starts a new match, replacing any stored one.
    function begin(setup as Array<Number>) as Void {
        clear();
        _values.put(HEADER_KEY, [VERSION, setup]);
    }

    function hasMatch() as Boolean {
        return header() != null;
    }

    hidden function header() as Array? {
        var stored = _values.get(HEADER_KEY);
        if (stored instanceof Lang.Array && stored.size() == HEADER_SIZE && VERSION.equals(stored[0] as Object?)) {
            return stored;
        }
        return null;
    }

    // [setup values, log entries, marks] of the stored match, or null.
    function load() as Array? {
        var stored = header();
        return stored == null ? null : [stored[1], loadEntries(), loadMarks()];
    }

    hidden function loadMarks() as Array< Array<Number> > {
        var stored = _values.get(MARKS_KEY);
        var marks = (stored instanceof Lang.Array ? stored : []) as Array< Array<Number> >;
        _markCount = marks.size();
        return marks;
    }

    hidden function loadEntries() as Array<Number> {
        var entries = [] as Array<Number>;
        var starts = [0] as Array<Number>;
        addAll(entries, _values.get(setKey(0)));
        var set = _values.get(setKey(1));
        while (set instanceof Lang.Array) {
            starts.add(entries.size());
            addAll(entries, set);
            set = _values.get(setKey(starts.size()));
        }
        _starts = starts;
        return entries;
    }

    hidden function addAll(entries as Array<Number>, stored as Object?) as Void {
        if (stored instanceof Lang.Array) {
            entries.addAll(stored as Array<Number>);
        }
    }

    // Stores the log after a change. Only the set in progress is written
    // again; the sets a correction went back over are removed. The marks
    // are written only when one was added or removed.
    function sync(entries as Array<Number>, finishedSets as Number, marks as Array< Array<Number> >) as Void {
        syncSets(entries, finishedSets);
        if (marks.size() != _markCount) {
            _markCount = marks.size();
            _values.put(MARKS_KEY, marks as Array);
        }
    }

    hidden function syncSets(entries as Array<Number>, finishedSets as Number) as Void {
        while (isLastSetStale(entries.size(), finishedSets)) {
            _values.remove(setKey(_starts.size() - 1));
            _starts = _starts.slice(0, -1);
        }
        var last = _starts.size() - 1;
        _values.put(setKey(last), entries.slice(_starts[last], null) as Array);
        if (_starts.size() <= finishedSets) {
            _starts.add(entries.size());
        }
    }

    hidden function isLastSetStale(logSize as Number, finishedSets as Number) as Boolean {
        var count = _starts.size();
        return count > 1 && (count > finishedSets + 1 || _starts[count - 1] > logSize);
    }

    function clear() as Void {
        _values.remove(HEADER_KEY);
        _values.remove(MARKS_KEY);
        _markCount = 0;
        for (var set = 0; _values.get(setKey(set)) != null; set++) {
            _values.remove(setKey(set));
        }
        _starts = [0] as Array<Number>;
    }

    hidden function setKey(set as Number) as String {
        return SET_KEY + set;
    }
}
