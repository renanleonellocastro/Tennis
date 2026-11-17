import Toybox.Lang;

// The match as the summary fields of the activity file hold it (see
// docs/DATA_FORMAT.md): the setup word, the score text and the set scores.
module MatchSummary {
    const FORMAT_VERSION = 1;
    // Where the setup word keeps the first fields of MatchSetup (format, no
    // advantage, detail, first server) and the fields of MatchTags.
    const SETUP_SHIFTS = [4, 7, 8, 9];
    const TAG_SHIFTS = [10, 12];
    const SET_GAP = " ";
    // The score text field has room for this many characters.
    const SCORE_TEXT_MAX = 31;

    function setupWord(setup as Array<Number>, tags as Array<Number>) as Number {
        return FORMAT_VERSION | packed(setup, SETUP_SHIFTS) | packed(tags, TAG_SHIFTS);
    }

    function packed(values as Array<Number>, shifts as Array<Number>) as Number {
        var word = 0;
        for (var i = 0; i < shifts.size(); i++) {
            word |= values[i] << shifts[i];
        }
        return word;
    }

    // [games me, games opponent, tie break points me, tie break points
    // opponent] of a finished set; the points are zero without a tie break.
    function setScore(state as MatchState, set as Number) as Array<Number> {
        return [state.setGames(set, Player.ME), state.setGames(set, Player.OPPONENT),
                state.setTieBreakPoints(set, Player.ME), state.setTieBreakPoints(set, Player.OPPONENT)];
    }

    // The set that closed last, or zeros before the first one closes.
    function closedSetScore(state as MatchState) as Array<Number> {
        var sets = state.finishedSets();
        return sets == 0 ? [0, 0, 0, 0] : setScore(state, sets - 1);
    }

    // The set of the lap that is open when the activity is saved: the last
    // set of a decided match, or the part played of a set that was stopped.
    function openSetScore(state as MatchState) as Array<Number> {
        if (state.isFinished()) {
            return closedSetScore(state);
        }
        var isTieBreak = state.isTieBreak();
        return [state.games(Player.ME), state.games(Player.OPPONENT),
                isTieBreak ? state.displayPoints(Player.ME) : 0,
                isTieBreak ? state.displayPoints(Player.OPPONENT) : 0];
    }

    // "7-6(7-5)" for a set a tie break decided, "6-3" for any other.
    function setText(score as Array<Number>) as String {
        var games = MatchPresenter.pair(score[0], score[1]);
        if (score[2] + score[3] == 0) {
            return games;
        }
        return games + "(" + MatchPresenter.pair(score[2], score[3]) + ")";
    }

    // True while a set is being played. A match that stops right after a
    // set has no open set: its next set has neither a game nor a point.
    function hasOpenSet(state as MatchState) as Boolean {
        var played = state.games(Player.ME) + state.games(Player.OPPONENT)
            + state.points(Player.ME) + state.points(Player.OPPONENT);
        return !state.isFinished() && (played > 0 || state.finishedSets() == 0);
    }

    // The closed sets as on a scoreboard, then the games of a set that was
    // still open: "7-6(7-5) 6-3".
    function scoreText(state as MatchState) as String {
        var text = "";
        for (var set = 0; set < state.finishedSets(); set++) {
            text += (set == 0 ? "" : SET_GAP) + setText(setScore(state, set));
        }
        if (hasOpenSet(state)) {
            text += (text.length() == 0 ? "" : SET_GAP) + MatchPresenter.pair(state.games(Player.ME), state.games(Player.OPPONENT));
        }
        return text.substring(0, SCORE_TEXT_MAX) as String;
    }

    // [setup word, score text, statistics, score of the open set, size of
    // the point log], as MatchRecorder.writeSummary takes them.
    function fields(setup as Array<Number>, tags as Array<Number>, engine as MatchEngine) as Array {
        var state = engine.state();
        return [setupWord(setup, tags), scoreText(state), engine.statistics().toArray(), openSetScore(state),
                engine.log().size()];
    }
}
