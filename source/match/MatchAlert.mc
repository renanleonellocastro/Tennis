import Toybox.Attention;
import Toybox.Lang;

// Vibration cues of the match. Not every watch can vibrate.
module MatchAlert {
    const CHANGE_ENDS_DUTY = 100;
    const CHANGE_ENDS_MS = 600;

    function changeEnds() as Void {
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(CHANGE_ENDS_DUTY, CHANGE_ENDS_MS)]);
        }
    }
}
