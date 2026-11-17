import Toybox.Lang;

// The choices of the setup screen: preset, deuce scoring, detail level, who
// serves first and the GPS.
class MatchSetup extends OptionList {
    static const FORMAT = 0;
    static const NO_ADVANTAGE = 1;
    static const DETAIL = 2;
    static const FIRST_SERVER = 3;
    static const GPS = 4;
    static const FIELD_COUNT = 5;

    // Rows follow the field ids; the options of each row follow the values
    // the engine uses (MatchFormat, off then on, simple then detailed, Player,
    // off then on).
    function initialize(stored as Object?) {
        OptionList.initialize(
            ["SetupFormat", "SetupNoAd", "SetupDetail", "SetupFirstServe", "SetupGps"] as Array<String>,
            [
                ["FormatBestOf3", "FormatMatchTieBreak", "FormatOneSet", "FormatProSet", "FormatTieBreakOnly"],
                ["ValueOff", "ValueOn"],
                ["DetailSimple", "DetailDetailed"],
                ["PlayerMe", "PlayerOpponent"],
                ["ValueOff", "ValueOn"]
            ] as Array< Array<String> >,
            stored);
    }

    // The rows of the setup screen. A watch without GPS has no GPS row.
    function fields(hasGps as Boolean) as Array<Number> {
        var all = [FORMAT, NO_ADVANTAGE, DETAIL, FIRST_SERVER, GPS] as Array<Number>;
        return hasGps ? all : all.slice(0, GPS);
    }

    function usesGps() as Boolean {
        return _values[GPS] == 1;
    }

    function isDetailed() as Boolean {
        return _values[DETAIL] == 1;
    }

    function config() as MatchConfig {
        return new MatchConfig(_values[FORMAT], _values[NO_ADVANTAGE] == 1, _values[FIRST_SERVER]);
    }
}
