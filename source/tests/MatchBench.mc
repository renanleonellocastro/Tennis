import Toybox.Lang;
import Toybox.Test;

// Test helpers for the match screen classes. Nothing here carries (:test).

// A clock the tests move by hand.
class FakeTime {
    var ms as Number = 0;

    function now() as Number {
        return ms;
    }
}

// A controller on a fresh match, driven by the same actions the keys send.
class MatchBench {
    const POINTS_OF_A_LOVE_GAME = 4;
    const ACTIONS = {
        'M' => MatchAction.POINT_ME, 'O' => MatchAction.POINT_OPPONENT,
        'F' => MatchAction.FAULT, 'U' => MatchAction.UNDO
    };

    var time as FakeTime = new FakeTime();
    var engine as MatchEngine;
    var controller as MatchController;
    var session as FakeSession = new FakeSession();
    var sensors as FakeSensors = new FakeSensors();
    var locator as FakeLocator = new FakeLocator();
    var memory as MemoryStore = new MemoryStore();
    var store as MatchStore;

    function initialize(format as Number, isDetailed as Boolean) {
        engine = new MatchEngine(new MatchConfig(format, false, Player.ME), new PointLog([] as Array<Number>), []);
        store = new MatchStore(memory);
        controller = controllerOn(engine, setupOf(format, isDetailed));
    }

    // The setup of a match I serve first, with advantage and without GPS.
    function setupOf(format as Number, isDetailed as Boolean) as MatchSetup {
        return new MatchSetup([format, 0, isDetailed ? 1 : 0, Player.ME, 0]);
    }

    // A controller on the fakes of this bench, as the app builds one.
    function controllerOn(matchEngine as MatchEngine, setup as MatchSetup) as MatchController {
        return new MatchController(matchEngine, setup, time,
                                   new MatchRecorder(session, sensors, locator), store);
    }

    // One action per character: 'M', 'O', 'F' as in MatchDriver and 'U' for
    // undo. Returns the reaction to the last one.
    function play(script as String) as Number {
        var codes = script.toCharArray();
        var reaction = Reaction.NONE;
        for (var i = 0; i < codes.size(); i++) {
            reaction = controller.handle(ACTIONS[codes[i]] as Number);
        }
        return reaction;
    }

    // One love game per character. Returns the reaction to the last point.
    function games(script as String) as Number {
        var codes = script.toCharArray();
        var reaction = Reaction.NONE;
        for (var i = 0; i < codes.size() * POINTS_OF_A_LOVE_GAME; i++) {
            reaction = play(codes[i / POINTS_OF_A_LOVE_GAME].toString());
        }
        return reaction;
    }

    function score() as String {
        return scoreOf(engine.state());
    }

    function notice() as String {
        var key = controller.noticeKey();
        return key == null ? "" : key.toString();
    }
}

function simpleBench(format as Number) as MatchBench {
    return new MatchBench(format, false);
}

// The items, texts or text keys, with a comma between them.
function joined(texts as Array<String> or Array<Number>) as String {
    var text = "";
    for (var i = 0; i < texts.size(); i++) {
        text += (i == 0 ? "" : ",") + texts[i].toString();
    }
    return text;
}

// "sets games points", me first, with the advantage as 50.
function scoreOf(state as MatchState) as String {
    return state.sets(Player.ME) + "-" + state.sets(Player.OPPONENT) + " "
        + state.games(Player.ME) + "-" + state.games(Player.OPPONENT) + " "
        + state.displayPoints(Player.ME) + "-" + state.displayPoints(Player.OPPONENT);
}

function assertKeyInEveryLanguage(key as Number) as Void {
    var codes = I18n.CODES;
    for (var i = 0; i < codes.size(); i++) {
        var code = codes[i] as String;
        Test.assertMessage(I18n.table(code)[key].length() > 0, "no text " + key + " in " + code);
    }
}

function assertRowsAreMethodsOf(rows as Array, delegate as Object) as Void {
    for (var i = 0; i < rows.size(); i++) {
        var row = rows[i] as Array;
        assertKeyInEveryLanguage(row[0] as Number);
        Test.assert(delegate has (row[1] as Symbol));
    }
}
