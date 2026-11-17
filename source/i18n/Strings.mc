using Toybox.System;
using Toybox.Lang;

// Runtime i18n facade. Looks translations up in the generated I18n table,
// in the language of the watch.
module Strings {
    // Module scope vars cannot be `hidden` in Monkey C; treat as private.
    var _code as Lang.String? = null;       // current effective code
    var _table as Lang.Dictionary? = null;  // cached dict for _code

    // Look a key up in the active language, falling back to the key itself
    // so a missing text is still debuggable on screen. The generator gives
    // every language every key (the English text where a translation is
    // missing), so one table in memory is enough.
    function t(key as Lang.String) as Lang.String {
        ensureInit();
        var value = (_table as Lang.Dictionary).get(key);
        return value != null ? value as Lang.String : key;
    }

    // Current effective code (never null).
    function language() as Lang.String {
        ensureInit();
        return _code as Lang.String;
    }

    // The old table is let go first so the two are never in memory together.
    function loadTables(code as Lang.String) as Void {
        _code = code;
        _table = null;
        _table = I18n.table(code);
    }

    // Map the device system locale to one of the supported codes.
    function systemDefault() as Lang.String {
        var lang = System.getDeviceSettings().systemLanguage;
        if (lang == System.LANGUAGE_POR) { return "por"; }
        if (lang == System.LANGUAGE_SPA) { return "spa"; }
        if (lang == System.LANGUAGE_FRE) { return "fre"; }
        if (lang == System.LANGUAGE_DEU) { return "deu"; }
        if (lang == System.LANGUAGE_ITA) { return "ita"; }
        return "eng";
    }

    // Lazy one time resolution of the active language from the system locale.
    function ensureInit() as Void {
        if (_table == null) {
            loadTables(systemDefault());
        }
    }
}
