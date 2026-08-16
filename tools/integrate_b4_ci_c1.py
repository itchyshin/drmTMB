#!/usr/bin/env python3
"""Apply or verify the source-bound B4-CI C1 ledger integration.

This tool intentionally knows one approved cohort only.  It never selects cells
by a broad status or family rule: C1 is the ordered allowlist below, bound to
the retained source commit approved in the Arc 0 packet.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import subprocess

import b4_ci_guard
from pathlib import Path


SOURCE_COMMIT = "574c1108e16e3b0fe4ba88e254a34673508db901"
BASE_COMMIT = "7c3bc8b3f917b5d5c00099b1dee49ff5bbf70500"
PACKET_SHA256 = "e7bfdd77ec92351df7ea0f7a874eba69e7f9aab9e8bcf6abc0c97b5bb7d97ef7"
ALLOWLIST_SHA256 = "659f5a660c60dc48e67981406e9d9e68af9565b52fd19bf00f115bd715e4f907"
# Re-frozen 2026-08-15 (was 9fcd839a8f5f15d18016c0280193a5de928eae5af98f53e672948ce6fc71a7ac).
# The interval-claim truth audit appended the spatial fixed-range conditioning to
# mc-0124's claim_boundary. This guard fired correctly, and the re-freeze was gated on
# proving it masks nothing else: of the four B3 rows, mc-0102/mc-0146/mc-0168 are
# byte-IDENTICAL to origin/main, and mc-0124 differs in claim_boundary ONLY, as a pure
# append (new == old + the sentence). Tier, target, scale and evidence are unchanged.
# Re-freeze a B3 row only after re-running that same field-level diff.
B3_BASE_ROWS_SHA256 = "31c3c7addb28cd200b15f8047d795d6e8707d75e5256ae27d6c7e7e5851de344"
# Re-frozen 2026-08-15 (2nd time today; was 396b4b9452c9408a3ec09dd440b3dc26dd42e4c64033e9375b487fc49032096a).
# The `location_checked` column was appended to CELL_FIELDS, which changes every row's
# bytes and therefore every row digest. Gated on the same proof as the B3 re-freeze:
# a field-level diff of all 24 C1 rows, all 4 B3 rows and all 4 EXCLUDED rows against the
# prior commit found NO pre-existing field changed at all -- the digests move solely
# because a column was added. Re-freeze a pinned digest only after re-running that diff.
C1_CELL_ROWS_SHA256 = "5e9f825e5abc9498dd7ba8970d9df4177d9708cddcc0d3dd5eecc1b183d877a9"
# Identity (not full row) of the four hard-excluded neighbours. Their evidence-bearing
# fields legitimately move under later arcs -- mc-0207 was split by Arc 4b and mc-0269
# promoted by the Arc 1 REML-slope campaign -- but their identity never may. Paired with
# a provenance check below, this needs no BASE_COMMIT lookup, which keeps check_current()
# runnable in a shallow CI clone.
EXCLUDED_IDENTITY_SHA256 = "73b541a0a943a5289c9b57910fe61356a88a0464f38cef084eb2eadc54685041"
C1_EVIDENCE_ROWS_SHA256 = "49a27d57dbff815e38700ed29f8c7947af55e219d3bde2e0b48dc2bc4c0e5937"
C1_TRANSITION_ROWS_SHA256 = "5fcd085ddccfc444744d1a547bb6f23596abf33c2e87138d0838e3613a00b0ab"
CELL_IDS = """
mc-0005 mc-0007 mc-0059 mc-0184 mc-0185 mc-0187 mc-0188 mc-0203
mc-0204 mc-0225 mc-0265 mc-0267 mc-0270 mc-0271 mc-0380 mc-0401
mc-0402 mc-0403 mc-0429 mc-0431 mc-0463 mc-0511 mc-0538 mc-0567
""".split()
B3_IDS = {"mc-0102", "mc-0124", "mc-0146", "mc-0168"}
EXCLUDED_IDS = {"mc-0182", "mc-0183", "mc-0207", "mc-0269"}
ABSOLUTE_PATH_PREFIXES = (
    "/Users/z3437171/.codex/worktrees/f9e4/drmTMB/docs/",
    "/home/snakagaw/hsq_work/drmTMB-lane-b-ordinary-0c1f39d86-git/docs/",
)
LEDGER = Path("docs/dev-log/dashboard/capability-ledger")
MANIFEST = Path("docs/dev-log/canonical-integration/2026-08-01-b4-ci-c1-manifest.tsv")


def fail(message: str) -> None:
    raise SystemExit(f"B4-CI C1: {message}")


def git_bytes(spec: str) -> bytes:
    return subprocess.check_output(["git", "show", spec])


def source_rows(name: str) -> list[dict[str, str]]:
    return list(csv.DictReader(io.StringIO(git_bytes(f"{SOURCE_COMMIT}:{LEDGER / name}").decode()), delimiter="\t"))


def local_rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def write_rows(path: Path, rows: list[dict[str, str]]) -> None:
    with path.open(newline="") as handle:
        header = next(csv.reader(handle, delimiter="\t"))
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=header, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def normalized_path(path: str) -> str:
    if path.startswith("/"):
        for prefix in ABSOLUTE_PATH_PREFIXES:
            if path.startswith(prefix):
                return "docs/" + path.removeprefix(prefix)
        fail(f"absolute source path is not in the frozen B4-CI replacement map: {path}")
    return path


def parse_tsv_bytes(data: bytes) -> list[dict[str, str]]:
    return list(csv.DictReader(io.StringIO(data.decode()), delimiter="\t"))


def finite_ordered(value: str, other: str, context: str) -> None:
    import math

    lower, upper = float(value), float(other)
    if not math.isfinite(lower) or not math.isfinite(upper) or not lower < upper:
        fail(f"{context} is not a finite ordered interval")


def validate_profile_triplet(
    cell: dict[str, str], receipt: dict[str, str], trace: list[dict[str, str]], interval: list[dict[str, str]]
) -> None:
    """Reject target, scale, boundary, and interval-contract drift in C1 evidence."""
    cell_id = cell["cell_id"]
    target_id = receipt.get("target_id", "")
    if receipt.get("cell_id") != cell_id or not target_id.startswith(f"{cell_id}::"):
        fail(f"receipt target binding mismatch for {cell_id}")
    if receipt.get("profile_parameter") != target_id.split("::", 1)[1]:
        fail(f"receipt profile parameter mismatch for {cell_id}")
    receipt_scale = receipt.get("true_parameter_scale", "")
    trace_scale = "link" if receipt_scale.startswith("link:") else "response"
    if not receipt_scale:
        fail(f"receipt reporting scale mismatch for {cell_id}")
    if any(receipt.get(field) != expected for field, expected in {
        "conf_status": "profile", "profile_engine": "tmbprofile", "convergence": "0",
        "pdHess": "TRUE", "profile_boundary": "FALSE", "clamp_limited": "FALSE",
        "trace_complete": "TRUE",
    }.items()):
        fail(f"receipt does not establish an unclamped completed profile for {cell_id}")
    finite_ordered(receipt["lower"], receipt["upper"], f"receipt {cell_id}")
    if not trace or not interval:
        fail(f"profile artifacts are empty for {cell_id}")
    if any(row.get("cell_id") != cell_id or row.get("target_id") != target_id
           or row.get("parm") != receipt["profile_parameter"]
           or row.get("scale") != trace_scale for row in trace):
        fail(f"trace target or reporting-scale mismatch for {cell_id}")
    if any(row.get("conf.low") != receipt["lower"] or row.get("conf.high") != receipt["upper"]
           or row.get("conf.status") != "profile" or row.get("profile_pass") != "profile"
           for row in trace):
        fail(f"trace interval contract mismatch for {cell_id}")
    if len(interval) != 1 or interval[0].get("cell_id") != cell_id or interval[0].get("target_id") != target_id:
        fail(f"interval target binding mismatch for {cell_id}")
    if (interval[0].get("lower"), interval[0].get("upper"), interval[0].get("profile_engine")) != (
        receipt["lower"], receipt["upper"], receipt["profile_engine"],
    ):
        fail(f"interval endpoint or engine mismatch for {cell_id}")


def source_closure(evidence: list[dict[str, str]], cells: list[dict[str, str]]) -> list[dict[str, str]]:
    closure: list[dict[str, str]] = []
    for record in evidence:
        refs = record["path_or_url"].split(";")
        if len(refs) != 1:
            fail(f"C1 evidence {record['evidence_id']} does not name one receipt")
        receipt = normalized_path(refs[0])
        receipt_rows = parse_tsv_bytes(git_bytes(f"{SOURCE_COMMIT}:{receipt}"))
        if len(receipt_rows) != 1 or receipt_rows[0]["cell_id"] != record["cell_id"]:
            fail(f"receipt does not bind {record['evidence_id']} to {record['cell_id']}")
        cell = next(row for row in cells if row["cell_id"] == record["cell_id"])
        trace_path, interval_path = (normalized_path(receipt_rows[0][field]) for field in ("trace_path", "interval_path"))
        validate_profile_triplet(
            cell, receipt_rows[0], parse_tsv_bytes(git_bytes(f"{SOURCE_COMMIT}:{trace_path}")),
            parse_tsv_bytes(git_bytes(f"{SOURCE_COMMIT}:{interval_path}")),
        )
        for role, path in (("receipt", receipt), ("trace", receipt_rows[0]["trace_path"]), ("interval", receipt_rows[0]["interval_path"])):
            canonical = normalized_path(path)
            data = git_bytes(f"{SOURCE_COMMIT}:{canonical}")
            closure.append({
                "cell_id": record["cell_id"],
                "evidence_id": record["evidence_id"],
                "role": role,
                "path": canonical,
                "source_blob_sha256": hashlib.sha256(data).hexdigest(),
            })
    if len(closure) != 72 or len({row["path"] for row in closure}) != 72:
        fail("C1 artifact closure is not exactly 24 receipt/trace/interval triplets")
    return closure


def selected_source() -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, str]], list[dict[str, str]]]:
    if hashlib.sha256(("\n".join(CELL_IDS) + "\n").encode()).hexdigest() != ALLOWLIST_SHA256:
        fail("C1 allowlist hash mismatch")
    if len(CELL_IDS) != 24 or len(set(CELL_IDS)) != 24:
        fail("C1 allowlist cardinality or uniqueness mismatch")
    if set(CELL_IDS) & (B3_IDS | EXCLUDED_IDS):
        fail("C1 allowlist contains a preserved or excluded cell")
    cells = {row["cell_id"]: row for row in source_rows("cells.tsv")}
    selected_cells = [cells[cell_id] for cell_id in CELL_IDS]
    if any(row["evidence_tier"] != "interval_feasible" or row["work_status"] != "verified" for row in selected_cells):
        fail("source C1 cells are not verified interval_feasible")
    evidence = {row["evidence_id"]: row for row in source_rows("evidence.tsv")}
    selected_evidence = [evidence[row["primary_evidence_id"]] for row in selected_cells]
    if len({row["evidence_id"] for row in selected_evidence}) != 24:
        fail("C1 primary evidence is not one-to-one")
    transitions = {
        row["cell_id"]: row
        for row in source_rows("transitions.tsv")
        if row["cell_id"] in CELL_IDS and row["from_work_status"] == "verified"
        and row["to_work_status"] == "verified"
    }
    selected_transitions = [transitions[cell_id] for cell_id in CELL_IDS]
    for cell, transition in zip(selected_cells, selected_transitions):
        if transition["evidence_ids"] != cell["primary_evidence_id"]:
            fail(f"transition/evidence mismatch for {cell['cell_id']}")
    return selected_cells, selected_evidence, selected_transitions, source_closure(selected_evidence, selected_cells)


def manifest_rows(closure: list[dict[str, str]]) -> list[dict[str, str]]:
    return [
        {
            "packet_sha256": PACKET_SHA256,
            "source_commit": SOURCE_COMMIT,
            "base_commit": BASE_COMMIT,
            "cohort": "C1",
            **row,
        }
        for row in closure
    ]


def b3_digest(cell_map: dict[str, dict[str, str]]) -> str:
    import json

    payload = json.dumps(
        [cell_map[cell_id] for cell_id in sorted(B3_IDS)],
        sort_keys=True,
        separators=(",", ":"),
    ).encode()
    return hashlib.sha256(payload).hexdigest()


def rows_digest(rows: list[dict[str, str]]) -> str:
    import json

    return hashlib.sha256(json.dumps(rows, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def apply() -> None:
    cells, evidence, transitions, closure = selected_source()
    local_cells = local_rows(LEDGER / "cells.tsv")
    local_by_id = {row["cell_id"]: row for row in local_cells}
    if any(local_by_id[cell_id]["evidence_tier"] not in {"point_fit_recovery", "diagnostic_only"} for cell_id in CELL_IDS):
        fail("destination C1 cells are not eligible pre-promotion tiers")
    base_b3 = {
        row["cell_id"]: row
        for row in csv.DictReader(
            io.StringIO(git_bytes(f"{BASE_COMMIT}:{LEDGER / 'cells.tsv'}").decode()), delimiter="\t"
        )
        if row["cell_id"] in B3_IDS
    }
    if {cell_id: local_by_id[cell_id] for cell_id in B3_IDS} != base_b3:
        fail("B3 differs from the frozen C1 base; do not overwrite it")
    source_by_id = {row["cell_id"]: row for row in cells}
    write_rows(LEDGER / "cells.tsv", [source_by_id.get(row["cell_id"], row) for row in local_cells])
    for filename, records, key in (("evidence.tsv", evidence, "evidence_id"), ("transitions.tsv", transitions, "transition_id")):
        local = local_rows(LEDGER / filename)
        present = {row[key] for row in local}
        if present & {row[key] for row in records}:
            fail(f"destination already contains a C1 {filename} record")
        write_rows(LEDGER / filename, local + records)
    for row in closure:
        target = Path(row["path"])
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(git_bytes(f"{SOURCE_COMMIT}:{row['path']}"))
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    fields = ["packet_sha256", "source_commit", "base_commit", "cohort", "cell_id", "evidence_id", "role", "path", "source_blob_sha256"]
    with MANIFEST.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(manifest_rows(closure))


def check() -> None:
    cells, evidence, transitions, closure = selected_source()
    local_cell_map = {row["cell_id"]: row for row in local_rows(LEDGER / "cells.tsv")}
    for source in cells:
        if local_cell_map.get(source["cell_id"]) != source:
            fail(f"cell does not exactly match source: {source['cell_id']}")
    base_b3 = {
        row["cell_id"]: row
        for row in csv.DictReader(
            io.StringIO(git_bytes(f"{BASE_COMMIT}:{LEDGER / 'cells.tsv'}").decode()), delimiter="\t"
        )
        if row["cell_id"] in B3_IDS
    }
    if {cell_id: local_cell_map[cell_id] for cell_id in B3_IDS} != base_b3:
        fail("B3 was changed from the frozen C1 base")
    local_evidence = {row["evidence_id"]: row for row in local_rows(LEDGER / "evidence.tsv")}
    local_transitions = {row["transition_id"]: row for row in local_rows(LEDGER / "transitions.tsv")}
    for source in evidence:
        if local_evidence.get(source["evidence_id"]) != source:
            fail(f"evidence does not exactly match source: {source['evidence_id']}")
    for source in transitions:
        if local_transitions.get(source["transition_id"]) != source:
            fail(f"transition does not exactly match source: {source['transition_id']}")
    expected_manifest = manifest_rows(closure)
    if not MANIFEST.exists() or local_rows(MANIFEST) != expected_manifest:
        fail("source manifest is absent or differs from the approved closure")
    for row in closure:
        target = Path(row["path"])
        if not target.exists() or hashlib.sha256(target.read_bytes()).hexdigest() != row["source_blob_sha256"]:
            fail(f"artifact blob differs from source: {row['path']}")
    if len([row for row in local_rows(LEDGER / "cells.tsv") if row["evidence_tier"] == "interval_feasible"]) < 72:
        fail("C1 interval_feasible baseline was lost")


def check_current() -> None:
    """CI-safe verification of the landed C1 packet without source-history access."""
    if hashlib.sha256(("\n".join(CELL_IDS) + "\n").encode()).hexdigest() != ALLOWLIST_SHA256:
        fail("C1 allowlist hash mismatch")
    cells = {row["cell_id"]: row for row in local_rows(LEDGER / "cells.tsv")}
    if b3_digest(cells) != B3_BASE_ROWS_SHA256:
        fail("B3 changed from the frozen C1 base")
    if rows_digest([cells[cell_id] for cell_id in CELL_IDS]) != C1_CELL_ROWS_SHA256:
        fail("C1 target, scale, or claim-boundary row drift")
    excluded_rows = [cells[cell_id] for cell_id in sorted(EXCLUDED_IDS)]
    if b4_ci_guard.identity_digest(excluded_rows) != EXCLUDED_IDENTITY_SHA256:
        fail("a hard-excluded C1 neighbour changed identity from the frozen base")
    if any(cells[cell_id]["evidence_tier"] != "interval_feasible" or cells[cell_id]["work_status"] != "verified" for cell_id in CELL_IDS):
        fail("C1 cell tier or work status drift")
    evidence = {row["evidence_id"]: row for row in local_rows(LEDGER / "evidence.tsv")}
    transitions = local_rows(LEDGER / "transitions.tsv")
    # A hard-excluded neighbour may move under a LATER arc, but only with a recorded
    # transition accounting for the evidence it now cites. C1 never claims one, so any
    # C1 transition here would itself be the violation.
    excluded_problems = b4_ci_guard.unaccounted_provenance(
        cell_ids=EXCLUDED_IDS,
        local_cells=cells,
        transitions=transitions,
        cohort_transition_ids={row["cell_id"] for row in transitions if row["cell_id"] in CELL_IDS},
    )
    if excluded_problems:
        fail(f"a hard-excluded C1 neighbour moved without provenance -- {b4_ci_guard.describe(excluded_problems)}")
    manifest = local_rows(MANIFEST) if MANIFEST.exists() else []
    if len(manifest) != 72 or {row["role"] for row in manifest} != {"receipt", "trace", "interval"}:
        fail("C1 manifest is incomplete")
    if any(row["packet_sha256"] != PACKET_SHA256 or row["source_commit"] != SOURCE_COMMIT or row["base_commit"] != BASE_COMMIT for row in manifest):
        fail("C1 manifest provenance drift")
    by_cell = {cell_id: [row for row in manifest if row["cell_id"] == cell_id] for cell_id in CELL_IDS}
    if any(len(rows) != 3 or {row["role"] for row in rows} != {"receipt", "trace", "interval"} for rows in by_cell.values()):
        fail("C1 manifest does not contain one artifact triplet per cell")
    for cell_id, rows in by_cell.items():
        evidence_id = cells[cell_id]["primary_evidence_id"]
        if evidence_id not in evidence or any(row["evidence_id"] != evidence_id for row in rows):
            fail(f"C1 evidence binding drift: {cell_id}")
        if not any(row["cell_id"] == cell_id and row["evidence_ids"] == evidence_id and row["from_work_status"] == "verified" and row["to_work_status"] == "verified" for row in transitions):
            fail(f"C1 transition binding drift: {cell_id}")
        for row in rows:
            target = Path(row["path"])
            if not target.exists() or hashlib.sha256(target.read_bytes()).hexdigest() != row["source_blob_sha256"]:
                fail(f"C1 artifact hash drift: {row['path']}")
        artifacts = {row["role"]: Path(row["path"]) for row in rows}
        receipt_rows = local_rows(artifacts["receipt"])
        validate_profile_triplet(cells[cell_id], receipt_rows[0] if len(receipt_rows) == 1 else {},
                                 local_rows(artifacts["trace"]), local_rows(artifacts["interval"]))
    primary_ids = {cells[cell_id]["primary_evidence_id"] for cell_id in CELL_IDS}
    c1_evidence = [row for row in evidence.values() if row["evidence_id"] in primary_ids]
    c1_transitions = [
        row for row in transitions if row["cell_id"] in CELL_IDS
        and row["evidence_ids"] == cells[row["cell_id"]]["primary_evidence_id"]
        and row["from_work_status"] == "verified" and row["to_work_status"] == "verified"
    ]
    if len(c1_evidence) != 24 or {row["evidence_id"] for row in c1_evidence} != primary_ids:
        fail("C1 evidence cardinality or allowlist binding drift")
    if len(c1_transitions) != 24 or {row["cell_id"] for row in c1_transitions} != set(CELL_IDS):
        fail("C1 transition cardinality or allowlist binding drift")
    evidence_by_id = {row["evidence_id"]: row for row in c1_evidence}
    transition_by_cell = {row["cell_id"]: row for row in c1_transitions}
    if rows_digest([evidence_by_id[cells[cell_id]["primary_evidence_id"]] for cell_id in CELL_IDS]) != C1_EVIDENCE_ROWS_SHA256:
        fail("C1 primary-evidence record or claim-boundary drift")
    if rows_digest([transition_by_cell[cell_id] for cell_id in CELL_IDS]) != C1_TRANSITION_ROWS_SHA256:
        fail("C1 transition record drift")
    if len([row for row in cells.values() if row["evidence_tier"] == "interval_feasible"]) < 72:
        fail("C1 interval_feasible baseline was lost")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--check-current", action="store_true")
    args = parser.parse_args()
    if sum((args.apply, args.check, args.check_current)) != 1:
        fail("supply exactly one of --apply, --check, or --check-current")
    if args.apply:
        apply()
    elif args.check:
        check()
    else:
        check_current()


if __name__ == "__main__":
    main()
