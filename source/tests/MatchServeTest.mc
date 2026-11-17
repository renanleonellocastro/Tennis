import Toybox.Lang;
import Toybox.Test;

// Tests for who serves, from which side, serve faults and the ends of the
// court, including the tie break rotation.

function assertTieBreakServers(match as MatchDriver, expected as Array<Number>) as Void {
    for (var i = 0; i < expected.size(); i++) {
        Test.assertMessage(match.state().server() == expected[i], "wrong server on tie break point " + (i + 1));
        match.play("M");
    }
}

(:test)
function testFirstServerIsTheOneChosen(logger as Test.Logger) as Boolean {
    var mine = new MatchDriver(MatchFormat.BEST_OF_3, false, Player.ME);
    Test.assertEqual(mine.state().server(), Player.ME);
    Test.assertEqual(mine.state().receiver(), Player.OPPONENT);
    var theirs = new MatchDriver(MatchFormat.BEST_OF_3, false, Player.OPPONENT);
    Test.assertEqual(theirs.state().server(), Player.OPPONENT);
    Test.assertEqual(theirs.state().receiver(), Player.ME);
    return true;
}

(:test)
function testServeAlternatesEveryGameAndNotEveryPoint(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MOM");
    Test.assertEqual(match.state().server(), Player.ME);
    match.play("MM");
    Test.assertEqual(match.state().server(), Player.OPPONENT);
    match.games("O");
    Test.assertEqual(match.state().server(), Player.ME);
    return true;
}

(:test)
function testServeCarriesOverFromOneSetToTheNext(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MMMMMOOOM");
    Test.assertEqual(match.state().finishedSets(), 1);
    Test.assertEqual(match.state().server(), Player.OPPONENT);
    return true;
}

(:test)
function testServeSideAlternatesDeuceAndAdEveryPoint(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    Test.assertEqual(match.state().serveSide(), ServeSide.DEUCE);
    match.play("M");
    Test.assertEqual(match.state().serveSide(), ServeSide.AD);
    match.play("O");
    Test.assertEqual(match.state().serveSide(), ServeSide.DEUCE);
    match.play("MM");
    Test.assertEqual(match.state().serveSide(), ServeSide.DEUCE);
    match.play("M");
    Test.assertEqual(match.state().serveSide(), ServeSide.DEUCE);
    return true;
}

(:test)
function testFaultKeepsTheServeSide(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MF");
    Test.assertEqual(match.state().serveSide(), ServeSide.AD);
    Test.assertEqual(match.score(), "0-0 0-0 15-0");
    return true;
}

(:test)
function testFirstFaultMarksTheSecondServe(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    Test.assert(!match.state().isSecondServe());
    match.play("F");
    Test.assert(match.state().isSecondServe());
    Test.assertEqual(match.score(), "0-0 0-0 0-0");
    match.play("M");
    Test.assert(!match.state().isSecondServe());
    Test.assertEqual(match.score(), "0-0 0-0 15-0");
    return true;
}

(:test)
function testDoubleFaultGivesThePointToTheReceiver(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("FF");
    Test.assertEqual(match.score(), "0-0 0-0 0-15");
    Test.assert(!match.state().isSecondServe());
    return true;
}

(:test)
function testDoubleFaultOnTheOpponentServeGivesMeThePoint(logger as Test.Logger) as Boolean {
    var match = new MatchDriver(MatchFormat.BEST_OF_3, false, Player.OPPONENT);
    match.play("FF");
    Test.assertEqual(match.score(), "0-0 0-0 15-0");
    return true;
}

(:test)
function testDoubleFaultCanEndTheGame(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("OOOFF");
    Test.assertEqual(match.score(), "0-0 0-1 0-0");
    Test.assertEqual(match.state().server(), Player.OPPONENT);
    return true;
}

(:test)
function testTieBreakServePassesAfterOnePointThenEveryTwo(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    assertTieBreakServers(match, [
        Player.ME, Player.OPPONENT, Player.OPPONENT, Player.ME,
        Player.ME, Player.OPPONENT, Player.OPPONENT
    ]);
    return true;
}

