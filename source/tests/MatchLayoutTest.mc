import Toybox.Lang;
import Toybox.Test;

// Tests for the layout numbers on the three screen shapes the app builds
// for: small round with keys, large round touch and rectangular touch.
module MatchLayoutTests {
    function testLayouts() as Array<MatchLayout> {
        return [new MatchLayout(208, 208, false, true), new MatchLayout(416, 416, true, true),
                new MatchLayout(320, 360, true, false)] as Array<MatchLayout>;
    }

    function assertRowsDoNotOverlap(layout as MatchLayout) as Void {
        var court = layout.courtRect();
        var markerReach = layout.markerRadius() * 5 / 2;
        Test.assert(layout.setsY() < layout.bannerY());
        Test.assert(layout.bannerY() < court[1] - markerReach);
        Test.assert(court[1] + court[3] + markerReach < layout.labelsY());
        Test.assert(layout.labelsY() + layout.ballRadius() < layout.controlsY());
        Test.assert(layout.controlsY() < layout.clockY());
    }

    function assertPointsClearTheCourt(layout as MatchLayout) as Void {
        var court = layout.courtRect();
        var halfPoints = layout.pointsMaxWidth() / 2;
        Test.assert(layout.playerX(Player.ME) + halfPoints < court[0]);
        Test.assert(layout.playerX(Player.OPPONENT) - halfPoints > court[0] + court[2]);
        Test.assert(layout.playerX(Player.ME) - halfPoints > 0);
    }

    (:test)
    function testLayoutRowsAndColumnsDoNotOverlapOnAnyShape(logger as Test.Logger) as Boolean {
        var layouts = testLayouts();
        for (var i = 0; i < layouts.size(); i++) {
            assertRowsDoNotOverlap(layouts[i]);
            assertPointsClearTheCourt(layouts[i]);
        }
        return true;
    }

    (:test)
    function testLayoutMirrorsTheOpponentSide(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(320, 360, true, false);
        Test.assertEqual(layout.centerX(), 160);
        Test.assertEqual(layout.playerX(Player.ME) + layout.playerX(Player.OPPONENT), 320);
        Test.assertEqual(layout.ballX(Player.ME) + layout.ballX(Player.OPPONENT), 320);
        Test.assertEqual(layout.labelX(Player.ME) + layout.labelX(Player.OPPONENT), 320);
        Test.assertEqual(layout.menuControlX() + layout.faultControlX(), 320);
        Test.assert(layout.labelX(Player.ME) > layout.ballX(Player.ME) + layout.ballRadius());
        return true;
    }

    // The serve ball is the item closest to the edge of a round screen.
    (:test)
    function testServeBallStaysInsideARoundScreen(logger as Test.Logger) as Boolean {
        var sizes = [208, 218, 240, 260, 280, 390, 416, 454];
        for (var i = 0; i < sizes.size(); i++) {
            var layout = new MatchLayout(sizes[i], sizes[i], false, true);
            var radius = sizes[i] / 2;
            var dx = radius - (layout.ballX(Player.ME) - layout.ballRadius());
            var dy = layout.labelsY() - radius;
            Test.assert(dx * dx + dy * dy < radius * radius);
        }
        return true;
    }

    (:test)
    function testFirstFittingPicksTheLargestFontThatFits(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(208, 208, false, true);
        Test.assertEqual(layout.pointsMaxWidth(), 64);
        Test.assertEqual(layout.pointsMaxHeight(), 73);
        Test.assertEqual(layout.firstFitting([[64, 73], [10, 10]] as Array< Array<Number> >), 0);
        Test.assertEqual(layout.firstFitting([[65, 60], [60, 74], [60, 60], [9, 9]] as Array< Array<Number> >), 2);
        Test.assertEqual(layout.firstFitting([[90, 90], [80, 90]] as Array< Array<Number> >), 1);
        return true;
    }

    // The numbers of the Forerunner 55: the step under the font that fits
    // the whole screen is less than half its size, so that font stays.
    (:test)
    function testAWatchWithFewFontStepsKeepsTheFontThatFitsTheScreen(logger as Test.Logger) as Boolean {
        var sizes = [[78, 90], [78, 90], [70, 79], [32, 37]] as Array< Array<Number> >;
        Test.assertEqual(new MatchLayout(208, 208, false, true).firstFitting(sizes), 2);
        Test.assertEqual(new MatchLayout(208, 208, true, true).firstFitting(sizes), 2);
        Test.assertEqual(new MatchLayout(416, 416, false, true).firstFitting(sizes), 0);
        return true;
    }

