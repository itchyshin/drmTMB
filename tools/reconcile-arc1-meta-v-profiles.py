#!/usr/bin/env python3
"""Fail-closed reconciler for the Arc 1 mc-0260m pooled-effect receipts."""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from arc1_profile_reconcile import read_one, require_fields, sha256, validate_profile_artifacts


SOURCE_SHA = "c8e04258d9d550384b037b1e2a91734c22aaaab5"
TARGET_ID = "mc-0260m::fixef:mu:(Intercept)"
SEEDS = {"2026080232", "2026080233", "2026080234"}


def fail(message: str) -> None:
    raise SystemExit(f"Arc 1 meta_V reconciliation failed: {message}")


def reconcile(root: Path) -> list[dict[str, str]]:
    receipts = sorted(root.glob("seed-*/*-receipt.tsv"))
    if len(receipts) != 3:
        fail(f"expected three receipts, found {len(receipts)}")
    seen: set[str] = set()
    output: list[dict[str, str]] = []
    runner_path = Path(__file__).with_name("run-arc1-meta-v-profile-feasibility.R")
    for path in receipts:
        row = read_one(path, "Arc 1 meta_V reconciliation failed")
        seed = row.get("seed", "")
        if seed not in SEEDS or seed in seen:
            fail(f"unexpected or duplicate seed {seed}")
        seen.add(seed)
        required = {
            "cell_id": "mc-0260m",
            "target_id": TARGET_ID,
            "cohort_id": "arc1-meta-v-profile-feasibility",
            "provider": "meta_V",
            "source_sha": SOURCE_SHA,
            "estimator": "ML",
            "target_type": "direct",
            "profile_engine": "tmbprofile",
            "promotion_eligible": "TRUE",
            "receipt_scope": "pooled_effect_only_no_tau_interval_no_coverage",
            "conf_status": "profile",
            "convergence": "0",
            "pdHess": "TRUE",
            "profile_boundary": "FALSE",
            "clamp_limited": "FALSE",
            "trace_complete": "TRUE",
            "failure_reason": "",
        }
        require_fields(row, required, path, "Arc 1 meta_V reconciliation failed")
        hashes = validate_profile_artifacts(
            receipt_path=path,
            receipt=row,
            runner_path=runner_path,
            target_id=TARGET_ID,
            profile_parameter="fixef:mu:(Intercept)",
            prefix="Arc 1 meta_V reconciliation failed",
        )
        output.append({
            "cell_id": "mc-0260m", "target_id": TARGET_ID, "seed": seed,
            "source_sha": SOURCE_SHA, "runner_sha256": row["runner_sha256"],
            "receipt_sha256": sha256(path), **hashes,
            "decision": "PASS_INTERVAL_FEASIBLE_TARGET",
        })
    if seen != SEEDS:
        fail("seed denominator is incomplete")
    output.sort(key=lambda row: row["seed"])
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    output = reconcile(args.root)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(output[0]), delimiter="\t")
        writer.writeheader()
        writer.writerows(output)
    print(f"mc-0260m\t{TARGET_ID}\t3/3\tPASS")


if __name__ == "__main__":
    main()
