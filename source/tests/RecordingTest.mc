import Toybox.FitContributor;
import Toybox.Lang;
import Toybox.Test;

// Tests for the steps and distance counting and for the recorder that
// drives the activity session.
module RecordingTests {
    function recorderOn(session as FakeSession, sensors as FakeSensors, locator as FakeLocator) as MatchRecorder {
        return new MatchRecorder(session, sensors, locator);
    }

    (:test)
    function testTrackerCountsOnlyTheChangeSinceItsFirstReading(logger as Test.Logger) as Boolean {
        var tracker = new MotionTracker();
        tracker.update(5000, 400000);
        Test.assertEqual(tracker.steps(), 0);
        Test.assertEqual(tracker.meters(), 0);
        tracker.update(5040, 403250);
        Test.assertEqual(tracker.steps(), 40);
        Test.assertEqual(tracker.meters(), 32);
        return true;
    }

    (:test)
    function testTrackerSkipsAMissingReading(logger as Test.Logger) as Boolean {
        var tracker = new MotionTracker();
        tracker.update(null, null);
        tracker.update(100, null);
        tracker.update(null, 1000);
        tracker.update(130, 1500);
        Test.assertEqual(tracker.steps(), 30);
        Test.assertEqual(tracker.meters(), 5);
        return true;
    }

    (:test)
    function testTrackerCountsANewDayFromZero(logger as Test.Logger) as Boolean {
        var tracker = new MotionTracker();
        tracker.update(9000, 700000);
        tracker.update(9010, 700800);
        tracker.update(12, 900);
        Test.assertEqual(tracker.steps(), 22);
        Test.assertEqual(tracker.meters(), 17);
        return true;
    }

    (:test)
    function testTrackerLeavesThePauseOut(logger as Test.Logger) as Boolean {
        var tracker = new MotionTracker();
        tracker.update(100, 0);
        tracker.pause();
        tracker.update(300, 20000);
        tracker.resume();
        tracker.update(310, 20500);
        Test.assertEqual(tracker.steps(), 10);
        Test.assertEqual(tracker.meters(), 5);
        return true;
    }

    (:test)
    function testTrackerStartsEachLapFromZero(logger as Test.Logger) as Boolean {
        var tracker = new MotionTracker();
        tracker.update(0, 0);
        tracker.update(50, 4000);
        Test.assertEqual(tracker.lapSteps(), 50);
        Test.assertEqual(tracker.lapMeters(), 40);
        tracker.closeLap();
        tracker.update(70, 5000);
        Test.assertEqual(tracker.lapSteps(), 20);
        Test.assertEqual(tracker.lapMeters(), 10);
        Test.assertEqual(tracker.steps(), 70);
        return true;
    }

    (:test)
    function testRecorderStartsTheSessionAndTheGps(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var locator = new FakeLocator();
        recorderOn(session, new FakeSensors(), locator).start(0, false);
        Test.assertEqual(session.calls, "s");
        Test.assertEqual(locator.calls, "+");
        Test.assertEqual(session.fields[RecordingFields.STEPS] as Number, 0);
        return true;
    }

    (:test)
    function testRecorderPausesAndResumesOnlyOnce(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var recorder = recorderOn(session, new FakeSensors(), new FakeLocator());
        recorder.pause();
        recorder.start(0, false);
        recorder.resume();
        recorder.pause();
        recorder.pause();
        recorder.resume();
        Test.assertEqual(session.calls, "sps");
        return true;
    }

    (:test)
    function testRecorderWritesStepsAndMetersOnEachSample(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var sensors = new FakeSensors();
        var recorder = recorderOn(session, sensors, new FakeLocator());
        sensors.walk(1000, 80000);
        recorder.start(0, false);
        sensors.walk(25, 1900);
        recorder.sample();
        Test.assertEqual(session.fields[RecordingFields.STEPS] as Number, 25);
        Test.assertEqual(session.fields[RecordingFields.DISTANCE] as Number, 19);
        Test.assertEqual(session.fields[RecordingFields.SET_STEPS] as Number, 25);
        Test.assertEqual(session.fields[RecordingFields.SET_DISTANCE] as Number, 19);
        return true;
    }

