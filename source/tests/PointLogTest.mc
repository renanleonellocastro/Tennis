import Toybox.Lang;
import Toybox.Test;

// Tests for the packed log entry, the log itself and the format table.

(:test)
function testPointEntryKeepsEveryField(logger as Test.Logger) as Boolean {
    var entry = PointEntry.point(Player.OPPONENT, Ending.ERROR_OUT, 3725, 148);
    Test.assert(!PointEntry.isFault(entry));
    Test.assertEqual(PointEntry.winner(entry), Player.OPPONENT);
    Test.assertEqual(PointEntry.ending(entry), Ending.ERROR_OUT);
    Test.assertEqual(PointEntry.time(entry), 3725);
    Test.assertEqual(PointEntry.heartRate(entry) as Number, 148);
    return true;
}

(:test)
function testPointEntryForMeWithEveryEnding(logger as Test.Logger) as Boolean {
    var endings = [Ending.NONE, Ending.WINNER, Ending.ACE, Ending.ERROR_NET, Ending.ERROR_OUT];
    for (var i = 0; i < endings.size(); i++) {
        var entry = PointEntry.point(Player.ME, endings[i], 0, null);
        Test.assertEqual(PointEntry.winner(entry), Player.ME);
        Test.assertEqual(PointEntry.ending(entry), endings[i]);
        Test.assert(!PointEntry.isFault(entry));
    }
    return true;
}

(:test)
function testFaultEntryHasNoEndingAndKeepsTimeAndHeartRate(logger as Test.Logger) as Boolean {
    var entry = PointEntry.fault(90, 121);
    Test.assert(PointEntry.isFault(entry));
    Test.assertEqual(PointEntry.ending(entry), Ending.NONE);
    Test.assertEqual(PointEntry.time(entry), 90);
    Test.assertEqual(PointEntry.heartRate(entry) as Number, 121);
    return true;
}

(:test)
function testEntryWithoutHeartRateReadsNull(logger as Test.Logger) as Boolean {
    Test.assert(PointEntry.heartRate(PointEntry.point(Player.ME, Ending.NONE, 5, null)) == null);
    Test.assert(PointEntry.heartRate(PointEntry.fault(5, null)) == null);
    Test.assert(PointEntry.heartRate(PointEntry.fault(5, 0)) == null);
    return true;
}

(:test)
function testEntryClampsValuesThatDoNotFit(logger as Test.Logger) as Boolean {
    var entry = PointEntry.point(Player.ME, Ending.WINNER, 99999999, 400);
    Test.assertEqual(PointEntry.time(entry), PointEntry.TIME_MASK);
    Test.assertEqual(PointEntry.heartRate(entry) as Number, PointEntry.HEART_RATE_MASK);
    Test.assertEqual(PointEntry.winner(entry), Player.ME);
    Test.assertEqual(PointEntry.ending(entry), Ending.WINNER);
    var negative = PointEntry.fault(-5, -1);
    Test.assertEqual(PointEntry.time(negative), 0);
    Test.assert(PointEntry.heartRate(negative) == null);
    return true;
}

(:test)
function testEntryIsAPlainNonNegativeNumber(logger as Test.Logger) as Boolean {
    var entry = PointEntry.point(Player.OPPONENT, Ending.ERROR_OUT, PointEntry.TIME_MASK, 255);
    Test.assert((entry as Object) instanceof Lang.Number);
    Test.assert(entry > 0);
    Test.assertEqual(PointEntry.fault(0, null), 0);
    return true;
}

(:test)
function testPointLogAppendsAndTruncates(logger as Test.Logger) as Boolean {
    var log = new PointLog([] as Array<Number>);
    Test.assertEqual(log.size(), 0);
    log.append(11);
    log.append(22);
    Test.assertEqual(log.size(), 2);
    Test.assertEqual(log.at(0), 11);
    Test.assertEqual(log.at(1), 22);
    log.append(33);
    log.truncate(1);
    Test.assertEqual(log.size(), 1);
    Test.assertEqual(log.toArray()[0], 11);
    return true;
}

(:test)
function testPointLogStartsFromAStoredArray(logger as Test.Logger) as Boolean {
    var log = new PointLog([5, 6, 7] as Array<Number>);
    Test.assertEqual(log.size(), 3);
    Test.assertEqual(log.at(2), 7);
    return true;
}

(:test)
function testFormatTableHasOneRowPerPreset(logger as Test.Logger) as Boolean {
    var expected = {
        MatchFormat.BEST_OF_3 => [2, 6, 7, 0],
        MatchFormat.BEST_OF_3_MATCH_TIE_BREAK => [2, 6, 7, 10],
        MatchFormat.ONE_SET => [1, 6, 7, 0],
        MatchFormat.PRO_SET => [1, 8, 7, 0],
        MatchFormat.TIE_BREAK_ONLY => [1, 0, 7, 0]
    } as Dictionary< Number, Array<Number> >;
    var formats = expected.keys();
    for (var i = 0; i < formats.size(); i++) {
        var rules = MatchFormat.rules(formats[i]);
        var row = expected[formats[i]] as Array<Number>;
        for (var column = 0; column < row.size(); column++) {
            Test.assertEqual(rules[column], row[column]);
        }
    }
    return true;
}

(:test)
function testConfigReadsTheRulesOfItsFormat(logger as Test.Logger) as Boolean {
    var config = new MatchConfig(MatchFormat.BEST_OF_3_MATCH_TIE_BREAK, false, Player.ME);
    Test.assertEqual(config.setsToWin(), 2);
    Test.assertEqual(config.gamesPerSet(), 6);
    Test.assertEqual(config.tieBreakPoints(), 7);
    Test.assertEqual(config.matchTieBreakPoints(), 10);
    Test.assertEqual(config.gameWinMargin(), 2);
    Test.assertEqual(new MatchConfig(MatchFormat.ONE_SET, true, Player.ME).gameWinMargin(), 1);
    return true;
}

(:test)
function testConfigRotatesTheServeFromTheFirstServer(logger as Test.Logger) as Boolean {
    var config = new MatchConfig(MatchFormat.ONE_SET, false, Player.OPPONENT);
    Test.assertEqual(config.serverAt(0), Player.OPPONENT);
    Test.assertEqual(config.serverAt(1), Player.ME);
    Test.assertEqual(config.serverAt(2), Player.OPPONENT);
    Test.assertEqual(Player.opponentOf(Player.ME), Player.OPPONENT);
    Test.assertEqual(Player.opponentOf(Player.OPPONENT), Player.ME);
    return true;
}
