import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// The final score: who won, the sets and the time played, with a mark at
// the bottom for the report that waits one page down.
class FinalScoreView extends WatchUi.View {
    hidden const TITLE_Y = 28;
    hidden const SETS_Y = 50;
    hidden const CLOCK_Y = 72;
    hidden const MORE_Y = 88;
    hidden const MORE_SIZE_DIVISOR = 30;
    hidden const CENTERED = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    hidden var _controller as MatchController;

    function initialize(controller as MatchController) {
        View.initialize();
        _controller = controller;
    }

    // The save menu and the discard question close over this screen, so it
    // looks at the result each time it comes back.
    function onShow() as Void {
        MatchFlow.showFarewellIfClosed(_controller);
    }

    function onUpdate(dc as Dc) as Void {
        var state = _controller.state();
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);
        drawLine(dc, TITLE_Y, Graphics.FONT_SMALL, Theme.COLOR_ACCENT,
                 Strings.t(MatchPresenter.finalTitleKey(state)));
        drawLine(dc, SETS_Y, Graphics.FONT_MEDIUM, Theme.COLOR_TEXT, MatchPresenter.finalSetsText(state));
        drawLine(dc, CLOCK_Y, Graphics.FONT_TINY, Theme.COLOR_TEXT_DIM,
                 MatchPresenter.clockText(_controller.clockSeconds()));
        drawMoreMark(dc);
    }

    // A small arrow head pointing down.
    hidden function drawMoreMark(dc as Dc) as Void {
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() * MORE_Y / 100;
        var size = dc.getWidth() / MORE_SIZE_DIVISOR;
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x - size, y], [x + size, y], [x, y + size]]);
    }

    hidden function drawLine(dc as Dc, percentY as Number, font as Graphics.FontDefinition,
                             color as Number, text as String) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * percentY / 100, font, text, CENTERED);
    }
}

// START or a tap opens the menu to save, see the report or discard. DOWN or
// a swipe up opens the report directly. BACK returns to the match, so a
// last point entered by mistake can still be taken back.
class FinalScoreDelegate extends WatchUi.BehaviorDelegate {
    hidden var _controller as MatchController;

    function initialize(controller as MatchController) {
        BehaviorDelegate.initialize();
        _controller = controller;
    }

    function onSelect() as Boolean {
        MatchFlow.pushFinalMenu(_controller);
        return true;
    }

    function onNextPage() as Boolean {
        MatchFlow.pushReport(_controller);
        return true;
    }

    function onBack() as Boolean {
        _controller.reopen();
        MatchFlow.showMatch(_controller, WatchUi.SLIDE_DOWN);
        return true;
    }
}
