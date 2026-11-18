import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Home screen: the app name under the brand arc and the entry point to the
// menu.
class HomeView extends WatchUi.View {
    const BALL_Y_PERCENT = 30;
    const NAME_Y_PERCENT = 50;
    const HINT_Y_PERCENT = 80;
    const BALL_RADIUS_DIVISOR = 26;

    hidden var _hasOfferedResume as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        if (!_hasOfferedResume) {
            _hasOfferedResume = true;
            MatchFlow.offerResume();
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        Theme.drawFrameRing(dc);
        Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);
        drawBall(dc);
        drawAppName(dc);
        drawMenuHint(dc);
    }

    // Small tennis ball dot above the name: the detail color of the app.
    hidden function drawBall(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_BALL, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(dc.getWidth() / 2, dc.getHeight() * BALL_Y_PERCENT / 100,
                      dc.getWidth() / BALL_RADIUS_DIVISOR);
    }

    hidden function drawAppName(dc as Dc) as Void {
        dc.setColor(Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() * NAME_Y_PERCENT / 100,
                    Graphics.FONT_LARGE, Strings.t(Str.AppName).toUpper(),
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawMenuHint(dc as Dc) as Void {
        Theme.drawPill(dc, dc.getWidth() / 2, dc.getHeight() * HINT_Y_PERCENT / 100,
                       Strings.t(Str.HomeHint), Graphics.FONT_XTINY, Theme.COLOR_ACCENT);
    }
}

class HomeDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        MenuKit.pushMainMenu();
        return true;
    }

    function onMenu() as Boolean {
        MenuKit.pushMainMenu();
        return true;
    }
}
