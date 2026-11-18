import Toybox.Lang;
import Toybox.Test;

// Helpers of the whole match tests. Nothing here carries (:test).
module WholeMatchTests {
    // Keeps the score of a match with its own plain rules, written apart
    // from the engine, so every entry of a whole match can be checked
    // against a second opinion: score, server, serve side, ends, change of
    // ends, what the entry closed and the point at stake.
    class Umpire {
        // [sets to win, games per set, points of a match tie break], by MatchFormat.
        const RULES = [[2, 6, 0], [2, 6, 10], [1, 6, 0], [1, 8, 0], [1, 0, 0]];
        const TIE_BREAK_TARGET = 7;
        const GAME_TARGET = 4;
        const GAME = 1;
        const SET = 2;
        const MATCH = 3;
        const STAKES = [Str.LabelBreakPoint, Str.LabelSetPoint, Str.LabelMatchPoint];

        var format as Number;
        var isNoAd as Boolean;
        var first as Number;
        var points as Array<Number> = [0, 0] as Array<Number>;
        var games as Array<Number> = [0, 0] as Array<Number>;
        var sets as Array<Number> = [0, 0] as Array<Number>;
        // The closed sets as the score text has them and as a lap has them.
        var setTexts as Array<String> = [] as Array<String>;
        var setScores as Array<String> = [] as Array<String>;
        var turns as Number = 0;
        var endChanges as Number = 0;
        var gamesClosed as Number = 0;
        var isSecond as Boolean = false;
        var isChangeDue as Boolean = false;
        // What the last move closed: nothing, GAME, SET or MATCH.
        var closed as Number = 0;
        var winner as Number = Player.NONE;

        function initialize(matchFormat as Number, noAd as Boolean, firstServer as Number) {
            format = matchFormat;
            isNoAd = noAd;
            first = firstServer;
        }

        function rule(index as Number) as Number {
            return (RULES[format] as Array<Number>)[index];
        }

        function isDecider() as Boolean {
            return rule(2) > 0 && sets[0] == rule(0) - 1 && sets[1] == rule(0) - 1;
        }

        function isTieBreak() as Boolean {
            return isDecider() || (games[0] == rule(1) && games[1] == rule(1));
        }

        function target() as Number {
            if (isDecider()) {
                return rule(2);
            }
            return isTieBreak() ? TIE_BREAK_TARGET : GAME_TARGET;
        }

        function margin() as Number {
            return isTieBreak() || !isNoAd ? 2 : 1;
        }

        function server() as Number {
            var extra = isTieBreak() ? (points[0] + points[1] + 1) / 2 : 0;
            return (first + turns + extra) % 2;
        }

        function fault() as Void {
            if (isSecond) {
                point(1 - server());
            } else {
                isSecond = true;
                isChangeDue = false;
                closed = 0;
            }
        }

        function point(player as Number) as Void {
            isSecond = false;
            isChangeDue = false;
            closed = 0;
            points[player] += 1;
            if (points[player] >= target() && points[player] - points[1 - player] >= margin()) {
                closeGame(player);
            } else if (isTieBreak() && (points[0] + points[1]) % 6 == 0) {
                changeEnds();
            }
        }

        function changeEnds() as Void {
            endChanges++;
            isChangeDue = true;
        }

        function closeGame(player as Number) as Void {
            var wasTieBreak = isTieBreak();
            games[player] += 1;
            turns++;
            gamesClosed++;
            closed = GAME;
            if ((games[0] + games[1]) % 2 == 1) {
                changeEnds();
            }
            if (wasTieBreak || (games[player] >= rule(1) && games[player] - games[1 - player] >= 2)) {
                closeSet(player, wasTieBreak);
            }
            points = [0, 0] as Array<Number>;
        }

        function closeSet(player as Number, wasTieBreak as Boolean) as Void {
            var tail = wasTieBreak ? [points[0], points[1]] : [0, 0];
            setTexts.add(games[0] + "-" + games[1] + (wasTieBreak ? "(" + tail[0] + "-" + tail[1] + ")" : ""));
            setScores.add(games[0] + "," + games[1] + "," + tail[0] + "," + tail[1]);
            sets[player] += 1;
            games = [0, 0] as Array<Number>;
            closed = SET;
            if (sets[player] == rule(0)) {
                winner = player;
                isChangeDue = false;
                closed = MATCH;
            }
        }

