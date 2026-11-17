import Toybox.Lang;
import Toybox.Test;

// Tests for the engine itself: what it accepts, undo at every kind of
// boundary and resuming from a stored log.

function assertUndoRestores(match as MatchDriver, script as String, expectedScore as String) as Void {
    match.play(script);
    Test.assert(match.engine.undo());
    Test.assertEqual(match.score(), expectedScore);
}

(:test)
function testAceIsAcceptedOnlyForTheServer(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    Test.assert(!match.detailed(Player.OPPONENT, Ending.ACE, null));
    Test.assertEqual(match.engine.log().size(), 0);
    Test.assert(match.detailed(Player.ME, Ending.ACE, null));
    Test.assertEqual(match.score(), "0-0 0-0 15-0");
    match.play("MMM");
    Test.assert(!match.detailed(Player.ME, Ending.ACE, null));
    Test.assert(match.detailed(Player.OPPONENT, Ending.ACE, null));
    Test.assertEqual(match.score(), "0-0 1-0 0-15");
    return true;
}

(:test)
function testAceFollowsTheTieBreakRotation(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    Test.assert(match.detailed(Player.ME, Ending.ACE, null));
    Test.assert(!match.detailed(Player.ME, Ending.ACE, null));
    Test.assert(match.detailed(Player.OPPONENT, Ending.ACE, null));
    Test.assertEqual(match.score(), "0-0 0-0 1-1");
    return true;
}

(:test)
function testAceIsValidOnASecondServe(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("F");
    Test.assert(match.detailed(Player.ME, Ending.ACE, null));
    Test.assertEqual(match.score(), "0-0 0-0 15-0");
    return true;
}

(:test)
function testOtherEndingsAreAcceptedForBothPlayers(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    Test.assert(match.detailed(Player.OPPONENT, Ending.WINNER, null));
    Test.assert(match.detailed(Player.OPPONENT, Ending.ERROR_NET, null));
    Test.assert(match.detailed(Player.ME, Ending.ERROR_OUT, null));
    Test.assert(match.detailed(Player.ME, Ending.WINNER, null));
    Test.assertEqual(match.score(), "0-0 0-0 30-30");
    return true;
}

(:test)
function testFinishedMatchRejectsNewEntries(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.ONE_SET);
    match.games("MMMMMM");
    var entries = match.engine.log().size();
    Test.assert(!match.step('M'));
    Test.assert(!match.step('O'));
    Test.assert(!match.step('F'));
    Test.assert(!match.detailed(Player.ME, Ending.WINNER, 120));
    Test.assertEqual(match.engine.log().size(), entries);
    Test.assertEqual(match.score(), "1-0 0-0 0-0");
    return true;
}

(:test)
function testLogKeepsWhatTheCallerSupplied(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.engine.fault(12, 131);
    match.engine.point(Player.ME, Ending.WINNER, 20, 140);
    var log = match.engine.log();
    Test.assertEqual(log.size(), 2);
    Test.assert(PointEntry.isFault(log.at(0)));
    Test.assertEqual(PointEntry.time(log.at(0)), 12);
    Test.assertEqual(PointEntry.heartRate(log.at(0)) as Number, 131);
    Test.assertEqual(PointEntry.winner(log.at(1)), Player.ME);
    Test.assertEqual(PointEntry.ending(log.at(1)), Ending.WINNER);
    Test.assertEqual(PointEntry.time(log.at(1)), 20);
    Test.assertEqual(PointEntry.heartRate(log.at(1)) as Number, 140);
    return true;
}

(:test)
function testUndoOnAnEmptyLogDoesNothing(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    Test.assert(!match.engine.undo());
    Test.assertEqual(match.score(), "0-0 0-0 0-0");
    return true;
}

(:test)
function testUndoRemovesTheLastPoint(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    assertUndoRestores(match, "MO", "0-0 0-0 15-0");
    Test.assertEqual(match.engine.log().size(), 1);
    return true;
}

(:test)
function testUndoOfAFaultReturnsToTheFirstServe(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    assertUndoRestores(match, "MF", "0-0 0-0 15-0");
    Test.assert(!match.state().isSecondServe());
    return true;
}

(:test)
function testUndoOfADoubleFaultReturnsToTheSecondServe(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    assertUndoRestores(match, "FF", "0-0 0-0 0-0");
    Test.assert(match.state().isSecondServe());
    return true;
}

(:test)
function testUndoOfThePointAfterAFaultKeepsTheSecondServe(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    assertUndoRestores(match, "FM", "0-0 0-0 0-0");
    Test.assert(match.state().isSecondServe());
    return true;
}

(:test)
function testUndoAcrossAGameRestoresServerAndEnds(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    assertUndoRestores(match, "MMMM", "0-0 0-0 40-0");
    Test.assertEqual(match.state().server(), Player.ME);
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.NEAR);
    Test.assert(!match.state().isChangeOfEndsDue());
    return true;
}

