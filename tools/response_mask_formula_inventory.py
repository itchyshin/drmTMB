#!/usr/bin/env python3
"""Generate the response-missingness formula inventory from the capability ledger.

The existing ``missing_response`` ledger axis is deliberately family-level.  This
tool projects each ``model_surface`` cell onto that family evidence without
silently promoting a random, structured, covariance, or REML formula because
its base density has a response mask.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "docs/dev-log/dashboard/capability-ledger"
CELLS = LEDGER / "cells.tsv"
OUTPUT = LEDGER / "response-mask-formulas.tsv"

FIELDS = [
    "formula_cell_id", "model_cell_id", "family_type", "model_type",
    "route_variant", "route_modifier", "dpar", "effect_type",
    "structure_provider", "dimension", "q_gate", "estimator",
    "formula_status", "family_mask_gate", "formula_mask_gate",
    "claim_boundary", "next_gate",
]

EXPLICIT_BOUNDARIES = (
    {
        "formula_cell_id": "rmf-biv-gaussian-meta-v-partial",
        "model_cell_id": "",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "partial_response_dense_known_V",
        "route_modifier": "meta_V",
        "dpar": "rho12",
        "effect_type": "fixed",
        "structure_provider": "none",
        "dimension": "bivariate",
        "q_gate": "na",
        "estimator": "ML",
        "formula_status": "blocked_dense_known_V",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G0",
        "claim_boundary": (
            "Partial bivariate response rows with dense meta_V(V = V) are rejected; "
            "the covariance needs component-level slicing."
        ),
        "next_gate": (
            "Implement component-level covariance slicing and verify it against a dense-MVN oracle."
        ),
    },
)


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def formula_gate(row: dict[str, str]) -> tuple[str, str, str]:
    """Return status, evidence gate, and next action for one model-surface cell."""
    if row["capability_status"] != "implemented":
        return (
            "not_admitted", "G0",
            "Keep the response-mask cell absent until this formula is admitted."
        )
    if row["estimator"] == "REML":
        return (
            "blocked_reml", "G0",
            "Derive and validate the observed-response restricted likelihood before admission."
        )
    if row["dimension"] == "bivariate" and row["route_modifier"] == "meta_V":
        return (
            "blocked_dense_known_V", "G0",
            "Implement component-level covariance slicing and verify it against a dense-MVN oracle."
        )
    if row["effect_type"] == "fixed":
        return (
            "family_validated", "G3",
            "Retain the family-level sentinel and recovery evidence for this fixed-effect formula."
        )
    return (
        "needs_formula_evidence", "G1",
        "Add formula-specific G2 sentinel/oracle checks and G3 known-DGP recovery evidence."
    )


def build(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    model = [row for row in rows if row["axis"] == "model_surface"]
    # Mixture routes deliberately share a base ``family_type`` with their
    # Poisson/NB2 density, so ``family_type`` is not a primary key here.
    # ``family_route`` is the public response route and is unique on the
    # missing-response axis.
    missing = {row["family_route"]: row for row in rows if row["axis"] == "missing_response"}
    result: list[dict[str, str]] = []
    for row in model:
        if row["family_route"] not in missing:
            raise ValueError(f"{row['cell_id']}: no missing-response family row")
        family = missing[row["family_route"]]
        status, gate, next_gate = formula_gate(row)
        result.append({
            "formula_cell_id": f"rmf-{row['cell_id']}",
            "model_cell_id": row["cell_id"],
            "family_type": row["family_type"],
            "model_type": row["model_type"],
            "route_variant": row["route_variant"],
            "route_modifier": row["route_modifier"],
            "dpar": row["dpar"],
            "effect_type": row["effect_type"],
            "structure_provider": row["structure_provider"],
            "dimension": row["dimension"],
            "q_gate": row["q_gate"],
            "estimator": row["estimator"],
            "formula_status": status,
            "family_mask_gate": family["test_gate"],
            "formula_mask_gate": gate,
            "claim_boundary": (
                "Family-level response-mask evidence does not promote this formula cell. "
                + row["claim_boundary"]
            ),
            "next_gate": next_gate,
        })
    return result + list(EXPLICIT_BOUNDARIES)


def render(rows: list[dict[str, str]]) -> str:
    from io import StringIO

    output = StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=FIELDS, delimiter="\t", lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.write == args.check:
        parser.error("choose exactly one of --write or --check")

    rendered = render(build(read_tsv(CELLS)))
    if args.write:
        OUTPUT.write_text(rendered, encoding="utf-8")
        print(OUTPUT.relative_to(ROOT))
    elif not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8") != rendered:
        raise SystemExit("response-mask formula inventory is stale; run --write")
    else:
        print("response-mask formula inventory: OK")


if __name__ == "__main__":
    main()
