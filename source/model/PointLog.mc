import Toybox.Lang;

// The ordered list of packed entries (see PointEntry). It is the single
// source of truth of a match: storing the array and loading it back is all
// that resume needs.
class PointLog {
    hidden var _entries as Array<Number>;

    // Pass an empty array for a new match or a stored one to resume.
    function initialize(entries as Array<Number>) {
        _entries = entries;
    }

    function append(entry as Number) as Void {
        _entries.add(entry);
    }

    // Keeps the first size entries and drops the rest.
    function truncate(size as Number) as Void {
        _entries = _entries.slice(0, size);
    }

    function size() as Number {
        return _entries.size();
    }

    function at(index as Number) as Number {
        return _entries[index];
    }

    function toArray() as Array<Number> {
        return _entries;
    }
}
