import Toybox.Lang;
import Toybox.Test;

// Tests for the match kept in storage: one value per set, and the log that
// comes back from them.
module MatchStoreTests {
    const SETUP = [1, 0, 1, 0, 0];

    function range(from as Number, to as Number) as Array<Number> {
        var numbers = [] as Array<Number>;
        for (var i = from; i < to; i++) {
            numbers.add(i);
        }
        return numbers;
    }

    function storedLog(memory as MemoryStore) as String {
        var stored = new MatchStore(memory).load() as Array;
        return joinedNumbers(stored[1] as Array<Number>);
    }

    function keys(memory as MemoryStore) as Number {
        return memory.values.size();
    }

    (:test)
    function testStoreHasNoMatchUntilOneBegins(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        Test.assert(!store.hasMatch());
        Test.assert(store.load() == null);
        store.begin(SETUP);
        Test.assert(store.hasMatch());
        return true;
    }

    (:test)
    function testStoreIgnoresAHeaderItDoesNotKnow(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        var headers = [[1], [2, SETUP], ["1", SETUP], [1, SETUP, 0]];
        for (var i = 0; i < headers.size(); i++) {
            memory.put("match", headers[i] as Array);
            Test.assert(!store.hasMatch());
        }
        return true;
    }

    (:test)
    function testStoreGivesBackTheSetupAndAnEmptyLog(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        new MatchStore(memory).begin(SETUP);
        var stored = new MatchStore(memory).load() as Array;
        Test.assertEqual(joinedNumbers(stored[0] as Array<Number>), "1,0,1,0,0");
        Test.assertEqual((stored[1] as Array).size(), 0);
        return true;
    }

    (:test)
    function testStoreKeepsOneValuePerSet(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        store.begin(SETUP);
        store.sync(range(0, 2), 0, []);
        store.sync(range(0, 3), 1, []);
        store.sync(range(0, 5), 1, []);
        Test.assertEqual(joinedNumbers(memory.values["set0"] as Array<Number>), "0,1,2");
        Test.assertEqual(joinedNumbers(memory.values["set1"] as Array<Number>), "3,4");
        Test.assertEqual(storedLog(memory), "0,1,2,3,4");
        return true;
    }

    (:test)
    function testStoreWritesOnlyTheSetInProgress(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        store.begin(SETUP);
        store.sync(range(0, 3), 1, []);
        memory.values.put("set0", ["kept"]);
        store.sync(range(0, 4), 1, []);
        Test.assertEqual((memory.values["set0"] as Array)[0] as String, "kept");
        return true;
    }

    (:test)
    function testStoreDropsTheSetsACorrectionWentBackOver(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        store.begin(SETUP);
        store.sync(range(0, 3), 1, []);
        store.sync(range(0, 6), 2, []);
        store.sync(range(0, 8), 2, []);
        store.sync(range(0, 2), 0, []);
        Test.assertEqual(keys(memory), 2);
        Test.assertEqual(storedLog(memory), "0,1");
        store.sync(range(0, 3), 1, []);
        store.sync(range(0, 4), 1, []);
        Test.assertEqual(storedLog(memory), "0,1,2,3");
        return true;
    }

    (:test)
    function testStoreTakesBackTheLastEntryOfASet(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        store.begin(SETUP);
        store.sync(range(0, 3), 1, []);
        store.sync(range(0, 2), 0, []);
        Test.assertEqual(storedLog(memory), "0,1");
        store.sync(range(0, 0), 0, []);
        Test.assertEqual(storedLog(memory), "");
        return true;
    }

    (:test)
    function testStoreGoesOnAfterALoad(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var first = new MatchStore(memory);
        first.begin(SETUP);
        first.sync(range(0, 3), 1, []);
        first.sync(range(0, 5), 1, []);
        var second = new MatchStore(memory);
        second.load();
        second.sync(range(0, 6), 1, []);
        Test.assertEqual(storedLog(memory), "0,1,2,3,4,5");
        second.sync(range(0, 1), 0, []);
        Test.assertEqual(keys(memory), 2);
        Test.assertEqual(storedLog(memory), "0");
        return true;
    }

    // A set that closed just before the app did has no value of its own
    // yet, so the loaded store keeps its first entries with the set before.
    (:test)
    function testStoreStaysWholeWhenALoadedSetIsCutShort(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var first = new MatchStore(memory);
        first.begin(SETUP);
        first.sync(range(0, 3), 1, []);
        var second = new MatchStore(memory);
        second.load();
        second.sync(range(0, 5), 1, []);
        second.sync(range(0, 4), 1, []);
        Test.assertEqual(storedLog(memory), "0,1,2,3");
        second.sync(range(0, 6), 1, []);
        Test.assertEqual(storedLog(memory), "0,1,2,3,4,5");
        return true;
    }

    (:test)
    function testStoreClearRemovesEveryValue(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        store.begin(SETUP);
        store.sync(range(0, 3), 1, []);
        store.sync(range(0, 6), 2, []);
        store.sync(range(0, 7), 2, []);
        store.clear();
        Test.assertEqual(keys(memory), 0);
        Test.assert(!store.hasMatch());
        return true;
    }

    (:test)
    function testStoreBeginReplacesAnOlderMatch(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        var store = new MatchStore(memory);
        store.begin(SETUP);
        store.sync(range(0, 3), 1, []);
        store.sync(range(0, 5), 1, []);
        store.begin([0, 0, 0, 0, 0]);
        Test.assertEqual(storedLog(memory), "");
        store.sync(range(7, 9), 0, []);
        Test.assertEqual(storedLog(memory), "7,8");
        return true;
    }

    (:test)
    function testStoreSkipsAValueThatIsNotAList(logger as Test.Logger) as Boolean {
        var memory = new MemoryStore();
        new MatchStore(memory).begin(SETUP);
        Test.assertEqual(storedLog(memory), "");
        memory.put("set1", [9]);
        Test.assertEqual(storedLog(memory), "9");
        return true;
    }
}
