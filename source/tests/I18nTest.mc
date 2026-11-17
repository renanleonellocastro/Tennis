import Toybox.Lang;
import Toybox.Test;

// Integration tests for the generated I18n table and the Strings facade.
// Strings caches the resolved table in module vars, so a test that asserts
// translated values pins the language first with Strings.loadTables.

(:test)
function testEveryLanguageHasEveryEngKey(logger as Test.Logger) as Boolean {
    var eng = I18n.table("eng");
    var engKeys = eng.keys();
    Test.assert(engKeys.size() > 0);
    var codes = I18n.CODES;
    for (var c = 0; c < codes.size(); c++) {
        var code = codes[c] as String;
        var table = I18n.table(code);
        Test.assertEqualMessage(table.size(), eng.size(), "key count mismatch for " + code);
        for (var k = 0; k < engKeys.size(); k++) {
            var key = engKeys[k] as String;
            var value = table.get(key);
            Test.assertMessage(value != null, "missing " + key + " in " + code);
            Test.assertMessage((value as String).length() > 0, "empty " + key + " in " + code);
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
        Test.assertEqual(Strings.t("MenuAbout"), I18n.table(code).get("MenuAbout") as String);
    }
    return true;
}

(:test)
function testStringsTranslateKnownKeys(logger as Test.Logger) as Boolean {
    Strings.loadTables("eng");
    Test.assertEqual(Strings.t("AppName"), "Tennis");
    Strings.loadTables("por");
    Test.assertEqual(Strings.t("ComingSoonMsg"), "Em breve");
    return true;
}

(:test)
function testStringsUnknownKeyReturnsKeyItself(logger as Test.Logger) as Boolean {
    Strings.loadTables("por");
    Test.assertEqual(Strings.t("NoSuchKey_123"), "NoSuchKey_123");
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
    Test.assert(Strings.t("AppName").length() > 0);
    return true;
}
