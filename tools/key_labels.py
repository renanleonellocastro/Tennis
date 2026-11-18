"""Generate the images of the key labels for the watches that cannot turn text.

Next to each key the match, ending and practice screens say what the key
does, in small letters that follow the round edge. Newer watches draw them
with a vector font. The watches in DEVICE_SIZES have no such font, so they
get one small image per label, already bent for the place of its key: one
set per screen size and per language, and the watch loads only the four of
the screen that shows.

The letters are single strokes that follow the circle point by point, drawn
large and scaled down, then cut to the few grey levels the screen has. A
screen without greys cannot smooth a turned line, so its letters get a
quarter turn and each row of pixels then moves with the round edge. The
image is cropped around the middle of the label, which is the point where
the watch centers it (MatchLayout.keyPoint). The radius and the key angles
are read from MatchLayout.mc, so both sides agree.

Usage:
    python tools/key_labels.py           write the images and their index
    python tools/key_labels.py --check   fail when they are out of date
"""

import itertools
import json
import math
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET
from dataclasses import astuple, dataclass
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
FOLDER = "keylabels"
INDEX = "index.json"
LAYOUT_SOURCE = Path("source") / "match" / "MatchLayout.mc"
JUNGLE = "monkey.jungle"
LANGUAGES = {
    "eng": "resources",
    "por": "resources-por",
    "spa": "resources-spa",
    "fre": "resources-fre",
    "deu": "resources-deu",
    "ita": "resources-ita",
}
BASE_LANGUAGE = "eng"
# The slots of KeySlot in MatchLayout.mc.
UP, START, DOWN, BACK = range(4)
# The string ids of the labels each screen shows together, in the order of
# the slots: the match, the practice and the two forms of the ending screen.
SCREENS = (
    ("LabelMe", "ControlFault", "LabelOpponent", "KeyUndo"),
    ("PracticeHit", "PracticeNext", "PracticeMiss", "KeyUndo"),
    ("EndingErrorOut", "EndingWinner", "EndingErrorNet", "KeyBack"),
    ("EndingErrorOut", "KeyMore", "EndingErrorNet", "KeyBack"),
)
# String id of each label and the key it sits next to. The image carries the
# id of its string.
LABELS = {label: slot for screen in SCREENS for slot, label in enumerate(screen)}
# The two keys of one side of the watch, as pairs of slots.
SIDES = ((UP, DOWN), (START, BACK))
# The round watches with the five keys and no vector font, by screen width.
DEVICE_SIZES = {
    "fr55": 208,
    "fr255s": 218,
    "fr255sm": 218,
    "fr245": 240,
    "fr245m": 240,
    "fr745": 240,
    "fr945": 240,
    "fr945lte": 240,
    "fenix6s": 240,
    "fenix6spro": 240,
    "fr255": 260,
    "fr255m": 260,
    "fenix6": 260,
    "fenix6pro": 260,
    "fenix6xpro": 280,
    "instinct3amoled45mm": 390,
    "instinctcrossoveramoled": 390,
    "instinct3amoled50mm": 416,
}
# Watches whose device files list no Portuguese: a language line for them
# only makes the compiler warn.
NO_PORTUGUESE = ("fr55", "fr245", "fr245m", "fr745")
# The letters are single strokes on a grid four units wide and GRID units
# tall, so a label of eight pixels still has clean lines. Each letter is its
# strokes, each stroke its points as the two digits x and y, y going up.
GLYPHS = {
    "A": "00 26 40|12 32",
    "B": "00 06 36 45 44 33 03|33 42 41 30 00",
    "C": "45 36 16 05 01 10 30 41",
    "D": "00 06 36 45 41 30 00",
    "E": "46 06 00 40|03 33",
    "F": "46 06 00|03 33",
    "G": "45 36 16 05 01 10 30 41 43 23",
    "H": "00 06|40 46|03 43",
    "I": "00 06",
    "J": "46 41 30 10 01",
    "K": "00 06|46 03 40",
    "L": "06 00 40",
    "M": "00 06 23 46 40",
    "N": "00 06 40 46",
    "O": "10 01 05 16 36 45 41 30 10",
    "P": "00 06 36 45 44 33 03",
    "Q": "10 01 05 16 36 45 41 30 10|22 40",
    "R": "00 06 36 45 44 33 03|23 40",
    "S": "45 36 16 05 04 13 33 42 41 30 10 01",
    "T": "06 46|26 20",
    "U": "06 01 10 30 41 46",
    "V": "06 20 46",
    "W": "06 10 24 30 46",
    "X": "00 46|06 40",
    "Y": "06 23 46|23 20",
    "Z": "06 46 00 40",
    ".": "00 01",
    "+": "03 43|21 25",
}
GRID = 6
# Space between two letters, in units of the grid.
TRACKING = 2
WHITE = 255
PER_MILLE = 1000
# Changing how the images are drawn must change this, so the check asks for
# a new run.
RECIPE = 4


