import Toybox.Lang;

// Which page of the report shows. Turning past either end goes around.
class ReportPager {
    hidden var _count as Number;
    hidden var _index as Number = 0;

    function initialize(count as Number) {
        _count = count;
    }

    function index() as Number {
        return _index;
    }

    // One page forward (1) or back (-1).
    function turn(step as Number) as Void {
        _index = (_index + step + _count) % _count;
    }

    // "2/6"
    function label() as String {
        return (_index + 1) + "/" + _count;
    }
}
