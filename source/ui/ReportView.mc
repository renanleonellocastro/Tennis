import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// One page of the report at a time: the title, the rows the presenter
// builds for that page and the page number. It only places texts.
class ReportView extends WatchUi.View {
    hidden const CENTERED = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const FROM_LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const TO_RIGHT = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
    hidden const PLAYER_CELLS = 3;

    hidden var _presenter as ReportPresenter;
    hidden var _controller as MatchController;
    hidden var _layout as ReportLayout;
    hidden var _pager as ReportPager;

    function initialize(presenter as ReportPresenter, controller as MatchController, layout as ReportLayout,
                        pager as ReportPager) {
        View.initialize();
        _presenter = presenter;
        _controller = controller;
        _layout = layout;
        _pager = pager;
    }

    function onUpdate(dc as Dc) as Void {
        var page = _presenter.page(_pager.index(), _controller.isDetailed(), _controller.clockSeconds(),
                                   _controller.sensors());
        var rows = page[1] as Array<Array>;
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);
        drawText(dc, _layout.centerX(), _layout.titleY(), Theme.COLOR_ACCENT, Strings.t(page[0] as Number), CENTERED);
        drawHeader(dc, rows[0].size());
        for (var i = 0; i < rows.size(); i++) {
            drawCells(dc, _layout.rowY(i), rows[i], Theme.COLOR_TEXT);
        }
        drawText(dc, _layout.centerX(), _layout.pagerY(), Theme.COLOR_TEXT_DIM, _pager.label(), CENTERED);
    }

    // Whose column is whose, on the pages that compare the players.
    hidden function drawHeader(dc as Dc, cellCount as Number) as Void {
        if (cellCount == PLAYER_CELLS) {
            drawCells(dc, _layout.headerY(), ["", Strings.t(Str.LabelMe), Strings.t(Str.LabelOpponent)],
                      Theme.COLOR_ACCENT);
        }
    }

    // The label is dim; the values take the given color.
    hidden function drawCells(dc as Dc, y as Number, cells as Array, valueColor as Number) as Void {
        var xs = _layout.cellXs(cells.size());
        var justifications = cells.size() == PLAYER_CELLS ? [CENTERED, CENTERED, CENTERED] : [FROM_LEFT, TO_RIGHT];
        for (var i = 0; i < cells.size(); i++) {
            drawText(dc, xs[i], y, i == 0 ? Theme.COLOR_TEXT_DIM : valueColor, cells[i] as String,
                     justifications[i]);
        }
    }

    hidden function drawText(dc as Dc, x as Number, y as Number, color as Number, text as String,
                             justification as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_XTINY, text, justification);
    }
}

// DOWN, START, a tap or a swipe up turns to the next page and UP or a
// swipe down to the one before. BACK closes the report.
class ReportDelegate extends WatchUi.BehaviorDelegate {
    hidden var _pager as ReportPager;

    function initialize(pager as ReportPager) {
        BehaviorDelegate.initialize();
        _pager = pager;
    }

    hidden function turn(step as Number) as Boolean {
        _pager.turn(step);
        WatchUi.requestUpdate();
        return true;
    }

    function onNextPage() as Boolean {
        return turn(1);
    }

    function onSelect() as Boolean {
        return turn(1);
    }

    function onPreviousPage() as Boolean {
        return turn(-1);
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
