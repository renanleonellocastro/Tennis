import Toybox.Lang;

// The half of the baseline the server stands on.
module ServeSide {
    const DEUCE = 0;
    const AD = 1;
}

// The end of the court a player is on. Player.ME starts the match on the
// near end, the one drawn at the bottom of the mini court.
module CourtEnd {
    const NEAR = 0;
    const FAR = 1;
}
