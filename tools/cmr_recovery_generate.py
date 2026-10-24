#!/usr/bin/env python3
"""Fail-closed v6/v7 admission wrapper for the frozen CMR dataset generator.

The scientific implementation lives in the immutable MIT snapshot under
docs/dev-log/cmr/generator-source-v6. This wrapper owns execution admission and
metadata only; it does not duplicate or alter the generator algorithms.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "docs/dev-log/cmr/fixtures/recovery-manifest-v6.json"
GENERATOR_SOURCE = ROOT / "docs/dev-log/cmr/generator-source-v6/bench/cmr_recovery/generate.py"
V5_MANIFEST = ROOT / "docs/dev-log/cmr/generator-source/docs/dev-log/cmr/fixtures/recovery-manifest-v5.json"
V6_PARENT_MANIFEST = ROOT / "docs/dev-log/cmr/fixtures/recovery-manifest-v6.json"
MANIFEST_SHA256 = "5dbce920b0de7e89460edd68a49fcea07afb612ff75d32ae11680cc07de8171d"
MANIFEST_V7_SHA256 = "b31d915064cddde3a2bd82202072c7451a453b0fefe8ab84f0bd1f82a3f366f8"
GENERATOR_SHA256 = "2c1878154fcddddc17c3d55926dfc8b6aa8cbb2c94c7fe792e69576cf8eb1b70"
V6_SCHEMA = 6
V7_SCHEMA = 7
STAGE_INDEX = {"pre_run": 0, "pilot": 1, "screen": 2, "qualification": 3}


class AdmissionError(ValueError):
    """The requested generation is outside the frozen v6 admission contract."""


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise AdmissionError(f"cannot read JSON artifact {path}: {exc}") from None
    if not isinstance(value, dict):
        raise AdmissionError(f"JSON artifact {path} must contain an object")
    return value


def verify_v5_scientific_equivalence(manifest: dict[str, Any], old: dict[str, Any]) -> None:
    if manifest.get("common_design") != old.get("common_design"):
        raise AdmissionError("v6 common_design differs from the frozen v5 scientific design")
    for key in ("generator", "primary_cells", "screening_only_cells", "estimands",
                "qualification_defaults", "inference_scope", "summary_statistics"):
        if manifest.get(key) != old.get(key):
            raise AdmissionError(f"v6 scientific field {key!r} differs from frozen v5")


def verify_v6_scientific_equivalence(manifest: dict[str, Any], old: dict[str, Any]) -> None:
    excluded = {"schema_version", "status", "provenance", "inference_scope", "computation", "pilot_admission"}
    for key in old:
        if key not in excluded and manifest.get(key) != old.get(key):
            raise AdmissionError(f"v7 changes frozen v6 scientific/approval field {key!r}")
    if (manifest.get("pilot_admission", {}).get("cells") != old.get("pilot_admission", {}).get("cells")
            or manifest.get("pilot_admission", {}).get("replicate_range") != old.get("pilot_admission", {}).get("replicate_range")
            or manifest.get("pilot_admission", {}).get("stage") != old.get("pilot_admission", {}).get("stage")):
        raise AdmissionError("v7 changes the approved v6 pilot cells, range, or stage")


def verify_frozen_inputs(manifest_path: Path) -> tuple[dict[str, Any], str, str]:
    if not GENERATOR_SOURCE.is_file() or sha256_file(GENERATOR_SOURCE) != GENERATOR_SHA256:
        raise AdmissionError("frozen generator source is missing or its pinned SHA-256 changed")
    if not V5_MANIFEST.is_file():
        raise AdmissionError("frozen v5 source manifest is missing")
    digest = sha256_file(manifest_path)
    if digest not in (MANIFEST_SHA256, MANIFEST_V7_SHA256):
        raise AdmissionError("manifest is not a hash-pinned v6 or v7 artifact")
    if sha256_file(V5_MANIFEST) != "7392d01f67f75eeb9a2bd62e0aff8585a42c130c22b3b17f42f88fc695c9740e":
        raise AdmissionError("frozen v5 source manifest SHA-256 changed")
    manifest = load_json(manifest_path)
    if digest == MANIFEST_SHA256:
        old = load_json(V5_MANIFEST)
        if manifest.get("schema_version") != V6_SCHEMA:
            raise AdmissionError("pinned manifest does not declare schema version 6")
        verify_v5_scientific_equivalence(manifest, old)
        return manifest, MANIFEST_SHA256, GENERATOR_SHA256
    if not V6_PARENT_MANIFEST.is_file() or sha256_file(V6_PARENT_MANIFEST) != MANIFEST_SHA256:
        raise AdmissionError("frozen v6 parent manifest is missing or changed")
    parent = load_json(V6_PARENT_MANIFEST)
    if (manifest.get("schema_version") != V7_SCHEMA
            or manifest.get("provenance", {}).get("parent_schema_version") != V6_SCHEMA
            or manifest.get("provenance", {}).get("parent_manifest_sha256") != MANIFEST_SHA256):
        raise AdmissionError("v7 manifest does not identify the approved v6 parent")
    verify_v6_scientific_equivalence(manifest, parent)
    return manifest, MANIFEST_V7_SHA256, GENERATOR_SHA256


def _cells(manifest: dict[str, Any]) -> dict[str, dict[str, Any]]:
    found: dict[str, dict[str, Any]] = {}
    for group in ("primary_cells", "screening_only_cells"):
        rows = manifest.get(group)
        if not isinstance(rows, list):
            raise AdmissionError(f"v6 manifest has no registered {group}")
        for row in rows:
            if not isinstance(row, dict) or not isinstance(row.get("cell"), str):
                raise AdmissionError(f"v6 manifest contains a malformed {group} entry")
            if row["cell"] in found:
                raise AdmissionError(f"v6 manifest repeats cell {row['cell']!r}")
            found[row["cell"]] = row
    return found


def seed_for(stage: str, cell_index: int, replicate: int) -> int:
    if stage not in STAGE_INDEX or cell_index < 1 or replicate < 1:
        raise AdmissionError("stage, cell index, or replicate is outside the seed formula domain")
    return 20261007 + 10_000_000 * STAGE_INDEX[stage] + 100_000 * cell_index + replicate


def _verify_review_receipt(path: Path | None, manifest_sha: str, source_sha: str) -> None:
    if path is None:
        raise AdmissionError("screen and qualification require a reviewed precheck receipt")
    receipt = load_json(path)
    if (receipt.get("reviewed") is not True
            or receipt.get("prechecks_complete") is not True
            or receipt.get("manifest_sha256") != manifest_sha
            or receipt.get("generator_source_sha256") != source_sha):
        raise AdmissionError(
            "review receipt must confirm reviewed=true, prechecks_complete=true, "
            "and match the pinned manifest and generator source hashes"
        )
    paired = receipt.get("paired_source_runtime", {})
    requirements = {
        "R": ("source_manifest_sha256", "dll_sha256", "prerun_receipts_sha256"),
        "Julia": ("source_manifest_sha256", "project_sha256", "environment_manifest_sha256", "prerun_receipts_sha256"),
    }
    for label, hashes in requirements.items():
        identity = paired.get(label, {}) if isinstance(paired, dict) else {}
        for field in hashes:
            value = identity.get(field)
            if (not isinstance(value, str) or len(value) != 64
                    or any(char not in "0123456789abcdef" for char in value)):
                raise AdmissionError(f"review receipt is missing a valid {label}.{field}")
        for field in ("package_version", "runtime_version", "worker_threads", "thread_environment"):
            value = identity.get(field)
            if not isinstance(value, str) or not value:
                raise AdmissionError(f"review receipt is missing {label}.{field}")
        if identity.get("worker_threads") != "1":
            raise AdmissionError("CMR recovery campaigns require one worker thread per process")
    for field in ("module_path", "depot_path"):
        value = paired.get("Julia", {}).get(field)
        if not isinstance(value, str) or not value:
            raise AdmissionError(f"review receipt is missing Julia.{field}")


def authorize(manifest: dict[str, Any], stage: str, cell_name: str, replicate: int,
              receipt: Path | None, manifest_sha: str, source_sha: str) -> dict[str, Any]:
    cells = _cells(manifest)
    if cell_name not in cells:
        raise AdmissionError(f"cell {cell_name!r} is not registered in schema {manifest.get('schema_version')}")
    if stage not in STAGE_INDEX or isinstance(replicate, bool) or replicate < 1:
        raise AdmissionError("stage/replicate must be a registered stage and positive integer")
    primary_names = {row["cell"] for row in manifest["primary_cells"]}
    stage_spec = manifest.get("stages", {}).get(stage)
    if not isinstance(stage_spec, dict):
        raise AdmissionError(f"stage {stage!r} is not registered")
    if stage == "pre_run":
        admitted = ((cell_name in primary_names if manifest.get("schema_version") == V7_SCHEMA else cell_name in cells)
                    and replicate <= int(stage_spec.get("replicates", 0)))
    elif stage == "pilot":
        admission = manifest.get("pilot_admission", {})
        lo, hi = admission.get("replicate_range", [0, -1])
        admitted = (admission.get("stage") == stage and cell_name in admission.get("cells", [])
                    and int(admission.get("manifest_version", -1)) == manifest.get("schema_version")
                    and lo <= replicate <= hi)
    elif stage == "screen":
        lo, hi = manifest.get("seed_ranges", {}).get(stage, [0, -1])
        admitted = cell_name in cells and lo <= replicate <= hi
    else:
        lo, hi = manifest.get("seed_ranges", {}).get(stage, [0, -1])
        admitted = cell_name in primary_names and lo <= replicate <= hi
    if not admitted:
        raise AdmissionError(f"{stage}/{cell_name}/replicate {replicate} is outside v{manifest.get('schema_version')} admission")
    if stage in ("screen", "qualification"):
        _verify_review_receipt(receipt, manifest_sha, source_sha)
    return cells[cell_name]


def load_generator(path: Path = GENERATOR_SOURCE):
    """Load the pinned implementation without writing bytecode into its snapshot."""
    if sha256_file(path) != GENERATOR_SHA256:
        raise AdmissionError("generator source is missing or its pinned SHA-256 changed")
    old_flag = sys.dont_write_bytecode
    sys.dont_write_bytecode = True
    try:
        spec = importlib.util.spec_from_file_location("cmr_frozen_generator", path)
        if spec is None or spec.loader is None:
            raise AdmissionError("could not load the pinned generator module")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
    finally:
        sys.dont_write_bytecode = old_flag


def generate(cell_name: str, replicate: int, stage: str, out: Path,
             manifest_path: Path = DEFAULT_MANIFEST,
             receipt: Path | None = None) -> dict[str, Any]:
    manifest, manifest_sha, source_sha = verify_frozen_inputs(manifest_path)
    cell = authorize(manifest, stage, cell_name, replicate, receipt, manifest_sha, source_sha)
    if out.exists() and (not out.is_dir() or any(out.iterdir())):
        raise AdmissionError("output directory must be empty; refusing to reuse prior data")
    gen = load_generator()
    resolved = gen.resolve_cell(manifest, cell_name)
    # v6 public admission is independent of the frozen source's historical v2-v4 gate.
    seed = seed_for(stage, int(cell["index"]), replicate)
    data = gen.generate_dataset(resolved, replicate, seed,
                                common_design=manifest["common_design"])
    table_schema_version = 5 if (
        resolved.get("year_design") == "paired_halfyear"
        or isinstance(resolved.get("selection"), dict)
        and "first_capture" in resolved["selection"]
    ) else 4
    hashes = gen.write_dataset(data, out, schema_version=table_schema_version)
    metadata = {
        "manifest_schema_version": manifest["schema_version"],
        "manifest_sha256": manifest_sha,
        "generator_source_sha256": source_sha,
        "table_schema_version": table_schema_version,
        "cell": cell_name,
        "stage": stage,
        "replicate": replicate,
        "seed": seed,
        "rows": {name: len(rows) for name, rows in data.items()},
        "sha256": hashes,
    }
    return metadata


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cell", required=True)
    parser.add_argument("--replicate", required=True, type=int)
    parser.add_argument("--stage", choices=STAGE_INDEX, required=True)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--receipt", type=Path)
    args = parser.parse_args()
    try:
        print(json.dumps(generate(args.cell, args.replicate, args.stage, args.out,
                                  args.manifest, args.receipt), sort_keys=True))
    except (AdmissionError, ValueError, OSError) as exc:
        print(f"CMR_GENERATION_REFUSED: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
