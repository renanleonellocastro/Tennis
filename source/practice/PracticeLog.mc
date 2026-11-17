import Toybox.Lang;

// The counters of a practice: the hits and misses of the open block and of
// every block closed before it. A closed block is final, because its lap is
// already in the activity and a lap cannot be taken back.
class PracticeLog {
    hidden const NUMBERS_PER_BLOCK = 2;
    hidden const MISSES_OFFSET = 1;

    // The closed blocks, flat: hits and then misses of each one.
    hidden var _closed as Array<Number> = [] as Array<Number>;
    // The entries of the open block in order, true for a hit. Undo needs
    // the order, and the misses are the entries that are not hits.
    hidden var _trail as Array<Boolean> = [] as Array<Boolean>;
    hidden var _hits as Number = 0;

    function hit() as Void {
        _trail.add(true);
        _hits++;
    }

    function miss() as Void {
        _trail.add(false);
    }

    // Takes back the last entry of the open block. False when it has none.
    function undo() as Boolean {
        var last = _trail.size() - 1;
        if (last < 0) {
            return false;
        }
        if (_trail[last]) {
            _hits--;
        }
        _trail = _trail.slice(0, last);
        return true;
    }

    // Closes the open block and opens the next one. False for a block with
    // no entries, so pressing twice does not leave an empty block behind.
    function closeBlock() as Boolean {
        if (_trail.size() == 0) {
            return false;
        }
        _closed.add(_hits);
        _closed.add(misses());
        _trail = [] as Array<Boolean>;
        _hits = 0;
        return true;
    }

    // The open block.

    function hits() as Number {
        return _hits;
    }

    function misses() as Number {
        return _trail.size() - _hits;
    }

    // Counted from 1, as the screen shows it.
    function blockNumber() as Number {
        return closedBlocks() + 1;
    }

    function closedBlocks() as Number {
        return _closed.size() / NUMBERS_PER_BLOCK;
    }

    // The summary: every closed block and the open one when it has entries.

    function blocks() as Number {
        return closedBlocks() + (_trail.size() > 0 ? 1 : 0);
    }

    function hitsOf(block as Number) as Number {
        return block < closedBlocks() ? _closed[block * NUMBERS_PER_BLOCK] : _hits;
    }

    function missesOf(block as Number) as Number {
        return block < closedBlocks() ? _closed[block * NUMBERS_PER_BLOCK + MISSES_OFFSET] : misses();
    }

    function totalHits() as Number {
        var total = _hits;
        for (var block = 0; block < closedBlocks(); block++) {
            total += hitsOf(block);
        }
        return total;
    }

    function totalMisses() as Number {
        var total = misses();
        for (var block = 0; block < closedBlocks(); block++) {
            total += missesOf(block);
        }
        return total;
    }
}