(:test)
function testUndoOfTheFirstPointOfAGameReopensThePreviousOne(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    assertUndoRestores(match, "MMMMO", "0-0 1-0 0-0");
    Test.assert(match.state().isChangeOfEndsDue());
    Test.assert(match.engine.undo());
    Test.assertEqual(match.score(), "0-0 0-0 40-0");
    return true;
}

(:test)
function testUndoAcrossASetReopensIt(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MMMMM");
    assertUndoRestores(match, "MMMM", "0-0 5-0 40-0");
    Test.assertEqual(match.state().finishedSets(), 0);
    Test.assertEqual(match.state().server(), Player.OPPONENT);
    return true;
}

(:test)
function testUndoAtSixAllLeavesTheTieBreak(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    Test.assert(match.engine.undo());
    Test.assertEqual(match.score(), "0-0 6-5 0-40");
    Test.assert(!match.state().isTieBreak());
    Test.assertEqual(match.state().server(), Player.OPPONENT);
    return true;
}

(:test)
function testUndoInsideATieBreakRestoresServerAndEnds(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    assertUndoRestores(match, "M", "0-0 6-6 0-0");
    Test.assertEqual(match.state().server(), Player.ME);
    assertUndoRestores(match, "MMMOOO", "0-0 6-6 3-2");
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.NEAR);
    Test.assert(!match.state().isChangeOfEndsDue());
    Test.assertEqual(match.state().server(), Player.OPPONENT);
    return true;
}

(:test)
function testUndoAcrossTheEndOfATieBreakReopensIt(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    assertUndoRestores(match, "MMMMMMM", "0-0 6-6 6-0");
    Test.assert(match.state().isTieBreak());
    Test.assertEqual(match.state().finishedSets(), 0);
    Test.assert(match.state().hasSetPoint(Player.ME));
    return true;
}

(:test)
function testUndoOfTheLastPointReopensTheMatch(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.ONE_SET);
    match.games("MMMMM");
    assertUndoRestores(match, "MMMM", "0-0 5-0 40-0");
    Test.assert(!match.state().isFinished());
    Test.assertEqual(match.state().winner(), Player.NONE);
    Test.assert(match.step('M'));
    Test.assert(match.state().isFinished());
    return true;
}

(:test)
function testUndoAcrossTheEndOfAMatchTieBreak(logger as Test.Logger) as Boolean {
    var match = matchAtOneSetAll(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK);
    assertUndoRestores(match, "OOOOOOOOOO", "1-1 0-0 0-9");
    Test.assert(!match.state().isFinished());
    Test.assert(match.state().hasMatchPoint(Player.OPPONENT));
    return true;
}

(:test)
function testUndoOfEveryEntryReturnsToANewMatch(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MOFMFFOMMM");
    while (match.engine.undo()) {
    }
    Test.assertEqual(match.engine.log().size(), 0);
    Test.assertEqual(match.score(), "0-0 0-0 0-0");
    Test.assertEqual(match.state().server(), Player.ME);
    Test.assert(!match.state().isSecondServe());
    Test.assertEqual(match.state().endOf(Player.ME), CourtEnd.NEAR);
    return true;
}

(:test)
function testResumeFromAStoredLogRebuildsTheMatch(logger as Test.Logger) as Boolean {
    var match = new MatchDriver(MatchFormat.BEST_OF_3, true, Player.OPPONENT);
    match.games("MMMMMMOOM");
    match.play("MOOF");
    var stored = match.engine.log().toArray().slice(0, null);
    var config = new MatchConfig(MatchFormat.BEST_OF_3, true, Player.OPPONENT);
    var resumed = new MatchEngine(config, new PointLog(stored)).state();
    Test.assertEqual(resumed.sets(Player.ME), 1);
    Test.assertEqual(resumed.games(Player.ME), 1);
    Test.assertEqual(resumed.games(Player.OPPONENT), 2);
    Test.assertEqual(resumed.displayPoints(Player.OPPONENT), 30);
    Test.assert(resumed.isSecondServe());
    Test.assertEqual(resumed.server(), match.state().server());
    Test.assertEqual(resumed.endOf(Player.ME), match.state().endOf(Player.ME));
    return true;
}

(:test)
function testEntriesPastTheEndOfAStoredLogAreIgnored(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    match.play("MMMMMMM");
    var stored = match.engine.log().toArray().slice(0, null);
    stored.add(PointEntry.point(Player.OPPONENT, Ending.NONE, 500, null));
    stored.add(PointEntry.fault(510, null));
    var config = new MatchConfig(MatchFormat.TIE_BREAK_ONLY, false, Player.ME);
    var resumed = new MatchEngine(config, new PointLog(stored));
    Test.assert(resumed.state().isFinished());
    Test.assertEqual(resumed.state().winner(), Player.ME);
    Test.assertEqual(resumed.statistics().count(Stat.POINTS_WON, Player.OPPONENT), 0);
    Test.assertEqual(resumed.statistics().count(Stat.POINTS_WON, Player.ME), 7);
    return true;
}
