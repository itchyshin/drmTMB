#!/usr/bin/env python3
"""Apply or verify the approved source-bound B4-CI C4 integration."""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import math
import subprocess

import b4_ci_guard
from pathlib import Path, PurePosixPath

SOURCE_COMMIT = "574c1108e16e3b0fe4ba88e254a34673508db901"
BASE_COMMIT = "f41dfc01a812af1294ee86790dc3e8d39e412c50"
PACKET_SHA256 = "9b9f30f089214e160db1bb1344bbd313440c683c8f35056cf2b1c6b40f245525"
ALLOWLIST_SHA256 = "682037229fee39178e9437ee605e78138ce9abc49af0febc447643a386b7dea9"
CELL_IDS = """
mc-0101 mc-0115 mc-0116 mc-0117 mc-0118 mc-0137 mc-0138 mc-0139
mc-0140 mc-0145 mc-0159 mc-0160 mc-0161 mc-0162 mc-0167 mc-0212
mc-0213 mc-0214 mc-0215 mc-0216 mc-0217 mc-0218 mc-0219
""".split()
C1_IDS = """mc-0005 mc-0007 mc-0059 mc-0184 mc-0185 mc-0187 mc-0188 mc-0203 mc-0204 mc-0225 mc-0265 mc-0267 mc-0270 mc-0271 mc-0380 mc-0401 mc-0402 mc-0403 mc-0429 mc-0431 mc-0463 mc-0511 mc-0538 mc-0567""".split()
C2_IDS = """mc-0012 mc-0248 mc-0251 mc-0297 mc-0300 mc-0312 mc-0386 mc-0388 mc-0405 mc-0406 mc-0407 mc-0408 mc-0410 mc-0411 mc-0412 mc-0413 mc-0434 mc-0435 mc-0440 mc-0441 mc-0447 mc-0448 mc-0451 mc-0452 mc-0494""".split()
C3_IDS = """mc-0083 mc-0084 mc-0089 mc-0090 mc-0091 mc-0092 mc-0107 mc-0108 mc-0109 mc-0110 mc-0113 mc-0114 mc-0129 mc-0130 mc-0131 mc-0132 mc-0135 mc-0136 mc-0151 mc-0152 mc-0157 mc-0158 mc-0199 mc-0201 mc-0208 mc-0209 mc-0280 mc-0281 mc-0293 mc-0294 mc-0305 mc-0306 mc-0317 mc-0318 mc-0672 mc-0674""".split()
B3_IDS = {"mc-0102", "mc-0124", "mc-0146", "mc-0168"}
EXCLUDED_IDS = {"mc-0182", "mc-0183", "mc-0207", "mc-0269"}
ASSOCIATION_IDS = {"as-0001", "as-0002", "as-0003", "as-0004", "as-0005", "as-0006"}
C17_C1_IDS = {"mc-0570"}
LEDGER = Path("docs/dev-log/dashboard/capability-ledger")
MANIFEST = Path("docs/dev-log/canonical-integration/2026-08-02-b4-ci-c4-manifest.tsv")


def fail(message: str) -> None:
    raise SystemExit(f"B4-CI C4: {message}")


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
        writer.writeheader(); writer.writerows(rows)


def normalize(path: str) -> str:
    if not path.startswith("/"):
        return path
    marker = "/drmTMB/docs/"
    if marker in path:
        return "docs/" + path.split(marker, 1)[1]
    fail(f"unmapped absolute path: {path}")


def source_peer(path: str, role: str) -> str:
    names = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", SOURCE_COMMIT, str(PurePosixPath(path).parent)]).decode().splitlines()
    matches = [name for name in names if name.endswith(f"{role}.tsv")]
    if len(matches) != 1:
        fail(f"cannot resolve unique {role} peer for {path}")
    return matches[0]


def validate_triplet(cell: dict[str, str], receipt: dict[str, str], trace: list[dict[str, str]], interval: list[dict[str, str]]) -> None:
    target = receipt.get("target_id", "")
    if receipt.get("cell_id") != cell["cell_id"] or not target.startswith(cell["cell_id"] + "::"):
        fail(f"receipt target binding drift for {cell['cell_id']}")
    required = {"conf_status": "profile", "profile_engine": "tmbprofile", "convergence": "0", "pdHess": "TRUE", "profile_boundary": "FALSE", "clamp_limited": "FALSE", "trace_complete": "TRUE"}
    if any(receipt.get(key) != value for key, value in required.items()):
        fail(f"receipt does not establish a completed unclamped profile for {cell['cell_id']}")
    lo, hi = float(receipt["lower"]), float(receipt["upper"])
    if not math.isfinite(lo) or not math.isfinite(hi) or not lo < hi:
        fail(f"receipt interval is not finite and ordered for {cell['cell_id']}")
    if not trace or len(interval) != 1:
        fail(f"incomplete triplet for {cell['cell_id']}")
    if any(row.get("cell_id") != cell["cell_id"] or row.get("target_id") != target or row.get("profile_pass") != "profile" or row.get("conf.status") != "profile" or (row.get("conf.low"), row.get("conf.high")) != (receipt["lower"], receipt["upper"]) for row in trace):
        fail(f"trace target or endpoint drift for {cell['cell_id']}")
    if (interval[0].get("cell_id"), interval[0].get("target_id"), interval[0].get("lower"), interval[0].get("upper")) != (cell["cell_id"], target, receipt["lower"], receipt["upper"]):
        fail(f"interval endpoint or target drift for {cell['cell_id']}")


