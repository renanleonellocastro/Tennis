"""The one error the command line reports instead of a traceback."""

from __future__ import annotations


class ExportError(Exception):
    """A file that cannot be read or that does not follow docs/DATA_FORMAT.md."""
