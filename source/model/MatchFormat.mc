import Toybox.Lang;

// The match presets. Each one is a word of rules, so a new preset is one more
// word and no new code.
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

    // One word per preset, a byte per column: sets to win, games per set,
    // tie break points, match tie break points. A table of rows would take
    // about 200 bytes more of the little memory of the smallest watches.
    function rules(format as Number) as Array<Number> {
        var word = ([0x02060700, 0x0206070A, 0x01060700, 0x01080700, 0x01000700] as Array<Number>)[format];
        return [word >> 24, (word >> 16) & 0xFF, (word >> 8) & 0xFF, word & 0xFF] as Array<Number>;
    }
}
