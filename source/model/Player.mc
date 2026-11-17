import Toybox.Lang;

// The two competitors of a singles match. Every score, flag and statistic is
// indexed by these ids, and the serve rotation is an ordered turn over them.
module Player {
    const NONE = -1;
    const ME = 0;
    const OPPONENT = 1;
    const COUNT = 2;

    function opponentOf(player as Number) as Number {
        return OPPONENT - player;
    }
}