@dataclass(frozen=True)
class Style:
    """How the letters of one screen size are drawn."""

    levels: int  # grey levels of the image, black included
    scale: int  # how many times larger the label is drawn before it is scaled down
    stroke: int  # width of the lines in per mille of the screen width
    ink: int  # brightest grey, the color of the letters


@dataclass(frozen=True)
class Arc:
    """Where the labels go: MatchLayout.KEY_ARC, KEY_ROOMS and KEY_DEGREES."""

    radius: int  # of the middle of the letters, per mille of the screen width
    cap: int  # height of the letters, per mille
    rooms: tuple[int, ...]  # mean width of the two labels of the left and of the right side, per mille
    degrees: tuple[int, ...]


@dataclass(frozen=True)
class Bend:
    """Turns a place along a label and above its middle line into a pixel."""

    center: float
    radius: float
    degrees: int
    is_clockwise: bool
    half: float  # half the length of the label

    def point(self, along: float, above: float) -> tuple[float, float]:
        offset = (self.half - along) / self.radius
        turn = math.radians(self.degrees) + (offset if self.is_clockwise else -offset)
        reach = self.radius + (above if self.is_clockwise else -above)
        return self.center + reach * math.cos(turn), self.center - reach * math.sin(turn)


# The 208 pixel screen shows eight colors: pure white, no grey, so its
# letters are set pixel by pixel (scale 1). The other memory in pixel screens
# show four greys, and the AMOLED ones all of them.
STYLES = {
    208: Style(2, 1, 4, 0xFF),
    218: Style(3, 8, 7, 0xAA),
    240: Style(3, 8, 7, 0xAA),
    260: Style(3, 8, 7, 0xAA),
    280: Style(3, 8, 7, 0xAA),
    390: Style(6, 8, 5, 0xAA),
    416: Style(6, 8, 5, 0xAA),
}


def read_arc(root: Path) -> Arc:
    """The label geometry the watch uses, from the layout source."""
    source = (root / LAYOUT_SOURCE).read_text(encoding="utf-8")
    arc = _numbers(source, "KEY_ARC")
    return Arc(arc[0], arc[1], tuple(_numbers(source, "KEY_ROOMS")), tuple(_numbers(source, "KEY_DEGREES")))


def _numbers(source: str, name: str) -> list[int]:
    found = re.search(rf"const {name} = \[([^\]]*)\]", source)
    if found is None:
        raise ValueError(f"{name} is not in {LAYOUT_SOURCE}")
    return [int(part) for part in found.group(1).split(",")]


def plain(text: str) -> str:
    """Upper case without accents: the letters are too small to carry them."""
    return "".join(letter for letter in unicodedata.normalize("NFD", text.upper()) if not unicodedata.combining(letter))


def read_texts(root: Path) -> dict[str, dict[str, str]]:
    """The label texts of every language, as the images show them."""
    texts = {}
    for code, folder in LANGUAGES.items():
        nodes = ET.parse(root / folder / "strings" / "strings.xml").getroot().findall("string")
        strings = {node.get("id"): node.text or "" for node in nodes}
        texts[code] = {label: plain(strings[label]) for label in LABELS}
    return texts


def anchor(width: int, arc: Arc, slot: int) -> tuple[int, int]:
    """The middle of a label, with the rounding of MatchLayout.keyPoint."""
    radians = math.radians(arc.degrees[slot])
    radius = width * arc.radius // PER_MILLE
    return width // 2 + round(radius * math.cos(radians)), width // 2 - round(radius * math.sin(radians))


def is_clockwise(slot: int) -> bool:
    """The upper keys read clockwise, so no label is upside down."""
    return slot in (UP, START)


def strokes(letter: str) -> list[list[tuple[int, int]]]:
    """The lines of a letter, as points on the grid."""
    return [[(int(point[0]), int(point[1])) for point in stroke.split()] for stroke in GLYPHS[letter].split("|")]


def advance(letter: str) -> int:
    """The width of a letter, in units of the grid."""
    return max(x for stroke in strokes(letter) for x, _ in stroke)


def length(text: str) -> int:
    """The length of a label along its circle, in units of the grid."""
    return sum(advance(letter) for letter in text) + TRACKING * (len(text) - 1)


def unit_of(width: int, arc: Arc, style: Style) -> float:
    """One unit of the letter grid on the enlarged screen, in pixels."""
    return width * style.scale * arc.cap / PER_MILLE / GRID