        function shown(player as Number) as Number {
            var mine = points[player];
            if (isTieBreak()) {
                return mine;
            }
            if (mine < 3) {
                return mine * 15;
            }
            return mine > 3 && mine > points[1 - player] ? 50 : 40;
        }

        // The same moves on a second umpire, to look one point ahead.
        function copy() as Umpire {
            var other = new Umpire(format, isNoAd, first);
            other.points = points.slice(0, null);
            other.games = games.slice(0, null);
            other.sets = sets.slice(0, null);
            other.turns = turns;
            return other;
        }

        // What a player closes by taking the next point.
        function reach(player as Number) as Number {
            var next = copy();
            next.point(player);
            return next.closed;
        }

        // "label key:player" of the heaviest point at stake, or "".
        function stake() as String {
            for (var level = MATCH; level >= GAME && winner == Player.NONE; level--) {
                for (var player = 0; player < 2; player++) {
                    var isBreak = player != server() && !isTieBreak();
                    if (reach(player) >= level && (level > GAME || isBreak)) {
                        return STAKES[level - 1] + ":" + player;
                    }
                }
            }
            return "";
        }

        function notice() as String {
            var keys = [] as Array<Number>;
            if (closed == GAME || closed == SET) {
                keys.add(closed == SET ? Str.NoticeSet : Str.NoticeGame);
            }
            if (isChangeDue) {
                keys.add(Str.NoticeChangeEnds);
            }
            return joined(keys);
        }

        // The closed sets and then the games of a set that is open.
        function scoreText() as String {
            var text = joinedWith(setTexts, " ");
            var played = games[0] + games[1] + points[0] + points[1];
            if (winner == Player.NONE && (played > 0 || setTexts.size() == 0)) {
                text += (text.length() == 0 ? "" : " ") + games[0] + "-" + games[1];
            }
            return text;
        }

        // One line with everything the match screen shows of the score.
        function text() as String {
            return sets[0] + "-" + sets[1] + " " + games[0] + "-" + games[1] + " " + shown(0) + "-" + shown(1)
                + " server " + server() + (isSecond ? " second" : "") + " side " + (points[0] + points[1]) % 2
                + " end " + endChanges % 2 + (isChangeDue ? " change" : "") + (isTieBreak() ? " tiebreak" : "")
                + " winner " + winner + " [" + stake() + "] " + scoreText();
        }
    }

    function joinedWith(texts as Array<String>, gap as String) as String {
        var text = "";
        for (var i = 0; i < texts.size(); i++) {
            text += (i == 0 ? "" : gap) + texts[i];
        }
        return text;
    }

    function tail(text as String, count as Number) as String {
        return text.substring(text.length() - count, text.length()) as String;
    }

    function stakeOf(held as Array?) as String {
        return held == null ? "" : (held[0] as String) + ":" + (held[1] as Number);
    }

    // The same line as Umpire.text(), read from the engine through the
    // classes the match screen uses.
    function seen(state as MatchState) as String {
        var held = MatchPresenter.pressure(state);
        return scoreOf(state) + " server " + state.server() + (state.isSecondServe() ? " second" : "")
            + " side " + state.serveSide() + " end " + state.endOf(Player.ME)
            + (state.isChangeOfEndsDue() ? " change" : "") + (state.isTieBreak() ? " tiebreak" : "")
            + " winner " + state.winner() + " [" + stakeOf(held) + "] " + MatchSummary.scoreText(state);
    }

