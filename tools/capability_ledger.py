#!/usr/bin/env python3
"""Validate and generate drmTMB's capability ledger and public surfaces.

The ledger is authoritative. Generated census, JSON, Markdown, HTML, vignette
include, and tranche summaries must never be edited by hand.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import html
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "docs/dev-log/dashboard/capability-ledger"
CELLS = LEDGER / "cells.tsv"
EVIDENCE = LEDGER / "evidence.tsv"
TRANSITIONS = LEDGER / "transitions.tsv"
SCHEMA = LEDGER / "schema.json"
CENSUS = ROOT / "docs/dev-log/dashboard/capability-census"

# C14 restores the package-boundary classification from the last ledger commit
# that recorded it explicitly.  This is a taxonomy correction, not evidence for
# an implementation: the immutable source set is deliberately named here so a
# future rerun cannot infer boundaries from a broad formula heuristic.  The
# committed snapshot keeps the check portable when the historical local-only
# commit is not available to a fresh CI checkout.
C14_BOUNDARY_SOURCE_COMMIT = "0ccffcb539e19c3b4eeabf394634ddbcfc930cd8"
C14_BOUNDARY_SOURCE_PATH = "docs/dev-log/dashboard/capability-ledger/cells.tsv"
C14_BOUNDARY_SOURCE_SNAPSHOT = LEDGER / "c14-boundary-source.tsv"
C14_BOUNDARY_COUNT = 330
C14_ZOB_LEAF_TAXONOMY = (
    ("mc-0583", "mc-0695"), ("mc-0584", "mc-0696"),
    ("mc-0585", "mc-0697"), ("mc-0586", "mc-0698"),
    ("mc-0587", "mc-0699"), ("mc-0593", "mc-0700"),
    ("mc-0594", "mc-0701"), ("mc-0595", "mc-0702"),
    ("mc-0596", "mc-0703"), ("mc-0597", "mc-0704"),
)
C14_ZOB_LEAF_TAXONOMY_SOURCE = (
    "docs/dev-log/dashboard/capability-ledger/"
    "c14-zob-structured-leaf-taxonomy.md"
)
C14_RECEIPT_EQUIVALENCE = LEDGER / "c14-receipt-equivalence.tsv"
C14_RECEIPT_EQUIVALENCE_TARGET = "e58d77119c3562cdfcede3191f2482b38b30f4af"
C14_RECEIPT_EQUIVALENCE_FINGERPRINT = (
    "854d09453a44610c4d699bbb442331634b93852c2aecd024e45892904052470b"
)
C14_RECEIPT_EQUIVALENCE_PATHS = (
    "R/drmTMB.R::zero_one_beta_spec",
    "R/drmTMB.R::zero_one_beta_start_and_map",
    "R/drmTMB.R::zero_one_beta_tmb_and_extractors",
    "src/drmTMB.cpp::model_type_15",
)
C17_C14_CURRENT_SOURCE_COMPATIBILITY = (
    LEDGER / "c17c2-c14-current-source-compatibility.tsv"
)
C17_C14_COMPATIBLE_SEEDS = {
    "mc-0568": {str(seed) for seed in range(2026073401, 2026073405)},
    "mc-0569": {str(seed) for seed in range(2026073501, 2026073505)},
    "mc-0576": {str(seed) for seed in range(2026073701, 2026073705)},
}
C17_C14_SOURCE_FILES = (
    "R/drmTMB.R",
    "R/methods.R",
    "src/drmTMB.cpp",
    "tests/testthat/test-zero-one-beta.R",
    "tools/run-lane-c-c17c1-c14-model15-compatibility.R",
)

DATE = "2026-07-14"
IMPORTED_MODEL_COUNT = 668
# 676 frozen census rows + mc-0260m, the meta_V route row landed 2026-07-25 from the
# approved draft docs/dev-log/handover/2026-07-21-mc-0260m-ledger-cell-draft.md. The row
# is an insert at the tier its evidence already supports (point_fit_recovery); nothing was
# promoted. Bump this guard only for an approved row insert, never to silence drift.
MODEL_SURFACE_COUNT = 687
ASSOCIATION_COUNT = 6
# The frozen 2026-07-09 census: the original 676 model_surface rows and their
# recovery tier. C12 promoted mc-0653, then the approved canonical Lane-C
# count tranche promoted mc-0418, mc-0425, mc-0436, mc-0446, mc-0450, and
# mc-0454. With explicit user approval, C14 promotes only mc-0568, mc-0569,
# and mc-0576 after source-equivalence verification and fresh three-lens GO.
# B4-CI C1 then C2 promote exactly the approved 24-cell ordinary/fixed cohort
# and 25-cell structured cohort from point-fit recovery to interval feasible.
# These are source-bound promotion receipts, not a blanket re-baseline.
FROZEN_CENSUS_COUNT = 676
FROZEN_CENSUS_POINT_FIT_RECOVERY = 92
B3_Q6_MU2_RUNNER_SHA = "a8d068e641105473b3f30723a92c909467a46fac"
B3_Q6_MU2_TARGETS = {
    "mc-0102": ("phylo", "mc-0101", "mc-0102::sd:mu:mu2:phylo(1 | p | species)"),
    "mc-0124": ("spatial", "mc-0123", "mc-0124::sd:mu:mu2:spatial(1 | p | site)"),
    "mc-0146": ("animal", "mc-0145", "mc-0146::sd:mu:mu2:animal(1 | p | id)"),
    "mc-0168": ("relmat", "mc-0167", "mc-0168::sd:mu:mu2:relmat(1 | p | id)"),
}
B3_Q6_MU2_PACKET = (
    ROOT / "docs/dev-log/evidence/2026-08-01-b3-q6-target-promotion-packet.tsv"
)
MODEL_FIELDS = [
    "family", "model_type", "dpar", "effect_type", "structure_provider",
    "dimension", "q_gate", "estimator", "status", "evidence_tier",
    "evidence_source", "notes",
]
CELL_FIELDS = [
    "cell_id", "source_order", "axis", "family_route", "family_type",
    "model_type", "route_variant", "route_modifier", "dpar", "effect_type",
    "structure_provider", "dimension", "q_gate", "estimator",
    "capability_status", "work_status", "evidence_tier", "test_gate",
    "tranche_id", "owner", "blocking_reviewers", "primary_evidence_id",
    "claim_boundary", "next_gate", "issue_url", "pr_url", "updated_commit",
    "updated_date", "legacy_evidence_source", "notes",
]
EVIDENCE_FIELDS = [
    "evidence_id", "cell_id", "evidence_class", "path_or_url", "commit_sha",
    "run_id", "command", "result", "replicates", "reviewed_by",
    "review_date", "claim_boundary",
]
TRANSITION_FIELDS = [
    "transition_id", "cell_id", "from_work_status", "to_work_status",
    "evidence_ids", "reason", "actor", "commit_sha", "date",
]

ROUTES = [
    (1, "gaussian", "gaussian", "base", "MR-T1"),
    (2, "biv_gaussian", "biv_gaussian", "base", "MR-T1"),
    (3, "student", "student", "base", "MR-T2"),
    (4, "lognormal", "lognormal", "base", "MR-T2"),
    (5, "gamma", "gamma", "base", "MR-T2"),
    (6, "poisson", "poisson", "base", "MR-T1"),
    (7, "nbinom2", "nbinom2", "base", "MR-T1"),
    (8, "zi_poisson", "poisson", "zi", "MR-T6"),
    (9, "zi_nbinom2", "nbinom2", "zi", "MR-T6"),
    (10, "beta", "beta", "base", "MR-T1"),
    (11, "truncated_nbinom2", "truncated_nbinom2", "base", "MR-T5"),
    (12, "hurdle_nbinom2", "truncated_nbinom2", "hu", "MR-T6"),
    (13, "cumulative_logit", "cumulative_logit", "base", "MR-T4"),
    (14, "beta_binomial", "beta_binomial", "base", "MR-T4"),
    (15, "zero_one_beta", "zero_one_beta", "base", "MR-T3"),
    (16, "tweedie", "tweedie", "base", "MR-T3"),
    (17, "skew_normal", "skew_normal", "base", "MR-T2"),
    (18, "binomial", "binomial", "base", "MR-T1"),
]
ADMITTED = {
    "gaussian", "biv_gaussian", "student", "lognormal", "gamma", "poisson",
    "nbinom2", "beta", "zero_one_beta", "tweedie", "beta_binomial",
    "cumulative_logit", "skew_normal", "binomial", "truncated_nbinom2",
    "zi_poisson", "zi_nbinom2", "hurdle_nbinom2",
}

WORK_STATUSES = {
    "backlog", "designed", "in_progress", "implemented_unverified",
    "verified", "blocked", "deferred",
}
CAPABILITY_STATUSES = {
    "not_implemented", "rejected_by_design", "scaffolded", "implemented",
}
TEST_GATES = {"na", "G0", "G1", "G2", "G3", "G4", "G5"}
# evidence_class was previously unconstrained, so a typo silently produced zero badges
# and a green --check. external_comparator is the newest member: agreement with an
# independent implementation. Adding a class here is deliberate; it is not a free-text field.
EVIDENCE_CLASSES = {
    "legacy_model_evidence", "model_recovery", "rejection_test", "recovery_test",
    "g2_contract_test", "contract_test", "coverage_study", "admission_test",
    "estimator_diagnostic", "external_comparator",
}
EVIDENCE_TIERS = {
    "supported", "inference_ready_with_caveats", "interval_feasible",
    "diagnostic_only", "point_fit_recovery", "none", "miswired", "na",
}

TIER_ORDER = [
    "supported", "inference_ready_with_caveats", "interval_feasible",
    "diagnostic_only", "point_fit_recovery", "none", "miswired",
]
STRUCTURED_PROVIDERS = [
    "phylo", "spatial", "animal", "relmat", "phylo_interaction",
]

# A route reaches the missing-predictor runtime gate through its fitted
# family_type, not necessarily through its user-facing route name. Keep this
# mapping explicit: mixture routes deliberately share the base family's gate,
# while the hurdle route deliberately does not.
MISSING_PREDICTOR_RUNTIME_GATE = {
    "gaussian": "gaussian",
    "biv_gaussian": "biv_gaussian",
    "student": "student",
    "lognormal": "lognormal",
    "gamma": "gamma",
    "poisson": "poisson",
    "nbinom2": "nbinom2",
    "zi_poisson": "poisson",
    "zi_nbinom2": "nbinom2",
    "beta": "beta",
    "truncated_nbinom2": "truncated_nbinom2",
    "hurdle_nbinom2": "truncated_nbinom2",
    "cumulative_logit": "cumulative_logit",
    "beta_binomial": "beta_binomial",
    "zero_one_beta": "zero_one_beta",
    "tweedie": "tweedie",
    "skew_normal": "skew_normal",
    "binomial": "binomial",
}


def git_sha() -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
    ).strip()


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def read_legacy_tsv_text(text: str) -> list[dict[str, str]]:
    """Read the historical census literally; its quote characters are data."""
    lines = text.splitlines()
    fields = lines[0].split("\t")
    rows = []
    for line_number, line in enumerate(lines[1:], start=2):
        values = line.split("\t")
        if len(values) != len(fields):
            raise SystemExit(
                f"Legacy census line {line_number} has {len(values)} fields, "
                f"expected {len(fields)}"
            )
        rows.append(dict(zip(fields, values)))
    return rows


def tsv_bytes(fields: list[str], rows: list[dict[str, str]]) -> bytes:
    from io import StringIO

    buffer = StringIO(newline="")
    writer = csv.DictWriter(
        buffer, fieldnames=fields, delimiter="\t", lineterminator="\n",
        extrasaction="ignore",
    )
    writer.writeheader()
    writer.writerows(rows)
    return buffer.getvalue().encode("utf-8")


def json_bytes(value: object) -> bytes:
    return (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def legacy_tsv_bytes(fields: list[str], rows: list[dict[str, str]]) -> bytes:
    """Preserve the historical census's unquoted tab-separated representation."""
    lines = ["\t".join(fields)]
    lines.extend("\t".join(row.get(field, "") for field in fields) for row in rows)
    return ("\n".join(lines) + "\n").encode("utf-8")


