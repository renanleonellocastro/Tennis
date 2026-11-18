import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

module PracticeFlow {
    // The summary of a practice: the total, one row per block and the time.
    class PracticeSummaryView extends WatchUi.View {
        // Rows of the screen, as percentages of its height.
        const TOTAL_Y = 25;
        const FIRST_ROW_Y = 40;
        const ROW_STEP = 10;
        const FOOTER_Y = 84;
        hidden const CENTERED = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        hidden var _controller as PracticeController;
        hidden var _pager as SummaryPager;

        function initialize(controller as PracticeController, pager as SummaryPager) {
            View.initialize();
            _controller = controller;
            _pager = pager;
        }

        // The save menu and the discard question close over this screen, so it
        // looks at the result each time it comes back.
        function onShow() as Void {
            PracticeFlow.showFarewellIfClosed(_controller);
        }

        function onUpdate(dc as Dc) as Void {
            var log = _controller.log();
            dc.setColor(Theme.COLOR_TEXT, Theme.COLOR_BG);
            dc.clear();
            Theme.drawBrandArc(dc, Theme.COLOR_ACCENT);
            var isRound = System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_ROUND;
            drawLine(dc, PracticePresenter.summaryTitleY(isRound), Graphics.FONT_XTINY, Theme.COLOR_TEXT_DIM,
                     Strings.t("PracticeTotal"));
            drawLine(dc, TOTAL_Y, Graphics.FONT_SMALL, Theme.COLOR_ACCENT, PracticePresenter.totalText(log));
            drawRows(dc, PracticePresenter.summaryRows(log, _pager.firstRow(), _pager.pageSize()));
            drawLine(dc, FOOTER_Y, Graphics.FONT_XTINY, Theme.COLOR_TEXT_DIM,
                     PracticePresenter.summaryFooter(_controller.clockSeconds(), _pager.page(), _pager.pages()));
        }

        hidden function drawRows(dc as Dc, rows as Array<String>) as Void {
            for (var i = 0; i < rows.size(); i++) {
                drawLine(dc, FIRST_ROW_Y + i * ROW_STEP, Graphics.FONT_XTINY, Theme.COLOR_TEXT, rows[i]);
            }
        }

        hidden function drawLine(dc as Dc, percentY as Number, font as Graphics.FontDefinition,
                                 color as Number, text as String) as Void {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(dc.getWidth() / 2, dc.getHeight() * percentY / 100, font, text, CENTERED);
        }
    }

    // START or a tap asks to save or discard the activity. UP and DOWN, or a
    // swipe, turn the pages. BACK returns to the practice, so one ended by
    // mistake goes on.
    class PracticeSummaryDelegate extends WatchUi.BehaviorDelegate {
        hidden var _controller as PracticeController;
        hidden var _pager as SummaryPager;

        function initialize(controller as PracticeController, pager as SummaryPager) {
            BehaviorDelegate.initialize();
            _controller = controller;
            _pager = pager;
        }

        function onSelect() as Boolean {
            PracticeFlow.pushSaveMenu(_controller);
            return true;
        }

        function onNextPage() as Boolean {
            if (_pager.next()) {
                WatchUi.requestUpdate();
            }
            return true;
        }

        function onPreviousPage() as Boolean {
            if (_pager.previous()) {
                WatchUi.requestUpdate();
            }
            return true;
        }

        function onBack() as Boolean {
            _controller.reopen();
            PracticeFlow.showPractice(_controller);
            return true;
        }
    }
}
