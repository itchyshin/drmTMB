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
CANONICAL_AGENTS = {
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
    "Hopper",
    "Codex",
    "GitHub",
    "Ayumi",
    "Dashboard",
    "Issue ledger",
    "Status matrix",
}


def read_json(path: pathlib.Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


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
        if name not in CANONICAL_AGENTS:
            errors.append(f"non-canonical agent name in team list: {name!r}")
    agent_names = {agent.get("name") for agent in status.get("agents", [])}
    missing_standing = sorted(STANDING_REVIEW_NAMES - agent_names)
    if missing_standing:
        errors.append(f"team list missing standing review names: {', '.join(missing_standing)}")

    for section in ("active_work", "activity", "blockers", "evidence"):
        for item in status.get(section, []):
            who = item.get("who") or item.get("kind")
            if who and who not in CANONICAL_AGENTS and section != "blockers":
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
            if owner not in CANONICAL_AGENTS:
                errors.append(f"{row_id}: non-canonical owner {owner!r}")
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

    if errors:
        for error in errors:
            print(f"mission-control validation error: {error}", file=sys.stderr)
        return 1

    print(
        "mission_control_ok: "
        f"{expected_metrics['verified']}/{expected_metrics['total']} banked_or_verified, "
        f"{expected_metrics['active']} active, "
        f"{len(matrix)} matrix rows, "
        f"{len(finish_board)} finish rows"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
