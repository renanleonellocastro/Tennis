import Toybox.Lang;
import Toybox.Test;

// Best of 3 with a match tie break: whole matches played through the controller, entry by entry.
// The bench (WholeMatchBench.mc) checks every entry against its own umpire;
// the scores, statistics, laps and clock written here were worked out apart
// from the app, with the replay of the Python converter.
// Script letters: M W A N X a point for me (plain, winner, ace, error net,
// error out), O w a n x the same for the opponent, F a fault, U undo,
// G undo game, + and - a game given to me or to the opponent, P pause on
// and off, Z a pause with dead presses ended by the fault button, C an
// ending list left without a choice, R back from the final screen.
module WholeMatchTests {
    // One set each and a match tie break to 10. An undo goes back from the tie break
    // into the second set, and the final score is reopened and played again.
    (:test)
    function testMatchTieBreakAdvantageSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK, false, false, Player.ME);
        play.play("FOMOMFFMFMFFOMFMFM FMOMMFM MOOOFO MFFFMOFM MFFOMOO FMMMM MOOMFOMMFFOO FOMMFMM MOMMFM");
        play.at("1-0 0-0 0-0", "6-3", "", 76);
        play.play("MOMFOMFOFOO FMOMFMM FOMFOOO FMFMMM FOOFOO MOMMOM OMOOMFMOMFOFMFOO FMOOFMMM FOOOO FMOFOMFOMOO");
        play.at("1-1 0-0 0-0", "6-3 4-6", "", 159);
        play.play("OUUOOMOMOFOFMMFO");
        play.at("1-1 0-0 4-5", "6-3 4-6 0-0", "", 171);
        play.play("MMMFF");
        play.at("1-1 0-0 8-5", "6-3 4-6 0-0", "", 176);
        play.play("FMFOFOOMRM");
        play.at("2-1 0-0 0-0", "6-3 4-6 1-0(10-8)", "", 184);
        play.ended(Player.ME, 3740, "6,3,0,0 4,6,0,0");
        play.save(0, 1, "6-3 4-6 1-0(10-8)",
                  "76,61,52,38,30,19,13,13,4,2,10,9,6,5,6,8,4,4,72,65,5,4,0,0,0,0,0,0,0,0");
        return true;
    }

    // Two straight sets, so no match tie break. The app closes on the final score.
    (:test)
    function testMatchTieBreakNoAdSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK, true, false, Player.OPPONENT);
        play.stride = 45;
        play.play("MFMFMM OOFOMMFF MFMMFF MOOFOFMO OFMFMOFOFMM OMMOMOFOPP MFMMFM MOFOMFFFF FOOFMMOFMM MMOFFOFF");
        play.play("OOMFMFMM MMFMFM");
        play.at("1-0 0-0 0-0", "7-5", "", 94);
        play.play("OOMFMMM FMMFFFOFFMFO FOOOFMMFFM OFFOMMFO FMMOMM OFOOO FMOOMOMFM MOOMFOMO FOFMMMOOM OFFMMMM");
        play.at("2-0 0-0 0-0", "7-5 6-4", "", 175);
        play.ended(Player.ME, 3500, "7,5,0,0");
        play.walked("4230:3384", 7875, 6300);
        play.closeFinishedApp("7-5 6-4",
                              "65,64,43,40,23,16,4,4,9,2,11,11,2,0,13,16,11,9,71,58,8,6,0,0,0,0,0,0,0,0");
        return true;
    }

    // A match tie break lost 11-13, with a pause and a game given to the opponent.
    (:test)
    function testMatchTieBreakAdvantageDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK, false, true, Player.ME);
        play.play("wwxXXWnFx FwNWFFW xWxFFNx Xa- WFAXFX nFnFwa FFnAFnFAWXA xXnwFn FxnXxXNxx");
        play.at("0-1 0-0 0-0", "3-6", "", 66);
        play.play("aNaXxXXwFFFN xNWFXW FFwxwn FZwAAnXxxFWFAN nFWxFNFXFxNnXFN xxxXAFF wNFFNnN XXAA");
        play.at("1-1 0-0 0-0", "3-6 6-2", "", 136);
        play.play("FWAFwFFFXwXXwFWXxF");
        play.at("1-1 0-0 8-4", "3-6 6-2 0-0", "", 154);
        play.play("xwFxaFaXWwwXwa");
        play.at("1-2 0-0 0-0", "3-6 6-2 0-1(11-13)", "", 168);
        play.ended(Player.OPPONENT, 3300, "3,6,0,0 6,2,0,0");
        play.save(1, 2, "3-6 6-2 0-1(11-13)",
                  "71,62,55,43,33,28,7,7,3,5,9,8,5,4,8,15,4,4,67,66,7,6,13,17,11,7,13,13,23,25");
        return true;
    }

    // Two tie break sets and a match tie break: the longest score text. The app
    // closes and opens again inside the match tie break.
    (:test)
    function testMatchTieBreakNoAdDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK, true, true, Player.OPPONENT);
        play.play("xXXNwN xFwnAAFNFF XWwxXW FFFFNwAAx XxxWNN xNnxFNn wNFxXFFFW WxxnNx FaFaXxXXFF FFWFwwFXx WxFaXnNFF");
        play.play("FFxFFx wFXxFNxWWFFXFX");
        play.at("1-0 0-0 0-0", "7-6(7-3)", "", 107);
        play.play("NXXFxxN FxxFnw xFAXAW nxwXx WxFXFxFAFnFW Fnwaa wXXAA xFaxWa XwAAX XaFwFnn NNWN wFxFxFx");
        play.play("FXawXXawFFFFNFw");
        play.at("1-1 0-0 0-0", "7-6(7-3) 6-7(4-7)", "", 197);
        play.play("WXnXNWW");
        play.reopenApp();
        play.at("1-1 0-0 6-1", "7-6(7-3) 6-7(4-7) 0-0", "", 204);
        play.play("XnFFFFxWXFX");
        play.at("2-1 0-0 0-0", "7-6(7-3) 6-7(4-7) 1-0(10-5)", "", 215);
        play.ended(Player.ME, 4300, "");
        play.save(2, 1, "7-6(7-3) 6-7(4-7) 1-0(10-5)",
                  "86,83,60,63,37,33,11,14,10,4,12,12,6,6,7,15,6,6,84,85,8,5,18,18,11,10,13,19,34,32");
        return true;
    }
}
