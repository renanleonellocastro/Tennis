import Toybox.Lang;
import Toybox.Test;

// Tests for the point log as the activity file carries it: the three words
// of an entry, the newest three entries the engine keeps, and when the
// controller hands them to the recording.
module PointSlotTests {
    // The sequence numbers of the three slots, newest first: "3,2,1".
    function sequences(slots as Array<Number>) as String {
        return joinedNumbers([slots[0] & 0xFFFF, slots[3] & 0xFFFF, slots[6] & 0xFFFF]);
    }

    function fieldOf(bench as MatchBench) as Array<Number> {
        return bench.session.fields[RecordingFields.POINT_LOG] as Array<Number>;
    }

    (:test)
    function testHeaderSaysWhoServedAndHow(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        Test.assertEqual(PointSlot.header(1, match.state()), 1);
        match.play("F");
        Test.assertEqual(PointSlot.header(2, match.state()), 2 + 0x20000);
        match.play("MMMM");
        Test.assertEqual(PointSlot.header(6, match.state()), 6 + 0x10000);
        Test.assertEqual(PointSlot.header(0x10005, match.state()), 5 + 0x10000);
        Test.assertEqual(PointSlot.header(9, matchAtSixAll(MatchFormat.BEST_OF_3).state()), 9 + 0x40000);
        return true;
    }

    (:test)
    function testScoreCountsPointsGamesAndSets(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play("MMOMOO");
        Test.assertEqual(PointSlot.score(match.state()), 3 + (3 << 7));
        match.play("OO");
        Test.assertEqual(PointSlot.score(match.state()), 1 << 18);
        match.games("MMMMMM");
        Test.assertEqual(PointSlot.score(match.state()), 1 << 22);
        match.games("OOOOOOM");
        match.play("O");
        Test.assertEqual(PointSlot.score(match.state()), (1 << 7) + (1 << 14) + (1 << 22) + (1 << 24));
        return true;
    }

    (:test)
    function testScoreStopsCountingPointsAt127(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        for (var i = 0; i < 130; i++) {
            match.play("MO");
        }
        Test.assertEqual(match.state().points(Player.ME), 130);
        Test.assertEqual(PointSlot.score(match.state()), 127 + (127 << 7) + (6 << 14) + (6 << 18));
        return true;
    }

    (:test)
    function testNewestEntryGoesInFrontAndTheOldestDropsOut(logger as Test.Logger) as Boolean {
        var field = PointSlot.pushed(PointSlot.none(), [1, 2, 3]);
        Test.assertEqual(joinedNumbers(field), "1,2,3,0,0,0,0,0,0");
        field = PointSlot.pushed(PointSlot.pushed(field, [4, 5, 6]), [7, 8, 9]);
        Test.assertEqual(joinedNumbers(field), "7,8,9,4,5,6,1,2,3");
        Test.assertEqual(joinedNumbers(PointSlot.pushed(field, [10, 11, 12])), "10,11,12,7,8,9,4,5,6");
        return true;
    }

    // The example of docs/DATA_FORMAT.md: I serve and win three points.
    (:test)
    function testEngineKeepsTheSlotsOfTheDocumentedExample(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        Test.assertEqual(joinedNumbers(match.engine.slots()), "0,0,0,0,0,0,0,0,0");
        match.clock = 10;
        match.detailed(Player.ME, Ending.NONE, 120);
        match.clock = 30;
        match.detailed(Player.ME, Ending.NONE, 121);
        match.clock = 50;
        match.detailed(Player.ME, Ending.NONE, 122);
        Test.assertEqual(joinedNumbers(match.engine.slots()),
                         joinedNumbers([3, 0x00078F41, 3, 2, 0x00050F21, 2, 1, 0x00028F01, 1]));
        return true;
    }

