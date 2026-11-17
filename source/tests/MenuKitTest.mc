import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

// Tests for the main menu table and its lookup (pushing the Menu2 itself
// needs a live view stack and is exercised on the simulator by hand).

(:test)
function testMainMenuRowsHaveUniqueIdsAndActions(logger as Test.Logger) as Boolean {
    var rows = MenuKit.mainMenuRows();
    Test.assertEqual(rows.size(), 4);
    var seen = {} as Dictionary<Symbol, Boolean>;
    for (var i = 0; i < rows.size(); i++) {
        var row = rows[i] as Array;
        Test.assert((row[2] as Object) instanceof Lang.Method);
        Test.assert(!seen.hasKey(row[1] as Symbol));
        seen.put(row[1] as Symbol, true);
    }
    return true;
}

(:test)
function testMainMenuOrderIsMatchPracticeSettingsAbout(logger as Test.Logger) as Boolean {
    var rows = MenuKit.mainMenuRows();
    var expected = [:startMatch, :practice, :settings, :about];
    for (var i = 0; i < expected.size(); i++) {
        Test.assert(((rows[i] as Array)[1] as Symbol) == expected[i]);
    }
    return true;
}

(:test)
function testMainMenuLabelsExistInEveryLanguage(logger as Test.Logger) as Boolean {
    var rows = MenuKit.mainMenuRows();
    var codes = I18n.CODES;
    for (var c = 0; c < codes.size(); c++) {
        var table = I18n.table(codes[c] as String);
        for (var i = 0; i < rows.size(); i++) {
            var key = (rows[i] as Array)[0] as String;
            Test.assertMessage(table.hasKey(key), "no label " + key + " in " + (codes[c] as String));
        }
    }
    return true;
}

(:test)
function testActionForFindsTheRegisteredMethodOnly(logger as Test.Logger) as Boolean {
    var action = new Lang.Method(MenuKit, :pushAbout);
    var actions = {:about => action} as Dictionary<Symbol, Method>;
    Test.assert(MenuKit.actionFor(actions, new WatchUi.MenuItem("About", null, :about, null)) == action);
    Test.assert(MenuKit.actionFor(actions, new WatchUi.MenuItem("Other", null, :other, null)) == null);
    return true;
}