(:test)
function testTieBreakStartsWithThePlayerWhoseTurnItIs(logger as Test.Logger) as Boolean {
    var match = new MatchDriver(MatchFormat.PRO_SET, false, Player.OPPONENT);
    match.games("MOMOMOMOMOMOMOMO");
    Test.assert(match.state().isTieBreak());
    assertTieBreakServers(match, [Player.OPPONENT, Player.ME, Player.ME, Player.OPPONENT]);
    return true;
}

(:test)
function testReceiverOfTheTieBreakServesTheNextSet(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    Test.assertEqual(match.state().server(), Player.ME);
    match.play("MMMMMMM");
    Test.assertEqual(match.state().finishedSets(), 1);
    Test.assertEqual(match.state().server(), Player.OPPONENT);
    return true;
}

(:test)
function testTieBreakServeSideAlternatesEveryPoint(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    Test.assertEqual(match.state().serveSide(), ServeSide.DEUCE);
    match.play("M");
    Test.assertEqual(match.state().serveSide(), ServeSide.AD);
    match.play("O");
    Test.assertEqual(match.state().serveSide(), ServeSide.DEUCE);
    return true;
}

(:test)
function testMatchTieBreakRotatesTheServeToo(logger as Test.Logger) as Boolean {
    var match = matchAtOneSetAll(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK);
    assertTieBreakServers(match, [Player.ME, Player.OPPONENT, Player.OPPONENT, Player.ME, Player.ME]);
    return true;
}

(:test)
function testPlayersStartOnOppositeEnds(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.NEAR);
    Test.assertEqual(match.state().endOf(Player.OPPONENT), CourtEnd.FAR);
    Test.assert(!match.state().isChangeOfEndsDue());
    return true;
}

(:test)
function testEndsChangeAfterEveryOddGame(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("M");
    Test.assert(match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.FAR);
    Test.assertEqual(match.state().endOf(Player.OPPONENT), CourtEnd.NEAR);
    match.games("M");
    Test.assert(!match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.FAR);
    match.games("M");
    Test.assert(match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.NEAR);
    return true;
}

(:test)
function testChangeOfEndsNoticeLastsUntilTheNextEntry(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("M");
    Test.assert(match.state().isChangeOfEndsDue());
    match.play("F");
    Test.assert(!match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.FAR);
    return true;
}

(:test)
function testEndsChangeAtTheEndOfASetWithOddGames(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MMMMMOOOM");
    Test.assertEqual(match.state().finishedSets(), 1);
    Test.assert(match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.FAR);
    return true;
}

(:test)
function testEndsStayAfterASetWithEvenGamesUntilTheFirstGame(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MMMMMOOOOM");
    Test.assertEqual(match.state().finishedSets(), 1);
    Test.assert(!match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.FAR);
    match.games("M");
    Test.assert(match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.NEAR);
    return true;
}

(:test)
function testTieBreakChangesEndsEverySixPoints(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.NEAR);
    match.play("MMMOO");
    Test.assert(!match.state().isChangeOfEndsDue());
    match.play("O");
    Test.assert(match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.FAR);
    match.play("M");
    Test.assert(!match.state().isChangeOfEndsDue());
    match.play("OMOMO");
    Test.assertEqual(match.score(), "0-0 6-6 6-6");
    Test.assert(match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.NEAR);
    return true;
}

(:test)
function testEndsChangeOnceWhenTheTieBreakEndsTheSet(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    match.play("MMMMMMOOOOOM");
    Test.assertEqual(match.state().finishedSets(), 1);
    Test.assert(match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.NEAR);
    return true;
}

(:test)
function testNoChangeOfEndsIsDueOnceTheMatchIsOver(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    match.play("MMMMMMM");
    Test.assert(match.state().isFinished());
    Test.assert(!match.state().isChangeOfEndsDue());
    return true;
}
