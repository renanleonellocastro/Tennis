#!/usr/bin/env python3
"""Generate the launcher icon: a tennis ball mark on a transparent background.

The ball is drawn on a supersampled canvas and scaled down so the edges stay
smooth. The seams are cut out of the ball, so the watch background shows
through them. The ball yellow survives the 64 color Garmin MIP palette (every
channel is a multiple of 0x55) and matches Theme.COLOR_BALL in the app.

Usage:
    python3 scripts/generate_icon.py

Output:
    resources/drawables/launcher_icon.png
"""

import os

from PIL import Image, ImageDraw

ICON_SIZE = 80
SUPERSAMPLING = 10
CANVAS = ICON_SIZE * SUPERSAMPLING

BACKGROUND = (0, 0, 0, 0)  # transparent, like the Stretches icon
BALL = (170, 255, 0, 255)  # 0xAAFF00

# Geometry in the 0..80 icon space.
BALL_CENTER = 40
BALL_RADIUS = 30
SEAM_RADIUS = 26
SEAM_OFFSET = 38
SEAM_WIDTH = 4

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_PATH = os.path.join(REPO_ROOT, "resources", "drawables", "launcher_icon.png")


def circle_box(center_x, center_y, radius):
    """Bounding box of a circle, scaled to the supersampled canvas."""
    corners = (center_x - radius, center_y - radius, center_x + radius, center_y + radius)
    return [value * SUPERSAMPLING for value in corners]


def ball_mask():
    """White where the ball is, so the seams can be clipped to it."""
    mask = Image.new("L", (CANVAS, CANVAS), 0)
    ImageDraw.Draw(mask).ellipse(circle_box(BALL_CENTER, BALL_CENTER, BALL_RADIUS), fill=255)
    return mask


def seam_layer():
    """The two curved seams, as circles centered left and right of the ball."""
    layer = Image.new("RGBA", (CANVAS, CANVAS), BALL)
    draw = ImageDraw.Draw(layer)
    for center_x in (BALL_CENTER - SEAM_OFFSET, BALL_CENTER + SEAM_OFFSET):
        draw.ellipse(circle_box(center_x, BALL_CENTER, SEAM_RADIUS),
                     outline=BACKGROUND, width=SEAM_WIDTH * SUPERSAMPLING)
    return layer


def render_icon():
    icon = Image.new("RGBA", (CANVAS, CANVAS), BACKGROUND)
    icon.paste(seam_layer(), (0, 0), ball_mask())
    return icon.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)


def main():
    render_icon().save(OUTPUT_PATH)
    print("Generated %s" % os.path.relpath(OUTPUT_PATH, REPO_ROOT))


if __name__ == "__main__":
    main()