def compact_json_bytes(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")


def schema_value() -> dict[str, object]:
    return {
        "schema_version": 1,
        "axes": ["model_surface", "association", "missing_response"],
        "cell_fields": CELL_FIELDS,
        "evidence_fields": EVIDENCE_FIELDS,
        "transition_fields": TRANSITION_FIELDS,
        "enums": {
            "capability_status": sorted(CAPABILITY_STATUSES),
            "work_status": sorted(WORK_STATUSES),
            "test_gate": sorted(TEST_GATES),
            "evidence_tier": sorted(EVIDENCE_TIERS),
            "evidence_class": sorted(EVIDENCE_CLASSES),
        },
        "expected_counts": {
            "model_surface": MODEL_SURFACE_COUNT,
            "association": ASSOCIATION_COUNT,
            "missing_response": 18,
        },
        "missing_response_verified_gate": "G3",
        "claim_boundary": (
            "Missing-response evidence is independent of model inference maturity."
        ),
    }


def missing_evidence_source(route: str) -> str:
    specific = {
        "gaussian": "tests/testthat/test-missing-response-gaussian.R",
        "biv_gaussian": "tests/testthat/test-missing-response-biv-gaussian.R",
        "binomial": "tests/testthat/test-missing-response-binomial.R",
        "poisson": "tests/testthat/test-missing-response-poisson.R",
        "nbinom2": "tests/testthat/test-missing-response-nbinom2.R",
        "beta": "tests/testthat/test-missing-response-beta.R",
        "zi_poisson": "R/drmTMB.R:5585-5589",
        "zi_nbinom2": "R/drmTMB.R:6126-6130",
    }
    return specific.get(route, "tests/testthat/test-missing-response-family-gate.R")


def bootstrap() -> None:
    if any(path.exists() for path in (CELLS, EVIDENCE, TRANSITIONS, SCHEMA)):
        raise SystemExit("Refusing bootstrap: capability-ledger source files already exist")

    master = read_legacy_tsv_text((CENSUS / "_master.tsv").read_text(encoding="utf-8"))
    if len(master) != IMPORTED_MODEL_COUNT:
        raise SystemExit(
            f"Expected {IMPORTED_MODEL_COUNT} legacy rows, found {len(master)}"
        )

    visible = [
        "family", "model_type", "dpar", "effect_type", "structure_provider",
        "dimension", "q_gate", "estimator",
    ]
    groups: dict[tuple[str, ...], list[int]] = defaultdict(list)
    for index, row in enumerate(master, start=1):
        groups[tuple(row[field] for field in visible)].append(index)

    sha = git_sha()
    cells: list[dict[str, str]] = []
    evidence: list[dict[str, str]] = []
    transitions: list[dict[str, str]] = []

    occurrence: Counter[tuple[str, ...]] = Counter()
    for index, old in enumerate(master, start=1):
        key = tuple(old[field] for field in visible)
        occurrence[key] += 1
        variant = "base" if len(groups[key]) == 1 else f"legacy_{occurrence[key]:02d}"
        cell_id = f"mc-{index:04d}"
        evidence_id = f"ev-{cell_id}-legacy" if old["evidence_source"] else ""
        status = old["status"]
        # The pre-ledger census used `rejected_by_design` for cells deliberately
        # out of scope at the time. That was not a proof of impossibility: every
        # unimplemented model cell belongs to the visible backlog.
        status = "not_implemented" if status == "rejected_by_design" else status
        work = "verified" if status == "implemented" else "backlog"
        cells.append({
            "cell_id": cell_id,
            "source_order": str(index),
            "axis": "model_surface",
            "family_route": old["family"],
            "family_type": old["family"],
            "model_type": old["model_type"],
            "route_variant": variant,
            "route_modifier": "base",
            "dpar": old["dpar"],
            "effect_type": old["effect_type"],
            "structure_provider": old["structure_provider"],
            "dimension": old["dimension"],
            "q_gate": old["q_gate"],
            "estimator": old["estimator"],
            "capability_status": status,
            "work_status": work,
            "evidence_tier": old["evidence_tier"],
            "test_gate": "na",
            "tranche_id": "legacy-census",
            "owner": "",
            "blocking_reviewers": "",
            "primary_evidence_id": evidence_id,
            "claim_boundary": old["notes"],
            "next_gate": "Preserve the existing model-surface evidence tier.",
            "issue_url": "",
            "pr_url": "",
            "updated_commit": sha,
            "updated_date": DATE,
            "legacy_evidence_source": old["evidence_source"],
            "notes": old["notes"],
        })
        if evidence_id:
            evidence.append({
                "evidence_id": evidence_id,
                "cell_id": cell_id,
                "evidence_class": "legacy_model_evidence",
                "path_or_url": old["evidence_source"],
                "commit_sha": sha,
                "run_id": "",
                "command": "",
                "result": "imported",
                "replicates": "",
                "reviewed_by": "MR-T0 migration",
                "review_date": DATE,
                "claim_boundary": old["notes"],
            })
        transitions.append({
            "transition_id": f"tr-{cell_id}-seed",
            "cell_id": cell_id,
            "from_work_status": "",
            "to_work_status": work,
            "evidence_ids": evidence_id,
            "reason": (
                f"MR-T0 import of the unchanged {IMPORTED_MODEL_COUNT}-cell census"
            ),
            "actor": "Codex MR-T0",
            "commit_sha": sha,
            "date": DATE,
        })

    for offset, (model_type, route, family_type, modifier, tranche) in enumerate(ROUTES, start=1):
        admitted = route in ADMITTED
        cell_id = f"mr-{route.replace('_', '-')}"
        evidence_id = f"ev-{cell_id}-baseline"
        boundary = (
            "Route is admitted by current code, but MR-T1 must repair/audit true "
            "sentinel mutation, residual/accounting semantics, and named recovery "
            "before a verified tick."
            if admitted else
            "Current code rejects response-missingness for this exact route. "
            "No support is inherited from a base family."
        )
        next_gate = (
            "MR-T1: complete the shared G2/G3 audit." if admitted else
            f"{tranche}: design and implement this route before G2/G3 validation."
        )
        cells.append({
            "cell_id": cell_id,
            "source_order": str(IMPORTED_MODEL_COUNT + offset),
            "axis": "missing_response",
            "family_route": route,
            "family_type": family_type,
            "model_type": str(model_type),
            "route_variant": "base",
            "route_modifier": modifier,
            "dpar": "all fitted dpars",
            "effect_type": "response_missingness",
            "structure_provider": "route_contract",
            "dimension": "bivariate" if route == "biv_gaussian" else "univariate",
            "q_gate": "na",
            "estimator": "ML",
            "capability_status": "implemented" if admitted else "not_implemented",
            "work_status": "implemented_unverified" if admitted else "backlog",
            "evidence_tier": "na",
            "test_gate": "G1" if admitted else "G0",
            "tranche_id": tranche,
            "owner": "",
            "blocking_reviewers": "Rose; Grace" if admitted else "Noether; Fisher",
            "primary_evidence_id": evidence_id,
            "claim_boundary": boundary,
            "next_gate": next_gate,
            "issue_url": "",
            "pr_url": "",
            "updated_commit": sha,
            "updated_date": DATE,
            "legacy_evidence_source": "",
            "notes": "Seeded from live builder/gate behavior during MR-T0.",
        })
        evidence.append({
            "evidence_id": evidence_id,
            "cell_id": cell_id,
            "evidence_class": "admission_test" if admitted else "rejection_test",
            "path_or_url": missing_evidence_source(route),
            "commit_sha": sha,
            "run_id": "",
            "command": "Rscript tools/check-capability-runtime.R",
            "result": "admitted_unverified" if admitted else "rejected",
            "replicates": "",
            "reviewed_by": "MR-T0 engine audit",
            "review_date": DATE,
            "claim_boundary": boundary,
        })
        transitions.append({
            "transition_id": f"tr-{cell_id}-seed",
            "cell_id": cell_id,
            "from_work_status": "",
            "to_work_status": "implemented_unverified" if admitted else "backlog",
            "evidence_ids": evidence_id,
            "reason": "MR-T0 route-level baseline from live code behavior",
            "actor": "Codex MR-T0",
            "commit_sha": sha,
            "date": DATE,
        })

    LEDGER.mkdir(parents=True, exist_ok=True)
    CELLS.write_bytes(tsv_bytes(CELL_FIELDS, cells))
    EVIDENCE.write_bytes(tsv_bytes(EVIDENCE_FIELDS, evidence))
    TRANSITIONS.write_bytes(tsv_bytes(TRANSITION_FIELDS, transitions))
    SCHEMA.write_bytes(json_bytes(schema_value()))
    print(f"Bootstrapped {len(cells)} cells and {len(evidence)} evidence records")


def c14_boundary_source_rows() -> list[dict[str, str]]:
    """Return the immutable C14 package-boundary source set.

    The prior MR-T0 import intentionally made all historical rows visible in a
    single implementation backlog. C14 reverses only the 330 records that an
    earlier committed ledger explicitly classified as package boundaries. The
    source commit is part of the contract: a row must never be reclassified by
    a pattern over its current formula fields.  Its checked-in ID snapshot is
    deliberately used instead of ``git show`` so source verification is
    available in a shallow CI checkout too.
    """
    rows = read_tsv(C14_BOUNDARY_SOURCE_SNAPSHOT)
    if not rows or set(rows[0]) != {"cell_id"}:
        raise SystemExit("C14 boundary source snapshot has an invalid schema")
    if len(rows) != C14_BOUNDARY_COUNT:
        raise SystemExit(
            "C14 boundary source count changed: "
            f"{len(rows)} (expected {C14_BOUNDARY_COUNT})"
        )
    ids = [row["cell_id"] for row in rows]
    if len(ids) != len(set(ids)):
        raise SystemExit("C14 boundary source contains duplicate cell IDs")
    return rows


def restore_c14_boundaries() -> None:
    """Restore only the source-pinned C14 package-boundary classifications."""
    source = c14_boundary_source_rows()
    source_ids = {row["cell_id"] for row in source}
    cells = read_tsv(CELLS)
    transitions = read_tsv(TRANSITIONS)
    by_id = {row["cell_id"]: row for row in cells}
    missing = source_ids - set(by_id)
    if missing:
        raise SystemExit(
            "C14 boundary source IDs missing from the current ledger: "
            + ", ".join(sorted(missing))
        )

    affected = [by_id[cell_id] for cell_id in source_ids]
    if any(row["axis"] != "model_surface" for row in affected):
        raise SystemExit("C14 boundary source attempted to alter a non-model row")
    if any(row["capability_status"] == "implemented" for row in affected):
        raise SystemExit("C14 taxonomy restoration would overwrite an implementation")
    unexpected = {
        (row["capability_status"], row["work_status"], row["evidence_tier"])
        for row in affected
        if (row["capability_status"], row["work_status"], row["evidence_tier"])
        not in {
            ("not_implemented", "backlog", "none"),
            ("rejected_by_design", "deferred", "none"),
        }
    }
    if unexpected:
        raise SystemExit(
            "C14 boundary source has non-taxonomy state in the current ledger: "
            + repr(sorted(unexpected))
        )

    for row in affected:
        row["capability_status"] = "rejected_by_design"
        row["work_status"] = "deferred"
        row["evidence_tier"] = "none"

    transition_ids = {row["transition_id"] for row in transitions}
    for cell_id in sorted(source_ids):
        transition_id = f"tr-{cell_id}-c14-boundary-taxonomy"
        if transition_id in transition_ids:
            continue
        transitions.append({
            "transition_id": transition_id,
            "cell_id": cell_id,
            "from_work_status": "backlog",
            "to_work_status": "deferred",
            "evidence_ids": "",
            "reason": (
                "C14 source-pinned taxonomy restoration from the explicit "
                f"package-boundary classification at {C14_BOUNDARY_SOURCE_COMMIT}; "
                "this changes no implementation or evidence claim."
            ),
            "actor": "Codex C14 taxonomy restoration",
            "commit_sha": C14_BOUNDARY_SOURCE_COMMIT,
            "date": "2026-07-31",
        })

    CELLS.write_bytes(tsv_bytes(CELL_FIELDS, cells))
    TRANSITIONS.write_bytes(tsv_bytes(TRANSITION_FIELDS, transitions))
    SCHEMA.write_bytes(json_bytes(schema_value()))
    print(
        "C14 boundary taxonomy restored "
        f"({len(affected)} rows from {C14_BOUNDARY_SOURCE_COMMIT})"
    )


def split_c14_zob_structured_leaves() -> None:
    """Replace C14's lossy zero-one-beta structured rows with exact leaves.

    Each original row becomes a q1 intercept leaf. A separate q2-plus boundary
    row is added for the same provider and endpoint, so promotion of the q1
    leaf can never silently inherit the untested higher-dimensional forms.
    """
    cells = read_tsv(CELLS)
    evidence = read_tsv(EVIDENCE)
    transitions = read_tsv(TRANSITIONS)
    by_id = {row["cell_id"]: row for row in cells}
    evidence_ids = {row["evidence_id"] for row in evidence}
    transition_ids = {row["transition_id"] for row in transitions}
    sha = git_sha()

    for original_id, boundary_id in C14_ZOB_LEAF_TAXONOMY:
        if original_id not in by_id:
            raise SystemExit(f"C14 q1 leaf source is missing: {original_id}")
        original = by_id[original_id]
        expected = {
            "axis": "model_surface",
            "family_route": "zero_one_beta",
            "effect_type": "structured",
            "capability_status": "not_implemented",
            "work_status": "backlog",
            "evidence_tier": "none",
        }
        if any(original[field] != value for field, value in expected.items()):
            raise SystemExit(
                f"C14 q1 leaf source has unexpected state: {original_id}"
            )

        q1_evidence_id = f"ev-{original_id}-c14-q1-leaf-taxonomy"
        q1_transition_id = f"tr-{original_id}-c14-q1-leaf-taxonomy"
        q1_boundary = (
            "Exact C14 leaf for ordinary ML zero_one_beta(): one unlabelled "
            f"structured {original['dpar']} intercept with provider "
            f"`{original['structure_provider']}` and q1 only. This leaf carries "
            "no point-fit evidence until its provider-specific oracle, retained "
            "attempts, source SHA, and independent GO review are bound. Slopes, "
            "labels, covariance, q2+, other random effects, profiles, intervals, "
            "coverage, and inference claims remain outside this leaf."
        )
        if q1_evidence_id not in evidence_ids:
            evidence.append({
                "evidence_id": q1_evidence_id,
                "cell_id": original_id,
                "evidence_class": "contract_test",
                "path_or_url": C14_ZOB_LEAF_TAXONOMY_SOURCE,
                "commit_sha": sha,
                "run_id": "c14-zob-structured-q1-leaf-taxonomy",
                "command": "python3 tools/capability_ledger.py --split-c14-zob-structured-leaves",
                "result": "q1_leaf_not_promoted",
                "replicates": "",
                "reviewed_by": "C14 taxonomy reconciliation",
                "review_date": "2026-07-31",
                "claim_boundary": q1_boundary,
            })
        original.update({
            "route_variant": "c14_exact_q1_structured_intercept",
            "q_gate": "q1",
            "tranche_id": "lane-c-c14-leaf-taxonomy",
            "owner": "Lane C",
            "blocking_reviewers": "Noether; Fisher; Rose",
            "primary_evidence_id": q1_evidence_id,
            "claim_boundary": q1_boundary,
            "next_gate": (
                "Bind this exact q1 leaf to its current-source oracle, all-attempt "
                "recovery receipt, and independent GO/BLOCK review before promotion."
            ),
            "updated_commit": sha,
            "updated_date": "2026-07-31",
            "notes": "C14 non-lossy q1 leaf; q2-plus boundary is " + boundary_id + ".",
        })
        if q1_transition_id not in transition_ids:
            transitions.append({
                "transition_id": q1_transition_id,
                "cell_id": original_id,
                "from_work_status": "backlog",
                "to_work_status": "backlog",
                "evidence_ids": q1_evidence_id,
                "reason": "C14 non-lossy taxonomy split; q1 remains unpromoted.",
                "actor": "Codex C14 leaf taxonomy",
                "commit_sha": sha,
                "date": "2026-07-31",
            })

        q2_evidence_id = f"ev-{boundary_id}-c14-q2plus-boundary"
        q2_transition_id = f"tr-{boundary_id}-c14-q2plus-boundary"
        q2_boundary = (
            "C14 q2-plus boundary paired with " + original_id + ": q2, q4, q6, "
            "q8, q12, slopes, labels, covariance, additional structured or "
            "ordinary random effects, profiles, intervals, coverage, and inference "
            "claims are not currently supported by the exact q1 leaf."
        )
        if boundary_id not in by_id:
            boundary = original.copy()
            boundary.update({
                "cell_id": boundary_id,
                "source_order": str(695 + len([pair for pair in C14_ZOB_LEAF_TAXONOMY if pair[1] < boundary_id])),
                "route_variant": "c14_q2plus_structured_boundary",
                "q_gate": "q2plus",
                "capability_status": "rejected_by_design",
                "work_status": "deferred",
                "evidence_tier": "none",
                "tranche_id": "lane-c-c14-leaf-taxonomy",
                "owner": "Lane C",
                "blocking_reviewers": "Noether; Fisher; Rose",
                "primary_evidence_id": q2_evidence_id,
                "claim_boundary": q2_boundary,
                "next_gate": (
                    "A separately approved exact q2-plus target, implementation, "
                    "oracle, and recovery programme is required."
                ),
                "updated_commit": sha,
                "updated_date": "2026-07-31",
                "notes": "C14 non-lossy q2-plus boundary paired with " + original_id + ".",
            })
            cells.append(boundary)
            by_id[boundary_id] = boundary
        if q2_evidence_id not in evidence_ids:
            evidence.append({
                "evidence_id": q2_evidence_id,
                "cell_id": boundary_id,
                "evidence_class": "contract_test",
                "path_or_url": C14_ZOB_LEAF_TAXONOMY_SOURCE,
                "commit_sha": sha,
                "run_id": "c14-zob-structured-q2plus-boundary",
                "command": "python3 tools/capability_ledger.py --split-c14-zob-structured-leaves",
                "result": "q2plus_deferred",
                "replicates": "",
                "reviewed_by": "C14 taxonomy reconciliation",
                "review_date": "2026-07-31",
                "claim_boundary": q2_boundary,
            })
        if q2_transition_id not in transition_ids:
            transitions.append({
                "transition_id": q2_transition_id,
                "cell_id": boundary_id,
                "from_work_status": "",
                "to_work_status": "deferred",
                "evidence_ids": q2_evidence_id,
                "reason": "C14 non-lossy q2-plus boundary created beside a q1 leaf.",
                "actor": "Codex C14 leaf taxonomy",
                "commit_sha": sha,
                "date": "2026-07-31",
            })

    CELLS.write_bytes(tsv_bytes(CELL_FIELDS, cells))
    EVIDENCE.write_bytes(tsv_bytes(EVIDENCE_FIELDS, evidence))
    TRANSITIONS.write_bytes(tsv_bytes(TRANSITION_FIELDS, transitions))
    SCHEMA.write_bytes(json_bytes(schema_value()))
    print("C14 zero-one-beta structured q1/q2-plus leaves are current")


def check_c14_receipt_equivalence() -> None:
    """Verify C14's separate source-equivalence bridge for retained receipts.

    Raw all-attempt receipt SHA values are immutable and remain their original
    values. The source fingerprints were computed from those immutable
    revisions during the local C14 audit. This check proves that the current
    target matches the committed target fingerprint and is equal to (or
    distinct from) the recorded execution source as declared. It never
    promotes a cell or replaces the required independent completion review.
    """
    rows = read_tsv(C14_RECEIPT_EQUIVALENCE)
    expected_ids = {
        "mc-0568", "mc-0569", "mc-0576", "mc-0586", "mc-0587",
        "mc-0593", "mc-0594", "mc-0595", "mc-0596", "mc-0597",
    }
    ids = {row["cell_id"] for row in rows}
    if ids != expected_ids or len(rows) != len(expected_ids):
        raise SystemExit("C14 receipt-equivalence manifest does not name exactly ten cells")
    current_fingerprint = c14_model15_source_fingerprint()
    c17_bridge = current_fingerprint != C14_RECEIPT_EQUIVALENCE_FINGERPRINT
    if c17_bridge:
        check_c17_c14_current_source_compatibility(current_fingerprint)
    eligible_ids = set()
    for row in rows:
        if row["c14_target_sha"] != C14_RECEIPT_EQUIVALENCE_TARGET:
            raise SystemExit(f"{row['cell_id']}: wrong C14 equivalence target")
        if row["compared_paths"] != ";".join(C14_RECEIPT_EQUIVALENCE_PATHS):
            raise SystemExit(f"{row['cell_id']}: wrong C14 equivalence path set")
        raw_path = ROOT / row["raw_attempts_path"]
        if not raw_path.is_file():
            raise SystemExit(f"{row['cell_id']}: raw attempts receipt is unavailable")
        raw_rows = read_tsv(raw_path)
        raw_shas = {raw_row.get("source_sha", "") for raw_row in raw_rows}
        if not raw_rows or raw_shas != {row["retained_source_sha"]}:
            raise SystemExit(
                f"{row['cell_id']}: manifest SHA does not match its raw attempts receipt"
            )
        if row["target_fingerprint"] != C14_RECEIPT_EQUIVALENCE_FINGERPRINT:
            raise SystemExit(f"{row['cell_id']}: immutable C14 target fingerprint differs")
        eligible = row["equivalence_eligible"] == "TRUE"
        source_matches = row["source_fingerprint"] == row["target_fingerprint"]
        if eligible and not source_matches:
            raise SystemExit(f"{row['cell_id']}: eligible source fingerprint differs")
        if not eligible and source_matches:
            raise SystemExit(
                f"{row['cell_id']}: ineligible receipt unexpectedly matches the C14 target"
            )
        if eligible:
            eligible_ids.add(row["cell_id"])
    if eligible_ids != {"mc-0568", "mc-0569", "mc-0576"}:
        raise SystemExit("C14 receipt equivalence has an unexpected eligible cell set")
    print(
        f"C14 receipt equivalence: OK ({len(eligible_ids)} eligible, "
        f"{len(rows) - len(eligible_ids)} source-different retained receipts"
        + ("; C17 current-source compatibility PASS" if c17_bridge else "")
        + ")"
    )


def check_c17_c14_current_source_compatibility(
    current_fingerprint: str,
) -> None:
    """Authenticate C17's narrow current-source bridge for C14 receipts.

    The historical C14 target and raw receipts stay immutable. This bridge
    accepts only the separately authenticated latest C17 model-15 fingerprint and
    only when all retained attempts for the three previously promoted ordinary
    routes pass with the new ``coi`` carrier inert.
    """
    rows = read_tsv(C17_C14_CURRENT_SOURCE_COMPATIBILITY)
    expected_ids = set(C17_C14_COMPATIBLE_SEEDS)
    if len(rows) != len(expected_ids) or {row["cell_id"] for row in rows} != expected_ids:
        raise SystemExit(
            "C17 compatibility manifest must name exactly mc-0568, "
            "mc-0569, and mc-0576"
        )

    expected_paths = ";".join(C14_RECEIPT_EQUIVALENCE_PATHS)
    expected_source_files = ";".join(C17_C14_SOURCE_FILES)
    runner_path = ROOT / C17_C14_SOURCE_FILES[-1]
    runner_hash = hashlib.sha256(runner_path.read_bytes()).hexdigest()

    for row in rows:
        cell_id = row["cell_id"]
        if row["compared_paths"] != expected_paths:
            raise SystemExit(f"{cell_id}: wrong C17 compatibility path set")
        if row["source_fingerprint"] != current_fingerprint:
            raise SystemExit(f"{cell_id}: current model-15 fingerprint differs")
        if row["source_files"] != expected_source_files:
            raise SystemExit(f"{cell_id}: wrong C17 authenticated source-file set")
        if (
            row["attempts"] != "4"
            or row["passed"] != "4"
            or row["compatibility_result"] != "PASS_CURRENT_SOURCE_COMPATIBILITY"
        ):
            raise SystemExit(f"{cell_id}: current-source compatibility did not pass 4/4")
        if runner_hash != row["runner_sha256"]:
            raise SystemExit(f"{cell_id}: committed compatibility runner differs")

        raw_path = ROOT / row["raw_attempts_path"]
        provenance_path = ROOT / row["provenance_path"]
        summary_path = ROOT / row["summary_path"]
        if not all(path.is_file() for path in (raw_path, provenance_path, summary_path)):
            raise SystemExit(f"{cell_id}: C17 compatibility receipt is unavailable")

        provenance = {
            item["key"]: item["value"] for item in read_tsv(provenance_path)
        }
        if provenance.get("run_status") != "COMPLETE":
            raise SystemExit(f"{cell_id}: C17 compatibility run is incomplete")
        if provenance.get("source_sha") != row["current_source_sha"]:
            raise SystemExit(f"{cell_id}: compatibility source SHA differs")
        if provenance.get("runner_sha256") != row["runner_sha256"]:
            raise SystemExit(f"{cell_id}: compatibility runner hash differs")
        for source_file in C17_C14_SOURCE_FILES:
            blob = subprocess.run(
                ["git", "hash-object", source_file],
                cwd=ROOT,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            if provenance.get(f"git_blob:{source_file}") != blob:
                raise SystemExit(f"{cell_id}: current source blob differs for {source_file}")

        raw_rows = [
            item for item in read_tsv(raw_path) if item["cell_id"] == cell_id
        ]
        if (
            len(raw_rows) != 4
            or {item["seed"] for item in raw_rows}
            != C17_C14_COMPATIBLE_SEEDS[cell_id]
        ):
            raise SystemExit(f"{cell_id}: compatibility seed set differs")
        for attempt in raw_rows:
            passed = (
                attempt["source_sha"] == row["current_source_sha"]
                and attempt["runner_sha256"] == row["runner_sha256"]
                and attempt["status"] == "fit_ok"
                and attempt["convergence"] == "0"
                and attempt["pdHess"] == "TRUE"
                and float(attempt["max_gradient"]) <= 0.01
                and attempt["boundary_hit"] == "FALSE"
                and attempt["support_gate"] == "TRUE"
                and float(attempt["mode_correlation"]) > 0.45
                and attempt["n_coi_re_terms"] == "0"
                and attempt["error"] == "none"
            )
            if not passed:
                raise SystemExit(f"{cell_id}: a compatibility attempt fails its contract")

        summary = [
            item for item in read_tsv(summary_path) if item["cell_id"] == cell_id
        ]
        if (
            len(summary) != 1
            or summary[0]["attempts"] != "4"
            or summary[0]["passed"] != "4"
            or summary[0]["decision"] != "PASS_CURRENT_SOURCE_COMPATIBILITY"
            or float(summary[0]["mean_tau_relative_error"]) > 0.40
        ):
            raise SystemExit(f"{cell_id}: compatibility summary does not pass")


def c14_model15_source_fingerprint() -> str:
    """Hash the closed model-15 surface governing C14's ZOB receipts.

    A model-9 ZINB routing repair must not invalidate a model-15 zero-one-beta
    receipt.  Each named source anchor below is therefore part of this hash;
    changing a builder, carrier, extractor, or the model-15 likelihood changes
    it, while unrelated family code does not.
    """
    r_source = (ROOT / "R/drmTMB.R").read_text(encoding="utf-8")
    cpp_source = (ROOT / "src/drmTMB.cpp").read_text(encoding="utf-8")

    # C17-B widens only the missing-response diagnostic so it names the already
    # fitted same-symbol zoi slope. Missing responses remain rejected before a
    # likelihood object is built, so this prose-only abort must not invalidate
    # C14's immutable fit-source equivalence receipts. Normalize that one abort
    # block to its C14 wording before hashing; all builder/carrier/extractor and
    # model-15 likelihood bytes remain fingerprinted exactly.
    c17_diagnostic = '''  if (include_missing_response && length(zoi_re$terms) > 0L) {
    cli::cli_abort(c(
      "The zero-one-beta zoi q1 random-effect gate does not support missing responses.",
      "i" = "Use complete observed responses with either {.code zoi ~ 1 + (1 | id)} or the same-raw-symbol slope form {.code zoi ~ x + (0 + x | id)}."
    ))
  }
'''
    c14_diagnostic = '''  if (include_missing_response && length(zoi_re$terms) > 0L) {
    cli::cli_abort(c(
      "The zero-one-beta zoi random-intercept q1 gate does not support missing responses.",
      "i" = "Use complete observed responses for {.code bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1)}."
    ))
  }
'''
    if c17_diagnostic not in r_source:
        raise SystemExit("C17-B diagnostic normalization anchor is unavailable")
    r_source = r_source.replace(c17_diagnostic, c14_diagnostic, 1)

    def section(source: str, start: str, end: str, label: str) -> str:
        start_index = source.find(start)
        if start_index < 0:
            raise SystemExit(f"C14 equivalence anchor is unavailable: {label}")
        end_index = source.find(end, start_index)
        if end_index < 0:
            raise SystemExit(f"C14 equivalence endpoint is unavailable: {label}")
        return source[start_index:end_index]

    sections = (
        section(
            r_source,
            "drm_build_zero_one_beta_spec <- function(",
            "drm_build_beta_binomial_spec <- function(",
            C14_RECEIPT_EQUIVALENCE_PATHS[0],
        ),
        section(
            r_source,
            "zero_one_beta_start <- function(",
            "poisson_start <- function(",
            C14_RECEIPT_EQUIVALENCE_PATHS[1],
        ),
        section(
            r_source,
            "zero_one_beta_atom_tmb_data <- function(",
            "# TMB data for the scoped second structured location field",
            C14_RECEIPT_EQUIVALENCE_PATHS[2],
        )
        + section(
            r_source,
            "split_tmb_sdpars <- function(",
            "split_tmb_corpars <- function(",
            C14_RECEIPT_EQUIVALENCE_PATHS[2],
        )
        + section(
            r_source,
            "split_tmb_random_effects <- function(",
            "sd_mu_group_values <- function(",
            C14_RECEIPT_EQUIVALENCE_PATHS[2],
        ),
        section(
            cpp_source,
            "  } else if (model_type == 15) {",
            "  } else if (model_type == 14) {",
            C14_RECEIPT_EQUIVALENCE_PATHS[3],
        ),
    )
    fingerprint = hashlib.sha256()
    for label, source in zip(C14_RECEIPT_EQUIVALENCE_PATHS, sections):
        fingerprint.update(label.encode())
        fingerprint.update(b"\\0")
        fingerprint.update(source.encode())
        fingerprint.update(b"\\0")
    return fingerprint.hexdigest()


def source_path_exists(value: str) -> bool:
    if not value or value.startswith(("http://", "https://")):
        return True
    first = value.split(";", 1)[0].strip()
    candidate = first.split(":", 1)[0]
    return (ROOT / candidate).exists()


def validate(
    cells: list[dict[str, str]],
    evidence: list[dict[str, str]],
    transitions: list[dict[str, str]],
) -> None:
    errors: list[str] = []
    if list(cells[0]) != CELL_FIELDS:
        errors.append("cells.tsv header does not match schema")
    if evidence and list(evidence[0]) != EVIDENCE_FIELDS:
        errors.append("evidence.tsv header does not match schema")
    if transitions and list(transitions[0]) != TRANSITION_FIELDS:
        errors.append("transitions.tsv header does not match schema")

    ids = [row["cell_id"] for row in cells]
    if len(ids) != len(set(ids)):
        errors.append("cell_id values are not unique")
    evidence_ids = [row["evidence_id"] for row in evidence]
    if len(evidence_ids) != len(set(evidence_ids)):
        errors.append("evidence_id values are not unique")
    transition_ids = [row["transition_id"] for row in transitions]
    if len(transition_ids) != len(set(transition_ids)):
        errors.append("transition_id values are not unique")

    by_axis = Counter(row["axis"] for row in cells)
    if by_axis != Counter({
        "model_surface": MODEL_SURFACE_COUNT,
        "missing_response": 18,
        "association": ASSOCIATION_COUNT,
    }):
        errors.append(
            f"axis counts are {dict(by_axis)}, expected "
            f"{MODEL_SURFACE_COUNT} model + 18 missing-response + "
            f"{ASSOCIATION_COUNT} association"
        )
    route_names = {row["family_route"] for row in cells if row["axis"] == "missing_response"}
    if route_names != {route for _, route, _, _, _ in ROUTES}:
        errors.append("missing_response route set does not match the 18-route contract")

    cell_ids = set(ids)
    evidence_id_set = set(evidence_ids)
    evidence_by_id = {row["evidence_id"]: row for row in evidence}
    for row in cells:
        if row["capability_status"] not in CAPABILITY_STATUSES:
            errors.append(f"{row['cell_id']}: invalid capability_status")
        if row["work_status"] not in WORK_STATUSES:
            errors.append(f"{row['cell_id']}: invalid work_status")
        if row["test_gate"] not in TEST_GATES:
            errors.append(f"{row['cell_id']}: invalid test_gate")
        if row["evidence_tier"] not in EVIDENCE_TIERS:
            errors.append(f"{row['cell_id']}: invalid evidence_tier")
        if not row["claim_boundary"] or not row["next_gate"]:
            errors.append(f"{row['cell_id']}: claim_boundary and next_gate are required")
        primary = row["primary_evidence_id"]
        if primary and primary not in evidence_id_set:
            errors.append(f"{row['cell_id']}: missing primary evidence {primary}")
        elif primary and evidence_by_id[primary]["cell_id"] != row["cell_id"]:
            errors.append(
                f"{row['cell_id']}: primary evidence {primary} belongs to "
                f"{evidence_by_id[primary]['cell_id']}"
            )

    # The model-cell ledger feeds the public capability surface. Keep the eight
    # conceptual inference-ready configurations (ten endpoint-level ledger
    # rows) explicit about their two distinct interval channels so generic
    # historical "Wald" wording cannot erase the correction or apply it to
    # the sigma axis.
    by_id = {row["cell_id"]: row for row in cells}
    location_bias_t_ids = {
        "mc-0085", "mc-0086", "mc-0153", "mc-0154",
        "mc-0272", "mc-0285", "mc-0309",
    }
    sigma_raw_wald_ids = {"mc-0276", "mc-0301", "mc-0313"}
    for cell_id in sorted(location_bias_t_ids):
        boundary = by_id[cell_id]["claim_boundary"]
        for required in (
            "location-axis bias-corrected small-sample-t Wald",
            "inference-ready with caveats",
            "not nominal",
        ):
            if required not in boundary:
                errors.append(
                    f"{cell_id}: location-axis interval boundary omits {required!r}"
                )
    for cell_id in sorted(sigma_raw_wald_ids):
        boundary = by_id[cell_id]["claim_boundary"]
        for required in (
            "raw uncorrected log-SD Wald-z",
            "location-axis bias+t correction does not apply to sigma",
            "profile is diagnostic-only at g=8",
            "inference-ready with caveats",
            "not supported",
        ):
            if required not in boundary:
                errors.append(
                    f"{cell_id}: sigma interval boundary omits {required!r}"
                )

    for row in evidence:
        if row["cell_id"] not in cell_ids:
            errors.append(f"{row['evidence_id']}: unknown cell_id")
        if row["evidence_class"] not in EVIDENCE_CLASSES:
            errors.append(
                f"{row['evidence_id']}: invalid evidence_class "
                f"{row['evidence_class']!r}"
            )
        if row["evidence_class"] == "external_comparator":
            # Rendering matches package names against a fixed tuple, so a comparator
            # nobody registered there would silently render a BLANK badge -- the row
            # would look like no comparator exists. Fail loudly instead: an
            # unregistered package must be added to COMPARATOR_PACKAGES to be recorded.
            named = f"{row['run_id']} {row['result']}"
            if not any(pkg in named for pkg in COMPARATOR_PACKAGES):
                errors.append(
                    f"{row['evidence_id']}: run_id/result names no package from "
                    "COMPARATOR_PACKAGES; register it there or the badge renders blank"
                )
            boundary = row["claim_boundary"].upper()
            if not (
                "STRONG INDEPENDENCE" in boundary or "WEAK INDEPENDENCE" in boundary
            ):
                errors.append(
                    f"{row['evidence_id']}: claim_boundary must declare STRONG "
                    "INDEPENDENCE or WEAK INDEPENDENCE"
                )
        # The frozen 2026-07-09 census contains historical cell names and
        # semicolon-packed provenance as well as paths. Preserve those verbatim
        # during MR-T0; require resolvable paths for every new evidence record.
        if (
            row["evidence_class"] != "legacy_model_evidence"
            and not source_path_exists(row["path_or_url"])
        ):
            errors.append(f"{row['evidence_id']}: unresolved path {row['path_or_url']}")
    for row in transitions:
        if row["cell_id"] not in cell_ids:
            errors.append(f"{row['transition_id']}: unknown cell_id")
        if row["to_work_status"] not in WORK_STATUSES:
            errors.append(f"{row['transition_id']}: invalid target work status")
        for evidence_id in filter(None, row["evidence_ids"].split(";")):
            if evidence_id not in evidence_id_set:
                errors.append(f"{row['transition_id']}: unknown evidence {evidence_id}")

    model = [row for row in cells if row["axis"] == "model_surface"]
    status_counts = Counter(row["capability_status"] for row in model)
    # C14 restores the 330 source-pinned package boundaries and then splits ten
    # lossy structured zero-one-beta representatives into q1 and q2-plus leaves.
    # C16 independently promotes ten exact q1 structured zero-one-beta leaves
    # after source-bound recovery and fresh three-lens GO. C17-B promotes the
    # exact ordinary zero-one-beta zoi same-symbol q1 slope after authenticated
    # recovery and fresh Fisher/Noether/Rose GO. C17-C1 promotes the exact coi
    # q1 random intercept with a documented sparse-atom conditional-mode warning.
    # C17-C2 promotes the exact coi same-raw-symbol q1 random slope while retaining
    # weak boundary-row predictor spread as a conditional-mode warning. The remaining 17 rows
    # are the actionable implementation backlog, not a claim that every
    # boundary is mathematically impossible.
    expected = Counter(
        {
            "implemented": 330,
            "rejected_by_design": C14_BOUNDARY_COUNT + len(C14_ZOB_LEAF_TAXONOMY),
            "not_implemented": 17,
        }
    )
    if status_counts != expected:
        errors.append(f"model status counts changed: {dict(status_counts)}")

    # The frozen census has 127 point_fit_recovery cells after the exact
    # ten-leaf promotion, B3's exact four q6 mu2 target promotions, C17-B's
    # exact zero-one-beta zoi same-symbol q1 slope promotion, C1's exact
    # 24-cell promotion, C2's exact 25-cell promotion to interval feasible,
    # C17-C1's exact zero-one-beta coi q1 random-intercept promotion, and
    # C17-C2's exact same-raw-symbol coi q1 random-slope promotion.
    # Approved inserts take a higher source_order and so cannot disturb this
    # number; every frozen-cell promotion needs a named
    # transition and evidence receipt.
    frozen = [row for row in model if int(row["source_order"]) <= FROZEN_CENSUS_COUNT]
    if len(frozen) != FROZEN_CENSUS_COUNT:
        errors.append(
            f"frozen census size changed: {len(frozen)} (expected {FROZEN_CENSUS_COUNT})"
        )
    frozen_recovery = sum(
        row["evidence_tier"] == "point_fit_recovery" for row in frozen
    )
    if frozen_recovery != FROZEN_CENSUS_POINT_FIT_RECOVERY:
        errors.append(
            f"frozen census point_fit_recovery changed: {frozen_recovery} "
            f"(expected {FROZEN_CENSUS_POINT_FIT_RECOVERY}); a frozen cell was promoted "
            "or demoted"
        )

    by_cell = {row["cell_id"]: row for row in cells}
    b3_observed = {
        row["cell_id"]
        for row in model
        if row["q_gate"] == "q6"
        and row["dpar"] == "mu2"
        and row["effect_type"] == "structured"
        and row["estimator"] == "ML"
        and row["evidence_tier"] == "interval_feasible"
    }
    if b3_observed != set(B3_Q6_MU2_TARGETS):
        errors.append(
            "B3 q6 mu2 interval-feasible allowlist changed: "
            f"{sorted(b3_observed)}"
        )
    b3_latest_transition = {
        row["cell_id"]: row for row in transitions
    }
    for cell_id, (provider, paired_mu1, target_id) in B3_Q6_MU2_TARGETS.items():
        cell = by_cell.get(cell_id, {})
        evidence_id = f"ev-{cell_id}-b3-q6-mu2-interval"
        evidence_row = evidence_by_id.get(evidence_id, {})
        expected_receipt = (
            "docs/dev-log/interval-feasibility/results/"
            f"{B3_Q6_MU2_RUNNER_SHA}/b2-q6-proof-profile/{cell_id}/"
            f"b2-q6-proof-{cell_id}-high-seed-20260731-receipt.tsv"
        )
        if (
            cell.get("structure_provider") != provider
            or cell.get("family_route") != "biv_gaussian"
            or cell.get("dpar") != "mu2"
            or cell.get("q_gate") != "q6"
            or cell.get("estimator") != "ML"
            or cell.get("capability_status") != "implemented"
            or cell.get("work_status") != "verified"
            or cell.get("evidence_tier") != "interval_feasible"
            or cell.get("primary_evidence_id") != evidence_id
        ):
            errors.append(f"{cell_id}: B3 canonical target row changed")
        if by_cell.get(paired_mu1, {}).get("evidence_tier") != "point_fit_recovery":
            errors.append(f"{paired_mu1}: paired mu1 row inherited B3 target promotion")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "estimator_diagnostic"
            or evidence_row.get("path_or_url") != expected_receipt
            or evidence_row.get("commit_sha") != B3_Q6_MU2_RUNNER_SHA
            or evidence_row.get("result") != "interval_feasible"
        ):
            errors.append(f"{evidence_id}: B3 evidence binding changed")
        if target_id not in B3_Q6_MU2_PACKET.read_text(encoding="utf-8"):
            errors.append(f"{cell_id}: exact direct target missing from B3 packet")
        transition = b3_latest_transition.get(cell_id, {})
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: B3 transition must remain verified-to-verified")

    missing = {row["family_route"]: row for row in cells if row["axis"] == "missing_response"}
    for route, row in missing.items():
        gate = int(row["test_gate"][1:])
        if row["capability_status"] == "implemented" and gate < 1:
            errors.append(f"{route}: implemented capability requires G1 or higher")
        if row["capability_status"] != "implemented" and gate > 0:
            errors.append(f"{route}: G1+ requires implemented capability")
        if row["work_status"] == "verified" and gate < 3:
            errors.append(f"{route}: verified work status requires G3 or higher")
        if gate >= 3 and row["work_status"] != "verified":
            errors.append(f"{route}: G3+ evidence must display verified work status")

    latest_transition = {}
    for row in transitions:
        latest_transition[row["cell_id"]] = row
    for cell in cells:
        transition = latest_transition.get(cell["cell_id"])
        if transition and transition["to_work_status"] != cell["work_status"]:
            errors.append(
                f"{cell['cell_id']}: current work status does not match latest transition"
            )

    evidence_by_cell: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in evidence:
        evidence_by_cell[row["cell_id"]].append(row)
    for route, cell in missing.items():
        gate = int(cell["test_gate"][1:])
        if gate < 2:
            continue
        cell_evidence = evidence_by_cell[cell["cell_id"]]
        g2_ids = {
            row["evidence_id"]
            for row in cell_evidence
            if row["evidence_class"] == "g2_contract_test"
            and row["result"] == "G2_pass"
        }
        if not g2_ids:
            errors.append(f"{route}: G2+ requires passing same-cell G2 contract evidence")
        recovery_ids = {
            row["evidence_id"]
            for row in cell_evidence
            if row["evidence_class"] == "recovery_test"
            and row["result"] == "G3_pass"
        }
        if gate >= 3 and not recovery_ids:
            errors.append(f"{route}: G3+ requires passing same-cell recovery evidence")
        primary = evidence_by_id.get(cell["primary_evidence_id"])
        if gate >= 3 and primary and (
            primary["evidence_class"] != "recovery_test"
            or primary["result"] != "G3_pass"
        ):
            errors.append(f"{route}: G3+ primary evidence must be a passing recovery test")
        transition = latest_transition.get(cell["cell_id"])
        transition_evidence = set(
            filter(None, transition["evidence_ids"].split(";"))
        ) if transition else set()
        if not transition or not (transition_evidence & g2_ids):
            errors.append(f"{route}: latest G2+ transition must cite G2 contract evidence")
        if gate >= 3 and (
            not transition or not (transition_evidence & recovery_ids)
        ):
            errors.append(f"{route}: latest G3+ transition must cite recovery evidence")

    if errors:
        raise SystemExit("Capability ledger validation failed:\n- " + "\n- ".join(errors))


def model_projection(
    cells: list[dict[str, str]], evidence: list[dict[str, str]]
) -> list[dict[str, str]]:
    evidence_by_id = {row["evidence_id"]: row for row in evidence}
    rows = sorted(
        (row for row in cells if row["axis"] == "model_surface"),
        key=lambda row: int(row["source_order"]),
    )
    return [{
        "family": row["family_route"],
        "model_type": row["model_type"],
        "dpar": row["dpar"],
        "effect_type": row["effect_type"],
        "structure_provider": row["structure_provider"],
        "dimension": row["dimension"],
        "q_gate": row["q_gate"],
        "estimator": row["estimator"],
        "status": row["capability_status"],
        "planning_class": planning_class(row),
        "evidence_tier": row["evidence_tier"],
        "evidence_source": (
            evidence_by_id[row["primary_evidence_id"]]["path_or_url"]
            if row["primary_evidence_id"]
            else row["legacy_evidence_source"]
        ),
        "notes": row["claim_boundary"] or row["notes"],
    } for row in rows]


def planning_class(row: dict[str, str]) -> str:
    """Return a visible scope class without treating an unimplemented cell as impossible.

    It is a planning cue, not an effort estimate or an inference claim. REML is
    a restricted-likelihood objective; an ML fit does not automatically supply it.
    """
    if row["capability_status"] == "implemented":
        return "available"
    if row["estimator"] in {"REML", "AI-REML"}:
        return "estimator method"
    if row["effect_type"] == "structured":
        return "covariance / model method"
    return "admission candidate"


def widget_value(
    model: list[dict[str, str]], generated_date: str
) -> dict[str, object]:
    tiers = [
        "supported", "inference_ready_with_caveats", "interval_feasible",
        "diagnostic_only", "point_fit_recovery", "none", "miswired",
    ]
    families = sorted({row["family"] for row in model})
    matrix = {
        family: {tier: 0 for tier in tiers}
        for family in families
    }
    for row in model:
        if row["status"] == "implemented":
            matrix[row["family"]][row["evidence_tier"]] += 1
    status_counts = Counter(row["status"] for row in model)
    tier_counts = Counter(
        row["evidence_tier"] for row in model if row["status"] == "implemented"
    )
    return {
        "generated": generated_date,
        "rows": [
            {key: row[key] for key in (
                "family", "dpar", "effect_type", "structure_provider",
                "dimension", "q_gate", "estimator", "status", "planning_class", "evidence_tier",
            )}
            for row in model
        ],
        "families": families,
        "tiers": tiers,
        "matrix": matrix,
        "status_counts": dict(status_counts),
        "tier_counts": dict(tier_counts),
        "total": len(model),
    }


def missing_next_gate(row: dict[str, str]) -> str:
    """Return current reader-facing next-step wording for a missing-response row."""
    if row["next_gate"] == "G4/G5 interval and coverage evidence are outside this arc.":
        return (
            "G4/G5 framework is ready and partial calibration evidence is retained; "
            "all routes remain G3 because the campaign stopped before route-wide "
            "reconciliation and promotion review."
        )
    return row["next_gate"]


def missing_g4g5_summary() -> str:
    """Return the current, target-rung-grain missing-response evidence summary."""
    return (
        "G4 framework ready for all 18 routes: 295 of 306 frozen target-rung "
        "records are feasible and 11 ineligible records are retained. G5 has "
        "eight reconciled cohorts: 98 of 130 exact cells pass and 32 fail; "
        "binomial is 6/6. This is target-rung calibration evidence, not a "
        "route-wide G5 or model-inference promotion."
    )


MISSING_G5_ROUTE_SUMMARIES = {
    "gaussian": "G5: 51/54 passing cells in the combined Gaussian cohort",
    "biv_gaussian": "G5: 51/54 passing cells in the combined Gaussian cohort",
    "binomial": "G5: 6/6 cells pass",
    "poisson": "G5: 5/9 cells pass; 4 retained failures",
    "nbinom2": "G5: 10/15 cells pass; 5 retained failures",
    "student": "G5: 3/16 cells pass; 13 retained failures",
    "lognormal": "G5: 11/15 cells pass; 4 retained failures",
    "gamma": "G5: 12/15 cells pass; 3 retained failures",
    "beta": "G5: cancelled after 2 unreconciled receipts",
}


def missing_route_g4g5_summary(route: str) -> str:
    """Return a scoped, non-promotional G4/G5 line for a route-table cell."""
    g5 = MISSING_G5_ROUTE_SUMMARIES.get(route, "G5: not run")
    return f"G4: framework ready; {g5}"


def missing_markdown(missing: list[dict[str, str]], compact: bool = False) -> str:
    lines = [
        "| Route | Runtime state | Evidence gate | Work state | Next gate |",
        "|---|---|---:|---|---|",
    ]
    for row in missing:
        runtime = "implemented" if row["capability_status"] == "implemented" else "rejected"
        verified = " ✓" if int(row["test_gate"][1:]) >= 3 else ""
        lines.append(
            f"| `{row['family_route']}` | {runtime} | {row['test_gate']}{verified} | "
            f"{row['work_status'].replace('_', ' ')} | {missing_next_gate(row)} |"
        )
    if compact:
        lines.extend([
            "",
            "A ✓ appears only at G3 recovery or above. Missing-response evidence does "
            "not change the model's separate inference tier.",
        ])
    return "\n".join(lines) + "\n"


def ledger_updated_date(cells: list[dict[str, str]]) -> str:
    """Return the newest ISO date present in the authoritative ledger."""
    dates = {row["updated_date"] for row in cells if row.get("updated_date")}
    invalid = sorted(date for date in dates if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", date))
    if invalid:
        raise SystemExit(f"Invalid ledger updated_date value(s): {', '.join(invalid)}")
    if not dates:
        raise SystemExit("Capability ledger has no updated_date values")
    return max(dates)


def runtime_missing_predictor_families() -> set[str]:
    """Read the fitted-family allow-list from the R runtime's SSOT helper."""
    source = (ROOT / "R/missing-data.R").read_text(encoding="utf-8")
    match = re.search(
        r"drm_missing_predictor_families\s*<-\s*function\(\)\s*\{\s*c\((.*?)\)\s*\}",
        source,
        flags=re.DOTALL,
    )
    if not match:
        raise SystemExit("Cannot read drm_missing_predictor_families() runtime gate")
    families = set(re.findall(r'["\']([^"\']+)["\']', match.group(1)))
    if not families:
        raise SystemExit("drm_missing_predictor_families() runtime gate is empty")
    return families


def validate_missing_predictor_runtime_map() -> set[str]:
    """Validate route-to-family routing, then return the live R allow-list."""
    expected = {route: family_type for _, route, family_type, _, _ in ROUTES}
    if MISSING_PREDICTOR_RUNTIME_GATE != expected:
        raise SystemExit(
            "MISSING_PREDICTOR_RUNTIME_GATE does not match the fitted route contract"
        )
    runtime = runtime_missing_predictor_families()
    unknown = runtime - set(expected.values())
    if unknown:
        raise SystemExit(
            "R missing-predictor runtime gate names unknown family type(s): "
            + ", ".join(sorted(unknown))
        )
    return runtime


def _aggregate_state(rows: list[dict[str, str]]) -> str:
    """Aggregate cells without turning absence into rejection."""
    if not rows:
        return "absent"
    counts = Counter(row["capability_status"] for row in rows)
    labels = {
        "implemented": "implemented",
        "not_implemented": "not implemented",
        "rejected_by_design": "not currently supported",
        "scaffolded": "scaffolded",
    }
    if len(counts) == 1:
        return labels[next(iter(counts))]
    details = "; ".join(
        f"{labels[status]} {counts[status]}"
        for status in (
            "implemented", "not_implemented", "rejected_by_design", "scaffolded"
        )
        if counts[status]
    )
    prefix = "scope-limited" if counts["implemented"] else "mixed"
    return f"{prefix} ({details})"


def _dpar_order(rows: list[dict[str, str]]) -> list[str]:
    first_seen: dict[str, int] = {}
    for row in rows:
        first_seen.setdefault(row["dpar"], int(row["source_order"]))
    return sorted(first_seen, key=first_seen.get)


def _effect_summary(
    rows: list[dict[str, str]], dpars: list[str], effect_type: str
) -> str:
    pieces = []
    for dpar in dpars:
        selected = [
            row for row in rows
            if row["dpar"] == dpar and row["effect_type"] == effect_type
        ]
        pieces.append(f"`{dpar}`: {_aggregate_state(selected)}")
    return "; ".join(pieces)


def _ordinary_summary(rows: list[dict[str, str]], dpars: list[str]) -> str:
    pieces = []
    for dpar in dpars:
        intercept = [
            row for row in rows
            if row["dpar"] == dpar and row["effect_type"] == "ordinary_re_intercept"
        ]
        slope = [
            row for row in rows
            if row["dpar"] == dpar and row["effect_type"] == "ordinary_re_slope"
        ]
        pieces.append(
            f"`{dpar}`: int {_aggregate_state(intercept)} / "
            f"slope {_aggregate_state(slope)}"
        )
    return "; ".join(pieces)


def _structured_summary(rows: list[dict[str, str]], dpars: list[str]) -> str:
    pieces = []
    for dpar in dpars:
        providers = []
        for provider in STRUCTURED_PROVIDERS:
            selected = [
                row for row in rows
                if row["dpar"] == dpar
                and row["effect_type"] == "structured"
                and row["structure_provider"] == provider
            ]
            providers.append(f"{provider}={_aggregate_state(selected)}")
        pieces.append(f"`{dpar}`: " + ", ".join(providers))
    return "; ".join(pieces)


def _evidence_summary(rows: list[dict[str, str]]) -> tuple[str, str]:
    implemented = [row for row in rows if row["capability_status"] == "implemented"]
    available = {row["evidence_tier"] for row in implemented}
    highest = next((tier for tier in TIER_ORDER if tier in available), "none")
    scoped = sorted(
        (row for row in implemented if row["evidence_tier"] == highest),
        key=lambda row: int(row["source_order"]),
    )
    if not scoped:
        return highest, f"**{highest}** — no implemented cell at this tier"
    scopes = "; ".join(
        "`{cell}` ({dpar}; {effect}; provider={provider}; estimator={estimator}; "
        "dimension={dimension}; q={q}; variant={variant})".format(
            cell=row["cell_id"],
            dpar=row["dpar"],
            effect=row["effect_type"],
            provider=row["structure_provider"],
            estimator=row["estimator"],
            dimension=row["dimension"],
            q=row["q_gate"],
            variant=row["route_variant"],
        )
        for row in scoped
    )
    return highest, f"**{highest}** — {scopes}"


def _missing_predictor_summary(route: str, runtime: set[str]) -> str:
    family_type = MISSING_PREDICTOR_RUNTIME_GATE[route]
    if family_type not in runtime:
        return f"rejected by runtime gate (`{family_type}` response)"
    if family_type == "gaussian":
        return "implemented: broad predictor-family catalogue"
    inherited = "" if route == family_type else f" via `{family_type}` family-type gate"
    return f"implemented: one binary missing predictor{inherited}"


def family_map_rows(cells: list[dict[str, str]]) -> list[dict[str, str]]:
    """Project the per-family reference exclusively from live ledger cells."""
    runtime = validate_missing_predictor_runtime_map()
    model = [row for row in cells if row["axis"] == "model_surface"]
    by_route: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in model:
        by_route[row["family_route"]].append(row)

    rows = []
    for _, route, _, _, _ in ROUTES:
        route_rows = by_route.get(route, [])
        if not route_rows:
            raise SystemExit(f"No live model-surface cells for route {route}")
        dpars = _dpar_order(route_rows)
        ml = [row for row in route_rows if row["estimator"] == "ML"]
        reml = [row for row in route_rows if row["estimator"] == "REML"]
        highest, evidence = _evidence_summary(route_rows)
        rows.append({
            "family_route": route,
            "Response": f"**{route}**",
            "dpars": ", ".join(f"`{dpar}`" for dpar in dpars),
            "Fixed": _effect_summary(ml, dpars, "fixed"),
            "Random (int/slope)": _ordinary_summary(ml, dpars),
            "Structured (phylo/spatial/animal/relmat/phylo_interaction)": (
                _structured_summary(ml, dpars)
            ),
            "REML": "",
            "Highest evidence (exact scope)": evidence,
            "highest_evidence_tier": highest,
            "Miss-predictor mi()": _missing_predictor_summary(route, runtime),
        })
        # REML is one estimator-wide state per dpar. It is intentionally
        # computed from REML rows only, including fixed, ordinary, and
        # structured cells, rather than inferred from the ML surface.
        rows[-1]["REML"] = "; ".join(
            f"`{dpar}`: {_aggregate_state([row for row in reml if row['dpar'] == dpar])}"
            for dpar in dpars
        )
    return rows


def corrected_family_map_markdown(
    missing: list[dict[str, str]], family_rows: list[dict[str, str]]
) -> str:
    by_route = {row["family_route"]: row for row in missing}
    headers = [
        "Response", "dpars", "Fixed", "Random (int/slope)",
        "Structured (phylo/spatial/animal/relmat/phylo_interaction)", "REML",
        "Highest evidence (exact scope)",
        "Miss-response", "Miss-predictor mi()",
    ]
    lines = [
        "| " + " | ".join(headers) + " |",
        "|" + "|".join("---" for _ in headers) + "|",
    ]
    for source_row in family_rows:
        row = dict(source_row)
        gate = by_route[row["family_route"]]["test_gate"]
        gate_num = int(gate[1:])
        labels = {
            0: "rejected/planned",
            1: "implemented; audit pending",
            2: "masking validated; recovery pending",
            3: "✓ recovery verified",
            4: "✓ interval feasible",
            5: "✓ inference-ready",
        }
        row["Miss-response"] = (
            f"{gate} {labels[gate_num]}; {missing_route_g4g5_summary(row['family_route'])}"
        )
        lines.append("| " + " | ".join(row[header] for header in headers) + " |")
    return "\n".join(lines) + "\n"


def inline_markdown(value: str) -> str:
    value = html.escape(value)
    value = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", value)
    value = re.sub(r"`(.+?)`", r"<code>\1</code>", value)
    return value


def family_map_html(
    missing: list[dict[str, str]], family_rows: list[dict[str, str]]
) -> str:
    by_route = {row["family_route"]: row for row in missing}
    descriptors = {
        "gaussian": "continuous", "biv_gaussian": "two responses",
        "nbinom2": "NB2 count", "poisson": "count, log", "beta": "proportions",
        "binomial": "logit", "student": "robust", "gamma": "positive",
        "truncated_nbinom2": "positive count", "hurdle_nbinom2": "trunc + hu~",
        "cumulative_logit": "ordinal", "lognormal": "positive, log scale",
        "beta_binomial": "overdispersed trials", "skew_normal": "continuous skew",
        "tweedie": "semicontinuous", "zero_one_beta": "boundary proportions",
        "zi_poisson": "zero-inflated count", "zi_nbinom2": "zero-inflated NB2",
    }
    body = []
    for row in family_rows:
        route = row["family_route"]
        gate = by_route[route]["test_gate"]
        gate_num = int(gate[1:])
        gate_labels = {
            0: ("rejected", "planned"),
            1: ("implemented", "audit pending"),
            2: ("masking validated", "recovery pending"),
            3: ("✓ recovery verified", ""),
            4: ("✓ interval feasible", ""),
            5: ("✓ inference-ready", ""),
        }
        label, note = gate_labels[gate_num]
        gate_class = "mr-g0" if gate_num == 0 else "mr-g1" if gate_num == 1 else "mr-g2" if gate_num == 2 else "mr-verified"
        missing_cell = (
            f'<span class="mr-state {gate_class}">{gate} {label}</span>'
            + (f"<small>{note}</small>" if note else "")
            + f'<small class="mr-g4g5">{html.escape(missing_route_g4g5_summary(route))}</small>'
        )
        interval_class = (
            "inference"
            if row["highest_evidence_tier"] in {"supported", "inference_ready_with_caveats"}
            else "feasible"
        )
        body.append(
            "<tr>"
            f'<th scope="row"><code>{html.escape(route)}</code><small>{html.escape(descriptors[route])}</small></th>'
            f"<td>{inline_markdown(row['dpars'])}</td>"
            f"<td class=\"fixed\">{inline_markdown(row['Fixed'])}</td>"
            f"<td>{inline_markdown(row['Random (int/slope)'])}</td>"
            f"<td>{inline_markdown(row['Structured (phylo/spatial/animal/relmat/phylo_interaction)'])}</td>"
            f"<td>{inline_markdown(row['REML'])}</td>"
            f'<td><span class="tier {interval_class}">{inline_markdown(row["Highest evidence (exact scope)"])}</span></td>'
            f"<td>{missing_cell}</td>"
            f"<td>{inline_markdown(row['Miss-predictor mi()'])}</td>"
            "</tr>"
        )
    return "".join(body)


def surface_markdown(
    cells: list[dict[str, str]], evidence: list[dict[str, str]],
    family_rows: list[dict[str, str]] | None = None,
) -> str:
    if family_rows is None:
        family_rows = family_map_rows(cells)
    model = [row for row in cells if row["axis"] == "model_surface"]
    missing = sorted(
        (row for row in cells if row["axis"] == "missing_response"),
        key=lambda row: int(row["model_type"]),
    )
    association = sorted(
        (row for row in cells if row["axis"] == "association"),
        key=lambda row: int(row["source_order"]),
    )
    status = Counter(row["capability_status"] for row in model)
    tiers = Counter(
        row["evidence_tier"] for row in model if row["capability_status"] == "implemented"
    )
    missing_gates = Counter(row["test_gate"] for row in missing)
    verified_missing = sum(int(row["test_gate"][1:]) >= 3 for row in missing)
    by_family: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in model:
        by_family[row["family_route"]].append(row)
    lines = [
        "# drmTMB capability surface",
        "",
        f"_Generated {ledger_updated_date(cells)} from `capability-ledger/` by "
        "`tools/capability_ledger.py`; do not hand-edit this file._",
        "",
        "The model surface, staged-association surface, and missing-response "
        "execution axis answer different questions. Model cells describe direct "
        "drmTMB fits; association cells describe post-fit associate_pairs() "
        "estimators; missing-response cells describe response handling. Evidence "
        "never transfers automatically between axes.",
        "",
        "## Snapshot",
        "",
        f"- Model surface: **{len(model)} cells** across **{len(by_family)} routes**.",
        f"- Staged association: **{len(association)} cells**; "
        f"**{sum(row['evidence_tier'] == 'interval_feasible' for row in association)} interval-feasible** and "
        f"**{sum(row['evidence_tier'] == 'inference_ready_with_caveats' for row in association)} inference-ready with caveats**.",
        f"- Runtime status: **{status['implemented']} implemented**, "
        f"**{status['not_implemented']} actionable not implemented**, and "
        f"**{status['rejected_by_design']} not currently supported**.",
        "- Planning classes make the backlog visible without calling it impossible: "
        "admission candidate, covariance/model method, or estimator method. "
        "They are scope classes, not effort estimates or evidence claims.",
        "- ML and REML are separate estimators. An ML implementation does not "
        "automatically supply REML; REML cells require a valid restricted-likelihood "
        "objective and their own validation.",
        f"- Evidence: **{tiers['supported']} supported**, "
        f"**{tiers['inference_ready_with_caveats']} inference-ready**, "
        f"**{tiers['interval_feasible']} interval-feasible**, "
        f"**{tiers['point_fit_recovery']} recovery-grade**.",
        f"- Missing-response board: **{len(missing)} routes; "
        f"{missing_gates['G0']} G0; {missing_gates['G1']} G1; "
        f"{missing_gates['G2']} G2; {verified_missing} verified (G3+)**.",
        "",
        "## Staged association capability",
        "",
        "The evidence ladder is point-fit recovery, interval feasible, inference-"
        "ready with caveats, then supported. Interval feasibility is sufficient "
        "to expose a scoped method; coverage evidence promotes the tested domain "
        "to inference-ready. Limits belong in the claim boundary unless evidence "
        "directly contradicts the route.",
        "",
        "| Cell | Pair route | Association shape | Status | Evidence tier | Claim boundary |",
        "|---|---|---|---|---|---|",
        *[
            f"| `{row['cell_id']}` | `{row['family_route']}` | "
            f"`{row['route_variant']}` | {row['capability_status'].replace('_', ' ')} | "
            f"{row['evidence_tier'].replace('_', ' ')} | {row['claim_boundary']} |"
            for row in association
        ],
        "",
        "## Missing-response execution board",
        "",
        "G0 = rejected; G1 = implemented; G2 = masking validated; G3 = recovery; "
        "G4 = interval feasible; G5 = inference-ready. The verified tick begins "
        "at G3.",
        "",
        f"> **Current G4/G5 evidence (target-rung grain):** {missing_g4g5_summary()}",
        "",
        missing_markdown(missing).rstrip(),
        "",
        "### Route-level evidence rule",
        "",
        "Mixture routes have their own masking and recovery evidence. A zero-"
        "inflated or hurdle route never inherits a tick from its Poisson, NB2, "
        "or truncated-NB2 base family.",
        "",
        "Each route's displayed gate and work state come from its own ledger "
        "evidence. Verified routes have passed direct sentinel mutation, "
        "residual/accounting, and named recovery audits; no route inherits a "
        "tick from a base family.",
        "",
        "## Per-family model-surface summary",
        "",
        "| Route | Cells | Implemented | Actionable backlog | Not currently supported | Highest evidence |",
        "|---|---:|---:|---:|---:|---|",
    ]
    for family in sorted(by_family):
        rows = by_family[family]
        counts = Counter(row["capability_status"] for row in rows)
        available = {row["evidence_tier"] for row in rows if row["capability_status"] == "implemented"}
        highest = next((tier for tier in TIER_ORDER if tier in available), "none")
        lines.append(
            f"| `{family}` | {len(rows)} | {counts['implemented']} | "
            f"{counts['not_implemented']} | {counts['rejected_by_design']} | "
            f"{highest.replace('_', ' ')} |"
        )
    lines.extend([
        "",
        "## Evidence and detailed cells",
        "",
        "Use the generated HTML surface for filters, route anchors, claim "
        "boundaries, next gates, and direct evidence links. Machine-readable "
        "sources are `capability-ledger/cells.tsv`, `evidence.tsv`, and "
        "`transitions.tsv`.",
        "",
        "## Per-family capability reference",
        "",
        "This table is projected from the current model-surface cells. Its "
        "missing-response column is joined separately from the 18-route ledger, "
        "and its missing-predictor column follows the live R runtime gate.",
        "",
        corrected_family_map_markdown(missing, family_rows).rstrip(),
        "",
    ])
    return "\n".join(lines)


COMPARATOR_PACKAGES = (
    "metafor", "glmmTMB", "lme4", "MASS", "ordinal", "VGAM", "mgcv", "betareg",
    "gamlss", "brms", "stats::glm",
)


def external_comparator_by_cell(
    evidence: list[dict[str, str]]
) -> dict[str, str]:
    """Name the external comparators recorded for each cell, keyed by cell_id.

    DELIBERATELY PER CELL, and it must stay that way. A family_route bucket mixes
    fixed, random, structured, phylogenetic, spatial and bivariate cells together. A
    family-level comparator badge would therefore read as covering frontier routes for
    which no external implementation exists at all -- which is exactly the
    credibility-laundering this evidence class is meant to avoid. Agreement with an
    established package licenses the OVERLAP region only, never the frontier.

    Each entry reads "package (strong)" or "package (weak)". The strength is NOT
    decoration: lme4 and metafor are separate estimation engines, so agreement is a real
    cross-implementation check, whereas glmmTMB is built on the same TMB/AD stack and
    outer optimizer as drmTMB, so agreement there is a consistency check between related
    implementations. Rendering the package name alone made all three look equivalent.

    Package names are matched against run_id and result only, never claim_boundary. The
    boundary is where a row says what it does NOT cover, so a phrase like "does not extend
    to glmmTMB" would otherwise badge glmmTMB as a comparator.
    """
    found: dict[str, set[str]] = {}
    for row in evidence:
        if row["evidence_class"] != "external_comparator":
            continue
        haystack = f"{row['run_id']} {row['result']}"
        boundary = row["claim_boundary"].upper()
        if "STRONG INDEPENDENCE" in boundary:
            strength = "strong"
        elif "WEAK INDEPENDENCE" in boundary:
            strength = "weak"
        else:
            strength = "unclassified"
        names = {
            f"{pkg} ({strength})" for pkg in COMPARATOR_PACKAGES if pkg in haystack
        }
        found.setdefault(row["cell_id"], set()).update(names)
    return {
        cell_id: ", ".join(sorted(names, key=str.lower))
        for cell_id, names in found.items()
        if names
    }


def surface_html(
    cells: list[dict[str, str]], evidence: list[dict[str, str]],
    family_rows: list[dict[str, str]] | None = None,
) -> str:
    if family_rows is None:
        family_rows = family_map_rows(cells)
    generated_date = ledger_updated_date(cells)
    model = sorted(
        (row for row in cells if row["axis"] == "model_surface"),
        key=lambda row: int(row["source_order"]),
    )
    missing = sorted(
        (row for row in cells if row["axis"] == "missing_response"),
        key=lambda row: int(row["model_type"]),
    )
    association = sorted(
        (row for row in cells if row["axis"] == "association"),
        key=lambda row: int(row["source_order"]),
    )
    status = Counter(row["capability_status"] for row in model)
    tiers = Counter(
        row["evidence_tier"] for row in model if row["capability_status"] == "implemented"
    )
    missing_gates = Counter(row["test_gate"] for row in missing)
    verified_missing = sum(int(row["test_gate"][1:]) >= 3 for row in missing)
    comparators = external_comparator_by_cell(evidence)
    model_data = json.dumps([
        {
            **{key: row[key] for key in (
                "cell_id", "family_route", "route_variant", "dpar", "effect_type",
                "structure_provider", "dimension", "q_gate", "estimator",
                "capability_status", "evidence_tier", "claim_boundary",
                "primary_evidence_id",
            )},
            "planning_class": planning_class(row),
            "external_comparator": comparators.get(row["cell_id"], ""),
        }
        for row in model
    ], ensure_ascii=False).replace("</", "<\\/")
    initial_model_rows = "".join(
        "<tr>"
        f"<td><code>{html.escape(row['cell_id'])}</code></td>"
        f"<td><code>{html.escape(row['family_route'])}</code></td>"
        f"<td>{html.escape(row['route_variant'])}</td>"
        f"<td>{html.escape(row['dpar'])}</td>"
        f"<td>{html.escape(row['effect_type'])}</td>"
        f"<td>{html.escape(row['structure_provider'])}</td>"
        f"<td>{html.escape(row['estimator'])}</td>"
        f"<td>{html.escape(planning_class(row))}</td>"
        f"<td><span class=\"pill\">{html.escape(row['capability_status'].replace('_', ' '))}</span></td>"
        f"<td>{html.escape(row['evidence_tier'].replace('_', ' '))}</td>"
        f"<td>{html.escape(comparators.get(row['cell_id'], ''))}</td>"
        f"<td>{html.escape(row['claim_boundary'])}</td>"
        "</tr>"
        for row in model
    )
    association_rows = "".join(
        "<tr>"
        f"<td><code>{html.escape(row['cell_id'])}</code></td>"
        f"<td><code>{html.escape(row['family_route'])}</code></td>"
        f"<td>{html.escape(row['route_variant'])}</td>"
        f"<td><span class=\"pill\">{html.escape(row['capability_status'].replace('_', ' '))}</span></td>"
        f"<td>{html.escape(row['evidence_tier'].replace('_', ' '))}</td>"
        f"<td>{html.escape(row['claim_boundary'])}</td>"
        "</tr>"
        for row in association
    )
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>drmTMB capability surface</title>
<style>
:root{{--bg:#eef3f4;--panel:#fff;--text:#162326;--muted:#617176;--line:#d4dfe2;--teal:#087d89;--green:#188653;--amber:#b77a13;--red:#b84436;--blue:#2f6fad;--shadow:0 8px 24px #17333a12;--mono:ui-monospace,SFMono-Regular,Menlo,monospace}}
@media(prefers-color-scheme:dark){{:root{{--bg:#10181b;--panel:#182328;--text:#e8f0f2;--muted:#a3b2b7;--line:#304147;--teal:#48bdc8;--green:#4bc78b;--amber:#e4b45e;--red:#f07b6a;--blue:#78afe8;--shadow:none}}}}
:root[data-theme="light"]{{--bg:#eef3f4;--panel:#fff;--text:#162326;--muted:#617176;--line:#d4dfe2;--teal:#087d89;--green:#188653;--amber:#b77a13;--red:#b84436;--blue:#2f6fad;--shadow:0 8px 24px #17333a12}}
:root[data-theme="dark"]{{--bg:#10181b;--panel:#182328;--text:#e8f0f2;--muted:#a3b2b7;--line:#304147;--teal:#48bdc8;--green:#4bc78b;--amber:#e4b45e;--red:#f07b6a;--blue:#78afe8;--shadow:none}}
*{{box-sizing:border-box}} body{{margin:0;background:var(--bg);color:var(--text);font:16px/1.5 system-ui,-apple-system,Segoe UI,sans-serif}} a{{color:var(--teal)}} code{{font-family:var(--mono)}} .skip{{position:absolute;left:-9999px;top:8px;background:var(--panel);padding:8px 12px;z-index:10}} .skip:focus{{left:8px}} .page{{max-width:1440px;margin:auto;padding:34px 28px 80px}} .topline{{display:flex;justify-content:space-between;gap:16px;align-items:center}} .eyebrow{{font:700 13px/1.2 var(--mono);letter-spacing:.14em;text-transform:uppercase;color:var(--teal)}} h1{{font-size:clamp(2.1rem,5vw,4.4rem);line-height:1.02;margin:.35rem 0 1rem}} h2{{font-size:1.55rem;margin:3rem 0 1rem;scroll-margin-top:18px}} .lede{{font-size:1.2rem;color:var(--muted);max-width:980px}} .jump{{display:flex;gap:10px;flex-wrap:wrap;margin:1rem 0 1.5rem}} .jump a{{background:var(--panel);border:1px solid var(--line);border-radius:99px;padding:6px 11px;text-decoration:none}} .scope{{border-left:4px solid var(--teal);padding:.8rem 1rem;background:var(--panel);box-shadow:var(--shadow)}} .stats{{display:grid;grid-template-columns:repeat(auto-fit,minmax(155px,1fr));gap:12px;margin:28px 0}} .stat{{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:15px;box-shadow:var(--shadow)}} .stat b{{display:block;font:750 1.8rem var(--mono)}} .stat span{{color:var(--muted)}} .legend{{display:flex;gap:18px;flex-wrap:wrap;color:var(--muted);margin:.6rem 0 1.4rem}} .legend i{{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:6px}} .routes{{display:grid;grid-template-columns:repeat(auto-fit,minmax(285px,1fr));gap:14px}} .route-card{{background:var(--panel);border:1px solid var(--line);border-top:5px solid var(--amber);border-radius:13px;padding:16px;box-shadow:var(--shadow);scroll-margin-top:20px}} .route-card.g0{{border-top-color:var(--red)}} .route-card.g2{{border-top-color:var(--blue)}} .route-card.g3,.route-card.g4,.route-card.g5{{border-top-color:var(--green)}} .route-head{{display:flex;justify-content:space-between;gap:12px;align-items:center;font-size:1.06rem;font-weight:750}} .gate{{font:750 .85rem var(--mono);border:1px solid currentColor;border-radius:99px;padding:2px 8px;color:var(--amber)}} .g0 .gate{{color:var(--red)}} .g2 .gate{{color:var(--blue)}} .g3 .gate,.g4 .gate,.g5 .gate{{color:var(--green)}} .route-state{{color:var(--muted);margin:.45rem 0}} .gate-track{{height:6px;border-radius:6px;background:var(--line);overflow:hidden}} .gate-track span{{display:block;height:100%;background:var(--amber)}} .g0 .gate-track span{{background:var(--red)}} .g2 .gate-track span{{background:var(--blue)}} .g3 .gate-track span,.g4 .gate-track span,.g5 .gate-track span{{background:var(--green)}} .route-card p{{font-size:.92rem}} .route-card .next{{min-height:4.1em}} .route-card a{{font-size:.82rem;overflow-wrap:anywhere}} .verified{{color:var(--green);font-weight:700}} .filters{{display:flex;gap:10px;flex-wrap:wrap;margin:1rem 0}} input,select,button{{font:inherit;color:var(--text);background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:8px 10px}} button{{cursor:pointer}} .table-wrap{{overflow:auto;background:var(--panel);border:1px solid var(--line);border-radius:12px;max-height:720px}} table{{border-collapse:collapse;width:100%;font-size:.84rem}} caption{{text-align:left;padding:12px;color:var(--muted)}} th,td{{padding:9px 11px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}} thead th{{position:sticky;top:0;background:var(--panel);z-index:1}} tbody tr:hover{{background:color-mix(in srgb,var(--teal) 7%,transparent)}} .pill{{display:inline-block;border-radius:99px;padding:2px 7px;background:var(--bg);white-space:nowrap}} .family-wrap{{overflow:auto;background:var(--panel);border:1px solid var(--line);border-radius:14px;box-shadow:var(--shadow)}} .family-map{{min-width:1620px;font-size:.92rem}} .family-map th,.family-map td{{padding:18px 16px}} .family-map tbody th{{position:sticky;left:0;background:var(--panel);z-index:1;min-width:175px}} .family-map tbody th code{{font-size:1rem;font-weight:800}} .family-map small{{display:block;color:var(--muted);font-weight:400;margin-top:4px}} .family-map .fixed{{color:var(--green);font-weight:700;text-align:center;font-size:1.05rem}} .tier{{display:inline-block;border-radius:8px;padding:5px 7px}} .tier.inference{{background:color-mix(in srgb,var(--green) 14%,transparent);color:var(--green)}} .tier.feasible{{background:color-mix(in srgb,var(--amber) 14%,transparent);color:var(--amber)}} .mr-state{{font-weight:750;white-space:nowrap}} .mr-g1{{color:var(--amber)}} .mr-g0{{color:var(--red)}} .mr-g2{{color:var(--blue)}} .mr-verified{{color:var(--green)}} .muted{{color:var(--muted)}} footer{{margin-top:3rem;color:var(--muted)}} @media(max-width:650px){{.page{{padding:24px 14px 60px}} .route-card .next{{min-height:0}}}} @media(prefers-reduced-motion:reduce){{*{{scroll-behavior:auto!important}}}}
</style></head><body><a class="skip" href="#model-cells">Skip to capability content</a><main class="page">
<div class="topline"><div class="eyebrow">drmTMB · generated capability ledger · MR-T0</div><button id="theme" type="button" aria-label="Toggle light and dark theme">Theme</button></div>
<h1>Capability surface</h1>
<p class="lede">One model census, one staged-association surface, one scoped missing-response evidence summary, and no inherited ticks. The ledger distinguishes code admission, validation work, and inferential evidence across axes.</p>
<nav class="jump" aria-label="Capability surface sections"><a href="#association">Association</a><a href="#missing-response">Missing-response board</a><a href="#model-cells">Detailed cells</a><a href="#family-capability">Per-family map</a></nav>
<p class="scope"><strong>Scope:</strong> {len(model)} model-surface cells, {len(association)} staged-association cells, and 18 missing-response routes. Evidence never transfers automatically between axes; a missing-response ✓ appears only at G3 recovery or above and never promotes the model's separate inference tier.</p>
<section class="stats" aria-label="Capability summary">
<div class="stat"><b>{len(model)}</b><span>model cells</span></div><div class="stat"><b>{len(association)}</b><span>association cells</span></div><div class="stat"><b>{sum(row['evidence_tier'] == 'interval_feasible' for row in association)}</b><span>association interval-feasible</span></div><div class="stat"><b>{sum(row['evidence_tier'] == 'inference_ready_with_caveats' for row in association)}</b><span>association inference-ready</span></div><div class="stat"><b>{len(missing)}</b><span>missing-response routes</span></div>
<div class="stat"><b>{status['implemented']}</b><span>implemented model cells</span></div><div class="stat"><b>{status['not_implemented']}</b><span>actionable backlog cells</span></div><div class="stat"><b>{status['rejected_by_design']}</b><span>not currently supported</span></div><div class="stat"><b>{tiers['inference_ready_with_caveats']}</b><span>inference-ready cells</span></div>
<div class="stat"><b>{missing_gates['G1']}</b><span>routes at G1</span></div><div class="stat"><b>{verified_missing}</b><span>routes verified at G3+</span></div>
</section>
<h2 id="association">Staged association capability</h2>
<p>The evidence ladder is point-fit recovery → interval feasible → inference-ready with caveats → supported. Interval feasibility is enough to expose a scoped method; coverage promotes the tested domain to inference-ready. Limits belong in warnings and the claim boundary unless evidence directly contradicts the route.</p>
<div class="table-wrap"><table><caption>{len(association)} post-fit <code>associate_pairs()</code> capability cells</caption><thead><tr><th scope="col">Cell</th><th scope="col">Pair route</th><th scope="col">Shape</th><th scope="col">Status</th><th scope="col">Evidence tier</th><th scope="col">Claim boundary</th></tr></thead><tbody>{association_rows}</tbody></table></div>
<h2 id="missing-response">Missing-response evidence</h2>
<p class="scope"><strong>Current G4/G5 evidence (target-rung grain):</strong> {html.escape(missing_g4g5_summary())}</p>
<p class="muted">The per-family reference below remains the route-level source: its Missing response column retains G3 recovery status, while this summary shows the additional G4/G5 evidence without implying a route-wide promotion.</p>
<h2 id="model-cells">Detailed model surface</h2>
<p class="muted">These {len(model)} cells are the current model/inference census. Missing-response progress is not folded into these tiers.</p>
<p class="scope"><strong>Missing-response column:</strong> route-level G3 is retained on purpose. {html.escape(missing_g4g5_summary())}</p>
<p class="muted"><strong>Estimator:</strong> ML and REML are separate objectives. A working ML route does not automatically have a valid REML implementation. <strong>Planning class</strong> distinguishes an admission candidate from a covariance/model-method or estimator-method extension; it is a planning cue, not an effort estimate or a support claim.</p>
<p class="muted"><strong>External comparator</strong> names a package that fits the same model and reaches the same estimates on a single simulated dataset. It says the implementation agrees with an independent one; it is <em>not</em> an interval, coverage, bias or recovery claim, and it never raises the evidence tier. <em>strong</em> means a separate estimation engine (lme4, metafor); <em>weak</em> means the comparator shares drmTMB's TMB/AD stack (glmmTMB), so agreement is a consistency check between related implementations. A blank cell means no comparator has been recorded — for structured, scale-side, bivariate and phylogenetic routes no established implementation exists to compare against at all.</p>
<div class="filters" role="search"><label>Route <select id="family"><option value="">All</option></select></label><label>Status <select id="status"><option value="">All</option></select></label><label>Search <input id="query" type="search" placeholder="parameter, provider, evidence…"></label><button id="clear" type="button">Clear</button></div>
<div id="count" class="muted" aria-live="polite"></div>
<div class="table-wrap"><table><caption>Generated {len(model)}-cell model capability census</caption><thead><tr><th scope="col">Cell</th><th scope="col">Route</th><th scope="col">Variant</th><th scope="col">dpar</th><th scope="col">Effect</th><th scope="col">Provider</th><th scope="col">Estimator</th><th scope="col">Planning class</th><th scope="col">Status</th><th scope="col">Evidence tier</th><th scope="col">External comparator</th><th scope="col">Claim boundary</th></tr></thead><tbody id="rows">{initial_model_rows}</tbody></table></div>
<h2 id="family-capability">Per-family capability reference</h2>
<p class="muted">This reference is projected from current model-surface cells. REML uses only REML rows; missing-response is joined from its separate route ledger; and missing-predictor support follows the live R runtime gate.</p>
<div class="family-wrap"><table class="family-map"><caption>Live per-family capability map</caption><thead><tr><th scope="col">Family</th><th scope="col">dpars</th><th scope="col">Fixed</th><th scope="col">Random (int / slope)</th><th scope="col">Structured — phylo / spatial / animal / relmat / phylo_interaction</th><th scope="col">REML</th><th scope="col">Highest evidence (exact scope)</th><th scope="col">Missing response</th><th scope="col">Missing predictor mi()</th></tr></thead><tbody>{family_map_html(missing, family_rows)}</tbody></table></div>
<footer>Generated {generated_date} by <code>tools/capability_ledger.py</code> from <code>docs/dev-log/dashboard/capability-ledger/</code>. Do not hand-edit generated outputs.</footer>
</main><script>const DATA={model_data};
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}}[c]));
const fam=document.querySelector('#family'),status=document.querySelector('#status'),query=document.querySelector('#query'),body=document.querySelector('#rows'),count=document.querySelector('#count');
for(const v of [...new Set(DATA.map(r=>r.family_route))].sort()) fam.insertAdjacentHTML('beforeend',`<option>${{esc(v)}}</option>`);
for(const v of [...new Set(DATA.map(r=>r.capability_status))].sort()) status.insertAdjacentHTML('beforeend',`<option>${{esc(v)}}</option>`);
function render(){{const q=query.value.toLowerCase();const out=DATA.filter(r=>(!fam.value||r.family_route===fam.value)&&(!status.value||r.capability_status===status.value)&&(!q||Object.values(r).join(' ').toLowerCase().includes(q)));count.textContent=`${{out.length}} of {len(model)} cells`;body.innerHTML=out.map(r=>`<tr><td><code>${{esc(r.cell_id)}}</code></td><td><code>${{esc(r.family_route)}}</code></td><td>${{esc(r.route_variant)}}</td><td>${{esc(r.dpar)}}</td><td>${{esc(r.effect_type)}}</td><td>${{esc(r.structure_provider)}}</td><td>${{esc(r.estimator)}}</td><td>${{esc(r.planning_class)}}</td><td><span class="pill">${{esc(r.capability_status.replaceAll('_',' '))}}</span></td><td>${{esc(r.evidence_tier.replaceAll('_',' '))}}</td><td>${{esc(r.external_comparator)}}</td><td>${{esc(r.claim_boundary)}}</td></tr>`).join('')}}
for(const el of [fam,status,query]) el.addEventListener('input',render);document.querySelector('#clear').addEventListener('click',()=>{{fam.value=status.value=query.value='';render()}});document.querySelector('#theme').addEventListener('click',()=>{{const root=document.documentElement;root.dataset.theme=root.dataset.theme==='dark'?'light':'dark'}});render();</script></body></html>"""


def tranche_summary(cells: list[dict[str, str]], tranche_id: str) -> str:
    missing = [
        row for row in cells
        if row["axis"] == "missing_response" and row["tranche_id"] == tranche_id
    ]
    counts = Counter(row["work_status"] for row in missing)
    lines = [
        f"# {tranche_id} missing-response ledger summary",
        "",
        "_Generated; do not hand-edit._",
        "",
        "| Tranche | Routes | Backlog | Implemented unverified | Verified | Next gate |",
        "|---|---:|---:|---:|---:|---|",
        f"| {tranche_id} | {len(missing)} | {counts['backlog']} | {counts['implemented_unverified']} | {counts['verified']} | Follow each route's evidence and next-gate fields |",
        "",
        "## Route accounting",
        "",
        missing_markdown(sorted(missing, key=lambda row: int(row["model_type"]))).rstrip(),
        "",
        "## Does not cover",
        "",
        "This summary does not promote intervals, coverage, model inference tiers, "
        "missing-predictor support, REML, or structured-effect claims.",
        "",
    ]
    return "\n".join(lines)


def outputs(
    cells: list[dict[str, str]], evidence: list[dict[str, str]]
) -> dict[Path, bytes]:
    model = model_projection(cells, evidence)
    generated_date = ledger_updated_date(cells)
    family_rows = family_map_rows(cells)
    missing = sorted(
        (row for row in cells if row["axis"] == "missing_response"),
        key=lambda row: int(row["model_type"]),
    )
    result: dict[Path, bytes] = {
        CENSUS / "_master.tsv": legacy_tsv_bytes(MODEL_FIELDS, model),
        CENSUS / "_widget_data.json": compact_json_bytes(
            widget_value(model, generated_date)
        ),
        ROOT / "docs/dev-log/dashboard/capability-surface.md": surface_markdown(
            cells, evidence, family_rows
        ).encode("utf-8"),
        ROOT / "docs/dev-log/dashboard/capability-surface.html": surface_html(
            cells, evidence, family_rows
        ).encode("utf-8"),
        ROOT / "vignettes/includes/capability-ledger-missing-response.md": missing_markdown(missing, compact=True).encode("utf-8"),
        ROOT / "vignettes/includes/capability-ledger-family-map.md": corrected_family_map_markdown(
            missing, family_rows
        ).encode("utf-8"),
        **{
            LEDGER / "tranches" / f"{tranche}.md": tranche_summary(cells, tranche).encode("utf-8")
            for tranche in ("MR-T1", "MR-T2", "MR-T3", "MR-T4", "MR-T5", "MR-T6")
        },
    }
    for family in sorted({row["family"] for row in model}):
        result[CENSUS / f"{family}.tsv"] = legacy_tsv_bytes(
            MODEL_FIELDS, [row for row in model if row["family"] == family]
        )
    return result


def load_sources() -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, str]]]:
    if not all(path.exists() for path in (CELLS, EVIDENCE, TRANSITIONS, SCHEMA)):
        raise SystemExit("Capability ledger is missing; run --bootstrap once")
    if json.loads(SCHEMA.read_text(encoding="utf-8")) != schema_value():
        raise SystemExit("schema.json does not match the generator contract")
    cells = read_tsv(CELLS)
    evidence = read_tsv(EVIDENCE)
    transitions = read_tsv(TRANSITIONS)
    validate(cells, evidence, transitions)
    return cells, evidence, transitions


def write_outputs(generated: dict[Path, bytes]) -> None:
    for path, content in generated.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        print(display_path(path))


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def check_outputs(generated: dict[Path, bytes]) -> None:
    stale = []
    for path, expected in generated.items():
        if not path.exists():
            stale.append(f"missing: {display_path(path)}")
        elif path.read_bytes() != expected:
            stale.append(f"stale: {display_path(path)}")
    if stale:
        raise SystemExit(
            "Generated capability outputs are not current:\n- " + "\n- ".join(stale)
            + "\nRun: python3 tools/capability_ledger.py --write"
        )
    print(f"capability-ledger: OK ({len(generated)} generated outputs)")


def summary(cells: list[dict[str, str]]) -> None:
    axes = Counter(row["axis"] for row in cells)
    missing = [row for row in cells if row["axis"] == "missing_response"]
    work = Counter(row["work_status"] for row in missing)
    gates = Counter(row["test_gate"] for row in missing)
    print(f"model_surface={axes['model_surface']} missing_response={axes['missing_response']}")
    print("missing work:", " ".join(f"{key}={work[key]}" for key in sorted(work)))
    print("missing gates:", " ".join(f"{key}={gates[key]}" for key in sorted(gates)))


def main() -> None:
    parser = argparse.ArgumentParser()
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--bootstrap", action="store_true")
    action.add_argument("--restore-c14-boundaries", action="store_true")
    action.add_argument("--split-c14-zob-structured-leaves", action="store_true")
    action.add_argument("--check-c14-receipt-equivalence", action="store_true")
    action.add_argument("--write", action="store_true")
    action.add_argument("--check", action="store_true")
    action.add_argument("--summary", action="store_true")
    args = parser.parse_args()
    if args.bootstrap:
        bootstrap()
        return
    if args.restore_c14_boundaries:
        restore_c14_boundaries()
        return
    if args.split_c14_zob_structured_leaves:
        split_c14_zob_structured_leaves()
        return
    if args.check_c14_receipt_equivalence:
        check_c14_receipt_equivalence()
        return
    cells, evidence, _ = load_sources()
    if args.write:
        write_outputs(outputs(cells, evidence))
    elif args.check:
        check_outputs(outputs(cells, evidence))
    else:
        summary(cells)


if __name__ == "__main__":
    main()
