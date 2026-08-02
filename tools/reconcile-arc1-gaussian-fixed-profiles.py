#!/usr/bin/env python3
"""Fail-closed reconciler for the Arc 1 Gaussian fixed-target receipts."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from arc1_profile_reconcile import (
    read_one,
    require_fields,
    sha256,
    validate_profile_artifacts,
)


SOURCE_SHA = "c8e04258d9d550384b037b1e2a91734c22aaaab5"
CONTRACTS = {
    "mc-0260": "mc-0260::fixef:mu:x",
    "mc-0262": "mc-0262::fixef:sigma:x",
}
SEEDS = {"2026080222", "2026080223", "2026080224"}


def fail(message: str) -> None:
    raise SystemExit(f"Arc 1 reconciliation failed: {message}")


def reconcile(root: Path) -> list[dict[str, str]]:
    receipts = sorted(root.glob("seed-*/*-receipt.tsv"))
    if len(receipts) != len(CONTRACTS) * len(SEEDS):
        fail(f"expected six receipts, found {len(receipts)}")
    seen: set[tuple[str, str]] = set()
    output: list[dict[str, str]] = []
    runner_path = Path(__file__).with_name("run-arc1-gaussian-fixed-profile-feasibility.R")
    for path in receipts:
        row = read_one(path, "Arc 1 reconciliation failed")
        cell = row.get("cell_id", "")
        seed = row.get("seed", "")
        key = (cell, seed)
        if cell not in CONTRACTS or seed not in SEEDS or key in seen:
            fail(f"unexpected or duplicate target/seed key {key}")
        seen.add(key)
        required = {
            "target_id": CONTRACTS[cell],
            "cohort_id": "arc1-gaussian-fixed-profile-feasibility",
            "family": "gaussian",
            "provider": "none",
            "source_sha": SOURCE_SHA,
            "estimator": "ML",
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
        }
        require_fields(row, required, path, "Arc 1 reconciliation failed")
        hashes = validate_profile_artifacts(
            receipt_path=path,
            receipt=row,
            runner_path=runner_path,
            target_id=CONTRACTS[cell],
            profile_parameter=CONTRACTS[cell].split("::", 1)[1],
            prefix="Arc 1 reconciliation failed",
        )
        output.append(
            {
                "cell_id": cell,
                "target_id": CONTRACTS[cell],
                "seed": seed,
                "source_sha": SOURCE_SHA,
                "runner_sha256": row["runner_sha256"],
                "receipt_sha256": sha256(path),
                **hashes,
                "decision": "PASS_INTERVAL_FEASIBLE_TARGET",
            }
        )
    expected = {(cell, seed) for cell in CONTRACTS for seed in SEEDS}
    if seen != expected:
        fail("target-by-seed denominator is incomplete")
    return sorted(output, key=lambda row: (row["cell_id"], row["seed"]))


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
    for cell in CONTRACTS:
        count = sum(row["cell_id"] == cell for row in rows)
        print(f"{cell}\t{CONTRACTS[cell]}\t{count}/3\tPASS")


if __name__ == "__main__":
    main()
