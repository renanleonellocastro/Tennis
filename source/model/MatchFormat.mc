import Toybox.Lang;

// The match presets. Each one is a row of rules, so a new preset is one more
// row and no new code.
module MatchFormat {
    const BEST_OF_3 = 0;
    const BEST_OF_3_MATCH_TIE_BREAK = 1;
    const ONE_SET = 2;
    const PRO_SET = 3;
    const TIE_BREAK_ONLY = 4;

    // Columns of a rules row.
    const SETS_TO_WIN = 0;
    // A set reaches its tie break at this many games all, so zero means the
    // set is nothing but a tie break.
    const GAMES_PER_SET = 1;
    const TIE_BREAK_POINTS = 2;
    // Zero means the deciding set is played out as a full set.
    const MATCH_TIE_BREAK_POINTS = 3;

    function rules(format as Number) as Array<Number> {
        var table = [
            [2, 6, 7, 0],
            [2, 6, 7, 10],
            [1, 6, 7, 0],
            [1, 8, 7, 0],
            [1, 0, 7, 0]
        ] as Array< Array<Number> >;
        return table[format];
    }
}
