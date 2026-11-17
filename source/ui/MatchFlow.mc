import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Moves between the screens of a match: setup, match, its menus and the
// final score. The functions here only build and show views; every decision
// they rely on lives in the plain classes of source/match.
module MatchFlow {
    const TOUCH_NEEDED_MS = 4000;

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

    function menuOf(titleKey as String, rows as Array) as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => Strings.t(titleKey)});
        for (var i = 0; i < rows.size(); i++) {
            var row = rows[i] as Array;
            menu.addItem(new WatchUi.MenuItem(Strings.t(row[0] as String), null, row[1] as Symbol, null));
        }
        return menu;
    }

    // Setup.

    function setupMenu(setup as MatchSetup) as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => Strings.t("MenuStartMatch")});
        for (var field = 0; field < MatchSetup.FIELD_COUNT; field++) {
            menu.addItem(new WatchUi.MenuItem(Strings.t(setup.labelKey(field)),
                                              Strings.t(setup.valueKey(field)), field, null));
        }
        menu.addItem(new WatchUi.MenuItem(Strings.t("SetupStart"), null, :start, null));
        return menu;
    }

    // Opens with the start row selected, so a match with the remembered
    // choices is one press away.
    function pushSetup() as Void {
        var setup = SetupStore.load();
        var menu = setupMenu(setup);
        menu.setFocus(MatchSetup.FIELD_COUNT);
        WatchUi.pushView(menu, new SetupMenuDelegate(setup), WatchUi.SLIDE_LEFT);
    }

    function start(setup as MatchSetup) as Void {
        SetupStore.save(setup);
        if (!MatchInput.profileOfDevice().canScore()) {
            showTouchNeeded();
            return;
        }
        var engine = new MatchEngine(setup.config(), new PointLog([] as Array<Number>));
        showMatch(new MatchController(engine, setup.isDetailed(), new SystemTime()), WatchUi.SLIDE_LEFT);
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
