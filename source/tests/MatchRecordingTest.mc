import Toybox.Lang;
import Toybox.Test;

// Tests for what the controller does with the recorder and the stored
// match: heart rate, pause, laps, save, discard, closing and resuming.
module MatchRecordingTests {
    // The match of a bench as the app would find it at the next launch.
    function resumed(bench as MatchBench) as MatchBench {
        var next = simpleBench(MatchFormat.BEST_OF_3);
        next.memory = bench.memory;
        next.store = new MatchStore(next.memory);
        var stored = next.store.load() as Array;
        next.time.ms = 500000;
        next.session = new FakeSession();
        next.engine = new MatchEngine(bench.engine.config(), new PointLog(stored[1] as Array<Number>), stored[2] as Array< Array<Number> >);
        next.controller = next.controllerOn(next.engine, next.setupOf(MatchFormat.BEST_OF_3, false));
        return next;
    }

    (:test)
    function testMatchStartsTheRecordingWithIt(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        Test.assertEqual(bench.session.calls, "s");
        Test.assertEqual(bench.locator.calls, "+");
        return true;
    }

    (:test)
    function testEntriesCarryTheHeartRateOfTheMoment(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.play("M");
        bench.sensors.beats = 150;
        bench.play("FO");
        Test.assert(PointEntry.heartRate(bench.engine.log().at(0)) == null);
        Test.assertEqual(PointEntry.heartRate(bench.engine.log().at(1)) as Number, 150);
        Test.assertEqual(PointEntry.heartRate(bench.engine.log().at(2)) as Number, 150);
        Test.assertEqual(bench.controller.heartRate() as Number, 150);
        return true;
    }

    (:test)
    function testPauseStopsTheSessionAndResumeStartsIt(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.controller.togglePause();
        Test.assertEqual(bench.session.calls, "sp");
        bench.controller.togglePause();
        Test.assertEqual(bench.session.calls, "sps");
        return true;
    }

    (:test)
    function testTickKeepsTheStepsFieldCurrent(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.sensors.walk(100, 9000);
        bench.controller.tick();
        bench.sensors.walk(12, 1100);
        bench.controller.tick();
        Test.assertEqual(bench.session.fields[RecordingFields.STEPS] as Number, 12);
        Test.assertEqual(bench.session.fields[RecordingFields.DISTANCE] as Number, 11);
        return true;
    }

    (:test)
    function testEachSetButTheLastOpensALap(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.games("MMMMMM");
        Test.assertEqual(bench.session.calls, "sl");
        bench.games("OOOOOO");
        Test.assertEqual(bench.session.calls, "sll");
        bench.games("MMMMMM");
        Test.assertEqual(bench.session.calls, "sllp");
        return true;
    }

    (:test)
    function testEndingFromTheMenuStopsTheSession(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.controller.end();
        Test.assertEqual(bench.session.calls, "sp");
        bench.controller.reopen();
        Test.assertEqual(bench.session.calls, "sps");
        return true;
    }

    (:test)
    function testEveryEntryAndCorrectionReachesTheStore(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.store.begin([0, 0, 0, 0, 0]);
        bench.play("MFO");
        Test.assertEqual((bench.memory.values["set0"] as Array).size(), 3);
        bench.play("U");
        Test.assertEqual((bench.memory.values["set0"] as Array).size(), 2);
        bench.controller.awardGame(Player.ME);
        Test.assertEqual((bench.memory.values["set0"] as Array).size(), bench.engine.log().size());
        bench.controller.undoGame();
        Test.assertEqual((bench.memory.values["set0"] as Array).size(), 0);
        return true;
    }

