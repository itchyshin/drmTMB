#!/usr/bin/env python3
"""Validate and generate drmTMB's capability ledger and public surfaces.

The ledger is authoritative. Generated census, JSON, Markdown, HTML, vignette
include, and tranche summaries must never be edited by hand.
"""

from __future__ import annotations

import argparse
import csv
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

DATE = "2026-07-11"
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
    "cumulative_logit", "skew_normal", "binomial",
}

WORK_STATUSES = {
    "backlog", "designed", "in_progress", "implemented_unverified",
    "verified", "blocked", "deferred",
}
CAPABILITY_STATUSES = {
    "rejected_by_design", "not_implemented", "scaffolded", "implemented",
}
TEST_GATES = {"na", "G0", "G1", "G2", "G3", "G4", "G5"}
EVIDENCE_TIERS = {
    "supported", "inference_ready_with_caveats", "interval_feasible",
    "diagnostic_only", "point_fit_recovery", "none", "miswired", "na",
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
        "axes": ["model_surface", "missing_response"],
        "cell_fields": CELL_FIELDS,
        "evidence_fields": EVIDENCE_FIELDS,
        "transition_fields": TRANSITION_FIELDS,
        "enums": {
            "capability_status": sorted(CAPABILITY_STATUSES),
            "work_status": sorted(WORK_STATUSES),
            "test_gate": sorted(TEST_GATES),
            "evidence_tier": sorted(EVIDENCE_TIERS),
        },
        "expected_counts": {"model_surface": 668, "missing_response": 18},
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
    if len(master) != 668:
        raise SystemExit(f"Expected 668 legacy rows, found {len(master)}")

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
        work = (
            "verified" if status == "implemented"
            else "deferred" if status == "rejected_by_design"
            else "backlog"
        )
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
            "reason": "MR-T0 import of the unchanged 668-cell census",
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
            "source_order": str(668 + offset),
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
            "capability_status": "implemented" if admitted else "rejected_by_design",
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
    if by_axis != Counter({"model_surface": 668, "missing_response": 18}):
        errors.append(f"axis counts are {dict(by_axis)}, expected 668 + 18")
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

    for row in evidence:
        if row["cell_id"] not in cell_ids:
            errors.append(f"{row['evidence_id']}: unknown cell_id")
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
    expected = Counter({"implemented": 283, "rejected_by_design": 343, "not_implemented": 42})
    if status_counts != expected:
        errors.append(f"model status counts changed: {dict(status_counts)}")

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


def model_projection(cells: list[dict[str, str]]) -> list[dict[str, str]]:
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
        "evidence_tier": row["evidence_tier"],
        "evidence_source": row["legacy_evidence_source"],
        "notes": row["notes"],
    } for row in rows]