    // A whole match played through the controller, as the keys and menus
    // drive it, on fakes of the watch. Every move is also given to the
    // umpire, and after every move the two are compared, together with the
    // clock, the notice, the point log field, the laps and the stored match.
    class Play {
        const STEP_MS = 20000;
        // [winner, ending] of a point letter: capital for me, small for the
        // opponent. M and O are plain points, for simple mode.
        const POINTS = {
            'M' => [0, Ending.NONE], 'W' => [0, Ending.WINNER], 'A' => [0, Ending.ACE],
            'N' => [0, Ending.ERROR_NET], 'X' => [0, Ending.ERROR_OUT],
            'O' => [1, Ending.NONE], 'w' => [1, Ending.WINNER], 'a' => [1, Ending.ACE],
            'n' => [1, Ending.ERROR_NET], 'x' => [1, Ending.ERROR_OUT]
        };
        const OTHERS = {'F' => :fault, 'U' => :undo, 'G' => :undoGame, '+' => :gameForMe, '-' => :gameForOpponent,
                        'P' => :pause, 'R' => :reopen, 'Z' => :pausedPresses, 'C' => :cancelledEnding};
        const CM_PER_STEP = 80;

        var format as Number;
        var isNoAd as Boolean;
        var isDetailed as Boolean;
        var first as Number;
        var time as FakeTime = new FakeTime();
        var session as FakeSession = new FakeSession();
        var sensors as FakeSensors = new FakeSensors();
        var locator as FakeLocator = new FakeLocator();
        var memory as MemoryStore = new MemoryStore();
        var store as MatchStore;
        var engine as MatchEngine;
        var controller as MatchController;
        var umpire as Umpire;
        // The moves the umpire was given: M, O and F.
        var moves as String = "";
        var playedMs as Number = 0;
        // The laps this activity should have, and the sets that were closed
        // before it started.
        var laps as Number = 0;
        var lapBase as Number = 0;
        var notice as String = "";
        // The steps the player walks before every point and fault.
        var stride as Number = 0;

        function initialize(matchFormat as Number, noAd as Boolean, detailed as Boolean, firstServer as Number) {
            format = matchFormat;
            isNoAd = noAd;
            isDetailed = detailed;
            first = firstServer;
            umpire = new Umpire(format, isNoAd, first);
            sensors.stepCount = 0;
            sensors.centimeters = 0;
            store = new MatchStore(memory);
            store.begin(setup().toArray());
            engine = new MatchEngine(setup().config(), new PointLog([] as Array<Number>), []);
            controller = newController();
        }

        function setup() as MatchSetup {
            return new MatchSetup([format, isNoAd ? 1 : 0, isDetailed ? 1 : 0, first, 0]);
        }

        function newController() as MatchController {
            return new MatchController(engine, setup(), time, new MatchRecorder(session, sensors, locator), store);
        }

        // One move per character; spaces only split the games for the reader.
        function play(script as String) as Void {
            var codes = script.toCharArray();
            for (var i = 0; i < codes.size(); i++) {
                if (POINTS.hasKey(codes[i])) {
                    point(POINTS[codes[i]] as Array<Number>);
                } else if (codes[i] != ' ') {
                    method(OTHERS[codes[i]] as Symbol).invoke();
                }
            }
        }

        // Twenty seconds pass before every point and fault.
        function wait() as Void {
            time.ms += STEP_MS;
            sensors.walk(stride, stride * CM_PER_STEP);
            if (!controller.isPaused() && !controller.isOver()) {
                playedMs += STEP_MS;
            }
        }

        function point(pointOf as Array<Number>) as Void {
            wait();
            var reaction = controller.handle(pointOf[0] == Player.ME ? MatchAction.POINT_ME : MatchAction.POINT_OPPONENT);
            if (isDetailed) {
                Test.assertEqualMessage(reaction, Reaction.ASK_ENDING, where());
                Test.assertEqualMessage(controller.pendingWinner(), pointOf[0], where());
                Test.assertMessage(EndingChoices.endings(pointOf[0], umpire.server()).indexOf(pointOf[1]) >= 0,
                                   "ending not on the list " + where());
                reaction = controller.chooseEnding(pointOf[1]);
            }
            moved(pointOf[0] == Player.ME ? "M" : "O", reaction);
        }

        function fault() as Void {
            wait();
            moved("F", controller.handle(MatchAction.FAULT));
        }

