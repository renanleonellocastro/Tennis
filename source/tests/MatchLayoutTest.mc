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
        var markerReach = layout.markerRadius() * 3;
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
        Test.assertEqual(layout.pointsMaxWidth(), 72);
        Test.assertEqual(layout.pointsMaxHeight(), 83);
        Test.assertEqual(layout.firstFitting([[72, 83], [10, 10]] as Array< Array<Number> >), 0);
        Test.assertEqual(layout.firstFitting([[73, 60], [60, 84], [60, 60]] as Array< Array<Number> >), 2);
        Test.assertEqual(layout.firstFitting([[90, 90], [80, 90]] as Array< Array<Number> >), 1);
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
    function testKeyHintsOnlyOnRoundWatchesThatScoreWithKeys(logger as Test.Logger) as Boolean {
        var layout = new MatchLayout(208, 208, false, true);
        Test.assert(layout.hasKeyHints());
        Test.assert(!new MatchLayout(416, 416, true, true).hasKeyHints());
        Test.assert(!new MatchLayout(320, 360, false, false).hasKeyHints());
        Test.assertEqual(layout.keyHintDegrees(Player.ME)[0], 175);
        Test.assertEqual(layout.keyHintDegrees(Player.ME)[1], 185);
        Test.assertEqual(layout.keyHintDegrees(Player.OPPONENT)[0], 205);
        Test.assertEqual(layout.keyHintDegrees(Player.OPPONENT)[1], 215);
        return true;
    }

    (:test)
    function testControlBandExistsOnlyWithTouchControls(logger as Test.Logger) as Boolean {
        var touch = new MatchLayout(416, 416, true, true);
        var keys = new MatchLayout(208, 208, false, true);
        Test.assert(touch.hasTouchControls());
        Test.assert(!touch.isOnControls(294));
        Test.assert(touch.isOnControls(295));
        Test.assert(touch.isOnControls(348));
        Test.assert(!touch.isOnControls(349));
        Test.assert(touch.controlsY() >= 295 && touch.controlsY() < 349);
        Test.assert(!keys.hasTouchControls());
        Test.assert(!keys.isOnControls(keys.controlsY()));
        return true;
    }
}
