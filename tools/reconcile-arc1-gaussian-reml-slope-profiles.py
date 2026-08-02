#!/usr/bin/env python3
"""Fail-closed reconciler for the Arc 1 mc-0269 Gaussian REML slope SD."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from arc1_profile_reconcile import read_one, require_fields, sha256, validate_profile_artifacts


SOURCE_SHA = "c8e04258d9d550384b037b1e2a91734c22aaaab5"
TARGET_ID = "mc-0269::sd:mu:(0 + x | id)"
SEEDS = {"2026080252", "2026080253", "2026080254"}


def fail(message: str) -> None:
    raise SystemExit(f"Arc 1 Gaussian REML slope reconciliation failed: {message}")


def reconcile(root: Path) -> list[dict[str, str]]:
    receipts = sorted(root.glob("seed-*/*-receipt.tsv"))
    if len(receipts) != 3:
        fail(f"expected three receipts, found {len(receipts)}")
    seen: set[str] = set()
    output: list[dict[str, str]] = []
    runner_path = Path(__file__).with_name("run-arc1-gaussian-reml-slope-profile-feasibility.R")
    for path in receipts:
        row = read_one(path, "Arc 1 Gaussian REML slope reconciliation failed")
        seed = row.get("seed", "")
        if seed not in SEEDS or seed in seen:
            fail(f"unexpected or duplicate seed {seed}")
        seen.add(seed)
        require_fields(
            row,
            {
                "cell_id": "mc-0269",
                "target_id": TARGET_ID,
                "cohort_id": "arc1-gaussian-reml-slope-profile-feasibility",
                "family": "gaussian",
                "provider": "ordinary_re",
                "source_sha": SOURCE_SHA,
                "estimator": "REML",
                "target_type": "direct",
                "profile_engine": "tmbprofile",
                "promotion_eligible": "TRUE",
                "receipt_scope": "targetwise_interval_feasibility_only_no_coverage",
                "conf_status": "profile",
                "convergence": "0",
                "pdHess": "TRUE",
                "profile_boundary": "FALSE",
                "clamp_limited": "FALSE",
                "trace_complete": "TRUE",
                "failure_reason": "",
            },
            path,
            "Arc 1 Gaussian REML slope reconciliation failed",
        )
        hashes = validate_profile_artifacts(
            receipt_path=path,
            receipt=row,
            runner_path=runner_path,
            target_id=TARGET_ID,
            profile_parameter="sd:mu:(0 + x | id)",
            prefix="Arc 1 Gaussian REML slope reconciliation failed",
            estimator="REML",
        )
        output.append(
            {
                "cell_id": "mc-0269", "target_id": TARGET_ID, "seed": seed,
                "source_sha": SOURCE_SHA, "runner_sha256": row["runner_sha256"],
                "receipt_sha256": sha256(path), **hashes,
                "decision": "PASS_INTERVAL_FEASIBLE_TARGET",
            }
        )
    if seen != SEEDS:
        fail("seed denominator is incomplete")
    return sorted(output, key=lambda row: row["seed"])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    rows = reconcile(args.root)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)
    print(f"mc-0269\t{TARGET_ID}\t3/3\tPASS")


if __name__ == "__main__":
    main()
