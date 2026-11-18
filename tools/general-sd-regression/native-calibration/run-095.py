#!/usr/bin/env python3
"""Bounded all-attempt supervisor for a prepared native SD campaign."""
import argparse
import csv
import hashlib
import json
import os
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from integrity import verify


class Interrupted(BaseException):
    pass


def atomic_json(path, value):
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def supervise(indices, command_factory, outdir: Path, workers=16,
              case_timeout=120.0, campaign_timeout=3600.0, env=None,
              registry_sha256=None, design_mode="test", calibration_claim=True):
    if workers < 1 or workers > 16 or case_timeout <= 0 or case_timeout > 120 or campaign_timeout <= 0 or campaign_timeout > 3600:
        raise ValueError("limits exceed frozen 16 workers / 120s per case / 3600s campaign")
    indices = [int(i) for i in indices]
    if not indices or len(set(indices)) != len(indices):
        raise ValueError("indices must be nonempty and unique")
    receipt_path = outdir / "supervisor-receipt.json"
    if receipt_path.exists():
        raise FileExistsError(f"Refusing to overwrite {receipt_path}")
    started_at = time.time(); deadline = started_at + campaign_timeout
    states = {i: {"index": i, "status": "not_started", "started_at": None,
                  "finished_at": None, "returncode": None, "pid": None} for i in indices}
    pending = iter(indices); running = {}; logs = outdir / "worker-logs"
    logs.mkdir(exist_ok=False)

    def receipt(interrupted=False):
        complete_subset = all(states[i]["status"] in {"completed", "error", "timeout"} for i in indices)
        complete_campaign = (indices in (list(range(1, 3001)), list(range(1, 46))) and
                             not interrupted and complete_subset)
        atomic_json(receipt_path, {"started_at": started_at, "finished_at": time.time(),
            "campaign_timeout_seconds": campaign_timeout, "case_timeout_seconds": case_timeout,
            "workers": workers, "planned_indices": indices, "interrupted": interrupted,
            "design_mode": design_mode, "registry_sha256": registry_sha256,
            "calibration_claim": bool(calibration_claim),
            "subset_complete": complete_subset, "campaign_complete": complete_campaign,
            "manifest_sha256": sha256_file(outdir / "manifest.csv") if (outdir / "manifest.csv").is_file() else None,
            "cases": [states[i] for i in sorted(states)]})

    def cleanup(status):
        for i, (proc, began, stdout, stderr) in list(running.items()):
            try:
                os.killpg(proc.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            proc.wait(); stdout.close(); stderr.close()
            states[i].update(status=status, finished_at=time.time(), returncode=proc.returncode)
            del running[i]

    def interrupt_handler(signum, frame):
        raise Interrupted(f"received signal {signum}")

    old_handlers = {sig: signal.signal(sig, interrupt_handler) for sig in (signal.SIGINT, signal.SIGTERM)}
    exhausted = False; last_receipt = 0.0; was_interrupted = False
    try:
        while not exhausted or running:
            now = time.time()
            while not exhausted and len(running) < workers and now < deadline:
                try:
                    idx = next(pending)
                except StopIteration:
                    exhausted = True; break
                stdout = (logs / f"{idx:04d}.stdout.log").open("wb")
                stderr = (logs / f"{idx:04d}.stderr.log").open("wb")
                child_env = os.environ.copy()
                child_env.update({"OPENBLAS_NUM_THREADS": "1", "OMP_NUM_THREADS": "1",
                                  "MKL_NUM_THREADS": "1", "VECLIB_MAXIMUM_THREADS": "1",
                                  "DRMTMB_SD_PLANNED_INDICES": ",".join(map(str, indices))})
                if env: child_env.update(env)
                try:
                    proc = subprocess.Popen(command_factory(idx), stdout=stdout, stderr=stderr,
                        env=child_env, start_new_session=True)
                except Exception as exc:
                    stdout.close(); stderr.close()
                    states[idx].update(status="launch_error", finished_at=time.time(),
                                       launch_error=f"{type(exc).__name__}: {exc}")
                    continue
                states[idx].update(status="started", started_at=time.time(), pid=proc.pid)
                running[idx] = (proc, time.time(), stdout, stderr)
            for idx, (proc, began, stdout, stderr) in list(running.items()):
                code = proc.poll()
                if code is not None:
                    stdout.close(); stderr.close()
                    states[idx].update(status="completed" if code == 0 else "error",
                                       finished_at=time.time(), returncode=code)
                    del running[idx]
                elif time.time() - began >= case_timeout or time.time() >= deadline:
                    try: os.killpg(proc.pid, signal.SIGKILL)
                    except ProcessLookupError: pass
                    proc.wait(); stdout.close(); stderr.close()
                    status = "timeout" if time.time() - began >= case_timeout else "campaign_timeout"
                    states[idx].update(status=status, finished_at=time.time(), returncode=proc.returncode)
                    del running[idx]
            if time.time() - last_receipt >= 1 or (exhausted and not running):
                receipt(); last_receipt = time.time()
            if time.time() >= deadline:
                cleanup("campaign_timeout"); exhausted = True
            if running or not exhausted: time.sleep(.05)
    except Interrupted:
        was_interrupted = True
        cleanup("interrupted")
        exhausted = True
    finally:
        cleanup("interrupted" if was_interrupted else "campaign_timeout")
        for sig, handler in old_handlers.items(): signal.signal(sig, handler)
        receipt(interrupted=was_interrupted)
    return states


def sha256_file(path):
    h = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""): h.update(chunk)
    return h.hexdigest()


