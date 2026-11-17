import Toybox.Lang;
import Toybox.Test;

// Tests for cutting the log back and for the corrections of fix the score.
module ScoreFixerTests {
    (:test)
    function testTruncateCutsTheLogAndReplays(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play("MMMMOO");
        Test.assert(match.engine.truncate(4));
        Test.assertEqual(match.engine.log().size(), 4);
        Test.assertEqual(match.score(), "0-0 1-0 0-0");
        Test.assert(match.engine.truncate(0));
        Test.assertEqual(match.score(), "0-0 0-0 0-0");
        return true;
    }

    (:test)
    function testTruncateRefusesWhatRemovesNothing(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        Test.assert(!match.engine.truncate(0));
        Test.assert(!match.engine.truncate(-1));
        match.play("MO");
        Test.assert(!match.engine.truncate(2));
        Test.assert(!match.engine.truncate(3));
        Test.assertEqual(match.engine.log().size(), 2);
        return true;
    }

    (:test)
    function testEngineExposesItsConfig(logger as Test.Logger) as Boolean {
        var match = new MatchDriver(MatchFormat.PRO_SET, true, Player.OPPONENT);
        Test.assertEqual(match.engine.config().gamesPerSet(), 8);
        Test.assertEqual(match.engine.config().serverAt(0), Player.OPPONENT);
        return true;
    }

    (:test)
    function testUndoGameRemovesTheGameInProgress(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play("MMMMOFO");
        Test.assertEqual(match.engine.gameStart(), 4);
        Test.assert(ScoreFixer.undoGame(match.engine));
        Test.assertEqual(match.engine.log().size(), 4);
        Test.assertEqual(match.score(), "0-0 1-0 0-0");
        return true;
    }

    (:test)
    function testUndoGameRemovesThePreviousGameWhenNoneIsInProgress(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("MO");
        Test.assertEqual(match.engine.gameStart(), 4);
        Test.assert(ScoreFixer.undoGame(match.engine));
        Test.assertEqual(match.score(), "0-0 1-0 0-0");
        Test.assert(ScoreFixer.undoGame(match.engine));
        Test.assertEqual(match.score(), "0-0 0-0 0-0");
        Test.assert(!ScoreFixer.undoGame(match.engine));
        return true;
    }

    (:test)
    function testUndoGameReopensAFinishedSetAndMatch(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("MMMMMM");
        Test.assert(ScoreFixer.undoGame(match.engine));
        Test.assertEqual(match.score(), "0-0 5-0 0-0");
        match.games("MMMMMMM");
        Test.assert(match.state().isFinished());
        Test.assert(ScoreFixer.undoGame(match.engine));
        Test.assertEqual(match.score(), "1-0 5-0 0-0");
        return true;
    }

    (:test)
    function testAwardGameLogsPointsUntilTheGameCloses(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play("OOO");
        Test.assert(ScoreFixer.awardGame(match.engine, Player.ME, 70));
        Test.assertEqual(match.score(), "0-0 1-0 0-0");
        Test.assertEqual(match.engine.log().size(), 8);
        Test.assertEqual(PointEntry.time(match.engine.log().at(7)), 70);
        Test.assert(ScoreFixer.awardGame(match.engine, Player.OPPONENT, 80));
        Test.assertEqual(match.score(), "0-0 1-1 0-0");
        return true;
    }

    (:test)
    function testAwardGameClosesATieBreakAndTheSet(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        match.play("OOO");
        Test.assert(ScoreFixer.awardGame(match.engine, Player.ME, 0));
        Test.assertEqual(match.score(), "1-0 0-0 0-0");
        Test.assertEqual(match.state().setTieBreakPoints(0, Player.ME), 7);
        return true;
    }

    (:test)
    function testAwardGameCanEndTheMatchAndThenRefuses(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.ONE_SET);
        match.games("MMMMM");
        Test.assert(ScoreFixer.awardGame(match.engine, Player.ME, 0));
        Test.assert(match.state().isFinished());
        var size = match.engine.log().size();
        Test.assert(!ScoreFixer.awardGame(match.engine, Player.ME, 0));
        Test.assertEqual(match.engine.log().size(), size);
        return true;
    }

    (:test)
    function testGamesPlayedCountsEverySet(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        Test.assertEqual(ScoreFixer.gamesPlayed(match.state()), 0);
        match.games("MMMMMMO");
        match.play("MM");
        Test.assertEqual(ScoreFixer.gamesPlayed(match.state()), 7);
        return true;
    }
}
