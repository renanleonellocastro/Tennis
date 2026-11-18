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

    // What a key or a tap may ask for besides an ending: the full list,
    // back to the match without a point, or nothing at all.
    const MORE = -1;
    const CANCEL = -2;
    const NOTHING = -3;
    // The slot of the key of each MatchAction, or -1.
    const ACTION_SLOTS = [-1, KeySlot.UP, KeySlot.DOWN, KeySlot.START, KeySlot.BACK, -1];
    // The tap areas, in percent of the screen: the left edges of the two
    // columns, the tops of the two rows, then the width and the height.
    // Everything about taps is left out of the builds for the watches that
    // draw their key labels from images: none of them has a touch screen.
    // The columns, the rows and the size of the tap areas, in percent of the
    // screen. A round screen keeps their corners inside the circle; a flat
    // one has its corners to fill.
    (:keyArc)
    const TAP_FRAME = [[10, 52], [31, 55], [38, 20]];
    (:keyArc)
    const FLAT_TAP_FRAME = [[6, 52], [31, 62], [42, 27]];

    // What UP, START, DOWN and BACK pick, in the order of KeySlot. The two
    // common endings are on the keys of the two players. START takes the
    // winner; when an ace is possible too, it opens the full list instead.
    function keyChoices(winner as Number, server as Number) as Array<Number> {
        return [Ending.ERROR_OUT, winner == server ? MORE : Ending.WINNER, Ending.ERROR_NET, CANCEL] as Array<Number>;
    }

    function choiceKey(choice as Number) as Number {
        if (choice == MORE) {
            return Str.KeyMore;
        }
        return choice == CANCEL ? Str.KeyBack : labelKey(choice);
    }

    // The texts next to the keys, in the order of KeySlot.
    function keyTexts(winner as Number, server as Number) as Array<Number> {
        var choices = keyChoices(winner, server);
        var keys = [] as Array<Number>;
        for (var slot = 0; slot < choices.size(); slot++) {
            keys.add(choiceKey(choices[slot]));
        }
        return keys;
    }

    // What the key of a match action picks. The key that leaves works on
    // every watch; the others only where their labels are on screen.
    function keyChoice(action as Number, hasKeyLabels as Boolean, winner as Number, server as Number) as Number {
        var slot = ACTION_SLOTS[action] as Number;
        if (slot < 0 || (slot != KeySlot.BACK && !hasKeyLabels)) {
            return NOTHING;
        }
        return keyChoices(winner, server)[slot];
    }

    // The endings of the tap areas, most common first: a touch screen has
    // room for every one of them, so it needs no full list.
    (:keyArc)
    function tapChoices(winner as Number, server as Number) as Array<Number> {
        var choices = [Ending.ERROR_OUT, Ending.ERROR_NET, Ending.WINNER] as Array<Number>;
        if (winner == server) {
            choices.add(Ending.ACE);
        }
        return choices;
    }

    // [x, y, width, height] of a tap area on a screen of [width, height]:
    // two columns and two rows. The third of three areas takes the whole
    // lower row.
    (:keyArc)
    function tapRect(index as Number, count as Number, screen as Array<Number>, isRound as Boolean) as Array<Number> {
        var frame = isRound ? TAP_FRAME : FLAT_TAP_FRAME;
        var isWide = count % 2 == 1 && index == count - 1;
        var x = screen[0] * frame[0][index % 2] / 100;
        var right = frame[0][isWide ? 1 : index % 2] + frame[2][0];
        return [x, screen[1] * frame[1][index / 2] / 100, screen[0] * right / 100 - x, screen[1] * frame[2][1] / 100]
            as Array<Number>;
    }

    // The room of the text of a tap area: a line in the middle only grazes
    // the round corners.
    (:keyArc)
    function textRoom(box as Array<Number>) as Array<Number> {
        return [box[2] - box[3] / 6, box[3]] as Array<Number>;
    }

    // The ending of the area under a tap at [x, y] on a screen of [width,
    // height], or NOTHING between the areas.
    (:keyArc)
    function tapChoice(at as Array<Number>, screen as Array<Number>, isRound as Boolean, winner as Number,
                       server as Number) as Number {
        var choices = tapChoices(winner, server);
        for (var i = 0; i < choices.size(); i++) {
            var box = tapRect(i, choices.size(), screen, isRound);
            if (at[0] >= box[0] && at[0] < box[0] + box[2] && at[1] >= box[1] && at[1] < box[1] + box[3]) {
                return choices[i];
            }
        }
        return NOTHING;
    }

    // Carries out the choice of a key or a tap: the reaction of the match,
    // or null when the full list must open.
    function settle(controller as MatchController, choice as Number) as Number? {
        if (choice == MORE) {
            return null;
        }
        if (choice == CANCEL) {
            controller.cancelEnding();
        }
        return choice < 0 ? Reaction.NONE : controller.chooseEnding(choice);
    }
}
