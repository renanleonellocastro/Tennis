import Toybox.Lang;
import Toybox.Test;

// Tests for points, games, sets and every match format. Scores read
// "sets games points" with me first (see MatchDriver.score).

(:test)
function testNewMatchStartsAtZero(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    Test.assertEqual(match.score(), "0-0 0-0 0-0");
    Test.assert(!match.state().isFinished());
    Test.assertEqual(match.state().winner(), Player.NONE);
    Test.assertEqual(match.state().finishedSets(), 0);
    return true;
}

(:test)
function testPointsCount15Then30Then40(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("M");
    Test.assertEqual(match.score(), "0-0 0-0 15-0");
    match.play("MO");
    Test.assertEqual(match.score(), "0-0 0-0 30-15");
    match.play("MOO");
    Test.assertEqual(match.score(), "0-0 0-0 40-40");
    return true;
}

(:test)
function testFourthPointWinsTheGame(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MMMM");
    Test.assertEqual(match.score(), "0-0 1-0 0-0");
    match.play("OMOOO");
    Test.assertEqual(match.score(), "0-0 1-1 0-0");
    return true;
}

(:test)
function testDeuceAndAdvantageBackAndForth(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MMMOOO");
    Test.assertEqual(match.score(), "0-0 0-0 40-40");
    match.play("M");
    Test.assertEqual(match.score(), "0-0 0-0 AD-40");
    match.play("O");
    Test.assertEqual(match.score(), "0-0 0-0 40-40");
    match.play("O");
    Test.assertEqual(match.score(), "0-0 0-0 40-AD");
    match.play("M");
    Test.assertEqual(match.score(), "0-0 0-0 40-40");
    return true;
}

(:test)
function testAdvantageThenPointWinsTheGame(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MMMOOOMM");
    Test.assertEqual(match.score(), "0-0 1-0 0-0");
    match.play("MMMOOOOMOO");
    Test.assertEqual(match.score(), "0-0 1-1 0-0");
    return true;
}

(:test)
function testNoAdvantageDecidingPointWinsTheGame(logger as Test.Logger) as Boolean {
    var match = new MatchDriver(MatchFormat.BEST_OF_3, true, Player.ME);
    match.play("MMMOOO");
    Test.assertEqual(match.score(), "0-0 0-0 40-40");
    match.play("O");
    Test.assertEqual(match.score(), "0-0 0-1 0-0");
    match.play("OOOMMMM");
    Test.assertEqual(match.score(), "0-0 1-1 0-0");
    return true;
}

(:test)
function testSetIsWonAtSixGamesWithTwoClear(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MMMMMOOOO");
    Test.assertEqual(match.score(), "0-0 5-4 0-0");
    match.games("M");
    Test.assertEqual(match.score(), "1-0 0-0 0-0");
    Test.assertEqual(match.state().finishedSets(), 1);
    Test.assertEqual(match.state().setGames(0, Player.ME), 6);
    Test.assertEqual(match.state().setGames(0, Player.OPPONENT), 4);
    Test.assertEqual(match.state().setTieBreakPoints(0, Player.ME), 0);
    return true;
}

(:test)
function testSixFiveDoesNotWinTheSetSevenFiveDoes(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MOMOMOMOMOO");
    Test.assertEqual(match.score(), "0-0 5-6 0-0");
    match.games("O");
    Test.assertEqual(match.score(), "0-1 0-0 0-0");
    Test.assertEqual(match.state().setGames(0, Player.ME), 5);
    Test.assertEqual(match.state().setGames(0, Player.OPPONENT), 7);
    Test.assertEqual(match.state().setTieBreakPoints(0, Player.OPPONENT), 0);
    return true;
}

(:test)
function testTieBreakStartsAtSixAllAndCountsPlainPoints(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    Test.assert(match.state().isTieBreak());
    match.play("MMMOOOO");
    Test.assertEqual(match.score(), "0-0 6-6 3-4");
    match.play("MMM");
    Test.assertEqual(match.score(), "0-0 6-6 6-4");
    return true;
}

(:test)
function testTieBreakWonAtSevenGivesTheSetSevenSix(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    match.play("MMMMMMOOOOOM");
    Test.assertEqual(match.score(), "1-0 0-0 0-0");
    Test.assertEqual(match.state().setGames(0, Player.ME), 7);
    Test.assertEqual(match.state().setGames(0, Player.OPPONENT), 6);
    Test.assertEqual(match.state().setTieBreakPoints(0, Player.ME), 7);
    Test.assertEqual(match.state().setTieBreakPoints(0, Player.OPPONENT), 5);
    Test.assert(!match.state().isTieBreak());
    return true;
}

(:test)
function testTieBreakNeedsTwoClearPoints(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    match.play("MMMMMMOOOOOOO");
    Test.assertEqual(match.score(), "0-0 6-6 6-7");
    match.play("MM");
    Test.assertEqual(match.score(), "0-0 6-6 8-7");
    match.play("M");
    Test.assertEqual(match.score(), "1-0 0-0 0-0");
    Test.assertEqual(match.state().setTieBreakPoints(0, Player.OPPONENT), 7);
    return true;
}

