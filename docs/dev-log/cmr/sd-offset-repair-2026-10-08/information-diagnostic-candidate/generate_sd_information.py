#!/usr/bin/env python3
"""Generate (without fitting) the frozen-generator CMR individual-SD diagnostic.

This script is intentionally fail-closed. It reads the retained v6 bundle,
checks its pinned manifest/source bytes, and calls that source's generator with
its documented n_override test seam. It writes only into a new, empty output
directory. Running it does not fit a model or assess recovery.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path

MANIFEST = Path(
    "/private/tmp/cmr-r-prerun-v6-lean/docs/dev-log/cmr/fixtures/recovery-manifest-v6.json"
)
GENERATOR = Path(
    "/private/tmp/cmr-r-prerun-v6-lean/docs/dev-log/cmr/generator-source-v6/bench/cmr_recovery/generate.py"
)
MANIFEST_SHA256 = "5dbce920b0de7e89460edd68a49fcea07afb612ff75d32ae11680cc07de8171d"
GENERATOR_SHA256 = "2c1878154fcddddc17c3d55926dfc8b6aa8cbb2c94c7fe792e69576cf8eb1b70"
BASE_CELL = "m5_sd_pair_nonzero_slopes"
CELL_INDEX = 9
DIAGNOSTIC_NS = "m5_sd_pair_nonzero_slopes_info"
SIZES = (800, 1600)
REPLICATES_PER_SIZE = 5
# New seed domain, disjoint from v6's pre_run/pilot/screen/qualification range.
SEED_BASE = 120_000_000


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_generator():
    if sha256(MANIFEST) != MANIFEST_SHA256:
        raise RuntimeError("frozen v6 manifest hash mismatch")
    if sha256(GENERATOR) != GENERATOR_SHA256:
        raise RuntimeError("frozen v6 generator source hash mismatch")
    sys.dont_write_bytecode = True
    spec = importlib.util.spec_from_file_location("cmr_frozen_generator", GENERATOR)
    if spec is None or spec.loader is None:
        raise RuntimeError("could not load pinned generator")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def generate(out: Path) -> dict:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if manifest.get("schema_version") != 6:
        raise RuntimeError("expected recovery-manifest-v6 schema")
    rows = manifest.get("primary_cells", [])
    base = next((row for row in rows if row.get("cell") == BASE_CELL), None)
    expected = {
        "index": CELL_INDEX,
        "n": 400,
        "route": "individual_pair_sd",
        "phi": "~1+x_phi+(1|id)",
        "p": "~1+z_p+(1|id)",
        "sd_phi": "~1+x_phi",
        "sd_p": "~1+z_p",
        "selection": False,
    }
    if base is None or any(base.get(k) != v for k, v in expected.items()):
        raise RuntimeError("frozen base cell does not match the specified M5 route")

    gen = load_generator()
    # The retained source's default manifest loader accepts historical v2-v5
    # manifests. Supply the hash-checked v6 manifest in memory; no source edit
    # or duplicate generator logic is introduced.
    gen.load_manifest = lambda: manifest
    generated = []
    diag_index = 0
    for n in SIZES:
        cell_name = f"{DIAGNOSTIC_NS}_N{n}"
        for replicate in range(1, REPLICATES_PER_SIZE + 1):
            diag_index += 1
            seed = SEED_BASE + 100_000 * CELL_INDEX + diag_index
            target = out / cell_name / f"{replicate:02d}"
            if target.exists() and (not target.is_dir() or any(target.iterdir())):
                raise RuntimeError(f"refusing nonempty output path: {target}")
            target.mkdir(parents=True, exist_ok=True)
            resolved = gen.resolve_cell(manifest, BASE_CELL)
            resolved["cell"] = cell_name
            data = gen.generate_dataset(
                resolved,
                replicate,
                seed,
                n_override=n,
                common_design=manifest["common_design"],
            )
            # Ordinary (non exact-f-selection) v6 tables use schema 4.
            hashes = gen.write_dataset(data, target, schema_version=4)
            generated.append({
                "cell": cell_name,
                "n": n,
                "replicate": replicate,
                "seed": seed,
                "rows": {key: len(value) for key, value in data.items()},
                "sha256": hashes,
            })
    receipt = {
        "status": "generated_data_only_no_fits",
        "manifest_sha256": MANIFEST_SHA256,
        "generator_source_sha256": GENERATOR_SHA256,
        "generator": "SplitMix64-v1",
        "diagnostic_seed_rule": "120000000 + 100000*9 + diagnostic_index; index 1:10, N=800 indices 1:5 then N=1600 indices 6:10",
        "datasets": generated,
    }
    (out / "generation-receipt.json").write_text(
        json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    return receipt


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if args.out.exists() and (not args.out.is_dir() or any(args.out.iterdir())):
        parser.error("--out must be new or empty; primary pre-run data are never overwritten")
    try:
        result = generate(args.out)
    except (OSError, ValueError, RuntimeError, KeyError) as exc:
        print(f"GENERATION_REFUSED: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({
        "status": result["status"],
        "dataset_count": len(result["datasets"]),
        "sizes": list(SIZES),
        "out": str(args.out),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
