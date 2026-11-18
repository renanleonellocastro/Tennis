import Toybox.Lang;
import Toybox.Test;

// One set: whole matches played through the controller, entry by entry.
// The bench (WholeMatchBench.mc) checks every entry against its own umpire;
// the scores, statistics, laps and clock written here were worked out apart
// from the app, with the replay of the Python converter.
// Script letters: M W A N X a point for me (plain, winner, ace, error net,
// error out), O w a n x the same for the opponent, F a fault, U undo,
// G undo game, + and - a game given to me or to the opponent, P pause on
// and off, Z a pause with dead presses ended by the fault button, C an
// ending list left without a choice, R back from the final screen.
module WholeMatchTests {
    // One set won 7-6(9-7). An undo goes back out of the tie break into the last game.
    (:test)
    function testOneSetAdvantageSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.ONE_SET, false, false, Player.OPPONENT);
        play.play("FOMMFFFM OMOMOFO OOFMMMFOOFFFMM OOMMFOFMOO MFOFFMOM OMOOFMO FOMMOMFOMFOFMM MMOMOFFMOMOFOFF");
        play.play("FMMOOFFM OMOFOFF FOFFFFOFOMMFM OOOFO FOUUUOFOOFMOMFOMOM");
        play.at("0-0 6-6 4-5", "6-6", "", 128);
        play.play("MOMOMFMM");
        play.at("1-0 0-0 0-0", "7-6(9-7)", "", 136);
        play.ended(Player.ME, 2780, "");
        play.save(3, 1, "7-6(9-7)",
                  "49,53,36,32,14,11,4,9,3,6,6,6,0,0,10,8,6,6,51,51,4,6,0,0,0,0,0,0,0,0");
        return true;
    }

    // One set won 6-2 with steps counted, and a save without tags.
    (:test)
    function testOneSetNoAdSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.ONE_SET, true, false, Player.ME);
        play.stride = 60;
        play.play("FMMMOOM FMFOOFFFMFF OMOOFF MMMFOOM");
        play.at("0-0 3-1 0-0", "3-1", "", 31);
        play.play("MOFFOMMFM OFOOFMO MMOOMFM MOOFFFMFM");
        play.at("1-0 0-0 0-0", "6-2", "", 63);
        play.ended(Player.ME, 1260, "");
        play.walked("", 3780, 3024);
        play.save(0, 0, "6-2",
                  "24,23,19,12,10,7,3,3,2,3,4,4,3,1,5,4,3,1,26,21,3,3,0,0,0,0,0,0,0,0");
        return true;
    }

    // One set won 6-4 with every ending, reopened from the final score and discarded.
    (:test)
    function testOneSetAdvantageDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.ONE_SET, false, true, Player.ME);
        play.play("xnxXFXWxXwXwXXFX waWFXxx WXwXN WaFWFWFxwnx xFFXFXFxWXFFFNN FCCFaxaWx FANNW FFFFFwwax");
        play.play("FFFnWFxFXNXFxwAAX NXFxxNnFNWRUNW");
        play.at("1-0 0-0 0-0", "6-4", "", 102);
        play.ended(Player.ME, 2080, "");
        play.discard();
        return true;
    }

    // One set lost 5-7. The fix of the score gives and takes back games.
    (:test)
    function testOneSetNoAdDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.ONE_SET, true, true, Player.OPPONENT);
        play.play("nxXnFNWw xFAFFNFWW nxax X+GXFWAN axxFXFFx + nxWXWaa XxxXXFFFW aFXaFFwWwGGXxxXXFFFWaFXaFFwWw");
        play.play("FXFXFFFFXX FxaXFaFw XWwnnXFF");
        play.at("0-1 0-0 0-0", "5-7", "", 89);
        play.ended(Player.OPPONENT, 2080, "");
        play.save(1, 1, "5-7",
                  "34,36,23,28,17,21,6,3,5,2,6,6,5,6,4,3,0,1,35,35,4,4,9,5,2,8,6,3,11,15");
        return true;
    }
}
