import Toybox.Lang;
import Toybox.Test;

// Tests for every statistic, always for both players. Unless a test says
// otherwise I serve first, so the opponent serves the second game.

function assertCounts(statistics as MatchStatistics, stat as Number, mine as Number, theirs as Number) as Void {
    Test.assertEqual(statistics.count(stat, Player.ME), mine);
    Test.assertEqual(statistics.count(stat, Player.OPPONENT), theirs);
}

(:test)
function testNewMatchHasEmptyStatistics(logger as Test.Logger) as Boolean {
    var statistics = newMatch(MatchFormat.BEST_OF_3).statistics();
    for (var stat = 0; stat < Stat.COUNT; stat++) {
        assertCounts(statistics, stat, 0, 0);
    }
    Test.assertEqual(statistics.firstServePercent(Player.ME), 0);
    Test.assertEqual(statistics.gameDurations().size(), 0);
    Test.assertEqual(statistics.setDurations().size(), 0);
    Test.assertEqual(statistics.averageSecondsBetweenPoints(), 0.0);
    Test.assert(statistics.averageDecidingHeartRate() == null);
    return true;
}

(:test)
function testAcesAndWinnersBelongToThePointWinner(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.detailed(Player.ME, Ending.ACE, null);
    match.detailed(Player.ME, Ending.ACE, null);
    match.detailed(Player.ME, Ending.WINNER, null);
    match.detailed(Player.OPPONENT, Ending.WINNER, null);
    match.detailed(Player.ME, Ending.NONE, null);
    match.detailed(Player.OPPONENT, Ending.ACE, null);
    var statistics = match.statistics();
    assertCounts(statistics, Stat.ACES, 2, 1);
    assertCounts(statistics, Stat.WINNERS, 1, 1);
    assertCounts(statistics, Stat.ERRORS_NET, 0, 0);
    assertCounts(statistics, Stat.ERRORS_OUT, 0, 0);
    return true;
}

(:test)
function testErrorsBelongToThePlayerWhoLostThePoint(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.detailed(Player.ME, Ending.ERROR_NET, null);
    match.detailed(Player.ME, Ending.ERROR_OUT, null);
    match.detailed(Player.ME, Ending.ERROR_OUT, null);
    match.detailed(Player.OPPONENT, Ending.ERROR_NET, null);
    var statistics = match.statistics();
    assertCounts(statistics, Stat.ERRORS_NET, 1, 1);
    assertCounts(statistics, Stat.ERRORS_OUT, 0, 2);
    assertCounts(statistics, Stat.WINNERS, 0, 0);
    assertCounts(statistics, Stat.ACES, 0, 0);
    return true;
}

(:test)
function testSimpleModeCountsNoEndings(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MOMOFFMM");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.ACES, 0, 0);
    assertCounts(statistics, Stat.WINNERS, 0, 0);
    assertCounts(statistics, Stat.ERRORS_NET, 0, 0);
    assertCounts(statistics, Stat.ERRORS_OUT, 0, 0);
    return true;
}

(:test)
function testDoubleFaultsCountForTheServer(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("FFFMFFM");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.DOUBLE_FAULTS, 2, 0);
    assertCounts(statistics, Stat.POINTS_WON, 2, 2);
    match.play("OOFF");
    Test.assertEqual(match.score(), "0-0 0-1 15-0");
    assertCounts(match.statistics(), Stat.DOUBLE_FAULTS, 2, 1);
    return true;
}

(:test)
function testFirstServePercentageAndPointsWonByServe(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MFMFFO");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.SERVICE_POINTS, 4, 0);
    assertCounts(statistics, Stat.FIRST_SERVES_IN, 2, 0);
    Test.assertEqual(statistics.firstServePercent(Player.ME), 50);
    Test.assertEqual(statistics.firstServePercent(Player.OPPONENT), 0);
    assertCounts(statistics, Stat.FIRST_SERVE_POINTS_WON, 1, 0);
    assertCounts(statistics, Stat.SECOND_SERVE_POINTS_WON, 1, 0);
    Test.assertEqual(statistics.secondServePoints(Player.ME), 2);
    Test.assertEqual(statistics.secondServePoints(Player.OPPONENT), 0);
    return true;
}

