#!/usr/bin/env python3
"""Prepare three isolated adapter probes without a stage-two GO decision."""
import argparse
import csv
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from stage_two import (MASTER, attempt_digest,
                       batch_rows, read_csv, sealed_reconstruction_file, sha256,
                       validate_binary_receipt,
                       validate_prior_stream, write_batch_manifest, write_registry,
                       resolve_adapter_qualification_source,
                       clean_current_adapter_design_receipt)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("first_look", type=Path)
    p.add_argument("source_registry", type=Path)
    p.add_argument("library", type=Path)
    p.add_argument("frozen_manifest", type=Path)
    p.add_argument("first_look_seal", type=Path)
    p.add_argument("--first-look-seal-sha256", required=True)
    p.add_argument("--source-mode", choices=("legacy", "clean_current"),
                   default="legacy")
    p.add_argument("--source-overlay", type=Path,
                   help=("verified source tree overlay for the adapter worker; "
                         "the sealed first-look source tree remains unchanged"))
    p.add_argument("--rscript", default="Rscript")
    p.add_argument("prior_manifests", nargs=3, type=Path,
                   help="pilot, qualification, and first-look manifests")
    p.add_argument("new_root", type=Path)
    a = p.parse_args()
    root = a.new_root.absolute()
    if root.exists():
        raise FileExistsError(f"refusing to overwrite adapter qualification root: {root}")
    if not a.library.is_dir() or not a.source_registry.is_file():
        raise ValueError("original Bernoulli library and source registry are required")
    seal = json.loads(a.first_look_seal.read_text())
    if sha256(a.first_look_seal) != a.first_look_seal_sha256:
        raise ValueError("first-look seal differs from externally supplied digest")
    if seal.get("registry_sha256") != sha256(a.source_registry):
        raise ValueError("first-look seal does not bind the supplied source registry")
    validate_binary_receipt(seal, a.library)
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "native-calibration"))
    from integrity import verify
    verify(a.first_look)
    if (sha256(a.first_look / "source-hashes.csv") != seal.get("registry_sha256")
            or sha256(a.first_look / "manifest.csv") == ""
            or sha256(a.first_look / "supervisor-receipt.json") == ""
            or sha256(a.first_look / "source-hashes.csv") != sha256(a.source_registry)):
        raise ValueError("first-look source artifacts are incomplete or not seal-bound")
    if attempt_digest(a.first_look, expected_results=3000) != seal.get("attempts_sha256"):
        raise ValueError("first-look attempts do not match the retained seal")
    decision = Path(seal["decision_path"]).resolve(strict=True)
    if sha256(decision) != seal.get("decision_sha256") or "look2_required" not in decision.read_text(errors="replace"):
        raise ValueError("first-look decision is absent, altered, or not look2_required")
    if a.first_look.resolve(strict=True) not in a.library.resolve(strict=True).parents and not any(
            a.library.resolve(strict=True) in Path(x["path"]).resolve(strict=True).parents
            for x in read_csv(a.source_registry)
            if Path(x["path"]).name in {"drmTMB.rdb", "drmTMB.rdx"}
            or Path(x["path"]).suffix.lower() in {".so", ".dylib", ".dll"}):
        raise ValueError("source registry is not tied to supplied Bernoulli library")
    supervisor = json.loads((a.first_look / "supervisor-receipt.json").read_text())
    if (supervisor.get("campaign_complete") is not True or supervisor.get("subset_complete") is not True
            or supervisor.get("interrupted") is not False):
        raise ValueError("first-look supervisor receipt is not a complete campaign")
    with tempfile.TemporaryDirectory(prefix="sd-adapter-qualification-replay-") as tmp:
        standardized = Path(tmp) / "first-look-standardized.csv"
        verifier = sealed_reconstruction_file(seal, "verify-first-look.R")
        replay = subprocess.run([a.rscript, str(verifier),
                                 str(a.first_look.resolve(strict=True)),
                                 str(a.first_look_seal.resolve(strict=True)), str(standardized)],
                                capture_output=True, text=True, timeout=120)
        if replay.returncode or not standardized.is_file():
            raise ValueError("first-look replay failed before adapter qualification: " + replay.stderr[-1500:])
    prior_specs = ((6, 2026101702, "pilot"), (3000, 2026101704, "qualification"),
                   (3000, 2026101703, "production"))
    excluded = set()
    for path, (n, master, mode) in zip(a.prior_manifests, prior_specs):
        rows = read_csv(path)
        validate_prior_stream(rows, path, n, master)
        result = subprocess.run([a.rscript, str(Path(__file__).with_name("verify-prior-seeds.R")),
                                 str(path.resolve(strict=True)), str(n), str(master), mode],
                               capture_output=True, text=True, timeout=60)
        if result.returncode:
            raise ValueError(f"prior {mode} stream failed deterministic verification: {result.stderr[-1500:]}")
        excluded.update(int(row["seed"]) for row in rows)
    source_contract = resolve_adapter_qualification_source(
        a.frozen_manifest, source_mode=a.source_mode, excluded_seeds=excluded)
    source = source_contract["source_rows"]
    if a.source_mode == "clean_current":
        source_batches = source_contract["batches"]
    else:
        source_batches = None
    probe_map = source_contract["cases"]
    root.mkdir(parents=True)
    batch_receipts = []
    for b in (1, 2, 3):
        d = root / f"batch-{b}"; d.mkdir()
        manifest = d / "manifest.csv"
        batch = source_batches[b - 1] if source_batches is not None else batch_rows(source, b)
        write_batch_manifest(batch, manifest)
        case = probe_map[b - 1]
        if a.source_mode == "clean_current":
            design_receipt = clean_current_adapter_design_receipt(
                b, source_contract["source_manifest_sha256"], case)
        else:
            design_receipt = "\n".join([
            "design_id=native-bernoulli-sd-adapter-qualification-v1",
            "design_mode=production", f"master_seed={MASTER}",
            "planned_attempts=3000", "workers=3", "per_case_timeout_seconds=120",
            "campaign_timeout_seconds=240", f"batch_id={b}",
            "stage_two_status=adapter_qualification_only_no_final_go",
            f"qualification_local_index={case['local_index']}",
            f"qualification_stage_two_index={case['stage_two_index']}",
            "calibration_claim=false", "status=prepared_not_launched"]) + "\n"
        (d / "design-receipt.txt").write_text(design_receipt)
        (d / "conversion-receipt.json").write_text(json.dumps({
            "purpose": "adapter_qualification_only", "calibration_claim": False,
            "batch_id": b, "source_manifest_sha256": source_contract["source_manifest_sha256"],
            "source_design_mode": source_contract["source_design_mode"],
            "worker_design_mode": source_contract["worker_design_mode"],
            "first_look_registry_sha256": seal["registry_sha256"],
            "first_look_seal_sha256": a.first_look_seal_sha256,
            "source_row_start": 3000 * (b - 1) + 1, "source_row_end": 3000 * b,
            "local_index_start": 1, "local_index_end": 3000,
            "qualification_case": case, "manifest_sha256": sha256(manifest),
            "status": "prepared_not_launched"}, indent=2, sort_keys=True) + "\n")
        registry_kwargs = {
            "source_manifest": source_contract["source_manifest"]
        }
        if a.source_overlay is not None:
            registry_kwargs["source_overlay"] = a.source_overlay
        registry_sha = write_registry(d, a.source_registry, a.first_look,
                                      a.library.resolve(strict=True), manifest,
                                      **registry_kwargs)
        batch_receipts.append({"batch_id": b, "local_index": case["local_index"],
                               "stage_two_index": case["stage_two_index"],
                               "replicate": case["replicate"], "a": case["a"],
                               "manifest_sha256": sha256(manifest),
                               "registry_sha256": registry_sha})
    receipt = {"schema": "native-sd-adapter-qualification-preparation-v1",
               "status": "prepared_not_launched", "no_fits_launched": True,
               "calibration_claim": False, "campaign_complete": False,
               "planned_attempts": 9000,
               "source_manifest_sha256": source_contract["source_manifest_sha256"],
               "source_manifest_path": str(source_contract["source_manifest"].resolve()),
               "source_design_mode": source_contract["source_design_mode"],
               "worker_design_mode": source_contract["worker_design_mode"],
               "first_look_registry_sha256": seal["registry_sha256"],
               "source_registry_sha256": seal["registry_sha256"],
               "first_look_seal_sha256": a.first_look_seal_sha256,
               "library": str(a.library.resolve(strict=True)),
               "library_artifacts": [{"path": row["path"], "sha256": row["sha256"]}
                                     for row in read_csv(a.source_registry)
                                     if Path(row["path"]).name in {"drmTMB.rdb", "drmTMB.rdx"}
                                     or Path(row["path"]).suffix.lower() in {".so", ".dylib", ".dll"}],
               "batches": batch_receipts}
    target = root / "adapter-qualification-preparation-receipt.json"
    target.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n")
    print(json.dumps(receipt, indent=2))


if __name__ == "__main__":
    main()
