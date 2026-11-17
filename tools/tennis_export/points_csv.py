"""Writes points.csv: one row for each point log entry, in the order they were played."""

from __future__ import annotations

import csv
from typing import TYPE_CHECKING

from tennis_export.layout import ENDING_NAMES, name_at
from tennis_export.match_state import Outcome
from tennis_export.rules import ME, OPPONENT, PLAYER_NAMES

if TYPE_CHECKING:
    from collections.abc import Callable, Iterable
    from pathlib import Path

    from tennis_export.replay import Row

CLOSES = ((Outcome.MATCH, "match"), (Outcome.SET, "set"), (Outcome.GAME, "game"))


def kind_of(row: Row) -> str:
    if not row.is_point:
        return "fault"
    return "double_fault" if row.entry.is_fault else "point"


def winner_of(row: Row) -> str:
    return PLAYER_NAMES[row.situation.winner] if row.is_point else ""


def closes(row: Row) -> str:
    """The largest thing the entry ended: a game, a set or the match."""
    return next((name for flag, name in CLOSES if flag in row.outcome), "")


COLUMNS: tuple[tuple[str, Callable[[Row], object]], ...] = (
    ("sequence", lambda row: row.slot.sequence),
    ("time_s", lambda row: row.entry.time),
    ("heart_rate", lambda row: row.entry.heart_rate),
    ("set", lambda row: row.situation.set_number),
    ("game", lambda row: row.situation.game_number),
    ("point", lambda row: row.situation.point_number),
    ("server", lambda row: PLAYER_NAMES[row.situation.server]),
    ("serve", lambda row: 2 if row.situation.is_second_serve else 1),
    ("kind", kind_of),
    ("winner", winner_of),
    ("ending", lambda row: name_at(ENDING_NAMES, row.entry.ending)),
    ("tie_break", lambda row: int(row.situation.is_tie_break)),
    ("break_point", lambda row: int(row.situation.is_break_point)),
    ("set_point", lambda row: int(row.situation.is_set_point)),
    ("match_point", lambda row: int(row.situation.is_match_point)),
    ("score_me", lambda row: row.score.display_points[ME]),
    ("score_opponent", lambda row: row.score.display_points[OPPONENT]),
    ("games_me", lambda row: row.score.games[ME]),
    ("games_opponent", lambda row: row.score.games[OPPONENT]),
    ("sets_me", lambda row: row.score.sets[ME]),
    ("sets_opponent", lambda row: row.score.sets[OPPONENT]),
    ("closes", closes),
)


def write_points_csv(path: Path, rows: Iterable[Row]) -> None:
    """A value that does not apply (no heart rate, no winner on a fault) is left empty."""
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(name for name, _ in COLUMNS)
        writer.writerows([read(row) for _, read in COLUMNS] for row in rows)
