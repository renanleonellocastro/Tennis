import Toybox.Lang;
import Toybox.System;

// Every position and size of the match screen, as plain numbers derived
// from the screen size. The rows are percentages of the height chosen so
// each one fits inside the chord of a round screen at that height.
class MatchLayout {
    hidden const SETS_Y = 13;
    hidden const BANNER_Y = 24;
    hidden const POINTS_Y = 46;
    hidden const LABELS_Y = 65;
    hidden const CONTROLS_Y = 77;
    hidden const CONTROLS_TOP = 71;
    hidden const CONTROLS_BOTTOM = 84;
    // The bottom row is sized for the clock and, from the recording
    // milestone on, the heart rate next to it.
    hidden const CLOCK_Y = 89;
    // A screen that is not round has free room at the bottom: its labels
    // sit a little higher and its controls and clock lower, so the three
    // rows do not touch.
    hidden const FLAT_LABELS_SHIFT = -1;
    hidden const FLAT_CONTROLS_SHIFT = 1;
    hidden const FLAT_CLOCK_SHIFT = 3;
    hidden const FOOTER_GAP = 3;
    hidden const HEART_DOT_DIVISOR = 60;
    hidden const PLAYER_X = 23;
    hidden const BALL_X = 12;
    hidden const CONTROL_X = 28;
    hidden const LABEL_GAP = 3;
    hidden const BALL_RADIUS_DIVISOR = 22;
    hidden const POINTS_MAX_WIDTH = 35;
    hidden const POINTS_MAX_HEIGHT = 40;
    hidden const COURT_WIDTH = 15;
    hidden const COURT_HEIGHT = 24;
    hidden const MARKER_RADIUS_DIVISOR = 70;
    // Where the UP and DOWN keys sit on a round five button watch, in the
    // degrees drawArc uses (3 o'clock is zero, counter clockwise).
    hidden const KEY_DEGREES = [180, 210];
    hidden const KEY_HINT_HALF_SWEEP = 5;

    hidden var _width as Number;
    hidden var _height as Number;
    hidden var _hasTouchControls as Boolean;
    hidden var _isRound as Boolean;

    function initialize(width as Number, height as Number, hasTouchControls as Boolean,
                        isRound as Boolean) {
        _width = width;
        _height = height;
        _hasTouchControls = hasTouchControls;
        _isRound = isRound;
    }

    hidden function row(percent as Number) as Number {
        return _height * percent / 100;
    }

    // A row of the lower half, moved by the shift on a screen that is not round.
    hidden function lowRow(percent as Number, flatShift as Number) as Number {
        return row(_isRound ? percent : percent + flatShift);
    }

    // A column given for my side, mirrored for the opponent.
    hidden function column(percent as Number, player as Number) as Number {
        var mine = _width * percent / 100;
        return player == Player.ME ? mine : _width - mine;
    }

    function centerX() as Number {
        return _width / 2;
    }

    function setsY() as Number {
        return row(SETS_Y);
    }

    function bannerY() as Number {
        return row(BANNER_Y);
    }

    function pointsY() as Number {
        return row(POINTS_Y);
    }

    function labelsY() as Number {
        return lowRow(LABELS_Y, FLAT_LABELS_SHIFT);
    }

    function clockY() as Number {
        return lowRow(CLOCK_Y, FLAT_CLOCK_SHIFT);
    }

    // The bottom row.

    function heartDotRadius() as Number {
        return _width / HEART_DOT_DIVISOR + 1;
    }

    // Left edge of the clock, center of the heart dot and left edge of the
    // heart rate, for the widths of the two texts. The row is centered as
    // a whole; without a heart rate (width 0) it is the clock alone.
    function footerXs(clockWidth as Number, heartWidth as Number) as Array<Number> {
        var gap = _width * FOOTER_GAP / 100;
        var extra = heartWidth == 0 ? 0 : heartWidth + 2 * gap + 2 * heartDotRadius();
        var clockX = centerX() - (clockWidth + extra) / 2;
        var dotX = clockX + clockWidth + gap + heartDotRadius();
        return [clockX, dotX, dotX + heartDotRadius() + gap] as Array<Number>;
    }