    (:test)
    function testSaveKeepsTheActivityAndForgetsTheMatch(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.ONE_SET);
        bench.store.begin([2, 0, 0, 0, 0]);
        bench.games("MMMMMM");
        Test.assert(bench.controller.farewellKey() == null);
        bench.controller.save(new MatchTags(null));
        Test.assertEqual(bench.session.calls, "spS");
        Test.assertEqual(bench.locator.calls, "+-");
        Test.assertEqual(bench.controller.farewellKey() as Number, Str.SavedMsg);
        Test.assert(!bench.store.hasMatch());
        return true;
    }

    (:test)
    function testMatchOpensWithItsSetupInTheFile(logger as Test.Logger) as Boolean {
        var bench = new MatchBench(MatchFormat.ONE_SET, true);
        Test.assertEqual(bench.session.fields[RecordingFields.MATCH_SETUP] as Number, 1 + (2 << 4) + (1 << 8));
        Test.assertEqual(bench.session.fields[RecordingFields.FINAL_SCORE] as String, "0-0");
        Test.assert(bench.controller.isDetailed());
        Test.assert(!simpleBench(MatchFormat.ONE_SET).controller.isDetailed());
        return true;
    }

    (:test)
    function testSaveWritesTheSummaryWithTheTags(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.ONE_SET);
        bench.games("MMMMMM");
        bench.controller.save(new MatchTags([1, 2]));
        var counts = bench.session.fields[RecordingFields.STATISTICS] as Array<Number>;
        Test.assertEqual(bench.session.fields[RecordingFields.MATCH_SETUP] as Number,
                         1 + (2 << 4) + (1 << 10) + (2 << 12));
        Test.assertEqual(bench.session.fields[RecordingFields.FINAL_SCORE] as String, "6-0");
        Test.assertEqual(bench.session.numbers(RecordingFields.SET_SCORE), "6,0,0,0");
        Test.assertEqual(counts[Stat.POINTS_WON * Player.COUNT + Player.ME], 24);
        return true;
    }

    (:test)
    function testEachClosedSetGivesItsLapTheScore(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.games("MMMMMMOOOOOOMM");
        Test.assertEqual(joined(bench.session.lapScores), "6,0,0,0,0,6,0,0");
        bench.controller.end();
        bench.controller.save(new MatchTags(null));
        Test.assertEqual(bench.session.numbers(RecordingFields.SET_SCORE), "2,0,0,0");
        Test.assertEqual(bench.session.fields[RecordingFields.FINAL_SCORE] as String, "6-0 0-6 2-0");
        return true;
    }

    (:test)
    function testClosingTheAppWritesTheSummaryWithoutTags(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.games("MMO");
        bench.controller.suspend();
        Test.assertEqual(bench.session.fields[RecordingFields.MATCH_SETUP] as Number, 1);
        Test.assertEqual(bench.session.fields[RecordingFields.FINAL_SCORE] as String, "2-1");
        Test.assertEqual(bench.session.numbers(RecordingFields.SET_SCORE), "2,1,0,0");
        return true;
    }

    (:test)
    function testControllerHandsTheReportItsNumbers(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.games("MO");
        Test.assertEqual(bench.controller.statistics().count(Stat.POINTS_WON, Player.OPPONENT), 4);
        Test.assert(bench.controller.sensors() == bench.sensors);
        return true;
    }

    (:test)
    function testDiscardDropsTheActivityAndForgetsTheMatch(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.store.begin([0, 0, 0, 0, 0]);
        bench.play("MM");
        bench.controller.end();
        bench.controller.discard();
        Test.assertEqual(bench.session.calls, "spD");
        Test.assertEqual(bench.controller.farewellKey() as Number, Str.DiscardedMsg);
        Test.assertEqual(bench.memory.values.size(), 0);
        return true;
    }

    (:test)
    function testFarewellTextsExistInEveryLanguage(logger as Test.Logger) as Boolean {
        assertKeyInEveryLanguage(Str.SavedMsg);
        assertKeyInEveryLanguage(Str.DiscardedMsg);
        return true;
    }

    (:test)
    function testClosingTheAppSavesTheActivityAndKeepsAnOpenMatch(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.store.begin([0, 0, 0, 0, 0]);
        bench.play("MMO");
        bench.controller.suspend();
        bench.controller.suspend();
        Test.assertEqual(bench.session.calls, "spS");
        Test.assert(bench.store.hasMatch());
        return true;
    }

    (:test)
    function testClosingTheAppOnTheFinalScoreForgetsTheMatch(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.store.begin([0, 0, 0, 0, 0]);
        bench.play("M");
        bench.controller.end();
        bench.controller.suspend();
        Test.assertEqual(bench.session.calls, "spS");
        Test.assert(!bench.store.hasMatch());
        return true;
    }

    (:test)
    function testClosingTheAppAfterSaveOrDiscardDoesNothingMore(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.controller.end();
        bench.controller.discard();
        bench.controller.suspend();
        Test.assertEqual(bench.session.calls, "spD");
        return true;
    }

    (:test)
    function testResumeBringsBackTheScoreFromTheStoredLog(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.store.begin([0, 0, 0, 0, 0]);
        bench.games("MMMMMMOO");
        bench.play("MFFO");
        bench.controller.suspend();
        var next = resumed(bench);
        Test.assertEqual(next.score(), bench.score());
        Test.assertEqual(next.score(), "1-0 0-2 15-30");
        Test.assertEqual(next.session.calls, "s");
        next.play("O");
        Test.assertEqual(next.score(), "1-0 0-2 15-40");
        Test.assertEqual(resumed(next).score(), "1-0 0-2 15-40");
        return true;
    }

    (:test)
    function testResumedClockGoesOnFromTheLastEntry(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.store.begin([0, 0, 0, 0, 0]);
        bench.time.ms = 95000;
        bench.play("M");
        bench.time.ms = 300000;
        var next = resumed(bench);
        Test.assertEqual(next.controller.clockSeconds(), 95);
        next.time.ms += 5000;
        Test.assertEqual(next.controller.clockSeconds(), 100);
        return true;
    }

    // A set closed before the app did already has its lap in the first
    // activity; the new activity opens laps only for the sets after it.
    (:test)
    function testResumedMatchOpensLapsFromItsNextSet(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.BEST_OF_3);
        bench.store.begin([0, 0, 0, 0, 0]);
        bench.games("MMMMMMO");
        var next = resumed(bench);
        next.games("OOOOO");
        Test.assertEqual(next.score(), "1-1 0-0 0-0");
        Test.assertEqual(next.session.calls, "sl");
        return true;
    }

    (:test)
    function testResumedFinishedMatchWaitsStopped(logger as Test.Logger) as Boolean {
        var bench = simpleBench(MatchFormat.ONE_SET);
        bench.store.begin([2, 0, 0, 0, 0]);
        bench.games("MMMMMM");
        var next = simpleBench(MatchFormat.ONE_SET);
        var stored = new MatchStore(bench.memory).load() as Array;
        next.controller = next.controllerOn(
            new MatchEngine(bench.engine.config(), new PointLog(stored[1] as Array<Number>), stored[2] as Array< Array<Number> >), next.setupOf(MatchFormat.ONE_SET, false));
        Test.assert(next.controller.isOver());
        Test.assert(!next.controller.isPaused());
        return true;
    }
}
