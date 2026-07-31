#!/usr/bin/env python3
"""Private, per-outer-process supervisor for the AOI-3 diagnostic runner.

This is not a package API or an uncertainty method.  It isolates each outer
attempt in a separate R process so that a real wall-clock limit can terminate a
native TMB optimization; R's setTimeLimit() cannot reliably do that.
"""

import argparse
import csv
import os
import pathlib
import subprocess
import sys
from datetime import datetime, timezone


FORMULAS = ("additive", "mixed", "factor_interaction", "numeric_interaction", "transformation")


def timestamp():
    return datetime.now(timezone.utc).isoformat()


def read_manifest(path):
    with path.open(newline="") as handle:
        rows = list(csv.DictReader(handle))
    required = {"attempt_type", "formula_id", "n", "outer_id", "inner_id", "seed", "source_sha"}
    if not rows or not required.issubset(rows[0]):
        raise ValueError("Invalid AOI-3 supervised seed manifest schema.")
    return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--out-root", required=True, type=pathlib.Path)
    parser.add_argument("--seed-manifest", required=True, type=pathlib.Path)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--attempt-wall-time-seconds", required=True, type=float)
    parser.add_argument("--runner", default="tools/run-aoi3-bernoulli-nb2-full-refit.R", type=pathlib.Path)
    parser.add_argument("--n", default=720, type=int)
    parser.add_argument("--inner-n", default=3, type=int)
    arguments = parser.parse_args()
    if arguments.out_root.exists():
        raise ValueError("Refusing to overwrite immutable AOI-3 supervised result root.")
    if arguments.attempt_wall_time_seconds < 1:
        raise ValueError("--attempt-wall-time-seconds must be at least one second.")

    manifest = read_manifest(arguments.seed_manifest)
    if {row["source_sha"] for row in manifest} != {arguments.source_sha}:
        raise ValueError("AOI-3 supervised source SHA does not match the frozen manifest.")
    expected = {(formula, outer) for formula in FORMULAS for outer in range(1, 4)}
    observed = {(row["formula_id"], int(row["outer_id"])) for row in manifest if row["attempt_type"] == "outer"}
    if observed != expected:
        raise ValueError("AOI-3 supervised manifest must schedule exactly five formulae by three outers.")

    arguments.out_root.mkdir(parents=True)
    event_path = arguments.out_root / "supervisor-events.csv"
    fieldnames = ["timestamp_utc", "formula_id", "outer_id", "event", "exit_code", "elapsed_seconds", "message"]
    with event_path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        for formula in FORMULAS:
            for outer in range(1, 4):
                shard = arguments.out_root / "shards" / f"{formula}-o{outer}"
                command = [
                    "Rscript", str(arguments.runner), f"--out-dir={shard}", "--mode=diagnostic",
                    f"--seed-manifest={arguments.seed_manifest}", f"--formula-id={formula}",
                    f"--n={arguments.n}", "--strength=interior", f"--outer-start={outer}",
                    f"--outer-end={outer}", f"--inner-n={arguments.inner_n}",
                ]
                environment = os.environ.copy()
                environment["AOI3_SOURCE_SHA"] = arguments.source_sha
                started = datetime.now(timezone.utc)
                try:
                    completed = subprocess.run(
                        command, env=environment, text=True, capture_output=True,
                        timeout=arguments.attempt_wall_time_seconds, check=False,
                    )
                    elapsed = (datetime.now(timezone.utc) - started).total_seconds()
                    event = "outer_complete" if completed.returncode == 0 else "outer_process_error"
                    message = (completed.stderr or completed.stdout).strip()
                    code = completed.returncode
                except subprocess.TimeoutExpired as error:
                    elapsed = (datetime.now(timezone.utc) - started).total_seconds()
                    event = "outer_wall_time_exceeded"
                    message = f"attempt_wall_time_seconds={arguments.attempt_wall_time_seconds}; {error}"
                    code = 124
                writer.writerow({
                    "timestamp_utc": timestamp(), "formula_id": formula, "outer_id": outer,
                    "event": event, "exit_code": code, "elapsed_seconds": elapsed, "message": message,
                })
                handle.flush()
                os.fsync(handle.fileno())
                if event != "outer_complete":
                    (arguments.out_root / "INCOMPLETE").write_text("AOI3_SUPERVISED_INCOMPLETE\n")
                    return 1
    (arguments.out_root / "COMPLETE").write_text("AOI3_SUPERVISED_COMPLETE\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
