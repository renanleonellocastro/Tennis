import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

module PracticeFlow {
    // The practice screen: the block, its success rate, the hits and misses in
    // large digits, the clock and the heart rate. It only draws: the texts come
    // from PracticePresenter and the state from PracticeController. The
    // positions are those of the match screen, with the hits where my points
    // are and the misses where the opponent's are.
    class PracticeView extends WatchUi.View {
        hidden const CLOCK_TICK_MS = 1000;
        hidden const HIT_SIDE = Player.ME;
        hidden const MISS_SIDE = Player.OPPONENT;
        // The widest count of two and of three digits, indexed by
        // PracticePresenter.digitSlot.
        hidden const WIDEST_COUNTS = ["88", "888"];
        hidden const LABEL_KEYS = [Str.PracticeHit, Str.PracticeMiss];
        hidden const CENTERED = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        hidden var _controller as PracticeController;
        hidden var _layout as MatchLayout;
        hidden var _countFonts as Array<Graphics.FontDefinition> =
            [Graphics.FONT_NUMBER_MILD, Graphics.FONT_NUMBER_MILD] as Array<Graphics.FontDefinition>;
        hidden var _timer as Timer.Timer?;

        function initialize(controller as PracticeController, layout as MatchLayout) {
            View.initialize();
            _controller = controller;
            _layout = layout;
        }

        function onLayout(dc as Dc) as Void {
            for (var slot = 0; slot < WIDEST_COUNTS.size(); slot++) {
                _countFonts[slot] = MatchDraw.numberFont(dc, _layout, WIDEST_COUNTS[slot] as String);
            }
        }

        // The menu and its question change the practice while this screen is
        // hidden, so it looks at the result each time it comes back.
        function onShow() as Void {
            _timer = new Timer.Timer();
            (_timer as Timer.Timer).start(method(:onTick), CLOCK_TICK_MS, true);
            PracticeFlow.showSummaryIfOver(_controller);
        }

        function onHide() as Void {
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
            var log = _controller.log();
            var font = _countFonts[PracticePresenter.digitSlot(log.hits(), log.misses())];
            dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
            dc.clear();
            drawHeader(dc, log);
            drawDivider(dc);
            drawSide(dc, HIT_SIDE, log.hits(), font);
            drawSide(dc, MISS_SIDE, log.misses(), font);
            drawFooter(dc);
        }

        // The block and, under it, the pause or the success rate of the block.
        hidden function drawHeader(dc as Dc, log as PracticeLog) as Void {
            var isPaused = _controller.isPaused();
            dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_layout.centerX(), _layout.setsY(), Graphics.FONT_XTINY,
                        PracticePresenter.blockTitle(log.blockNumber()), CENTERED);
            dc.setColor(isPaused ? Theme.COLOR_WARM : Theme.COLOR_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_layout.centerX(), _layout.bannerY(), Graphics.FONT_XTINY,
                        PracticePresenter.bannerText(isPaused, log.hits(), log.misses()), CENTERED);
        }

        // A quiet line between the two counts, where the match has its court.
        hidden function drawDivider(dc as Dc) as Void {
            var court = _layout.courtRect();
            dc.setColor(Theme.COLOR_FRAME, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(_layout.centerX(), court[1], _layout.centerX(), court[1] + court[3]);
        }

        // The count of one side and its label.
        hidden function drawSide(dc as Dc, side as Number, count as Number,
                                 font as Graphics.FontDefinition) as Void {
            dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_layout.playerX(side), _layout.pointsY(), font, count.toString(), CENTERED);
            dc.setColor(MatchDraw.SIDE_COLORS[side] as Number, Graphics.COLOR_TRANSPARENT);
            dc.drawText(_layout.playerX(side), _layout.labelsY(), Graphics.FONT_XTINY,
                        Strings.t(LABEL_KEYS[side] as Number), CENTERED);
        }

        hidden function drawFooter(dc as Dc) as Void {
            MatchDraw.draw(dc, _layout,
                             [_controller.clockSeconds(), _controller.heartRate(), _controller.isPaused()],
                             Str.PracticeNext);
        }
    }

    // Inputs of the practice screen. Keys and taps become practice actions; the
    // behaviors that the same inputs also raise are swallowed so nothing runs
    // twice and no stray gesture leaves the practice.
    class PracticeDelegate extends WatchUi.BehaviorDelegate {
        hidden var _controller as PracticeController;
        hidden var _layout as MatchLayout;

        function initialize(controller as PracticeController, layout as MatchLayout) {
            BehaviorDelegate.initialize();
            _controller = controller;
            _layout = layout;
        }

        hidden function run(action as Number) as Boolean {
            PracticeFlow.react(_controller.handle(action), _controller);
            return true;
        }

        function onKey(event as WatchUi.KeyEvent) as Boolean {
            var action = MatchInput.actionForKey(event.getKey());
            return action == PracticeAction.NONE ? false : run(action);
        }

        function onTap(event as WatchUi.ClickEvent) as Boolean {
            var at = event.getCoordinates();
            return run(MatchInput.actionForTap(at[0], at[1], _layout));
        }

        function onMenu() as Boolean {
            return run(PracticeAction.MENU);
        }

        // A back gesture on a watch without a back key.
        function onBack() as Boolean {
            return run(PracticeAction.UNDO);
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
}