    function playerX(player as Number) as Number {
        return column(PLAYER_X, player);
    }

    // Center of the serve ball, on the outer side of the player label.
    function ballX(player as Number) as Number {
        return column(BALL_X, player);
    }

    function ballRadius() as Number {
        return _width / BALL_RADIUS_DIVISOR;
    }

    // The edge of the player label that faces its serve ball.
    function labelX(player as Number) as Number {
        var offset = ballRadius() + _width * LABEL_GAP / 100;
        return ballX(player) + (player == Player.ME ? offset : -offset);
    }

    // Points digits.

    function pointsMaxWidth() as Number {
        return _width * POINTS_MAX_WIDTH / 100;
    }

    function pointsMaxHeight() as Number {
        return row(POINTS_MAX_HEIGHT);
    }

    // Index of the first font, largest first, whose [width, height] of the
    // widest score fits its half of the screen. The last one is the fallback.
    function firstFitting(sizes as Array< Array<Number> >) as Number {
        for (var i = 0; i < sizes.size(); i++) {
            if (sizes[i][0] <= pointsMaxWidth() && sizes[i][1] <= pointsMaxHeight()) {
                return i;
            }
        }
        return sizes.size() - 1;
    }

    // Mini court, seen from above with the near end at the bottom.

    // [x, y, width, height]
    function courtRect() as Array<Number> {
        var width = _width * COURT_WIDTH / 100;
        var height = row(COURT_HEIGHT);
        return [centerX() - width / 2, pointsY() - height / 2, width, height] as Array<Number>;
    }

    // A player facing the net has the deuce side on the right hand, so it is
    // the right half of the screen only for the player on the near end.
    function isOnRight(end as Number, side as Number) as Boolean {
        return (end == CourtEnd.NEAR) == (side == ServeSide.DEUCE);
    }

    // The quarter of the court the server stands behind: [x, y, width, height].
    function serveQuarter(end as Number, side as Number) as Array<Number> {
        var court = courtRect();
        var width = court[2] / 2;
        var height = court[3] / 2;
        var x = isOnRight(end, side) ? court[0] + court[2] - width : court[0];
        var y = end == CourtEnd.NEAR ? court[1] + court[3] - height : court[1];
        return [x, y, width, height] as Array<Number>;
    }

    function markerRadius() as Number {
        return _width / MARKER_RADIUS_DIVISOR + 1;
    }

    // Center of a player marker, just behind the baseline of an end: [x, y].
    function markerPoint(end as Number, isOnRightHalf as Boolean) as Array<Number> {
        var court = courtRect();
        var gap = markerRadius() * 2;
        var x = centerX() + (isOnRightHalf ? court[2] / 4 : -court[2] / 4);
        var y = end == CourtEnd.NEAR ? court[1] + court[3] + gap : court[1] - gap;
        return [x, y] as Array<Number>;
    }

    // Key hints on the screen edge.

    // Only a round watch with the UP and DOWN keys has them next to the edge.
    function hasKeyHints() as Boolean {
        return _isRound && !_hasTouchControls;
    }

    // [start, end] of the arc next to the key of a player.
    function keyHintDegrees(player as Number) as Array<Number> {
        var center = KEY_DEGREES[player] as Number;
        return [center - KEY_HINT_HALF_SWEEP, center + KEY_HINT_HALF_SWEEP] as Array<Number>;
    }

    // Menu and serve fault controls for watches that score by touch.

    function hasTouchControls() as Boolean {
        return _hasTouchControls;
    }

    function controlsY() as Number {
        return lowRow(CONTROLS_Y, FLAT_CONTROLS_SHIFT);
    }

    function menuControlX() as Number {
        return column(CONTROL_X, Player.ME);
    }

    function faultControlX() as Number {
        return column(CONTROL_X, Player.OPPONENT);
    }

    function isOnControls(y as Number) as Boolean {
        return _hasTouchControls && y >= lowRow(CONTROLS_TOP, FLAT_CONTROLS_SHIFT)
            && y < lowRow(CONTROLS_BOTTOM, FLAT_CONTROLS_SHIFT);
    }
}
