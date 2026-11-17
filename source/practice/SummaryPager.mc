import Toybox.Lang;

// Which page of the practice summary shows. The summary lists one row per
// block and a practice can have more blocks than fit on the screen.
class SummaryPager {
    hidden var _rows as Number;
    hidden var _pageSize as Number;
    hidden var _page as Number = 0;

    function initialize(rows as Number, pageSize as Number) {
        _rows = rows;
        _pageSize = pageSize;
    }

    // A summary with no rows still has its one page.
    function pages() as Number {
        return _rows == 0 ? 1 : (_rows + _pageSize - 1) / _pageSize;
    }

    function page() as Number {
        return _page;
    }

    function pageSize() as Number {
        return _pageSize;
    }

    function firstRow() as Number {
        return _page * _pageSize;
    }

    // False on the last page, which stays.
    function next() as Boolean {
        if (_page + 1 >= pages()) {
            return false;
        }
        _page++;
        return true;
    }

    // False on the first page, which stays.
    function previous() as Boolean {
        if (_page == 0) {
            return false;
        }
        _page--;
        return true;
    }
}
