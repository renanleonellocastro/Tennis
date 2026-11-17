import Toybox.Lang;
import Toybox.Test;

module PracticeTests {
    // Test helpers for the practice classes. Nothing here carries (:test).

    // A fake session that also keeps the block fields as they were when each
    // lap closed: [hits, misses].
    class BlockSession extends FakeSession {
        var blocks as Array< Array<Number> > = [] as Array< Array<Number> >;

        function initialize() {
            FakeSession.initialize();
        }

        function addLap() as Void {
            blocks.add([fields[RecordingFields.BLOCK_HITS], fields[RecordingFields.BLOCK_MISSES]] as Array<Number>);
            FakeSession.addLap();
        }
    }

    // A controller on a fresh practice, driven by the same actions the keys send.
    class PracticeBench {
        const ACTIONS = {
            'H' => PracticeAction.HIT, 'X' => PracticeAction.MISS,
            'N' => PracticeAction.CLOSE_BLOCK, 'U' => PracticeAction.UNDO
        };

        var time as FakeTime = new FakeTime();
        var session as BlockSession = new BlockSession();
        var sensors as FakeSensors = new FakeSensors();
        var locator as FakeLocator = new FakeLocator();
        var controller as PracticeController;

        function initialize() {
            controller = new PracticeController(time, new PracticeRecorder(session, sensors, locator));
        }

        // One action per character: 'H' hit, 'X' miss, 'N' next block and 'U'
        // undo. Returns the reaction to the last one.
        function play(script as String) as Number {
            var codes = script.toCharArray();
            var reaction = Reaction.NONE;
            for (var i = 0; i < codes.size(); i++) {
                reaction = controller.handle(ACTIONS[codes[i]] as Number);
            }
            return reaction;
        }

        // "block hits-misses" of the open block.
        function tally() as String {
            return tallyOf(controller.log());
        }

        // The value of a block field as the activity has it now.
        function field(id as Number) as Number {
            return session.fields[id] as Number;
        }
    }

    function tallyOf(log as PracticeLog) as String {
        return log.blockNumber() + " " + log.hits() + "-" + log.misses();
    }

    // A log filled by a script: 'H' hit, 'X' miss, 'N' next block, 'U' undo.
    function practiceLogOf(script as String) as PracticeLog {
        var steps = {'H' => :hit, 'X' => :miss, 'N' => :closeBlock, 'U' => :undo};
        var log = new PracticeLog();
        var codes = script.toCharArray();
        for (var i = 0; i < codes.size(); i++) {
            log.method(steps[codes[i]] as Symbol).invoke();
        }
        return log;
    }
}
