import Toybox.Lang;

// What the watch plays after an input, so the player feels what the press
// did without looking.
module Cue {
    const NONE = 0;
    const POINT = 1;
    const FAULT = 2;
    const UNDO = 3;
    const GAME = 4;
    // A set, a change of ends, the end of the match or a closed block.
    const LONG = 5;
}

// Vibration cues of the match and the practice.
module MatchAlert {
    // Indexed by Cue: the strength (0 to 100) and the milliseconds of each
    // step. A step of no strength is a gap.
    const PATTERNS = [[], [50, 60], [50, 60, 0, 80, 50, 60], [30, 200], [100, 200], [100, 600]];

    // The tests put a fake here.
    var buzzer as Buzzer = new WatchBuzzer();

    function play(cue as Number) as Void {
        if (cue != Cue.NONE) {
            buzzer.buzz(PATTERNS[cue] as Array<Number>);
        }
    }
}
