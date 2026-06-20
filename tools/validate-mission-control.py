#!/usr/bin/env python3
"""Validate the local drmTMB mission-control dashboard files.

This script deliberately uses only the Python standard library. It is a
developer guard for status drift; it is not part of the R package runtime.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
DASHBOARD = ROOT / "docs" / "dev-log" / "dashboard"
DESIGN_MATRIX = ROOT / "docs" / "design" / "168-r-julia-finish-capability-matrix.md"
GATE_REGISTRY = DASHBOARD / "julia-gates.tsv"
CAPABILITY_REGISTRY = DASHBOARD / "julia-capabilities.tsv"
CLAIM_MATRIX_REF = "docs/design/168-r-julia-finish-capability-matrix.md"
PUBLIC_CLAIM_REFERENCE_FILES = (
    ROOT / "README.md",
    ROOT / "ROADMAP.md",
    ROOT / "NEWS.md",
    ROOT / "_pkgdown.yml",
    ROOT / "docs" / "dev-log" / "dashboard" / "README.md",
    ROOT / "docs" / "dev-log" / "known-limitations.md",
)
PUBLIC_CLAIM_SCAN_FILES = PUBLIC_CLAIM_REFERENCE_FILES + (
    ROOT / "docs" / "design" / "168-r-julia-finish-capability-matrix.md",
)
RELEASE_READY_PATTERN = re.compile(
    r"\b(release[- ]ready|ready (?:for|to) release|CRAN[- ]ready)\b",
    re.I,
)
RESERVED_PUBLIC_CONTROL_PATTERN = re.compile(r"\bengine_control\b")
# Accelerator / hardware vocabulary must stay guarded as planned/unsupported
# until benchmark evidence exists. Deliberately excludes the overloaded token
# "backend", which denotes the parallel-execution mode (backend = "multicore" /
# "none") and the TMB precision backend, not a hardware accelerator.
ACCELERATOR_CLAIM_PATTERN = re.compile(
    r"\b(GPU|CUDA|cuDNN|TPU|accelerator|compute[- ]target|offload)\b",
    re.I,
)

SLICE_STATUSES = {"queued", "active", "blocked", "verified", "banked", "deferred"}
PHASE_STATUSES = SLICE_STATUSES
MATRIX_STATUSES = {"covered", "partial", "experimental", "planned", "unsupported"}
FINISH_STATUSES = SLICE_STATUSES | MATRIX_STATUSES | {"active", "blocked", "guard"}
FINISH_LANES = {
    "Critical Path",
    "Issue Ledger",
    "Twin Claim Board",
    "Cross-Package Lessons",
    "Evidence Gates",
    "Release Readiness",
}
FINISH_STATUS_FIELDS = (
    "status",
    "engine_tmb",
    "engine_julia",
    "point",
    "wald",
    "profile",
    "bootstrap",
    "tests",
    "docs",
    "visual",
    "simulation",
    "release_gate",
)
GATE_FIELDS = (
    "gate_id",
    "route",
    "guard",
    "family_type",
    "syntax",
    "r_bridge_status",
    "drmjl_status",
    "message_pattern",
    "review_due",
    "evidence_url",
    "action",
    "evidence",
    "issue",
)
CAPABILITY_FIELDS = (
    "capability_id",
    "route",
    "syntax",
    "r_bridge_status",
    "drmjl_status",
    "claim_status",
    "evidence_url",
    "claim_boundary",
    "next_action",
    "issue",
)
R_BRIDGE_STATUSES = {"supported", "experimental", "intentional_error", "planned", "unsupported"}
CAPABILITY_CLAIM_STATUSES = MATRIX_STATUSES | {"blocked"}
EVIDENCE_STATUSES = {"verified", "banked", "covered"}
STANDING_REVIEW_NAMES = {
    "Ada",
    "Boole",
    "Gauss",
    "Noether",
    "Darwin",
    "Florence",
    "Fisher",
    "Pat",
    "Jason",
    "Curie",
    "Emmy",
    "Grace",
    "Rose",
}
SYSTEM_ACTORS = {
    "Codex",
    "GitHub",
    "Ayumi",
    "Dashboard",
    "Issue ledger",
    "Status matrix",
}
CANONICAL_ACTORS = STANDING_REVIEW_NAMES | SYSTEM_ACTORS


def owner_names(owner: str | None) -> list[str]:
    if not owner:
        return []
    normalized = owner.replace(",", "+")
    return [part.strip() for part in normalized.split("+") if part.strip()]


def read_json(path: pathlib.Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def read_tsv(path: pathlib.Path) -> list[dict[str, str]]:
    import csv

    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE))


def rel_path(path: pathlib.Path) -> str:
    return path.relative_to(ROOT).as_posix()


def text_line_number(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def local_documenter_claim_paths() -> list[pathlib.Path]:
    """Return local Documenter.jl claim files if this repo ever grows them."""

    paths: list[pathlib.Path] = []
    docs_src = ROOT / "docs" / "src"
    if docs_src.exists():
        paths.extend(path for path in docs_src.rglob("*") if path.is_file())
    for name in ("make.jl", "Documenter.toml", "Project.toml"):
        path = ROOT / "docs" / name
        if path.exists():
            paths.append(path)
    return sorted(set(paths))


def public_claim_scan_paths() -> list[pathlib.Path]:
    paths = list(PUBLIC_CLAIM_SCAN_FILES)
    paths.extend(sorted((ROOT / "vignettes").glob("*.Rmd")))
    paths.extend(local_documenter_claim_paths())
    return [path for path in sorted(set(paths)) if path.exists()]


def matrix_row_count_from_design(path: pathlib.Path) -> int:
    text = path.read_text(encoding="utf-8")
    match = re.search(r"## Finish Matrix\n(?P<table>.*?)\n## Issue-Led", text, re.S)
    if not match:
        return -1
    rows = []
    for line in match.group("table").splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        if set(line.replace("|", "").replace(" ", "")) == {"-"}:
            continue
        if line.startswith("| Area "):
            continue
        rows.append(line)
    return len(rows)


def main() -> int:
    errors: list[str] = []
    status = read_json(DASHBOARD / "status.json")
    read_json(DASHBOARD / "sweep.json")
    gate_rows = read_tsv(GATE_REGISTRY)
    capability_rows = read_tsv(CAPABILITY_REGISTRY)
    documenter_paths = local_documenter_claim_paths()

    version = (DASHBOARD / "version.txt").read_text(encoding="utf-8").strip()
    index = (DASHBOARD / "index.html").read_text(encoding="utf-8")
    build = re.search(r'const BUILD = "([^"]+)"', index)
    if not build:
        errors.append("index.html has no BUILD constant")
    elif build.group(1) != version:
        errors.append(f"version.txt is {version!r}, but index.html BUILD is {build.group(1)!r}")

    slice_counts = {key: 0 for key in ("verified", "active", "blocked", "deferred")}
    total_slices = 0
    for phase in status.get("phases", []):
        phase_status = phase.get("status")
        if phase_status not in PHASE_STATUSES:
            errors.append(f"{phase.get('id', '<phase>')} has invalid status {phase_status!r}")
        for owner in owner_names(phase.get("owner")):
            if owner not in STANDING_REVIEW_NAMES:
                errors.append(f"{phase.get('id', '<phase>')} has non-standing owner {owner!r}")
        slices = phase.get("slices", [])
        total_slices += len(slices)
        done = 0
        for item in slices:
            item_status = item.get("status")
            if item_status not in SLICE_STATUSES:
                errors.append(f"{phase.get('id', '<phase>')} slice {item.get('name')!r} has invalid status {item_status!r}")
            if item_status in {"verified", "banked"}:
                done += 1
                slice_counts["verified"] += 1
                if not any(item.get(key) for key in ("evidence", "issue", "url")):
                    errors.append(f"verified/banked slice lacks evidence: {item.get('name')!r}")
            elif item_status in slice_counts:
                slice_counts[item_status] += 1
        expected_counts = f"{done}/{len(slices)}"
        if phase.get("counts") != expected_counts:
            errors.append(
                f"{phase.get('id', '<phase>')} counts are {phase.get('counts')!r}; expected {expected_counts!r}"
            )

    metrics = status.get("metrics", {})
    expected_metrics = {
        "verified": slice_counts["verified"],
        "active": slice_counts["active"],
        "blocked": slice_counts["blocked"],
        "deferred": slice_counts["deferred"],
        "total": total_slices,
    }
    for key, expected in expected_metrics.items():
        if metrics.get(key) != expected:
            errors.append(f"metrics.{key} is {metrics.get(key)!r}; expected {expected!r}")

    for agent in status.get("agents", []):
        name = agent.get("name")
        if name not in STANDING_REVIEW_NAMES:
            errors.append(f"non-standing review name in team list: {name!r}")
    agent_names = {agent.get("name") for agent in status.get("agents", [])}
    missing_standing = sorted(STANDING_REVIEW_NAMES - agent_names)
    if missing_standing:
        errors.append(f"team list missing standing review names: {', '.join(missing_standing)}")
    extra_team = sorted(agent_names - STANDING_REVIEW_NAMES)
    if extra_team:
        errors.append(f"team list has non-standing names: {', '.join(extra_team)}")

    for section in ("active_work", "activity", "blockers", "evidence"):
        for item in status.get(section, []):
            who = item.get("who") or item.get("kind")
            if who and who not in CANONICAL_ACTORS and section != "blockers":
                errors.append(f"non-canonical name in {section}: {who!r}")

    matrix = status.get("matrix", [])
    design_count = matrix_row_count_from_design(DESIGN_MATRIX)
    if design_count >= 0 and len(matrix) != design_count:
        errors.append(f"dashboard matrix has {len(matrix)} rows; design matrix has {design_count}")
    matrix_fields = (
        "engine",
        "bridge",
        "point",
        "wald",
        "profile",
        "bootstrap",
        "docs",
        "visual",
        "simulation",
        "release",
    )
    for row in matrix:
        row_name = row.get("area", "<matrix row>")
        has_covered = False
        for field in matrix_fields:
            value = row.get(field)
            if value not in MATRIX_STATUSES:
                errors.append(f"{row_name}: {field} has invalid status {value!r}")
            has_covered = has_covered or value == "covered"
        if has_covered and not (row.get("evidence") or row.get("evidence_url")):
            errors.append(f"{row_name}: covered row lacks evidence")

    finish_board = status.get("finish_board", [])
    lanes_seen: set[str] = set()
    row_ids: set[str] = set()
    for row in finish_board:
        row_id = row.get("id", "<finish row>")
        if not row.get("id"):
            errors.append("finish_board row lacks id")
        elif row_id in row_ids:
            errors.append(f"duplicate finish_board id: {row_id}")
        row_ids.add(row_id)
        lane = row.get("lane")
        if lane not in FINISH_LANES:
            errors.append(f"{row_id}: invalid finish-board lane {lane!r}")
        else:
            lanes_seen.add(lane)
        issue = row.get("issue")
        if issue and not re.match(r"^https://github\.com/[^/]+/[^/]+/(issues|pull)/[0-9]+", issue):
            errors.append(f"{row_id}: issue is not a GitHub issue/PR URL: {issue!r}")
        owners = row.get("owners", [])
        if not owners:
            errors.append(f"{row_id}: finish-board row has no owners")
        for owner in owners:
            if owner not in STANDING_REVIEW_NAMES:
                errors.append(f"{row_id}: non-standing owner {owner!r}")
        has_evidence_status = False
        for field in FINISH_STATUS_FIELDS:
            value = row.get(field)
            if value not in FINISH_STATUSES:
                errors.append(f"{row_id}: {field} has invalid status {value!r}")
            has_evidence_status = has_evidence_status or value in EVIDENCE_STATUSES
        if has_evidence_status and not (row.get("evidence_url") or row.get("evidence")):
            errors.append(f"{row_id}: verified/banked/covered finish row lacks evidence")
        if not row.get("last_verified"):
            errors.append(f"{row_id}: finish-board row lacks last_verified")
    missing_lanes = sorted(FINISH_LANES - lanes_seen)
    if missing_lanes:
        errors.append(f"finish_board missing lanes: {', '.join(missing_lanes)}")

    gate_ids: set[str] = set()
    if not gate_rows:
        errors.append("julia-gates.tsv has no gate rows")
    for row in gate_rows:
        row_id = row.get("gate_id", "<gate row>")
        if set(row.keys()) != set(GATE_FIELDS):
            errors.append(f"{row_id}: julia-gates.tsv fields do not match the registry contract")
        if not row.get("gate_id"):
            errors.append("julia-gates.tsv row lacks gate_id")
        elif row_id in gate_ids:
            errors.append(f"duplicate Julia gate id: {row_id}")
        gate_ids.add(row_id)
        for field in GATE_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("r_bridge_status") != "intentional_error":
            errors.append(f"{row_id}: r_bridge_status is not intentional_error")
        if row.get("action") != "error":
            errors.append(f"{row_id}: action is not error")
        if row.get("issue") != "drmTMB#544":
            errors.append(f"{row_id}: issue is not drmTMB#544")
        if not re.match(r"^https://github\.com/[^/]+/[^/]+/issues/[0-9]+", row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url is not a GitHub issue URL")

    capability_ids: set[str] = set()
    if not capability_rows:
        errors.append("julia-capabilities.tsv has no capability rows")
    for row in capability_rows:
        row_id = row.get("capability_id", "<capability row>")
        if set(row.keys()) != set(CAPABILITY_FIELDS):
            errors.append(f"{row_id}: julia-capabilities.tsv fields do not match the comparison contract")
        if not row.get("capability_id"):
            errors.append("julia-capabilities.tsv row lacks capability_id")
        elif row_id in capability_ids:
            errors.append(f"duplicate Julia capability id: {row_id}")
        capability_ids.add(row_id)
        for field in CAPABILITY_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("r_bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid r_bridge_status {row.get('r_bridge_status')!r}")
        if row.get("claim_status") not in CAPABILITY_CLAIM_STATUSES:
            errors.append(f"{row_id}: invalid claim_status {row.get('claim_status')!r}")
        if not re.match(r"^https://github\.com/[^/]+/[^/]+/issues/[0-9]+", row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url is not a GitHub issue URL")
        if not re.match(r"^[A-Za-z0-9]+#[0-9]+$", row.get("issue", "")):
            errors.append(f"{row_id}: issue is not a compact issue label")

    for path in PUBLIC_CLAIM_REFERENCE_FILES:
        if not path.exists():
            errors.append(f"public claim reference file is missing: {rel_path(path)}")
            continue
        text = path.read_text(encoding="utf-8")
        if CLAIM_MATRIX_REF not in text:
            errors.append(f"{rel_path(path)} does not link the finish capability matrix")
    for path in documenter_paths:
        text = path.read_text(encoding="utf-8", errors="ignore")
        if CLAIM_MATRIX_REF not in text:
            errors.append(f"{rel_path(path)} local Documenter claim file does not link the finish capability matrix")

    for path in public_claim_scan_paths():
        if path == DESIGN_MATRIX:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in RELEASE_READY_PATTERN.finditer(text):
            line = text_line_number(text, match.start())
            errors.append(
                f"{rel_path(path)}:{line} uses release-ready language outside the release gate"
            )
        for match in RESERVED_PUBLIC_CONTROL_PATTERN.finditer(text):
            line = text_line_number(text, match.start())
            errors.append(f"{rel_path(path)}:{line} exposes reserved engine_control language")
        for accel_line_no, accel_line_text in enumerate(text.splitlines(), start=1):
            if ACCELERATOR_CLAIM_PATTERN.search(accel_line_text) and not re.search(
                r"\b(planned|unsupported)\b", accel_line_text, re.I
            ):
                errors.append(
                    f"{rel_path(path)}:{accel_line_no} claims GPU/accelerator "
                    "capability without a 'planned' or 'unsupported' guard"
                )

    if errors:
        for error in errors:
            print(f"mission-control validation error: {error}", file=sys.stderr)
        return 1

    print(
        "mission_control_ok: "
        f"{expected_metrics['verified']}/{expected_metrics['total']} banked_or_verified, "
        f"{expected_metrics['active']} active, "
        f"{len(matrix)} matrix rows, "
        f"{len(finish_board)} finish rows, "
        f"{len(gate_rows)} Julia gate rows, "
        f"{len(capability_rows)} Julia capability rows"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
