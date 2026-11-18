import Toybox.Lang;
import Toybox.WatchUi;

// Moves between the screens of a practice: the counters, the menu and the
// summary. The functions here only build and show views; every decision
// they rely on lives in the plain classes of this folder.
module PracticeFlow {
    const SUMMARY_ROWS = 4;

    // The practice that is open, so the app can save it when it closes.
    var active as PracticeController? = null;

    // Menu rows as [label key, id]. The id is the method of the menu
    // delegate that the row runs.
    function practiceMenuRows(isPaused as Boolean) as Array {
        return [
            [isPaused ? "MatchMenuResume" : "MatchMenuPause", :togglePause],
            ["PracticeMenuEnd", :askToEnd]
        ];
    }

    function saveMenuRows() as Array {
        return [
            ["FinalSave", :save],
            ["FinalDiscard", :askToDiscard]
        ];
    }

    // Practice needs no setup: it starts recording as it opens. It has no
    // GPS track, because drills stay on one spot of the court.
    function start() as Void {
        if (!MatchInput.profileOfDevice().canScore()) {
            pushTouchNeeded();
            return;
        }
        var controller = new PracticeController(new SystemTime(), deviceRecorder());
        var layout = MatchFlow.deviceLayout(MatchInput.profileOfDevice());
        active = controller;
        WatchUi.pushView(new PracticeView(controller, layout), new PracticeDelegate(controller, layout),
                         WatchUi.SLIDE_LEFT);
    }

    function deviceRecorder() as PracticeRecorder {
        return new PracticeRecorder(new FitSession(Strings.t("AppName"), RecordingFields.PRACTICE),
                                    new WatchSensors(), new NoLocator());
    }

    function pushTouchNeeded() as Void {
        WatchUi.pushView(new MessageView(Strings.t("TouchNeededMsg"), Theme.COLOR_WARM, MatchFlow.TOUCH_NEEDED_MS),
                         new MessageDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Replaces the summary, which must be the one on top.
    function showPractice(controller as PracticeController) as Void {
        var layout = MatchFlow.deviceLayout(MatchInput.profileOfDevice());
        WatchUi.switchToView(new PracticeView(controller, layout), new PracticeDelegate(controller, layout),
                             WatchUi.SLIDE_DOWN);
    }

    // Carries out the Reaction flags of an input on the practice screen.
    function react(reaction as Number, controller as PracticeController) as Void {
        if ((reaction & Reaction.VIBRATE) != 0) {
            MatchAlert.changeEnds();
        }
        if ((reaction & Reaction.OPEN_MENU) != 0) {
            pushPracticeMenu(controller);
        }
        WatchUi.requestUpdate();
    }

    function pushPracticeMenu(controller as PracticeController) as Void {
        WatchUi.pushView(MatchFlow.menuOf(practiceMenuRows(controller.isPaused())),
                         new PracticeMenuDelegate(controller), WatchUi.SLIDE_UP);
    }

    function showEndConfirmation(controller as PracticeController) as Void {
        WatchUi.switchToView(new WatchUi.Confirmation(Strings.t("EndPracticeQ")),
                             new PracticeConfirmDelegate(controller.method(:end)), WatchUi.SLIDE_IMMEDIATE);
    }

    // Replaces the practice screen, which must be the one on top.
    function showSummaryIfOver(controller as PracticeController) as Void {
        if (controller.isOver()) {
            var pager = new SummaryPager(controller.log().blocks(), SUMMARY_ROWS);
            WatchUi.switchToView(new PracticeSummaryView(controller, pager),
                                 new PracticeSummaryDelegate(controller, pager), WatchUi.SLIDE_UP);
        }
    }

    // Summary: save or discard.

    function pushSaveMenu(controller as PracticeController) as Void {
        WatchUi.pushView(MatchFlow.menuOf(saveMenuRows()), new PracticeSaveMenuDelegate(controller),
                         WatchUi.SLIDE_UP);
    }

    function showDiscardConfirmation(controller as PracticeController) as Void {
        WatchUi.switchToView(new WatchUi.Confirmation(Strings.t("DiscardQ")),
                             new PracticeConfirmDelegate(controller.method(:discard)), WatchUi.SLIDE_IMMEDIATE);
    }

    // Replaces the summary, which must be the one on top, once the practice
    // was saved or discarded.
    function showFarewellIfClosed(controller as PracticeController) as Void {
        var key = controller.farewellKey();
        if (key != null) {
            active = null;
            WatchUi.switchToView(new MessageView(Strings.t(key), Theme.COLOR_ACCENT, MatchFlow.FAREWELL_MS),
                                 new MessageDelegate(), WatchUi.SLIDE_UP);
        }
    }
}
