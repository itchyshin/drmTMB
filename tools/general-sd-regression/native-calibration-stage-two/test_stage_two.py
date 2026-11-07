#!/usr/bin/env python3
"""Pure contract tests for stage-two identity conversion; no fits or network."""
import csv
import contextlib
import importlib.util
import io
import json
import shutil
import subprocess
import sys
import tarfile
import tempfile
import types
import unittest
from unittest.mock import patch
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import stage_two
import record_completed_adapter_attempts as finalizer


def tiny_source():
    rows = []
    for i in range(1, 9001):
        b = (i - 1) // 3000
        j = (i - 1) % 3000 + 1
        rows.append({"index": str(i), "a": str((-0.5, 0.0, 0.5)[b]),
                     "replicate": str(1000+j), "seed": str(i+10000),
                     "groups": "160", "repeats": "16", "beta0": "-0.3",
                     "beta1": "0.6", "alpha0": "-0.2231435513142097",
                     "design_mode": "stage_two_not_authorized",
                     "master_seed": "2026101705"})
    return rows


def write_adapter_runner_fixture(root):
    """Build a complete synthetic adapter capsule for no-fit CLI tests."""
    root.mkdir()
    library = root / "library"
    (library / "R").mkdir(parents=True)
    (library / "libs").mkdir()
    artifacts = []
    for rel, contents in (("R/drmTMB.rdb", "synthetic rdb"),
                          ("R/drmTMB.rdx", "synthetic rdx"),
                          ("libs/drmTMB.so", "synthetic shared object")):
        path = library / rel
        path.write_text(contents)
        artifacts.append({"path": str(path.resolve()), "sha256": stage_two.sha256(path)})

    source_manifest = HERE.parents[2] / "docs/dev-log/general-sd-regression/stage-two-manifest.csv"
    if stage_two.sha256(source_manifest) != stage_two.SEED_SHA:
        raise AssertionError("fixture requires the frozen 9,000-row source manifest")
    original_manifest = root / "original" / "manifest.csv"
    original_manifest.parent.mkdir()
    original_manifest.write_text("index\n1\n")
    source_registry = root / "original-source-hashes.csv"
    registry_rows = [{"path": str(source_manifest.resolve()), "sha256": stage_two.sha256(source_manifest)},
                     {"path": str(original_manifest.resolve()), "sha256": stage_two.sha256(original_manifest)}]
    profile_worker = stage_two.BASE / "worker-095.R"
    relocated_worker = root / "source" / "native-calibration" / "worker-095.R"
    relocated_worker.parent.mkdir(parents=True)
    shutil.copy2(profile_worker, relocated_worker)
    registry_rows.append({"path": str(relocated_worker.resolve()),
                          "sha256": stage_two.sha256(relocated_worker)})
    registry_rows.extend(artifacts)
    with source_registry.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
        writer.writeheader()
        writer.writerows(registry_rows)

    source_rows = stage_two.read_csv(source_manifest)
    prepared = root / "prepared"
    prepared.mkdir()
    batches = []
    for batch in (1, 2, 3):
        directory = prepared / f"batch-{batch}"
        directory.mkdir()
        manifest = directory / "manifest.csv"
        stage_two.write_batch_manifest(stage_two.batch_rows(source_rows, batch), manifest)
        case = stage_two.adapter_qualification_case(source_rows, batch)
        (directory / "design-receipt.txt").write_text("status=prepared_not_launched\n")
        (directory / "conversion-receipt.json").write_text(json.dumps({"batch_id": batch}))
        registry_sha = stage_two.write_registry(
            directory, source_registry, prepared, library, manifest
        )
        batches.append({**case, "registry_sha256": registry_sha,
                        "manifest_sha256": stage_two.sha256(manifest)})

    preparation = {"schema": "native-sd-adapter-qualification-preparation-v1",
                   "status": "prepared_not_launched", "no_fits_launched": True,
                   "calibration_claim": False, "campaign_complete": False,
                   "planned_attempts": 9000, "source_manifest_sha256": stage_two.SEED_SHA,
                   "first_look_registry_sha256": stage_two.sha256(source_registry),
                   "source_registry_sha256": stage_two.sha256(source_registry),
                   "first_look_seal_sha256": "a" * 64,
                   "library": str(library.resolve()), "library_artifacts": artifacts,
                   "batches": batches}
    preparation_path = prepared / "adapter-qualification-preparation-receipt.json"
    preparation_path.write_text(json.dumps(preparation, indent=2, sort_keys=True) + "\n")
    return prepared, library, preparation_path


def write_clean_current_run_fixture(root):
    """Build an externally sealed, no-fit clean-current runner capsule."""
    _, library, _ = write_adapter_runner_fixture(root / "baseline")
    source_registry = root / "baseline" / "original-source-hashes.csv"
    adapter = stage_two._clean_current_adapter()
    source_manifest = adapter.DEFAULT_MANIFEST.resolve(strict=True)
    source_rows = stage_two.read_csv(source_manifest)

    first = root / "first-look"
    first.mkdir()
    first_manifest = first / "manifest.csv"
    first_manifest.write_text("index\n1\n")
    first_registry = first / "source-hashes.csv"
    with first_registry.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
        writer.writeheader()
        writer.writerow({"path": str(first_manifest.resolve()),
                         "sha256": stage_two.sha256(first_manifest)})
    decision = first / "decision.txt"
    decision.write_text("look2_required\n")
    go = root / "go-record.json"
    go.write_text("{}\n")
    first_seal = {
        "registry_sha256": stage_two.sha256(first_registry),
        "decision_sha256": stage_two.sha256(decision),
        "harness_archive_sha256": "h" * 64,
        "matched_original_native_artifacts": [{"name": "drmTMB.so",
                                               "sha256": "b" * 64}],
        "attempts_sha256": "attempts-digest",
    }
    first_seal_path = root / "first-look-seal.json"
    first_seal_path.write_text(json.dumps(first_seal, sort_keys=True) + "\n")

    prepared = root / "prepared-clean-current"
    prepared.mkdir()
    standardized = prepared / "first-look-standardized.csv"
    standardized.write_text("index\n1\n")
    replay_receipt = prepared / "first-look-replay-receipt.json"
    replay_receipt.write_text("{}\n")
    batches = []
    probe_cases = adapter.adapter_qualification_cases(adapter.load_batches(source_manifest))
    for batch_id in (1, 2, 3):
        directory = prepared / f"batch-{batch_id}"
        directory.mkdir()
        rows = stage_two.batch_rows(source_rows, batch_id)
        manifest = directory / "manifest.csv"
        stage_two.write_batch_manifest(rows, manifest)
        (directory / "design-receipt.txt").write_text(
            stage_two.clean_current_stage_two_design_receipt(
                batch_id, adapter.EXPECTED_SHA256))
        (directory / "conversion-receipt.json").write_text(
            json.dumps({"batch_id": batch_id}) + "\n")
        registry_sha = stage_two.write_registry(
            directory, source_registry, prepared, library, manifest,
            source_manifest=source_manifest)
        batches.append({"batch_id": batch_id, "registry_sha256": registry_sha})

    qualification_batches = []
    for batch_id, case in enumerate(probe_cases, start=1):
        directory = prepared / f"batch-{batch_id}"
        qualification_batches.append({
            **case,
            "manifest_sha256": stage_two.sha256(directory / "manifest.csv"),
            "registry_sha256": stage_two.sha256(directory / "source-hashes.csv"),
        })
    adapter_preparation = {
        "schema": "native-sd-adapter-qualification-preparation-v1",
        "status": "prepared_not_launched", "no_fits_launched": True,
        "calibration_claim": False, "campaign_complete": False,
        "planned_attempts": 9000,
        "source_manifest_sha256": adapter.EXPECTED_SHA256,
        "source_manifest_path": str(source_manifest),
        "source_design_mode": "clean_current",
        "worker_design_mode": "clean_current_stage_two",
        "first_look_registry_sha256": stage_two.sha256(first_registry),
        "source_registry_sha256": stage_two.sha256(first_registry),
        "first_look_seal_sha256": stage_two.sha256(first_seal_path),
        "library": str(library.resolve()),
        "library_artifacts": [
            {"path": str((library / rel).resolve()),
             "sha256": stage_two.sha256(library / rel)}
            for rel in ("R/drmTMB.rdb", "R/drmTMB.rdx", "libs/drmTMB.so")
        ],
        "batches": qualification_batches,
    }
    (prepared / "adapter-qualification-preparation-receipt.json").write_text(
        json.dumps(adapter_preparation, indent=2, sort_keys=True) + "\n")

    root_receipt = {
        "status": "prepared_not_launched", "no_fits_launched": True,
        "source_manifest_sha256": adapter.EXPECTED_SHA256,
        "source_design_mode": "clean_current",
        "worker_design_mode": "clean_current_stage_two",
        "go_record_sha256": stage_two.sha256(go),
        "first_look_registry_sha256": first_seal["registry_sha256"],
        "first_look_decision_sha256": first_seal["decision_sha256"],
        "first_look_seal_sha256": stage_two.sha256(first_seal_path),
        "first_look_standardized_sha256": stage_two.sha256(standardized),
        "first_look_replay_receipt_sha256": stage_two.sha256(replay_receipt),
        "harness_archive_sha256": first_seal["harness_archive_sha256"],
        "matched_original_native_artifacts": first_seal[
            "matched_original_native_artifacts"],
        "batches": batches,
    }
    root_receipt_path = prepared / "root-preparation-receipt.json"
    root_receipt_path.write_text(json.dumps(root_receipt, sort_keys=True) + "\n")
    external = {
        "go_record_path": str(go.resolve()),
        "go_record_sha256": stage_two.sha256(go),
        "first_look_seal_path": str(first_seal_path.resolve()),
        "first_look_seal_sha256": stage_two.sha256(first_seal_path),
        "first_look_root": str(first.resolve()),
        "first_look_decision_path": str(decision.resolve()),
        "root_preparation_receipt_sha256": stage_two.sha256(root_receipt_path),
        "batch_registry_sha256": {str(x["batch_id"]): x["registry_sha256"]
                                  for x in batches},
        "rscript": "Rscript",
    }
    external_path = root / "external-seals.json"
    external_path.write_text(json.dumps(external, sort_keys=True) + "\n")
    return prepared, external_path, library


def invoke_adapter_runner_without_fits(prepared, library, preparation_digest,
                                      source_mode="legacy"):
    """Exercise the actual CLI path while replacing the supervisor with a recorder."""
    calls = []
    worker_library_paths = []
    worker_paths = []
    integrity_spec = importlib.util.spec_from_file_location(
        "adapter_integrity_under_test", HERE.parent / "native-calibration" / "integrity.py"
    )
    integrity = importlib.util.module_from_spec(integrity_spec)
    integrity_spec.loader.exec_module(integrity)
    supervisor_module = types.ModuleType("run")

    def supervise(indices, command_factory, directory, workers, case_timeout,
                  campaign_timeout, env, registry_sha256, design_mode):
        del workers, case_timeout, campaign_timeout, design_mode
        calls.append(indices[0])
        worker_paths.append(str(Path(command_factory(indices[0])[1]).resolve()))
        worker_library_paths.append(env["DRMTMB_SD_TEST_LIBRARY"])
        manifest = stage_two.read_csv(directory / "manifest.csv")
        row = manifest[indices[0] - 1]
        receipt = {"planned_indices": indices, "subset_complete": True,
                   "campaign_complete": False, "interrupted": False,
                   "registry_sha256": registry_sha256,
                   "manifest_sha256": stage_two.sha256(directory / "manifest.csv"),
                   "cases": [{"index": indices[0], "status": "completed", "returncode": 0}]}
        (directory / "supervisor-receipt.json").write_text(json.dumps(receipt))
        result = {"index": row["index"], "replicate": row["replicate"],
                  "seed": row["seed"], "a": row["a"], "state": "completed",
                  "valid_interval": "TRUE", "oracle_pass": "TRUE",
                  "profile_level": "0.95", "convergence": "0",
                  "pdHess": "TRUE", "clamp_at_optimum": "ok",
                  "interval_status": "profile", "profile_boundary": "FALSE",
                  "estimate": row["a"], "se": "0.2",
                  "max_abs_gradient": "1e-7", "lower": "-1",
                  "upper": "1", "laplace_oracle_error": "1e-8"}
        with (directory / f"result-{indices[0]:04d}.csv").open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(result))
            writer.writeheader()
            writer.writerow(result)

    supervisor_module.supervise = supervise
    spec = importlib.util.spec_from_file_location(
        "adapter_runner_under_test", HERE / "run-adapter-qualification.py"
    )
    runner = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(runner)
    argv = [str(HERE / "run-adapter-qualification.py"), str(prepared),
            "--library", str(library), "--preparation-receipt-sha256", preparation_digest,
            "--source-mode", source_mode]
    with patch.dict(sys.modules, {"integrity": integrity, "run": supervisor_module}), \
            patch.object(sys, "argv", argv):
        runner.main()
    return calls, worker_library_paths, worker_paths


