#!/usr/bin/env python3
"""Run one sealed probe in each of three isolated batch registries."""
import argparse
import json
import math
import os
import sys
import time
from pathlib import Path

from stage_two import (qualification_registry_digest,
                       read_csv, sha256, validate_adapter_qualification, validate_batch_manifest,
                       validate_qualification_elapsed, validate_qualification_subset,
                       worker_library_search_path, resolve_adapter_qualification_source,
                       resolve_stage_two_source, validate_clean_current_batch_manifest,
                       resolve_registered_profile_worker)


def main():
    started = time.monotonic()
    p = argparse.ArgumentParser()
    p.add_argument("prepared_root", type=Path)
    p.add_argument("--library", required=True, type=Path)
    p.add_argument("--preparation-receipt-sha256", required=True,
                   help="digest retained outside the prepared root before launch")
    p.add_argument("--rscript", default="Rscript")
    p.add_argument("--source-mode", choices=("legacy", "clean_current"),
                   default="legacy")
    a = p.parse_args()
    root = a.prepared_root.resolve(strict=True)
    library = a.library.resolve(strict=True)
    from integrity import verify as verify_registry
    preparation = root / "adapter-qualification-preparation-receipt.json"
    expected_preparation_sha = a.preparation_receipt_sha256
    if (len(expected_preparation_sha) != 64
            or any(c not in "0123456789abcdef" for c in expected_preparation_sha)):
        raise ValueError("externally retained preparation receipt digest is malformed")
    if sha256(preparation) != expected_preparation_sha:
        raise ValueError("preparation receipt differs from externally retained digest")
    receipt = json.loads(preparation.read_text())
    if (receipt.get("schema") != "native-sd-adapter-qualification-preparation-v1"
            or receipt.get("status") != "prepared_not_launched"
            or receipt.get("no_fits_launched") is not True
            or receipt.get("calibration_claim") is not False
            or receipt.get("campaign_complete") is not False
            or receipt.get("source_design_mode", "production") != (
                "clean_current" if a.source_mode == "clean_current" else "production")
            or Path(receipt.get("library", "")).resolve(strict=True) != library
            or len(receipt.get("batches", [])) != 3
            or len(receipt.get("library_artifacts", [])) < 3):
        raise ValueError("prepared adapter-qualification receipt is incomplete or altered")
    for artifact in receipt["library_artifacts"]:
        path = Path(artifact["path"]).resolve(strict=True)
        if library not in path.parents or sha256(path) != artifact["sha256"]:
            raise ValueError("original Bernoulli library artifact differs from preparation seal")
    source_contract = None
    planned = []
    for b, item in enumerate(receipt["batches"], 1):
        d = root / f"batch-{b}"
        verify_registry(d)
        registry_sha = sha256(d / "source-hashes.csv")
        manifest_sha = sha256(d / "manifest.csv")
        if (item.get("batch_id") != b or item.get("registry_sha256") != registry_sha
                or item.get("manifest_sha256") != manifest_sha):
            raise ValueError(f"batch {b} no longer matches its preparation receipt")
        rows = read_csv(d / "manifest.csv")
        registry_rows = read_csv(d / "source-hashes.csv")
        worker = resolve_registered_profile_worker(registry_rows)
        sources, clean_current = resolve_stage_two_source(
            registry_rows, receipt["source_manifest_sha256"])
        if clean_current != (a.source_mode == "clean_current"):
            raise ValueError("batch registry source mode differs from the requested adapter mode")
        if source_contract is None:
            source_contract = resolve_adapter_qualification_source(
                sources, source_mode=a.source_mode)
        elif sources != source_contract["source_manifest"]:
            raise ValueError("adapter batches point to different frozen source manifests")
        if clean_current:
            validate_clean_current_batch_manifest(rows, sources, b)
        else:
            validate_batch_manifest(rows, source_contract["source_rows"], b)
        expected = source_contract["cases"][b - 1]
        if (item.get("local_index") != expected["local_index"]
                or item.get("stage_two_index") != expected["stage_two_index"]
                or item.get("replicate") != expected["replicate"]
                or str(item.get("a")) != expected["a"]):
            raise ValueError("qualification mapping differs from frozen source rows")
        result = d / f"result-{expected['local_index']:04d}.csv"
        supervisor = d / "supervisor-receipt.json"
        if result.exists() or supervisor.exists():
            raise FileExistsError(f"refusing to overwrite prior qualification attempt in {d}")
        planned.append((b, d, expected, registry_sha, manifest_sha, worker))

    from run import supervise
    aggregate = []
    for b, d, expected, registry_sha, manifest_sha, worker in planned:
        remain = 240 - (time.monotonic() - started)
        if remain < 1:
            raise TimeoutError("adapter qualification exceeded its 240-second total cap")
        env = {"DRMTMB_SD_TEST_LIBRARY": worker_library_search_path(library),
               "DRMTMB_SD_REGISTRY_SHA256": registry_sha}
        supervise([expected["local_index"]],
                  lambda i: [a.rscript, str(worker), str(d), str(i)], d,
                  workers=3, case_timeout=120, campaign_timeout=min(240, remain),
                  env=env, registry_sha256=registry_sha,
                  design_mode=source_contract["worker_design_mode"])
        # The per-batch supervisor cap does not include all adapter work or
        # cleanup. Recheck the single overall deadline after every probe,
        # including the final probe, before a PASS receipt can be written.
        validate_qualification_elapsed(time.monotonic() - started)
        supervisor_path = d / "supervisor-receipt.json"
        supervisor = json.loads(supervisor_path.read_text())
        case_receipt = validate_qualification_subset(supervisor, expected["local_index"],
                                                     registry_sha, manifest_sha)
        result_path = d / f"result-{expected['local_index']:04d}.csv"
        result = read_csv(result_path)
        if len(result) != 1:
            raise RuntimeError(f"qualification result {b} has wrong row count")
        row = result[0]
        if (int(row.get("index", -1)) != expected["local_index"]
                or int(row.get("replicate", -1)) != expected["replicate"]
                or int(row.get("seed", -1)) != expected["seed"]
                or float(row.get("a", float("nan"))) != float(expected["a"])
                or row.get("state") != "completed" or row.get("valid_interval") not in {"TRUE", "True"}
                or row.get("oracle_pass") not in {"TRUE", "True"}
                or not math.isclose(float(row.get("profile_level", "nan")),
                                    0.95, rel_tol=0.0, abs_tol=1e-12)):
            raise RuntimeError(f"qualification worker {b} did not pass health and oracle checks")
        aggregate.append({"batch_id": b, **expected,
                          "registry_sha256": registry_sha, "manifest_sha256": manifest_sha,
                          "registry_path": str((d / "source-hashes.csv").resolve()),
                          "manifest_path": str((d / "manifest.csv").resolve()),
                          "supervisor_sha256": sha256(supervisor_path),
                          "supervisor_path": str(supervisor_path.resolve()),
                          "result_sha256": sha256(result_path), "status": "completed",
                          "result_path": str(result_path.resolve()),
                          "subset_complete": True, "campaign_complete": False,
                          "returncode": 0, "valid_interval": True, "oracle_pass": True})
    final = {"schema": "native-sd-adapter-qualification-v1", "status": "PASS",
             "calibration_claim": False, "campaign_complete": False,
             "subset_complete": True, "planned_attempts": 9000, "attempted": 3,
             "source_manifest_sha256": source_contract["source_manifest_sha256"],
             "source_manifest_path": str(source_contract["source_manifest"].resolve()),
             "source_design_mode": source_contract["source_design_mode"],
             "worker_design_mode": source_contract["worker_design_mode"],
             "aggregate_registry_sha256": qualification_registry_digest(aggregate),
             "first_look_registry_sha256": receipt["first_look_registry_sha256"],
             "first_look_seal_sha256": receipt["first_look_seal_sha256"],
             "source_registry_sha256": receipt["source_registry_sha256"],
             "library_artifacts": receipt["library_artifacts"],
             "library": str(library),
             "preparation_receipt_sha256": sha256(preparation),
             "external_preparation_receipt_sha256": expected_preparation_sha,
             "preparation_receipt_path": str(preparation.resolve()),
             "qualification_root": str(root),
             "library": str(library), "elapsed_seconds": time.monotonic() - started,
             "batches": aggregate}
    validate_adapter_qualification(final)
    output = root / "adapter-qualification-receipt.json"
    if output.exists():
        raise FileExistsError(f"refusing to overwrite {output}")
    output.write_text(json.dumps(final, indent=2, sort_keys=True) + "\n")
    print(json.dumps(final, indent=2))


if __name__ == "__main__":
    main()
