import Toybox.Lang;

// The short notice shown after a game, a set or a change of ends. It holds
// the text keys and goes away by itself after a few seconds.
class MatchNotice {
    static const VISIBLE_MS = 4000;

    hidden var _keys as Array<Number> = [] as Array<Number>;
    hidden var _shownAtMs as Number = 0;

    function show(keys as Array<Number>, nowMs as Number) as Void {
        _keys = keys;
        _shownAtMs = nowMs;
    }

    function clear() as Void {
        _keys = [] as Array<Number>;
    }

    function keys(nowMs as Number) as Array<Number> {
        if (nowMs - _shownAtMs >= VISIBLE_MS) {
            clear();
        }
        return _keys;
    }
}
