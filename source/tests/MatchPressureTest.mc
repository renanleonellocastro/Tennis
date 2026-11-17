import Toybox.Lang;
import Toybox.Test;

// Tests for the game, break, set and match point flags of both players.

(:test)
function testReceiverOneFromTheGameHasABreakPoint(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("OO");
    Test.assert(!match.state().hasBreakPoint(Player.OPPONENT));
    Test.assert(!match.state().isDecidingPoint());
    match.play("O");
    Test.assert(match.state().hasGamePoint(Player.OPPONENT));
    Test.assert(match.state().hasBreakPoint(Player.OPPONENT));
    Test.assert(!match.state().hasBreakPoint(Player.ME));
    Test.assert(!match.state().hasSetPoint(Player.OPPONENT));
    Test.assert(match.state().isDecidingPoint());
    return true;
}

(:test)
function testServerOneFromTheGameHasNoBreakPoint(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MMM");
    Test.assert(match.state().hasGamePoint(Player.ME));
    Test.assert(!match.state().hasGamePoint(Player.OPPONENT));
    Test.assert(!match.state().hasBreakPoint(Player.ME));
    Test.assert(!match.state().isDecidingPoint());
    return true;
}

(:test)
function testBreakPointForMeOnTheOpponentServe(logger as Test.Logger) as Boolean {
    var match = new MatchDriver(MatchFormat.BEST_OF_3, false, Player.OPPONENT);
    match.play("MMMO");
    Test.assert(match.state().hasBreakPoint(Player.ME));
    Test.assert(!match.state().hasBreakPoint(Player.OPPONENT));
    return true;
}

(:test)
function testDeuceHasNoGamePointAndAdvantageHasOne(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MMMOOO");
    Test.assert(!match.state().hasGamePoint(Player.ME));
    Test.assert(!match.state().hasGamePoint(Player.OPPONENT));
    Test.assert(!match.state().isDecidingPoint());
    match.play("O");
    Test.assert(match.state().hasBreakPoint(Player.OPPONENT));
    match.play("MM");
    Test.assert(match.state().hasGamePoint(Player.ME));
    Test.assert(!match.state().hasBreakPoint(Player.OPPONENT));
    return true;
}

(:test)
function testNoAdvantageDecidingPointIsAGamePointForBoth(logger as Test.Logger) as Boolean {
    var match = new MatchDriver(MatchFormat.BEST_OF_3, true, Player.ME);
    match.play("MMMOOO");
    Test.assert(match.state().hasGamePoint(Player.ME));
    Test.assert(match.state().hasGamePoint(Player.OPPONENT));
    Test.assert(match.state().hasBreakPoint(Player.OPPONENT));
    Test.assert(!match.state().hasBreakPoint(Player.ME));
    return true;
}

(:test)
function testSetPointWhenTheGameWouldWinTheSet(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MMMMM");
    match.play("MM");
    Test.assert(!match.state().hasSetPoint(Player.ME));
    match.play("M");
    Test.assert(match.state().hasSetPoint(Player.ME));
    Test.assert(match.state().hasBreakPoint(Player.ME));
    Test.assert(!match.state().hasSetPoint(Player.OPPONENT));
    Test.assert(!match.state().hasMatchPoint(Player.ME));
    return true;
}

(:test)
function testNoSetPointAtFiveAllButOneAtSixFive(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MOMOMOMOMO");
    match.play("MMM");
    Test.assert(match.state().hasGamePoint(Player.ME));
    Test.assert(!match.state().hasSetPoint(Player.ME));
    Test.assert(!match.state().isDecidingPoint());
    match.play("MOOO");
    Test.assertEqual(match.score(), "0-0 6-5 0-40");
    Test.assert(!match.state().hasSetPoint(Player.OPPONENT));
    match.play("MMM");
    Test.assert(!match.state().hasSetPoint(Player.ME));
    match.play("M");
    Test.assert(match.state().hasSetPoint(Player.ME));
    return true;
}

(:test)
function testTieBreakHasSetPointsAndNoBreakPoints(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    match.play("OOOOOO");
    Test.assert(match.state().hasSetPoint(Player.OPPONENT));
    Test.assert(!match.state().hasSetPoint(Player.ME));
    Test.assert(!match.state().hasBreakPoint(Player.OPPONENT));
    Test.assert(!match.state().hasBreakPoint(Player.ME));
    Test.assert(match.state().isDecidingPoint());
    match.play("MMMMMM");
    Test.assert(!match.state().hasSetPoint(Player.OPPONENT));
    Test.assert(!match.state().isDecidingPoint());
    return true;
}

(:test)
function testMatchPointInAOneSetMatch(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.ONE_SET);
    match.games("OOOOO");
    match.play("OOO");
    Test.assert(match.state().hasMatchPoint(Player.OPPONENT));
    Test.assert(!match.state().hasMatchPoint(Player.ME));
    Test.assert(match.state().isDecidingPoint());
    return true;
}

(:test)
function testMatchPointNeedsTheSetThatWinsTheMatch(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MMMMMMOOOOO");
    match.play("OOO");
    Test.assert(match.state().hasSetPoint(Player.OPPONENT));
    Test.assert(!match.state().hasMatchPoint(Player.OPPONENT));
    match.play("O");
    match.games("MMMMM");
    match.play("MMM");
    Test.assertEqual(match.score(), "1-1 5-0 40-0");
    Test.assert(match.state().hasMatchPoint(Player.ME));
    return true;
}

(:test)
function testMatchPointInTheMatchTieBreak(logger as Test.Logger) as Boolean {
    var match = matchAtOneSetAll(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK);
    match.play("MMMMMMMMOOOOOOOO");
    Test.assert(!match.state().hasMatchPoint(Player.ME));
    match.play("M");
    Test.assert(match.state().hasMatchPoint(Player.ME));
    Test.assert(!match.state().hasMatchPoint(Player.OPPONENT));
    match.play("O");
    Test.assert(!match.state().hasMatchPoint(Player.ME));
    Test.assert(!match.state().isDecidingPoint());
    return true;
}

(:test)
function testMatchPointInATieBreakOnlyMatch(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    match.play("MMMMM");
    Test.assert(!match.state().hasMatchPoint(Player.ME));
    match.play("M");
    Test.assert(match.state().hasMatchPoint(Player.ME));
    return true;
}

(:test)
function testFinishedMatchRaisesNoFlag(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    match.play("MMMMMMM");
    Test.assert(match.state().isFinished());
    Test.assert(!match.state().hasGamePoint(Player.ME));
    Test.assert(!match.state().hasSetPoint(Player.ME));
    Test.assert(!match.state().hasMatchPoint(Player.ME));
    Test.assert(!match.state().hasBreakPoint(Player.OPPONENT));
    Test.assert(!match.state().isDecidingPoint());
    return true;
}
