#!/usr/bin/env python3
"""Re-certify the C17 model-15 compatibility receipt after an unrelated source edit.

WHY THIS EXISTS (issue #979)
----------------------------
The C17 guard pins the WHOLE-FILE blob of five files, two of which are large and
frequently edited. Any change to `R/drmTMB.R` -- an 18,000-line file -- stales the
`mc-0568/0569/0576` receipt, even when the edit is a `cli::cli_abort()` string
with no bearing on zero-one-beta model 15.

Issue #979 offers four responses. This tool implements option 4: keep whole-file
pinning exactly as strong, and make re-certification a single documented command
instead of a five-step manual ritual.

WHY NOT OPTION 2 (narrow the pin to the fingerprinted anchors)
--------------------------------------------------------------
Because the anchors do not cover what the receipt actually grades. The
fingerprint reads only `R/drmTMB.R` and `src/drmTMB.cpp`. But the runner derives
`mode_correlation` -- a graded field -- through `ranef.drmTMB()` in
`R/methods.R`, which the fingerprint never touches, and `convergence`,
`pdHess` and `max_gradient` come from fitting plumbing that is likewise
unanchored. Narrowing the pin to the anchors would therefore drop real coverage
*silently*, and a silent hole in an evidence guard is strictly worse than a noisy
one. The friction is the problem; the conservatism is not.

THE SAFETY PROPERTY THIS ADDS
-----------------------------
Re-certification by hand is a judgement call: you look at the new numbers and
decide they are fine. This tool refuses to rewire the ledger if the measured
behaviour moved. `--tolerance` is the only knob, it defaults to exact, and
exceeding it is a hard failure that prints the drift rather than recording it.
So the mechanical part is automated and the interpretive part is turned into a
check.

USAGE
    python3 tools/recertify-c17.py --label emmy          # run, verify, rewire
    python3 tools/recertify-c17.py --label x --dry-run   # run and verify only
"""

from __future__ import annotations

import argparse
import csv
import datetime as _dt
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNNER = "tools/run-lane-c-c17c1-c14-model15-compatibility.R"
RUNNER_OUT = ROOT / "docs/dev-log/implementation-recovery" / (
    "2026-08-01-lane-c-c17c1-c14-model15-compatibility-run-1"
)
MANIFEST = ROOT / (
    "docs/dev-log/dashboard/capability-ledger/"
    "2026-08-08-c17c2-c14-final-source-compatibility.tsv"
)
CELLS = ("mc-0568", "mc-0569", "mc-0576")


def read_tsv(path: Path) -> list[dict]:
    with path.open(newline="", encoding="utf-8") as fh:
        return list(csv.DictReader(fh, delimiter="\t"))


def sh(*args: str) -> str:
    return subprocess.run(
        list(args), cwd=ROOT, check=True, capture_output=True, text=True
    ).stdout.strip()


def current_fingerprint() -> str:
    sys.path.insert(0, str(ROOT / "tools"))
    import capability_ledger  # noqa: E402  (path set above)

    return capability_ledger.c14_model15_source_fingerprint()


def summary_by_cell(path: Path) -> dict[str, float]:
    return {
        r["cell_id"]: float(r["mean_tau_relative_error"])
        for r in read_tsv(path)
        if r["cell_id"] in CELLS
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--label", required=True,
                    help="short slug for the receipt directory, e.g. 'emmy'")
    ap.add_argument("--tolerance", type=float, default=0.0,
                    help="max allowed |change| in mean tau relative error per cell "
                         "(default 0.0 = must reproduce exactly)")
    ap.add_argument("--dry-run", action="store_true",
                    help="run and verify, but do not rename or rewire")
    args = ap.parse_args()

    if not MANIFEST.is_file():
        print(f"manifest not found: {MANIFEST}", file=sys.stderr)
        return 2

    rows = read_tsv(MANIFEST)
    before = summary_by_cell(ROOT / rows[0]["summary_path"])
    print("prior receipt:")
    for c in CELLS:
        print(f"    {c}  mean_tau_relative_error {before[c]!r}")

    if RUNNER_OUT.exists():
        print(f"\nrefusing to run: {RUNNER_OUT.relative_to(ROOT)} already exists.\n"
              "The runner hardcodes that directory; move or remove it first.",
              file=sys.stderr)
        return 2

    print(f"\nrunning {RUNNER} (~80 s) ...")
    subprocess.run(
        ["Rscript", "--no-init-file", RUNNER],
        cwd=ROOT, check=True,
        env={**__import__("os").environ, "R_PROFILE_USER": "/dev/null"},
        stdout=subprocess.DEVNULL,
    )

    after = summary_by_cell(RUNNER_OUT / "summary.tsv")
    print("\nnew receipt:")
    drift = {}
    for c in CELLS:
        d = abs(after[c] - before[c])
        drift[c] = d
        print(f"    {c}  {after[c]!r}   |change| {d:.3e}")

    worst = max(drift.values())
    if worst > args.tolerance:
        print(
            "\nREFUSING TO REWIRE: the measured behaviour moved.\n"
            f"  worst |change| {worst:.3e} exceeds tolerance {args.tolerance:.3e}\n"
            "  This is the signal the guard exists for. Do NOT raise the tolerance to\n"
            "  make it pass -- investigate what changed model-15 behaviour. The new\n"
            f"  receipt is left in place at {RUNNER_OUT.relative_to(ROOT)} for inspection.",
            file=sys.stderr,
        )
        return 1

    print(f"\nbehaviour reproduced within tolerance ({worst:.3e} <= {args.tolerance:.3e}).")

    if args.dry_run:
        print(f"--dry-run: leaving {RUNNER_OUT.relative_to(ROOT)} in place, manifest untouched.")
        return 0

    stamp = _dt.date.today().isoformat()
    dest = RUNNER_OUT.parent / f"{stamp}-{args.label}-c17c2-c14-final-source-compatibility"
    if dest.exists():
        print(f"destination already exists: {dest.relative_to(ROOT)}", file=sys.stderr)
        return 2
    shutil.move(str(RUNNER_OUT), str(dest))
    rel = dest.relative_to(ROOT).as_posix()
    print(f"receipt -> {rel}")

    sha = sh("git", "rev-parse", "HEAD")
    fp = current_fingerprint()
    fields = list(rows[0].keys())
    for r in rows:
        r["raw_attempts_path"] = f"{rel}/raw-attempts.tsv"
        r["provenance_path"] = f"{rel}/provenance.tsv"
        r["summary_path"] = f"{rel}/summary.tsv"
        r["current_source_sha"] = sha
        r["source_fingerprint"] = fp
    with MANIFEST.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=fields, delimiter="\t", lineterminator="\n")
        w.writeheader()
        w.writerows(rows)
    print(f"manifest rewired: current_source_sha={sha[:9]} source_fingerprint={fp[:12]}...")
    print("\nclaim_boundary is NOT touched -- it is prose describing what sits outside the\n"
          "authenticated anchors, and only a human knows what the current change was.\n"
          "Review it before committing.")

    print("\nverifying ...")
    subprocess.run([sys.executable, "tools/capability_ledger.py", "--check"], cwd=ROOT, check=True)
    subprocess.run([sys.executable, "-m", "unittest",
                    "tools/tests/test_capability_ledger.py"], cwd=ROOT, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
