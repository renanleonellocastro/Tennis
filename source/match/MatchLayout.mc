import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// The keys that get a label on the match and practice screens. Even slots
// are on the left of the watch and odd ones on the right; the first two are
// the upper keys.
module KeySlot {
    const UP = 0;
    const START = 1;
    const DOWN = 2;
    const BACK = 3;
    const COUNT = 4;
    const PER_ROW = 2;
}

// Every position and size of the match screen, as plain numbers derived
// from the screen size. The rows are percentages of the height chosen so
// each one fits inside the chord of a round screen at that height.
class MatchLayout {
    hidden const SETS_Y = 13;
    hidden const BANNER_Y = 24;
    hidden const POINTS_Y = 46;
    hidden const LABELS_Y = 65;
    hidden const CONTROLS_Y = 78;
    hidden const CONTROLS_TOP = 73;
    hidden const CONTROLS_BOTTOM = 84;
    // The bottom row is sized for the clock and, from the recording
    // milestone on, the heart rate next to it.
    hidden const CLOCK_Y = 89;
    // A screen that is not round has free room at the bottom: its labels
    // sit a little higher and its controls and clock lower, so the three
    // rows do not touch.
    hidden const FLAT_LABELS_SHIFT = -1;
    // Next to the key labels the names sit a little lower, clear of the score.
    hidden const KEYS_LABELS_SHIFT = 2;
    hidden const FLAT_CONTROLS_SHIFT = 1;
    hidden const FLAT_CLOCK_SHIFT = 3;
    // A round screen with no touch controls has free room above the clock:
    // it sits higher, where the screen is wider, so a clock over an hour
    // with a heart rate of three digits stays clear of the edge.
    hidden const KEYS_CLOCK_SHIFT = -3;
    hidden const FOOTER_GAP = 2;
    hidden const HEART_DOT_DIVISOR = 60;
    hidden const PLAYER_X = 23;
    hidden const BALL_X = 12;
    hidden const CONTROL_X = 30;
    hidden const LABEL_GAP = 3;
    hidden const BALL_RADIUS_DIVISOR = 22;
    hidden const POINTS_MAX_WIDTH = 35;
    hidden const POINTS_MAX_HEIGHT = 40;
    hidden const COURT_WIDTH = 11;
    hidden const COURT_HEIGHT = 20;
    hidden const MARKER_RADIUS_DIVISOR = 60;
    // Where the UP, START, DOWN and BACK keys sit on a round five button
    // watch, in the degrees drawArc uses (3 o'clock is zero, counter
    // clockwise). The order is the one of the key slots.
    hidden const KEY_DEGREES = [180, 30, 213, 327];
    // The labels of the keys follow the round edge in a thin ring: the
    // radius of the middle of their letters and the height of the capitals,
    // then the mean width the two labels of a side may have, on the left,
    // where the keys are close, and on the right. All in per mille of the
    // width. tools/key_labels.py reads these two lines and the key angles.
    hidden const KEY_ARC = [481, 30];
    hidden const KEY_ROOMS = [215, 300];
    hidden const PER_MILLE = 1000;
    // A watch with the labels of the keys draws everything else this much
    // smaller, in percent, around the middle of the screen: the labels get
    // a clear ring of their own at the edge.
    hidden const KEYS_SCALE = 88;
    // The room of the texts whose font follows the screen, as [width,
    // height] in percent of the screen: the set score, the banner, the label
    // of a player and the outline of a touch control.
    const SETS_ROOM = [56, 14];
    const BANNER_ROOM = [76, 13];
    const LABEL_ROOM = [21, 12];
    // A screen that is not round has the width for wider touch controls.
    hidden const CONTROL_ROOM = [30, 9];
    hidden const FLAT_CONTROL_ROOM = [38, 11];

    // The screen, and the box the content is laid out in: its left, its
    // top, its width and its height.
    hidden var _width as Number;
    hidden var _height as Number;
    hidden var _left as Number;
    hidden var _top as Number;
    hidden var _w as Number;
    hidden var _h as Number;
    hidden var _hasTouchControls as Boolean;
    hidden var _isRound as Boolean;

    function initialize(width as Number, height as Number, hasTouchControls as Boolean,
                        isRound as Boolean) {
        _width = width;
        _height = height;
        _hasTouchControls = hasTouchControls;
        _isRound = isRound;
        var scale = hasKeyHints() ? KEYS_SCALE : 100;
        _w = width * scale / 100;
        _h = height * scale / 100;
        _left = (width - _w) / 2;
        _top = (height - _h) / 2;
    }

    hidden function row(percent as Number) as Number {
        return _top + _h * percent / 100;
    }

    // A row of the lower half, moved by the shift on a screen that is not round.
    hidden function lowRow(percent as Number, flatShift as Number) as Number {
        return row(_isRound ? percent : percent + flatShift);
    }

    // A column given for my side, mirrored for the opponent.
    hidden function column(percent as Number, player as Number) as Number {
        var mine = _left + _w * percent / 100;
        return player == Player.ME ? mine : _width - mine;
    }

    // A room given in percent of the content, in pixels.
    function roomOf(percents as Array<Number>) as Array<Number> {
        return [_w * percents[0] / 100, _h * percents[1] / 100] as Array<Number>;
    }

    function centerX() as Number {
        return _width / 2;
    }

    function centerY() as Number {
        return _height / 2;
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
        return lowRow(hasKeyHints() ? LABELS_Y + KEYS_LABELS_SHIFT : LABELS_Y, FLAT_LABELS_SHIFT);
    }