def widget_value(model: list[dict[str, str]]) -> dict[str, object]:
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
        "generated": DATE,
        "rows": [
            {key: row[key] for key in (
                "family", "dpar", "effect_type", "structure_provider",
                "dimension", "q_gate", "estimator", "status", "evidence_tier",
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


def evidence_href(value: str) -> str:
    if value.startswith(("http://", "https://")):
        return value
    first = value.split(";", 1)[0].strip()
    path, separator, lines = first.partition(":")
    anchor = ""
    if separator and lines.replace("-", "").isdigit():
        bounds = lines.split("-", 1)
        anchor = f"#L{bounds[0]}"
        if len(bounds) == 2:
            anchor += f"-L{bounds[1]}"
    return f"https://github.com/itchyshin/drmTMB/blob/main/{path}{anchor}"


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
            f"{row['work_status'].replace('_', ' ')} | {row['next_gate']} |"
        )
    if compact:
        lines.extend([
            "",
            "A ✓ appears only at G3 recovery or above. Missing-response evidence does "
            "not change the model's separate inference tier.",
        ])
    return "\n".join(lines) + "\n"


def family_map_rows() -> list[dict[str, str]]:
    """Recover the code-verified 2026-07-11 family map as a retained view."""
    source = ROOT / "docs/dev-log/dashboard/2026-07-11-capability-surface.md"
    lines = source.read_text(encoding="utf-8").splitlines()
    start = next(
        index for index, line in enumerate(lines)
        if line.startswith("| Response | dpars | Fixed |")
    )
    headers = [cell.strip() for cell in lines[start].strip("|").split("|")]
    rows = []
    for line in lines[start + 2:]:
        if not line.startswith("|"):
            break
        values = [cell.strip() for cell in line.strip("|").split("|")]
        if len(values) != len(headers):
            raise SystemExit("Archived per-family capability table is malformed")
        row = dict(zip(headers, values))
        match = re.search(r"\*\*([^*]+)\*\*", row["Response"])
        if not match:
            raise SystemExit(f"Cannot identify family route in {row['Response']}")
        row["family_route"] = match.group(1)
        rows.append(row)
    if len(rows) != 18:
        raise SystemExit(f"Expected 18 retained family-map rows, found {len(rows)}")
    return rows


def corrected_family_map_markdown(missing: list[dict[str, str]]) -> str:
    by_route = {row["family_route"]: row for row in missing}
    headers = [
        "Response", "dpars", "Fixed", "Random (int/slope)",
        "Structured (phylo/spatial/animal/relmat)", "REML", "Interval tier",
        "Miss-response", "Miss-predictor mi()",
    ]
    lines = [
        "| " + " | ".join(headers) + " |",
        "|" + "|".join("---" for _ in headers) + "|",
    ]
    for row in family_map_rows():
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
        row["Miss-response"] = f"{gate} {labels[gate_num]}"
        lines.append("| " + " | ".join(row[header] for header in headers) + " |")
    return "\n".join(lines) + "\n"


def inline_markdown(value: str) -> str:
    value = html.escape(value)
    value = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", value)
    value = re.sub(r"`(.+?)`", r"<code>\1</code>", value)
    return value


def family_map_html(missing: list[dict[str, str]]) -> str:
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
    for row in family_map_rows():
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
        )
        interval_class = "inference" if "Inference-ready" in row["Interval tier"] else "feasible"
        body.append(
            "<tr>"
            f'<th scope="row"><code>{html.escape(route)}</code><small>{html.escape(descriptors[route])}</small></th>'
            f"<td>{inline_markdown(row['dpars'])}</td>"
            f"<td class=\"fixed\">{inline_markdown(row['Fixed'])}</td>"
            f"<td>{inline_markdown(row['Random (int/slope)'])}</td>"
            f"<td>{inline_markdown(row['Structured (phylo/spatial/animal/relmat)'])}</td>"
            f"<td>{inline_markdown(row['REML'])}</td>"
            f'<td><span class="tier {interval_class}">{inline_markdown(row["Interval tier"])}</span></td>'
            f"<td>{missing_cell}</td>"
            f"<td>{inline_markdown(row['Miss-predictor mi()'])}</td>"
            "</tr>"
        )
    return "".join(body)


def surface_markdown(
    cells: list[dict[str, str]], evidence: list[dict[str, str]]
) -> str:
    model = [row for row in cells if row["axis"] == "model_surface"]
    missing = sorted(
        (row for row in cells if row["axis"] == "missing_response"),
        key=lambda row: int(row["model_type"]),
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
    tier_order = [
        "supported", "inference_ready_with_caveats", "interval_feasible",
        "diagnostic_only", "point_fit_recovery", "none", "miswired",
    ]
    lines = [
        "# drmTMB capability surface",
        "",
        "_Generated from `capability-ledger/` by `tools/capability_ledger.py`; do "
        "not hand-edit this file._",
        "",
        "The model surface and missing-response execution axis answer different "
        "questions. The first records what a model cell fits and what inference "
        "evidence exists. The second records whether an exact user-visible route "
        "handles missing responses. A missing-response tick never promotes the "
        "model's inference tier.",
        "",
        "## Snapshot",
        "",
        f"- Model surface: **{len(model)} cells** across **{len(by_family)} routes**.",
        f"- Runtime status: **{status['implemented']} implemented**, "
        f"**{status['rejected_by_design']} rejected by design**, "
        f"**{status['not_implemented']} not implemented**.",
        f"- Evidence: **{tiers['supported']} supported**, "
        f"**{tiers['inference_ready_with_caveats']} inference-ready**, "
        f"**{tiers['interval_feasible']} interval-feasible**, "
        f"**{tiers['point_fit_recovery']} recovery-grade**.",
        f"- Missing-response board: **{len(missing)} routes; "
        f"{missing_gates['G0']} G0; {missing_gates['G1']} G1; "
        f"{missing_gates['G2']} G2; {verified_missing} verified (G3+)**.",
        "",
        "## Missing-response execution board",
        "",
        "G0 = rejected; G1 = implemented; G2 = masking validated; G3 = recovery; "
        "G4 = interval feasible; G5 = inference-ready. The verified tick begins "
        "at G3.",
        "",
        missing_markdown(missing).rstrip(),
        "",
        "### Corrections made in MR-T0",
        "",
        "`zi_poisson` and `zi_nbinom2` are G0/rejected. Their base family types "
        "pass the broad family gate, but their builders explicitly reject a zero-"
        "inflation formula combined with response-missingness. Neither route "
        "inherits a tick from Poisson or NB2.",
        "",
        "Each route's displayed gate and work state come from its own ledger "
        "evidence. Verified routes have passed direct sentinel mutation, "
        "residual/accounting, and named recovery audits; no route inherits a "
        "tick from a base family.",
        "",
        "## Per-family model-surface summary",
        "",
        "| Route | Cells | Implemented | Rejected | Not implemented | Highest evidence |",
        "|---|---:|---:|---:|---:|---|",
    ]
    for family in sorted(by_family):
        rows = by_family[family]
        counts = Counter(row["capability_status"] for row in rows)
        available = {row["evidence_tier"] for row in rows if row["capability_status"] == "implemented"}
        highest = next((tier for tier in tier_order if tier in available), "none")
        lines.append(
            f"| `{family}` | {len(rows)} | {counts['implemented']} | "
            f"{counts['rejected_by_design']} | {counts['not_implemented']} | "
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
        "This retains the original whole-package map. Its missing-response "
        "column is regenerated from the corrected 18-route ledger.",
        "",
        corrected_family_map_markdown(missing).rstrip(),
        "",
    ])
    return "\n".join(lines)


def surface_html(
    cells: list[dict[str, str]], evidence: list[dict[str, str]]
) -> str:
    model = sorted(
        (row for row in cells if row["axis"] == "model_surface"),
        key=lambda row: int(row["source_order"]),
    )
    missing = sorted(
        (row for row in cells if row["axis"] == "missing_response"),
        key=lambda row: int(row["model_type"]),
    )
    evidence_by_id = {row["evidence_id"]: row for row in evidence}
    status = Counter(row["capability_status"] for row in model)
    tiers = Counter(
        row["evidence_tier"] for row in model if row["capability_status"] == "implemented"
    )
    missing_gates = Counter(row["test_gate"] for row in missing)
    verified_missing = sum(int(row["test_gate"][1:]) >= 3 for row in missing)
    cards = []
    for row in missing:
        gate_num = int(row["test_gate"][1:])
        state_class = f"g{gate_num}"
        evidence_row = evidence_by_id[row["primary_evidence_id"]]
        link = evidence_href(evidence_row["path_or_url"])
        verified = '<span class="verified" aria-label="verified">✓ verified</span>' if gate_num >= 3 else ""
        cards.append(f"""
<article class="route-card {state_class}" id="route-{html.escape(row['family_route'].replace('_', '-'))}">
  <div class="route-head"><code>{html.escape(row['family_route'])}</code><span class="gate">{row['test_gate']}</span></div>
  <div class="route-state">{html.escape(row['capability_status'].replace('_', ' '))} · {html.escape(row['work_status'].replace('_', ' '))} {verified}</div>
  <div class="gate-track" aria-label="Evidence gate {gate_num} of 5"><span style="width:{gate_num * 20}%"></span></div>
  <p>{html.escape(row['claim_boundary'])}</p>
  <p class="next"><strong>Next:</strong> {html.escape(row['next_gate'])}</p>
  <a href="{html.escape(link)}">Evidence: {html.escape(evidence_row['path_or_url'])}</a>
</article>""")
    model_data = json.dumps([
        {key: row[key] for key in (
            "cell_id", "family_route", "route_variant", "dpar", "effect_type",
            "structure_provider", "dimension", "q_gate", "estimator",
            "capability_status", "evidence_tier", "claim_boundary",
            "primary_evidence_id",
        )}
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
        f"<td><span class=\"pill\">{html.escape(row['capability_status'].replace('_', ' '))}</span></td>"
        f"<td>{html.escape(row['evidence_tier'].replace('_', ' '))}</td>"
        f"<td>{html.escape(row['claim_boundary'])}</td>"
        "</tr>"
        for row in model
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
</style></head><body><a class="skip" href="#missing-response">Skip to capability content</a><main class="page">
<div class="topline"><div class="eyebrow">drmTMB · generated capability ledger · MR-T0</div><button id="theme" type="button" aria-label="Toggle light and dark theme">Theme</button></div>
<h1>Capability surface</h1>
<p class="lede">One model census, one separate missing-response execution board, and no inherited ticks. The ledger distinguishes code admission, validation work, and inferential evidence.</p>
<nav class="jump" aria-label="Capability surface sections"><a href="#missing-response">Missing-response board</a><a href="#model-cells">Detailed cells</a><a href="#family-capability">Per-family map</a></nav>
<p class="scope"><strong>Scope:</strong> 668 model-surface cells plus 18 missing-response routes. A missing-response ✓ appears only at G3 recovery or above; it never promotes the model's separate inference tier.</p>
<section class="stats" aria-label="Capability summary">
<div class="stat"><b>{len(model)}</b><span>model cells</span></div><div class="stat"><b>{len(missing)}</b><span>missing-response routes</span></div>
<div class="stat"><b>{status['implemented']}</b><span>implemented model cells</span></div><div class="stat"><b>{tiers['inference_ready_with_caveats']}</b><span>inference-ready cells</span></div>
<div class="stat"><b>{missing_gates['G1']}</b><span>routes at G1</span></div><div class="stat"><b>{verified_missing}</b><span>routes verified at G3+</span></div>
</section>
<h2 id="missing-response">Missing-response execution board</h2>
<p>G0 rejected · G1 implemented · G2 masking validated · G3 recovery · G4 interval feasible · G5 inference-ready.</p>
<div class="legend"><span><i style="background:var(--amber)"></i>implemented, audit pending</span><span><i style="background:var(--red)"></i>rejected, planned</span><span><i style="background:var(--green)"></i>verified only at G3+</span></div>
<section class="routes" aria-label="18 missing-response routes">{''.join(cards)}</section>
<h2 id="model-cells">Detailed model surface</h2>
<p class="muted">These 668 cells retain the existing model/inference census. Missing-response progress is not folded into these tiers.</p>
<div class="filters" role="search"><label>Route <select id="family"><option value="">All</option></select></label><label>Status <select id="status"><option value="">All</option></select></label><label>Search <input id="query" type="search" placeholder="parameter, provider, evidence…"></label><button id="clear" type="button">Clear</button></div>
<div id="count" class="muted" aria-live="polite"></div>
<div class="table-wrap"><table><caption>Generated 668-cell model capability census</caption><thead><tr><th scope="col">Cell</th><th scope="col">Route</th><th scope="col">Variant</th><th scope="col">dpar</th><th scope="col">Effect</th><th scope="col">Provider</th><th scope="col">Estimator</th><th scope="col">Status</th><th scope="col">Evidence tier</th><th scope="col">Claim boundary</th></tr></thead><tbody id="rows">{initial_model_rows}</tbody></table></div>
<h2 id="family-capability">Per-family capability reference</h2>
<p class="muted">The original whole-package map is retained here. It summarizes distributional parameters, fixed and random effects, structured providers, REML, inference maturity, and both missing-data axes. The missing-response column now follows the corrected 18-route ledger.</p>
<div class="family-wrap"><table class="family-map"><caption>Whole-package per-family capability map</caption><thead><tr><th scope="col">Family</th><th scope="col">dpars</th><th scope="col">Fixed</th><th scope="col">Random (int / slope)</th><th scope="col">Structured — phylo / spatial / animal / relmat</th><th scope="col">REML</th><th scope="col">Inference tier</th><th scope="col">Missing response</th><th scope="col">Missing predictor mi()</th></tr></thead><tbody>{family_map_html(missing)}</tbody></table></div>
<footer>Generated {DATE} by <code>tools/capability_ledger.py</code> from <code>docs/dev-log/dashboard/capability-ledger/</code>. Do not hand-edit generated outputs.</footer>
</main><script>const DATA={model_data};
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}}[c]));
const fam=document.querySelector('#family'),status=document.querySelector('#status'),query=document.querySelector('#query'),body=document.querySelector('#rows'),count=document.querySelector('#count');
for(const v of [...new Set(DATA.map(r=>r.family_route))].sort()) fam.insertAdjacentHTML('beforeend',`<option>${{esc(v)}}</option>`);
for(const v of [...new Set(DATA.map(r=>r.capability_status))].sort()) status.insertAdjacentHTML('beforeend',`<option>${{esc(v)}}</option>`);
function render(){{const q=query.value.toLowerCase();const out=DATA.filter(r=>(!fam.value||r.family_route===fam.value)&&(!status.value||r.capability_status===status.value)&&(!q||Object.values(r).join(' ').toLowerCase().includes(q)));count.textContent=`${{out.length}} of 668 cells`;body.innerHTML=out.map(r=>`<tr><td><code>${{esc(r.cell_id)}}</code></td><td><code>${{esc(r.family_route)}}</code></td><td>${{esc(r.route_variant)}}</td><td>${{esc(r.dpar)}}</td><td>${{esc(r.effect_type)}}</td><td>${{esc(r.structure_provider)}}</td><td>${{esc(r.estimator)}}</td><td><span class="pill">${{esc(r.capability_status.replaceAll('_',' '))}}</span></td><td>${{esc(r.evidence_tier.replaceAll('_',' '))}}</td><td>${{esc(r.claim_boundary)}}</td></tr>`).join('')}}
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
    model = model_projection(cells)
    missing = sorted(
        (row for row in cells if row["axis"] == "missing_response"),
        key=lambda row: int(row["model_type"]),
    )
    result: dict[Path, bytes] = {
        CENSUS / "_master.tsv": legacy_tsv_bytes(MODEL_FIELDS, model),
        CENSUS / "_widget_data.json": compact_json_bytes(widget_value(model)),
        ROOT / "docs/dev-log/dashboard/capability-surface.md": surface_markdown(cells, evidence).encode("utf-8"),
        ROOT / "docs/dev-log/dashboard/capability-surface.html": surface_html(cells, evidence).encode("utf-8"),
        ROOT / "vignettes/includes/capability-ledger-missing-response.md": missing_markdown(missing, compact=True).encode("utf-8"),
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
    action.add_argument("--write", action="store_true")
    action.add_argument("--check", action="store_true")
    action.add_argument("--summary", action="store_true")
    args = parser.parse_args()
    if args.bootstrap:
        bootstrap()
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
