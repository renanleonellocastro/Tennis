import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Drawing that the match screen and the practice screen share: the font of
// the large numbers and the bottom of the screen, with the clock and the
// heart rate, the two touch controls of the watches without the keys, and
// the labels next to the keys.
module MatchDraw {
    // Largest first; the first one whose widest number fits is used.
    const NUMBER_FONTS = [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT,
                          Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD];
    // The faces a key label may use, best first.
    (:keyArc)
    const KEY_FACES = ["RobotoCondensedBold", "RobotoRegular", "BionicBold", "BionicSemiBold", "KosugiRegular"];
    // The size of the vector font whose capitals have the height of the
    // labels, in percent of that height.
    (:keyArc)
    const VECTOR_SIZE = 160;
    // Largest first.
    const TEXT_FONTS = [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL, Graphics.FONT_TINY, Graphics.FONT_XTINY];
    const LEFT = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
    const RIGHT = Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER;
    const CENTERED = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    // Indexed by Player, which is also the BannerTone of a point at stake:
    // orange for me, white for the opponent, amber for a notice.
    const TONE_COLORS = [Theme.COLOR_ACCENT, Theme.COLOR_TEXT, Theme.COLOR_WARM];
    // Indexed by the tones of MatchPresenter.pointsTone. A pause turns the numbers amber like its
    // banner: the small screens have no grey to dim them with.
    const POINTS_COLORS = [Theme.COLOR_TEXT, Theme.COLOR_TEXT_DIM, Theme.COLOR_WARM];

    // The largest text font, from the one at first on, in which the text
    // fits the room [width, height]. The smallest one is the fallback.
    function textFont(dc as Dc, text as String, first as Number, room as Array<Number>) as Graphics.FontDefinition {
        for (var i = first; i < TEXT_FONTS.size() - 1; i++) {
            var font = TEXT_FONTS[i] as Graphics.FontDefinition;
            if (dc.getTextWidthInPixels(text, font) <= room[0] && dc.getFontHeight(font) <= room[1]) {
                return font;
            }
        }
        return Graphics.FONT_XTINY;
    }

    // One font for the labels of the two sides: the largest in which the
    // wider of the two fits.
    function labelFont(dc as Dc, layout as MatchLayout, mine as String, theirs as String) as Graphics.FontDefinition {
        var isMineWider = dc.getTextWidthInPixels(mine, Graphics.FONT_XTINY)
            >= dc.getTextWidthInPixels(theirs, Graphics.FONT_XTINY);
        return textFont(dc, isMineWider ? mine : theirs, 1, layout.roomOf(layout.LABEL_ROOM));
    }

    // The largest number font in which the widest text fits its quarter.
    function numberFont(dc as Dc, layout as MatchLayout, widest as String) as Graphics.FontDefinition {
        var sizes = [] as Array< Array<Number> >;
        for (var i = 0; i < NUMBER_FONTS.size(); i++) {
            var font = NUMBER_FONTS[i] as Graphics.FontDefinition;
            sizes.add([dc.getTextWidthInPixels(widest, font), dc.getFontHeight(font)] as Array<Number>);
        }
        return NUMBER_FONTS[layout.firstFitting(sizes)] as Graphics.FontDefinition;
    }

    // clock is [seconds, heart rate or null, is paused]; keys are the text
    // keys of what UP, START, DOWN and BACK do, in the order of KeySlot. The
    // one of START is also the text of the second touch control.
    function draw(dc as Dc, layout as MatchLayout, clock as Array, keys as Array<Number>) as Void {
        drawClock(dc, layout, clock);
        if (layout.hasTouchControls()) {
            drawControl(dc, layout, layout.menuControlX(), Str.HomeHint);
            drawControl(dc, layout, layout.faultControlX(), keys[KeySlot.START]);
        }
        for (var slot = 0; slot < KeySlot.COUNT; slot++) {
            drawKeyLabel(dc, layout, slot, keys);
        }
    }

