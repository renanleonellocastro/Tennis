#!/usr/bin/env python3
"""Compile the app for every product listed in manifest.xml.

`make build-shapes` compiles one device per screen shape and `make package`
stops at the first device that fails. This script compiles each device on
its own, so one run names every device that does not compile, with the
compiler output of each failure.

Usage:
    python3 scripts/build_all_devices.py --monkeyc PATH --key PATH
        [--type-check LEVEL] [--jobs N] [--output-dir DIR] [DEVICE ...]

Exit code 1 if any device fails to compile.
"""

import argparse
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_TYPE_CHECK = "2"
DEFAULT_OUTPUT_DIR = os.path.join("bin", "all")
# Each compiler is a Java process of its own; more than this gains little.
MAX_DEFAULT_JOBS = 8
WARNING_MARK = "WARNING:"


def manifest_devices():
    with open(os.path.join(ROOT, "manifest.xml"), encoding="utf-8") as handle:
        return re.findall(r'iq:product id="([^"]+)"', handle.read())


def default_jobs():
    return max(1, min(MAX_DEFAULT_JOBS, (os.cpu_count() or 2) // 2))


def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--monkeyc", required=True, help="path of the monkeyc compiler")
    parser.add_argument("--key", required=True, help="path of the developer signing key")
    parser.add_argument("--type-check", default=DEFAULT_TYPE_CHECK, help="type check level (0 to 3)")
    parser.add_argument("--jobs", type=int, default=default_jobs(), help="devices compiled at the same time")
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR, help="folder of the compiled programs")
    parser.add_argument("devices", nargs="*", help="devices to compile (default: every manifest product)")
    return parser.parse_args()


def compile_command(options, device):
    # A folder per device: the compiler keeps intermediate files next to the
    # program, and two compilers sharing them fail with a critical error.
    output = os.path.join(options.output_dir, device, f"Tennis-{device}.prg")
    return [
        options.monkeyc, "-f", "monkey.jungle", "-d", device, "-o", output,
        "-y", options.key, "-w", "-l", options.type_check,
    ]


def compile_device(options, device):
    """Compile one device; returns (device, passed, compiler output, seconds)."""
    started = time.monotonic()
    result = subprocess.run(
        compile_command(options, device),
        cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=False,
    )
    return device, result.returncode == 0, result.stdout.strip(), time.monotonic() - started


def report_device(position, total, outcome):
    device, passed, output, seconds = outcome
    status = "PASS" if passed else "FAIL"
    warnings = sum(WARNING_MARK in line for line in output.splitlines())
    print(f"[{position:>2}/{total}] {status}  {device:<26} {seconds:5.1f}s  {warnings} warnings", flush=True)
    if not passed:
        print("\n".join(f"        {line}" for line in output.splitlines()), flush=True)


def compile_all(options, devices):
    os.makedirs(os.path.join(ROOT, options.output_dir), exist_ok=True)
    outcomes = []
    with ThreadPoolExecutor(max_workers=options.jobs) as pool:
        for outcome in pool.map(lambda device: compile_device(options, device), devices):
            outcomes.append(outcome)
            report_device(len(outcomes), len(devices), outcome)
    return outcomes


def report_summary(outcomes, seconds):
    failed = [device for device, passed, _output, _seconds in outcomes if not passed]
    print(f"\n{len(outcomes) - len(failed)} passed, {len(failed)} failed, {len(outcomes)} devices in {seconds:.0f}s")
    if failed:
        print("FAILED: " + " ".join(failed))
    return failed


def main():
    options = parse_arguments()
    devices = options.devices or manifest_devices()
    started = time.monotonic()
    outcomes = compile_all(options, devices)
    return 1 if report_summary(outcomes, time.monotonic() - started) else 0


if __name__ == "__main__":
    sys.exit(main())
