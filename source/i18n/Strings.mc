using Toybox.System;
using Toybox.Lang;

// Runtime i18n facade. Looks translations up in the generated I18n table,
// in the language of the watch.
module Strings {
    // Module scope vars cannot be `hidden` in Monkey C; treat as private.
    var _code as Lang.String? = null;       // current effective code
    var _table as Lang.Dictionary? = null;  // cached dict for _code
    var _eng as Lang.Dictionary? = null;    // eng fallback dict

    // Look a key up in the active language, falling back to eng, then to the
    // key itself so a missing translation is still debuggable on screen.
    function t(key as Lang.String) as Lang.String {
        ensureInit();
        var value = (_table as Lang.Dictionary).get(key);
        if (value == null) {
            value = (_eng as Lang.Dictionary).get(key);
        }
        return value != null ? value as Lang.String : key;
    }

    // Current effective code (never null).
    function language() as Lang.String {
        ensureInit();
        return _code as Lang.String;
    }

    // When the active language IS English, reuse the same dictionary as the
    // fallback instead of allocating a second identical table.
    function loadTables(code as Lang.String) as Void {
        _code = code;
        _table = I18n.table(code);
        _eng = code.equals("eng") ? _table : I18n.table("eng");
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
