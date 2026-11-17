import Toybox.Lang;

// The choices made before the first point: preset, scoring of deuce and who
// serves first. Together with the point log it fully describes a match.
class MatchConfig {
    hidden const ADVANTAGE_MARGIN = 2;
    hidden const DECIDING_POINT_MARGIN = 1;

    hidden var _rules as Array<Number>;
    hidden var _isNoAdvantage as Boolean;
    hidden var _firstServer as Number;

    function initialize(format as Number, isNoAdvantage as Boolean, firstServer as Number) {
        _rules = MatchFormat.rules(format);
        _isNoAdvantage = isNoAdvantage;
        _firstServer = firstServer;
    }

    function setsToWin() as Number {
        return _rules[MatchFormat.SETS_TO_WIN];
    }

    function gamesPerSet() as Number {
        return _rules[MatchFormat.GAMES_PER_SET];
    }

    function tieBreakPoints() as Number {
        return _rules[MatchFormat.TIE_BREAK_POINTS];
    }

    function matchTieBreakPoints() as Number {
        return _rules[MatchFormat.MATCH_TIE_BREAK_POINTS];
    }

    // Lead needed to win a regular game: one with the deciding point at 40
    // all, two with advantage scoring.
    function gameWinMargin() as Number {
        return _isNoAdvantage ? DECIDING_POINT_MARGIN : ADVANTAGE_MARGIN;
    }

    // The serve rotation: the player who serves on a given service turn. A
    // turn is one game, or one point pair inside a tie break.
    function serverAt(serviceTurn as Number) as Number {
        return (_firstServer + serviceTurn) % Player.COUNT;
    }
}
