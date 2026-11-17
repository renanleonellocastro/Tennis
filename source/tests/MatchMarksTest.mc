import Toybox.Lang;
import Toybox.Test;

// Tests for the marks of the engine: when one is taken, and that a match
// brought back from them is the match that was played.
module MatchMarksTests {
    const SIX_ALL = "MOMOMOMOMOMO";
    const NO_MARKS = [] as Array< Array<Number> >;

    // Everything the engine derives from the log, as one line.
    function picture(engine as MatchEngine) as String {
        return joinedNumbers(engine.state().toArray()) + " | " + joinedNumbers(engine.statistics().snapshot())
            + " | " + joinedNumbers(engine.slots()) + " | " + engine.gameStart() + " | " + engine.marks().size();
    }

    function copyOf(engine as MatchEngine, marks as Array< Array<Number> >) as MatchEngine {
        return new MatchEngine(engine.config(), new PointLog(engine.log().toArray().slice(0, null)), marks);
    }

    function fromTheStart(engine as MatchEngine) as MatchEngine {
        return copyOf(engine, [] as Array< Array<Number> >);
    }

    (:test)
    function testListKeepsTheMarksUpToASize(logger as Test.Logger) as Boolean {
        var marks = [[48, 44], [96, 92]] as Array< Array<Number> >;
        Test.assertEqual(MatchMarks.upTo(marks, 200).size(), 2);
        Test.assertEqual(MatchMarks.upTo(marks, 96).size(), 2);
        Test.assertEqual(MatchMarks.upTo(marks, 95).size(), 1);
        Test.assertEqual(MatchMarks.upTo(marks, 47).size(), 0);
        Test.assertEqual(MatchMarks.upTo(NO_MARKS, 5).size(), 0);
        return true;
    }

    (:test)
    function testListFindsTheNewestMarkUpToASize(logger as Test.Logger) as Boolean {
        var marks = [[48, 44], [96, 92]] as Array< Array<Number> >;
        Test.assertEqual((MatchMarks.newestUpTo(marks, 100) as Array<Number>)[0], 96);
        Test.assertEqual((MatchMarks.newestUpTo(marks, 95) as Array<Number>)[0], 48);
        Test.assert(MatchMarks.newestUpTo(marks, 47) == null);
        Test.assert(MatchMarks.newestUpTo(NO_MARKS, 47) == null);
        Test.assertEqual(MatchMarks.newestIndex(marks), 96);
        Test.assertEqual(MatchMarks.newestIndex(NO_MARKS), 0);
        return true;
    }

    (:test)
    function testMarkIsTakenWhenAGameClosesAfterTheSpacing(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("MOMOMOMOMOM");
        Test.assertEqual(match.engine.marks().size(), 0);
        match.games("O");
        Test.assertEqual(match.engine.marks().size(), 1);
        var mark = match.engine.marks()[0];
        Test.assertEqual(mark[0], MatchEngine.MARK_SPACING);
        Test.assertEqual(mark[1], 44);
        Test.assertEqual(mark.size(), 2 + Stat.SIZE + match.state().toArray().size());
        return true;
    }

    (:test)
    function testMarkWaitsForTheGameToClose(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("MOMOMOMOMOM");
        match.play("MOMOMO");
        Test.assertEqual(match.engine.log().size(), 50);
        Test.assertEqual(match.engine.marks().size(), 0);
        match.play("MM");
        Test.assertEqual(match.engine.marks()[0][0], 52);
        match.games(SIX_ALL.substring(0, 11) as String);
        Test.assertEqual(match.engine.marks().size(), 1);
        return true;
    }

