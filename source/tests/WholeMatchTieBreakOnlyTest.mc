import Toybox.Lang;
import Toybox.Test;

// Tie break only: whole matches played through the controller, entry by entry.
// The bench (WholeMatchBench.mc) checks every entry against its own umpire;
// the scores, statistics, laps and clock written here were worked out apart
// from the app, with the replay of the Python converter.
// Script letters: M W A N X a point for me (plain, winner, ace, error net,
// error out), O w a n x the same for the opponent, F a fault, U undo,
// G undo game, + and - a game given to me or to the opponent, P pause on
// and off, Z a pause with dead presses ended by the fault button, C an
// ending list left without a choice, R back from the final screen.
module WholeMatchTests {
    // A tie break won 7-5, with an undo over the change of ends.
    (:test)
    function testTieBreakOnlyAdvantageSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.TIE_BREAK_ONLY, false, false, Player.ME);
        play.play("FMOOMO");
        play.at("0-0 0-0 2-3", "0-0", "", 6);
        play.play("MUUOMOMFMMFOFM");
        play.at("1-0 0-0 0-0", "1-0(7-5)", "", 16);
        play.ended(Player.ME, 360, "");
        play.save(1, 1, "1-0(7-5)",
                  "6,6,3,5,2,3,3,1,0,0,0,0,0,0,0,0,0,0,7,5,3,2,0,0,0,0,0,0,0,0");
        return true;
    }

    // A tie break lost 10-12: no advantage scoring changes nothing in a tie break.
    (:test)
    function testTieBreakOnlyNoAdSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.TIE_BREAK_ONLY, true, false, Player.OPPONENT);
        play.play("MMMOFOOOOMFM");
        play.at("0-0 0-0 5-5", "0-0", "", 12);
        play.play("MOOMMO");
        play.at("0-0 0-0 8-8", "0-0", "", 18);
        play.play("OMMFOOO");
        play.at("0-1 0-0 0-0", "0-1(10-12)", "", 25);
        play.ended(Player.OPPONENT, 500, "");
        play.closeFinishedApp("0-1(10-12)",
                              "11,11,10,9,7,7,1,2,0,0,0,0,0,0,0,0,0,0,10,12,3,5,0,0,0,0,0,0,0,0");
        return true;
    }

    // A tie break won 7-3 with every ending, a pause and the app closed and opened.
    (:test)
    function testTieBreakOnlyAdvantageDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.TIE_BREAK_ONLY, false, true, Player.OPPONENT);
        play.play("WnNZWX");
        play.reopenApp();
        play.at("0-0 0-0 4-1", "0-0", "", 5);
        play.play("XFNFnxFX");
        play.at("1-0 0-0 0-0", "1-0(7-3)", "", 13);
        play.ended(Player.ME, 260, "");
        play.save(2, 1, "1-0(7-3)",
                  "5,5,3,4,2,1,2,1,0,0,0,0,0,0,0,0,0,0,7,3,5,2,2,0,0,0,2,2,1,3");
        return true;
    }

    // A tie break won 8-6, reopened from the final score, then the whole tie break is
    // undone from the menu and given to the opponent.
    (:test)
    function testTieBreakOnlyNoAdDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.TIE_BREAK_ONLY, true, true, Player.ME);
        play.play("AFnxnAXxXwXFNwAFWRW");
        play.at("1-0 0-0 0-0", "1-0(8-6)", "", 17);
        play.ended(Player.ME, 360, "");
        play.play("RG");
        play.at("0-0 0-0 0-0", "0-0", "", 0);
        play.play("-");
        play.ended(Player.OPPONENT, 360, "");
        play.discard();
        return true;
    }
}