    // The clock and, when the watch reads one, the heart rate after a dot.
    function drawClock(dc as Dc, layout as MatchLayout, clock as Array) as Void {
        var time = MatchPresenter.clockText(clock[0] as Number);
        var beats = MatchPresenter.heartRateText(clock[1] as Number?);
        // Next to the key labels everything is a step smaller.
        var font = layout.hasKeyHints() ? Graphics.FONT_XTINY : Graphics.FONT_TINY;
        var xs = layout.footerXs(dc.getTextWidthInPixels(time, font), dc.getTextWidthInPixels(beats, font));
        dc.setColor((clock[2] as Boolean) ? Theme.COLOR_TEXT_DIM : Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xs[0], layout.clockY(), font, time, LEFT);
        if (beats.length() > 0) {
            dc.drawText(xs[2], layout.clockY(), font, beats, LEFT);
            dc.setColor(Theme.COLOR_DANGER, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(xs[1], layout.clockY(), layout.heartDotRadius());
        }
    }

    // A touch control: a quiet outline that shows how large the target is,
    // with its word in white. The capitals only graze the round ends, so
    // the word may take all but half the height of the width.
    function drawControl(dc as Dc, layout as MatchLayout, x as Number, key as Number) as Void {
        var box = layout.controlRoom();
        var text = Strings.t(key);
        dc.setPenWidth(Theme.FRAME_PEN);
        dc.setColor(Theme.COLOR_FRAME, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(x - box[0] / 2, layout.controlsY() - box[1] / 2, box[0], box[1], box[1] / 2);
        dc.setPenWidth(1);
        dc.setColor(Theme.COLOR_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, layout.controlsY(), textFont(dc, text, 2, [box[0] - box[1] / 2, box[1]] as Array<Number>), text,
                    CENTERED);
    }

    // What the screen holds to draw its key labels: the vector font on a
    // watch that turns text, the four images on one that cannot.
    var keyArt as Object? = null;

    // Lets the font or the images go when the screen closes.
    function release() as Void {
        keyArt = null;
    }

    // Looks for the font of the key labels. Null leaves them out.
    (:keyArc)
    function prepare(layout as MatchLayout, keys as Array<Number>) as Void {
        keyArt = null;
        if (layout.hasKeyHints() && Graphics has :getVectorFont) {
            keyArt = Graphics.getVectorFont({:face => KEY_FACES, :size => layout.keyArc()[1] * VECTOR_SIZE / 100});
        }
    }

    // What a key does, in small dim letters along the round edge next to
    // it. The upper keys read clockwise and the lower ones the other way,
    // so no label is upside down. Labels that would meet the one of the
    // other key of their side are left out.
    (:keyArc)
    function drawKeyLabel(dc as Dc, layout as MatchLayout, slot as Number, keys as Array<Number>) as Void {
        var font = keyArt as Graphics.VectorFont?;
        if (font != null && dc has :drawRadialText) {
            var text = Strings.t(keys[slot]).toUpper();
            var other = Strings.t(keys[(slot + KeySlot.PER_ROW) % KeySlot.COUNT]).toUpper();
            if (dc.getTextWidthInPixels(text + other, font) <= layout.keyRoom(slot)) {
                drawArcText(dc, layout, slot, text, font);
            }
        }
    }

    // Centered text takes the radius of the middle of its letters.
    (:keyArc)
    function drawArcText(dc as Dc, layout as MatchLayout, slot as Number, text as String,
                         font as Graphics.VectorFont) as Void {
        var isUpper = slot < KeySlot.PER_ROW;
        dc.setColor(Theme.COLOR_TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawRadialText(layout.centerX(), layout.centerY(), font, text, CENTERED, layout.keyDegrees(slot),
                          layout.keyArc()[0],
                          isUpper ? Graphics.RADIAL_TEXT_DIRECTION_CLOCKWISE
                                  : Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);
    }

    // The image of each key label, by the text it shows.
    (:keyImages)
    function keyImageOf(key as Number) as ResourceId? {
        var images = {
            Str.LabelMe => Rez.Drawables.LabelMe, Str.ControlFault => Rez.Drawables.ControlFault,
            Str.LabelOpponent => Rez.Drawables.LabelOpponent, Str.KeyUndo => Rez.Drawables.KeyUndo,
            Str.PracticeHit => Rez.Drawables.PracticeHit, Str.PracticeNext => Rez.Drawables.PracticeNext,
            Str.PracticeMiss => Rez.Drawables.PracticeMiss, Str.EndingErrorOut => Rez.Drawables.EndingErrorOut,
            Str.EndingErrorNet => Rez.Drawables.EndingErrorNet, Str.EndingWinner => Rez.Drawables.EndingWinner,
            Str.KeyMore => Rez.Drawables.KeyMore, Str.KeyBack => Rez.Drawables.KeyBack
        };
        return images[key] as ResourceId?;
    }

    // Loads the images of the four key labels, already bent for their keys.
    (:keyImages)
    function prepare(layout as MatchLayout, keys as Array<Number>) as Void {
        keyArt = null;
        if (layout.hasKeyHints()) {
            var art = [] as Array;
            for (var slot = 0; slot < keys.size(); slot++) {
                var image = keyImageOf(keys[slot]);
                art.add(image == null ? null : WatchUi.loadResource(image));
            }
            keyArt = art;
        }
    }

    // What a key does, as a small image centered on the place of its label.
    (:keyImages)
    function drawKeyLabel(dc as Dc, layout as MatchLayout, slot as Number, keys as Array<Number>) as Void {
        var art = keyArt as Array?;
        var image = art == null ? null : art[slot] as WatchUi.BitmapResource?;
        if (image != null) {
            var at = layout.keyPoint(slot);
            dc.drawBitmap(at[0] - image.getWidth() / 2, at[1] - image.getHeight() / 2, image);
        }
    }
}