    // The game that ends the match takes no mark: nothing comes after it.
    (:test)
    function testNoMarkWhenTheMatchEnds(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.ONE_SET);
        match.games("MMMMM");
        match.play("MOMOMOMOMOMOMOMOMOMOMOMOMOMOMO");
        Test.assertEqual(match.engine.log().size(), 50);
        match.play("MM");
        Test.assert(match.state().isFinished());
        Test.assertEqual(match.engine.marks().size(), 0);
        return true;
    }

    (:test)
    function testUndoGoesBackOverAMark(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        match.play("M");
        match.engine.undo();
        Test.assertEqual(match.engine.marks().size(), 1);
        Test.assertEqual(picture(match.engine), picture(fromTheStart(match.engine)));
        match.engine.undo();
        Test.assertEqual(match.engine.marks().size(), 0);
        Test.assertEqual(match.score(), "0-0 6-5 0-40");
        Test.assertEqual(picture(match.engine), picture(fromTheStart(match.engine)));
        match.play("O");
        Test.assertEqual(match.engine.marks().size(), 1);
        return true;
    }

    (:test)
    function testUndoneGameAtAMarkGoesToTheGameBefore(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        Test.assertEqual(match.engine.gameStart(), 44);
        match.play("MO");
        Test.assertEqual(match.engine.gameStart(), 48);
        Test.assert(ScoreFixer.undoGame(match.engine));
        Test.assertEqual(match.engine.gameStart(), 44);
        Test.assert(ScoreFixer.undoGame(match.engine));
        Test.assertEqual(match.engine.gameStart(), 40);
        Test.assertEqual(match.score(), "0-0 6-5 0-0");
        return true;
    }

    (:test)
    function testMatchFromItsMarksIsTheMatchPlayed(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        match.play("MMOMMMMM");
        match.games("OMOMOMOMOMO");
        match.play("OOF");
        var played = picture(match.engine);
        Test.assertEqual(match.engine.marks().size(), 2);
        Test.assertEqual(picture(copyOf(match.engine, match.engine.marks().slice(0, null))), played);
        Test.assertEqual(picture(fromTheStart(match.engine)), played);
        return true;
    }

    (:test)
    function testMarksPastTheEndOfTheLogAreLeftOut(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        var marks = match.engine.marks().slice(0, null);
        match.engine.truncate(10);
        var again = copyOf(match.engine, marks);
        Test.assertEqual(again.marks().size(), 0);
        Test.assertEqual(picture(again), picture(match.engine));
        return true;
    }

    (:test)
    function testStateComesBackFromItsArray(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        match.play("MMOMMMMM");
        match.games(SIX_ALL);
        var values = match.state().toArray();
        Test.assertEqual(joinedNumbers(values.slice(0, 5)), "6,6,1,0,25");
        Test.assertEqual(joinedNumbers(values.slice(7, null)), "7,6,7,1");
        var state = new MatchState(match.engine.config());
        state.restore(values);
        Test.assertEqual(joinedNumbers(state.toArray()), joinedNumbers(values));
        Test.assert(state.isTieBreak());
        Test.assertEqual(state.server(), match.state().server());
        Test.assertEqual(state.setTieBreakPoints(0, Player.OPPONENT), 1);
        return true;
    }

    (:test)
    function testStateArrayKeepsAChangeOfEndsThatIsDue(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("M");
        var state = new MatchState(match.engine.config());
        state.restore(match.state().toArray());
        Test.assert(state.isChangeOfEndsDue());
        Test.assert(!state.isTieBreak());
        Test.assertEqual(state.games(Player.ME), 1);
        return true;
    }

    (:test)
    function testStoreKeepsTheMarksWithTheLog(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        store.begin([1, 0, 1, 0, 0]);
        store.sync([1, 2], 0, NO_MARKS);
        Test.assertEqual(memory.writes, 2);
        store.sync([1, 2, 3], 0, [[3, 0, 9]] as Array< Array<Number> >);
        Test.assertEqual(memory.writes, 4);
        store.sync([1, 2, 3, 4], 0, [[3, 0, 9]] as Array< Array<Number> >);
        Test.assertEqual(memory.writes, 5);
        var stored = new MatchStore(memory).load() as Array;
        Test.assertEqual(joinedNumbers((stored[2] as Array< Array<Number> >)[0]), "3,0,9");
        return true;
    }

    (:test)
    function testStoreWritesTheMarksAgainWhenOneGoes(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        memory.put("match", [1, [1, 0, 1, 0, 0]]);
        memory.put("set0", [1, 2, 3]);
        memory.put("marks", [[3, 0, 9]]);
        var store = new MatchStore(memory);
        store.load();
        store.sync([1, 2, 3], 0, [[3, 0, 9]] as Array< Array<Number> >);
        Test.assertEqual(memory.writes, 4);
        store.sync([1, 2], 0, NO_MARKS);
        Test.assertEqual((memory.get("marks") as Array).size(), 0);
        store.clear();
        Test.assertEqual(memory.values.size(), 0);
        return true;
    }

    (:test)
    function testStoreReadsNoMarksFromAValueThatIsNotAList(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        store.begin([1, 0, 1, 0, 0]);
        Test.assertEqual(((store.load() as Array)[2] as Array).size(), 0);
        return true;
    }
}