(:test)
function testNoAdvantageSettingDoesNotShortenTheTieBreak(logger as Test.Logger) as Boolean {
    var match = new MatchDriver(MatchFormat.ONE_SET, true, Player.ME);
    match.games("MOMOMOMOMOMO");
    match.play("MMMMMMOOOOOOM");
    Test.assertEqual(match.score(), "0-0 6-6 7-6");
    Test.assert(!match.state().isFinished());
    return true;
}

(:test)
function testBestOfThreeEndsAfterTwoStraightSets(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("OOOOOO");
    Test.assert(!match.state().isFinished());
    match.games("OOOOOO");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().winner(), Player.OPPONENT);
    Test.assertEqual(match.score(), "0-2 0-0 0-0");
    Test.assertEqual(match.state().finishedSets(), 2);
    return true;
}

(:test)
function testBestOfThreePlaysAFullThirdSet(logger as Test.Logger) as Boolean {
    var match = matchAtOneSetAll(MatchFormat.BEST_OF_3);
    Test.assertEqual(match.score(), "1-1 0-0 0-0");
    Test.assert(!match.state().isTieBreak());
    match.games("MMMMMM");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().winner(), Player.ME);
    Test.assertEqual(match.state().setGames(2, Player.ME), 6);
    Test.assertEqual(match.state().setGames(1, Player.OPPONENT), 6);
    return true;
}

(:test)
function testMatchTieBreakReplacesTheThirdSet(logger as Test.Logger) as Boolean {
    var match = matchAtOneSetAll(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK);
    Test.assert(match.state().isTieBreak());
    match.play("MMMMMMMOO");
    Test.assertEqual(match.score(), "1-1 0-0 7-2");
    Test.assert(!match.state().isFinished());
    match.play("MMM");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().winner(), Player.ME);
    Test.assertEqual(match.score(), "2-1 0-0 0-0");
    return true;
}

(:test)
function testMatchTieBreakNeedsTwoClearPointsAndKeepsItsScore(logger as Test.Logger) as Boolean {
    var match = matchAtOneSetAll(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK);
    match.play("MMMMMMMMMOOOOOOOOOO");
    Test.assertEqual(match.score(), "1-1 0-0 9-10");
    match.play("MMM");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().setGames(2, Player.ME), 1);
    Test.assertEqual(match.state().setGames(2, Player.OPPONENT), 0);
    Test.assertEqual(match.state().setTieBreakPoints(2, Player.ME), 12);
    Test.assertEqual(match.state().setTieBreakPoints(2, Player.OPPONENT), 10);
    return true;
}

(:test)
function testMatchTieBreakFormatStillPlaysRegularFirstSets(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK);
    match.play("MMMMMMM");
    Test.assertEqual(match.score(), "1-0 0-0 0-0");
    match.games("MMMMMM");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().finishedSets(), 2);
    return true;
}

(:test)
function testOneSetMatchEndsWithTheSet(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.ONE_SET);
    match.games("MMMMMM");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().winner(), Player.ME);
    Test.assertEqual(match.score(), "1-0 0-0 0-0");
    return true;
}

(:test)
function testOneSetMatchCanEndInATieBreak(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.ONE_SET);
    match.play("OOOOOOO");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().winner(), Player.OPPONENT);
    Test.assertEqual(match.state().setGames(0, Player.OPPONENT), 7);
    return true;
}

(:test)
function testProSetGoesToEightGames(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.PRO_SET);
    match.games("MMMMMMM");
    Test.assertEqual(match.score(), "0-0 7-0 0-0");
    Test.assert(!match.state().isFinished());
    match.games("M");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().setGames(0, Player.ME), 8);
    return true;
}

(:test)
function testProSetNeedsTwoClearGames(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.PRO_SET);
    match.games("MOMOMOMOMOMOMOM");
    Test.assertEqual(match.score(), "0-0 8-7 0-0");
    Test.assert(!match.state().isTieBreak());
    Test.assert(!match.state().isFinished());
    match.games("M");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().setGames(0, Player.ME), 9);
    Test.assertEqual(match.state().setGames(0, Player.OPPONENT), 7);
    return true;
}

(:test)
function testProSetPlaysATieBreakAtEightAll(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.PRO_SET);
    match.games("MOMOMOMOMOMO");
    Test.assert(!match.state().isTieBreak());
    match.games("MOMO");
    Test.assert(match.state().isTieBreak());
    match.play("MMMMMMM");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().setGames(0, Player.ME), 9);
    Test.assertEqual(match.state().setGames(0, Player.OPPONENT), 8);
    Test.assertEqual(match.state().setTieBreakPoints(0, Player.ME), 7);
    return true;
}

(:test)
function testTieBreakOnlyMatchIsOneTieBreak(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    Test.assert(match.state().isTieBreak());
    match.play("MMMOOOMMM");
    Test.assertEqual(match.score(), "0-0 0-0 6-3");
    match.play("M");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().winner(), Player.ME);
    Test.assertEqual(match.state().setGames(0, Player.ME), 1);
    Test.assertEqual(match.state().setTieBreakPoints(0, Player.ME), 7);
    Test.assertEqual(match.state().setTieBreakPoints(0, Player.OPPONENT), 3);
    return true;
}

(:test)
function testTieBreakOnlyMatchNeedsTwoClearPoints(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    match.play("MMMMMMOOOOOOO");
    Test.assert(!match.state().isFinished());
    match.play("O");
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.state().winner(), Player.OPPONENT);
    return true;
}
