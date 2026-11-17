import Toybox.Lang;
import Toybox.Test;

// Tests for the palette rule and the UI helper logic that needs no device
// context. The draw helpers need a live Graphics.Dc, which the Run No Evil
// harness does not provide, so they are checked on the simulator by eye.

const MIP_CHANNEL_STEP = 0x55;

function themePalette() as Array<Number> {
    return [
        Theme.COLOR_BG, Theme.COLOR_TEXT, Theme.COLOR_TEXT_DIM, Theme.COLOR_FRAME,
        Theme.COLOR_ACCENT, Theme.COLOR_WARM, Theme.COLOR_DANGER, Theme.COLOR_BALL
    ];
}

function isMipSafe(color as Number) as Boolean {
    var red = (color >> 16) & 0xFF;
    var green = (color >> 8) & 0xFF;
    var blue = color & 0xFF;
    return red % MIP_CHANNEL_STEP == 0 && green % MIP_CHANNEL_STEP == 0
        && blue % MIP_CHANNEL_STEP == 0;
}

(:test)
function testEveryPaletteChannelIsAMultipleOf0x55(logger as Test.Logger) as Boolean {
    var palette = themePalette();
    for (var i = 0; i < palette.size(); i++) {
        Test.assertMessage(isMipSafe(palette[i]), "not MIP safe: " + palette[i].format("%06X"));
    }
    return true;
}

(:test)
function testMipSafeRejectsOffPaletteChannels(logger as Test.Logger) as Boolean {
    Test.assert(!isMipSafe(0xFF8800));
    Test.assert(!isMipSafe(0x010000));
    Test.assert(!isMipSafe(0x0000FE));
    return true;
}

(:test)
function testBrandAccentIsOrangeAndBallIsYellowGreen(logger as Test.Logger) as Boolean {
    Test.assertEqual(Theme.COLOR_ACCENT, 0xFF5500);
    Test.assertEqual(Theme.COLOR_BALL, 0xAAFF00);
    return true;
}

(:test)
function testSplitShortTextSingleLine(logger as Test.Logger) as Boolean {
    var lines = Theme.splitTwoLines("Coming soon", 16);
    Test.assertEqual(lines.size(), 1);
    Test.assertEqual(lines[0] as String, "Coming soon");
    return true;
}

(:test)
function testSplitLongTextAtLastFittingSpace(logger as Test.Logger) as Boolean {
    var lines = Theme.splitTwoLines("AB CD EFGHIJKLM", 10);
    Test.assertEqual(lines.size(), 2);
    Test.assertEqual(lines[0] as String, "AB CD");
    Test.assertEqual(lines[1] as String, "EFGHIJKLM");
    return true;
}

(:test)
function testSplitTextWithoutSpacesStaysSingle(logger as Test.Logger) as Boolean {
    var lines = Theme.splitTwoLines("ABCDEFGHIJKL", 11);
    Test.assertEqual(lines.size(), 1);
    Test.assertEqual(lines[0] as String, "ABCDEFGHIJKL");
    return true;
}

(:test)
function testSplitLeadingSpaceStaysSingleLine(logger as Test.Logger) as Boolean {
    // The only space is at index 0; splitting there would give an empty
    // first line, so the text stays on one line.
    var lines = Theme.splitTwoLines(" ABCDEFGHIJKL", 11);
    Test.assertEqual(lines.size(), 1);
    return true;
}

(:test)
function testLastSpaceWithinBoundaries(logger as Test.Logger) as Boolean {
    Test.assertEqual(Theme.lastSpaceWithin("NoSpaces", 7), -1);
    // A space exactly at index maxChars still counts.
    Test.assertEqual(Theme.lastSpaceWithin("abcd efgh", 4), 4);
    Test.assertEqual(Theme.lastSpaceWithin("abcd efgh", 3), -1);
    return true;
}
