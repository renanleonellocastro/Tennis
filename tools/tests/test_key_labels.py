"""Tests for tools/key_labels.py: the label images of the watches that cannot turn text."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

import pytest
from PIL import Image

import key_labels as labels

ARC = labels.Arc(481, 30, (215, 300), (180, 30, 213, 327))
DEVICE_FILES = Path.home() / "Library" / "Application Support" / "Garmin" / "ConnectIQ" / "Devices"


def copy_sources(root: Path) -> Path:
    """A copy of the files the generator reads, to write images next to."""
    for folder in labels.LANGUAGES.values():
        target = root / folder / "strings"
        target.mkdir(parents=True)
        shutil.copy(labels.ROOT / folder / "strings" / "strings.xml", target)
    (root / labels.LAYOUT_SOURCE).parent.mkdir(parents=True)
    shutil.copy(labels.ROOT / labels.LAYOUT_SOURCE, root / labels.LAYOUT_SOURCE)
    shutil.copy(labels.ROOT / labels.JUNGLE, root / labels.JUNGLE)
    return root


def replace_in(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    assert old in text
    path.write_text(text.replace(old, new), encoding="utf-8")


def inks(image: Image.Image) -> set[int]:
    """The red levels of the pixels that are not see through."""
    pairs = zip(image.getchannel("R").tobytes(), image.getchannel("A").tobytes(), strict=True)
    return {red for red, alpha in pairs if alpha}


def test_the_geometry_comes_from_the_layout_of_the_watch() -> None:
    arc = labels.read_arc(labels.ROOT)

    assert len(arc.rooms) == 2
    assert len(arc.degrees) == 4
    assert arc.radius + arc.cap / 2 < labels.PER_MILLE / 2


def test_a_layout_without_the_geometry_is_an_error(tmp_path: Path) -> None:
    (tmp_path / labels.LAYOUT_SOURCE).parent.mkdir(parents=True)
    (tmp_path / labels.LAYOUT_SOURCE).write_text("class MatchLayout {}", encoding="utf-8")

    with pytest.raises(ValueError, match="KEY_ARC"):
        labels.read_arc(tmp_path)


@pytest.mark.parametrize(("text", "shown"), [("Próx.", "PROX."), ("Zurück", "ZURUCK"), ("Me", "ME"), ("+", "+")])
def test_labels_are_capitals_without_accents(text: str, shown: str) -> None:
    assert labels.plain(text) == shown


def test_every_language_has_every_label_in_letters_the_font_has() -> None:
    texts = labels.read_texts(labels.ROOT)

    assert set(texts) == set(labels.LANGUAGES)
    for shown in texts.values():
        assert set(shown) == set(labels.LABELS)
        assert all(letter in labels.GLYPHS for text in shown.values() for letter in text)
    assert texts["eng"]["LabelMe"] == "ME"
    assert texts["por"]["LabelMe"] == "EU"


def test_each_label_belongs_to_one_key_on_every_screen() -> None:
    assert labels.LABELS["LabelMe"] == labels.UP
    assert labels.LABELS["ControlFault"] == labels.START
    assert labels.LABELS["LabelOpponent"] == labels.DOWN
    assert labels.LABELS["KeyUndo"] == labels.BACK
    for screen in labels.SCREENS:
        assert [labels.LABELS[label] for label in screen] == [labels.UP, labels.START, labels.DOWN, labels.BACK]


# The same numbers as testEveryKeyLabelSitsAtItsKey of the watch tests.
@pytest.mark.parametrize(
    ("slot", "point"),
    [(labels.UP, (4, 104)), (labels.START, (191, 54)), (labels.DOWN, (20, 158)), (labels.BACK, (188, 158))],
)
def test_the_middle_of_a_label_is_where_the_watch_centers_it(slot: int, point: tuple[int, int]) -> None:
    assert labels.anchor(208, ARC, slot) == point


def test_only_the_upper_labels_read_clockwise() -> None:
    assert [labels.is_clockwise(slot) for slot in range(4)] == [True, True, False, False]


def test_letters_are_strokes_on_the_grid() -> None:
    assert labels.strokes("T") == [[(0, 6), (4, 6)], [(2, 6), (2, 0)]]
    assert labels.advance("T") == 4
    assert labels.advance("I") == 0
    assert labels.length("IT") == 4 + labels.TRACKING
    for letter in labels.GLYPHS:
        points = [point for stroke in labels.strokes(letter) for point in stroke]
        assert all(0 <= x <= 4 and 0 <= y <= labels.GRID for x, y in points)


def test_a_bend_puts_the_middle_of_a_label_on_its_angle() -> None:
    upper = labels.Bend(100, 80, 0, True, 10)
    lower = labels.Bend(100, 80, 270, False, 10)

    assert upper.point(10, 0) == pytest.approx((180, 100))
    assert upper.point(10, 5) == pytest.approx((185, 100))
    assert upper.point(0, 0)[1] < 100 < upper.point(20, 0)[1]
    assert lower.point(10, 5) == pytest.approx((100, 175))
    assert lower.point(0, 0)[0] < 100 < lower.point(20, 0)[0]


def test_a_stroke_becomes_its_pixels_in_order() -> None:
    assert labels.path_of([(0, 6), (2, 6), (2, 4)], 10) == [(10, 0), (11, 0), (12, 0), (12, 1), (12, 2)]
    assert labels.path_of([(0, 0), (2, 6)], 0)[-1] == (2, 0)
    assert len(labels.path_of([(0, 0), (2, 6)], 0)) == 7


def test_a_label_without_greys_gets_a_quarter_turn_about_its_middle() -> None:
    assert labels.turned((5, 3), labels.UP, 5) == (0, 0)
    assert labels.turned((0, 0), labels.UP, 5) == (-3, 5)
    assert labels.turned((0, 0), labels.BACK, 5) == (-3, 5)
    assert labels.turned((0, 0), labels.START, 5) == (3, -5)
    assert labels.turned((0, 6), labels.DOWN, 5) == (-3, -5)


def test_the_rows_of_a_label_follow_the_round_edge() -> None:
    right, left = (191, 54), (20, 158)

    assert labels.edge_shift(208, right, 54) == 0
    assert labels.edge_shift(208, right, 40) < 0 < labels.edge_shift(208, right, 68)
    assert labels.edge_shift(208, left, 150) < 0 < labels.edge_shift(208, left, 170)
    assert labels.edge_shift(208, (4, 104), 90) == 1
    assert labels.edge_shift(208, right, 0) == labels.edge_shift(208, right, 1)


def test_the_pixel_labels_sit_around_their_anchor_inside_the_round_screen() -> None:
    for slot in (labels.UP, labels.START, labels.DOWN, labels.BACK):
        screen = labels.draw_pixels(208, "ZURUCK", slot, ARC)
        left, top, right, bottom = screen.getbbox() or (0, 0, 0, 0)
        center = labels.anchor(208, ARC, slot)

        assert left <= center[0] < right
        assert abs((top + bottom - 1) // 2 - center[1]) <= 1
        assert all(
            (x - 103.5) ** 2 + (y - 103.5) ** 2 <= 104**2
            for x in range(left, right)
            for y in range(top, bottom)
            if screen.getpixel((x, y))
        )


def test_the_small_screen_gets_thin_pure_white_lines() -> None:
    image = labels.label_image(208, "ME", labels.UP, ARC)

    assert image.mode == "RGBA"
    assert inks(image) == {255}
    assert image.width <= 12
    assert image.height <= 30


def test_the_other_screens_get_dim_letters_in_the_greys_they_have() -> None:
    image = labels.label_image(260, "FAULT", labels.START, ARC)
    greys = inks(image)

    assert max(greys) == 0xAA
    assert greys <= {0x55, 0xAA}
    assert set(image.getchannel("A").tobytes()) == {0, 255}


def test_the_letters_stay_inside_the_ring_at_the_edge() -> None:
    for width, style in labels.STYLES.items():
        screen = labels.draw_label(width, "ZURUCK", labels.BACK, ARC, style)
        small = screen.resize((width, width), Image.Resampling.BOX)
        left, top, right, bottom = small.getbbox() or (0, 0, 0, 0)

        assert right <= width
        assert bottom <= width
        assert left > width // 2
        assert top > width // 2


def test_an_image_is_cropped_with_its_anchor_in_the_middle() -> None:
    image = Image.new("L", (40, 40), 0)
    image.putpixel((10, 12), 255)
    image.putpixel((18, 20), 255)

    cropped = labels.crop_around(image, (12, 18))

    assert cropped.size == (14, 12)
    assert cropped.getpixel((5, 0)) == 255


def test_an_empty_label_is_an_error() -> None:
    with pytest.raises(ValueError, match="no ink"):
        labels.crop_around(Image.new("L", (4, 4), 0), (2, 2))


def test_two_labels_of_one_side_may_not_meet() -> None:
    texts = {"eng": dict.fromkeys(labels.LABELS, "OK")}
    wide = {"por": {**texts["eng"], "LabelMe": "A" * 20, "KeyUndo": "B" * 30}}

    assert labels.too_wide(texts, ARC) == []
    assert labels.too_wide(wide, ARC) == [
        f"TOO WIDE por {'A' * 20} + OK",
        f"TOO WIDE por OK + {'B' * 30}",
    ]


def test_the_resource_file_lists_every_label_with_its_palette() -> None:
    xml = labels.drawables_xml(labels.STYLES[260])

    assert xml.count("<bitmap ") == len(labels.LABELS)
    assert '<bitmap id="KeyUndo" filename="KeyUndo.png" dithering="none">' in xml
    assert labels.palette_xml(labels.STYLES[260]) == (
        '<palette disableTransparency="false"><color>555555</color><color>AAAAAA</color></palette>'
    )
    assert labels.palette_xml(labels.STYLES[208]).count("<color>") == 1


def test_only_the_listed_watches_get_images_and_lose_the_arc_code() -> None:
    lines = labels.jungle_lines()

    assert "fr55.excludeAnnotations = keyArc" in lines
    assert "fr55.resourcePath = $(fr55.resourcePath);keylabels/208/eng" in lines
    assert "fr255.lang.por = $(fr255.lang.por);keylabels/260/por" in lines
    assert not [line for line in lines if line.startswith("fr55.lang.por")]
    assert not [line for line in lines if ".lang.eng" in line]
    assert len([line for line in lines if "excludeAnnotations" in line]) == len(labels.DEVICE_SIZES)
    assert set(labels.DEVICE_SIZES.values()) == set(labels.STYLES)


def test_generating_writes_every_image_and_the_check_passes(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    root = copy_sources(tmp_path)

    assert labels.main([], root) == 0
    assert labels.main(["--check"], root) == 0

    images = list((root / labels.FOLDER).rglob("*.png"))
    assert len(images) == len(labels.STYLES) * len(labels.LANGUAGES) * len(labels.LABELS)
    assert (root / labels.FOLDER / "208" / "por" / "drawables.xml").is_file()
    assert (
        json.loads((root / labels.FOLDER / labels.INDEX).read_text(encoding="utf-8"))["texts"]["por"]["LabelMe"] == "EU"
    )
    assert capsys.readouterr().out == "key labels: OK\nkey labels: OK\n"


def test_the_committed_images_match_the_strings_and_the_layout() -> None:
    assert labels.check(labels.ROOT) == []


def test_the_check_fails_on_a_changed_string_a_missing_image_or_a_missing_build_line(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    root = copy_sources(tmp_path)
    labels.generate(root)
    replace_in(root / "resources-por" / "strings" / "strings.xml", ">EU<", ">MEU<")
    replace_in(root / labels.JUNGLE, "fr55.excludeAnnotations = keyArc", "")
    (root / labels.FOLDER / "208" / "eng" / "KeyMore.png").unlink()

    assert labels.main(["--check"], root) == 1
    assert capsys.readouterr().out.splitlines() == [
        "STALE keylabels: run make key-labels",
        "NOT IN monkey.jungle: fr55.excludeAnnotations = keyArc",
        "MISSING keylabels/208/eng/KeyMore.png",
        "key labels: FAILED",
    ]


def test_the_check_fails_without_an_index(tmp_path: Path) -> None:
    assert labels.check(copy_sources(tmp_path))[0] == "STALE keylabels: run make key-labels"


def test_nothing_is_written_when_two_labels_would_meet(tmp_path: Path) -> None:
    root = copy_sources(tmp_path)
    replace_in(root / "resources" / "strings" / "strings.xml", ">UNDO<", ">UNDOTHELASTPOINTORFAULTOFTHEGAME<")

    problems = labels.generate(root)

    assert len(problems) >= 1
    assert all(problem.startswith("TOO WIDE eng ") for problem in problems)
    assert not (root / labels.FOLDER).exists()


# The device files of the SDK are not in the repository: where they are
# installed, the list of watches is compared with them.
@pytest.mark.skipif(not DEVICE_FILES.is_dir(), reason="needs the device files of the Connect IQ SDK")
def test_the_listed_watches_are_round_with_the_listed_width() -> None:  # pragma: no cover
    for device, width in labels.DEVICE_SIZES.items():
        facts = json.loads((DEVICE_FILES / device / "compiler.json").read_text(encoding="utf-8"))

        assert facts["deviceFamily"].startswith("round-")
        assert facts["resolution"] == {"width": width, "height": width}