    (:test)
    function testSlotsHoldTheStateBeforeAndTheScoreAfter(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play("MMMFF");
        var slots = match.engine.slots();
        Test.assertEqual(sequences(slots), "5,4,3");
        Test.assertEqual(slots[0], 5 + 0x20000);
        Test.assertEqual(slots[1], match.engine.log().at(4));
        Test.assertEqual(slots[2], 3 + (1 << 7));
        Test.assertEqual(slots[3], 4);
        Test.assertEqual(slots[5], 3);
        match.play("M");
        Test.assertEqual(match.engine.slots()[2], 1 << 14);
        return true;
    }

    (:test)
    function testUndoLowersTheNewestSequenceNumber(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.play("MOMOM");
        var before = joinedNumbers(match.engine.slots());
        match.play("O");
        Test.assertEqual(sequences(match.engine.slots()), "6,5,4");
        match.engine.undo();
        Test.assertEqual(joinedNumbers(match.engine.slots()), before);
        match.engine.truncate(1);
        Test.assertEqual(sequences(match.engine.slots()), "1,0,0");
        match.engine.undo();
        Test.assertEqual(joinedNumbers(match.engine.slots()), "0,0,0,0,0,0,0,0,0");
        return true;
    }

    (:test)
    function testStoredLogGivesTheSameSlotsAgain(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        match.play("MFOFFM");
        var again = new MatchEngine(match.engine.config(), new PointLog(match.engine.log().toArray()));
        Test.assertEqual(joinedNumbers(again.slots()), joinedNumbers(match.engine.slots()));
        Test.assertEqual(sequences(again.slots()), "54,53,52");
        return true;
    }

    // Entries a damaged stored log holds after the end of the match are
    // not played, so they are not in the file either.
    (:test)
    function testEntriesPastTheEndOfTheMatchGetNoSlot(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
        match.play("MMMMMMM");
        var entries = match.engine.log().toArray().slice(0, null);
        entries.addAll([entries[0], entries[0], entries[0], entries[0]]);
        var again = new MatchEngine(match.engine.config(), new PointLog(entries));
        Test.assert(again.state().isFinished());
        Test.assertEqual(again.state().setTieBreakPoints(0, Player.ME), 7);
        Test.assertEqual(joinedNumbers(again.slots()), "0,0,0,0,0,0,0,0,0");
        return true;
    }

    (:test)
    function testEveryEntryAndCorrectionReachesTheFile(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(joinedNumbers(fieldOf(bench)), "0,0,0,0,0,0,0,0,0");
        bench.play("MF");
        Test.assertEqual(sequences(fieldOf(bench)), "2,1,0");
        bench.play("U");
        Test.assertEqual(sequences(fieldOf(bench)), "1,0,0");
        bench.controller.awardGame(Player.OPPONENT);
        Test.assertEqual(sequences(fieldOf(bench)), "5,4,3");
        bench.controller.undoGame();
        Test.assertEqual(joinedNumbers(fieldOf(bench)), "0,0,0,0,0,0,0,0,0");
        return true;
    }