        // A point or a fault went in: the umpire gets it too.
        function moved(move as String, reaction as Number) as Void {
            moves += move;
            if (move.equals("F")) {
                umpire.fault();
            } else {
                umpire.point(move.equals("M") ? Player.ME : Player.OPPONENT);
            }
            notice = umpire.notice();
            Test.assertEqualMessage(reaction, Reaction.REFRESH | (umpire.isChangeDue ? Reaction.VIBRATE : 0), where());
            check();
        }

        function undo() as Void {
            Test.assertEqualMessage(controller.handle(MatchAction.UNDO), Reaction.REFRESH, where());
            corrected(moves.substring(0, moves.length() - 1) as String);
        }

        function undoGame() as Void {
            Test.assertEqualMessage(controller.undoGame(), Reaction.REFRESH, where());
            corrected(moves.substring(0, gameStart()) as String);
        }

        function gameForMe() as Void {
            award(Player.ME);
        }

        function gameForOpponent() as Void {
            award(Player.OPPONENT);
        }

        // The fix adds plain points until the game closes.
        function award(player as Number) as Void {
            Test.assertEqualMessage(controller.awardGame(player), Reaction.REFRESH, where());
            var fixed = moves;
            var closedBefore = umpire.gamesClosed;
            while (umpire.gamesClosed == closedBefore) {
                umpire.point(player);
                fixed += player == Player.ME ? "M" : "O";
            }
            corrected(fixed);
        }

        function pause() as Void {
            controller.togglePause();
            check();
        }

        // A pause from the menu: the clock stands, points and undo do
        // nothing, and the fault button resumes without logging a fault.
        function pausedPresses() as Void {
            controller.togglePause();
            Test.assertMessage(controller.isPaused(), "paused " + where());
            wait();
            notice = "";
            Test.assertEqualMessage(controller.handle(MatchAction.POINT_ME), Reaction.NONE, "point while paused " + where());
            Test.assertEqualMessage(controller.handle(MatchAction.POINT_OPPONENT), Reaction.NONE, "point while paused " + where());
            Test.assertEqualMessage(controller.handle(MatchAction.UNDO), Reaction.NONE, "undo while paused " + where());
            check();
            Test.assertEqualMessage(controller.handle(MatchAction.FAULT), Reaction.REFRESH, "resume " + where());
            Test.assertMessage(!controller.isPaused(), "resumed " + where());
            check();
        }

        // Detailed mode: leaving the list of endings logs nothing.
        function cancelledEnding() as Void {
            Test.assertEqualMessage(controller.handle(MatchAction.POINT_OPPONENT), Reaction.ASK_ENDING, where());
            controller.cancelEnding();
            Test.assertEqualMessage(controller.pendingWinner(), Player.NONE, where());
            Test.assertEqualMessage(controller.chooseEnding(Ending.WINNER), Reaction.NONE, where());
            check();
        }

        // Back from the final screen: a decided match loses its last entry.
        function reopen() as Void {
            var isDecided = umpire.winner != Player.NONE;
            controller.reopen();
            corrected(moves.substring(0, moves.length() - (isDecided ? 1 : 0)) as String);
        }

        // Where the game in progress starts in the moves, or the game
        // before it when the game in progress has no move yet.
        function gameStart() as Number {
            var starts = [0, 0] as Array<Number>;
            var counter = new Umpire(format, isNoAd, first);
            var codes = moves.toCharArray();
            for (var i = 0; i < codes.size(); i++) {
                give(counter, codes[i]);
                if (counter.closed != 0) {
                    starts = [starts[1], i + 1] as Array<Number>;
                }
            }
            return starts[1] == codes.size() ? starts[0] : starts[1];
        }

        function give(to as Umpire, move as Char) as Void {
            if (move == 'F') {
                to.fault();
            } else {
                to.point(move == 'M' ? Player.ME : Player.OPPONENT);
            }
        }

        // A correction left these moves: the umpire starts over with them.
        // A correction clears the notice and runs the clock of an open match.
        function corrected(kept as String) as Void {
            moves = kept;
            umpire = new Umpire(format, isNoAd, first);
            var codes = kept.toCharArray();
            for (var i = 0; i < codes.size(); i++) {
                give(umpire, codes[i]);
            }
            notice = "";
            check();
            checkStore();
        }

