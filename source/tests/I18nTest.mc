import Toybox.Lang;
import Toybox.Test;

// Integration tests for the generated I18n table and the Strings facade.
// Strings caches the resolved table in module vars, so a test that asserts
// translated values pins the language first with Strings.loadTables.

(:test)
function testEveryLanguageHasATextForEveryKey(logger as Test.Logger) as Boolean {
    var count = I18n.table("eng").size();
    Test.assert(count > 0);
    var codes = I18n.CODES;
    for (var c = 0; c < codes.size(); c++) {
        var code = codes[c] as String;
        var table = I18n.table(code);
        Test.assertEqualMessage(table.size(), count, "key count mismatch for " + code);
        for (var key = 0; key < count; key++) {
            Test.assertMessage(table[key].length() > 0, "empty " + key + " in " + code);
        }
    }
    return true;
}

(:test)
function testSixLanguagesAreSupported(logger as Test.Logger) as Boolean {
    Test.assertEqual(I18n.CODES.size(), 6);
    return true;
}

(:test)
function testStringsLoadTablesSwitchesLanguage(logger as Test.Logger) as Boolean {
    var codes = I18n.CODES;
    for (var c = 0; c < codes.size(); c++) {
        var code = codes[c] as String;
        Strings.loadTables(code);
        Test.assertEqual(Strings.language(), code);
        Test.assertEqual(Strings.t(Str.MenuAbout), I18n.table(code)[Str.MenuAbout]);
    }
    return true;
}

(:test)
function testStringsTranslateKnownKeys(logger as Test.Logger) as Boolean {
    Strings.loadTables("eng");
    Test.assertEqual(Strings.t(Str.AppName), "Tennis");
    Strings.loadTables("por");
    Test.assertEqual(Strings.t(Str.MenuPractice), "Treino");
    return true;
}

(:test)
function testSystemDefaultIsSupportedCode(logger as Test.Logger) as Boolean {
    var systemCode = Strings.systemDefault();
    Test.assertMessage(I18n.CODES.indexOf(systemCode) >= 0, "systemDefault not in CODES: " + systemCode);
    return true;
}

(:test)
function testStringsFollowSystemWhenNothingIsLoaded(logger as Test.Logger) as Boolean {
    Strings._code = null;
    Strings._table = null;
    Test.assertEqual(Strings.language(), Strings.systemDefault());
    Test.assert(Strings.t(Str.AppName).length() > 0);
    return true;
}
