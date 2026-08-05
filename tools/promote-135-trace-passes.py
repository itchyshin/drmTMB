#!/usr/bin/env python3
"""Promote the five 135-trace PASS cells to interval_feasible.

Authority: CELL-VERDICTS.md + FISHER-REVIEW.md (2026-08-05).
WITHHOLD cells are deliberately not touched.
"""
from __future__ import annotations

import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "docs/dev-log/dashboard/capability-ledger"
CELLS = LEDGER / "cells.tsv"
EVIDENCE = LEDGER / "evidence.tsv"
TRANSITIONS = LEDGER / "transitions.tsv"
ARTIFACT = "docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign"
SOURCE_SHA = "6618e4b30303f7815b272f709ac2c8d09089132d"
DATE = "2026-08-05"

STRUCTURED_TAIL = (
    " Documented ML sigma-axis low bias at small/moderate group counts; "
    "interval bracketing is therefore asymmetrically at risk on the upper "
    "endpoint. REML is unavailable for this family "
    "(drm_validate_reml_spec admits only Gaussian and binomial)."
)

COMMON_CAVEAT = (
    " Targetwise interval feasibility only - five seeds, single "
    "stats::profile() call per seed (TMB::tmbprofile / grid engine). "
    "No coverage, calibration, or Type-I error claim follows. Five seeds "
    "establish that a profile interval is obtainable and locates the truth, "
    "not that its nominal level is correct."
)

TARGETS = {
    "mc-0568": {
        "target": "sd:sigma:(1 | id)",
        "snippet": "zero_one_beta ordinary sigma intercept q1",
        "estimates": "0.388/0.420/0.420/0.377/0.393",
        "intervals": (
            "[0.299,0.518], [0.325,0.559], [0.324,0.559], "
            "[0.290,0.505], [0.304,0.524]"
        ),
        "truth": "0.45",
        "structured": False,
        "next_gate": (
            "Coverage/calibration remain out of scope; a separate goal is required."
        ),
        "notes": (
            "Promoted 135-trace: ordinary zero_one_beta sigma intercept; "
            "see claim_boundary."
        ),
    },
    "mc-0576": {
        "target": "sd:sigma:(0 + x | id)",
        "snippet": "zero_one_beta ordinary sigma slope q1",
        "estimates": "0.423/0.384/0.452/0.337/0.431",
        "intervals": (
            "[0.330,0.560], [0.297,0.511], [0.354,0.598], "
            "[0.260,0.450], [0.337,0.570]"
        ),
        "truth": "0.45",
        "structured": False,
        "next_gate": (
            "Coverage/calibration remain out of scope; a separate goal is required."
        ),
        "notes": (
            "Promoted 135-trace: ordinary zero_one_beta sigma slope; "
            "see claim_boundary."
        ),
    },
    "mc-0595": {
        "target": "sd:sigma:relmat(1 | species)",
        "snippet": "zero_one_beta sigma relmat q1",
        "estimates": "0.555/0.452/0.417/0.396/0.415",
        "intervals": (
            "[0.391,0.841], [0.309,0.696], [0.282,0.647], "
            "[0.264,0.616], [0.280,0.644]"
        ),
        "truth": "0.45",
        "structured": True,
        "next_gate": (
            "Coverage/calibration remain out of scope; q2-plus boundary remains "
            "mc-0702; REML unavailable for zero_one_beta."
        ),
        "notes": (
            "Promoted 135-trace: structured relmat sigma; ML bias + REML "
            "unavailable named in claim_boundary."
        ),
    },
    "mc-0596": {
        "target": "sd:sigma:spatial(1 | site)",
        "snippet": "zero_one_beta sigma spatial q1",
        "estimates": "0.502/0.451/0.311/0.451/0.452",
        "intervals": (
            "[0.333,0.788], [0.304,0.703], [0.187,0.519], "
            "[0.299,0.711], [0.301,0.708]"
        ),
        "truth": "0.45",
        "structured": True,
        "next_gate": (
            "Coverage/calibration remain out of scope; q2-plus boundary remains "
            "mc-0703; REML unavailable for zero_one_beta."
        ),
        "notes": (
            "Promoted 135-trace: structured spatial sigma; ML bias + REML "
            "unavailable named in claim_boundary."
        ),
    },
    "mc-0653": {
        "target": "sd:sigma:phylo_interaction(1 | plant:pollinator)",
        "snippet": "zi_nbinom2 sigma phylo_interaction q1",
        "estimates": "0.557/0.524/0.675/0.638/0.550",
        "intervals": (
            "[0.411,0.756], [0.367,0.730], [0.497,0.917], "
            "[0.474,0.858], [0.398,0.752]"
        ),
        "truth": "0.60",
        "structured": True,
        "next_gate": (
            "Coverage/calibration remain out of scope; REML unavailable for "
            "nbinom2 / zi_nbinom2 routes."
        ),
        "notes": (
            "Promoted 135-trace: zi_nbinom2 phylo_interaction sigma on 8x8 "
            "campaign DGP; ML bias + REML unavailable named in claim_boundary."
        ),
    },
}


