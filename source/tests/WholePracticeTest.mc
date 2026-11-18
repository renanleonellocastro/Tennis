import Toybox.Lang;
import Toybox.Test;

// A whole practice session through the controller: blocks, undo, a pause,
// the summary, back to the practice, and the save.
module PracticeTests {
    const PRESS_MS = 10000;
    const PRESS_STEPS = 10;
    const PRESS_CM = 800;

    // Plays the script; ten seconds and ten steps go by before every hit and miss.
    function practise(bench as PracticeBench, script as String) as Number {
        var codes = script.toCharArray();
        var reaction = Reaction.NONE;
        for (var i = 0; i < codes.size(); i++) {
            if (codes[i] == 'H' || codes[i] == 'X') {
                bench.time.ms += PRESS_MS;
                bench.sensors.walk(PRESS_STEPS, PRESS_CM);
            }
            reaction = bench.play(codes[i].toString());
        }
        return reaction;
    }

    function benchWithSteps() as PracticeBench {
        var bench = new PracticeBench();
        bench.sensors.walk(0, 0);
        bench.controller.tick();
        return bench;
    }

    // Three closed blocks and an open one, with a pause before the third.
    function sessionOfFourBlocks() as PracticeBench {
        var bench = benchWithSteps();
        practise(bench, "HHXHHHXHUHN");
        practise(bench, "XXHUUHXN");
        bench.controller.togglePause();
        practise(bench, "HXU");
        practise(bench, "N");
        practise(bench, "HHHHHHHHHHHHNN");
        practise(bench, "HXX");
        return bench;
    }

    (:test)
    function testWholePracticeCountsEveryBlock(logger as Test.Logger) as Boolean {
        var bench = benchWithSteps();
        Test.assertEqual(practise(bench, "HHXHHHXHUH"), Reaction.REFRESH);
        Test.assertEqual(bench.tally(), "1 6-2");
        Test.assertEqual(bench.field(RecordingFields.BLOCK_HITS), 6);
        Test.assertEqual(bench.field(RecordingFields.BLOCK_MISSES), 2);
        Test.assertEqual(practise(bench, "N"), Reaction.REFRESH | Reaction.VIBRATE);
        Test.assertEqual(bench.tally(), "2 0-0");
        Test.assertEqual(practise(bench, "XXHUUHX"), Reaction.REFRESH);
        Test.assertEqual(bench.tally(), "2 1-2");
        practise(bench, "N");
        Test.assertEqual(bench.session.blocks.toString(), "[[6, 2], [1, 2]]");
        Test.assertEqual(bench.session.laps.toString(), "[[90, 72], [50, 40]]");
        Test.assertEqual(bench.controller.clockSeconds(), 140);
        return true;
    }

    (:test)
    function testWholePracticePauseSwallowsThePresses(logger as Test.Logger) as Boolean {
        var bench = benchWithSteps();
        practise(bench, "HHXHHHXHUHN");
        practise(bench, "XXHUUHXN");
        bench.controller.togglePause();
        Test.assertEqual(practise(bench, "HXU"), Reaction.NONE);
        Test.assertEqual(bench.tally(), "3 0-0");
        Test.assertEqual(bench.controller.clockSeconds(), 140);
        Test.assertEqual(practise(bench, "N"), Reaction.REFRESH);
        Test.assert(!bench.controller.isPaused());
        Test.assertEqual(bench.session.laps.size(), 2);
        Test.assertEqual(bench.session.calls, "sllps");
        Test.assertEqual(practise(bench, "HHHHHHHHHHHHN"), Reaction.REFRESH | Reaction.VIBRATE);
        Test.assertEqual(practise(bench, "N"), Reaction.NONE);
        Test.assertEqual(bench.session.blocks.toString(), "[[6, 2], [1, 2], [12, 0]]");
        Test.assertEqual(bench.session.laps.toString(), "[[90, 72], [50, 40], [120, 96]]");
        Test.assertEqual(bench.controller.clockSeconds(), 260);
        return true;
    }

    (:test)
    function testWholePracticeSummaryHasEveryBlockAndTheTotal(logger as Test.Logger) as Boolean {
        var bench = sessionOfFourBlocks();
        bench.controller.end();
        Test.assertEqual(practise(bench, "HXNU"), Reaction.NONE);
        var log = bench.controller.log();
        Test.assertEqual(joined(PracticePresenter.summaryRows(log, 0, 4)),
                         "1  6/8  75%,2  1/3  33%,3  12/12  100%,4  1/3  33%");
        Test.assertEqual(joined(PracticePresenter.summaryRows(log, 3, 3)), "4  1/3  33%");
        Test.assertEqual(PracticePresenter.totalText(log), "20/26  77%");
        Test.assertEqual(PracticePresenter.summaryFooter(bench.controller.clockSeconds(), 0, 2), "4:50  1/2");
        return true;
    }

    (:test)
    function testWholePracticeReopenedPlayedOnAndSaved(logger as Test.Logger) as Boolean {
        var bench = sessionOfFourBlocks();
        bench.controller.end();
        practise(bench, "HX");
        bench.controller.reopen();
        Test.assertEqual(practise(bench, "H"), Reaction.REFRESH);
        Test.assertEqual(bench.tally(), "4 2-2");
        bench.controller.end();
        bench.controller.save();
        Test.assertEqual(bench.session.calls, "sllpslpspS");
        Test.assertEqual(bench.locator.calls, "+-");
        Test.assertEqual(bench.session.blocks.toString(), "[[6, 2], [1, 2], [12, 0]]");
        Test.assertEqual(bench.field(RecordingFields.BLOCK_HITS), 2);
        Test.assertEqual(bench.field(RecordingFields.BLOCK_MISSES), 2);
        Test.assertEqual(bench.field(RecordingFields.SET_STEPS), 40);
        Test.assertEqual(bench.field(RecordingFields.SET_DISTANCE), 32);
        Test.assertEqual(bench.field(RecordingFields.STEPS), 300);
        Test.assertEqual(bench.field(RecordingFields.DISTANCE), 240);
        Test.assertEqual(bench.controller.clockSeconds(), 300);
        Test.assertEqual(PracticePresenter.totalText(bench.controller.log()), "21/27  78%");
        Test.assertEqual(bench.controller.farewellKey() as Number, Str.SavedMsg);
        return true;
    }
}