(:test)
function testServeNumbersOfTheOpponent(logger as Test.Logger) as Boolean {
    var match = new MatchDriver(MatchFormat.BEST_OF_3, false, Player.OPPONENT);
    match.play("OFOM");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.SERVICE_POINTS, 0, 3);
    assertCounts(statistics, Stat.FIRST_SERVES_IN, 0, 2);
    assertCounts(statistics, Stat.FIRST_SERVE_POINTS_WON, 0, 1);
    assertCounts(statistics, Stat.SECOND_SERVE_POINTS_WON, 0, 1);
    Test.assertEqual(statistics.firstServePercent(Player.OPPONENT), 67);
    Test.assertEqual(statistics.secondServePoints(Player.OPPONENT), 1);
    return true;
}

(:test)
function testFirstServePercentageRoundsDown(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MFMFM");
    Test.assertEqual(match.statistics().firstServePercent(Player.ME), 33);
    return true;
}

(:test)
function testServiceAndReturnGames(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MOOMM");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.SERVICE_GAMES_PLAYED, 3, 2);
    assertCounts(statistics, Stat.SERVICE_GAMES_WON, 2, 1);
    Test.assertEqual(statistics.returnGamesPlayed(Player.ME), 2);
    Test.assertEqual(statistics.returnGamesWon(Player.ME), 1);
    Test.assertEqual(statistics.returnGamesPlayed(Player.OPPONENT), 3);
    Test.assertEqual(statistics.returnGamesWon(Player.OPPONENT), 1);
    return true;
}

(:test)
function testTieBreakIsNotAServiceGame(logger as Test.Logger) as Boolean {
    var match = matchAtSixAll(MatchFormat.BEST_OF_3);
    match.play("MMMMMMM");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.SERVICE_GAMES_PLAYED, 6, 6);
    assertCounts(statistics, Stat.SERVICE_GAMES_WON, 6, 6);
    assertCounts(statistics, Stat.SERVICE_POINTS, 27, 28);
    Test.assertEqual(statistics.gameDurations().size(), 13);
    return true;
}

(:test)
function testBreakPointsWonAndSaved(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("OOOMMO");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.BREAK_POINT_CHANCES, 0, 3);
    assertCounts(statistics, Stat.BREAK_POINTS_WON, 0, 1);
    Test.assertEqual(statistics.breakPointsFaced(Player.ME), 3);
    Test.assertEqual(statistics.breakPointsSaved(Player.ME), 2);
    Test.assertEqual(statistics.breakPointsFaced(Player.OPPONENT), 0);
    Test.assertEqual(statistics.breakPointsSaved(Player.OPPONENT), 0);
    return true;
}

(:test)
function testBreakPointsForMeOnTheOpponentServe(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("M");
    match.play("MMMOOOMOMM");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.BREAK_POINT_CHANCES, 5, 0);
    assertCounts(statistics, Stat.BREAK_POINTS_WON, 1, 0);
    Test.assertEqual(statistics.breakPointsFaced(Player.OPPONENT), 5);
    Test.assertEqual(statistics.breakPointsSaved(Player.OPPONENT), 4);
    return true;
}

(:test)
function testNoAdvantageDecidingPointIsABreakPoint(logger as Test.Logger) as Boolean {
    var match = new MatchDriver(MatchFormat.BEST_OF_3, true, Player.ME);
    match.play("MMMOOOM");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.BREAK_POINT_CHANCES, 0, 1);
    assertCounts(statistics, Stat.BREAK_POINTS_WON, 0, 0);
    Test.assertEqual(statistics.breakPointsSaved(Player.ME), 1);
    return true;
}

(:test)
function testDoubleFaultOnBreakPointConvertsIt(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("OOOFF");
    var statistics = match.statistics();
    assertCounts(statistics, Stat.BREAK_POINT_CHANCES, 0, 1);
    assertCounts(statistics, Stat.BREAK_POINTS_WON, 0, 1);
    return true;
}

(:test)
function testTieBreakPointsAreNotBreakPoints(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    match.play("OOOOOOMO");
    assertCounts(match.statistics(), Stat.BREAK_POINT_CHANCES, 0, 0);
    return true;
}

(:test)
function testTotalPointsWonIncludeDoubleFaults(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MMOFFMFO");
    assertCounts(match.statistics(), Stat.POINTS_WON, 3, 3);
    return true;
}

(:test)
function testLongestRunOfPointsForEachPlayer(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("MMOMMMOOM");
    assertCounts(match.statistics(), Stat.LONGEST_RUN, 3, 2);
    return true;
}

(:test)
function testLongestRunSpansGamesAndIgnoresFirstFaults(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("OMMMFMMFMO");
    assertCounts(match.statistics(), Stat.LONGEST_RUN, 6, 1);
    return true;
}

