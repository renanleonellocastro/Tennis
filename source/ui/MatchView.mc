import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// The match screen. It only draws: the texts come from MatchPresenter, the
// positions from MatchLayout and the state from MatchController.
class MatchView extends WatchUi.View {
    hidden const CLOCK_TICK_MS = 1000;
    hidden const WIDEST_SCORE = "40";
    hidden const SECOND_SERVE_MARK = "2";
    // What UP, START, DOWN and BACK do, in the order of KeySlot. The words
    // of UP and DOWN are also the labels of the two players.
    hidden const KEY_TEXTS = [Str.LabelMe, Str.ControlFault, Str.LabelOpponent, Str.KeyUndo];
    hidden const CENTERED = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    hidden var _controller as MatchController;
    hidden var _layout as MatchLayout;
    hidden var _pointsFont as Graphics.FontDefinition = Graphics.FONT_NUMBER_MILD;
    hidden var _labelFont as Graphics.FontDefinition = Graphics.FONT_XTINY;
    hidden var _timer as Timer.Timer?;

    function initialize(controller as MatchController, layout as MatchLayout) {
        View.initialize();
        _controller = controller;
        _layout = layout;
    }

    function onLayout(dc as Dc) as Void {
        _pointsFont = MatchDraw.numberFont(dc, _layout, WIDEST_SCORE);
        _labelFont = MatchDraw.labelFont(dc, _layout, labelOf(Player.ME), labelOf(Player.OPPONENT));
    }

    // Menus and dialogs change the match while this screen is hidden, so it
    // looks at the result each time it comes back.
    function onShow() as Void {
        MatchDraw.prepare(_layout, KEY_TEXTS);
        _timer = new Timer.Timer();
        (_timer as Timer.Timer).start(method(:onTick), CLOCK_TICK_MS, true);
        MatchFlow.showFinalIfOver(_controller);
    }

    function onHide() as Void {
        MatchDraw.release();
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        _controller.tick();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var state = _controller.state();
        dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
        dc.clear();
        drawSets(dc, state);
        drawBanner(dc, state);
        drawCourt(dc, state);
        for (var player = 0; player < Player.COUNT; player++) {
            drawPlayer(dc, state, player);
        }
        drawFooter(dc);
    }

    hidden function labelOf(player as Number) as String {
        return Strings.t(KEY_TEXTS[player * KeySlot.PER_ROW] as Number);
    }

    // The set score, in the largest font that holds it.
    hidden function drawSets(dc as Dc, state as MatchState) as Void {
        var text = MatchPresenter.setsText(state);
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_layout.centerX(), _layout.setsY(),
                    MatchDraw.textFont(dc, text, 0, _layout.roomOf(_layout.SETS_ROOM)), text, CENTERED);
    }

    hidden function drawBanner(dc as Dc, state as MatchState) as Void {
        var banner = MatchPresenter.banner(_controller.isPaused(), _controller.noticeKey(), state);
        var text = banner[0] as String;
        dc.setColor(MatchDraw.TONE_COLORS[banner[1] as Number] as Number, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_layout.centerX(), _layout.bannerY(),
                    MatchDraw.textFont(dc, text, 1, _layout.roomOf(_layout.BANNER_ROOM)), text, CENTERED);
    }

    // Points, label, serve ball and court marker of one player.
    hidden function drawPlayer(dc as Dc, state as MatchState, player as Number) as Void {
        drawPoints(dc, state, player);
        drawLabel(dc, player);
        drawMarker(dc, state, player);
        if (state.server() == player) {
            drawBall(dc, state, player);
        }
    }

    hidden function drawPoints(dc as Dc, state as MatchState, player as Number) as Void {
        var font = MatchPresenter.isPointsNumeric(state, player) ? _pointsFont : Graphics.FONT_LARGE;
        var tone = MatchPresenter.pointsTone(_controller.isPaused(), state, player);
        dc.setColor(MatchDraw.POINTS_COLORS[tone] as Number, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_layout.playerX(player), _layout.pointsY(), font,
                    MatchPresenter.pointsText(state, player), CENTERED);
    }

    hidden function drawLabel(dc as Dc, player as Number) as Void {
        var justify = player == Player.ME ? Graphics.TEXT_JUSTIFY_LEFT : Graphics.TEXT_JUSTIFY_RIGHT;
        dc.setColor(MatchDraw.TONE_COLORS[player] as Number, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_layout.labelX(player), _layout.labelsY(), _labelFont, labelOf(player),
                    justify | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // The ball sits next to the server and carries a 2 on a second serve.
    hidden function drawBall(dc as Dc, state as MatchState, player as Number) as Void {
        dc.setColor(Theme.COLOR_BALL, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(_layout.ballX(player), _layout.labelsY(), _layout.ballRadius());
        if (state.isSecondServe()) {
            dc.setColor(Theme.COLOR_BG, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_layout.ballX(player), _layout.labelsY(), Graphics.FONT_XTINY, SECOND_SERVE_MARK, CENTERED);
        }
    }

    // Mini court: outline, net and the quarter the server stands behind.
    hidden function drawCourt(dc as Dc, state as MatchState) as Void {
        var court = _layout.courtRect();
        var quarter = _layout.serveQuarter(state.endOf(state.server()), state.serveSide());
        var netY = court[1] + court[3] / 2;
        dc.setColor(Theme.COLOR_BALL, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(quarter[0], quarter[1], quarter[2], quarter[3]);
        dc.setColor(Theme.COLOR_FRAME, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(court[0], court[1], court[2], court[3]);
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        var post = _layout.markerRadius() / 2;
        dc.drawLine(court[0] - post, netY, court[0] + court[2] + post, netY);
    }

    // Both players stand on the side the point is served from.
    hidden function drawMarker(dc as Dc, state as MatchState, player as Number) as Void {
        var end = state.endOf(player);
        var point = _layout.markerPoint(end, _layout.isOnRight(end, state.serveSide()));
        dc.setColor(MatchDraw.TONE_COLORS[player] as Number, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(point[0], point[1], _layout.markerRadius());
    }

    hidden function drawFooter(dc as Dc) as Void {
        MatchDraw.draw(dc, _layout, [_controller.clockSeconds(), _controller.heartRate(), _controller.isPaused()],
                         KEY_TEXTS);
    }
}

// Inputs of the match screen. Keys and taps become match actions; the
// behaviors that the same inputs also raise are swallowed so nothing runs
// twice and no stray gesture leaves the match.
class MatchDelegate extends WatchUi.BehaviorDelegate {
    hidden var _controller as MatchController;
    hidden var _layout as MatchLayout;

    function initialize(controller as MatchController, layout as MatchLayout) {
        BehaviorDelegate.initialize();
        _controller = controller;
        _layout = layout;
    }

    hidden function run(action as Number) as Boolean {
        MatchFlow.react(_controller.handle(action), _controller);
        return true;
    }

    function onKey(event as WatchUi.KeyEvent) as Boolean {
        var action = MatchInput.actionForKey(event.getKey());
        return action == MatchAction.NONE ? false : run(action);
    }

    function onTap(event as WatchUi.ClickEvent) as Boolean {
        var at = event.getCoordinates();
        return run(MatchInput.actionForTap(at[0], at[1], _layout));
    }

    function onMenu() as Boolean {
        return run(MatchAction.MENU);
    }

    // A back gesture on a watch without a back key.
    function onBack() as Boolean {
        return run(MatchAction.UNDO);
    }

    function onSelect() as Boolean {
        return true;
    }

    function onNextPage() as Boolean {
        return true;
    }

    function onPreviousPage() as Boolean {
        return true;
    }
}