    // The names sit two percent lower next to the key labels, clear of the
    // score digits, which a watch with few font steps cannot shrink.
    (:test)
    function testTheNamesSitLowerNextToTheKeyLabels(logger as Test.Logger) as Boolean {
        Test.assertEqual(new MatchLayout(208, 208, true, true).labelsY(), 135);
        Test.assertEqual(new MatchLayout(208, 208, false, true).labelsY(), 134);
        Test.assertEqual(new MatchLayout(208, 208, false, true).labelsY(), 12 + 183 * 67 / 100);
        return true;
    }

    // Next to the key labels everything but the labels is 12 percent
    // smaller around the middle of the screen; elsewhere nothing changes.
    (:test)
    function testTheContentShrinksAroundTheMiddleNextToTheKeyLabels(logger as Test.Logger) as Boolean {
        var keys = new MatchLayout(208, 208, false, true);
        var touch = new MatchLayout(208, 208, true, true);
        Test.assertEqual(touch.roomOf([100, 100] as Array<Number>).toString(), "[208, 208]");
        Test.assertEqual(keys.roomOf([100, 100] as Array<Number>).toString(), "[183, 183]");
        Test.assertEqual(touch.playerX(Player.ME), 47);
        Test.assertEqual(keys.playerX(Player.ME), 54);
        Test.assertEqual(touch.setsY(), 27);
        Test.assertEqual(keys.setsY(), 35);
        Test.assertEqual(keys.courtRect().toString(), "[94, 78, 20, 36]");
        Test.assertEqual(keys.centerX(), touch.centerX());
        return true;
    }

    (:test)
    function testDeuceSideIsOnTheRightOnlyFromTheNearEnd(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(208, 208, false, true);
        Test.assert(layout.isOnRight(CourtEnd.NEAR, ServeSide.DEUCE));
        Test.assert(!layout.isOnRight(CourtEnd.NEAR, ServeSide.AD));
        Test.assert(!layout.isOnRight(CourtEnd.FAR, ServeSide.DEUCE));
        Test.assert(layout.isOnRight(CourtEnd.FAR, ServeSide.AD));
        return true;
    }

    function assertQuarter(end as Number, side as Number, isRight as Boolean, isBottom as Boolean) as Void {
        var layout = new MatchLayout(416, 416, true, true);
        var court = layout.courtRect();
        var quarter = layout.serveQuarter(end, side);
        Test.assertEqual(quarter[0] > court[0], isRight);
        Test.assertEqual(quarter[1] > court[1], isBottom);
        Test.assertEqual(quarter[2], court[2] / 2);
        Test.assertEqual(quarter[3], court[3] / 2);
        Test.assert(quarter[0] + quarter[2] <= court[0] + court[2]);
        Test.assert(quarter[1] + quarter[3] <= court[1] + court[3]);
    }

    (:test)
    function testServeQuarterIsTheCornerOfTheServer(logger as Test.Logger) as Boolean {
        assertQuarter(CourtEnd.NEAR, ServeSide.DEUCE, true, true);
        assertQuarter(CourtEnd.NEAR, ServeSide.AD, false, true);
        assertQuarter(CourtEnd.FAR, ServeSide.DEUCE, false, false);
        assertQuarter(CourtEnd.FAR, ServeSide.AD, true, false);
        return true;
    }

    (:test)
    function testPlayerMarkersSitBehindTheirBaseline(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(208, 208, false, true);
        var court = layout.courtRect();
        var near = layout.markerPoint(CourtEnd.NEAR, true);
        var far = layout.markerPoint(CourtEnd.FAR, false);
        Test.assert(near[1] - layout.markerRadius() > court[1] + court[3]);
        Test.assert(far[1] + layout.markerRadius() < court[1]);
        Test.assert(near[0] > layout.centerX() && near[0] < court[0] + court[2]);
        Test.assert(far[0] < layout.centerX() && far[0] > court[0]);
        return true;
    }

    (:test)
    function testKeyLabelsOnlyOnRoundWatchesThatScoreWithKeys(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(208, 208, false, true);
        Test.assert(layout.hasKeyHints());
        Test.assert(!new MatchLayout(416, 416, true, true).hasKeyHints());
        Test.assert(!new MatchLayout(320, 360, false, false).hasKeyHints());
        Test.assert(!new MatchLayout(320, 360, true, false).hasKeyHints());
        return true;
    }

    (:test, :keyArc)
    function testTheLayoutKnowsARoundScreen(logger as Test.Logger) as Boolean {
        Test.assert(new MatchLayout(416, 416, true, true).isRound());
        Test.assert(!new MatchLayout(320, 360, true, false).isRound());
        return true;
    }