def write_go_fixture(root, registry_sha="r", decision_sha="d"):
    goal_path = root / "approved-goal.md"
    plan_path = root / "approved-plan.md"
    goal_path.write_text("approved programme goal\n")
    plan_path.write_text("approved execution plan\n")
    qroot = root / "qualification-root"
    if qroot.exists(): shutil.rmtree(qroot)
    qroot.mkdir()
    source_path = qroot / "stage-two-manifest.csv"
    source = tiny_source()
    with source_path.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=list(source[0]))
        writer.writeheader(); writer.writerows(source)
    source_sha = stage_two.sha256(source_path)
    batches = []
    prepared_batches = []
    for batch, local, global_i, replicate, truth in (
            (1, 1, 1, 1001, "-0.5"), (2, 1001, 4001, 2001, "0.0"),
            (3, 2001, 8001, 3001, "0.5")):
        d = qroot / f"batch-{batch}"; d.mkdir()
        manifest_path = d / "manifest.csv"
        stage_two.write_batch_manifest(stage_two.batch_rows(source, batch), manifest_path)
        registry_path = d / "source-hashes.csv"
        with registry_path.open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
            writer.writeheader()
            writer.writerow({"path": str(manifest_path.resolve()), "sha256": stage_two.sha256(manifest_path)})
            writer.writerow({"path": str(source_path.resolve()), "sha256": source_sha})
        registry_sha_batch = stage_two.sha256(registry_path)
        manifest_sha_batch = stage_two.sha256(manifest_path)
        supervisor_path = d / "supervisor-receipt.json"
        supervisor_path.write_text(json.dumps({"started_at": 1000.0 + batch,
            "finished_at": 1010.0 + batch, "planned_indices": [local],
            "subset_complete": True, "campaign_complete": False, "interrupted": False,
            "registry_sha256": registry_sha_batch, "manifest_sha256": manifest_sha_batch,
            "cases": [{"index": local, "status": "completed", "returncode": 0,
                       "started_at": 1000.0 + batch,
                       "finished_at": 1010.0 + batch}]}))
        result_path = d / f"result-{local:04d}.csv"
        result_row = {"index": local, "a": truth, "replicate": replicate,
            "seed": source[global_i-1]["seed"], "state": "completed", "estimate": "0.2",
            "se": "0.1", "convergence": 0, "pdHess": True,
            "max_abs_gradient": "0.00001", "clamp_at_optimum": "ok",
            "lower": "0.01", "upper": "0.4", "profile_level": "0.95",
            "interval_status": "profile",
            "profile_boundary": False, "valid_interval": True,
            "laplace_oracle_error": "1e-8", "oracle_pass": True}
        with result_path.open("w", newline="") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(result_row)); writer.writeheader(); writer.writerow(result_row)
        batches.append({"batch_id": batch, "local_index": local,
                        "stage_two_index": global_i, "replicate": replicate, "a": truth,
                        "seed": int(source[global_i-1]["seed"]),
                        "registry_sha256": registry_sha_batch,
                        "manifest_sha256": manifest_sha_batch,
                        "registry_path": str(registry_path), "manifest_path": str(manifest_path),
                        "supervisor_sha256": stage_two.sha256(supervisor_path),
                        "result_sha256": stage_two.sha256(result_path),
                        "supervisor_path": str(supervisor_path), "result_path": str(result_path),
                        "status": "completed", "subset_complete": True,
                        "campaign_complete": False, "returncode": 0,
                        "valid_interval": True, "oracle_pass": True})
        prepared_batches.append({"batch_id": batch, "local_index": local,
            "stage_two_index": global_i, "replicate": replicate, "a": truth,
            "registry_sha256": registry_sha_batch, "manifest_sha256": manifest_sha_batch})
    qualification = {"schema": "native-sd-adapter-qualification-v1", "status": "PASS",
                     "calibration_claim": False, "campaign_complete": False,
                     "subset_complete": True, "planned_attempts": 9000,
                     "attempted": 3, "elapsed_seconds": 180.0,
                     "source_manifest_sha256": source_sha,
                     "first_look_registry_sha256": "r" * 64,
                     "first_look_seal_sha256": "s" * 64,
                     "source_registry_sha256": "q" * 64,
                     "aggregate_registry_sha256": stage_two.qualification_registry_digest(batches),
                     "library": str(root / "library"), "batches": batches}
    lib = root / "library"; (lib / "R").mkdir(parents=True, exist_ok=True); (lib / "libs").mkdir(exist_ok=True)
    lib_files = [lib / "R" / "drmTMB.rdb", lib / "R" / "drmTMB.rdx", lib / "libs" / "drmTMB.so"]
    for file in lib_files: file.write_text("library artifact\n")
    qualification["library_artifacts"] = [{"path": str(file), "sha256": stage_two.sha256(file)}
                                           for file in lib_files]
    prep_path = qroot / "adapter-qualification-preparation-receipt.json"
    prep = {"schema": "native-sd-adapter-qualification-preparation-v1",
            "status": "prepared_not_launched", "no_fits_launched": True,
            "calibration_claim": False, "campaign_complete": False,
            "source_manifest_sha256": source_sha,
            "first_look_seal_sha256": "s" * 64,
            "first_look_registry_sha256": registry_sha,
            "source_registry_sha256": registry_sha, "library": str(lib),
            "library_artifacts": qualification["library_artifacts"], "batches": prepared_batches}
    prep_path.write_text(json.dumps(prep))
    qualification["qualification_root"] = str(qroot)
    qualification["preparation_receipt_path"] = str(prep_path)
    qualification["preparation_receipt_sha256"] = stage_two.sha256(prep_path)
    qualification["external_preparation_receipt_sha256"] = qualification["preparation_receipt_sha256"]
    timing = {"operational_stress": "PASS", "timing_gate": True,
              "independent_replicates": False, "planning_gate_seconds": 3000,
              "campaign_cap_seconds": 3600,
              "repeated_attempts": 15, "production_waves": 188,
              "maximum_worker_wall_seconds": 13.149663209915161,
              "additional_overhead_allowance_seconds": 180,
              "projected_production_seconds": 2652.1366834640503}
    qpath = root / "qualification.json"
    tpath = root / "timing.json"
    qpath.write_text(json.dumps(qualification))
    tpath.write_text(json.dumps(timing))
    go = {"approved_goal_id": "goal-test", "approved_goal_path": goal_path.name,
          "approved_goal_sha256": stage_two.sha256(goal_path),
          "approved_plan_path": plan_path.name,
          "approved_plan_sha256": stage_two.sha256(plan_path), "look": 1,
          "decision": "look2_required", "first_look_registry_sha256": registry_sha,
          "first_look_decision_sha256": decision_sha,
          "qualification_registry_sha256": qualification["aggregate_registry_sha256"],
          "qualification_receipt_path": qpath.name,
          "qualification_receipt_sha256": stage_two.sha256(qpath),
          "runtime_receipt_path": tpath.name,
          "runtime_receipt_sha256": stage_two.sha256(tpath),
          "runtime_batches": 3,
          "projected_total_seconds": 3 * timing["projected_production_seconds"],
          "caps": dict(stage_two.CAPS)}
    path = root / "go.json"
    path.write_text(json.dumps(go))
    qualification["first_look_registry_sha256"] = registry_sha
    qualification["source_registry_sha256"] = registry_sha
    qualification["aggregate_registry_sha256"] = stage_two.qualification_registry_digest(batches)
    qpath.write_text(json.dumps(qualification))
    go["qualification_receipt_sha256"] = stage_two.sha256(qpath)
    path.write_text(json.dumps(go))
    return path, go, qualification, timing


