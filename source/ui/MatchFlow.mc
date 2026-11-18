import Toybox.Application;
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
            [isPaused ? Str.MatchMenuResume : Str.MatchMenuPause, :togglePause],
            [Str.MatchMenuFix, :openFixMenu],
            [Str.MatchMenuEnd, :askToEnd]
        ];
    }

    function fixMenuRows() as Array {
        return [
            [Str.FixUndoGame, :undoGame],
            [Str.FixGameMe, :gameForMe],
            [Str.FixGameOpponent, :gameForOpponent]
        ];
    }

    function finalMenuRows() as Array {
        return [
            [Str.FinalSave, :askTags],
            [Str.FinalReport, :openReport],
            [Str.FinalDiscard, :askToDiscard]
        ];
    }

    function resumeMenuRows() as Array {
        return [
            [Str.MatchMenuResume, :resume],
            [Str.FinalDiscard, :discard]
        ];
    }

    // Every menu carries the app name: a longer title wraps and is cut on
    // the small round screens.
    function menuOf(rows as Array) as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => Strings.t(Str.AppName)});
        for (var i = 0; i < rows.size(); i++) {
            var row = rows[i] as Array;
            menu.addItem(new WatchUi.MenuItem(Strings.t(row[0] as Number), null, row[1] as Symbol, null));
        }
        return menu;
    }

    // Setup.

    // One row per field with its current option, then the row that goes
    // on. The id of a field row is the field; the last row has a symbol.
    function optionMenu(options as OptionList, fields as Array<Number>, confirmKey as Number) as WatchUi.Menu2 {
        var menu = new WatchUi.Menu2({:title => Strings.t(Str.AppName)});
        for (var i = 0; i < fields.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(Strings.t(options.labelKey(fields[i])),
                                              Strings.t(options.valueKey(fields[i])), fields[i], null));
        }
        menu.addItem(new WatchUi.MenuItem(Strings.t(confirmKey), null, :confirm, null));
        return menu;
    }

    function setupMenu(setup as MatchSetup, fields as Array<Number>) as WatchUi.Menu2 {
        return optionMenu(setup, fields, Str.SetupStart);
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
        open(setup, [] as Array<Number>, [] as Array< Array<Number> >, store);
    }

    // Shows the match that the log adds up to, recording from now on.
    function open(setup as MatchSetup, entries as Array<Number>, marks as Array< Array<Number> >,
                  store as MatchStore) as Void {
        var engine = new MatchEngine(setup.config(), new PointLog(entries), marks);
        var controller = new MatchController(engine, setup, new SystemTime(),
                                             deviceRecorder(setup), store);
        active = controller;
        showMatch(controller, WatchUi.SLIDE_LEFT);
    }

    function deviceRecorder(setup as MatchSetup) as MatchRecorder {
        var usesGps = setup.usesGps() && GpsLocator.isAvailable();
        var session = new PacedSession(new FitSession(Strings.t(Str.AppName), RecordingFields.MATCH),
                                       (Application.getApp() as TennisApp).alarm);
        return new MatchRecorder(session, new WatchSensors(), usesGps ? new GpsLocator() : new NoLocator());
    }

    // A match the app closed on. Called once, when the home screen shows.

    function offerResume() as Void {
        var store = new MatchStore(new AppStorage());
        if (store.hasMatch()) {
            WatchUi.pushView(menuOf(resumeMenuRows()), new ResumeMenuDelegate(store),
                             WatchUi.SLIDE_UP);
        }
    }

    // Replaces the resume offer. The stored match goes only on a yes; a no
    // keeps it for the next launch, as leaving the offer with BACK does.
    function showResumeDiscardConfirmation(store as MatchStore) as Void {
        showQuestion(Str.DiscardQ, store.method(:clear));
    }

    // Replaces the menu on top with a question that runs the action on a yes.
    function showQuestion(key as Number, action as Method() as Void) as Void {
        WatchUi.switchToView(new WatchUi.Confirmation(Strings.t(key)),
                             new PracticeFlow.PracticeConfirmDelegate(action), WatchUi.SLIDE_IMMEDIATE);
    }

    // The score comes back from the stored log and marks; the activity is a
    // new one.
    function resume(store as MatchStore) as Void {
        var stored = store.load();
        if (stored == null) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (!MatchInput.profileOfDevice().canScore()) {
            showTouchNeeded();
        } else {
            open(new MatchSetup(stored[0] as Object?), stored[1] as Array<Number>, stored[2] as Array< Array<Number> >,
                 store);
        }
    }

    function showTouchNeeded() as Void {
        WatchUi.switchToView(new MessageView(Strings.t(Str.TouchNeededMsg), Theme.COLOR_WARM, TOUCH_NEEDED_MS),
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
        MatchAlert.play(Reaction.cueOf(reaction));
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

    // Final score: save, the report or discard.

    function pushFinalMenu(controller as MatchController) as Void {
        WatchUi.pushView(menuOf(finalMenuRows()), new FinalMenuDelegate(controller),
                         WatchUi.SLIDE_UP);
    }

    // The tags of the match, opening on the save row so a match with the
    // remembered tags is one press away. Replaces the final menu.
    function showSaveMenu(controller as MatchController) as Void {
        var tags = TagStore.load();
        var menu = optionMenu(tags, tags.fields(), Str.FinalSave);
        menu.setFocus(tags.fields().size());
        WatchUi.switchToView(menu, new SaveMenuDelegate(controller, tags), WatchUi.SLIDE_LEFT);
    }

    // Remembers the tags for the next match and saves this one with them.
    function saveWithTags(controller as MatchController, tags as MatchTags) as Void {
        TagStore.save(tags);
        controller.save(tags);
    }

    // Report.

    // [view, delegate] of the report of a match. The view asks for one
    // page at a time, so the pages never sit in memory together.
    function reportScreen(controller as MatchController) as Array {
        var settings = System.getDeviceSettings();
        var presenter = new ReportPresenter(controller.state(), controller.statistics());
        var pager = new ReportPager(presenter.pageCount(controller.isDetailed()));
        var layout = new ReportLayout(settings.screenWidth, settings.screenHeight);
        return [new ReportView(presenter, controller, layout, pager), new ReportDelegate(pager)];
    }

    // Over the final score, which shows again when the report closes.
    function pushReport(controller as MatchController) as Void {
        var screen = reportScreen(controller);
        WatchUi.pushView(screen[0] as ReportView, screen[1] as ReportDelegate, WatchUi.SLIDE_UP);
    }

    // From the final menu, which the report replaces.
    function showReport(controller as MatchController) as Void {
        var screen = reportScreen(controller);
        WatchUi.switchToView(screen[0] as ReportView, screen[1] as ReportDelegate, WatchUi.SLIDE_UP);
    }

    function showDiscardConfirmation(controller as MatchController) as Void {
        showQuestion(Str.DiscardQ, controller.method(:discard));
    }

    // Replaces the final screen, which must be the one on top, once the
    // match was saved or discarded.
    // True while a stop or a save still waits for the watch (see
    // PacedSession).
    function isSaving() as Boolean {
        return (Application.getApp() as TennisApp).alarm.isWaiting();
    }

    function showFarewellIfClosed(controller as MatchController) as Void {
        var key = controller.farewellKey();
        if (key != null) {
            active = null;
            WatchUi.switchToView(new MessageView(Strings.t(key), Theme.COLOR_ACCENT, FAREWELL_MS),
                                 new MessageDelegate(), WatchUi.SLIDE_UP);
        }
    }

    function pushMatchMenu(controller as MatchController) as Void {
        WatchUi.pushView(menuOf(matchMenuRows(controller.isPaused())),
                         new MatchMenuDelegate(controller), WatchUi.SLIDE_UP);
    }

    function showFixMenu(controller as MatchController) as Void {
        WatchUi.switchToView(menuOf(fixMenuRows()), new FixMenuDelegate(controller),
                             WatchUi.SLIDE_LEFT);
    }

    function showEndConfirmation(controller as MatchController) as Void {
        showQuestion(Str.EndMatchQ, controller.method(:end));
    }

    // Detailed mode: how the point ended.

    function endingMenu(winner as Number, server as Number) as WatchUi.Menu2 {
        var endings = EndingChoices.endings(winner, server);
        var menu = new WatchUi.Menu2({:title => Strings.t(Str.EndingTitle)});
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
