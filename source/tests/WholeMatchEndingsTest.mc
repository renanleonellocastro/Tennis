import Toybox.Lang;
import Toybox.Test;

// Ended early, closed and resumed: whole matches played through the controller, entry by entry.
// The bench (WholeMatchBench.mc) checks every entry against its own umpire;
// the scores, statistics, laps and clock written here were worked out apart
// from the app, with the replay of the Python converter.
// Script letters: M W A N X a point for me (plain, winner, ace, error net,
// error out), O w a n x the same for the opponent, F a fault, U undo,
// G undo game, + and - a game given to me or to the opponent, P pause on
// and off, Z a pause with dead presses ended by the fault button, C an
// ending list left without a choice, R back from the final screen.
module WholeMatchTests {
    // A match ended from the menu in the second set, reopened, played on, ended again
    // and saved: the file keeps the score of the open set.
    (:test)
    function testEndedEarlyReopenedAndSaved(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3, false, false, Player.ME);
        play.play("MMOMM FOOOFMFMO OFMMFMOM FMFOFOMMOOMFOFO MMFFMOM MMFOFOOO FMFOMMM OFOMOFMMOO FMMMOM MOOMMFM");
        play.at("1-0 0-0 0-0", "6-4", "", 82);
        play.play("MOOMMM OMFMMOOMOOMOMFOO FFFMFOMMM");
        play.endEarly();
        play.at("1-0 2-1 0-0", "6-4 2-1", "", 113);
        play.at("1-0 2-1 0-0", "6-4 2-1", "", 113);
        play.play("RMF");
        play.at("1-0 2-1 15-0", "6-4 2-1", "", 115);
        play.endEarly();
        play.ended(Player.NONE, 2300, "6,4,0,0");
        play.save(2, 1, "6-4 2-1",
                  "39,51,30,36,23,20,5,9,2,0,7,6,7,5,5,0,1,0,50,40,4,4,0,0,0,0,0,0,0,0");
        return true;
    }

    // A match ended before the first point and discarded.
    (:test)
    function testEndedEarlyAndDiscarded(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.ONE_SET, true, true, Player.OPPONENT);
        play.at("0-0 0-0 0-0", "0-0", "", 0);
        play.endEarly();
        play.ended(Player.NONE, 0, "");
        play.discard();
        return true;
    }

    // The app closes right after each set and once more before the first point of
    // the next one: every activity opens its own laps.
    (:test)
    function testClosedAndResumedAtEverySetBreak(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3, false, false, Player.OPPONENT);
        play.stride = 40;
        play.play("OMOOMO MFMMM OOOMMO MFOMOFMM OFOFOFO FOMMMFM FOOFOO MOMFFMM OMMFOFOFO OOOO");
        play.reopenApp();
        play.at("0-1 0-0 0-0", "4-6", "", 65);
        play.at("0-1 0-0 0-0", "4-6", "", 65);
        play.play("FMOMMM MMFOMM OFMOFOMO OMMMFM OFOMOO MMFFOMFM OOMOFMO OMFFOMMMM OMFMOOMMFM");
        play.reopenApp();
        play.at("1-1 0-0 0-0", "4-6 6-3", "", 131);
        play.reopenApp();
        play.at("1-1 0-0 0-0", "4-6 6-3", "", 131);
        play.at("1-1 0-0 0-0", "4-6 6-3", "", 131);
        play.play("MFMOOOFF FOOFOMO OOMFMFOMMM FMFOMOOFO MFOOMOO OOMMMOFMOMM MOFOFFO FOOOO");
        play.at("1-2 0-0 0-0", "4-6 6-3 2-6", "", 195);
        play.ended(Player.OPPONENT, 3900, "");
        play.walked("", 2560, 2048);
        play.save(1, 2, "4-6 6-3 2-6",
                  "74,81,56,59,36,37,7,15,5,0,13,14,9,11,5,7,3,4,72,83,5,8,0,0,0,0,0,0,0,0");
        return true;
    }
}
