#!/usr/bin/env python3
"""Preserve and replay completed adapter probes without claiming qualification."""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from stage_two import (SEED_SHA, adapter_qualification_case,
                       qualification_registry_digest, read_csv, replay_adapter_qualification,
                       sha256, validate_adapter_qualification,
                       validate_batch_manifest, validate_qualification_subset,
                       verify_registry)


def finalize(prepared_root: Path, library: Path, output: Path) -> dict:
    """Build a receipt from three existing, sealed probe outputs; never runs a fit."""
    root = prepared_root.resolve(strict=True)
    library = library.resolve(strict=True)
    output = output.resolve()
    if output.exists():
        raise FileExistsError(f"refusing to overwrite {output}")
    preparation = root / "adapter-qualification-preparation-receipt.json"
    prepared = json.loads(preparation.read_text())
    if (prepared.get("schema") != "native-sd-adapter-qualification-preparation-v1"
            or prepared.get("status") != "prepared_not_launched"
            or prepared.get("no_fits_launched") is not True
            or prepared.get("calibration_claim") is not False
            or prepared.get("campaign_complete") is not False
            or prepared.get("source_manifest_sha256") != SEED_SHA
            or Path(prepared.get("library", "")).resolve(strict=True) != library
            or len(prepared.get("batches", [])) != 3
            or len(prepared.get("library_artifacts", [])) < 3):
        raise ValueError("prepared adapter-qualification receipt is incomplete or altered")
    for artifact in prepared["library_artifacts"]:
        path = Path(artifact["path"]).resolve(strict=True)
        if library not in path.parents or sha256(path) != artifact["sha256"]:
            raise ValueError("original Bernoulli library artifact differs from preparation seal")

    source_rows = None
    source_path = None
    batches = []
    probe_starts = []
    probe_finishes = []
    for b, prep_item in enumerate(prepared["batches"], 1):
        batch_root = root / f"batch-{b}"
        verify_registry(batch_root)
        registry_path = batch_root / "source-hashes.csv"
        manifest_path = batch_root / "manifest.csv"
        registry_sha = sha256(registry_path)
        manifest_sha = sha256(manifest_path)
        if (prep_item.get("batch_id") != b
                or prep_item.get("registry_sha256") != registry_sha
                or prep_item.get("manifest_sha256") != manifest_sha):
            raise ValueError(f"batch {b} no longer matches its preparation receipt")
        registry_rows = read_csv(registry_path)
        sources = [Path(row["path"]).resolve(strict=True) for row in registry_rows
                   if Path(row["path"]).name == "stage-two-manifest.csv"]
        if len(sources) != 1 or sha256(sources[0]) != SEED_SHA:
            raise ValueError("batch registry does not pin the frozen stage-two source")
        if source_rows is None:
            source_path = sources[0]
            source_rows = read_csv(source_path)
        elif sources[0] != source_path:
            raise ValueError("qualification batches point to different source manifests")
        validate_batch_manifest(read_csv(manifest_path), source_rows, b)
        expected = adapter_qualification_case(source_rows, b)
        for key in ("local_index", "stage_two_index", "replicate"):
            if prep_item.get(key) != expected[key]:
                raise ValueError(f"prepared batch {b} has wrong frozen identity {key}")
        if not stage_two_same_truth(prep_item.get("a"), expected["a"]):
            raise ValueError(f"prepared batch {b} has wrong frozen truth value")

        supervisor_path = batch_root / "supervisor-receipt.json"
        result_path = batch_root / f"result-{expected['local_index']:04d}.csv"
        if not supervisor_path.is_file() or not result_path.is_file():
            raise FileNotFoundError(f"batch {b} completed-probe receipts are missing")
        supervisor = json.loads(supervisor_path.read_text())
        validate_qualification_subset(supervisor, expected["local_index"],
                                      registry_sha, manifest_sha)
        case = supervisor["cases"][0]
        probe_start = float(case["started_at"])
        probe_finish = float(case["finished_at"])
        if not math.isfinite(probe_start) or not math.isfinite(probe_finish) or probe_finish < probe_start:
            raise ValueError(f"batch {b} has invalid probe timing")
        probe_starts.append(probe_start)
        probe_finishes.append(probe_finish)
        rows = read_csv(result_path)
        if len(rows) != 1:
            raise ValueError(f"qualification result {b} has wrong row count")
        row = rows[0]
        numeric = [float(row.get(key, "nan")) for key in
                   ("estimate", "se", "max_abs_gradient", "lower", "upper",
                    "laplace_oracle_error")]
        if (int(row.get("index", -1)) != expected["local_index"]
                or int(row.get("replicate", -1)) != expected["replicate"]
                or int(row.get("seed", -1)) != expected["seed"]
                or not stage_two_same_truth(row.get("a"), expected["a"])
                or row.get("state") != "completed"
                or row.get("valid_interval", "").lower() != "true"
                or row.get("oracle_pass", "").lower() != "true"
                or int(row.get("convergence", -1)) != 0
                or row.get("pdHess", "").lower() != "true"
                or row.get("clamp_at_optimum") != "ok"
                or row.get("interval_status") != "profile"
                or row.get("profile_boundary", "").lower() != "false"
                or not all(math.isfinite(value) for value in numeric)
                or numeric[1] <= 0 or numeric[2] >= 1e-3
                or numeric[3] >= numeric[4] or abs(numeric[5]) >= 1e-6):
            raise ValueError(f"qualification result {b} failed its frozen health/oracle checks")
        batches.append({"batch_id": b, **expected,
                        "registry_sha256": registry_sha, "manifest_sha256": manifest_sha,
                        "registry_path": str(registry_path.resolve()),
                        "manifest_path": str(manifest_path.resolve()),
                        "supervisor_sha256": sha256(supervisor_path),
                        "supervisor_path": str(supervisor_path.resolve()),
                        "result_sha256": sha256(result_path), "status": "completed",
                        "result_path": str(result_path.resolve()),
                        "subset_complete": True, "campaign_complete": False,
                        "returncode": 0, "valid_interval": True, "oracle_pass": True})

    probe_elapsed = max(probe_finishes) - min(probe_starts)
    receipt = {"schema": "native-sd-adapter-probe-attempts-v1", "status": "INCOMPLETE",
               "qualification_status": "NOT_QUALIFIED",
               "calibration_claim": False, "campaign_complete": False,
               "subset_complete": True, "planned_attempts": 9000, "attempted": 3,
               "source_manifest_sha256": SEED_SHA,
               "aggregate_registry_sha256": qualification_registry_digest(batches),
               "first_look_registry_sha256": prepared["first_look_registry_sha256"],
               "first_look_seal_sha256": prepared["first_look_seal_sha256"],
               "source_registry_sha256": prepared["source_registry_sha256"],
               "library_artifacts": prepared["library_artifacts"],
               # Preserve the exact path spelling in the preparation receipt;
               # path resolution above is for identity checks only.
               "library": prepared["library"],
               "preparation_receipt_sha256": sha256(preparation),
               "preparation_receipt_path": str(preparation.resolve()),
               "qualification_root": str(root),
               "probe_span_seconds": probe_elapsed,
               "whole_run_elapsed_seconds": None,
               "qualification_blocker": (
                   "The original runner did not retain whole-run elapsed time; the probe span "
                   "excludes setup and final receipt validation."),
               "finalizer_source_path": str(Path(__file__).resolve()),
               "finalizer_source_sha256": sha256(Path(__file__).resolve()),
               "validator_source_path": str(Path(__file__).with_name("stage_two.py").resolve()),
               "validator_source_sha256": sha256(Path(__file__).with_name("stage_two.py")),
               "batches": batches}
    # Exercise the existing full receipt and replay validators on an in-memory
    # content candidate. Never serialize this candidate as PASS: the total-run
    # timing gate cannot be reconstructed from the retained probe receipts.
    # The equality below only lets the shared validator exercise the receipt
    # shape. This offline record does not claim an externally retained digest.
    candidate = dict(receipt)
    candidate.update(schema="native-sd-adapter-qualification-v1", status="PASS",
                     elapsed_seconds=probe_elapsed,
                     external_preparation_receipt_sha256=receipt["preparation_receipt_sha256"])
    validate_adapter_qualification(candidate)
    replay_adapter_qualification(candidate)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    return receipt


def stage_two_same_truth(observed: object, expected: object) -> bool:
    from stage_two import same_finite_numeric_value
    return same_finite_numeric_value(observed, expected)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("prepared_root", type=Path)
    parser.add_argument("--library", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    receipt = finalize(args.prepared_root, args.library, args.output)
    print(json.dumps(receipt, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