def parse_indices(spec, available):
    if not spec: return list(available)
    values = [int(part) for part in spec.split(",") if part]
    if not values or len(values) != len(set(values)) or not set(values).issubset(set(available)):
        raise ValueError("--indices must be unique comma-separated manifest indices")
    return values


def make_subset(source, destination, indices):
    if destination.exists(): raise FileExistsError(f"Refusing to overwrite subset output: {destination}")
    destination.mkdir(parents=True)
    shutil.copy2(source / "manifest.csv", destination / "manifest.csv")
    shutil.copy2(source / "source-hashes.csv", destination / "source-hashes.csv")
    shutil.copy2(source / "design-receipt.txt", destination / "design-receipt.txt")
    (destination / "subset-receipt.json").write_text(json.dumps({
        "source_directory": str(source), "manifest_sha256": sha256_file(destination / "manifest.csv"),
        "subset_copy": "byte-identical full frozen 3000-row manifest",
        "planned_indices": list(indices), "planned_subset": len(indices)}, indent=2) + "\n")
    return destination


def validate_design(manifest, design, indices, subset):
    mode = design.get("design_mode")
    try:
        master = int(design.get("master_seed", "0"))
    except (TypeError, ValueError):
        raise ValueError("Invalid master seed in design receipt")
    if mode == "timing_only":
        expected = list(range(1, 46))
        if master != 2026101903 or design.get("planned_attempts") != "45" or \
                design.get("profile_level") != "0.95" or \
                design.get("calibration_claim", "").lower() != "false":
            raise ValueError("Timing design receipt must pin seed 2026101903, 45 attempts, 95%, and calibration_claim=false")
        if subset or indices != expected or len(manifest) != 45:
            raise ValueError("Timing runs require the full ordered 45-row manifest; subsets are forbidden")
        if [int(row.get("index", "0")) for row in manifest] != expected:
            raise ValueError("Timing manifest indices must be the ordered sequence 1:45")
        if any(row.get("design_mode") != mode or int(row.get("master_seed", "0")) != master
               for row in manifest):
            raise ValueError("Timing manifest mode/master seed differs from the receipt")
        return False
    if mode == "qualification":
        if not subset or indices != [1, 1001, 2001] or master != 2026101704:
            raise ValueError("Qualification runs require master 2026101704 and indices 1,1001,2001 in a new subset directory")
    elif mode == "production":
        if subset or master != 2026101703:
            raise ValueError("Production runs require master 2026101703 and the full manifest")
    elif mode == "clean_current":
        if subset or master != 2026101901:
            raise ValueError("Clean-current look one requires master 2026101901 and the full manifest")
        if design.get("profile_level") != "0.95" or \
                design.get("planned_attempts") != "3000" or \
                design.get("calibration_claim", "").lower() != "true" or \
                design.get("clean_current_seed_stream") != "2026101901" or \
                design.get("excluded_historical_streams") != "2026101702:6,2026101703:3000,2026101704:3000,2026101705:10000" or \
                design.get("stage_two_manifest_sha256") != "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98" or \
                design.get("stage_two_status") != "clean_current_manifest_frozen_adapter_reconciliation_outstanding_not_authorized":
            raise ValueError("Clean-current receipt lacks the frozen 95% first-look contract")
    elif mode == "clean_current_stage_two":
        if subset or master != 2026101902:
            raise ValueError("Clean-current look two requires master 2026101902 and a full batch")
        if design.get("profile_level") != "0.95" or \
                design.get("planned_attempts") != "3000" or \
                design.get("calibration_claim", "").lower() != "true" or \
                design.get("clean_current_seed_stream") != "2026101902" or \
                design.get("stage_two_manifest_sha256") != "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98" or \
                design.get("stage_two_batch_id") not in {"1", "2", "3"}:
            raise ValueError("Clean-current look-two receipt lacks the frozen 95% batch contract")
    else:
        raise ValueError("Unknown prepared design mode")
    if len(manifest) != 3000 or [int(row["index"]) for row in manifest] != list(range(1, 3001)):
        raise ValueError("Expected the immutable 3,000-row prepared manifest")
    if any(row.get("design_mode") != mode or int(row.get("master_seed", "0")) != master
           for row in manifest):
        raise ValueError("Manifest mode/master seed differs from design receipt")
    return True