(:test)
function testGameAndSetDurationsFollowTheMatchClock(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("M");
    match.play("OMOOFO");
    var statistics = match.statistics();
    Test.assertEqual(statistics.gameDurations().size(), 2);
    Test.assertEqual(statistics.gameDurations()[0], 40);
    Test.assertEqual(statistics.gameDurations()[1], 60);
    Test.assertEqual(statistics.setDurations().size(), 0);
    return true;
}

(:test)
function testSetDurationsOfEveryFinishedSet(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.games("MMMMMM");
    match.games("OOOOO");
    var statistics = match.statistics();
    Test.assertEqual(statistics.setDurations().size(), 1);
    Test.assertEqual(statistics.setDurations()[0], 240);
    match.play("MMMOOOMOMOOO");
    statistics = match.statistics();
    Test.assertEqual(statistics.setDurations().size(), 2);
    Test.assertEqual(statistics.setDurations()[1], 320);
    Test.assertEqual(statistics.gameDurations().size(), 12);
    Test.assertEqual(statistics.gameDurations()[11], 120);
    return true;
}

(:test)
function testTieBreakOnlyMatchHasOneGameAndOneSetDuration(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    match.play("MMMMMMM");
    var statistics = match.statistics();
    Test.assertEqual(statistics.gameDurations().size(), 1);
    Test.assertEqual(statistics.gameDurations()[0], 70);
    Test.assertEqual(statistics.setDurations()[0], 70);
    assertCounts(statistics, Stat.SERVICE_GAMES_PLAYED, 0, 0);
    return true;
}

(:test)
function testAverageTimeBetweenPointsSkipsFaults(logger as Test.Logger) as Boolean {
    var engine = newMatch(MatchFormat.BEST_OF_3).engine;
    engine.point(Player.ME, Ending.NONE, 10, null);
    Test.assertEqual(engine.statistics().averageSecondsBetweenPoints(), 0.0);
    engine.fault(18, null);
    engine.point(Player.ME, Ending.NONE, 25, null);
    engine.point(Player.OPPONENT, Ending.NONE, 55, null);
    Test.assertEqual(engine.statistics().averageSecondsBetweenPoints(), 22.5);
    return true;
}

(:test)
function testAverageHeartRateCountsOnlyDecidingPoints(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.detailed(Player.OPPONENT, Ending.NONE, 100);
    match.detailed(Player.OPPONENT, Ending.NONE, 110);
    match.detailed(Player.OPPONENT, Ending.NONE, 120);
    Test.assert(match.statistics().averageDecidingHeartRate() == null);
    match.detailed(Player.ME, Ending.NONE, 150);
    match.detailed(Player.ME, Ending.NONE, null);
    match.detailed(Player.ME, Ending.NONE, 161);
    Test.assertEqual(match.statistics().averageDecidingHeartRate() as Number, 156);
    match.detailed(Player.ME, Ending.NONE, 190);
    Test.assertEqual(match.statistics().averageDecidingHeartRate() as Number, 156);
    return true;
}

(:test)
function testAverageHeartRateCountsSetAndMatchPoints(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.TIE_BREAK_ONLY);
    match.play("MMMMMM");
    match.detailed(Player.OPPONENT, Ending.NONE, 170);
    match.engine.fault(match.clock, 90);
    match.detailed(Player.ME, Ending.NONE, 180);
    Test.assert(match.state().isFinished());
    Test.assertEqual(match.statistics().averageDecidingHeartRate() as Number, 175);
    return true;
}

(:test)
function testHeartRateOfADoubleFaultOnADecidingPointCounts(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.play("OOO");
    match.engine.fault(40, 140);
    match.engine.fault(45, 144);
    Test.assertEqual(match.statistics().averageDecidingHeartRate() as Number, 144);
    return true;
}

(:test)
function testStatisticsFollowUndo(logger as Test.Logger) as Boolean {
    var match = newMatch(MatchFormat.BEST_OF_3);
    match.detailed(Player.ME, Ending.ACE, null);
    match.detailed(Player.ME, Ending.ACE, null);
    match.play("MM");
    match.engine.undo();
    match.engine.undo();
    match.engine.undo();
    var statistics = match.statistics();
    assertCounts(statistics, Stat.ACES, 1, 0);
    assertCounts(statistics, Stat.POINTS_WON, 1, 0);
    assertCounts(statistics, Stat.SERVICE_GAMES_PLAYED, 0, 0);
    Test.assertEqual(statistics.gameDurations().size(), 0);
    return true;
}
