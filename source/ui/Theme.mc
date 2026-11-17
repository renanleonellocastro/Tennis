import Toybox.Graphics;
import Toybox.Lang;

// Centralized palette and small drawing helpers, shared with the Stretches
// app. All colors use channel values that exist on 64 color MIP displays
// (each channel is a multiple of 0x55), so the app looks identical on the
// Forerunner 55 and on AMOLED, with no dithering.
module Theme {
    const COLOR_BG = 0x000000;
    const COLOR_TEXT = 0xFFFFFF;
    const COLOR_TEXT_DIM = 0xAAAAAA;
    const COLOR_FRAME = 0x555555;    // subtle rings / dividers
    const COLOR_ACCENT = 0xFF5500;   // single brand accent (orange)
    const COLOR_WARM = 0xFFAA00;     // amber
    const COLOR_DANGER = 0xFF0000;   // red
    const COLOR_BALL = 0xAAFF00;     // tennis ball yellow, a detail color only

    const FRAME_INSET = 3;
    const FRAME_PEN = 2;
    const ARC_PEN = 5;
    const BRAND_ARC_HALF_SWEEP = 16;
    const TOP_DEGREES = 90;

    // Radius of the ring that hugs the screen edge.
    function frameRadius(dc as Dc) as Number {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        return (cx < cy ? cx : cy) - FRAME_INSET;
    }

    // Thin, subtle frame ring hugging the screen edge.
    function drawFrameRing(dc as Dc) as Void {
        dc.setPenWidth(FRAME_PEN);
        dc.setColor(COLOR_FRAME, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(dc.getWidth() / 2, dc.getHeight() / 2, frameRadius(dc));
        dc.setPenWidth(1);
    }

    // Accent arc centered at 12 o'clock, on top of the frame ring, reaching
    // halfSweep degrees to each side.
    function drawTopArc(dc as Dc, color as Number, halfSweep as Number) as Void {
        dc.setPenWidth(ARC_PEN);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(dc.getWidth() / 2, dc.getHeight() / 2, frameRadius(dc),
                   Graphics.ARC_CLOCKWISE, TOP_DEGREES + halfSweep, TOP_DEGREES - halfSweep);
        dc.setPenWidth(1);
    }

    // Short arc at 12 o'clock: a quiet brand mark.
    function drawBrandArc(dc as Dc, color as Number) as Void {
        drawTopArc(dc, color, BRAND_ARC_HALF_SWEEP);
    }

    // Outlined rounded "pill" button hint with centered text; the caller
    // positions it by center point.
    function drawPill(dc as Dc, cx as Number, cy as Number, text as String,
                      font as Graphics.FontDefinition, color as Number) as Void {
        var textHeight = dc.getFontHeight(font);
        var boxWidth = dc.getTextWidthInPixels(text, font) + (textHeight / 2 + 2) * 2;
        var boxHeight = textHeight + (textHeight / 6) * 2;
        dc.setPenWidth(FRAME_PEN);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(cx - boxWidth / 2, cy - boxHeight / 2, boxWidth, boxHeight,
                                boxHeight / 2);
        dc.setPenWidth(1);
        dc.drawText(cx, cy, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Splits a label into at most two lines that fit narrow screens.
    function splitTwoLines(text as String, maxChars as Number) as Array {
        if (text.length() <= maxChars) {
            return [text];
        }
        var breakAt = lastSpaceWithin(text, maxChars);
        if (breakAt <= 0) {
            return [text];
        }
        return [text.substring(0, breakAt), text.substring(breakAt + 1, text.length())];
    }

    // Index of the last space at or before maxChars, or -1 when there is none.
    function lastSpaceWithin(text as String, maxChars as Number) as Number {
        var chars = text.toCharArray();
        var breakAt = -1;
        for (var i = 0; i < chars.size() && i <= maxChars; i++) {
            if (chars[i] == ' ') {
                breakAt = i;
            }
        }
        return breakAt;
    }
}
