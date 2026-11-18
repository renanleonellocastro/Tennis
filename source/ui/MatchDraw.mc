import Toybox.Graphics;
import Toybox.Lang;

// Drawing that the match screen and the practice screen share: the font of
// the large numbers and the bottom of the screen, with the clock and the
// heart rate, the two touch controls of the watches without the keys, and
// the hints next to the keys of the two sides.
module MatchDraw {
    // Largest first; the first one whose widest number fits is used.
    const NUMBER_FONTS = [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT,
                          Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD];
    const LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
    // Indexed by Player: the colors of the labels of the two sides.
    const SIDE_COLORS = [Theme.COLOR_ACCENT, Theme.COLOR_TEXT_DIM];

    // The largest number font in which the widest text fits its quarter.
    function numberFont(dc as Dc, layout as MatchLayout, widest as String) as Graphics.FontDefinition {
        var sizes = [] as Array< Array<Number> >;
        for (var i = 0; i < NUMBER_FONTS.size(); i++) {
            var font = NUMBER_FONTS[i] as Graphics.FontDefinition;
            sizes.add([dc.getTextWidthInPixels(widest, font), dc.getFontHeight(font)] as Array<Number>);
        }
        return NUMBER_FONTS[layout.firstFitting(sizes)] as Graphics.FontDefinition;
    }

    // clock is [seconds, heart rate or null, is paused]; controlKey is the
    // text of the second touch control.
    function draw(dc as Dc, layout as MatchLayout, clock as Array, controlKey as Number) as Void {
        drawClock(dc, layout, clock);
        if (layout.hasTouchControls()) {
            drawControl(dc, layout.menuControlX(), layout.controlsY(), Str.HomeHint);
            drawControl(dc, layout.faultControlX(), layout.controlsY(), controlKey);
        }
        if (layout.hasKeyHints()) {
            drawKeyHint(dc, layout, Player.ME);
            drawKeyHint(dc, layout, Player.OPPONENT);
        }
    }

    // The clock and, when the watch reads one, the heart rate after a dot.
    function drawClock(dc as Dc, layout as MatchLayout, clock as Array) as Void {
        var time = MatchPresenter.clockText(clock[0] as Number);
        var beats = MatchPresenter.heartRateText(clock[1] as Number?);
        var xs = layout.footerXs(dc.getTextWidthInPixels(time, Graphics.FONT_TINY),
                                 dc.getTextWidthInPixels(beats, Graphics.FONT_TINY));
        dc.setColor((clock[2] as Boolean) ? Theme.COLOR_TEXT_DIM : Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xs[0], layout.clockY(), Graphics.FONT_TINY, time, LEFT);
        if (beats.length() > 0) {
            dc.drawText(xs[2], layout.clockY(), Graphics.FONT_TINY, beats, LEFT);
            dc.setColor(Theme.COLOR_DANGER, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(xs[1], layout.clockY(), layout.heartDotRadius());
        }
    }

    function drawControl(dc as Dc, x as Number, y as Number, key as Number) as Void {
        Theme.drawPill(dc, x, y, Strings.t(key), Graphics.FONT_XTINY, Theme.COLOR_TEXT_DIM);
    }

    // A short arc on the screen edge next to the key of a side, in the
    // color of the label of that side.
    function drawKeyHint(dc as Dc, layout as MatchLayout, side as Number) as Void {
        var degrees = layout.keyHintDegrees(side);
        dc.setPenWidth(Theme.ARC_PEN);
        dc.setColor(SIDE_COLORS[side] as Number, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(layout.centerX(), dc.getHeight() / 2, Theme.frameRadius(dc),
                   Graphics.ARC_COUNTER_CLOCKWISE, degrees[0], degrees[1]);
        dc.setPenWidth(1);
    }
}