    // The watch writes a record when the session starts and when it stops,
    // so the entries must be in the field before both.
    (:test)
    function testEntryThatEndsTheMatchIsInTheRecordOfTheStop(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.TIE_BREAK_ONLY);
        bench.play("MMMMMMM");
        Test.assertEqual(bench.session.calls, "sp");
        Test.assertEqual(joinedNumbers(bench.session.records), "0,7");
        bench.controller.reopen();
        Test.assertEqual(joinedNumbers(bench.session.records), "0,7,6");
        bench.controller.togglePause();
        bench.controller.awardGame(Player.ME);
        Test.assertEqual(joinedNumbers(bench.session.records), "0,7,6,6");
        Test.assertEqual(sequences(fieldOf(bench)), "7,6,5");
        return true;
    }

    (:test)
    function testResumedMatchRepeatsTheNewestEntriesInItsFirstRecord(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.store.begin([0, 0, 0, 0, 0]);
        bench.play("MOFM");
        bench.controller.suspend();
        Test.assertEqual(bench.session.fields[RecordingFields.LOG_SIZE] as Number, 4);
        var next = MatchRecordingTests.resumed(bench);
        Test.assertEqual(joinedNumbers(next.session.records), "4");
        Test.assertEqual(joinedNumbers(fieldOf(next)), joinedNumbers(fieldOf(bench)));
        Test.assertEqual(next.session.fields[RecordingFields.LOG_SIZE] as Number, 4);
        next.play("O");
        next.controller.end();
        next.controller.save(new MatchTags(null));
        Test.assertEqual(sequences(fieldOf(next)), "5,4,3");
        Test.assertEqual(next.session.fields[RecordingFields.LOG_SIZE] as Number, 5);
        return true;
    }

    (:test)
    function testRecorderWritesThePointLogField(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        new MatchRecorder(session, new FakeSensors(), new FakeLocator()).writePointLog([4, 5, 6, 1, 2, 3, 0, 0, 0]);
        Test.assertEqual(session.numbers(RecordingFields.POINT_LOG), "4,5,6,1,2,3,0,0,0");
        return true;
    }

    (:test)
    function testPointLogFieldsAreARecordAndASessionField(logger as Test.Logger) as Boolean {
        var log = RecordingFields.TABLE[0] as Array;
        var size = RecordingFields.TABLE[1] as Array;
        Test.assertEqual(log[2] as Number, RecordingFields.RECORD);
        Test.assertEqual(log[5] as Number, PointSlot.SLOTS * PointSlot.WORDS);
        Test.assertEqual(size[2] as Number, RecordingFields.SESSION);
        Test.assert(!RecordingFields.isOfKind(log, RecordingFields.PRACTICE));
        return true;
    }

    // A match that stops right after a set has no open set to show.

    (:test)
    function testScoreTextLeavesOutASetThatNeverStarted(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        Test.assertEqual(MatchSummary.scoreText(match.state()), "0-0");
        match.games("MMMMMOM");
        Test.assert(!MatchSummary.hasOpenSet(match.state()));
        Test.assertEqual(MatchSummary.scoreText(match.state()), "6-1");
        Test.assertEqual(MatchPresenter.finalSetsText(match.state()), "6-1");
        Test.assertEqual(MatchPresenter.setsText(match.state()), "6-1  0-0");
        match.play("F");
        Test.assertEqual(MatchSummary.scoreText(match.state()), "6-1");
        match.play("F");
        Test.assert(MatchSummary.hasOpenSet(match.state()));
        Test.assertEqual(MatchSummary.scoreText(match.state()), "6-1 0-0");
        Test.assertEqual(MatchPresenter.finalSetsText(match.state()), "6-1  0-0");
        return true;
    }

    (:test)
    function testReportHasNoRowForASetThatNeverStarted(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("MMMMMOM");
        var rows = new ReportPresenter(match.state(), match.statistics()).pages(false, 0, new FakeSensors())[0][1] as Array;
        Test.assertEqual(rows.size(), 2);
        match.games("O");
        rows = new ReportPresenter(match.state(), match.statistics()).pages(false, 0, new FakeSensors())[0][1] as Array;
        Test.assertEqual(rows.size(), 3);
        match.games("OOOOOMMMMMM");
        Test.assert(match.state().isFinished());
        Test.assert(!MatchSummary.hasOpenSet(match.state()));
        Test.assertEqual(MatchPresenter.finalSetsText(match.state()), "6-1  0-6  6-0");
        return true;
    }

    (:test)
    function testStoredScoreOfAMatchStoppedAfterASetIsThatSet(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.games("MMMMMOM");
        bench.controller.end();
        bench.controller.save(new MatchTags(null));
        Test.assertEqual(bench.session.fields[RecordingFields.FINAL_SCORE] as String, "6-1");
        Test.assertEqual(bench.session.fields[RecordingFields.LOG_SIZE] as Number, 28);
        return true;
    }
}