    (:test)
    function testRecorderDoesNotCountStepsWalkedInAPause(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var sensors = new FakeSensors();
        var recorder = recorderOn(session, sensors, new FakeLocator());
        sensors.walk(10, 1000);
        recorder.start(0, false);
        sensors.walk(5, 500);
        recorder.pause();
        sensors.walk(200, 20000);
        recorder.resume();
        sensors.walk(3, 300);
        recorder.sample();
        Test.assertEqual(session.fields[RecordingFields.STEPS] as Number, 8);
        Test.assertEqual(session.fields[RecordingFields.DISTANCE] as Number, 8);
        return true;
    }

    (:test)
    function testRecorderOpensALapForEachClosedSetButTheLast(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var sensors = new FakeSensors();
        var recorder = recorderOn(session, sensors, new FakeLocator());
        sensors.walk(0, 0);
        recorder.start(0, false);
        recorder.closeSets(0, false, [6, 4, 0, 0]);
        sensors.walk(60, 5000);
        recorder.closeSets(1, false, [6, 4, 0, 0]);
        recorder.closeSets(1, false, [6, 4, 0, 0]);
        sensors.walk(40, 3000);
        recorder.closeSets(2, true, [6, 4, 0, 0]);
        Test.assertEqual(session.calls, "sl");
        Test.assertEqual(session.laps[0][0], 60);
        Test.assertEqual(session.laps[0][1], 50);
        Test.assertEqual(session.fields[RecordingFields.SET_STEPS] as Number, 0);
        return true;
    }

    (:test)
    function testRecorderOpensNoLapForSetsClosedBeforeItStarted(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var recorder = recorderOn(session, new FakeSensors(), new FakeLocator());
        recorder.start(1, false);
        recorder.closeSets(1, false, [6, 4, 0, 0]);
        Test.assertEqual(session.calls, "s");
        recorder.closeSets(2, false, [6, 4, 0, 0]);
        Test.assertEqual(session.calls, "sl");
        return true;
    }

    (:test)
    function testRecorderKeepsTheFirstLapOfASetPlayedAgain(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var recorder = recorderOn(session, new FakeSensors(), new FakeLocator());
        recorder.start(0, false);
        recorder.closeSets(1, false, [6, 4, 0, 0]);
        recorder.closeSets(0, false, [6, 4, 0, 0]);
        recorder.closeSets(1, false, [6, 4, 0, 0]);
        Test.assertEqual(session.calls, "sl");
        return true;
    }

    (:test)
    function testRecorderSavesWithTheLastReadingAndTheGpsOff(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var sensors = new FakeSensors();
        var locator = new FakeLocator();
        var recorder = recorderOn(session, sensors, locator);
        sensors.walk(0, 0);
        recorder.start(0, false);
        sensors.walk(7, 900);
        recorder.save();
        Test.assertEqual(session.calls, "spS");
        Test.assertEqual(locator.calls, "+-");
        Test.assertEqual(session.fields[RecordingFields.STEPS] as Number, 7);
        return true;
    }

    (:test)
    function testRecorderDiscardsAPausedSessionWithoutStoppingItAgain(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var recorder = recorderOn(session, new FakeSensors(), new FakeLocator());
        recorder.start(0, false);
        recorder.pause();
        recorder.discard();
        Test.assertEqual(session.calls, "spD");
        return true;
    }

    (:test)
    function testRecorderReadsTheHeartRateOfTheWatch(logger as Test.Logger) as Boolean {
        var sensors = new FakeSensors();
        var recorder = recorderOn(new FakeSession(), sensors, new FakeLocator());
        Test.assert(recorder.heartRate() == null);
        sensors.beats = 131;
        Test.assertEqual(recorder.heartRate() as Number, 131);
        return true;
    }

