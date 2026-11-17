import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Moves between the screens of a match: setup, match, its menus and the
// final score. The functions here only build and show views; every decision
// they rely on lives in the plain classes of source/match.
module MatchFlow {
    const TOUCH_NEEDED_MS = 4000;
    const FAREWELL_MS = 1800;

    // The match that is open, so the app can keep it when it closes.
    var active as MatchController? = null;

    // Menu rows as [label key, id]. The id is the method of the menu
    // delegate that the row runs.
    function matchMenuRows(isPaused as Boolean) as Array {
        return [
            [isPaused ? "MatchMenuResume" : "MatchMenuPause", :togglePause],
            ["MatchMenuFix", :openFixMenu],
            ["MatchMenuEnd", :askToEnd]
        ];
    }

    function fixMenuRows() as Array {
        return [
            ["FixUndoGame", :undoGame],
            ["FixGameMe", :gameForMe],
            ["FixGameOpponent", :gameForOpponent]
        ];
    }

    function finalMenuRows() as Array {
        return [
            ["FinalSave", :save],
            ["FinalDiscard", :askToDiscard]
        ];
    }

    function resumeMenuRows() as Array {
        return [
            ["MatchMenuResume", :resume],
            ["FinalDiscard", :discard]
        ];
    }

    function menuOf(titleKey as String, rows as Array) as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => Strings.t(titleKey)});
        for (var i = 0; i < rows.size(); i++) {
            var row = rows[i] as Array;
            menu.addItem(new WatchUi.MenuItem(Strings.t(row[0] as String), null, row[1] as Symbol, null));
        }
        return menu;
    }

    // Setup.

    function setupMenu(setup as MatchSetup, fields as Array<Number>) as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => Strings.t("MenuStartMatch")});
        for (var i = 0; i < fields.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(Strings.t(setup.labelKey(fields[i])),
                                              Strings.t(setup.valueKey(fields[i])), fields[i], null));
        }
        menu.addItem(new WatchUi.MenuItem(Strings.t("SetupStart"), null, :start, null));
        return menu;
    }

    // Opens with the start row selected, so a match with the remembered
    // choices is one press away.
    function pushSetup() as Void {
        var setup = SetupStore.load();
        var fields = setup.fields(GpsLocator.isAvailable());
        var menu = setupMenu(setup, fields);
        menu.setFocus(fields.size());
        WatchUi.pushView(menu, new SetupMenuDelegate(setup), WatchUi.SLIDE_LEFT);
    }

    function start(setup as MatchSetup) as Void {
        SetupStore.save(setup);
        if (!MatchInput.profileOfDevice().canScore()) {
            showTouchNeeded();
            return;
        }
        var store = new MatchStore(new AppStorage());
        store.begin(setup.toArray());
        open(setup, [] as Array<Number>, store);
    }

    // Shows the match that the log adds up to, recording from now on.
    function open(setup as MatchSetup, entries as Array<Number>, store as MatchStore) as Void {
        var engine = new MatchEngine(setup.config(), new PointLog(entries));
        var controller = new MatchController(engine, setup.isDetailed(), new SystemTime(),
                                             deviceRecorder(setup), store);
        active = controller;
        showMatch(controller, WatchUi.SLIDE_LEFT);
    }

    function deviceRecorder(setup as MatchSetup) as MatchRecorder {
        var usesGps = setup.usesGps() && GpsLocator.isAvailable();
        return new MatchRecorder(new FitSession(Strings.t("AppName")), new WatchSensors(),
                                 usesGps ? new GpsLocator() : new NoLocator());
    }

    // A match the app closed on. Called once, when the home screen shows.

    function offerResume() as Void {
        var store = new MatchStore(new AppStorage());
        if (store.hasMatch()) {
            WatchUi.pushView(menuOf("ResumeTitle", resumeMenuRows()), new ResumeMenuDelegate(store),
                             WatchUi.SLIDE_UP);
        }
    }

    // The score comes back from the stored log; the activity is a new one.
    function resume(store as MatchStore) as Void {
        var stored = store.load();
        if (stored == null) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (!MatchInput.profileOfDevice().canScore()) {
            showTouchNeeded();
        } else {
            open(new MatchSetup(stored[0] as Object?), stored[1] as Array<Number>, store);
        }
    }

    function showTouchNeeded() as Void {
        WatchUi.switchToView(new MessageView(Strings.t("TouchNeededMsg"), Theme.COLOR_WARM, TOUCH_NEEDED_MS),
                             new MessageDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Match.

    function deviceLayout(profile as InputProfile) as MatchLayout {
        var settings = System.getDeviceSettings();
        return new MatchLayout(settings.screenWidth, settings.screenHeight, profile.usesTouchControls(),
                               settings.screenShape == System.SCREEN_SHAPE_ROUND);
    }

    function showMatch(controller as MatchController, slide as WatchUi.SlideType) as Void {
        var layout = deviceLayout(MatchInput.profileOfDevice());
        WatchUi.switchToView(new MatchView(controller, layout), new MatchDelegate(controller, layout), slide);
    }

    // Carries out the Reaction flags of an input on the match screen.
    function react(reaction as Number, controller as MatchController) as Void {
        if ((reaction & Reaction.VIBRATE) != 0) {
            MatchAlert.changeEnds();
        }
        if ((reaction & Reaction.ASK_ENDING) != 0) {
            pushEndingMenu(controller);
        }
        if ((reaction & Reaction.OPEN_MENU) != 0) {
            pushMatchMenu(controller);
        }
        showFinalIfOver(controller);
        WatchUi.requestUpdate();
    }

    // Replaces the match screen, which must be the one on top.
    function showFinalIfOver(controller as MatchController) as Void {
        if (controller.isOver()) {
            WatchUi.switchToView(new FinalScoreView(controller), new FinalScoreDelegate(controller),
                                 WatchUi.SLIDE_UP);
        }
    }

    // Final score: save or discard.

    function pushFinalMenu(controller as MatchController) as Void {
        WatchUi.pushView(menuOf("FinalMatchEnded", finalMenuRows()), new FinalMenuDelegate(controller),
                         WatchUi.SLIDE_UP);
    }

    function showDiscardConfirmation(controller as MatchController) as Void {
        WatchUi.switchToView(new WatchUi.Confirmation(Strings.t("DiscardQ")),
                             new DiscardConfirmDelegate(controller), WatchUi.SLIDE_IMMEDIATE);
    }

    // Replaces the final screen, which must be the one on top, once the
    // match was saved or discarded.
    function showFarewellIfClosed(controller as MatchController) as Void {
        var key = controller.farewellKey();
        if (key != null) {
            active = null;
            WatchUi.switchToView(new MessageView(Strings.t(key), Theme.COLOR_ACCENT, FAREWELL_MS),
                                 new MessageDelegate(), WatchUi.SLIDE_UP);
        }
    }

    function pushMatchMenu(controller as MatchController) as Void {
        WatchUi.pushView(menuOf("AppName", matchMenuRows(controller.isPaused())),
                         new MatchMenuDelegate(controller), WatchUi.SLIDE_UP);
    }

    function showFixMenu(controller as MatchController) as Void {
        WatchUi.switchToView(menuOf("MatchMenuFix", fixMenuRows()), new FixMenuDelegate(controller),
                             WatchUi.SLIDE_LEFT);
    }

    function showEndConfirmation(controller as MatchController) as Void {
        WatchUi.switchToView(new WatchUi.Confirmation(Strings.t("EndMatchQ")),
                             new EndMatchConfirmDelegate(controller), WatchUi.SLIDE_IMMEDIATE);
    }

    // Detailed mode: how the point ended.

    function endingMenu(winner as Number, server as Number) as WatchUi.Menu2 {
        var endings = EndingChoices.endings(winner, server);
        var menu = new WatchUi.Menu2({:title => Strings.t("EndingTitle")});
        for (var i = 0; i < endings.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(Strings.t(EndingChoices.labelKey(endings[i])),
                                              Strings.t(EndingChoices.authorKey(endings[i], winner)),
                                              endings[i], null));
        }
        menu.setFocus(EndingChoices.preselected(endings));
        return menu;
    }

    function pushEndingMenu(controller as MatchController) as Void {
        WatchUi.pushView(endingMenu(controller.pendingWinner(), controller.state().server()),
                         new EndingMenuDelegate(controller), WatchUi.SLIDE_IMMEDIATE);
    }
}