class StageTwoTests(unittest.TestCase):
    def test_timing_capsule_validator_returns_nonqualifying_identity(self):
        repo = HERE.parents[2]
        capsule = (repo / "docs/dev-log/general-sd-regression/evidence"
                   / "calibration-20261023/timing-current-source-v1")
        look_one = (repo / "docs/dev-log/general-sd-regression/evidence"
                    / "calibration-20261019/clean-current-seed-design-v1/look1.csv")
        look_two = (repo / "docs/dev-log/general-sd-regression/evidence"
                    / "calibration-20261019/clean-current-seed-design-v1/look2.csv")
        identity = stage_two.validate_timing_capsule(capsule, repo, look_one, look_two)
        self.assertEqual(identity["source_file_count"], 26)
        self.assertEqual(identity["installed_library_file_count"], 6)
        self.assertEqual(identity["timing_seed_count"], 45)
        self.assertEqual(identity["disjoint_from_frozen_look_one"], True)
        self.assertEqual(identity["disjoint_from_frozen_look_two"], True)
        self.assertEqual(identity["evidence_scope"], "timing_only_worker_health")
        self.assertIs(identity["adapter_qualification"], False)
        self.assertIs(identity["calibration_claim"], False)

    def test_timing_capsule_validator_rejects_changed_summary_and_seed_overlap(self):
        repo = HERE.parents[2]
        capsule = (repo / "docs/dev-log/general-sd-regression/evidence"
                   / "calibration-20261023/timing-current-source-v1")
        look_one = (repo / "docs/dev-log/general-sd-regression/evidence"
                    / "calibration-20261019/clean-current-seed-design-v1/look1.csv")
        look_two = (repo / "docs/dev-log/general-sd-regression/evidence"
                    / "calibration-20261019/clean-current-seed-design-v1/look2.csv")
        with tempfile.TemporaryDirectory() as tmp:
            copied = Path(tmp) / "capsule"
            shutil.copytree(capsule, copied)
            summary = copied / "capsule/timing-summary.csv"
            summary.write_text(summary.read_text() + "\n")
            with self.assertRaisesRegex(ValueError, "timing-summary.csv digest"):
                stage_two.validate_timing_capsule(copied, repo, look_one, look_two)

        timing_seeds = {row["seed"] for row in
                        stage_two.read_csv(capsule / "capsule/manifest.csv")}
        look_one_seeds = stage_two._registered_seed_set(
            look_one, stage_two.FROZEN_LOOK_MANIFEST_SHA256["look-one"], "look-one")
        look_two_seeds = stage_two._registered_seed_set(
            look_two, stage_two.FROZEN_LOOK_MANIFEST_SHA256["look-two"], "look-two")
        timing_seeds.add(next(iter(look_two_seeds)))
        with self.assertRaisesRegex(ValueError, "overlap"):
            stage_two._require_timing_seed_disjoint(
                timing_seeds, look_one_seeds, look_two_seeds)

    def test_timing_capsule_validator_rejects_changed_registered_library_file(self):
        repo = HERE.parents[2]
        capsule = (repo / "docs/dev-log/general-sd-regression/evidence"
                   / "calibration-20261023/timing-current-source-v1")
        with tempfile.TemporaryDirectory() as tmp:
            copied = Path(tmp) / "capsule"
            shutil.copytree(capsule, copied)
            library_artifact = copied / "library/drmTMB.so"
            library_artifact.write_bytes(library_artifact.read_bytes() + b"tamper")
            look_one = (repo / "docs/dev-log/general-sd-regression/evidence"
                        / "calibration-20261019/clean-current-seed-design-v1/look1.csv")
            look_two = (repo / "docs/dev-log/general-sd-regression/evidence"
                        / "calibration-20261019/clean-current-seed-design-v1/look2.csv")
            with self.assertRaisesRegex(ValueError, "installed-library"):
                stage_two.validate_timing_capsule(copied, repo, look_one, look_two)

    def test_timing_capsule_validator_rejects_result_tamper_with_unchanged_aggregates(self):
        repo = HERE.parents[2]
        capsule = (repo / "docs/dev-log/general-sd-regression/evidence"
                   / "calibration-20261023/timing-current-source-v1")
        look_one = (repo / "docs/dev-log/general-sd-regression/evidence"
                    / "calibration-20261019/clean-current-seed-design-v1/look1.csv")
        look_two = (repo / "docs/dev-log/general-sd-regression/evidence"
                    / "calibration-20261019/clean-current-seed-design-v1/look2.csv")
        with tempfile.TemporaryDirectory() as tmp:
            copied = Path(tmp) / "capsule"
            shutil.copytree(capsule, copied)
            result = copied / "capsule/result-0001.csv"
            with result.open(newline="") as stream:
                rows = list(csv.DictReader(stream))
                fields = rows[0].keys()
            rows[0]["profile_level"] = "0.975"
            with result.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=fields)
                writer.writeheader()
                writer.writerows(rows)
            with self.assertRaisesRegex(ValueError, "result-0001.csv"):
                stage_two.validate_timing_capsule(copied, repo, look_one, look_two)

    def test_timing_capsule_validator_rejects_substitute_frozen_seed_manifests(self):
        repo = HERE.parents[2]
        capsule = (repo / "docs/dev-log/general-sd-regression/evidence"
                   / "calibration-20261023/timing-current-source-v1")
        frozen = (repo / "docs/dev-log/general-sd-regression/evidence"
                  / "calibration-20261019/clean-current-seed-design-v1")
        look_one = frozen / "look1.csv"
        look_two = frozen / "look2.csv"
        for name, supplied in (("look1.csv", look_one), ("look2.csv", look_two)):
            with self.subTest(manifest=name), tempfile.TemporaryDirectory() as tmp:
                substitute = Path(tmp) / name
                rows = stage_two.read_csv(supplied)
                rows[0]["seed"] = "999999999"
                with substitute.open("w", newline="") as stream:
                    writer = csv.DictWriter(stream, fieldnames=rows[0].keys())
                    writer.writeheader()
                    writer.writerows(rows)
                actual_one = substitute if name == "look1.csv" else look_one
                actual_two = substitute if name == "look2.csv" else look_two
                with self.assertRaisesRegex(ValueError, "frozen look-(one|two) manifest digest"):
                    stage_two.validate_timing_capsule(capsule, repo, actual_one, actual_two)

    def test_replay_verifier_must_match_external_source_seal(self):
        with tempfile.TemporaryDirectory(prefix="sealed-replay-script-") as tmp:
            directory = Path(tmp)
            verifier = directory / "verify-first-look.R"
            verifier.write_text("verified replay script\n")
            seal = {"reconstruction_source_directory": str(directory),
                    "reconstruction_source_sha256": {
                        verifier.name: stage_two.sha256(verifier)}}
            self.assertEqual(stage_two.sealed_reconstruction_file(seal, verifier.name), verifier)
            verifier.write_text("changed replay script\n")
            with self.assertRaisesRegex(ValueError, "differs from external seal"):
                stage_two.sealed_reconstruction_file(seal, verifier.name)

    def test_preparation_replay_command_uses_sealed_verifier(self):
        with tempfile.TemporaryDirectory(prefix="sealed-preparation-replay-") as tmp:
            directory = Path(tmp) / "historical-source"
            directory.mkdir()
            verifier = directory / "verify-first-look.R"
            verifier.write_text("historical verifier\n")
            seal = {"reconstruction_source_directory": str(directory),
                    "reconstruction_source_sha256": {
                        verifier.name: stage_two.sha256(verifier)}}
            command = stage_two.first_look_replay_command(
                seal, Path("first-look"), Path("first-look-seal.json"),
                Path("standardized.csv"), "Rscript-test")
            self.assertEqual(command, ["Rscript-test", str(verifier),
                                       "first-look", "first-look-seal.json",
                                       "standardized.csv"])
            verifier.write_text("changed historical verifier\n")
            with self.assertRaisesRegex(ValueError, "differs from external seal"):
                stage_two.first_look_replay_command(
                    seal, Path("first-look"), Path("first-look-seal.json"),
                    Path("standardized.csv"), "Rscript-test")

    def test_worker_library_search_path_is_package_parent(self):
        with tempfile.TemporaryDirectory(prefix="package-library-path-") as tmp:
            package = Path(tmp) / "R-library" / "drmTMB"
            package.mkdir(parents=True)
            self.assertEqual(stage_two.worker_library_search_path(package),
                             str(package.parent.resolve()))

    def test_adapter_runner_requires_external_preparation_digest_before_fits(self):
        with tempfile.TemporaryDirectory(prefix="adapter-preparation-seal-") as tmp:
            root = Path(tmp) / "prepared"
            root.mkdir()
            receipt_path = root / "adapter-qualification-preparation-receipt.json"
            receipt_path.write_text(
                json.dumps({"schema": "native-sd-adapter-qualification-preparation-v1"})
            )
            retained_digest = stage_two.sha256(receipt_path)
            # A caller cannot legitimize a prepared tree by recomputing its
            # digest after an unrecorded receipt mutation.
            receipt_path.write_text(json.dumps({
                "schema": "native-sd-adapter-qualification-preparation-v1",
                "status": "altered_after_preparation",
            }))
            library = Path(tmp) / "library"
            library.mkdir()
            completed = subprocess.run(
                [sys.executable, str(HERE / "run-adapter-qualification.py"), str(root),
                 "--library", str(library), "--preparation-receipt-sha256", retained_digest],
                capture_output=True, text=True, check=False,
            )
            self.assertNotEqual(completed.returncode, 0)
            self.assertIn("preparation receipt differs from externally retained digest",
                          completed.stderr)
            self.assertFalse((root / "batch-1" / "supervisor-receipt.json").exists())

    def test_adapter_runner_accepts_retained_digest_on_no_fit_positive_path(self):
        with tempfile.TemporaryDirectory(prefix="adapter-positive-cli-") as tmp:
            prepared, library, receipt_path = write_adapter_runner_fixture(Path(tmp) / "root")
            retained_digest = stage_two.sha256(receipt_path)
            with contextlib.redirect_stdout(io.StringIO()):
                calls, worker_library_paths, worker_paths = invoke_adapter_runner_without_fits(
                    prepared, library, retained_digest
                )
            self.assertEqual(calls, [1, 1001, 2001])
            self.assertEqual(worker_library_paths, [str(library.parent.resolve())] * 3)
            expected_worker = stage_two.resolve_registered_profile_worker(
                stage_two.read_csv(prepared / "batch-1" / "source-hashes.csv"))
            self.assertEqual(worker_paths, [str(expected_worker)] * 3)
            final = json.loads((prepared / "adapter-qualification-receipt.json").read_text())
            self.assertEqual(final["preparation_receipt_sha256"], retained_digest)
            self.assertEqual(final["external_preparation_receipt_sha256"], retained_digest)
            self.assertEqual(final["attempted"], 3)
            self.assertFalse(final["calibration_claim"])
            self.assertFalse(final["campaign_complete"])

    def test_clean_current_adapter_runner_rejects_reused_calibration_probes(self):
        with tempfile.TemporaryDirectory(prefix="clean-current-adapter-cli-") as tmp:
            root = Path(tmp) / "root"
            root.mkdir()
            prepared, _, library = write_clean_current_run_fixture(root)
            receipt_path = prepared / "adapter-qualification-preparation-receipt.json"
            retained_digest = stage_two.sha256(receipt_path)
            with contextlib.redirect_stdout(io.StringIO()):
                with self.assertRaisesRegex(ValueError,
                                            "reuses look-two calibration seeds"):
                    invoke_adapter_runner_without_fits(
                        prepared, library, retained_digest, source_mode="clean_current")
            self.assertFalse((prepared / "adapter-qualification-receipt.json").exists())

    def test_adapter_runner_rejects_registry_tamper_before_no_fit_supervisor(self):
        with tempfile.TemporaryDirectory(prefix="adapter-registry-tamper-") as tmp:
            prepared, library, receipt_path = write_adapter_runner_fixture(Path(tmp) / "root")
            retained_digest = stage_two.sha256(receipt_path)
            registry = prepared / "batch-1" / "source-hashes.csv"
            rows = stage_two.read_csv(registry)
            # Reordering leaves every registered artifact valid but changes the
            # registry bytes, so the runner's preparation-receipt seal is the
            # guard under test (not the artifact verifier).
            rows.reverse()
            with registry.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
                writer.writeheader()
                writer.writerows(rows)
            with self.assertRaisesRegex(ValueError, "batch 1 no longer matches its preparation receipt"):
                invoke_adapter_runner_without_fits(prepared, library, retained_digest)
            self.assertFalse((prepared / "batch-1" / "supervisor-receipt.json").exists())
            self.assertFalse((prepared / "adapter-qualification-receipt.json").exists())

    def test_adapter_qualification_truth_comparison_is_numeric_in_both_receipts(self):
        with tempfile.TemporaryDirectory() as tmp:
            _, _, qualification, _ = write_go_fixture(Path(tmp))
            original_seed_sha = stage_two.SEED_SHA
            self.addCleanup(setattr, stage_two, "SEED_SHA", original_seed_sha)
            stage_two.SEED_SHA = qualification["source_manifest_sha256"]
            qualification["batches"][1]["a"] = "0"
            stage_two.validate_adapter_qualification(qualification)
            stage_two.replay_adapter_qualification(qualification)

    def test_adapter_qualification_rejects_non_095_profile_interval(self):
        with tempfile.TemporaryDirectory() as tmp:
            _, _, qualification, _ = write_go_fixture(Path(tmp))
            original_seed_sha = stage_two.SEED_SHA
            self.addCleanup(setattr, stage_two, "SEED_SHA", original_seed_sha)
            stage_two.SEED_SHA = qualification["source_manifest_sha256"]
            batch = qualification["batches"][0]
            result_path = Path(batch["result_path"])
            rows = stage_two.read_csv(result_path)
            rows[0]["profile_level"] = "0.975"
            with result_path.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
                writer.writeheader()
                writer.writerows(rows)
            batch["result_sha256"] = stage_two.sha256(result_path)
            with self.assertRaisesRegex(ValueError, "result diagnostics failed"):
                stage_two.replay_adapter_qualification(qualification)

    def test_offline_attempt_recorder_seals_without_overwriting_or_qualifying(self):
        with tempfile.TemporaryDirectory() as tmp:
            _, _, qualification, _ = write_go_fixture(Path(tmp))
            original_seed_sha = stage_two.SEED_SHA
            original_finalizer_seed_sha = finalizer.SEED_SHA
            self.addCleanup(setattr, stage_two, "SEED_SHA", original_seed_sha)
            self.addCleanup(setattr, finalizer, "SEED_SHA", original_finalizer_seed_sha)
            source_sha = qualification["source_manifest_sha256"]
            stage_two.SEED_SHA = source_sha
            finalizer.SEED_SHA = source_sha
            root = Path(qualification["qualification_root"])
            output = root / "finalized" / "adapter-probe-attempts.json"
            receipt = finalizer.finalize(root, Path(qualification["library"]), output)
            self.assertEqual(receipt["probe_span_seconds"], 12.0)
            self.assertIsNone(receipt["whole_run_elapsed_seconds"])
            self.assertEqual(receipt["status"], "INCOMPLETE")
            self.assertEqual(receipt["qualification_status"], "NOT_QUALIFIED")
            self.assertIs(receipt["calibration_claim"], False)
            self.assertEqual(json.loads(output.read_text()), receipt)
            with self.assertRaises(FileExistsError):
                finalizer.finalize(root, Path(qualification["library"]), output)

    def test_reconstruction_source_map_is_required_and_verified(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            names = ("stage_two.py", "reconstruct-first-look.py", "stage-two-rules.R",
                     "verify-first-look.R", "combine-stage-two.R")
            hashes = {}
            for name in names:
                path = root / name
                path.write_text(name)
                hashes[name] = stage_two.sha256(path)
            seal = {"reconstruction_source_directory": str(root),
                    "reconstruction_source_sha256": hashes}
            stage_two.validate_reconstruction_sources(seal)
            (root / "verify-first-look.R").write_text("modified")
            with self.assertRaisesRegex(ValueError, "differs from its seal"):
                stage_two.validate_reconstruction_sources(seal)
            with self.assertRaisesRegex(ValueError, "complete reconstruction source map"):
                stage_two.validate_reconstruction_sources({})

    def test_reconstructed_first_look_binds_archive_and_all_raw_attempts(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            raw = root / "production-prepared"; raw.mkdir()
            summary = root / "first-look-summary"; summary.mkdir()
            manifest_rows = [{"index": str(i), "a": str((-0.5, 0, 0.5)[(i-1)//1]),
                              "replicate": str(i), "seed": str(20000+i),
                              "design_mode": "production", "master_seed": "2026101703"}
                             for i in range(1, 4)]
            for directory in (raw, summary):
                with (directory / "manifest.csv").open("w", newline="") as stream:
                    writer = csv.DictWriter(stream, fieldnames=list(manifest_rows[0]))
                    writer.writeheader(); writer.writerows(manifest_rows)
            registry = raw / "source-hashes.csv"
            registry.write_text("path,sha256\n" +
                f'"{raw / "manifest.csv"}",{stage_two.sha256(raw / "manifest.csv")}\n')
            shutil.copy2(registry, summary / "source-hashes.csv")
            for i, row in enumerate(manifest_rows, 1):
                result = {"index": i, "seed": row["seed"], "a": row["a"],
                          "replicate": row["replicate"], "state": "completed"}
                with (raw / f"result-{i:04d}.csv").open("w", newline="") as stream:
                    writer = csv.DictWriter(stream, fieldnames=list(result))
                    writer.writeheader(); writer.writerow(result)
            archive = root / "evidence.tar.gz"
            with tarfile.open(archive, "w:gz") as tf:
                for path in sorted(raw.iterdir()):
                    tf.add(path, arcname=f"production-prepared/{path.name}")
            shutil.copy2(raw / "manifest.csv", summary / "manifest.csv")
            supervisor = {"campaign_complete": True, "subset_complete": True,
                          "interrupted": False, "planned_indices": [1,2,3],
                          "registry_sha256": stage_two.sha256(registry),
                          "manifest_sha256": stage_two.sha256(raw / "manifest.csv"),
                          "cases": [{"index": i, "status": "completed", "returncode": 0}
                                    for i in range(1,4)]}
            (summary / "supervisor-receipt.json").write_text(json.dumps(supervisor))
            (summary / "root-collection-receipt.json").write_text(json.dumps({
                "archive_sha256": stage_two.sha256(archive), "archive_bytes": archive.stat().st_size,
                "attempts": 3, "campaign_complete": True}))
            original = root / "old-seal.json"
            original.write_text(json.dumps({"registry_sha256": stage_two.sha256(registry),
                "attempts_sha256": stage_two.attempt_digest(summary),
                "decision_sha256": "d" * 64}))
            output = root / "reconstructed-first-look"
            new_seal = root / "new-seal.json"
            receipt = stage_two.reconstruct_first_look(summary, raw, archive, original,
                stage_two.sha256(original), output, new_seal,
                expected_archive_sha256=stage_two.sha256(archive), expected_results=3)
            self.assertEqual(receipt["raw_result_files"], 3)
            self.assertEqual(receipt["raw_attempt_archive_sha256"], stage_two.sha256(archive))
            self.assertEqual(stage_two.attempt_digest(output, expected_results=3),
                             json.loads(new_seal.read_text())["attempts_sha256"])
            sealed = json.loads(new_seal.read_text())
            self.assertEqual(sealed["original_seal_sha256"], stage_two.sha256(original))
            self.assertEqual(sealed["collection_receipt_sha256"],
                             stage_two.sha256(summary / "root-collection-receipt.json"))
            self.assertEqual(sealed["reconstruction_source_directory"], str(stage_two.HERE))
            self.assertEqual(sealed["reconstruction_source_sha256"]["stage_two.py"],
                             stage_two.sha256(Path(stage_two.__file__).resolve()))
            self.assertEqual(sealed["reconstruction_source_sha256"]["verify-first-look.R"],
                             stage_two.sha256(Path(stage_two.__file__).resolve().parent / "verify-first-look.R"))
            self.assertTrue((output / "result-0001.csv").is_symlink())
            self.assertEqual(original.read_text(), json.dumps({"registry_sha256": stage_two.sha256(registry),
                "attempts_sha256": stage_two.attempt_digest(summary), "decision_sha256": "d" * 64}))

            # Changing both the archive and its colocated receipt cannot replace
            # the independently supplied archive identity.
            archive.write_bytes(archive.read_bytes() + b"tampered")
            collection = json.loads((summary / "root-collection-receipt.json").read_text())
            collection["archive_sha256"] = stage_two.sha256(archive)
            collection["archive_bytes"] = archive.stat().st_size
            (summary / "root-collection-receipt.json").write_text(json.dumps(collection))
            with self.assertRaisesRegex(ValueError, "independently supplied archive digest"):
                stage_two.reconstruct_first_look(summary, raw, archive, original,
                    stage_two.sha256(original), root / "second-reconstruction",
                    root / "second-seal.json", expected_archive_sha256=sealed["raw_attempt_archive_sha256"],
                    expected_results=3)

    def test_attempt_digest_requires_the_complete_expected_result_index_set(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "manifest.csv").write_text("index\n1\n2\n3\n")
            (root / "supervisor-receipt.json").write_text("{}\n")
            for index in (1, 2, 3):
                (root / f"result-{index:04d}.csv").write_text(f"index\n{index}\n")
            digest = stage_two.attempt_digest(root, expected_results=3)
            self.assertEqual(len(digest), 64)
            (root / "result-0002.csv").unlink()
            with self.assertRaisesRegex(ValueError, "expected results 1..3"):
                stage_two.attempt_digest(root, expected_results=3)

    def test_batch_attempt_digest_matches_completed_indices_and_keeps_timeout_denominator(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "manifest.csv").write_text("index\n1\n2\n3\n")
            (root / "supervisor-receipt.json").write_text(json.dumps({"cases": [
                {"index": 1, "status": "completed"},
                {"index": 2, "status": "timeout"},
                {"index": 3, "status": "error"}]}))
            (root / "result-0001.csv").write_text("index\n1\n")
            (root / "result-0002.csv").write_text("index\n2\npartial\n")
            (root / "result-0003.csv").write_text("index\n3\nfailed\n")
            digest = stage_two.attempt_digest(root, expected_indices=[1], allowed_indices=[1, 2, 3])
            self.assertEqual(len(digest), 64)
            (root / "result-0003.csv").unlink()
            absent_failed_result_digest = stage_two.attempt_digest(
                root, expected_indices=[1], allowed_indices=[1, 2, 3])
            self.assertEqual(len(absent_failed_result_digest), 64)
            (root / "result-0001.csv").unlink()
            with self.assertRaisesRegex(ValueError, "expected completed index"):
                stage_two.attempt_digest(root, expected_indices=[1], allowed_indices=[1, 2, 3])
            (root / "result-0001.csv").write_text("index\n1\n")
            (root / "result-0004.csv").write_text("index\n4\n")
            with self.assertRaisesRegex(ValueError, "outside the planned index set"):
                stage_two.attempt_digest(root, expected_indices=[1], allowed_indices=[1, 2, 3])
            with self.assertRaisesRegex(ValueError, "cannot be combined"):
                stage_two.attempt_digest(root, expected_results=3, expected_indices=[1])
            (root / "result-0002.csv").write_text("index\n2\n")
            (root / "result-0004.csv").write_text("index\n4\n")
            with self.assertRaisesRegex(ValueError, "expected results 1..3"):
                stage_two.attempt_digest(root, expected_results=3)

    def test_attempt_digest_rejects_non_four_digit_result_filenames(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "manifest.csv").write_text("index\n1\n")
            (root / "supervisor-receipt.json").write_text("{}\n")
            (root / "result-0001.csv").write_text("index\n1\n")
            for name in ("result-10000.csv", "result-00001.csv", "result-001.csv"):
                with self.subTest(name=name):
                    (root / name).write_text("index\n1\n")
                    with self.assertRaisesRegex(ValueError, "result filenames.*four digits"):
                        stage_two.attempt_digest(root, expected_indices=[1],
                                                 allowed_indices=[1, 2, 3])
                    (root / name).unlink()

    def test_adapter_probe_preserves_subset_vs_campaign_semantics(self):
        subset = {"planned_indices": [1001], "subset_complete": True,
                  "campaign_complete": False, "interrupted": False,
                  "registry_sha256": "r" * 64, "manifest_sha256": "m" * 64,
                  "cases": [{"index": 1001, "status": "completed", "returncode": 0}]}
        stage_two.validate_qualification_subset(subset, 1001, "r" * 64, "m" * 64)
        for key, bad in (("campaign_complete", True), ("subset_complete", False),
                         ("interrupted", True), ("planned_indices", [1])):
            mutant = json.loads(json.dumps(subset)); mutant[key] = bad
            with self.assertRaises(ValueError, msg=key):
                stage_two.validate_qualification_subset(mutant, 1001)
        with self.assertRaises(ValueError):
            stage_two.validate_qualification_subset(subset, 1001, "x" * 64, "m" * 64)

    def test_adapter_qualification_mapping_uses_distinct_frozen_rows(self):
        rows = tiny_source()
        observed = [stage_two.adapter_qualification_case(rows, b) for b in (1, 2, 3)]
        self.assertEqual([(x["batch_id"], x["local_index"], x["stage_two_index"],
                           x["replicate"], x["a"]) for x in observed],
                         [(1, 1, 1, 1001, "-0.5"),
                          (2, 1001, 4001, 2001, "0.0"),
                          (3, 2001, 8001, 3001, "0.5")])

    def test_adapter_qualification_aggregate_requires_three_distinct_terminal_subsets(self):
        batches = []
        for batch, local, global_index, replicate, truth in (
                (1, 1, 1, 1001, "-0.5"), (2, 1001, 4001, 2001, "0.0"),
                (3, 2001, 8001, 3001, "0.5")):
            batches.append({"batch_id": batch, "local_index": local,
                            "stage_two_index": global_index, "replicate": replicate,
                            "a": truth, "registry_sha256": str(batch) * 64,
                            "manifest_sha256": "a" * 64,
                            "registry_path": f"/batch-{batch}/source-hashes.csv",
                            "manifest_path": f"/batch-{batch}/manifest.csv",
                            "supervisor_sha256": "b" * 64, "result_sha256": "c" * 64,
                            "supervisor_path": f"/batch-{batch}/supervisor-receipt.json",
                            "result_path": f"/batch-{batch}/result.csv",
                            "status": "completed", "subset_complete": True,
                            "campaign_complete": False, "returncode": 0,
                            "valid_interval": True, "oracle_pass": True})
        receipt = {"schema": "native-sd-adapter-qualification-v1", "status": "PASS",
                   "calibration_claim": False, "campaign_complete": False,
                   "subset_complete": True, "planned_attempts": 9000,
                   "attempted": 3, "elapsed_seconds": 239.9, "batches": batches,
                   "aggregate_registry_sha256": stage_two.qualification_registry_digest(batches)}
        receipt["library"] = "/library"
        receipt["qualification_root"] = "/qualification-root"
        receipt["preparation_receipt_path"] = "/qualification-root/adapter-qualification-preparation-receipt.json"
        receipt["preparation_receipt_sha256"] = "d" * 64
        receipt["external_preparation_receipt_sha256"] = "d" * 64
        receipt["library_artifacts"] = [{"path": f"/library/{i}", "sha256": str(i) * 64}
                                         for i in (1, 2, 3)]
        stage_two.validate_adapter_qualification(receipt)
        reused = json.loads(json.dumps(receipt))
        reused["source_design_mode"] = "clean_current"
        with self.assertRaisesRegex(ValueError,
                                    "reuses look-two calibration seeds"):
            stage_two.validate_adapter_qualification(reused)
        mutants = []
        old = dict(receipt); old.pop("schema"); old["source_registry_sha256"] = "q" * 64
        mutants.append(old)
        duplicate = json.loads(json.dumps(receipt)); duplicate["batches"][2]["registry_sha256"] = duplicate["batches"][1]["registry_sha256"]
        mutants.append(duplicate)
        wrongmap = json.loads(json.dumps(receipt)); wrongmap["batches"][1]["stage_two_index"] = 3001
        mutants.append(wrongmap)
        campaign = json.loads(json.dumps(receipt)); campaign["campaign_complete"] = True
        mutants.append(campaign)
        claimed = json.loads(json.dumps(receipt)); claimed["calibration_claim"] = True
        mutants.append(claimed)
        external_prep_mismatch = json.loads(json.dumps(receipt))
        external_prep_mismatch["external_preparation_receipt_sha256"] = "e" * 64
        mutants.append(external_prep_mismatch)
        invalid = json.loads(json.dumps(receipt)); invalid["batches"][0]["valid_interval"] = False
        mutants.append(invalid)
        for mutant in mutants:
            with self.assertRaises(ValueError):
                stage_two.validate_adapter_qualification(mutant)

    def test_adapter_qualification_rejects_total_deadline_overrun(self):
        # Model an otherwise successful last probe that returns after the
        # overall 240-second cap. It must not be accepted as qualification.
        receipt = {"schema": "native-sd-adapter-qualification-v1", "status": "PASS",
                   "calibration_claim": False, "campaign_complete": False,
                   "subset_complete": True, "planned_attempts": 9000,
                   "attempted": 3, "elapsed_seconds": 240.001, "batches": []}
        with self.assertRaisesRegex(ValueError, "240-second"):
            stage_two.validate_adapter_qualification(receipt)
        for elapsed in (float("nan"), float("inf"), -0.001, None):
            with self.assertRaises(ValueError):
                stage_two.validate_qualification_elapsed(elapsed)
        stage_two.validate_qualification_elapsed(240.0)

    def test_batch_edges_preserve_global_replicate_and_seed(self):
        source = tiny_source()
        for b, first_truth in ((1, "-0.5"), (2, "0.0"), (3, "0.5")):
            rows = stage_two.batch_rows(source, b)
            self.assertEqual(len(rows), 3000)
            self.assertEqual((rows[0]["index"], rows[0]["stage_two_index"],
                              rows[0]["replicate"], rows[0]["a"]),
                             ("1", str(3000*(b-1)+1), "1001", first_truth))
            self.assertEqual((rows[-1]["index"], rows[-1]["stage_two_index"],
                              rows[-1]["replicate"], rows[-1]["seed"]),
                             ("3000", str(3000*b), "4000", str(10000+3000*b)))
            self.assertEqual(rows[0]["master_seed"], "2026101705")
            self.assertEqual(rows[0]["design_mode"], "production")

    def test_batch_manifest_mutations_fail_against_frozen_source(self):
        source = tiny_source()
        rows = stage_two.batch_rows(source, 2)
        stage_two.validate_batch_manifest(rows, source, 2)
        for field, bad in (("seed", "999999"), ("a", "0.5"),
                           ("stage_two_index", "1"), ("replicate", "1")):
            mutant = [dict(r) for r in rows]
            mutant[0][field] = bad
            with self.assertRaises(ValueError, msg=field):
                stage_two.validate_batch_manifest(mutant, source, 2)

    def test_corrupt_source_row_or_source_mode_fails_closed(self):
        rows = tiny_source()
        rows[3000]["replicate"] = "1"
        with patch.object(stage_two, "sha256", return_value=stage_two.SEED_SHA):
            with self.assertRaisesRegex(ValueError, "source identity mismatch"):
                stage_two.validate_source(rows, Path("unused"), set())
        rows = tiny_source()
        rows[0]["seed"] = rows[1]["seed"]
        with patch.object(stage_two, "sha256", return_value=stage_two.SEED_SHA):
            with self.assertRaisesRegex(ValueError, "duplicated or overlap"):
                stage_two.validate_source(rows, Path("unused"), set())
        rows = tiny_source()
        with patch.object(stage_two, "sha256", return_value=stage_two.SEED_SHA):
            with self.assertRaisesRegex(ValueError, "duplicated or overlap"):
                stage_two.validate_source(rows, Path("unused"), {int(rows[0]["seed"])})
        rows = tiny_source()
        rows[5999]["design_mode"] = "production"
        with patch.object(stage_two, "sha256", return_value=stage_two.SEED_SHA):
            with self.assertRaisesRegex(ValueError, "source identity mismatch"):
                stage_two.validate_source(rows, Path("unused"), set())

    def test_prior_stream_checks_every_master_index_and_seed(self):
        rows = [{"index": str(i), "seed": str(i + 500), "master_seed": "2026101704"}
                for i in range(1, 301)]
        stage_two.validate_prior_stream(rows, Path("qualification.csv"), 300, 2026101704)
        later_master = [dict(r) for r in rows]
        later_master[199]["master_seed"] = "2026101703"
        with self.assertRaisesRegex(ValueError, "identity mismatch"):
            stage_two.validate_prior_stream(later_master, Path("qualification.csv"), 300, 2026101704)
        later_dup = [dict(r) for r in rows]
        later_dup[199]["seed"] = later_dup[198]["seed"]
        with self.assertRaisesRegex(ValueError, "identity mismatch"):
            stage_two.validate_prior_stream(later_dup, Path("qualification.csv"), 300, 2026101704)

    def test_frozen_legacy_pilot_without_row_id_is_positionally_admissible(self):
        rows = [
            {"a": a, "pilot": pilot, "seed": seed}
            for a, pilot, seed in (
                ("-0.5", "1", "1746912062"), ("0", "1", "1475354618"),
                ("0.5", "1", "1120801948"), ("-0.5", "2", "131856170"),
                ("0", "2", "883057618"), ("0.5", "2", "661797416"),
            )
        ]
        stage_two.validate_prior_stream(rows, Path("pilot.csv"), 6, 2026101702)

        with self.assertRaisesRegex(ValueError, "row count"):
            stage_two.validate_prior_stream(rows[:5], Path("pilot.csv"), 6, 2026101702)
        with self.assertRaisesRegex(ValueError, "identity columns"):
            stage_two.validate_prior_stream(rows, Path("qualification.csv"), 6, 2026101704)

    def test_go_must_bind_look_one_decision_and_registry(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            path, go, _, _ = write_go_fixture(root)
            original_seed_sha = stage_two.SEED_SHA
            self.addCleanup(setattr, stage_two, "SEED_SHA", original_seed_sha)
            stage_two.SEED_SHA = json.loads((root / "qualification.json").read_text())["source_manifest_sha256"]
            lib = root / "library"
            seal = {"registry_sha256": "r", "decision_sha256": "d",
                    "harness_archive_sha256": stage_two.SOURCE_ARCHIVE_SHA,
                    "reconstruction_source_directory": str(stage_two.HERE),
                    "reconstruction_source_sha256": {
                        name: stage_two.sha256(stage_two.HERE / name)
                        for name in ("stage_two.py", "reconstruct-first-look.py",
                                     "stage-two-rules.R", "verify-first-look.R",
                                     "combine-stage-two.R")},
                    "matched_original_native_artifacts": ["R/drmTMB.R", "R/methods.R",
                      "R/profile.R", "src/drmTMB.cpp",
                      "tests/testthat/helper-binomial-sd-regression.R",
                      str(lib / "R" / "drmTMB.rdb"), str(lib / "R" / "drmTMB.rdx"),
                      str(lib / "libs" / "drmTMB.so")]}
            stage_two.validate_go(go, stage_two.sha256(path), seal, path)
            changed_source_seal = json.loads(json.dumps(seal))
            changed_source_seal["reconstruction_source_sha256"]["verify-first-look.R"] = "0" * 64
            with self.assertRaisesRegex(ValueError, "reconstruction source differs"):
                stage_two.validate_go(go, stage_two.sha256(path), changed_source_seal, path)
            with self.assertRaisesRegex(ValueError, "different first-look seal"):
                stage_two.validate_go(go, stage_two.sha256(path), seal, path, "x" * 64)
            path, go, qualification, _ = write_go_fixture(root)
            batch = qualification["batches"][1]
            result_path = Path(batch["result_path"])
            result_rows = stage_two.read_csv(result_path); result_rows[0]["valid_interval"] = "FALSE"
            with result_path.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=list(result_rows[0]))
                writer.writeheader(); writer.writerows(result_rows)
            batch["result_sha256"] = stage_two.sha256(result_path)
            qpath = root / go["qualification_receipt_path"]
            qpath.write_text(json.dumps(qualification))
            go["qualification_receipt_sha256"] = stage_two.sha256(qpath)
            path.write_text(json.dumps(go))
            with self.assertRaisesRegex(ValueError, "result diagnostics failed"):
                stage_two.validate_go(go, stage_two.sha256(path), seal, path)
            path, go, qualification, _ = write_go_fixture(root)
            batch = qualification["batches"][0]
            supervisor_path = Path(batch["supervisor_path"])
            supervisor = json.loads(supervisor_path.read_text()); supervisor["campaign_complete"] = True
            supervisor_path.write_text(json.dumps(supervisor))
            batch["supervisor_sha256"] = stage_two.sha256(supervisor_path)
            qpath = root / go["qualification_receipt_path"]
            qpath.write_text(json.dumps(qualification))
            go["qualification_receipt_sha256"] = stage_two.sha256(qpath)
            path.write_text(json.dumps(go))
            with self.assertRaisesRegex(ValueError, "subset is incomplete"):
                stage_two.validate_go(go, stage_two.sha256(path), seal, path)
            path, go, _, _ = write_go_fixture(root)
            for key, bad in (("decision", "accept"),
                             ("first_look_registry_sha256", "other"),
                             ("first_look_decision_sha256", "other"),
                             ("look", 2), ("runtime_batches", 4),
                             ("approved_goal_sha256", "bad")):
                mutant = dict(go); mutant[key] = bad
                path.write_text(json.dumps(mutant))
                with self.assertRaises(ValueError, msg=key):
                    stage_two.validate_go(mutant, stage_two.sha256(path), seal, path)

            path, go, qualification, timing = write_go_fixture(root)
            qualification["status"] = "FAIL"
            (root / "qualification.json").write_text(json.dumps(qualification))
            go["qualification_receipt_sha256"] = stage_two.sha256(root / "qualification.json")
            path.write_text(json.dumps(go))
            with self.assertRaisesRegex(ValueError, "qualification receipt"):
                stage_two.validate_go(go, stage_two.sha256(path), seal, path)

            path, go, _, timing = write_go_fixture(root)
            timing["projected_production_seconds"] += 10
            (root / "timing.json").write_text(json.dumps(timing))
            go["runtime_receipt_sha256"] = stage_two.sha256(root / "timing.json")
            path.write_text(json.dumps(go))
            with self.assertRaisesRegex(ValueError, "runtime estimate"):
                stage_two.validate_go(go, stage_two.sha256(path), seal, path)

    def test_prepare_cli_reaches_seal_validation_without_writing_capsule(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            first = root / "missing-first-look"
            registry = root / "source-hashes.csv"
            registry.write_text("path,sha256\n")
            library = root / "library"
            library.mkdir()
            frozen = root / "frozen.csv"
            frozen.write_text("index\n")
            decision_sha = "d" * 64
            seal = root / "first-seal.json"
            seal_fields = {"registry_sha256": stage_two.sha256(registry),
                           "decision_sha256": decision_sha}
            seal.write_text(json.dumps(seal_fields))
            go, _, _, _ = write_go_fixture(root, seal_fields["registry_sha256"], decision_sha)
            prior = [root / f"prior-{i}.csv" for i in range(3)]
            new_root = root / "must-not-be-created"
            command = [sys.executable, str(HERE / "prepare-stage-two.py"), str(first),
                       str(registry), str(library), str(frozen), str(go), str(seal),
                       "--go-record-sha256", stage_two.sha256(go),
                       "--first-look-seal-sha256", stage_two.sha256(seal),
                       "--rscript", "Rscript", *map(str, prior), str(new_root)]
            result = subprocess.run(command, capture_output=True, text=True, timeout=10)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("complete reconstruction source map", result.stderr)
            self.assertFalse(new_root.exists())

    def test_batch_and_cap_domains_are_finite(self):
        for batch in (0, 4, -1):
            with self.assertRaisesRegex(ValueError, "batch must"):
                stage_two.batch_rows(tiny_source(), batch)
        self.assertEqual(stage_two.CAPS["workers"], 16)
        self.assertEqual(stage_two.CAPS["case_timeout_seconds"], 120)
        self.assertEqual(stage_two.CAPS["batch_timeout_seconds"], 3300)
        self.assertEqual(stage_two.CAPS["outer_timeout_seconds"], 10500)
        with self.assertRaisesRegex(ValueError, "complete frozen"):
            stage_two.batch_rows(tiny_source()[:-1], 1)

    def test_run_batches_rejects_nonfinite_or_out_of_range_outer_timeout_before_io(self):
        invalid_timeouts = (float("nan"), float("inf"), float("-inf"), 0,
                            -1, stage_two.CAPS["outer_timeout_seconds"] + 1)
        for timeout in invalid_timeouts:
            with self.subTest(timeout=timeout):
                with self.assertRaisesRegex(ValueError, "finite.*10,500-second cap"):
                    stage_two.run_batches(Path("missing-prepared"), Path("missing-seals"),
                                          "unused", Path("missing-library"), timeout)

    def test_manifest_writer_refuses_replacement(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "manifest.csv"
            stage_two.write_batch_manifest(stage_two.batch_rows(tiny_source(), 1), path)
            original = path.read_bytes()
            with self.assertRaises(FileExistsError):
                stage_two.write_batch_manifest(stage_two.batch_rows(tiny_source(), 1), path)
            self.assertEqual(path.read_bytes(), original)

    def test_registry_refuses_missing_mandatory_adapter_artifact(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            old_manifest = root / "source" / "manifest.csv"
            old_manifest.parent.mkdir()
            old_manifest.write_text("index\n1\n")
            source_registry = root / "source-registry.csv"
            with source_registry.open("w", newline="") as f:
                writer = csv.DictWriter(f, fieldnames=["path", "sha256"])
                writer.writeheader()
                writer.writerow({"path": str(old_manifest), "sha256": stage_two.sha256(old_manifest)})
                worker = stage_two.BASE / "worker-095.R"
                writer.writerow({"path": str(worker.resolve()), "sha256": stage_two.sha256(worker)})
            out = root / "out"; out.mkdir()
            manifest = out / "manifest.csv"; manifest.write_text("index\n1\n")
            (out / "design-receipt.txt").write_text("design\n")
            (out / "conversion-receipt.json").write_text("{}\n")
            with patch.object(stage_two, "HERE", root / "adapter"):
                with self.assertRaisesRegex(ValueError, "mandatory adapter artifacts are missing"):
                    stage_two.write_registry(out, source_registry, root, root, manifest)
            self.assertFalse((out / "source-hashes.csv").exists())

    def test_source_binary_receipt_must_match_bernoulli_archive_and_library(self):
        with tempfile.TemporaryDirectory() as tmp:
            lib = Path(tmp) / "library" / "drmTMB"
            (lib / "R").mkdir(parents=True)
            (lib / "libs").mkdir()
            files = [lib / "R" / "drmTMB.rdb", lib / "R" / "drmTMB.rdx",
                     lib / "libs" / "drmTMB.so"]
            for f in files:
                f.write_text("pinned")
            seal = {"harness_archive_sha256": stage_two.SOURCE_ARCHIVE_SHA,
                    "matched_original_native_artifacts": ["R/drmTMB.R", "R/methods.R",
                        "R/profile.R", "src/drmTMB.cpp",
                        "tests/testthat/helper-binomial-sd-regression.R"] + [str(f) for f in files]}
            stage_two.validate_binary_receipt(seal, lib.parent)
            bad = dict(seal); bad["harness_archive_sha256"] = "stale"
            with self.assertRaisesRegex(ValueError, "source archive"):
                stage_two.validate_binary_receipt(bad, lib.parent)

    def test_source_binary_receipt_accepts_clean_current_archive_only_for_clean_current(self):
        with tempfile.TemporaryDirectory() as tmp:
            lib = Path(tmp) / "library" / "drmTMB"
            (lib / "R").mkdir(parents=True)
            (lib / "libs").mkdir()
            files = [lib / "R" / "drmTMB.rdb", lib / "R" / "drmTMB.rdx",
                     lib / "libs" / "drmTMB.so"]
            for f in files:
                f.write_text("pinned")
            artifacts = ["R/drmTMB.R", "R/methods.R", "R/profile.R",
                         "src/drmTMB.cpp",
                         "tests/testthat/helper-binomial-sd-regression.R"] + [str(f) for f in files]
            clean_current = {
                "source_design_mode": "clean_current",
                "harness_archive_sha256":
                    "84319a4620935d528a9bc84c8a69ffee9538f573d72ec16ccb6c65f31de8320e",
                "matched_original_native_artifacts": artifacts,
            }
            stage_two.validate_binary_receipt(clean_current, lib.parent)
            stale_mode = dict(clean_current, source_design_mode="production")
            with self.assertRaisesRegex(ValueError, "source archive"):
                stage_two.validate_binary_receipt(stale_mode, lib.parent)
            stale_archive = dict(clean_current, harness_archive_sha256=stage_two.SOURCE_ARCHIVE_SHA)
            with self.assertRaisesRegex(ValueError, "source archive"):
                stage_two.validate_binary_receipt(stale_archive, lib.parent)

    def test_batch_receipt_accepts_terminal_errors_but_rejects_timeout_or_incomplete(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            manifest = root / "manifest.csv"
            manifest.write_text("index\n" + "\n".join(map(str, range(1, 3001))) + "\n")
            cases = [{"index": i, "status": "error", "returncode": 1}
                     for i in range(1, 3001)]
            receipt = {"registry_sha256": "registry", "manifest_sha256": stage_two.sha256(manifest),
                       "planned_indices": list(range(1, 3001)), "campaign_complete": True,
                       "subset_complete": True, "interrupted": False, "cases": cases}
            receipt_path = root / "supervisor-receipt.json"

            def write(value):
                receipt_path.write_text(json.dumps(value))

            write(receipt)
            self.assertEqual(stage_two.validate_batch_receipt(root, "registry",
                             stage_two.sha256(manifest))["cases"], cases)
            timed = json.loads(json.dumps(receipt))
            timed["cases"][0].update(status="timeout", returncode=124)
            write(timed)
            self.assertEqual(stage_two.validate_batch_receipt(root, "registry",
                             stage_two.sha256(manifest))["cases"][0]["status"], "timeout")
            for mutate in (
                lambda x: x["cases"][0].update(status="campaign_timeout", returncode=124),
                lambda x: x["cases"][0].update(status="timeout", returncode=0),
                lambda x: x.update(campaign_complete=False),
                lambda x: x["cases"][1].update(index=1),
                lambda x: x.update(registry_sha256="other"),
            ):
                mutant = json.loads(json.dumps(receipt))
                mutate(mutant)
                write(mutant)
                with self.assertRaisesRegex(RuntimeError, "failed|incomplete or contradictory"):
                    stage_two.validate_batch_receipt(root, "registry", stage_two.sha256(manifest))


class CleanCurrentLookTwoManifestTests(unittest.TestCase):
    """Pure identity checks for the frozen clean-current look-two manifest."""

    @classmethod
    def setUpClass(cls):
        import clean_current_stage_two
        cls.adapter = clean_current_stage_two
        cls.manifest = (HERE.parents[2] / "docs/dev-log/general-sd-regression/evidence"
                        / "calibration-20261019/clean-current-seed-design-v1/look2.csv")

    def test_frozen_digest_rows_and_three_batch_identity_transform(self):
        batches = self.adapter.load_batches(self.manifest)
        self.assertEqual(self.adapter.sha256(self.manifest),
                         "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98")
        self.assertEqual([len(batch) for batch in batches], [3000, 3000, 3000])
        self.assertEqual(batches, self.adapter.load_batches(self.manifest))
        flattened = [row for batch in batches for row in batch]
        self.assertEqual([int(row["stage_two_index"]) for row in flattened],
                         list(range(1, 9001)))
        self.assertEqual([[int(row["index"]) for row in batch]
                          for batch in batches], [list(range(1, 3001))] * 3)
        self.assertEqual([[int(row["replicate"]) for row in batch] for batch in batches],
                         [list(range(1001, 4001))] * 3)
        self.assertEqual([row["a"] for row in (batch[0] for batch in batches)],
                         ["-0.5", "0", "0.5"])
        source_rows = self.adapter.read_frozen_rows(self.manifest)
        self.assertEqual(len(flattened), 9000)
        for source, transformed in zip(source_rows, flattened):
            batch_id = (int(source["index"]) - 1) // 3000 + 1
            expected = {key: value for key, value in source.items()
                        if key not in {"index", "design_mode"}}
            expected.update(index=str((int(source["index"]) - 1) % 3000 + 1),
                            stage_two_index=source["index"], batch_id=str(batch_id),
                            source_index=source["index"],
                            source_design_mode="clean_current",
                            design_mode="clean_current_stage_two")
            self.assertEqual(transformed, expected)

        seeds = [int(row["seed"]) for row in flattened]
        masters = [int(row["master_seed"]) for row in flattened]
        self.assertEqual(len(seeds), len(set(seeds)))
        self.assertEqual(set(masters), {2026101902})
        self.assertTrue(set(seeds).isdisjoint(set(masters)))
        seed_sets = [{int(row["seed"]) for row in batch} for batch in batches]
        self.assertTrue(seed_sets[0].isdisjoint(seed_sets[1]))
        self.assertTrue(seed_sets[0].isdisjoint(seed_sets[2]))
        self.assertTrue(seed_sets[1].isdisjoint(seed_sets[2]))
        self.assertTrue(all(row["source_design_mode"] == "clean_current" and
                            row["design_mode"] == "clean_current_stage_two" and
                            row["look"] == "look2" and row["master_seed"] == "2026101902" and
                            row["groups"] == "160" and
                            row["repeats"] == "16" and row["beta0"] == "-0.3" and
                            row["beta1"] == "0.6" and
                            row["alpha0"] == "-0.22314355131421"
                            for row in flattened))

    def test_batch_validator_rejects_tampered_or_wrong_batch(self):
        batches = self.adapter.load_batches(self.manifest)
        for batch_id, batch in enumerate(batches, start=1):
            self.assertTrue(self.adapter.validate_batch(batch, self.manifest, batch_id))
        changed = [dict(row) for row in batches[0]]
        changed[0]["stage_two_index"] = "2"
        with self.assertRaises(ValueError):
            self.adapter.validate_batch(changed, self.manifest, 1)
        with self.assertRaises(ValueError):
            self.adapter.validate_batch(batches[0], self.manifest, 2)

    def test_batch_registry_pins_clean_current_source_and_adapter(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            original_manifest = root / "first-look" / "manifest.csv"
            original_manifest.parent.mkdir()
            original_manifest.write_text("index\n1\n")
            source_registry = root / "first-look" / "source-hashes.csv"
            with source_registry.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
                writer.writeheader()
                for path in (original_manifest, stage_two.BASE / "worker-095.R"):
                    writer.writerow({"path": str(path.resolve()),
                                     "sha256": stage_two.sha256(path)})
            out = root / "batch-1"
            out.mkdir()
            batch_manifest = out / "manifest.csv"
            stage_two.write_batch_manifest(self.adapter.load_batches(self.manifest)[0],
                                           batch_manifest)
            (out / "design-receipt.txt").write_text("prepared_not_launched\n")
            (out / "conversion-receipt.json").write_text("{}\n")
            stage_two.write_registry(out, source_registry, root, root, batch_manifest,
                                     source_manifest=self.manifest)
            registry = stage_two.read_csv(out / "source-hashes.csv")
            source_rows = [row for row in registry
                           if Path(row["path"]).resolve() == self.manifest.resolve()]
            adapter_rows = [row for row in registry
                            if Path(row["path"]).resolve() ==
                            (HERE / "clean_current_stage_two.py").resolve()]
            self.assertEqual(len(source_rows), 1)
            self.assertEqual(source_rows[0]["sha256"], self.adapter.EXPECTED_SHA256)
            self.assertEqual(len(adapter_rows), 1)
            self.assertEqual(adapter_rows[0]["sha256"],
                             stage_two.sha256(HERE / "clean_current_stage_two.py"))

    def test_registered_profile_worker_resolves_to_the_pinned_source_path(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            fixture = root / "fixture"
            write_adapter_runner_fixture(fixture)
            registry = stage_two.read_csv(fixture / "original-source-hashes.csv")

            worker = stage_two.resolve_registered_profile_worker(registry)

            self.assertEqual(worker, (fixture / "source" / "native-calibration"
                                      / "worker-095.R").resolve())

    def test_batch_registry_deduplicates_mirrored_clean_current_source_pins(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, library, _ = write_adapter_runner_fixture(root / "baseline")
            source_registry = root / "source-hashes.csv"
            original_rows = stage_two.read_csv(
                root / "baseline" / "original-source-hashes.csv")
            source_manifest = root / "look2.csv"
            mirror_manifest = root / "mirror" / "look2.csv"
            mirror_manifest.parent.mkdir()
            source_manifest.write_bytes(self.manifest.read_bytes())
            mirror_manifest.write_bytes(self.manifest.read_bytes())
            for path in (source_manifest, mirror_manifest):
                original_rows.append({"path": str(path.resolve()),
                                      "sha256": stage_two.sha256(path)})
            with source_registry.open("w", newline="", encoding="utf-8") as stream:
                writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
                writer.writeheader()
                writer.writerows(original_rows)
            out = root / "batch-1"
            out.mkdir()
            batch_manifest = out / "manifest.csv"
            stage_two.write_batch_manifest(
                stage_two.batch_rows(self.adapter.read_frozen_rows(self.manifest), 1),
                batch_manifest)
            (out / "design-receipt.txt").write_text("prepared_not_launched\n")
            (out / "conversion-receipt.json").write_text("{}\n")

            stage_two.write_registry(out, source_registry, root, library,
                                     batch_manifest, source_manifest=source_manifest)

            registry = stage_two.read_csv(out / "source-hashes.csv")
            source_rows = [row for row in registry
                           if Path(row["path"]).name == "look2.csv"
                           and row["sha256"] == self.adapter.EXPECTED_SHA256]
            self.assertEqual(len(source_rows), 1)
            self.assertEqual(Path(source_rows[0]["path"]).resolve(),
                             source_manifest.resolve())

    def test_batch_registry_replaces_first_look_design_receipt(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            prepared, library, _ = write_adapter_runner_fixture(root / "baseline")
            source_rows = stage_two.read_csv(
                root / "baseline" / "original-source-hashes.csv")
            first_look_design = root / "first-look" / "design-receipt.txt"
            first_look_design.parent.mkdir()
            first_look_design.write_text("design_mode=clean_current\n")
            source_rows.append({"path": str(first_look_design.resolve()),
                                "sha256": stage_two.sha256(first_look_design)})
            source_registry = root / "source-registry-with-first-look-design.csv"
            with source_registry.open("w", newline="", encoding="utf-8") as stream:
                writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
                writer.writeheader()
                writer.writerows(source_rows)

            out = root / "batch"
            out.mkdir()
            batch_manifest = out / "manifest.csv"
            frozen_manifest = (HERE.parents[2]
                               / "docs/dev-log/general-sd-regression/stage-two-manifest.csv")
            stage_two.write_batch_manifest(
                stage_two.batch_rows(stage_two.read_csv(frozen_manifest), 1),
                batch_manifest)
            (out / "design-receipt.txt").write_text("design_mode=clean_current_stage_two\n")
            (out / "conversion-receipt.json").write_text("{}\n")

            stage_two.write_registry(out, source_registry, prepared, library, batch_manifest)

            registry = stage_two.read_csv(out / "source-hashes.csv")
            design_rows = [row for row in registry
                           if Path(row["path"]).name == "design-receipt.txt"]
            self.assertEqual(len(design_rows), 1)
            self.assertEqual(Path(design_rows[0]["path"]).resolve(),
                             (out / "design-receipt.txt").resolve())

    def test_batch_registry_preserves_one_source_rules_file_and_pins_adapter_copy(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            prepared, library, _ = write_adapter_runner_fixture(root / "baseline")
            registry_rows = stage_two.read_csv(
                root / "baseline" / "original-source-hashes.csv")
            source_rules = (root / "source" / "native-calibration-stage-two"
                            / "stage-two-rules.R")
            source_rules.parent.mkdir(parents=True)
            source_rules.write_text("# frozen first-look rules\n")
            registry_rows.append({"path": str(source_rules.resolve()),
                                  "sha256": stage_two.sha256(source_rules)})
            source_registry = root / "source-registry.csv"
            with source_registry.open("w", newline="", encoding="utf-8") as stream:
                writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
                writer.writeheader()
                writer.writerows(registry_rows)

            out = root / "batch"
            out.mkdir()
            manifest = out / "manifest.csv"
            frozen_manifest = (HERE.parents[2]
                               / "docs/dev-log/general-sd-regression/stage-two-manifest.csv")
            stage_two.write_batch_manifest(
                stage_two.batch_rows(stage_two.read_csv(frozen_manifest), 1), manifest)
            (out / "design-receipt.txt").write_text("status=prepared_not_launched\n")
            (out / "conversion-receipt.json").write_text("{}\n")

            stage_two.write_registry(out, source_registry, prepared, library, manifest)

            rows = stage_two.read_csv(out / "source-hashes.csv")
            rules = [row for row in rows
                     if row["path"].endswith("native-calibration-stage-two/stage-two-rules.R")]
            self.assertEqual(len(rules), 1)
            self.assertEqual(Path(rules[0]["path"]).resolve(), source_rules.resolve())
            adapter_copy = [row for row in rows
                            if Path(row["path"]).name == "adapter-stage-two-rules.R"]
            self.assertEqual(len(adapter_copy), 1)
            self.assertEqual(adapter_copy[0]["sha256"],
                             stage_two.sha256(HERE / "stage-two-rules.R"))

    def test_batch_registry_remaps_pinned_source_root_to_stage_two_overlay(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            prepared, library, _ = write_adapter_runner_fixture(root / "baseline")
            source_registry = root / "baseline" / "original-source-hashes.csv"
            rows = stage_two.read_csv(source_registry)
            source_root = root / "baseline" / "source"
            # Match actual package-relative registry paths. The old fixture
            # omitted the tools/general-sd-regression prefix and hid a miss.
            rows = [row for row in rows
                    if not Path(row["path"]).as_posix().endswith(
                        "native-calibration/worker-095.R")]
            package_file = source_root / "R" / "drmTMB.R"
            package_file.parent.mkdir()
            package_file.write_text("# source-bound package entry point\n")
            source_worker = (source_root / "tools" / "general-sd-regression"
                             / "native-calibration" / "worker-095.R")
            source_worker.parent.mkdir(parents=True)
            shutil.copy2(stage_two.BASE / "worker-095.R", source_worker)
            source_rules = (source_root / "tools" / "general-sd-regression"
                            / "native-calibration-stage-two" / "stage-two-rules.R")
            source_rules.parent.mkdir(parents=True)
            source_rules.write_text("# pre-stage-two rules\n")
            for path in (package_file, source_worker, source_rules):
                rows.append({"path": str(path.resolve()), "sha256": stage_two.sha256(path)})
            with source_registry.open("w", newline="", encoding="utf-8") as stream:
                writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
                writer.writeheader()
                writer.writerows(rows)

            overlay = root / "stage-two-source-overlay"
            shutil.copytree(source_root, overlay)
            worker = (overlay / "tools" / "general-sd-regression"
                      / "native-calibration" / "worker-095.R")
            shutil.copy2(HERE.parent / "native-calibration" / "worker-095.R", worker)
            rules = (overlay / "tools" / "general-sd-regression"
                     / "native-calibration-stage-two" / "stage-two-rules.R")
            shutil.copy2(HERE / "stage-two-rules.R", rules)
            shutil.copy2(HERE / "clean_current_stage_two.py", rules.parent
                         / "clean_current_stage_two.py")

            out = root / "batch"
            out.mkdir()
            manifest = out / "manifest.csv"
            frozen_manifest = (HERE.parents[2]
                               / "docs/dev-log/general-sd-regression/stage-two-manifest.csv")
            stage_two.write_batch_manifest(
                stage_two.batch_rows(stage_two.read_csv(frozen_manifest), 1), manifest)
            (out / "design-receipt.txt").write_text("status=prepared_not_launched\n")
            (out / "conversion-receipt.json").write_text("{}\n")

            stage_two.write_registry(out, source_registry, prepared, library, manifest,
                                     source_overlay=overlay)

            registry = stage_two.read_csv(out / "source-hashes.csv")
            for suffix, expected in (
                    ("R/drmTMB.R", overlay / "R" / "drmTMB.R"),
                    ("tools/general-sd-regression/native-calibration/worker-095.R", worker),
                    ("tools/general-sd-regression/native-calibration-stage-two/stage-two-rules.R",
                     rules),
                    ("tools/general-sd-regression/native-calibration-stage-two/clean_current_stage_two.py",
                     rules.parent / "clean_current_stage_two.py")):
                matches = [row for row in registry if row["path"].endswith(suffix)]
                self.assertEqual(len(matches), 1, suffix)
                self.assertEqual(Path(matches[0]["path"]).resolve(), expected.resolve())
                self.assertEqual(matches[0]["sha256"], stage_two.sha256(expected))
            self.assertEqual(package_file.read_text(), "# source-bound package entry point\n")
            self.assertFalse((source_root / "tools" / "general-sd-regression"
                              / "native-calibration-stage-two"
                              / "clean_current_stage_two.py").exists())

    def test_source_overlay_rejects_clean_helper_pin_outside_package_tree(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source_root = root / "source"
            package = source_root / "R" / "drmTMB.R"
            worker = (source_root / "tools" / "general-sd-regression"
                      / "native-calibration" / "worker-095.R")
            rules = (source_root / "tools" / "general-sd-regression"
                     / "native-calibration-stage-two" / "stage-two-rules.R")
            for path in (package, worker, rules):
                path.parent.mkdir(parents=True, exist_ok=True)
            package.write_text("# package root\n")
            shutil.copy2(stage_two.BASE / "worker-095.R", worker)
            rules.write_text("# original rules\n")

            overlay = root / "overlay"
            shutil.copytree(source_root, overlay)
            shutil.copy2(HERE.parent / "native-calibration" / "worker-095.R",
                         overlay / worker.relative_to(source_root))
            shutil.copy2(HERE / "stage-two-rules.R", overlay / rules.relative_to(source_root))
            helper_relative = rules.relative_to(source_root).with_name(
                "clean_current_stage_two.py")
            helper_target = overlay / helper_relative
            shutil.copy2(HERE / "clean_current_stage_two.py", helper_target)

            external_helper = (root / "external" / helper_relative)
            external_helper.parent.mkdir(parents=True)
            shutil.copy2(HERE / "clean_current_stage_two.py", external_helper)
            entries = [
                {"path": str(package), "sha256": stage_two.sha256(package)},
                {"path": str(worker), "sha256": stage_two.sha256(worker)},
                {"path": str(rules), "sha256": stage_two.sha256(rules)},
                {"path": str(external_helper), "sha256": stage_two.sha256(external_helper)},
            ]

            with self.assertRaisesRegex(ValueError, "inside the package source tree"):
                stage_two._source_overlay_registry_map(entries, overlay)

    def test_shared_stage_two_source_and_batch_helpers_preserve_clean_current_mode(self):
        source = self.adapter.read_frozen_rows(self.manifest)
        stage_two.validate_source(source, self.manifest, set())
        for batch_id, expected in enumerate(self.adapter.load_batches(self.manifest), start=1):
            observed = stage_two.batch_rows(source, batch_id)
            self.assertEqual(observed, expected)
            stage_two.validate_batch_manifest(observed, source, batch_id)
        contaminated = {int(source[0]["seed"])}
        with self.assertRaisesRegex(ValueError, "overlap"):
            stage_two.validate_source(source, self.manifest, contaminated)
        changed_source = [dict(row) for row in source]
        changed_source[0]["seed"] = str(int(changed_source[0]["seed"]) + 1)
        with self.assertRaisesRegex(ValueError, "exact frozen source"):
            stage_two.validate_source(changed_source, self.manifest, set())

    def test_run_preflight_resolves_only_the_source_bound_by_root_receipt(self):
        clean_rows = [{"path": str(self.manifest.resolve()),
                       "sha256": self.adapter.EXPECTED_SHA256}]
        path, is_clean = stage_two.resolve_stage_two_source(
            clean_rows, self.adapter.EXPECTED_SHA256)
        self.assertEqual(path, self.manifest.resolve())
        self.assertTrue(is_clean)
        legacy = (HERE.parents[2] / "docs/dev-log/general-sd-regression"
                  / "stage-two-manifest.csv")
        legacy_sha = stage_two.sha256(legacy)
        legacy_rows = [{"path": str(legacy.resolve()), "sha256": legacy_sha}]
        path, is_clean = stage_two.resolve_stage_two_source(legacy_rows, legacy_sha)
        self.assertEqual(path, legacy.resolve())
        self.assertFalse(is_clean)
        with self.assertRaisesRegex(ValueError, "unsupported"):
            stage_two.resolve_stage_two_source(clean_rows, "0" * 64)
        with self.assertRaisesRegex(ValueError, "exactly one"):
            stage_two.resolve_stage_two_source(
                clean_rows * 2, self.adapter.EXPECTED_SHA256)

    def test_rejects_changed_missing_reordered_and_wrong_identity_rows(self):
        rows = self.adapter.read_frozen_rows(self.manifest)
        mutations = (
            lambda values: values[0].update(a="0.0"),
            lambda values: values.pop(0),
            lambda values: values.__setitem__(slice(0, 2), values[1::-1]),
            lambda values: values[0].update(master_seed="2026101901"),
            lambda values: values[0].update(seed="1"),
            lambda values: values[0].update(beta0="0"),
            lambda values: values[0].update(replicate="1000"),
        )
        for mutate in mutations:
            with self.subTest(mutate=mutate):
                changed = [dict(row) for row in rows]
                mutate(changed)
                with tempfile.TemporaryDirectory() as tmp:
                    bad_path = Path(tmp) / "look2.csv"
                    self.adapter.write_rows(changed, bad_path)
                    with self.assertRaises((ValueError, RuntimeError)):
                        self.adapter.load_batches(bad_path)


class CleanCurrentLookTwoRunnerTests(unittest.TestCase):
    """No-fit checks that the production runner rejects look-two identity drift."""

    @classmethod
    def setUpClass(cls):
        import clean_current_stage_two
        cls.adapter = clean_current_stage_two
        cls.manifest = (HERE.parents[2] / "docs/dev-log/general-sd-regression/evidence"
                        / "calibration-20261019/clean-current-seed-design-v1/look2.csv")
        cal = HERE.parent / "native-calibration"
        spec = importlib.util.spec_from_file_location("run_095", cal / "run-095.py")
        cls.runner = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.runner)
        cls.module_path = HERE / "clean_current_stage_two.py"

    def test_runner_preflight_accepts_each_exact_batch_and_rejects_receipt_mutations(self):
        batches = self.adapter.load_batches(self.manifest)
        for batch_id, rows in enumerate(batches, start=1):
            design = {
                "design_mode": "clean_current_stage_two",
                "master_seed": "2026101902",
                "profile_level": "0.95",
                "planned_attempts": "3000",
                "calibration_claim": "true",
                "clean_current_seed_stream": "2026101902",
                "stage_two_manifest_sha256": self.adapter.EXPECTED_SHA256,
                "stage_two_batch_id": str(batch_id),
            }
            self.assertTrue(self.runner.validate_design(
                rows, design, list(range(1, 3001)), False))
            with tempfile.TemporaryDirectory() as tmp:
                registry = Path(tmp) / "source-hashes.csv"
                with registry.open("w", newline="", encoding="utf-8") as stream:
                    writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
                    writer.writeheader()
                    writer.writerow({"path": str(self.module_path.resolve()),
                                     "sha256": self.adapter.sha256(self.module_path)})
                self.assertTrue(self.runner.validate_clean_current_stage_two_manifest(
                    rows, self.manifest, registry, batch_id))
            mutations = (
                dict(design, master_seed="2026101901"),
                dict(design, stage_two_batch_id="4"),
                dict(design, profile_level="0.975"),
                dict(design, calibration_claim="false"),
                dict(design, stage_two_manifest_sha256="0" * 64),
            )
            for bad_design in mutations:
                with self.subTest(batch_id=batch_id, design=bad_design):
                    with self.assertRaises(ValueError):
                        self.runner.validate_design(
                            rows, bad_design, list(range(1, 3001)), False)

    def test_prepared_clean_current_design_receipts_satisfy_worker_contract(self):
        """Prepared batch receipts must pass the real worker's frozen design gate."""
        batches = self.adapter.load_batches(self.manifest)
        source_sha = self.adapter.EXPECTED_SHA256
        for batch_id, rows in enumerate(batches, start=1):
            text = stage_two.clean_current_stage_two_design_receipt(
                batch_id=batch_id, source_manifest_sha256=source_sha)
            design = dict(line.split("=", 1) for line in text.splitlines())
            with self.subTest(batch_id=batch_id):
                self.assertTrue(self.runner.validate_design(
                    rows, design, list(range(1, 3001)), False))
        with self.assertRaisesRegex(ValueError, "batch must be 1, 2, or 3"):
            stage_two.clean_current_stage_two_design_receipt(4, source_sha)
        with self.assertRaisesRegex(ValueError, "frozen look-two manifest"):
            stage_two.clean_current_stage_two_design_receipt(1, "0" * 64)

    def test_old_clean_current_probe_mapping_is_identity_preserving_only(self):
        """The historical row mapping is retained for audit, not qualification."""
        batches = self.adapter.load_batches(self.manifest)
        cases = self.adapter.adapter_qualification_cases(batches)
        self.assertEqual(
            [(x["batch_id"], x["local_index"], x["stage_two_index"],
              x["replicate"], float(x["a"])) for x in cases],
            [(1, 1, 1, 1001, -0.5),
             (2, 1001, 4001, 2001, 0.0),
             (3, 2001, 8001, 3001, 0.5)],
        )
        self.assertEqual([x["seed"] for x in cases], [
            int(batches[b - 1][local - 1]["seed"])
            for b, local in ((1, 1), (2, 1001), (3, 2001))
        ])

    def test_clean_current_qualification_rejects_look_two_seed_reuse(self):
        """Operational fit probes must not be selected from calibration rows."""
        with self.assertRaisesRegex(ValueError, "reuses look-two calibration seeds"):
            stage_two.resolve_adapter_qualification_source(
                self.manifest, source_mode="clean_current")

    def test_shared_adapter_source_resolver_rejects_reused_clean_current_probes(self):
        source = self.adapter.DEFAULT_MANIFEST.resolve(strict=True)
        with self.assertRaisesRegex(ValueError,
                                    "reuses look-two calibration seeds"):
            stage_two.resolve_adapter_qualification_source(
                source, source_mode="clean_current")

    def test_shared_adapter_source_resolver_rejects_changed_clean_current_source(self):
        with tempfile.TemporaryDirectory() as tmp:
            changed = Path(tmp) / "look2.csv"
            changed.write_bytes(self.adapter.DEFAULT_MANIFEST.read_bytes() + b"\n")
            with self.assertRaisesRegex(ValueError, "frozen clean-current"):
                stage_two.resolve_adapter_qualification_source(
                    changed, source_mode="clean_current")

    def test_shared_adapter_source_resolver_rejects_prior_seed_overlap(self):
        source = self.adapter.DEFAULT_MANIFEST.resolve(strict=True)
        first_seed = int(self.adapter.read_frozen_rows(source)[0]["seed"])
        with self.assertRaisesRegex(ValueError, "overlaps a prior seed stream"):
            stage_two.resolve_adapter_qualification_source(
                source, source_mode="clean_current", excluded_seeds={first_seed})

    def test_clean_current_adapter_receipt_marks_probes_nonqualifying(self):
        cases = self.adapter.adapter_qualification_cases(
            self.adapter.load_batches(self.manifest))
        receipt = stage_two.clean_current_adapter_design_receipt(
            2, self.adapter.EXPECTED_SHA256, cases[1])
        fields = dict(line.split("=", 1) for line in receipt.splitlines())
        self.assertEqual(fields["design_mode"], "clean_current_stage_two")
        self.assertEqual(fields["stage_two_status"],
                         "adapter_qualification_only_no_final_go")
        self.assertEqual(fields["calibration_claim"], "false")
        self.assertEqual(fields["qualification_local_index"], "1001")
        self.assertEqual(fields["qualification_stage_two_index"], "4001")
        self.assertEqual(fields["adapter_qualification_only"], "true")
        with self.assertRaisesRegex(ValueError, "batch does not match"):
            stage_two.clean_current_adapter_design_receipt(
                1, self.adapter.EXPECTED_SHA256, cases[1])

    def test_adapter_qualification_rejects_changed_clean_current_probe_identity(self):
        batches = self.adapter.load_batches(self.manifest)
        batches[1] = [dict(row) for row in batches[1]]
        batches[1][1000]["stage_two_index"] = "4002"
        with self.assertRaisesRegex(ValueError, "qualification mapping"):
            self.adapter.adapter_qualification_cases(batches)

    def test_runner_rejects_wrong_batch_mapping_before_any_supervisor_call(self):
        rows = self.adapter.load_batches(self.manifest)[0]
        changed = [dict(row) for row in rows]
        changed[0]["seed"] = str(int(changed[0]["seed"]) + 1)
        with tempfile.TemporaryDirectory() as tmp:
            registry = Path(tmp) / "source-hashes.csv"
            with registry.open("w", newline="", encoding="utf-8") as stream:
                writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
                writer.writeheader()
                writer.writerow({"path": str(self.module_path.resolve()),
                                 "sha256": self.adapter.sha256(self.module_path)})
            with self.assertRaises(ValueError):
                self.runner.validate_clean_current_stage_two_manifest(
                    changed, self.manifest, registry, 1)

    def test_stage_two_orchestrator_validates_clean_current_batch_identity(self):
        """The shared orchestrator must retain the clean-current source mapping."""
        batches = self.adapter.load_batches(self.manifest)
        for batch_id, rows in enumerate(batches, start=1):
            self.assertTrue(stage_two.validate_clean_current_batch_manifest(
                rows, self.manifest, batch_id))
            changed = [dict(row) for row in rows]
            changed[0]["source_index"] = str(int(changed[0]["source_index"]) + 1)
            with self.subTest(batch_id=batch_id), self.assertRaises(ValueError):
                stage_two.validate_clean_current_batch_manifest(
                    changed, self.manifest, batch_id)

    def test_run_batches_dispatches_all_prepared_clean_current_batches_without_fits(self):
        """The sealed runner path retains clean-current mode for each batch."""
        with tempfile.TemporaryDirectory() as tmp:
            prepared, external_path, library = write_clean_current_run_fixture(Path(tmp))
            design_modes = []
            worker_paths = []

            def no_fit_supervisor(indices, command_factory, directory, workers,
                                  case_timeout, campaign_timeout, env,
                                  registry_sha256, design_mode):
                del workers, case_timeout
                del campaign_timeout, env, registry_sha256
                self.assertEqual(indices, list(range(1, 3001)))
                design_modes.append(design_mode)
                worker_paths.append(Path(command_factory(indices[0])[1]).resolve())
                (directory / "supervisor-receipt.json").write_text(
                    json.dumps({"status": "all_terminal",
                                "planned_indices": indices,
                                "campaign_complete": True,
                                "subset_complete": True,
                                "interrupted": False}) + "\n")

            def replay_first_look(command, capture_output, text, timeout):
                del capture_output, text, timeout
                standardized = Path(command[-1])
                standardized.write_text("index\n1\n")
                Path(str(standardized) + ".receipt.json").write_text("{}\n")
                return subprocess.CompletedProcess(command, 0, "", "")

            run_module = types.ModuleType("run")
            run_module.supervise = no_fit_supervisor
            integrity_module = types.ModuleType("integrity")
            integrity_module.verify = lambda _path: None
            terminal_cases = [{"index": i, "status": "completed"}
                              for i in range(1, 3001)]
            with (
                patch.dict(sys.modules, {"run": run_module,
                                         "integrity": integrity_module}),
                patch.object(stage_two, "validate_go", lambda *args, **kwargs: None),
                patch.object(stage_two, "validate_binary_receipt",
                             lambda *args, **kwargs: None),
                patch.object(stage_two, "attempt_digest",
                             lambda *args, **kwargs: "attempts-digest"),
                patch.object(stage_two, "validate_batch_receipt",
                             lambda *args, **kwargs: {"cases": terminal_cases}),
                patch.object(stage_two, "sealed_reconstruction_file",
                             return_value=HERE / "verify-first-look.R"),
                patch.object(stage_two.subprocess, "run", replay_first_look),
            ):
                stage_two.run_batches(prepared, external_path,
                                      stage_two.sha256(external_path), library,
                                      outer_timeout=60)

            self.assertEqual(design_modes,
                             ["clean_current_stage_two"] * 3)
            expected_worker = stage_two.resolve_registered_profile_worker(
                stage_two.read_csv(prepared / "batch-1" / "source-hashes.csv"))
            self.assertEqual(worker_paths, [expected_worker] * 3)
            run_receipt = json.loads(
                (prepared / "stage-two-run-receipt.json").read_text())
            self.assertEqual(run_receipt["status"], "all_batches_terminal")
            self.assertEqual([x["batch_id"] for x in run_receipt["batches"]],
                             [1, 2, 3])
            self.assertTrue(all(x["status_counts"]["completed"] == 3000
                                for x in run_receipt["batches"]))

    def test_prepare_clean_current_cli_emits_worker_ready_batches_without_fits(self):
        """Preparation must produce manifests accepted by the actual worker validator."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            _, library, _ = write_adapter_runner_fixture(root / "baseline")
            original_registry = root / "baseline" / "original-source-hashes.csv"
            source_manifest = stage_two._clean_current_adapter().DEFAULT_MANIFEST
            first = root / "first-look"
            first.mkdir()
            first_rows = [{"index": str(i), "a": str((-0.5, 0.0, 0.5)[(i - 1) // 1000]),
                           "replicate": str(1000 + i), "seed": str(700000 + i),
                           "master_seed": "2026101703", "design_mode": "production"}
                          for i in range(1, 3001)]
            first_manifest = first / "manifest.csv"
            with first_manifest.open("w", newline="", encoding="utf-8") as stream:
                writer = csv.DictWriter(stream, fieldnames=list(first_rows[0]))
                writer.writeheader()
                writer.writerows(first_rows)
            result_fields = ["index", "seed", "a", "replicate", "state", "estimate", "se",
                             "convergence", "pdHess", "max_abs_gradient", "clamp_at_optimum",
                             "lower", "upper", "profile_level", "interval_status",
                             "profile_boundary", "valid_interval", "laplace_oracle_error",
                             "oracle_pass", "error"]
            result_template = {"state": "completed", "estimate": "0", "se": "1",
                               "convergence": "0", "pdHess": "TRUE",
                               "max_abs_gradient": "0.0001", "clamp_at_optimum": "ok",
                               "lower": "-1", "upper": "1", "profile_level": "0.95",
                               "interval_status": "profile", "profile_boundary": "FALSE",
                               "valid_interval": "FALSE", "laplace_oracle_error": "1",
                               "oracle_pass": "FALSE", "error": ""}
            for row in first_rows:
                result = {**result_template, "index": row["index"], "seed": row["seed"],
                          "a": row["a"], "replicate": row["replicate"]}
                result_path = first / f"result-{int(row['index']):04d}.csv"
                with result_path.open("w", newline="", encoding="utf-8") as stream:
                    writer = csv.DictWriter(stream, fieldnames=result_fields)
                    writer.writeheader()
                    writer.writerow(result)
            decision = first / "decision.txt"
            decision.write_text("look2_required\n")
            original_rows = stage_two.read_csv(original_registry)
            source_registry = root / "source-hashes.csv"
            registry_rows = [{"path": str(first_manifest.resolve()),
                              "sha256": stage_two.sha256(first_manifest)},
                             {"path": str(source_manifest.resolve()),
                              "sha256": stage_two.sha256(source_manifest)}]
            registry_rows.extend(row for row in original_rows
                                 if Path(row["path"]).name in {"drmTMB.rdb", "drmTMB.rdx",
                                                               "drmTMB.so",
                                                               "worker-095.R"})
            with source_registry.open("w", newline="", encoding="utf-8") as stream:
                writer = csv.DictWriter(stream, fieldnames=["path", "sha256"])
                writer.writeheader()
                writer.writerows(registry_rows)
            shutil.copy2(source_registry, first / "source-hashes.csv")
            (first / "supervisor-receipt.json").write_text(json.dumps({
                "registry_sha256": stage_two.sha256(source_registry),
                "manifest_sha256": stage_two.sha256(first_manifest),
                "planned_indices": list(range(1, 3001)),
                "campaign_complete": True, "subset_complete": True,
                "interrupted": False,
                "cases": [{"index": i, "status": "completed", "returncode": 0}
                          for i in range(1, 3001)],
            }))
            first_attempt_sha = stage_two.attempt_digest(first, expected_results=3000)
            go = root / "go.json"
            go.write_text(json.dumps({"decision": "look2_required",
                "first_look_registry_sha256": stage_two.sha256(source_registry),
                "first_look_decision_sha256": stage_two.sha256(decision)}) + "\n")
            seal = root / "seal.json"
            seal.write_text(json.dumps({
                "registry_sha256": stage_two.sha256(source_registry),
                "decision_path": str(decision.resolve()),
                "decision_sha256": stage_two.sha256(decision),
                "attempts_sha256": first_attempt_sha,
                "harness_archive_sha256": "h" * 64,
                "matched_original_native_artifacts": [{"name": "drmTMB.so",
                                                        "sha256": "b" * 64}],
            }) + "\n")

            prior_manifests = []
            for number, (n_rows, master) in enumerate(
                    ((6, 2026101702), (3000, 2026101704), (3000, 2026101703)), 1):
                path = root / f"prior-{number}.csv"
                with path.open("w", newline="", encoding="utf-8") as stream:
                    writer = csv.DictWriter(stream, fieldnames=["index", "seed", "master_seed"])
                    writer.writeheader()
                    writer.writerows({"index": i, "seed": 900000000 + number * 10000 + i,
                                      "master_seed": master}
                                     for i in range(1, n_rows + 1))
                prior_manifests.append(path)

            spec = importlib.util.spec_from_file_location(
                "prepare_stage_two_under_test", HERE / "prepare-stage-two.py")
            prepare = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(prepare)
            prepared = root / "prepared"
            external = root / "external-seals.json"
            standardized_rows = [{"look": "1", "attempt_index": str(i),
                                  "source_index": str(i), "truth": row["a"],
                                  "estimate": "0", "lower": "-1", "upper": "1",
                                  "profile_level": "0.95", "valid": "FALSE",
                                  "status": "completed"}
                                 for i, row in enumerate(first_rows, start=1)]

            def fake_subprocess_run(command, capture_output, text, timeout):
                del capture_output, text, timeout
                if (command[0] == "replay"
                        or str(command[-1]).endswith("first-look-standardized.csv")):
                    standardized = Path(command[-1])
                    with standardized.open("w", newline="", encoding="utf-8") as stream:
                        writer = csv.DictWriter(stream, fieldnames=list(standardized_rows[0]))
                        writer.writeheader()
                        writer.writerows(standardized_rows)
                    Path(str(standardized) + ".receipt.json").write_text("{}\n")
                return subprocess.CompletedProcess(command, 0, "", "")

            def no_fit_supervisor(indices, command_factory, directory, workers,
                                  case_timeout, campaign_timeout, env,
                                  registry_sha256, design_mode):
                del command_factory, workers, case_timeout, campaign_timeout, env
                self.assertEqual(indices, list(range(1, 3001)))
                self.assertEqual(design_mode, "clean_current_stage_two")
                cases = [{"index": i, "status": "error", "returncode": 1}
                         for i in indices]
                (directory / "supervisor-receipt.json").write_text(json.dumps({
                    "registry_sha256": registry_sha256,
                    "manifest_sha256": stage_two.sha256(directory / "manifest.csv"),
                    "planned_indices": indices, "campaign_complete": True,
                    "subset_complete": True, "interrupted": False,
                    "cases": cases,
                }) + "\n")

            run_module = types.ModuleType("run")
            run_module.supervise = no_fit_supervisor
            external.write_text(json.dumps({
                "go_record_path": str(go.resolve()),
                "go_record_sha256": stage_two.sha256(go),
                "first_look_seal_path": str(seal.resolve()),
                "first_look_seal_sha256": stage_two.sha256(seal),
                "first_look_root": str(first.resolve()),
                "first_look_decision_path": str(decision.resolve()),
                "root_preparation_receipt_sha256": "pending",
                "batch_registry_sha256": {}, "rscript": "Rscript",
            }, sort_keys=True) + "\n")

            argv = [str(HERE / "prepare-stage-two.py"), str(first),
                    str(source_registry), str(library), str(source_manifest),
                    str(go), str(seal), "--go-record-sha256", stage_two.sha256(go),
                    "--first-look-seal-sha256", stage_two.sha256(seal),
                    "--rscript", "Rscript", *map(str, prior_manifests), str(prepared)]
            integrity = types.ModuleType("integrity")
            integrity.verify = lambda _path: None
            with (
                patch.dict(sys.modules, {"integrity": integrity}),
                patch.dict(sys.modules, {"run": run_module}),
                patch.object(prepare, "validate_go", lambda *args, **kwargs: None),
                patch.object(prepare, "validate_binary_receipt", lambda *args, **kwargs: None),
                patch.object(prepare, "first_look_replay_command",
                             side_effect=lambda _seal, _first, _seal_path, output, _rscript:
                             ["replay", str(output)]),
                patch.object(prepare.subprocess, "run", side_effect=fake_subprocess_run),
                patch.object(sys, "argv", argv),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                prepare.main()

            receipt = json.loads((prepared / "root-preparation-receipt.json").read_text())
            self.assertEqual(receipt["status"], "prepared_not_launched")
            self.assertTrue(receipt["no_fits_launched"])
            self.assertEqual(receipt["source_design_mode"], "clean_current")
            self.assertEqual(receipt["worker_design_mode"], "clean_current_stage_two")
            self.assertEqual(len(receipt["batches"]), 3)
            for batch_id in (1, 2, 3):
                directory = prepared / f"batch-{batch_id}"
                rows = stage_two.read_csv(directory / "manifest.csv")
                design_text = (directory / "design-receipt.txt").read_text()
                design = dict(line.split("=", 1) for line in design_text.splitlines())
                self.assertTrue(self.runner.validate_design(
                    rows, design, list(range(1, 3001)), False))
                conversion = json.loads((directory / "conversion-receipt.json").read_text())
                self.assertEqual(conversion["design_mode_source"], "clean_current")
                self.assertEqual(conversion["design_mode_worker"],
                                 "clean_current_stage_two")

            external_doc = json.loads(external.read_text())
            external_doc["root_preparation_receipt_sha256"] = stage_two.sha256(
                prepared / "root-preparation-receipt.json")
            external_doc["batch_registry_sha256"] = {
                str(batch["batch_id"]): batch["registry_sha256"]
                for batch in receipt["batches"]}
            external.write_text(json.dumps(external_doc, sort_keys=True) + "\n")
            def replay_command(_seal, _first, _seal_path, output, _rscript):
                return ["replay", str(output)]

            with (
                patch.dict(sys.modules, {"run": run_module,
                                         "integrity": integrity}),
                patch.object(stage_two, "validate_go", lambda *args, **kwargs: None),
                patch.object(stage_two, "validate_binary_receipt",
                             lambda *args, **kwargs: None),
                patch.object(stage_two, "sealed_reconstruction_file",
                             return_value=HERE / "verify-first-look.R"),
                patch.object(stage_two, "first_look_replay_command",
                             side_effect=replay_command),
                patch.object(stage_two, "subprocess") as process,
            ):
                process.run.side_effect = fake_subprocess_run
                stage_two.run_batches(prepared, external, stage_two.sha256(external),
                                      library, outer_timeout=60)
            run_receipt = json.loads(
                (prepared / "stage-two-run-receipt.json").read_text())
            self.assertEqual(run_receipt["status"], "all_batches_terminal")
            self.assertEqual(len(run_receipt["batches"]), 3)
            self.assertTrue(all(batch["status_counts"]["error"] == 3000
                                for batch in run_receipt["batches"]))

            staged_analyzer = root / "staged-analyzer.R"
            staged_analyzer.write_text(
                "native_sd_staged_decision <- function(attempts, manifest_count, look, completed_campaign) {\n"
                "  decision <- if (look == 1L) 'look2_required' else 'inconclusive'\n"
                "  list(decision = decision, metrics = data.frame(), gates = data.frame(), status_counts = data.frame())\n"
                "}\n")
            setup_r = root / "save-first-look-decision.R"
            setup_r.write_text(
                "args <- commandArgs(trailingOnly = TRUE)\n"
                "saveRDS(list(decision = 'look2_required', metrics = data.frame(), gates = data.frame(), status_counts = data.frame()), args[[1L]])\n")
            setup = subprocess.run(["Rscript", str(setup_r),
                                    str(first / "staged-decision.rds")],
                                   capture_output=True, text=True, timeout=60)
            self.assertEqual(setup.returncode, 0, setup.stderr)

            adapter_sources = ("stage_two.py", "reconstruct-first-look.py",
                              "stage-two-rules.R", "verify-first-look.R",
                              "combine-stage-two.R")
            run_receipt_path = prepared / "stage-two-run-receipt.json"
            combination_seals = {
                "staged_decision_path": str(staged_analyzer.resolve()),
                "staged_decision_sha256": stage_two.sha256(staged_analyzer),
                "adapter_rules_path": str((HERE / "stage-two-rules.R").resolve()),
                "adapter_rules_sha256": stage_two.sha256(HERE / "stage-two-rules.R"),
                "first_look_reconstruction_source_sha256": {
                    name: stage_two.sha256(HERE / name) for name in adapter_sources},
                "first_look_registry_sha256": stage_two.sha256(first / "source-hashes.csv"),
                "first_look_attempts_sha256": stage_two.attempt_digest(
                    first, expected_results=3000),
                "root_preparation_receipt_sha256": stage_two.sha256(
                    prepared / "root-preparation-receipt.json"),
                "first_look_seal_sha256": stage_two.sha256(seal),
                "go_record_sha256": stage_two.sha256(go),
                "harness_archive_sha256": "h" * 64,
                "first_look_decision_sha256": stage_two.sha256(decision),
                "batch_registry_sha256": external_doc["batch_registry_sha256"],
                "stage_two_run_receipt_sha256": stage_two.sha256(run_receipt_path),
                "run_authorization_seals_sha256": stage_two.sha256(external),
                "batch_attempt_sha256": {
                    str(batch["batch_id"]): batch["attempts_sha256"]
                    for batch in run_receipt["batches"]},
                "first_look_decision_path": str(decision.resolve()),
                "go_record_path": str(go.resolve()),
            }
            combination_seal_path = root / "combination-seals.json"
            combination_seal_path.write_text(
                json.dumps(combination_seals, sort_keys=True) + "\n")
            combined = root / "combined"
            combine = subprocess.run([
                "Rscript", str(HERE / "combine-stage-two.R"), str(first),
                *(str(prepared / f"batch-{batch_id}") for batch_id in (1, 2, 3)),
                str(combination_seal_path), stage_two.sha256(combination_seal_path),
                str(combined)], capture_output=True, text=True, timeout=180)
            self.assertEqual(combine.returncode, 0,
                             combine.stdout + "\n" + combine.stderr)
            self.assertIn("STAGE_TWO_COMBINE_COMPLETE inconclusive", combine.stdout)
            decision_receipt = json.loads(
                (combined / "decision-receipt.json").read_text())
            combined_attempts = stage_two.read_csv(combined / "all-attempts.csv")
            self.assertEqual(decision_receipt["decision"], "inconclusive")
            self.assertEqual(len(combined_attempts), 12000)
            self.assertTrue(all(row.get("stage_two_index") in {None, "", "NA"}
                                for row in combined_attempts[:3000]))
            self.assertEqual([int(row["source_index"])
                              for row in combined_attempts[3000:]],
                             list(range(1, 9001)))
            self.assertEqual({row["source_design_mode"]
                              for row in combined_attempts[3000:]}, {"clean_current"})


if __name__ == "__main__":
    unittest.main(verbosity=2)
