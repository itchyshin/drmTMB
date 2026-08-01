#!/usr/bin/env python3
"""Apply or verify the approved source-bound B4-CI C2 integration.

This deliberately imports only the exact C2 allowlist from the immutable
retained source.  Unlike C1, C2 contains three direct trace-only receipts and
one two-target receipt, so its 25 evidence rows close over 72 blobs.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import math
import subprocess
from pathlib import Path

SOURCE_COMMIT = "574c1108e16e3b0fe4ba88e254a34673508db901"
BASE_COMMIT = "950636b378cad6fabe53a4b995e8c7de21b0aaec"
PACKET_SHA256 = "68b5534646e2816df00334e95f3b782cdeb7ed2ec1709438ce9096711bfd3734"
ALLOWLIST_SHA256 = "304b58d3ee9850752a2d7fe46425d32737a761f74ee29080aff86c1f19efb3d8"
CELL_IDS = """
mc-0012 mc-0248 mc-0251 mc-0297 mc-0300 mc-0312 mc-0386 mc-0388
mc-0405 mc-0406 mc-0407 mc-0408 mc-0410 mc-0411 mc-0412 mc-0413
mc-0434 mc-0435 mc-0440 mc-0441 mc-0447 mc-0448 mc-0451 mc-0452
mc-0494
""".split()
C1_IDS = """mc-0005 mc-0007 mc-0059 mc-0184 mc-0185 mc-0187 mc-0188 mc-0203
mc-0204 mc-0225 mc-0265 mc-0267 mc-0270 mc-0271 mc-0380 mc-0401
mc-0402 mc-0403 mc-0429 mc-0431 mc-0463 mc-0511 mc-0538 mc-0567""".split()
B3_IDS = {"mc-0102", "mc-0124", "mc-0146", "mc-0168"}
EXCLUDED_IDS = {"mc-0182", "mc-0183", "mc-0207", "mc-0269"}
ABSOLUTE_PATH_PREFIXES = (
    "/Users/z3437171/.codex/worktrees/f9e4/drmTMB/docs/",
    "/home/snakagaw/hsq_work/drmTMB-lane-b-ordinary-0c1f39d86-git/docs/",
)
LEDGER = Path("docs/dev-log/dashboard/capability-ledger")
MANIFEST = Path("docs/dev-log/canonical-integration/2026-08-01-b4-ci-c2-manifest.tsv")
_SOURCE_CLOSURE: list[dict[str, str]] | None = None


def fail(message: str) -> None:
    raise SystemExit(f"B4-CI C2: {message}")


def git_bytes(spec: str) -> bytes:
    return subprocess.check_output(["git", "show", spec])


def rows_bytes(data: bytes) -> list[dict[str, str]]:
    return list(csv.DictReader(io.StringIO(data.decode()), delimiter="\t"))


def source_rows(name: str) -> list[dict[str, str]]:
    return rows_bytes(git_bytes(f"{SOURCE_COMMIT}:{LEDGER / name}"))


def local_rows(path: Path) -> list[dict[str, str]]:
    return rows_bytes(path.read_bytes())


def write_rows(path: Path, rows: list[dict[str, str]]) -> None:
    header = next(csv.reader(io.StringIO(path.read_text()), delimiter="\t"))
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=header, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def normalize(path: str) -> str:
    if not path.startswith("/"):
        return path
    for prefix in ABSOLUTE_PATH_PREFIXES:
        if path.startswith(prefix):
            return "docs/" + path.removeprefix(prefix)
    fail(f"unmapped absolute path: {path}")


def finite_ordered(lower: str, upper: str, context: str) -> None:
    lo, hi = float(lower), float(upper)
    if not math.isfinite(lo) or not math.isfinite(hi) or not lo < hi:
        fail(f"{context} is not finite and ordered")


def validate_direct_trace(cell: dict[str, str], trace: list[dict[str, str]]) -> None:
    if not trace:
        fail(f"direct trace is empty for {cell['cell_id']}")
    target_ids = {row.get("target_id") for row in trace}
    if len(target_ids) != 1 or None in target_ids or any(row.get("cell_id") != cell["cell_id"] for row in trace):
        fail(f"direct trace target binding drift for {cell['cell_id']}")
    if any(row.get("profile_pass") != "profile" or row.get("conf.status") != "profile" for row in trace):
        fail(f"direct trace is not a completed profile for {cell['cell_id']}")
    finite_ordered(trace[0]["conf.low"], trace[0]["conf.high"], f"direct trace {cell['cell_id']}")
    if any((row["conf.low"], row["conf.high"]) != (trace[0]["conf.low"], trace[0]["conf.high"]) for row in trace):
        fail(f"direct trace endpoints drift for {cell['cell_id']}")


def validate_triplet(cell: dict[str, str], receipt: dict[str, str], trace: list[dict[str, str]], interval: list[dict[str, str]]) -> None:
    target = receipt.get("target_id", "")
    if receipt.get("cell_id") != cell["cell_id"] or not target.startswith(cell["cell_id"] + "::"):
        fail(f"receipt target binding drift for {cell['cell_id']}")
    required = {"conf_status": "profile", "profile_engine": "tmbprofile", "convergence": "0", "pdHess": "TRUE", "profile_boundary": "FALSE", "clamp_limited": "FALSE", "trace_complete": "TRUE"}
    if any(receipt.get(key) != value for key, value in required.items()):
        fail(f"receipt does not establish a completed unclamped profile for {cell['cell_id']}")
    finite_ordered(receipt["lower"], receipt["upper"], f"receipt {cell['cell_id']}")
    if not trace or len(interval) != 1:
        fail(f"incomplete triplet for {cell['cell_id']}")
    if any(row.get("cell_id") != cell["cell_id"] or row.get("target_id") != target or row.get("profile_pass") != "profile" or row.get("conf.status") != "profile" for row in trace):
        fail(f"trace target or status drift for {cell['cell_id']}")
    if any((row.get("conf.low"), row.get("conf.high")) != (receipt["lower"], receipt["upper"]) for row in trace):
        fail(f"trace endpoint drift for {cell['cell_id']}")
    if (interval[0].get("cell_id"), interval[0].get("target_id"), interval[0].get("lower"), interval[0].get("upper")) != (cell["cell_id"], target, receipt["lower"], receipt["upper"]):
        fail(f"interval endpoint or target drift for {cell['cell_id']}")


def selected_source() -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, str]], list[dict[str, str]]]:
    if hashlib.sha256(("\n".join(CELL_IDS) + "\n").encode()).hexdigest() != ALLOWLIST_SHA256 or len(CELL_IDS) != 25 or len(set(CELL_IDS)) != 25:
        fail("allowlist digest, cardinality, or uniqueness mismatch")
    if set(CELL_IDS) & (B3_IDS | EXCLUDED_IDS):
        fail("allowlist crosses a preserved or excluded boundary")
    cells_by_id = {row["cell_id"]: row for row in source_rows("cells.tsv")}
    cells = [cells_by_id[cell_id] for cell_id in CELL_IDS]
    if any(row["evidence_tier"] != "interval_feasible" or row["work_status"] != "verified" for row in cells):
        fail("source C2 cells are not verified interval_feasible")
    evidence_by_id = {row["evidence_id"]: row for row in source_rows("evidence.tsv")}
    evidence = [evidence_by_id[row["primary_evidence_id"]] for row in cells]
    transitions_by_cell = {row["cell_id"]: row for row in source_rows("transitions.tsv") if row["cell_id"] in set(CELL_IDS) and row["from_work_status"] == "verified" and row["to_work_status"] == "verified"}
    transitions = [transitions_by_cell[cell_id] for cell_id in CELL_IDS]
    if any(t["evidence_ids"] != cell["primary_evidence_id"] for cell, t in zip(cells, transitions)):
        fail("transition/evidence binding drift")
    global _SOURCE_CLOSURE
    if _SOURCE_CLOSURE is not None:
        return cells, evidence, transitions, [row.copy() for row in _SOURCE_CLOSURE]
    closure: list[dict[str, str]] = []
    for cell, evidence_row in zip(cells, evidence):
        refs = [normalize(path) for path in evidence_row["path_or_url"].split(";")]
        for ref in refs:
            blob = git_bytes(f"{SOURCE_COMMIT}:{ref}")
            rows = rows_bytes(blob)
            if rows and "trace_path" in rows[0]:
                if len(rows) != 1:
                    fail(f"receipt cardinality drift for {cell['cell_id']}")
                receipt = rows[0]
                trace_path, interval_path = (normalize(receipt[field]) for field in ("trace_path", "interval_path"))
                trace, interval = rows_bytes(git_bytes(f"{SOURCE_COMMIT}:{trace_path}")), rows_bytes(git_bytes(f"{SOURCE_COMMIT}:{interval_path}"))
                validate_triplet(cell, receipt, trace, interval)
                triples = (("receipt", ref), ("trace", trace_path), ("interval", interval_path))
            else:
                validate_direct_trace(cell, rows)
                triples = (("direct_trace", ref),)
            for role, path in triples:
                data = git_bytes(f"{SOURCE_COMMIT}:{path}")
                closure.append({"cell_id": cell["cell_id"], "evidence_id": evidence_row["evidence_id"], "role": role, "path": path, "source_blob_sha256": hashlib.sha256(data).hexdigest()})
    if len(closure) != 72 or len({row["path"] for row in closure}) != 72:
        fail("C2 closure is not exactly 72 distinct source blobs")
    if sum(row["role"] == "direct_trace" for row in closure) != 3 or sum(row["cell_id"] == "mc-0494" for row in closure) != 6:
        fail("C2 heterogeneous closure shape drift")
    _SOURCE_CLOSURE = [row.copy() for row in closure]
    return cells, evidence, transitions, closure


def manifest_rows(closure: list[dict[str, str]]) -> list[dict[str, str]]:
    return [{"packet_sha256": PACKET_SHA256, "source_commit": SOURCE_COMMIT, "base_commit": BASE_COMMIT, "cohort": "C2", **row} for row in closure]


def base_cells(ids: set[str]) -> dict[str, dict[str, str]]:
    return {row["cell_id"]: row for row in rows_bytes(git_bytes(f"{BASE_COMMIT}:{LEDGER / 'cells.tsv'}")) if row["cell_id"] in ids}


def apply() -> None:
    cells, evidence, transitions, closure = selected_source()
    local_cells = local_rows(LEDGER / "cells.tsv")
    local_by_id = {row["cell_id"]: row for row in local_cells}
    if any(local_by_id[cell_id]["evidence_tier"] not in {"point_fit_recovery", "diagnostic_only"} for cell_id in CELL_IDS):
        fail("destination C2 cells are not eligible")
    protected = set(C1_IDS) | B3_IDS | EXCLUDED_IDS
    if {cell_id: local_by_id[cell_id] for cell_id in protected} != base_cells(protected):
        fail("C1, B3, or excluded base rows differ; refusing overwrite")
    source_by_id = {row["cell_id"]: row for row in cells}
    write_rows(LEDGER / "cells.tsv", [source_by_id.get(row["cell_id"], row) for row in local_cells])
    for name, records, key in (("evidence.tsv", evidence, "evidence_id"), ("transitions.tsv", transitions, "transition_id")):
        current = local_rows(LEDGER / name)
        if {row[key] for row in current} & {row[key] for row in records}:
            fail(f"destination already contains C2 {name} record")
        write_rows(LEDGER / name, current + records)
    for row in closure:
        path = Path(row["path"])
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(git_bytes(f"{SOURCE_COMMIT}:{row['path']}"))
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    fields = ["packet_sha256", "source_commit", "base_commit", "cohort", "cell_id", "evidence_id", "role", "path", "source_blob_sha256"]
    with MANIFEST.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader(); writer.writerows(manifest_rows(closure))


def check_current() -> None:
    cells, evidence, transitions, closure = selected_source()
    local_cell_map = {row["cell_id"]: row for row in local_rows(LEDGER / "cells.tsv")}
    if any(local_cell_map[cell["cell_id"]] != cell for cell in cells):
        fail("C2 cell source or claim-boundary drift")
    protected = set(C1_IDS) | B3_IDS | EXCLUDED_IDS
    if {cell_id: local_cell_map[cell_id] for cell_id in protected} != base_cells(protected):
        fail("C1, B3, or excluded base-row drift")
    local_evidence = {row["evidence_id"]: row for row in local_rows(LEDGER / "evidence.tsv")}
    local_transitions = {row["transition_id"]: row for row in local_rows(LEDGER / "transitions.tsv")}
    if any(local_evidence.get(row["evidence_id"]) != row for row in evidence) or any(local_transitions.get(row["transition_id"]) != row for row in transitions):
        fail("C2 evidence or transition source drift")
    if not MANIFEST.exists() or local_rows(MANIFEST) != manifest_rows(closure):
        fail("manifest closure or provenance drift")
    for row in closure:
        path = Path(row["path"])
        if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != row["source_blob_sha256"]:
            fail(f"artifact blob drift: {path}")
    if len([
        row for row in local_cell_map.values()
        if row["axis"] == "model_surface"
        and row["evidence_tier"] == "interval_feasible"
    ]) != 97:
        fail("C2 did not move the canonical interval_feasible count to 97")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.apply == args.check:
        fail("supply exactly one of --apply or --check")
    apply() if args.apply else check_current()


if __name__ == "__main__":
    main()