    function clockY() as Number {
        if (_isRound && !_hasTouchControls) {
            return row(CLOCK_Y + KEYS_CLOCK_SHIFT);
        }
        return lowRow(CLOCK_Y, FLAT_CLOCK_SHIFT);
    }

    // The bottom row.

    function heartDotRadius() as Number {
        return _w / HEART_DOT_DIVISOR + 1;
    }

    // Left edge of the clock, center of the heart dot and left edge of the
    // heart rate, for the widths of the two texts. The row is centered as
    // a whole; without a heart rate (width 0) it is the clock alone.
    function footerXs(clockWidth as Number, heartWidth as Number) as Array<Number> {
        var gap = _w * FOOTER_GAP / 100;
        var extra = heartWidth == 0 ? 0 : heartWidth + 2 * gap + 2 * heartDotRadius();
        var clockX = centerX() - (clockWidth + extra) / 2;
        var dotX = clockX + clockWidth + gap + heartDotRadius();
        return [clockX, dotX, dotX + heartDotRadius() + gap] as Array<Number>;
    }

    function playerX(player as Number) as Number {
        return column(PLAYER_X, player);
    }

    // How far from its side of the screen the label of a player starts.
    hidden function labelOffset() as Number {
        return _left + _w * BALL_X / 100 + ballRadius() + _w * LABEL_GAP / 100;
    }

    // The edge of the player label that faces its serve ball.
    function labelX(player as Number) as Number {
        return player == Player.ME ? labelOffset() : _width - labelOffset();
    }

    function ballRadius() as Number {
        return _w / BALL_RADIUS_DIVISOR;
    }

    // Center of the serve ball, on the outer side of the player label.
    function ballX(player as Number) as Number {
        return column(BALL_X, player);
    }

    // Points digits.

    function pointsMaxWidth() as Number {
        return _w * POINTS_MAX_WIDTH / 100;
    }

    function pointsMaxHeight() as Number {
        return _h * POINTS_MAX_HEIGHT / 100;
    }

    // Index of the first font, largest first, whose [width, height] of the
    // widest score fits the room, or the last one.
    hidden function fitting(sizes as Array< Array<Number> >, width as Number, height as Number) as Number {
        var last = sizes.size() - 1;
        for (var i = 0; i < last; i++) {
            if (sizes[i][0] <= width * POINTS_MAX_WIDTH / 100 && sizes[i][1] <= height * POINTS_MAX_HEIGHT / 100) {
                return i;
            }
        }
        return last;
    }

    // The font of the score: the largest that fits its half of the content.
    // A watch with few font steps would fall to its smallest one there, far
    // too small for the score, so it keeps the one that fits the screen.
    function firstFitting(sizes as Array< Array<Number> >) as Number {
        var index = fitting(sizes, _w, _h);
        return index < sizes.size() - 1 ? index : fitting(sizes, _width, _height);
    }

    // Mini court, seen from above with the near end at the bottom.

    // [x, y, width, height]
    function courtRect() as Array<Number> {
        var width = _w * COURT_WIDTH / 100;
        var height = _h * COURT_HEIGHT / 100;
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
        return _w / MARKER_RADIUS_DIVISOR + 1;
    }

    // Center of a player marker, just behind the baseline of an end: [x, y].
    function markerPoint(end as Number, isOnRightHalf as Boolean) as Array<Number> {
        var court = courtRect();
        var gap = markerRadius() * 3 / 2;
        var x = centerX() + (isOnRightHalf ? court[2] / 4 : -court[2] / 4);
        var y = end == CourtEnd.NEAR ? court[1] + court[3] + gap : court[1] - gap;
        return [x, y] as Array<Number>;
    }

    // Asked only by the tap areas, which the watches without a touch screen
    // leave out.
    (:keyArc)
    function isRound() as Boolean {
        return _isRound;
    }

    // Key labels on the screen edge.

    // Only a round watch with the UP and DOWN keys has them next to the edge.
    // A watch that scores by touch has its touch controls and the labels of
    // the players to say what a tap does.
    function hasKeyHints() as Boolean {
        return _isRound && !_hasTouchControls;
    }

    // The angle of a key, for a label that follows the edge.
    function keyDegrees(slot as Number) as Number {
        return KEY_DEGREES[slot] as Number;
    }

    // [radius, height of the capitals] of the labels that follow the edge,
    // in pixels.
    function keyArc() as Array<Number> {
        return [_width * KEY_ARC[0] / PER_MILLE, _width * KEY_ARC[1] / PER_MILLE] as Array<Number>;
    }

    // The room the label of a key and the one of the other key of its side
    // have together, in pixels.
    function keyRoom(slot as Number) as Number {
        return 2 * _width * (KEY_ROOMS[slot % KeySlot.PER_ROW] as Number) / PER_MILLE;
    }

    // The middle of the label of a key: [x, y].
    function keyPoint(slot as Number) as Array<Number> {
        var radians = Math.toRadians(keyDegrees(slot));
        var radius = keyArc()[0];
        return [centerX() + Math.round(radius * Math.cos(radians)).toNumber(),
                centerY() - Math.round(radius * Math.sin(radians)).toNumber()] as Array<Number>;
    }

    // Menu and serve fault controls for watches that score by touch.

    function hasTouchControls() as Boolean {
        return _hasTouchControls;
    }

    function controlsY() as Number {
        return lowRow(CONTROLS_Y, FLAT_CONTROLS_SHIFT);
    }

    // [width, height] of the outline of a touch control.
    function controlRoom() as Array<Number> {
        return roomOf(_isRound ? CONTROL_ROOM : FLAT_CONTROL_ROOM);
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