    (:test)
    function testFieldTableUsesTheIdsSharedWithTheConverter(logger as Test.Logger) as Boolean {
        var names = {2 => "match_setup", 3 => "final_score", 4 => "statistics", 5 => "steps", 6 => "distance",
                     7 => "set_score", 8 => "set_steps", 9 => "set_distance",
                     10 => "block_hits", 11 => "block_misses"};
        Test.assertEqual(RecordingFields.TABLE.size(), names.size());
        for (var i = 0; i < RecordingFields.TABLE.size(); i++) {
            var row = RecordingFields.TABLE[i] as Array;
            Test.assertEqual(row[1] as String, names[row[0] as Number] as String);
        }
        return true;
    }

    (:test)
    function testFieldsStartEmptyInTheShapeOfTheirType(logger as Test.Logger) as Boolean {
        Test.assertEqual(RecordingFields.emptyValue(FitContributor.DATA_TYPE_STRING, 32) as String, "");
        Test.assertEqual(RecordingFields.emptyValue(FitContributor.DATA_TYPE_UINT32, 1) as Number, 0);
        Test.assertEqual(joinedNumbers(RecordingFields.emptyValue(FitContributor.DATA_TYPE_UINT8, 4) as Array<Number>),
                         "0,0,0,0");
        Test.assertEqual(RecordingFields.zeros(30).size(), 30);
        return true;
    }

    (:test)
    function testRecorderGivesTheClosingLapTheScoreOfItsSet(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var recorder = recorderOn(session, new FakeSensors(), new FakeLocator());
        recorder.start(0, false);
        recorder.closeSets(1, false, [6, 4, 0, 0]);
        recorder.closeSets(1, false, [1, 1, 1, 1]);
        recorder.closeSets(2, false, [6, 7, 5, 7]);
        Test.assertEqual(joined(session.lapScores), "6,4,0,0,6,7,5,7");
        return true;
    }

    (:test)
    function testRecorderWritesTheSummaryFields(logger as Test.Logger) as Boolean {
        var session = new FakeSession();
        var sensors = new FakeSensors();
        var recorder = recorderOn(session, sensors, new FakeLocator());
        recorder.writeSummary([33, "6-4 2-1", [1, 2, 3], [2, 1, 0, 0]]);
        Test.assertEqual(session.fields[RecordingFields.MATCH_SETUP] as Number, 33);
        Test.assertEqual(session.fields[RecordingFields.FINAL_SCORE] as String, "6-4 2-1");
        Test.assertEqual(session.numbers(RecordingFields.STATISTICS), "1,2,3");
        Test.assertEqual(session.numbers(RecordingFields.SET_SCORE), "2,1,0,0");
        Test.assert(recorder.sensors() == sensors);
        return true;
    }

    // The real edges, on the watch the tests run on.

    (:test)
    function testWatchSensorsAnswerWithANumberOrNothing(logger as Test.Logger) as Boolean {
        var sensors = new WatchSensors();
        var readings = [sensors.heartRate(), sensors.steps(), sensors.distanceCm(), sensors.averageHeartRate(),
                        sensors.maxHeartRate(), sensors.calories()];
        for (var i = 0; i < readings.size(); i++) {
            Test.assert(readings[i] == null || readings[i] instanceof Lang.Number);
        }
        return true;
    }

    (:test)
    function testGpsTurnsOnAndOffWhereTheWatchHasOne(logger as Test.Logger) as Boolean {
        var locator = GpsLocator.isAvailable() ? new GpsLocator() : new NoLocator();
        locator.turnOn();
        locator.turnOff();
        new NoLocator().turnOn();
        new NoLocator().turnOff();
        return true;
    }

    (:test)
    function testAppStorageKeepsAndRemovesAValue(logger as Test.Logger) as Boolean {
        var storage = new AppStorage();
        storage.put("test", [1, [2, 3]]);
        var stored = storage.get("test") as Array;
        Test.assertEqual(stored[0] as Number, 1);
        Test.assertEqual((stored[1] as Array)[1] as Number, 3);
        storage.remove("test");
        Test.assert(storage.get("test") == null);
        return true;
    }
}