def claim_boundary(cell_id: str, meta: dict) -> str:
    body = (
        f"Exact target {meta['target']}. A profile-likelihood interval exists "
        f"and is well-formed under ML for {meta['snippet']} "
        f"(true SD {meta['truth']}). Five-seed Totoro 135-trace campaign "
        f"(tools/run-135-trace-campaign.R; source SHA {SOURCE_SHA}): "
        f"estimates {meta['estimates']}, all five 95% profile intervals "
        f"bracket the true {meta['truth']} ({meta['intervals']}), "
        f"convergence 0, pdHess TRUE, profile_boundary FALSE, "
        f'conf_status "profile", clamp_limited FALSE (computed), '
        f"both-sides LR crossing and unimodality TRUE throughout."
        f"{COMMON_CAVEAT}"
    )
    if meta["structured"]:
        body += STRUCTURED_TAIL
    return body


def read_tsv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open(newline="") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        fieldnames = list(reader.fieldnames or [])
        rows = list(reader)
    return fieldnames, rows


def write_tsv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", newline="") as fh:
        writer = csv.DictWriter(
            fh,
            fieldnames=fieldnames,
            delimiter="\t",
            lineterminator="\n",
            extrasaction="ignore",
        )
        writer.writeheader()
        for row in rows:
            writer.writerow({k: row.get(k, "") for k in fieldnames})


def main() -> None:
    cell_fields, cells = read_tsv(CELLS)
    ev_fields, evidence = read_tsv(EVIDENCE)
    tr_fields, transitions = read_tsv(TRANSITIONS)
    by_cell = {row["cell_id"]: row for row in cells}

    for cell_id, meta in TARGETS.items():
        cell = by_cell[cell_id]
        if cell["evidence_tier"] != "point_fit_recovery":
            raise SystemExit(f"{cell_id}: expected point_fit_recovery, got {cell['evidence_tier']}")
        evidence_id = f"ev-{cell_id}-135trace-profile"
        transition_id = f"tr-{cell_id}-135trace-profile"
        boundary = claim_boundary(cell_id, meta)
        reconcile = (
            f"{ARTIFACT}/reconcile/{cell_id}-reconcile.tsv"
        )

        cell["evidence_tier"] = "interval_feasible"
        cell["primary_evidence_id"] = evidence_id
        cell["claim_boundary"] = boundary
        cell["next_gate"] = meta["next_gate"]
        cell["updated_commit"] = SOURCE_SHA
        cell["updated_date"] = DATE
        cell["notes"] = meta["notes"]

        evidence.append(
            {
                "evidence_id": evidence_id,
                "cell_id": cell_id,
                "evidence_class": "contract_test",
                "path_or_url": reconcile,
                "commit_sha": SOURCE_SHA,
                "run_id": "135-trace-prong-b-profile-feasibility",
                "command": (
                    "Totoro: Rscript tools/run-135-trace-campaign.R "
                    f"--cell={cell_id} --seed-index=<1-5> "
                    f"--target='{meta['target']}' "
                    "(GNU parallel -j64; DRMTMB_TOTORO_GO)"
                ),
                "result": "interval_feasible",
                "replicates": "5 exact target receipts (5 pass)",
                "reviewed_by": "tools/review-135-trace-receipts.R; Fisher location review",
                "review_date": DATE,
                "claim_boundary": boundary,
            }
        )
        transitions.append(
            {
                "transition_id": transition_id,
                "cell_id": cell_id,
                "from_work_status": "verified",
                "to_work_status": "verified",
                "evidence_ids": evidence_id,
                "reason": (
                    f"Five Totoro 135-trace receipts satisfy the exact direct "
                    f"{meta['target']} interval-feasibility contract; all five "
                    f"profile intervals bracket the true {meta['truth']}. "
                    f"Nine sibling campaign cells withheld. Targetwise interval "
                    f"feasibility only — no coverage claim."
                ),
                "actor": "Cursor 135-trace",
                "commit_sha": SOURCE_SHA,
                "date": DATE,
            }
        )
        print(f"promoted {cell_id} -> {evidence_id}")

    write_tsv(CELLS, cell_fields, cells)
    write_tsv(EVIDENCE, ev_fields, evidence)
    write_tsv(TRANSITIONS, tr_fields, transitions)
    print("wrote cells/evidence/transitions")


if __name__ == "__main__":
    main()
