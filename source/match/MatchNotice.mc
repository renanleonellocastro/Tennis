import Toybox.Lang;

// The notice shown after a game, a set or a change of ends, as its text
// key. It goes away by itself after a few seconds unless it was asked to
// stay.
class MatchNotice {
    static const VISIBLE_MS = 4000;

    hidden var _key as Number? = null;
    hidden var _shownAtMs as Number = 0;
    hidden var _stays as Boolean = false;

    function show(key as Number?, nowMs as Number, stays as Boolean) as Void {
        _key = key;
        _shownAtMs = nowMs;
        _stays = stays;
    }

    function clear() as Void {
        _key = null;
    }

    function key(nowMs as Number) as Number? {
        if (!_stays && nowMs - _shownAtMs >= VISIBLE_MS) {
            clear();
        }
        return _key;
    }
}