def registered_artifact(registry: Path, suffix: str) -> Path:
    with registry.open(newline="", encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    if suffix == "manifest.csv":
        matches = [Path(row["path"]) for row in rows
                   if Path(row.get("path", "")).name == suffix]
    else:
        matches = [Path(row["path"]) for row in rows
                   if row.get("path", "").endswith(suffix)]
    if len(matches) != 1:
        raise ValueError(f"Source registry must contain exactly one {suffix} artifact")
    return matches[0].resolve(strict=True)


def require_registered_script(registry: Path, script: Path, suffix: str) -> None:
    registered = registered_artifact(registry, suffix)
    if script.resolve(strict=True) != registered:
        raise ValueError(f"Executing {suffix} is not the source-registry-pinned script")


def validate_clean_current_manifest(manifest, frozen_path: Path,
                                    expected_sha="5e4c567c21cdb3bdabc61119d453563751447fe2fc011faa09f8b795bbdf80cb") -> bool:
    frozen_path = Path(frozen_path).resolve(strict=True)
    if sha256_file(frozen_path) != expected_sha:
        raise ValueError("Frozen clean-current look-one manifest has the wrong SHA-256")
    with frozen_path.open(newline="", encoding="utf-8") as stream:
        frozen = list(csv.DictReader(stream))
    if manifest != frozen:
        raise ValueError("Clean-current manifest rows differ from the frozen look-one seed design")
    return True


def validate_clean_current_stage_two_manifest(manifest, frozen_path: Path,
                                              registry: Path, batch_id: int) -> bool:
    import importlib.util
    module_path = registered_artifact(registry,
        "native-calibration-stage-two/clean_current_stage_two.py")
    spec = importlib.util.spec_from_file_location("clean_current_stage_two", module_path)
    if spec is None or spec.loader is None:
        raise ValueError("Could not load the registered clean-current stage-two validator")
    adapter = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(adapter)
    adapter.validate_batch(manifest, frozen_path=frozen_path, batch_id=batch_id)
    return True


def require_mode_registry(source: Path, mode: str) -> None:
    common = [
        "manifest.csv", "design-receipt.txt", "native-calibration/prepare-095.R",
        "native-calibration/worker-095.R", "native-calibration/run-095.py",
        "native-calibration/summarize-095.R", "native-calibration/integrity.py",
        "native-calibration/generator.R", "native-calibration/staged-decision.R",
        "native-calibration-stage-two/stage-two-rules.R", "R/drmTMB.R",
        "R/methods.R", "R/profile.R", "src/drmTMB.cpp",
        "tests/testthat/helper-binomial-sd-regression.R",
        "drmTMB.rdb", "drmTMB.rdx", "drmTMB/DESCRIPTION", "drmTMB/NAMESPACE",
        "drmTMB/Meta/package.rds", "/libs/drmTMB.so", "/bin/R",
    ]
    if mode in {"clean_current", "clean_current_stage_two"}:
        common += [
            "native-calibration/clean-manifests.R",
            "/clean-current-seed-design-v1/look1.csv",
            "/clean-current-seed-design-v1/look2.csv",
            "/clean-current-seed-design-v1/timing.csv",
            "/clean-current-seed-design-v1/seed-design.txt",
        ]
        if mode == "clean_current_stage_two":
            common.append("native-calibration-stage-two/clean_current_stage_two.py")
    else:
        common += ["native-calibration/stage-two-seeds.R", "stage-two-manifest.csv"]
    registry = source / "source-hashes.csv"
    for suffix in common:
        artifact = registered_artifact(registry, suffix)
        expected_sha = {
            "/clean-current-seed-design-v1/look1.csv": "5e4c567c21cdb3bdabc61119d453563751447fe2fc011faa09f8b795bbdf80cb",
            "/clean-current-seed-design-v1/look2.csv": "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98",
            "/clean-current-seed-design-v1/timing.csv": "47461e810a80c8aa7f6618497f9fe963c586f4db63f83ade4efdefccc767c1c7",
            "/clean-current-seed-design-v1/seed-design.txt": "122477952ad03e6945bf6e6a29706933e75eade84e6dcf1aa791129352c17d35",
        }.get(suffix)
        if expected_sha is not None and sha256_file(artifact) != expected_sha:
            raise ValueError(f"Frozen clean-current artifact has wrong SHA-256: {suffix}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("directory", type=Path)
    p.add_argument("--workers", type=int, default=16)
    p.add_argument("--case-timeout", type=float, default=120)
    p.add_argument("--campaign-timeout", type=float, default=3600)
    p.add_argument("--indices", help="bounded comma-separated manifest index subset")
    p.add_argument("--subset-output", type=Path, help="new separate output directory required with --indices")
    p.add_argument("--registry-sha256", required=True,
                   help="externally recorded SHA-256 of source-hashes.csv")
    args = p.parse_args()
    source = args.directory.resolve(strict=True)
    if bool(args.indices) != bool(args.subset_output):
        raise SystemExit("--indices and --subset-output must be used together")
    design = dict(line.strip().split("=", 1) for line in (source / "design-receipt.txt").read_text().splitlines() if "=" in line)
    mode = design.get("design_mode", "production")
    expected_count = 45 if mode == "timing_only" else 3000
    available = range(1, expected_count + 1)
    indices = parse_indices(args.indices, available)
    if mode == "timing_only" and (args.indices or args.subset_output):
        raise SystemExit("Timing runs require the full 45-row manifest; subsets are forbidden")
    # Validate the immutable source before creating any output. A rejected
    # design must not leave a directory that blocks a corrected retry.
    verify(source)
    require_registered_script(source / "source-hashes.csv", Path(__file__),
                              "native-calibration/run-095.py")
    registry_sha = sha256_file(source / "source-hashes.csv")
    if args.registry_sha256.lower() != registry_sha:
        raise SystemExit("External source-hashes.csv digest does not match prepared registry")
    with (source / "manifest.csv").open(newline="", encoding="utf-8") as stream:
        manifest = list(csv.DictReader(stream))
    require_mode_registry(source, mode)
    worker = Path(__file__).with_name("worker-095.R").resolve(strict=True)
    require_registered_script(source / "source-hashes.csv", worker,
                              "native-calibration/worker-095.R")
    if mode == "clean_current":
        frozen_look1 = registered_artifact(
            source / "source-hashes.csv", "/clean-current-seed-design-v1/look1.csv")
        validate_clean_current_manifest(manifest, frozen_look1)
    elif mode == "clean_current_stage_two":
        frozen_look2 = registered_artifact(
            source / "source-hashes.csv", "/clean-current-seed-design-v1/look2.csv")
        validate_clean_current_stage_two_manifest(
            manifest, frozen_look2, source / "source-hashes.csv",
            int(design["stage_two_batch_id"]))
    calibration_claim = validate_design(manifest, design, indices, bool(args.indices))

    rscript = os.environ.get("RSCRIPT", "Rscript")
    lib = os.environ.get("DRMTMB_SD_TEST_LIBRARY")
    if not lib:
        raise SystemExit("Set DRMTMB_SD_TEST_LIBRARY")
    if not worker.is_file():
        raise SystemExit(f"Worker script does not exist: {worker}")

    out = make_subset(source, args.subset_output.resolve(), indices) if args.indices else source
    if args.indices:
        verify(out)
        if sha256_file(out / "source-hashes.csv") != registry_sha:
            raise SystemExit("Subset source registry changed while it was copied")
        if sha256_file(out / "manifest.csv") != sha256_file(source / "manifest.csv"):
            raise SystemExit("Subset manifest changed while it was copied")
    if args.indices:
        subset_receipt = json.loads((out / "subset-receipt.json").read_text())
        subset_receipt.update(registry_sha256=registry_sha, design_mode=mode,
                              master_seed=int(design["master_seed"]))
        atomic_json(out / "subset-receipt.json", subset_receipt)
    command = lambda i: [rscript, str(worker), str(out), str(i)]
    states = supervise(indices, command, out, args.workers, args.case_timeout,
                       args.campaign_timeout, {"DRMTMB_SD_TEST_LIBRARY": lib,
                           "DRMTMB_SD_REGISTRY_SHA256": registry_sha},
                       registry_sha256=registry_sha, design_mode=mode,
                       calibration_claim=calibration_claim)
    counts = {}
    for state in states.values(): counts[state["status"]] = counts.get(state["status"], 0) + 1
    print(json.dumps({"planned_subset": len(indices), "attempted": sum(s["status"] not in {"not_started","launch_error"} for s in states.values()),
                      "launch_errors": sum(s["status"] == "launch_error" for s in states.values()),
                      "statuses": counts}, sort_keys=True))
    receipt = json.loads((out / "supervisor-receipt.json").read_text())
    if receipt["interrupted"] or not receipt["subset_complete"] or (mode in {"production", "clean_current", "timing_only"} and not receipt["campaign_complete"]):
        return 2
    return 0


if __name__ == "__main__": sys.exit(main())