    // UP and START are at their keys; DOWN and BACK a little below theirs,
    // away from the serve ball.
    (:test)
    function testEveryKeyLabelSitsAtItsKey(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(208, 208, false, true);
        Test.assertEqual(layout.keyDegrees(KeySlot.UP), 180);
        Test.assertEqual(layout.keyDegrees(KeySlot.START), 30);
        Test.assertEqual(layout.keyDegrees(KeySlot.DOWN), 213);
        Test.assertEqual(layout.keyDegrees(KeySlot.BACK), 327);
        Test.assertEqual(layout.keyPoint(KeySlot.UP).toString(), "[4, 104]");
        Test.assertEqual(layout.keyPoint(KeySlot.START).toString(), "[191, 54]");
        Test.assertEqual(layout.keyPoint(KeySlot.DOWN).toString(), "[20, 158]");
        Test.assertEqual(layout.keyPoint(KeySlot.BACK).toString(), "[188, 158]");
        return true;
    }

    // The two labels of the left keys, which are close, get less room than
    // the two of the right keys.
    (:test)
    function testTheLabelsOfOneSideShareItsRoom(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(208, 208, false, true);
        Test.assertEqual(layout.keyRoom(KeySlot.UP), 89);
        Test.assertEqual(layout.keyRoom(KeySlot.DOWN), 89);
        Test.assertEqual(layout.keyRoom(KeySlot.START), 124);
        Test.assertEqual(layout.keyRoom(KeySlot.BACK), 124);
        return true;
    }

    const ROUND_SIZES = [208, 218, 240, 260, 280, 390, 416, 454];

    // The inner radius of the ring the key labels live in.
    function ringInside(layout as MatchLayout) as Number {
        return layout.keyArc()[0] - layout.keyArc()[1] / 2;
    }

    // The labels are capitals of about 3 percent of the screen in a ring
    // that ends within 2 percent of the edge.
    (:test)
    function testTheKeyLabelRingIsThinAndHugsTheEdge(logger as Test.Logger) as Boolean {
        for (var i = 0; i < ROUND_SIZES.size(); i++) {
            var size = ROUND_SIZES[i];
            var arc = new MatchLayout(size, size, false, true).keyArc();
            var outside = arc[0] + (arc[1] + 1) / 2;
            Test.assert(arc[1] * 1000 <= size * 35 && arc[1] * 1000 >= size * 25);
            Test.assert(outside < size / 2);
            Test.assert(outside >= size / 2 - size / 50 - 1);
        }
        return true;
    }

    // Squared distance from the middle of the screen.
    function reach(layout as MatchLayout, x as Number, y as Number) as Number {
        var dx = x - layout.centerX();
        var dy = y - layout.centerY();
        return dx * dx + dy * dy;
    }

    // The numbers of the score, as wide as the whole screen lets them be,
    // the serve ball and the ink of the banner all end at least the gap
    // inside the ring of the key labels. The set score is at the top, where
    // no key is.
    function assertScoreClearsTheRing(layout as MatchLayout, gap as Number) as Void {
        var limit = ringInside(layout) - gap;
        var ballEdge = layout.ballX(Player.ME) - layout.ballRadius();
        var banner = layout.roomOf(layout.BANNER_ROOM);
        var halfPoints = layout.centerX() * 35 / 100;
        Test.assert(layout.centerX() - (layout.playerX(Player.ME) - halfPoints) <= limit);
        Test.assert(reach(layout, ballEdge, layout.labelsY() + layout.ballRadius() / 2) <= limit * limit);
        Test.assert(reach(layout, layout.centerX() + banner[0] / 2, layout.bannerY() - banner[1] / 3) <= limit * limit);
    }

    // The clear band between the labels and the content is at least 3
    // percent of the screen on every round size.
    (:test)
    function testTheKeyLabelRingNeverMeetsTheScore(logger as Test.Logger) as Boolean {
        for (var i = 0; i < ROUND_SIZES.size(); i++) {
            var size = ROUND_SIZES[i];
            assertScoreClearsTheRing(new MatchLayout(size, size, false, true), size * 3 / 100);
        }
        return true;
    }

    // A screen that is not round and a watch that scores by touch have no
    // ring: the score has the whole width.
    (:test)
    function testScreensWithoutKeyLabelsKeepTheWideBanner(logger as Test.Logger) as Boolean {
        var flat = new MatchLayout(320, 360, true, false);
        var keys = new MatchLayout(260, 260, false, true);
        Test.assert(!flat.hasKeyHints());
        Test.assertEqual(flat.roomOf(flat.BANNER_ROOM).toString(), "[243, 46]");
        Test.assertEqual(new MatchLayout(260, 260, true, true).roomOf(flat.BANNER_ROOM).toString(), "[197, 33]");
        Test.assertEqual(keys.roomOf(keys.BANNER_ROOM).toString(), "[173, 29]");
        Test.assertEqual(flat.roomOf([50, 10] as Array<Number>).toString(), "[160, 36]");
        return true;
    }