def bend_of(width: int, text: str, slot: int, arc: Arc, style: Style) -> Bend:
    """The circle of a label on the enlarged screen."""
    center = width // 2 * style.scale
    radius = width * arc.radius // PER_MILLE * style.scale
    half = length(text) * unit_of(width, arc, style) / 2
    return Bend(center, radius, arc.degrees[slot], is_clockwise(slot), half)


def draw_label(width: int, text: str, slot: int, arc: Arc, style: Style) -> Image.Image:
    """The label along its circle on a screen style.scale times larger."""
    side, unit = width * style.scale, unit_of(width, arc, style)
    bend = bend_of(width, text, slot, arc, style)
    screen = Image.new("L", (side, side), 0)
    pen, start = max(1, round(side * style.stroke / PER_MILLE)), 0
    for letter in text:
        for stroke in strokes(letter):
            points = [bend.point((start + x) * unit, (y - GRID / 2) * unit) for x, y in stroke]
            ImageDraw.Draw(screen).line(points, fill=WHITE, width=pen, joint="curve")
        start += advance(letter) + TRACKING
    return screen


def path_of(stroke: list[tuple[int, int]], start: int) -> list[tuple[int, int]]:
    """Every pixel of a stroke of an upright letter, in order: one pixel per unit, y going down."""
    pixels = [(start + stroke[0][0], GRID - stroke[0][1])]
    for (ax, ay), (bx, by) in itertools.pairwise(stroke):
        steps = max(abs(bx - ax), abs(by - ay))
        pixels += [
            (start + ax + round((bx - ax) * step / steps), GRID - ay - round((by - ay) * step / steps))
            for step in range(1, steps + 1)
        ]
    return pixels


