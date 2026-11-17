import Toybox.Lang;

// The list of marks of MatchEngine, oldest first. The first number of a
// mark is the size the log had when it was taken.
module MatchMarks {
    // The marks taken with the log at this size or shorter.
    function upTo(marks as Array< Array<Number> >, size as Number) as Array< Array<Number> > {
        var count = marks.size();
        while (count > 0 && marks[count - 1][0] > size) {
            count--;
        }
        return count == marks.size() ? marks : marks.slice(0, count);
    }

    // The newest mark taken with the log at this size or shorter, or null.
    function newestUpTo(marks as Array< Array<Number> >, size as Number) as Array<Number>? {
        for (var i = marks.size() - 1; i >= 0; i--) {
            if (marks[i][0] <= size) {
                return marks[i];
            }
        }
        return null;
    }

    // Zero, the start of the match, when there is no mark.
    function newestIndex(marks as Array< Array<Number> >) as Number {
        return marks.size() == 0 ? 0 : marks[marks.size() - 1][0];
    }
}
