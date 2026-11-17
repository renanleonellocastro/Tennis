"""The practice part of practice.json and the rows of blocks.csv: every block and the totals."""

from __future__ import annotations

import csv
from typing import TYPE_CHECKING, Any

from tennis_export.layout import SET_DISTANCE_FIELD, SET_STEPS_FIELD
from tennis_export.practice import success_percent

if TYPE_CHECKING:
    from collections.abc import Sequence
    from pathlib import Path

    from tennis_export.practice import Block

type Document = dict[str, Any]

LAP_TIMER = "total_timer_time"
TOTAL = "total"
COLUMNS = ("block", "hits", "misses", "shots", "success_percent", "duration_seconds", "steps", "distance_m")


def practice_document(blocks: Sequence[Block]) -> Document:
    return {"blocks": [block_document(block) for block in blocks], "totals": totals_document(blocks)}


def counts_document(hits: int, misses: int) -> Document:
    shots = hits + misses
    return {"hits": hits, "misses": misses, "shots": shots, "success_percent": success_percent(hits, shots)}


def block_document(block: Block) -> Document:
    """The time is what the timer counted while the block was open, so a pause is left out."""
    return {
        "block": block.number,
        **counts_document(block.hits, block.misses),
        "duration_seconds": block.lap.native.get(LAP_TIMER),
        "steps": block.lap.developer.get(SET_STEPS_FIELD),
        "distance_m": block.lap.developer.get(SET_DISTANCE_FIELD),
    }


def totals_document(blocks: Sequence[Block]) -> Document:
    hits = sum(block.hits for block in blocks)
    return {"blocks": len(blocks), **counts_document(hits, sum(block.misses for block in blocks))}


def write_blocks_csv(path: Path, practice: Document) -> None:
    """One row for each block and a last row named total; a value that is unknown is left empty."""
    rows = [*practice["blocks"], {**practice["totals"], "block": TOTAL}]
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(COLUMNS)
        writer.writerows([row.get(column) for column in COLUMNS] for row in rows)