def turned(pixel: tuple[int, int], slot: int, half: int) -> tuple[int, int]:
    """A pixel of an upright label after its quarter turn: (across, down) from the middle of the label.

    The keys are on the two sides, so the labels run up or down. The upper
    labels and the lower ones read in opposite directions around the circle,
    which puts the left ones bottom to top and the right ones top to bottom
    or the reverse; a quarter turn keeps every line one pixel wide.
    """
    x, y = pixel
    return (y - GRID // 2, half - x) if slot in (UP, BACK) else (GRID // 2 - y, x - half)


def edge_shift(width: int, center: tuple[int, int], row: int) -> int:
    """How many pixels the round edge moves sideways between the row of a label's middle and another row."""
    middle = (width - 1) / 2
    radius = math.hypot(center[0] - middle, center[1] - middle)
    reach = [math.sqrt(max(0.0, radius**2 - (y - middle) ** 2)) for y in (row, center[1])]
    shift = round(reach[0] - reach[1])
    return shift if center[0] > middle else -shift


def on_the_edge(width: int, center: tuple[int, int], spot: tuple[int, int]) -> tuple[int, int]:
    """The pixel of a turned spot: its row moves sideways with the round edge."""
    row = center[1] + spot[1]
    return center[0] + spot[0] + edge_shift(width, center, row), row


def draw_pixels(width: int, text: str, slot: int, arc: Arc) -> Image.Image:
    """The label of a screen without greys, at its final size around its anchor."""
    center, screen = anchor(width, arc, slot), Image.new("L", (width, width), 0)
    start = 0
    for letter in text:
        for stroke in strokes(letter):
            spots = [turned(pixel, slot, length(text) // 2) for pixel in path_of(stroke, start)]
            ImageDraw.Draw(screen).line([on_the_edge(width, center, spot) for spot in spots], fill=WHITE)
        start += advance(letter) + TRACKING
    return screen


def to_levels(image: Image.Image, style: Style) -> Image.Image:
    """Cuts the greys to the levels of the screen, the brightest being the ink."""
    steps = style.levels - 1
    return image.point(lambda value: round(value * steps / WHITE) * style.ink // steps)


def crop_around(image: Image.Image, center: tuple[int, int]) -> Image.Image:
    """The smallest box with all the ink that has the center in its middle."""
    box = image.getbbox()
    if box is None:
        raise ValueError("the label has no ink")
    half_width = max(center[0] - box[0], box[2] - center[0])
    half_height = max(center[1] - box[1], box[3] - center[1])
    return image.crop(
        (center[0] - half_width, center[1] - half_height, center[0] + half_width, center[1] + half_height)
    )


def label_image(width: int, text: str, slot: int, arc: Arc) -> Image.Image:
    """The finished image of one label for one screen size."""
    style = STYLES[width]
    if style.scale == 1:
        small = draw_pixels(width, text, slot, arc)
    else:
        small = draw_label(width, text, slot, arc, style).resize((width, width), Image.Resampling.BOX)
    return clear_black(crop_around(to_levels(small, style), anchor(width, arc, slot)))


def clear_black(image: Image.Image) -> Image.Image:
    """Makes the black see through, so the box of a label hides nothing."""
    clear = image.convert("RGBA")
    clear.putalpha(image.point(lambda value: WHITE if value else 0))
    return clear


def pairs_of(labels: dict[str, str]) -> list[tuple[int, str, str]]:
    """The two labels that share a side, for every screen: (side, one, other)."""
    return [
        (side, labels[screen[slots[0]]], labels[screen[slots[1]]])
        for screen in SCREENS
        for side, slots in enumerate(SIDES)
    ]


def too_wide(texts: dict[str, dict[str, str]], arc: Arc) -> list[str]:
    """The pairs of labels that would meet between their two keys."""
    problems = []
    for code, labels in texts.items():
        problems += [
            f"TOO WIDE {code} {one} + {other}"
            for side, one, other in pairs_of(labels)
            if (length(one) + length(other)) * arc.cap / GRID > 2 * arc.rooms[side]
        ]
    return sorted(set(problems))


def palette_xml(style: Style) -> str:
    steps = style.levels - 1
    greys = [level * style.ink // steps for level in range(1, style.levels)]
    colors = "".join(f"<color>{grey:02X}{grey:02X}{grey:02X}</color>" for grey in greys)
    return f'<palette disableTransparency="false">{colors}</palette>'


def drawables_xml(style: Style) -> str:
    """The resource file of one folder: every label with its palette."""
    rows = [
        f'    <bitmap id="{label}" filename="{label}.png" dithering="none">{palette_xml(style)}</bitmap>'
        for label in LABELS
    ]
    return "\n".join(["<drawables>", *rows, "</drawables>", ""])


def write_folder(root: Path, width: int, code: str, labels: dict[str, str], arc: Arc) -> None:
    folder = root / FOLDER / str(width) / code
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "drawables.xml").write_text(drawables_xml(STYLES[width]), encoding="utf-8")
    for label, text in labels.items():
        label_image(width, text, LABELS[label], arc).save(folder / f"{label}.png", optimize=True)


def index_of(texts: dict[str, dict[str, str]], arc: Arc) -> str:
    """What the images were made from. The check compares it with the sources."""
    styles = {str(width): list(astuple(style)) for width, style in STYLES.items()}
    drawing = {"recipe": RECIPE, "glyphs": GLYPHS, "tracking": TRACKING, "styles": styles}
    index = {**drawing, "arc": [arc.radius, arc.cap, *arc.rooms, *arc.degrees], "texts": texts}
    return json.dumps(index, ensure_ascii=False, indent=1, sort_keys=True) + "\n"


def jungle_lines() -> list[str]:
    """The build settings that give each watch its images and leave the others without."""
    lines = []
    for device, width in DEVICE_SIZES.items():
        lines.append(f"{device}.excludeAnnotations = keyArc")
        lines.append(f"{device}.resourcePath = $({device}.resourcePath);{FOLDER}/{width}/{BASE_LANGUAGE}")
        lines += [
            f"{device}.lang.{code} = $({device}.lang.{code});{FOLDER}/{width}/{code}"
            for code in LANGUAGES
            if code != BASE_LANGUAGE and (code != "por" or device not in NO_PORTUGUESE)
        ]
    return lines


def generate(root: Path) -> list[str]:
    """Writes every image. Returns the problems that stopped it."""
    arc, texts = read_arc(root), read_texts(root)
    problems = too_wide(texts, arc)
    if problems:
        return problems
    for width in STYLES:
        for code, labels in texts.items():
            write_folder(root, width, code, labels, arc)
    (root / FOLDER / INDEX).write_text(index_of(texts, arc), encoding="utf-8")
    return []


def missing_files(root: Path) -> list[str]:
    paths = [
        Path(FOLDER) / str(width) / code / f"{label}.png" for width in STYLES for code in LANGUAGES for label in LABELS
    ]
    return [f"MISSING {path}" for path in paths if not (root / path).is_file()]


def check(root: Path) -> list[str]:
    """The problems of the committed images: stale, missing or not in the build."""
    index = root / FOLDER / INDEX
    expected = index_of(read_texts(root), read_arc(root))
    problems = (
        []
        if index.is_file() and index.read_text(encoding="utf-8") == expected
        else [f"STALE {FOLDER}: run make key-labels"]
    )
    jungle = (root / JUNGLE).read_text(encoding="utf-8").splitlines()
    problems += [f"NOT IN {JUNGLE}: {line}" for line in jungle_lines() if line not in jungle]
    return problems + missing_files(root)


def main(arguments: list[str], root: Path = ROOT) -> int:
    problems = check(root) if "--check" in arguments else generate(root)
    for problem in problems:
        print(problem)
    print("key labels:", "FAILED" if problems else "OK")
    return 1 if problems else 0


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main(sys.argv[1:]))
