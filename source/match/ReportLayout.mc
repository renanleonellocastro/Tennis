import Toybox.Lang;

// Every position of a report page, as plain numbers derived from the
// screen size. The rows are percentages of the height chosen so each one
// fits inside the chord of a round screen at that height.
class ReportLayout {
    hidden const TITLE_Y = 15;
    hidden const HEADER_Y = 29;
    hidden const FIRST_ROW_Y = 42;
    hidden const ROW_STEP = 12;
    hidden const PAGER_Y = 91;
    // My values; the opponent's column mirrors it.
    hidden const PLAYER_X = 19;
    // The label and the value of a page without players.
    hidden const LABEL_X = 17;

    hidden var _width as Number;
    hidden var _height as Number;

    function initialize(width as Number, height as Number) {
        _width = width;
        _height = height;
    }

    hidden function row(percent as Number) as Number {
        return _height * percent / 100;
    }

    hidden function column(percent as Number) as Number {
        return _width * percent / 100;
    }

    function centerX() as Number {
        return _width / 2;
    }

    function titleY() as Number {
        return row(TITLE_Y);
    }

    function headerY() as Number {
        return row(HEADER_Y);
    }

    function rowY(index as Number) as Number {
        return row(FIRST_ROW_Y + index * ROW_STEP);
    }

    function pagerY() as Number {
        return row(PAGER_Y);
    }

    // Where the cells of a row go. Three cells are the label in the middle
    // with my value on its left and the opponent's on its right, each one
    // centered on its x. Two cells are a label that starts at the first x
    // and a value that ends at the second.
    function cellXs(cellCount as Number) as Array<Number> {
        if (cellCount == 2) {
            return [column(LABEL_X), _width - column(LABEL_X)] as Array<Number>;
        }
        return [centerX(), column(PLAYER_X), _width - column(PLAYER_X)] as Array<Number>;
    }
}
