import Toybox.Lang;
import Toybox.WatchUi;

// Builders and delegates for every Menu2 in the app.
module MenuKit {
    const COMING_SOON_MS = 2500;

    // Main menu rows in display order: label key, item id and the action the
    // row runs. A new entry is one more row here.
    function mainMenuRows() as Array {
        return [
            ["MenuStartMatch", :startMatch, new Lang.Method(MatchFlow, :pushSetup)],
            ["MenuPractice", :practice, new Lang.Method(PracticeFlow, :start)],
            ["MenuSettings", :settings, new Lang.Method(MenuKit, :pushComingSoon)],
            ["MenuAbout", :about, new Lang.Method(MenuKit, :pushAbout)]
        ];
    }

    function pushMainMenu() as Void {
        var menu = new WatchUi.Menu2({:title => Strings.t("AppName")});
        var rows = mainMenuRows();
        var actions = {} as Dictionary<Symbol, Method>;
        for (var i = 0; i < rows.size(); i++) {
            var row = rows[i] as Array;
            menu.addItem(new WatchUi.MenuItem(Strings.t(row[0] as String), null, row[1] as Symbol, null));
            actions.put(row[1] as Symbol, row[2] as Method);
        }
        WatchUi.pushView(menu, new MainMenuDelegate(actions), WatchUi.SLIDE_LEFT);
    }

    // The action registered for the selected item, or null for an unknown id.
    function actionFor(actions as Dictionary<Symbol, Method>, item as WatchUi.MenuItem) as Method? {
        return actions.get(item.getId() as Symbol);
    }

    // Shown by the entries whose screens arrive in later versions.
    function pushComingSoon() as Void {
        WatchUi.pushView(new MessageView(Strings.t("ComingSoonMsg"), Theme.COLOR_WARM, COMING_SOON_MS),
                         new MessageDelegate(), WatchUi.SLIDE_LEFT);
    }

    function pushAbout() as Void {
        WatchUi.pushView(new MessageView(Strings.t("AboutText"), Theme.COLOR_ACCENT, 0),
                         new MessageDelegate(), WatchUi.SLIDE_LEFT);
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    hidden var _actions as Dictionary<Symbol, Method>;

    function initialize(actions as Dictionary<Symbol, Method>) {
        Menu2InputDelegate.initialize();
        _actions = actions;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var action = MenuKit.actionFor(_actions, item);
        if (action != null) {
            action.invoke();
        }
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
