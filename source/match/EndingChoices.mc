import Toybox.Lang;

// The quick list shown in detailed mode after the point winner is known.
module EndingChoices {
    // In list order. An ace is offered only when the point winner served.
    function endings(winner as Number, server as Number) as Array<Number> {
        if (winner == server) {
            return [Ending.WINNER, Ending.ACE, Ending.ERROR_NET, Ending.ERROR_OUT] as Array<Number>;
        }
        return [Ending.WINNER, Ending.ERROR_NET, Ending.ERROR_OUT] as Array<Number>;
    }

    // The row that starts selected. Most club points end with a ball that
    // lands out, and that row is always the last one.
    function preselected(endings as Array<Number>) as Number {
        return endings.size() - 1;
    }

    function labelKey(ending as Number) as Number {
        var keys = ["", Str.EndingWinner, Str.EndingAce, Str.EndingErrorNet, Str.EndingErrorOut] as Array<Number>;
        return keys[ending];
    }

    // The player who hit the last ball: the point winner for a winner or an
    // ace, the other player for an error.
    function author(ending as Number, winner as Number) as Number {
        var isError = ending == Ending.ERROR_NET || ending == Ending.ERROR_OUT;
        return isError ? Player.opponentOf(winner) : winner;
    }

    function authorKey(ending as Number, winner as Number) as Number {
        return author(ending, winner) == Player.ME ? Str.PlayerMe : Str.PlayerOpponent;
    }
}