        function where() as String {
            return "after " + moves.length() + " moves, at " + umpire.text();
        }

        // Compares the controller with the umpire.
        function check() as Void {
            Test.assertEqualMessage(seen(controller.state()), umpire.text(), where());
            Test.assertEqualMessage(joined(controller.noticeKeys()), notice, "notice " + where());
            Test.assertEqualMessage(controller.clockSeconds(), playedMs / 1000, "clock " + where());
            Test.assertEqualMessage(engine.log().size(), moves.length(), "log size " + where());
            Test.assertEqualMessage(newestSequence(), moves.length(), "point log field " + where());
            checkLaps();
            if (umpire.closed != 0) {
                checkStore();
            }
        }

        // The sequence number of the newest entry in the point log field.
        function newestSequence() as Number {
            return (session.fields[RecordingFields.POINT_LOG] as Array<Number>)[0] & PointSlot.SEQUENCE_MASK;
        }

        // One lap per closed set but the one that ends the match. A lap
        // cannot be taken back, so an undone set keeps the lap it opened.
        function checkLaps() as Void {
            var due = umpire.setTexts.size() - (umpire.winner == Player.NONE ? 0 : 1) - lapBase;
            if (due > laps) {
                laps = due;
                Test.assertEqualMessage(session.lapScores[laps - 1], umpire.setScores[lapBase + laps - 1], "lap score " + where());
            }
            Test.assertEqualMessage(session.laps.size(), laps, "laps " + where());
        }

        // The stored match is the match played: the same log, and marks
        // that rebuild the same score and the same statistics.
        function checkStore() as Void {
            var stored = new MatchStore(memory).load() as Array;
            var entries = stored[1] as Array<Number>;
            Test.assertEqualMessage(joinedNumbers(entries), joinedNumbers(engine.log().toArray()), "stored log " + where());
            var rebuilt = new MatchEngine(setup().config(), new PointLog(entries), stored[2] as Array< Array<Number> >);
            Test.assertEqualMessage(seen(rebuilt.state()), umpire.text(), "stored match " + where());
            Test.assertEqualMessage(joinedNumbers(rebuilt.statistics().toArray()), statistics(), "stored statistics " + where());
        }

        // The app closes and opens again: a new controller on the stored
        // match, a new activity, and the clock at the time of the last entry.
        function reopenApp() as Void {
            controller.suspend();
            controller.suspend();
            Test.assertEqualMessage(tail(session.calls, 2), "pS", where());
            checkSummary(setupWord(0, 0), umpire.scoreText(), statistics());
            session = new FakeSession();
            store = new MatchStore(memory);
            var stored = store.load() as Array;
            engine = new MatchEngine(setup().config(), new PointLog(stored[1] as Array<Number>),
                                     stored[2] as Array< Array<Number> >);
            controller = newController();
            laps = 0;
            lapBase = umpire.setTexts.size();
            playedMs = engine.log().size() == 0 ? 0 : PointEntry.time(engine.log().at(engine.log().size() - 1)) * 1000;
            notice = "";
            check();
        }

        // The score line, the score text, the point at stake and the size
        // of the log, as written in the test.
        function at(scoreLine as String, text as String, held as String, size as Number) as Void {
            Test.assertEqualMessage(score(), scoreLine, "score " + where());
            Test.assertEqualMessage(MatchSummary.scoreText(controller.state()), text, "score text " + where());
            Test.assertEqualMessage(stake(), held, "stake " + where());
            Test.assertEqualMessage(engine.log().size(), size, "size " + where());
        }

        // Ends the match from the menu: the final screen takes over, the
        // clock stands and the keys score nothing.
        function endEarly() as Void {
            controller.end();
            Test.assertMessage(controller.isOver() && !controller.isPaused(), "over " + where());
            wait();
            notice = "";
            Test.assertEqualMessage(controller.handle(MatchAction.POINT_ME), Reaction.NONE, "point after the end " + where());
            Test.assertEqualMessage(controller.handle(MatchAction.FAULT), Reaction.NONE, "fault after the end " + where());
            check();
        }

