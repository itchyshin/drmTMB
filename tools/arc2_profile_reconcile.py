#!/usr/bin/env python3
"""Fail-closed reconciler for tools/run-arc2-profile-feasibility.R receipts.

Mirrors the Arc 1 reconcilers (tools/reconcile-arc1-gaussian-fixed-profiles.py,
tools/reconcile-arc1-gaussian-reml-slope-profiles.py) and reuses their shared
parsing/verification core (tools/arc1_profile_reconcile.py) unchanged: it
parses the receipt/interval/trace sidecars (not just hashes them), requires
receipt and interval endpoints to agree, requires the retained trace to carry
the same estimate/endpoints on every row and to span both sides of the
estimate, and requires the receipt's `runner_sha256` to match the CURRENT
tools/run-arc2-profile-feasibility.R file on disk.

Unlike the Arc 1 reconcilers -- each frozen to one hardcoded historical
`source_sha` because they reconcile a single immutable, already-merged
receipt cohort -- Arc 2 is still an active, unmerged worktree contract, so
this reconciler does not pin a historical commit. It instead requires every
receipt in one reconciliation run to share the SAME `source_sha` (internal
consistency across the seed cohort), and lets `--cell` select which
capability-ledger cell's contract (target, cohort, family, provider,
estimator) to check against, via CELL_CONTRACTS below. Add an entry there
whenever tools/run-arc2-profile-feasibility.R gains a new cell.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path

from arc1_profile_reconcile import read_one, require_fields, sha256, validate_profile_artifacts


CELL_CONTRACTS = {
    "mc-0186": {
        "target_id": "mc-0186::rho12",
        "cohort_id": "arc2-biv-gaussian-reml-rho12-profile-feasibility",
        "family": "biv_gaussian",
        "provider": "none",
        "estimator": "REML",
        "profile_parameter": "rho12",
    },
    "mc-0263": {
        "target_id": "mc-0263::fixef:sigma:x",
        "cohort_id": "arc2-gaussian-reml-heteroscedastic-sigma-fixef-profile-feasibility",
        "family": "gaussian",
        "provider": "none",
        "estimator": "REML",
        "profile_parameter": "fixef:sigma:x",
    },
    "mc-0274": {
        "target_id": "mc-0274::sd:mu:phylo(1 | species)",
        "cohort_id": "arc2-gaussian-reml-phylo-location-mu-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo",
        "estimator": "REML",
        "profile_parameter": "sd:mu:phylo(1 | species)",
    },
    "mc-0277": {
        "target_id": "mc-0277::sd:sigma:phylo(1 | species)",
        "cohort_id": "arc2-gaussian-reml-phylo-sigma-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo",
        "estimator": "REML",
        "profile_parameter": "sd:sigma:phylo(1 | species)",
    },
    "mc-0283": {
        "target_id": "mc-0283::sd:sigma:sigma:phylo(1 | p | species)",
        "cohort_id": "arc2-gaussian-reml-phylo-sigma-q2-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo",
        "estimator": "REML",
        "profile_parameter": "sd:sigma:sigma:phylo(1 | p | species)",
    },
    "mc-0013": {
        "target_id": "mc-0013::sd:mu:animal(0 + x | id)",
        "cohort_id": "arc2-beta-animal-mu-slope-sd-profile-feasibility",
        "family": "beta",
        "provider": "animal",
        "estimator": "ML",
        "profile_parameter": "sd:mu:animal(0 + x | id)",
    },
    "mc-0015": {
        "target_id": "mc-0015::sd:sigma:animal(1 | id)",
        "cohort_id": "arc2-beta-animal-sigma-intercept-sd-profile-feasibility",
        "family": "beta",
        "provider": "animal",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:animal(1 | id)",
    },
    "mc-0421": {
        "target_id": "mc-0421::sd:sigma:phylo(1 | species)",
        "cohort_id": "arc3-nbinom2-ml-phylo-sigma-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "phylo",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:phylo(1 | species)",
    },
    "mc-0422": {
        "target_id": "mc-0422::sd:sigma:spatial(1 | site)",
        "cohort_id": "arc3-nbinom2-ml-spatial-sigma-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "spatial",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:spatial(1 | site)",
    },
    "mc-0423": {
        "target_id": "mc-0423::sd:sigma:animal(1 | id)",
        "cohort_id": "arc3-nbinom2-ml-animal-sigma-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "animal",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:animal(1 | id)",
    },
    "mc-0424": {
        "target_id": "mc-0424::sd:sigma:relmat(1 | id)",
        "cohort_id": "arc3-nbinom2-ml-relmat-sigma-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "relmat",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:relmat(1 | id)",
    },
    "mc-0321": {
        "target_id": "mc-0321::sd:mu:phylo_interaction(1 | plant:pollinator)",
        "cohort_id": "arc3-gaussian-ml-phylo-interaction-mu-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo_interaction",
        "estimator": "ML",
        "profile_parameter": "sd:mu:phylo_interaction(1 | plant:pollinator)",
    },
    "mc-0409": {
        "target_id": "mc-0409::sd:mu:phylo_interaction(1 | plant:pollinator)",
        "cohort_id": "arc3-nbinom2-ml-phylo-interaction-mu-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "phylo_interaction",
        "estimator": "ML",
        "profile_parameter": "sd:mu:phylo_interaction(1 | plant:pollinator)",
    },
    "mc-0417": {
        "target_id": "mc-0417::sd:mu:spatial(1 | site)",
        "cohort_id": "arc4-nbinom2-ml-spatial-relmat-mu-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "spatial+relmat",
        "estimator": "ML",
        "profile_parameter": "sd:mu:spatial(1 | site)",
    },
}


def fail(message: str) -> None:
    raise SystemExit(f"Arc 2 reconciliation failed: {message}")


def reconcile(cell: str, root: Path, seeds: set[str]) -> list[dict[str, str]]:
    contract = CELL_CONTRACTS.get(cell)
    if contract is None:
        fail(f"unknown --cell {cell}; add it to CELL_CONTRACTS in this reconciler first")

    receipts = sorted(root.glob("*-receipt.tsv"))
    if len(receipts) != len(seeds):
        fail(f"expected {len(seeds)} receipts for {cell}, found {len(receipts)}")

    runner_path = Path(__file__).with_name("run-arc2-profile-feasibility.R")
    seen: set[str] = set()
    source_shas: set[str] = set()
    output: list[dict[str, str]] = []
    for path in receipts:
        row = read_one(path, "Arc 2 reconciliation failed")
        seed = row.get("seed", "")
        if seed not in seeds or seed in seen:
            fail(f"{path}: unexpected or duplicate seed {seed!r}")
        seen.add(seed)

        cell_field = row.get("cell_id", "")
        if cell_field != cell:
            fail(f"{path}: cell_id={cell_field!r}, expected {cell!r}")
        source_shas.add(row.get("source_sha", ""))

        required = {
            "target_id": contract["target_id"],
            "cohort_id": contract["cohort_id"],
            "family": contract["family"],
            "provider": contract["provider"],
            "estimator": contract["estimator"],
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
        require_fields(row, required, path, "Arc 2 reconciliation failed")
        hashes = validate_profile_artifacts(
            receipt_path=path,
            receipt=row,
            runner_path=runner_path,
            target_id=contract["target_id"],
            profile_parameter=contract["profile_parameter"],
            prefix="Arc 2 reconciliation failed",
            estimator=contract["estimator"],
        )
        output.append(
            {
                "cell_id": cell,
                "target_id": contract["target_id"],
                "seed": seed,
                "source_sha": row["source_sha"],
                "runner_sha256": row["runner_sha256"],
                "receipt_sha256": sha256(path),
                **hashes,
                "decision": "PASS_INTERVAL_FEASIBLE_TARGET",
            }
        )

    if seen != seeds:
        fail("seed denominator is incomplete")
    if len(source_shas) != 1:
        fail(f"receipts do not share one source_sha: {sorted(source_shas)}")
    return sorted(output, key=lambda row: row["seed"])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cell", required=True)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument(
        "--seeds", required=True, help="comma-separated list of expected seed values, e.g. 3,4,5"
    )
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    seeds = {s.strip() for s in args.seeds.split(",") if s.strip()}
    if not seeds:
        fail("--seeds must name at least one seed")
    rows = reconcile(args.cell, args.root, seeds)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)
    print(f"{args.cell}\t{CELL_CONTRACTS[args.cell]['target_id']}\t{len(rows)}/{len(seeds)}\tPASS")


if __name__ == "__main__":
    main()