def selected_source() -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, str]], list[dict[str, str]]]:
    if hashlib.sha256(("\n".join(CELL_IDS) + "\n").encode()).hexdigest() != ALLOWLIST_SHA256 or len(CELL_IDS) != 23 or len(set(CELL_IDS)) != 23:
        fail("allowlist digest, cardinality, or uniqueness mismatch")
    if set(CELL_IDS) & (B3_IDS | EXCLUDED_IDS):
        fail("allowlist crosses a preserved or excluded boundary")
    source_by_id = {row["cell_id"]: row for row in source_rows("cells.tsv")}
    cells = [source_by_id[cell_id] for cell_id in CELL_IDS]
    if any(row["evidence_tier"] != "interval_feasible" or row["work_status"] != "verified" for row in cells):
        fail("source C4 cells are not verified interval_feasible")
    evidence_by_id = {row["evidence_id"]: row for row in source_rows("evidence.tsv")}
    evidence = [{**evidence_by_id[row["primary_evidence_id"]], "path_or_url": ";".join(normalize(path) for path in evidence_by_id[row["primary_evidence_id"]]["path_or_url"].split(";"))} for row in cells]
    transitions_by_cell = {row["cell_id"]: row for row in source_rows("transitions.tsv") if row["cell_id"] in set(CELL_IDS) and row["from_work_status"] == "verified" and row["to_work_status"] == "verified"}
    transitions = [transitions_by_cell[cell_id] for cell_id in CELL_IDS]
    if any(t["evidence_ids"] != cell["primary_evidence_id"] for cell, t in zip(cells, transitions)):
        fail("transition/evidence binding drift")
    closure: list[dict[str, str]] = []
    for cell, evidence_row in zip(cells, evidence):
        for ref in evidence_row["path_or_url"].split(";"):
            receipt_rows = rows_bytes(git_bytes(f"{SOURCE_COMMIT}:{ref}"))
            if len(receipt_rows) != 1:
                fail(f"C4 requires a single receipt for {cell['cell_id']}")
            receipt = receipt_rows[0]
            trace_path = normalize(receipt["trace_path"]) if receipt.get("trace_path") else source_peer(ref, "trace")
            interval_path = normalize(receipt["interval_path"]) if receipt.get("interval_path") else source_peer(ref, "interval")
            trace, interval = rows_bytes(git_bytes(f"{SOURCE_COMMIT}:{trace_path}")), rows_bytes(git_bytes(f"{SOURCE_COMMIT}:{interval_path}"))
            validate_triplet(cell, receipt, trace, interval)
            for role, path in (("receipt", ref), ("trace", trace_path), ("interval", interval_path)):
                data = git_bytes(f"{SOURCE_COMMIT}:{path}")
                closure.append({"cell_id": cell["cell_id"], "evidence_id": evidence_row["evidence_id"], "role": role, "path": path, "source_blob_sha256": hashlib.sha256(data).hexdigest()})
    if len(closure) != 69 or len({row["path"] for row in closure}) != 69 or any(sum(row["cell_id"] == cell_id for row in closure) != 3 for cell_id in CELL_IDS):
        fail("C4 closure is not exactly 69 distinct source blobs")
    return cells, evidence, transitions, closure


def protected_ids() -> set[str]:
    return set(C1_IDS) | set(C2_IDS) | set(C3_IDS) | B3_IDS | EXCLUDED_IDS | ASSOCIATION_IDS | C17_C1_IDS


def base_cells(ids: set[str]) -> dict[str, dict[str, str]]:
    return {row["cell_id"]: row for row in rows_bytes(git_bytes(f"{BASE_COMMIT}:{LEDGER / 'cells.tsv'}")) if row["cell_id"] in ids}


def manifest_rows(closure: list[dict[str, str]]) -> list[dict[str, str]]:
    return [{"packet_sha256": PACKET_SHA256, "source_commit": SOURCE_COMMIT, "base_commit": BASE_COMMIT, "cohort": "C4", **row} for row in closure]


