import Toybox.Lang;
import Toybox.Test;

// Tests for the counters of a practice: entries, undo, blocks and totals.
module PracticeTests {
    (:test)
    function testNewLogIsAnEmptyFirstBlock(logger as Test.Logger) as Boolean {
        var log = new PracticeLog();
        Test.assertEqual(tallyOf(log), "1 0-0");
        Test.assertEqual(log.closedBlocks(), 0);
        Test.assertEqual(log.blocks(), 0);
        Test.assertEqual(log.totalHits(), 0);
        Test.assertEqual(log.totalMisses(), 0);
        return true;
    }

    (:test)
    function testHitsAndMissesCountInTheOpenBlock(logger as Test.Logger) as Boolean {
        var log = new PracticeLog();
        log.hit();
        log.miss();
        log.hit();
        Test.assertEqual(tallyOf(log), "1 2-1");
        Test.assertEqual(log.blocks(), 1);
        return true;
    }

    (:test)
    function testUndoTakesBackTheLastEntryWhateverItWas(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("HXH");
        Test.assert(log.undo());
        Test.assertEqual(tallyOf(log), "1 1-1");
        Test.assert(log.undo());
        Test.assertEqual(tallyOf(log), "1 1-0");
        Test.assert(log.undo());
        Test.assertEqual(tallyOf(log), "1 0-0");
        return true;
    }

    (:test)
    function testUndoOnAnEmptyBlockDoesNothing(logger as Test.Logger) as Boolean {
        var log = new PracticeLog();
        Test.assert(!log.undo());
        Test.assertEqual(tallyOf(log), "1 0-0");
        return true;
    }

    (:test)
    function testClosingABlockOpensTheNextFromZero(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("HHX");
        Test.assert(log.closeBlock());
        Test.assertEqual(tallyOf(log), "2 0-0");
        Test.assertEqual(log.closedBlocks(), 1);
        Test.assertEqual(log.hitsOf(0), 2);
        Test.assertEqual(log.missesOf(0), 1);
        return true;
    }

    (:test)
    function testAnEmptyBlockDoesNotClose(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("HN");
        Test.assert(!log.closeBlock());
        Test.assertEqual(tallyOf(log), "2 0-0");
        Test.assertEqual(log.closedBlocks(), 1);
        return true;
    }

    (:test)
    function testABlockEmptiedByUndoDoesNotClose(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("XU");
        Test.assert(!log.closeBlock());
        Test.assertEqual(log.blocks(), 0);
        return true;
    }

    (:test)
    function testUndoNeverReachesIntoAClosedBlock(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("HXN");
        Test.assert(!log.undo());
        Test.assertEqual(log.hitsOf(0), 1);
        Test.assertEqual(log.missesOf(0), 1);
        log.hit();
        Test.assert(log.undo());
        Test.assert(!log.undo());
        Test.assertEqual(log.closedBlocks(), 1);
        return true;
    }

    (:test)
    function testSummaryCountsTheOpenBlockOnlyWithEntries(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("HNXXN");
        Test.assertEqual(log.blocks(), 2);
        log.hit();
        Test.assertEqual(log.blocks(), 3);
        Test.assertEqual(log.hitsOf(2), 1);
        Test.assertEqual(log.missesOf(2), 0);
        Test.assertEqual(log.hitsOf(1), 0);
        Test.assertEqual(log.missesOf(1), 2);
        return true;
    }

    (:test)
    function testTotalsAddTheClosedBlocksAndTheOpenOne(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("HHXNHXXNH");
        Test.assertEqual(log.totalHits(), 4);
        Test.assertEqual(log.totalMisses(), 3);
        return true;
    }

    (:test)
    function testTotalsFollowAnUndo(logger as Test.Logger) as Boolean {
        var log = practiceLogOf("HNHXUU");
        Test.assertEqual(log.totalHits(), 1);
        Test.assertEqual(log.totalMisses(), 0);
        return true;
    }
}
