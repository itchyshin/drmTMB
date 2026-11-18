#!/usr/bin/env python3
"""Prepare three sealed-identity batch capsules; never runs fits."""
import argparse
import json
import subprocess
import tempfile
from pathlib import Path

from stage_two import (CAPS, MASTER, SEED_SHA, batch_rows, read_csv, sha256,
                       attempt_digest, validate_binary_receipt, validate_go, validate_source, write_batch_manifest,
                       validate_prior_stream, write_registry, first_look_replay_command,
                       _clean_current_adapter,
                       clean_current_stage_two_design_receipt)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("first_look", type=Path)
    p.add_argument("source_registry", type=Path)
    p.add_argument("library", type=Path)
    p.add_argument("frozen_manifest", type=Path)
    p.add_argument("go_record", type=Path)
    p.add_argument("first_look_seal", type=Path)
    p.add_argument("--go-record-sha256", required=True)
    p.add_argument("--first-look-seal-sha256", required=True)
    p.add_argument("--rscript", default="Rscript")
    p.add_argument("prior_manifests", nargs="+", type=Path,
                   help="pilot, qualification, and first-look manifests")
    p.add_argument("new_root", type=Path)
    a = p.parse_args()
    root = a.new_root.absolute()
    if root.exists():
        raise FileExistsError(f"refusing to overwrite stage-two root: {root}")
    if not a.library.is_dir() or not a.source_registry.is_file():
        raise ValueError("original Bernoulli library and source registry are required")
    first_seal = json.loads(a.first_look_seal.read_text())
    go = json.loads(a.go_record.read_text())
    go_sha = sha256(a.go_record)
    first_seal_sha = sha256(a.first_look_seal)
    if go_sha != a.go_record_sha256 or first_seal_sha != a.first_look_seal_sha256:
        raise ValueError("GO record or first-look seal does not match its external digest")
    validate_go(go, go_sha, first_seal, a.go_record, first_seal_sha)
    validate_binary_receipt(first_seal, a.library)
    if first_seal.get("registry_sha256") != sha256(a.source_registry):
        raise ValueError("first-look external seal does not match the supplied source registry")
    if len(a.prior_manifests) != 3:
        raise ValueError("supply exactly the pilot, qualification, and first-look manifests in that order")
    expected_rows = (6, 3000, 3000)
    expected_masters = (2026101702, 2026101704, 2026101703)
    prior_modes = ("pilot", "qualification", "production")
    for path, n, master, mode in zip(a.prior_manifests, expected_rows, expected_masters, prior_modes):
        validate_prior_stream(read_csv(path), path, n, master)
        verified = subprocess.run([a.rscript, str(Path(__file__).with_name("verify-prior-seeds.R")),
                                   str(path.resolve(strict=True)), str(n), str(master), mode],
                                  capture_output=True, text=True, timeout=60)
        if verified.returncode != 0:
            raise ValueError(f"prior manifest differs from its exact deterministic {mode} stream: "
                             + verified.stderr[-2000:])
    if attempt_digest(a.first_look, expected_results=3000) != first_seal.get("attempts_sha256"):
        raise ValueError("first-look raw attempt digest differs from its external seal")
    # Require a retained terminal first-look decision artifact and bind it to
    # the external seal before trusting the GO record.
    decision = Path(first_seal["decision_path"])
    if not decision.is_file() or sha256(decision) != first_seal.get("decision_sha256"):
        raise ValueError("first-look decision file is absent or differs from its external seal")
    decision_text = decision.read_text(errors="replace")
    if "look2_required" not in decision_text:
        raise ValueError("sealed first-look decision does not record look2_required")
    supervisor_path = a.first_look / "supervisor-receipt.json"
    supervisor = json.loads(supervisor_path.read_text())
    if (not supervisor.get("campaign_complete") or supervisor.get("interrupted")
            or not supervisor.get("subset_complete")
            or any(x.get("status") not in {"completed", "error", "timeout"}
                   for x in supervisor.get("cases", []))):
        raise ValueError("first-look supervisor receipt is incomplete or unresolved")
    registry_rows = read_csv(a.source_registry)
    if not registry_rows or not any(Path(x["path"]).name == "manifest.csv" for x in registry_rows):
        raise ValueError("source registry does not pin the Bernoulli source manifest")
    # Validate all registry artifacts and insist that installed package files
    # resolve under the requested original Bernoulli library.
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "native-calibration"))
    from integrity import verify
    verify(a.first_look)
    lib = a.library.resolve(strict=True)
    runtime = [Path(x["path"]).resolve(strict=True) for x in registry_rows
               if Path(x["path"]).name in {"drmTMB.rdb", "drmTMB.rdx"}
               or Path(x["path"]).suffix.lower() in {".so", ".dylib", ".dll"}]
    if len(runtime) < 3 or any(lib not in p.parents for p in runtime):
        raise ValueError("registry is not bound to the supplied original Bernoulli library")
    excluded = set()
    for path in a.prior_manifests:
        rows = read_csv(path)
        if "seed" not in (rows[0] if rows else {}):
            raise ValueError(f"prior manifest has no seed column: {path}")
        excluded.update(int(r["seed"]) for r in rows)
    source = read_csv(a.frozen_manifest)
    validate_source(source, a.frozen_manifest, excluded)
    source_sha = sha256(a.frozen_manifest)
    clean_current_sha = _clean_current_adapter().EXPECTED_SHA256
    if source_sha not in {SEED_SHA, clean_current_sha}:
        raise ValueError("stage-two source digest is not a frozen supported manifest")
    clean_current = source_sha == clean_current_sha
    source_design_mode = "clean_current" if clean_current else "stage_two_not_authorized"
    worker_design_mode = "clean_current_stage_two" if clean_current else "production"
    source_master = int(source[0]["master_seed"])
    # Before any stage-two capsule is created, independently replay the sealed
    # first-look worker rows through the frozen staged analyzer. Retain this
    # exact standardized table and replay receipt in the prepared root.
    with tempfile.TemporaryDirectory(prefix="native-sd-stage-two-replay-") as tmp:
        standardized_tmp = Path(tmp) / "first-look-standardized.csv"
        replay_cmd = first_look_replay_command(
            first_seal, a.first_look.resolve(strict=True),
            a.first_look_seal.resolve(strict=True), standardized_tmp, a.rscript)
        replay = subprocess.run(replay_cmd, capture_output=True, text=True, timeout=120)
        if replay.returncode != 0 or not standardized_tmp.is_file():
            raise RuntimeError("first-look raw replay failed before preparation: " + replay.stderr[-2000:])
        standardized_bytes = standardized_tmp.read_bytes()
        replay_receipt_bytes = Path(str(standardized_tmp)+".receipt.json").read_bytes()
    if root.exists():
        raise FileExistsError(root)
    root.mkdir(parents=True)
    standardized_path = root / "first-look-standardized.csv"
    replay_receipt_path = root / "first-look-replay-receipt.json"
    standardized_path.write_bytes(standardized_bytes)
    replay_receipt_path.write_bytes(replay_receipt_bytes)
    receipts = []
    for b in (1, 2, 3):
        d = root / f"batch-{b}"
        d.mkdir()
        rows = batch_rows(source, b)
        manifest = d / "manifest.csv"
        write_batch_manifest(rows, manifest)
        with (d / "design-receipt.txt").open("x") as f:
            if clean_current:
                f.write(clean_current_stage_two_design_receipt(b, source_sha))
            else:
                f.write("\n".join(["design_id=native-bernoulli-sd-ordinary-q1-stage-two-v1",
                                    f"design_mode={worker_design_mode}", f"master_seed={source_master}",
                                    "planned_attempts=3000", f"workers={CAPS['workers']}",
                                    f"per_case_timeout_seconds={CAPS['case_timeout_seconds']}",
                                    f"campaign_timeout_seconds={CAPS['batch_timeout_seconds']}",
                                    f"batch_id={b}", "stage_two_status=authorized_by_external_go_record",
                                    "status=prepared_not_launched"]) + "\n")
        mapping = d / "conversion-receipt.json"
        mapping.write_text(json.dumps({
            "batch_id": b, "source_manifest_sha256": sha256(a.frozen_manifest),
            "first_look_registry_sha256": first_seal["registry_sha256"],
            "first_look_decision_sha256": first_seal["decision_sha256"],
            "go_record_sha256": sha256(a.go_record), "source_row_start": (b-1)*3000+1,
            "source_row_end": b*3000, "local_index_start": 1, "local_index_end": 3000,
            "replicates": [1001, 4000], "master_seed": source_master,
            "design_mode_source": source_design_mode, "design_mode_worker": worker_design_mode,
            "manifest_sha256": sha256(manifest),
            "status": "prepared_not_launched"}, indent=2, sort_keys=True) + "\n")
        seal = write_registry(d, a.source_registry, a.first_look, lib, manifest,
                              source_manifest=a.frozen_manifest)
        receipts.append({"batch_id": b, "manifest_sha256": sha256(manifest),
                         "registry_sha256": seal, "conversion_receipt_sha256": sha256(mapping)})
    root_receipt = {"status": "prepared_not_launched", "no_fits_launched": True,
                    "source_manifest_sha256": source_sha,
                    "source_design_mode": source_design_mode,
                    "worker_design_mode": worker_design_mode,
                    "go_record_sha256": sha256(a.go_record),
                    "first_look_registry_sha256": first_seal["registry_sha256"],
                    "first_look_decision_sha256": first_seal["decision_sha256"],
                    "first_look_seal_sha256": first_seal_sha,
                    "first_look_standardized_sha256": sha256(standardized_path),
                    "first_look_replay_receipt_sha256": sha256(replay_receipt_path),
                    "harness_archive_sha256": first_seal["harness_archive_sha256"],
                    "matched_original_native_artifacts": first_seal["matched_original_native_artifacts"],
                    "caps": CAPS, "batches": receipts}
    (root / "root-preparation-receipt.json").write_text(json.dumps(root_receipt, indent=2, sort_keys=True)+"\n")
    print(json.dumps(root_receipt, indent=2))


if __name__ == "__main__":
    main()
