#!/usr/bin/env python3
"""Check the XML resources: valid XML, string catalogs in sync, table up to date.

Three gates, all of which must pass:
  1. manifest.xml and every XML file under resources*/ parse.
  2. Every language strings.xml has exactly the ids of the base (eng) file.
  3. source/generated/Strings.mc matches what scripts/generate_strings.py
     would write now.

Usage:
    python3 scripts/check_resources.py

Exit code 1 if any gate fails.
"""

import glob
import os
import re
import sys
import xml.dom.minidom
from xml.parsers.expat import ExpatError

import generate_strings

ROOT = generate_strings.REPO_ROOT
BASE_STRINGS = os.path.join("resources", "strings", "strings.xml")
STRING_ID_PATTERN = r'<string id="([^"]+)"'


def xml_files():
    return ["manifest.xml"] + sorted(glob.glob("resources*/**/*.xml", root_dir=ROOT, recursive=True))


def xml_problem(path):
    """The parse error of one file, or None when it is valid XML."""
    try:
        xml.dom.minidom.parse(os.path.join(ROOT, path))
    except ExpatError as error:
        return f"INVALID {path}: {error}"
    return None


def invalid_xml_problems():
    files = xml_files()
    print(f"checked {len(files)} XML files")
    return [problem for problem in map(xml_problem, files) if problem]


def string_ids(path):
    with open(os.path.join(ROOT, path), encoding="utf-8") as handle:
        return set(re.findall(STRING_ID_PATTERN, handle.read()))


def out_of_sync_problems():
    base = string_ids(BASE_STRINGS)
    print(f"base catalog has {len(base)} strings")
    problems = []
    for path in sorted(glob.glob("resources-*/strings/strings.xml", root_dir=ROOT)):
        difference = base.symmetric_difference(string_ids(path))
        if difference:
            problems.append(f"OUT OF SYNC {path}: {sorted(difference)}")
    return problems


def stale_table_problems():
    expected = generate_strings.render_module(generate_strings.read_tables())
    with open(generate_strings.OUTPUT_PATH, encoding="utf-8") as handle:
        if handle.read() == expected:
            return []
    return ["STALE source/generated/Strings.mc: run python3 scripts/generate_strings.py"]


def main():
    problems = invalid_xml_problems() + out_of_sync_problems() + stale_table_problems()
    for problem in problems:
        print(problem)
    print("RESOURCES FAILED" if problems else "RESOURCES OK")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
