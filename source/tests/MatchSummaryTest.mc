import Toybox.Lang;
import Toybox.Test;

// Tests for the match as the summary fields of the activity file hold it.
module MatchSummaryTests {
    const LONG_TIE_BREAK = "MOMOMOMOMOMOMOMOMOMO";

    // A set that reaches six all and is decided 12-10 in the tie break.
    function playLongTieBreakSet(match as MatchDriver, winner as String) as Void {
        match.games("MOMOMOMOMOMO");
        match.play(LONG_TIE_BREAK + winner + winner);
    }

    (:test)
    function testSetupWordPacksTheVersionTheSetupAndTheTags(logger as Test.Logger) as Boolean {
        Test.assertEqual(MatchSummary.setupWord([0, 0, 0, 0, 0], [0, 0]), 1);
        Test.assertEqual(MatchSummary.setupWord([4, 0, 0, 0, 1], [0, 0]), 1 + (4 << 4));
        Test.assertEqual(MatchSummary.setupWord([1, 1, 1, 1, 0], [2, 1]), 7057);
        Test.assertEqual(MatchSummary.setupWord([0, 0, 0, 0, 0], [3, 2]), 1 + (3 << 10) + (2 << 12));
        return true;
    }

    (:test)
    function testClosedSetScoreIsZerosBeforeTheFirstSetCloses(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        match.games("MMM");
        Test.assertEqual(joinedNumbers(MatchSummary.closedSetScore(match.state())), "0,0,0,0");
        match.games("MMM");
        Test.assertEqual(joinedNumbers(MatchSummary.closedSetScore(match.state())), "6,0,0,0");
        match.games("OOOOOO");
        Test.assertEqual(joinedNumbers(MatchSummary.closedSetScore(match.state())), "0,6,0,0");
        Test.assertEqual(joinedNumbers(MatchSummary.setScore(match.state(), 0)), "6,0,0,0");
        return true;
    }

    (:test)
    function testSetScoreKeepsTheTieBreakPoints(logger as Test.Logger) as Boolean {
        var match = matchAtSixAll(MatchFormat.BEST_OF_3);
        match.play("MMOMMMMM");
        Test.assertEqual(joinedNumbers(MatchSummary.closedSetScore(match.state())), "7,6,7,1");
        Test.assertEqual(MatchSummary.setText(MatchSummary.closedSetScore(match.state())), "7-6(7-1)");
        Test.assertEqual(MatchSummary.setText([6, 3, 0, 0]), "6-3");
        return true;
    }

    (:test)
    function testOpenSetScoreIsThePartPlayed(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        Test.assertEqual(joinedNumbers(MatchSummary.openSetScore(match.state())), "0,0,0,0");
        match.games("MMO");
        match.play("M");
        Test.assertEqual(joinedNumbers(MatchSummary.openSetScore(match.state())), "2,1,0,0");
        match = matchAtSixAll(MatchFormat.BEST_OF_3);
        match.play("MMO");
        Test.assertEqual(joinedNumbers(MatchSummary.openSetScore(match.state())), "6,6,2,1");
        return true;
    }

    (:test)
    function testOpenSetScoreOfADecidedMatchIsItsLastSet(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.ONE_SET);
        match.games("MMMMOMM");
        Test.assertEqual(joinedNumbers(MatchSummary.openSetScore(match.state())), "6,1,0,0");
        return true;
    }

    (:test)
    function testScoreTextReadsAsOnAScoreboard(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        Test.assertEqual(MatchSummary.scoreText(match.state()), "0-0");
        match.games("MOMOMOMOMOMO");
        match.play("MMMMMOOMM");
        Test.assertEqual(MatchSummary.scoreText(match.state()), "7-6(7-2) 0-0");
        match.games("MMMOOO");
        Test.assertEqual(MatchSummary.scoreText(match.state()), "7-6(7-2) 3-3");
        match.games("MMM");
        Test.assertEqual(MatchSummary.scoreText(match.state()), "7-6(7-2) 6-3");
        return true;
    }

    // The field has room for 31 characters and the closing zero.
    (:test)
    function testScoreTextIsCutToTheRoomOfTheField(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.BEST_OF_3);
        playLongTieBreakSet(match, "M");
        playLongTieBreakSet(match, "O");
        playLongTieBreakSet(match, "M");
        Test.assert(match.state().isFinished());
        Test.assertEqual(MatchSummary.scoreText(match.state()), "7-6(12-10) 6-7(10-12) 7-6(12-10");
        return true;
    }

    (:test)
    function testFieldsAreTheWordTheTextTheCountsAndTheSet(logger as Test.Logger) as Boolean {
        var match = newMatch(MatchFormat.ONE_SET);
        match.games("MMO");
        var fields = MatchSummary.fields([2, 0, 0, 0, 0], [1, 2], match.engine);
        var counts = fields[2] as Array<Number>;
        Test.assertEqual(fields[0] as Number, 1 + (2 << 4) + (1 << 10) + (2 << 12));
        Test.assertEqual(fields[1] as String, "2-1");
        Test.assertEqual(counts.size(), RecordingFields.STATISTICS_COUNT);
        Test.assertEqual(counts[Stat.POINTS_WON * Player.COUNT + Player.ME], 8);
        Test.assertEqual(counts[Stat.POINTS_WON * Player.COUNT + Player.OPPONENT], 4);
        Test.assertEqual(joinedNumbers(fields[3] as Array<Number>), "2,1,0,0");
        return true;
    }
}
