import Toybox.Lang;
import Toybox.Test;

// Pro set of 8 games: whole matches played through the controller, entry by entry.
// The bench (WholeMatchBench.mc) checks every entry against its own umpire;
// the scores, statistics, laps and clock written here were worked out apart
// from the app, with the replay of the Python converter.
// Script letters: M W A N X a point for me (plain, winner, ace, error net,
// error out), O w a n x the same for the opponent, F a fault, U undo,
// G undo game, + and - a game given to me or to the opponent, P pause on
// and off, Z a pause with dead presses ended by the fault button, C an
// ending list left without a choice, R back from the final screen.
module WholeMatchTests {
    // A pro set won 8-5, with an undo over a game and a pause.
    (:test)
    function testProSetAdvantageSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.PRO_SET, false, false, Player.ME);
        play.play("MFMMOOOMFM OFMOFOFMO MMMOM OOMFOO FMMOMFFFM FMMMOOOOFO MMOFMOOMM MUUUMMMMOFOFMFOMOOO");
        play.play("FMOOOFMMFFMMM OOOMO MMZOMM FMOOMFMFM MFO");
        play.at("0-0 7-5 15-15", "7-5", "", 106);
        play.play("MMOOMM");
        play.at("1-0 0-0 0-0", "8-5", "", 112);
        play.ended(Player.ME, 2300, "");
        play.save(2, 2, "8-5",
                  "50,40,40,28,26,20,7,5,2,0,7,6,7,5,6,3,1,0,48,42,4,5,0,0,0,0,0,0,0,0");
        return true;
    }

    // A pro set that goes to a tie break at 8-8: 9-8(7-4). The app closes and opens
    // again at 8-8.
    (:test)
    function testProSetNoAdSimple(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.PRO_SET, true, false, Player.OPPONENT);
        play.play("OOOMFMFFFM OMFMFOOO MFMOMOFF FOMOOMO OMOOMMM MMOFMOFOFO MMOFFFM MFOOMFOO MMMFOOOM OMFOOO");
        play.play("OMFOOFFFMM FOFMMOOO FOFOMMMOFM MMOOMFFO MOFMOMM MMFFFFOFMO");
        play.reopenApp();
        play.at("0-0 8-8 0-0", "8-8", "", 132);
        play.play("MFOOMOOMMMMM");
        play.at("1-0 0-0 0-0", "9-8(7-4)", "", 144);
        play.ended(Player.ME, 2880, "");
        play.save(1, 0, "9-8(7-4)",
                  "56,57,40,42,17,17,4,4,3,4,8,8,0,0,13,10,8,8,57,56,5,5,0,0,0,0,0,0,0,0");
        return true;
    }

    // A pro set lost 7-9 with every ending and a game undone from the menu.
    (:test)
    function testProSetAdvantageDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.PRO_SET, false, true, Player.OPPONENT);
        play.play("WWFXaFF FwFFxFXx FFwXFnFXX XNnWwnFFw XXNN FFFwnFWWFF FXFFNFN xXAxxw FFxFWFxFFFX AwnxAFx wFXaXXFF");
        play.play("FwFXXFFFnFF nNxFXFXX xFXFXnnx nnNXNxaa");
        play.at("0-0 7-8 0-0", "7-8", "", 121);
        play.play("FAGFAxxww");
        play.at("0-1 0-0 0-0", "7-9", "", 127);
        play.ended(Player.OPPONENT, 2580, "");
        play.save(0, 2, "7-9",
                  "48,45,31,28,9,12,6,2,6,6,8,8,0,1,9,12,7,8,46,47,4,5,6,11,4,4,11,8,15,22");
        return true;
    }

    // A pro set won 8-3. The app closes and opens again twice.
    (:test)
    function testProSetNoAdDetailed(logger as Test.Logger) as Boolean {
        var play = new Play(MatchFormat.PRO_SET, true, true, Player.ME);
        play.stride = 25;
        play.play("WFWAX xXWXFwX XwxxXNx FF");
        play.reopenApp();
        play.at("0-0 2-1 15-0", "2-1", "", 21);
        play.play("FxNxaNFF FnXxXFXN FwnxXn WnFNxFwXN WWaXxwX");
        play.reopenApp();
        play.at("0-0 6-2 0-0", "6-2", "", 59);
        play.play("FXxFFxWXFw aXFWFFFF WAFWFFnW");
        play.at("1-0 0-0 0-0", "8-3", "", 85);
        play.ended(Player.ME, 1700, "");
        play.walked("", 650, 520);
        play.save(3, 2, "8-3",
                  "37,30,27,22,17,10,5,3,2,4,6,5,4,1,7,8,4,2,39,28,7,3,11,6,2,3,5,6,12,16");
        return true;
    }
}
