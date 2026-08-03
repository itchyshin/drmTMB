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
from profile_truth_gate import (
    TruthGateError,
    evaluate_cell,
    load_truth_manifest,
    require_pass,
    truth_for,
)


CELL_CONTRACTS = {
    "mc-0186": {
        "target_id": "mc-0186::rho12",
        "cohort_id": "arc2-biv-gaussian-reml-rho12-profile-feasibility",
        "family": "biv_gaussian",
        "provider": "none",
        "estimator": "REML",
        "profile_parameter": "rho12",
        "information_rung": "n150",
        "seeds": ("2026080201", "2026080202", "2026080203"),
    },
    "mc-0263": {
        "target_id": "mc-0263::fixef:sigma:x",
        "cohort_id": "arc2-gaussian-reml-heteroscedastic-sigma-fixef-profile-feasibility",
        "family": "gaussian",
        "provider": "none",
        "estimator": "REML",
        "profile_parameter": "fixef:sigma:x",
        "information_rung": "id30_each4",
        "seeds": ("2026080201", "2026080202", "2026080203"),
    },
    "mc-0274": {
        "target_id": "mc-0274::sd:mu:phylo(1 | species)",
        "cohort_id": "arc2-gaussian-reml-phylo-location-mu-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo",
        "estimator": "REML",
        "profile_parameter": "sd:mu:phylo(1 | species)",
        "information_rung": "tip30_each3",
        "seeds": ("2026080201", "2026080202", "2026080203"),
    },
    "mc-0277": {
        "target_id": "mc-0277::sd:sigma:phylo(1 | species)",
        "cohort_id": "arc2-gaussian-reml-phylo-sigma-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo",
        "estimator": "REML",
        "profile_parameter": "sd:sigma:phylo(1 | species)",
        "information_rung": "tip60_each12",
        "seeds": ("2026080201", "2026080202", "2026080203"),
    },
    "mc-0282": {
        "target_id": "mc-0282::sd:mu:mu:phylo(1 | p | species)",
        "cohort_id": "arc2-gaussian-reml-phylo-mu-q2-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo",
        "estimator": "REML",
        "profile_parameter": "sd:mu:mu:phylo(1 | p | species)",
        "information_rung": "tip60_each12",
        "seeds": ("101", "202", "303", "404", "505"),
    },
    "mc-0283": {
        "target_id": "mc-0283::sd:sigma:sigma:phylo(1 | p | species)",
        "cohort_id": "arc2-gaussian-reml-phylo-sigma-q2-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo",
        "estimator": "REML",
        "profile_parameter": "sd:sigma:sigma:phylo(1 | p | species)",
        "information_rung": "tip60_each12",
        "seeds": ("2026080301", "2026080302", "2026080303"),
    },
    "mc-0013": {
        "target_id": "mc-0013::sd:mu:animal(0 + x | id)",
        "cohort_id": "arc2-beta-animal-mu-slope-sd-profile-feasibility",
        "family": "beta",
        "provider": "animal",
        "estimator": "ML",
        "profile_parameter": "sd:mu:animal(0 + x | id)",
        "information_rung": "id40_each20",
        "seeds": ("2026080201", "2026080202", "2026080203"),
    },
    "mc-0015": {
        "target_id": "mc-0015::sd:sigma:animal(1 | id)",
        "cohort_id": "arc2-beta-animal-sigma-intercept-sd-profile-feasibility",
        "family": "beta",
        "provider": "animal",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:animal(1 | id)",
        "information_rung": "id40_each40",
        "seeds": ("2026080201", "2026080202", "2026080203"),
    },
    "mc-0421": {
        "target_id": "mc-0421::sd:sigma:phylo(1 | species)",
        "cohort_id": "arc3-nbinom2-ml-phylo-sigma-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "phylo",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:phylo(1 | species)",
        "information_rung": "tip80_each30",
        "seeds": ("2026080301", "2026080302", "2026080303"),
    },
    "mc-0422": {
        "target_id": "mc-0422::sd:sigma:spatial(1 | site)",
        "cohort_id": "arc3-nbinom2-ml-spatial-sigma-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "spatial",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:spatial(1 | site)",
        "information_rung": "site81_each25",
        "seeds": ("2026080301", "2026080302", "2026080303"),
    },
    "mc-0423": {
        "target_id": "mc-0423::sd:sigma:animal(1 | id)",
        "cohort_id": "arc3-nbinom2-ml-animal-sigma-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "animal",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:animal(1 | id)",
        "information_rung": "id40_each25",
        "seeds": ("2026080301", "2026080302", "2026080303"),
    },
    "mc-0424": {
        "target_id": "mc-0424::sd:sigma:relmat(1 | id)",
        "cohort_id": "arc3-nbinom2-ml-relmat-sigma-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "relmat",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:relmat(1 | id)",
        "information_rung": "id80_each25",
        "seeds": ("2026080301", "2026080302", "2026080303"),
    },
    "mc-0321": {
        "target_id": "mc-0321::sd:mu:phylo_interaction(1 | plant:pollinator)",
        "cohort_id": "arc3-gaussian-ml-phylo-interaction-mu-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo_interaction",
        "estimator": "ML",
        "profile_parameter": "sd:mu:phylo_interaction(1 | plant:pollinator)",
        "information_rung": "star_np8_npo8_each8",
        "seeds": ("2026080401", "2026080402", "2026080403", "2026080404", "2026080405"),
    },
    "mc-0409": {
        "target_id": "mc-0409::sd:mu:phylo_interaction(1 | plant:pollinator)",
        "cohort_id": "arc3-nbinom2-ml-phylo-interaction-mu-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "phylo_interaction",
        "estimator": "ML",
        "profile_parameter": "sd:mu:phylo_interaction(1 | plant:pollinator)",
        "information_rung": "star_np8_npo8_each24",
        "seeds": ("2026080401", "2026080402", "2026080403", "2026080404", "2026080405"),
    },
    "mc-0123": {
        "target_id": "mc-0123::sd:mu:mu1:spatial(1 | p | site)",
        "cohort_id": "arc4b-biv-gaussian-ml-spatial-q6-mu1-sd-profile-feasibility",
        "family": "biv_gaussian",
        "provider": "spatial",
        "estimator": "ML",
        "profile_parameter": "sd:mu:mu1:spatial(1 | p | site)",
        "information_rung": "n72_each20",
        "seeds": ("2026080301", "2026080302", "2026080303", "2026080304", "2026080305"),
    },
    "mc-0417": {
        "target_id": "mc-0417::sd:mu:spatial(1 | site)",
        "cohort_id": "arc4-nbinom2-ml-spatial-relmat-mu-sd-profile-feasibility",
        "family": "nbinom2",
        "provider": "spatial+relmat",
        "estimator": "ML",
        "profile_parameter": "sd:mu:spatial(1 | site)",
        "information_rung": "site20_id24_each5",
        "seeds": ("2026080501", "2026080502", "2026080503", "2026080504", "2026080505"),
    },
    "mc-0205": {
        "target_id": "mc-0205::sd:mu:mu1:(1 | p | id)",
        "cohort_id": "arc2-biv-gaussian-reml-musigma-mu1-sd-profile-feasibility",
        "family": "biv_gaussian",
        "provider": "none",
        "estimator": "REML",
        "profile_parameter": "sd:mu:mu1:(1 | p | id)",
        "information_rung": "id60_each8",
        "seeds": ("1", "2", "3", "4", "5"),
    },
    "mc-0206": {
        "target_id": "mc-0206::sd:sigma:sigma1:(1 | p | id)",
        "cohort_id": "arc2-biv-gaussian-reml-musigma-sigma1-sd-profile-feasibility",
        "family": "biv_gaussian",
        "provider": "none",
        "estimator": "REML",
        "profile_parameter": "sd:sigma:sigma1:(1 | p | id)",
        "information_rung": "id60_each8",
        "seeds": ("1", "2", "3", "4", "5"),
    },
    "mc-0286": {
        "target_id": "mc-0286::sd:mu:spatial(1 | site)",
        "cohort_id": "arc5-gaussian-ml-spatial-mu-one-slope-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "spatial",
        "estimator": "ML",
        "profile_parameter": "sd:mu:spatial(1 | site)",
        "information_rung": "site16_each20",
        "seeds": ("2861", "2862", "2863", "2864", "2865"),
    },
    "mc-0298": {
        "target_id": "mc-0298::sd:mu:animal(1 | id)",
        "cohort_id": "arc5-gaussian-ml-animal-mu-one-slope-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "animal",
        "estimator": "ML",
        "profile_parameter": "sd:mu:animal(1 | id)",
        "information_rung": "animal_nf8_each20",
        "seeds": ("2981", "2982", "2983", "2984", "2985"),
    },
    "mc-0291": {
        "target_id": "mc-0291::sd:mu:mu:spatial(1 | p | site)",
        "cohort_id": "arc2-gaussian-ml-spatial-mu-q2-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "spatial",
        "estimator": "ML",
        "profile_parameter": "sd:mu:mu:spatial(1 | p | site)",
        "information_rung": "site81_each25",
        "seeds": ("101", "202", "303", "404", "505"),
    },
    "mc-0303": {
        "target_id": "mc-0303::sd:mu:mu:animal(1 | p | id)",
        "cohort_id": "arc2-gaussian-ml-animal-mu-q2-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "animal",
        "estimator": "ML",
        "profile_parameter": "sd:mu:mu:animal(1 | p | id)",
        "information_rung": "id80_each25",
        "seeds": ("101", "202", "303", "404", "505"),
    },
    "mc-0315": {
        "target_id": "mc-0315::sd:mu:mu:relmat(1 | p | id)",
        "cohort_id": "arc2-gaussian-ml-relmat-mu-q2-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "relmat",
        "estimator": "ML",
        "profile_parameter": "sd:mu:mu:relmat(1 | p | id)",
        "information_rung": "id80_each25",
        "seeds": ("101", "202", "303", "404", "505"),
    },
    "mc-0279": {
        # NOT mc-0283 under a different ledger ID: mc-0279's real formula is
        # two UNLABELLED matching `phylo(1 | species)` terms (no "p" label),
        # estimator ML (mc-0283 is REML, labelled) -- see
        # tools/arc2-phylo-sigma-fixtures.R's header.
        "target_id": "mc-0279::sd:sigma:sigma:phylo(1 | species)",
        "cohort_id": "arc2-gaussian-ml-phylo-sigma-q2-nolabel-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "phylo",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:sigma:phylo(1 | species)",
        "information_rung": "tip60_each12",
        "seeds": ("101", "202", "303", "404", "505"),
    },
    "mc-0304": {
        "target_id": "mc-0304::sd:sigma:sigma:animal(1 | id)",
        "cohort_id": "arc2-gaussian-ml-animal-sigma-q2-nolabel-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "animal",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:sigma:animal(1 | id)",
        "information_rung": "founders4_id40_each12",
        "seeds": ("101", "202", "303", "404", "505"),
    },
    "mc-0316": {
        "target_id": "mc-0316::sd:sigma:sigma:relmat(1 | id)",
        "cohort_id": "arc2-gaussian-ml-relmat-sigma-q2-nolabel-sd-profile-feasibility",
        "family": "gaussian",
        "provider": "relmat",
        "estimator": "ML",
        "profile_parameter": "sd:sigma:sigma:relmat(1 | id)",
        "information_rung": "id80_each12",
        "seeds": ("101", "202", "303", "404", "505"),
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
    endpoints: dict[str, tuple[float, float]] = {}
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
            # Pinning the cohort, not just the seed, is load-bearing: mc-0409's
            # superseded n_each=8 receipts reuse the SAME seed numbers as its
            # repaired n_each=24 family, so a seed-only pin silently readmits
            # the cohort the repair replaced.
            "execution_information_rung": contract["information_rung"],
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
        try:
            endpoints[seed] = (float(row["lower"]), float(row["upper"]))
        except (KeyError, ValueError) as error:
            fail(f"{path}: unusable interval endpoints ({error})")

    if seen != seeds:
        fail("seed denominator is incomplete")
    if len(source_shas) != 1:
        fail(f"receipts do not share one source_sha: {sorted(source_shas)}")

    # The truth gate. Everything above this line checks interval SHAPE; without
    # this, an interval can be flawless on every one of those checks and still
    # sit in the wrong place. Five cells passed every shape check while holding
    # an interval that excluded their own true value: mc-0292, mc-0409 and
    # mc-0423 were caught by a human reading the receipt prose; mc-0424 and
    # mc-0260m were not, and shipped as interval_feasible until Arc 7b.
    try:
        truth = truth_for(cell, load_truth_manifest())
        require_pass(evaluate_cell(cell, truth, endpoints), "Arc 2 truth gate")
    except TruthGateError as error:
        fail(str(error))
    return sorted(output, key=lambda row: row["seed"])


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--cell", required=True)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument(
        "--seeds",
        help=(
            "comma-separated seed values. Optional: defaults to the cohort pinned in "
            "CELL_CONTRACTS. If given it must MATCH that pin exactly -- it cannot "
            "narrow the denominator, which is how a failing seed would otherwise be "
            "dropped from a reconciliation run."
        ),
    )
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    contract = CELL_CONTRACTS.get(args.cell)
    if contract is None:
        fail(f"unknown --cell {args.cell}; add it to CELL_CONTRACTS in this reconciler first")
    pinned = set(contract["seeds"])
    if args.seeds is None:
        seeds = pinned
    else:
        seeds = {s.strip() for s in args.seeds.split(",") if s.strip()}
        if seeds != pinned:
            fail(
                f"--seeds {sorted(seeds)} does not match the cohort pinned for "
                f"{args.cell}: {sorted(pinned)}"
            )
    rows = reconcile(args.cell, args.root, seeds)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]), delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)
    print(f"{args.cell}\t{CELL_CONTRACTS[args.cell]['target_id']}\t{len(rows)}/{len(seeds)}\tPASS")


if __name__ == "__main__":
    main()