    // Next to the key labels the ball is smaller and closer to the middle,
    // and so is the label of the player.
    (:test)
    function testTheServeBallSitsBetweenTheEdgeAndTheLabel(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(208, 208, false, true);
        Test.assertEqual(layout.labelX(Player.ME), 46);
        Test.assertEqual(layout.labelX(Player.OPPONENT), 162);
        Test.assertEqual(layout.ballRadius(), 8);
        Test.assertEqual(layout.ballX(Player.ME), 33);
        Test.assertEqual(layout.ballX(Player.OPPONENT), 175);
        var touch = new MatchLayout(208, 208, true, true);
        Test.assertEqual(touch.labelX(Player.ME), 39);
        Test.assertEqual(touch.ballRadius(), 9);
        Test.assertEqual(touch.ballX(Player.ME), 24);
        return true;
    }

    (:test)
    function testTouchControlsAreWiderOnAScreenThatIsNotRound(logger as Test.Logger) as Boolean {
        Test.assertEqual(new MatchLayout(416, 416, true, true).controlRoom().toString(), "[124, 37]");
        Test.assertEqual(new MatchLayout(320, 360, true, false).controlRoom().toString(), "[121, 39]");
        return true;
    }

    (:test)
    function testControlBandExistsOnlyWithTouchControls(logger as Test.Logger) as Boolean {
        var touch = new MatchLayout(416, 416, true, true);
        var keys = new MatchLayout(208, 208, false, true);
        Test.assert(touch.hasTouchControls());
        Test.assert(!touch.isOnControls(302));
        Test.assert(touch.isOnControls(303));
        Test.assert(touch.isOnControls(348));
        Test.assert(!touch.isOnControls(349));
        Test.assert(touch.controlsY() >= 303 && touch.controlsY() < 349);
        Test.assert(!keys.hasTouchControls());
        Test.assert(!keys.isOnControls(keys.controlsY()));
        return true;
    }

    // A screen that is not round spreads its lower rows: 64, 79 and 92
    // percent of the height instead of 65, 78 and 89.
    (:test)
    function testLowerRowsSpreadOnAScreenThatIsNotRound(logger as Test.Logger) as Boolean {
        var flat = new MatchLayout(320, 360, true, false);
        var round = new MatchLayout(360, 360, true, true);
        Test.assertEqual(flat.labelsY(), 230);
        Test.assertEqual(flat.controlsY(), 284);
        Test.assertEqual(flat.clockY(), 331);
        Test.assertEqual(round.labelsY(), 234);
        Test.assertEqual(round.controlsY(), 280);
        Test.assertEqual(round.clockY(), 320);
        return true;
    }

    // With no touch controls above it, the clock of a round screen sits at
    // 86 percent of the height of its content, where the screen is wider.
    (:test)
    function testClockSitsHigherOnARoundScreenWithoutTouchControls(logger as Test.Logger) as Boolean {
        Test.assertEqual(new MatchLayout(208, 208, false, true).clockY(), 169);
        Test.assertEqual(new MatchLayout(208, 208, true, true).clockY(), 185);
        return true;
    }

    (:test)
    function testControlBandFollowsTheControlsOnAScreenThatIsNotRound(logger as Test.Logger) as Boolean {
        var flat = new MatchLayout(320, 360, true, false);
        Test.assert(!flat.isOnControls(265));
        Test.assert(flat.isOnControls(266));
        Test.assert(flat.isOnControls(flat.controlsY()));
        Test.assert(flat.isOnControls(305));
        Test.assert(!flat.isOnControls(306));
        return true;
    }

    (:test)
    function testFooterCentersTheClockAloneWithoutAHeartRate(logger as Test.Logger) as Boolean {
        var layouts = testLayouts();
        for (var i = 0; i < layouts.size(); i++) {
            Test.assertEqual(layouts[i].footerXs(40, 0)[0], layouts[i].centerX() - 20);
        }
        return true;
    }

    // The clock, the dot and the heart rate follow each other without
    // touching, and the row as a whole sits in the middle.
    (:test)
    function testFooterPutsTheHeartRateAfterTheClock(logger as Test.Logger) as Boolean {
        var layouts = testLayouts();
        for (var i = 0; i < layouts.size(); i++) {
            var xs = layouts[i].footerXs(60, 30);
            var radius = layouts[i].heartDotRadius();
            Test.assert(radius > 0);
            Test.assert(xs[0] + 60 < xs[1] - radius);
            Test.assert(xs[1] + radius < xs[2]);
            Test.assert((xs[0] + xs[2] + 30) / 2 - layouts[i].centerX() <= 1);
            Test.assert(layouts[i].centerX() - (xs[0] + xs[2] + 30) / 2 <= 1);
        }
        return true;
    }
}