        // Saves with the tags and checks what the activity file was given
        // and that the stored match is gone.
        function save(surface as Number, kind as Number, finalScore as String, counts as String) as Void {
            controller.save(new MatchTags([surface, kind]));
            Test.assertEqualMessage(controller.farewellKey() as Number, Str.SavedMsg, where());
            checkSummary(setupWord(surface, kind), finalScore, counts);
            checkClosed("S");
        }

        // The app closes on the final score: the activity is saved without
        // tags and the stored match is gone.
        function closeFinishedApp(finalScore as String, counts as String) as Void {
            controller.suspend();
            checkSummary(setupWord(0, 0), finalScore, counts);
            checkClosed("S");
        }

        // How the match stands at the end: the winner, the match clock in
        // seconds and the set scores of the laps of this activity.
        function ended(winner as Number, clockSeconds as Number, lapScores as String) as Void {
            Test.assertEqualMessage(controller.state().winner(), winner, "winner " + where());
            Test.assertMessage(controller.isOver(), "over " + where());
            Test.assertEqualMessage(controller.clockSeconds(), clockSeconds, "clock " + where());
            Test.assertEqualMessage(joinedWith(session.lapScores, " "), lapScores, "laps " + where());
        }

        // "steps:meters" of each lap, and the totals of the activity.
        function walked(lapsText as String, steps as Number, meters as Number) as Void {
            var texts = [] as Array<String>;
            for (var i = 0; i < session.laps.size(); i++) {
                texts.add(session.laps[i][0] + ":" + session.laps[i][1]);
            }
            Test.assertEqualMessage(joinedWith(texts, " "), lapsText, "lap steps " + where());
            Test.assertEqualMessage(field(RecordingFields.STEPS) as Object, steps, "steps " + where());
            Test.assertEqualMessage(field(RecordingFields.DISTANCE) as Object, meters, "meters " + where());
        }

        function discard() as Void {
            controller.discard();
            Test.assertEqualMessage(controller.farewellKey() as Number, Str.DiscardedMsg, where());
            checkClosed("D");
        }

        // The setup word as docs/DATA_FORMAT.md lays it out.
        function setupWord(surface as Number, kind as Number) as Number {
            return 1 | (format << 4) | ((isNoAd ? 1 : 0) << 7) | ((isDetailed ? 1 : 0) << 8) | (first << 9)
                | (surface << 10) | (kind << 12);
        }

        function checkSummary(word as Number, finalScore as String, counts as String) as Void {
            Test.assertEqualMessage(field(RecordingFields.MATCH_SETUP) as Object, word, "setup word " + where());
            Test.assertEqualMessage(field(RecordingFields.FINAL_SCORE) as Object, finalScore, "final score " + where());
            Test.assertEqualMessage(session.numbers(RecordingFields.STATISTICS), counts, "statistics " + where());
            Test.assertEqualMessage(field(RecordingFields.LOG_SIZE) as Object, moves.length(), "log size field " + where());
            Test.assertEqualMessage(newestSequence(), moves.length(), "point log field " + where());
        }

        // The activity ended with a stop and this call, the position was
        // turned off and nothing is left to resume.
        function checkClosed(lastCall as String) as Void {
            var calls = session.calls;
            Test.assertEqualMessage(tail(calls, 2), "p" + lastCall, "calls " + where());
            Test.assertEqualMessage(session.records[session.records.size() - 1], moves.length(), "last record " + where());
            Test.assertEqualMessage(tail(locator.calls, 1), "-", where());
            Test.assertMessage(new MatchStore(memory).load() == null, "store cleared " + where());
        }

        function score() as String {
            return scoreOf(controller.state());
        }

        // "label key:player" of the point at stake, as the banner shows it.
        function stake() as String {
            return stakeOf(MatchPresenter.pressure(controller.state()));
        }

        function statistics() as String {
            return joinedNumbers(engine.statistics().toArray());
        }

        function field(id as Number) as Object? {
            return session.fields.get(id);
        }
    }
}