def apply() -> None:
    cells, evidence, transitions, closure = selected_source()
    current_cells = local_rows(LEDGER / "cells.tsv"); local_by_id = {row["cell_id"]: row for row in current_cells}
    if any(local_by_id[cell_id]["evidence_tier"] not in {"point_fit_recovery", "diagnostic_only"} or local_by_id[cell_id]["work_status"] != "verified" for cell_id in CELL_IDS):
        fail("destination C4 cells are not eligible verified pre-promotion cells")
    protected = protected_ids()
    if any(cell_id not in local_by_id for cell_id in protected) or {cell_id: local_by_id[cell_id] for cell_id in protected} != base_cells(protected):
        fail("prior cohorts, exclusions, association, or C17 base rows differ; refusing overwrite")
    source_by_id = {row["cell_id"]: row for row in cells}
    write_rows(LEDGER / "cells.tsv", [source_by_id.get(row["cell_id"], row) for row in current_cells])
    for name, records, key in (("evidence.tsv", evidence, "evidence_id"), ("transitions.tsv", transitions, "transition_id")):
        current = local_rows(LEDGER / name); records_by_key = {row[key]: row for row in records}
        if any(row for row in current if row[key] in records_by_key and row.get("cell_id") not in set(CELL_IDS)):
            fail(f"destination C4 {name} key collision")
        write_rows(LEDGER / name, [records_by_key.get(row[key], row) for row in current] + [row for row in records if row[key] not in {current_row[key] for current_row in current}])
    for row in closure:
        path = Path(row["path"]); path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(git_bytes(f"{SOURCE_COMMIT}:{row['path']}"))
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    with MANIFEST.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["packet_sha256", "source_commit", "base_commit", "cohort", "cell_id", "evidence_id", "role", "path", "source_blob_sha256"], delimiter="\t", lineterminator="\n")
        writer.writeheader(); writer.writerows(manifest_rows(closure))


def check(*, allow_later_cohorts: bool = False) -> None:
    cells, evidence, transitions, closure = selected_source(); local = {row["cell_id"]: row for row in local_rows(LEDGER / "cells.tsv")}
    all_transitions = local_rows(LEDGER / "transitions.tsv")
    cohort_transition_ids = {row["transition_id"] for row in transitions}
    own = b4_ci_guard.unexplained_drift(
        protected_ids={row["cell_id"] for row in cells},
        base_cells={row["cell_id"]: row for row in cells},
        local_cells=local,
        transitions=all_transitions,
        cohort_transition_ids=cohort_transition_ids,
    )
    if own: fail(f"C4 cell source or claim-boundary drift -- {b4_ci_guard.describe(own)}")
    protected = protected_ids()
    neighbours = b4_ci_guard.unexplained_drift(
        protected_ids=protected,
        base_cells=base_cells(protected),
        local_cells=local,
        transitions=all_transitions,
        cohort_evidence_ids={row["evidence_id"] for row in evidence},
        cohort_transition_ids=cohort_transition_ids,
    )
    if neighbours: fail(f"protected base-row drift -- {b4_ci_guard.describe(neighbours)}")
    local_evidence = {row["evidence_id"]: row for row in local_rows(LEDGER / "evidence.tsv")}; local_transitions = {row["transition_id"]: row for row in all_transitions}
    if any(local_evidence.get(row["evidence_id"]) != row for row in evidence) or any(local_transitions.get(row["transition_id"]) != row for row in transitions): fail("C4 evidence or transition source drift")
    if not MANIFEST.exists() or local_rows(MANIFEST) != manifest_rows(closure): fail("manifest closure or provenance drift")
    if any(not Path(row["path"]).exists() or hashlib.sha256(Path(row["path"]).read_bytes()).hexdigest() != row["source_blob_sha256"] for row in closure): fail("artifact blob drift")
    interval_count = sum(row["evidence_tier"] == "interval_feasible" for row in local.values())
    # C4 moved the global interval_feasible count to 161. Later arcs move it again,
    # so the durable claim is that C4's contribution has not been lost, not that the
    # count is still exactly what it was the day C4 landed.
    if allow_later_cohorts:
        if interval_count < 161: fail(f"C4 global interval_feasible baseline was lost ({interval_count} < 161)")
    elif interval_count != 161:
        fail(f"C4 did not move global interval_feasible count to 161 (found {interval_count})")


def main() -> None:
    parser = argparse.ArgumentParser(); parser.add_argument("--apply", action="store_true"); parser.add_argument("--check", action="store_true"); parser.add_argument("--check-with-later-cohorts", action="store_true"); args = parser.parse_args()
    if sum((args.apply, args.check, args.check_with_later_cohorts)) != 1: fail("supply exactly one mode")
    apply() if args.apply else check(allow_later_cohorts=args.check_with_later_cohorts)


if __name__ == "__main__":
    main()
