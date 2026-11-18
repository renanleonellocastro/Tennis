import Toybox.Lang;
import Toybox.Test;

// Best of 3: whole matches played through the controller, entry by entry.
// The bench (WholeMatchBench.mc) checks every entry against its own umpire;
// the scores, statistics, laps and clock written here were worked out apart
// from the app, with the replay of the Python converter.
// Script letters: M W A N X a point for me (plain, winner, ace, error net,
// error out), O w a n x the same for the opponent, F a fault, U undo,
// G undo game, + and - a game given to me or to the opponent, P pause on
// and off, Z a pause with dead presses ended by the fault button, C an
// ending list left without a choice, R back from the final screen.
module WholeMatchTests {
    // Three sets with a tie break at the end. An undo goes back over a game, a pause
    // swallows presses, and the match is saved with its tags.
    (:test)
    function testBestOf3AdvantageSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3, false, false, Player.ME);
        play.stride = 30;
        play.play("MMMFOM MOFOOFFMFMOOO FMMFMM FUUMFMMOOMFOFFOFOO FFMMMFFM FOMMFOFFOFOO MFFFOMMM MOOOMO MMMM");
        play.play("OMOOMFMFOMOMFMOOFFMM");
        play.at("1-0 0-0 0-0", "6-4", "", 97);
        play.play("FFMOOMMFOFMMOOMOFO FMFOMMM FOOOFO MOFOFOFFO OFZFMMMM FOFOMFMOO FOFMMMFM OMOFMFMFOOFO OOMOFF");
        play.at("1-1 0-0 0-0", "6-4 3-6", "", 179);
        play.play("OOMOMFMMM OFFMMFFFO MFMMOM OOMOFF FMFFOMOOMFM FFOOO FOMMOFMM FOFFFOO FMFMFMFM OFOOMO MMMOOFM");
        play.play("FOFOMMOO");
        play.at("1-1 6-6 0-0", "6-4 3-6 6-6", "", 269);
        play.play("FOOFMM");
        play.at("1-1 6-6 2-2", "6-4 3-6 6-6", "", 275);
        play.play("OMMFMOFMFFM");
        play.at("2-1 0-0 0-0", "6-4 3-6 7-6(7-5)", "", 286);
        play.ended(Player.ME, 5760, "6,4,0,0 3,6,0,0");
        play.walked("2970:2376 2460:1968", 8640, 6912);
        play.save(1, 1, "6-4 3-6 7-6(7-5)",
                  "95,118,63,77,38,40,7,16,12,6,16,15,7,7,19,14,8,9,107,106,6,5,0,0,0,0,0,0,0,0");
        return true;
    }

    // Two straight sets with deciding points. An undo goes back over the end of the
    // first set, and the match is discarded.
    (:test)
    function testBestOf3NoAdSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3, true, false, Player.OPPONENT);
        play.play("OMFMOOMM MMMOFFM FOFMOFMFOO MMMM FOOFMFOFO FMMOFOFMOFM OFOFOO OMOMMM MFO");
        play.at("0-0 5-3 15-15", "5-3", "", 64);
        play.play("FMFOFMFM");
        play.at("1-0 0-0 0-0", "6-3", "", 72);
        play.play("MMUUUMMMMM MMFOFMM OOOMO OMFFFFFM MOOFOMMM FFOOMFOMFO OMOMMM MMMOFM");
        play.at("2-0 0-0 0-0", "6-3 6-2", "", 126);
        play.ended(Player.ME, 2580, "6,3,0,0");
        play.discard();
        return true;
    }

    // A loss in two sets with every ending. An undo goes back out of the tie break,
    // another over its change of ends, and an ending list is left without a choice.
    (:test)
    function testBestOf3AdvantageDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3, false, true, Player.ME);
        play.play("FnnWXFFx XnNaxx xCNnFFXNAFFXwFxXXFN nWxnFFNFax xFANxAFFFFXxFx WxNWN FFXwFxFn Fanna");
        play.at("0-1 0-0 0-0", "2-6", "", 74);
        play.play("xAANnxNFFFAFA xwFXaFNw nFAwXFxNFWN XXFxFwxn nFFXNFXxAFFxXNwAX aFXFxFaFa XXFwFnAW FnFxxn NwNXFX");
        play.play("nFnaa FwNFWFNA xXwwn AUUnAwFFFX");
        play.at("0-1 6-6 3-1", "2-6 6-6", "", 184);
        play.play("wUUXwxaWFnaFWFx");
        play.at("0-2 0-0 0-0", "2-6 6-7(5-7)", "", 195);
        play.ended(Player.OPPONENT, 3980, "2,6,0,0");
        play.save(2, 2, "2-6 6-7(5-7)",
                  "89,59,58,43,38,32,11,10,9,2,10,10,7,9,1,9,1,3,66,82,5,8,9,14,13,12,20,19,27,23");
        return true;
    }

    // Three sets. The app closes and opens again in the second set, a game is undone
    // and replayed, and games are given by the fix of the score.
    (:test)
    function testBestOf3NoAdDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3, true, true, Player.OPPONENT);
        play.play("FXaFnFFXFxW xFFNFXWFFFw NXFxFXFX WFxxFwFNFXFn FWXXFF XFxFwWnFNn WFxNFWnX AFxFnwXx FNnXXFxX");
        play.play("FFwXNxFXn FFFFxxNFxW wxXFxFXFNw wFAXFXXxnFaxxFw");
        play.at("0-1 0-0 0-0", "6-7(4-7)", "", 126);
        play.play("FXxFXFWN FWxXFXX FwFXwFNFFFXFX wFGwFaXaWFa N");
        play.reopenApp();
        play.at("0-1 3-1 15-0", "6-7(4-7) 3-1", "", 163);
        play.play("nFXAFFXGNnFXAFFX XXWX F-GFAWFAFX");
        play.at("1-1 0-0 0-0", "6-7(4-7) 6-1", "", 181);
        play.play("xFFxxNXN F+ XnWxXaFF xXXNwX xFFFFWxnW FxXxFXFFFAN");
        play.at("2-1 0-0 0-0", "6-7(4-7) 6-1 6-0", "", 228);
        play.ended(Player.ME, 4700, "6,1,0,0");
        play.save(3, 0, "6-7(4-7) 6-1 6-0",
                  "86,76,46,50,25,19,22,9,6,8,13,12,7,1,18,17,11,6,95,67,9,6,16,13,6,6,12,16,30,45");
        return true;
    }
}
