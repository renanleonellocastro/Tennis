import Toybox.Lang;

// One entry of the point log as the point_log field of the activity file
// carries it (docs/DATA_FORMAT.md): a header word, the entry itself and a
// score word. The field holds the newest three entries, newest first.
module PointSlot {
    const SLOTS = 3;
    const WORDS = 3;
    const SEQUENCE_MASK = 0xFFFF;
    // Header bits: who served, a second serve, a tie break.
    const SERVER_SHIFT = 16;
    const SECOND_SERVE_BIT = 0x20000;
    const TIE_BREAK_BIT = 0x40000;
    // Score bits: seven for the points of each player, four for the games,
    // two for the sets.
    const MAX_POINTS = 127;
    const POINTS_BITS = 7;
    const GAMES_SHIFT = 14;
    const GAMES_BITS = 4;
    const SETS_SHIFT = 22;
    const SETS_BITS = 2;

    // The field before the first entry: every slot empty.
    function none() as Array<Number> {
        var field = [] as Array<Number>;
        for (var i = 0; i < SLOTS * WORDS; i++) {
            field.add(0);
        }
        return field;
    }

    // The sequence number of the newest entry of a field, 0 when it has none.
    function newest(field as Array<Number>) as Number {
        return field[0] & SEQUENCE_MASK;
    }

    // Built from the state right before the entry. The sequence number is
    // the place of the entry in the log, counted from 1.
    function header(sequence as Number, state as MatchState) as Number {
        return (sequence & SEQUENCE_MASK) | (state.server() << SERVER_SHIFT)
            | (state.isSecondServe() ? SECOND_SERVE_BIT : 0) | (state.isTieBreak() ? TIE_BREAK_BIT : 0);
    }

    // Built from the state right after the entry.
    function score(state as MatchState) as Number {
        return pair(PointEntry.clamp(state.points(Player.ME), MAX_POINTS),
                    PointEntry.clamp(state.points(Player.OPPONENT), MAX_POINTS), POINTS_BITS)
            | (pair(state.games(Player.ME), state.games(Player.OPPONENT), GAMES_BITS) << GAMES_SHIFT)
            | (pair(state.sets(Player.ME), state.sets(Player.OPPONENT), SETS_BITS) << SETS_SHIFT);
    }

    function pair(mine as Number, theirs as Number, bits as Number) as Number {
        return mine | (theirs << bits);
    }

    // The field with a new entry in front; the oldest one drops out.
    function pushed(field as Array<Number>, slot as Array<Number>) as Array<Number> {
        return slot.addAll(field.slice(0, (SLOTS - 1) * WORDS));
    }
}
