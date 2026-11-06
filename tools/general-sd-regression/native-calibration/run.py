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
              registry_sha256=None, design_mode="test"):
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
        complete_campaign = (indices == list(range(1, 3001)) and not interrupted and complete_subset)
        atomic_json(receipt_path, {"started_at": started_at, "finished_at": time.time(),
            "campaign_timeout_seconds": campaign_timeout, "case_timeout_seconds": case_timeout,
            "workers": workers, "planned_indices": indices, "interrupted": interrupted,
            "design_mode": design_mode, "registry_sha256": registry_sha256,
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
    indices = parse_indices(args.indices, range(1, 3001))
    design = dict(line.strip().split("=", 1) for line in (source / "design-receipt.txt").read_text().splitlines() if "=" in line)
    mode = design.get("design_mode", "production")
    master = int(design.get("master_seed", "0"))
    if mode == "qualification":
        if not args.indices or indices != [1, 1001, 2001] or master != 2026101704:
            raise SystemExit("Qualification runs require master 2026101704 and indices 1,1001,2001 in a new subset directory")
    elif mode == "production":
        if args.indices or master != 2026101703:
            raise SystemExit("Production runs require master 2026101703 and the full manifest")
    else:
        raise SystemExit("Unknown prepared design mode")
    out = make_subset(source, args.subset_output.resolve(), indices) if args.indices else source
    verify(out)
    registry_sha = sha256_file(out / "source-hashes.csv")
    if args.registry_sha256.lower() != registry_sha:
        raise SystemExit("External source-hashes.csv digest does not match prepared registry")
    manifest = list(csv.DictReader((out / "manifest.csv").open(newline="", encoding="utf-8")))
    if len(manifest) != 3000 or [int(r["index"]) for r in manifest] != list(range(1, 3001)):
        raise SystemExit("Expected the immutable 3,000-row prepared manifest")
    if any(r.get("design_mode") != mode or int(r.get("master_seed", "0")) != master for r in manifest):
        raise SystemExit("Manifest mode/master seed differs from design receipt")
    if args.indices:
        subset_receipt = json.loads((out / "subset-receipt.json").read_text())
        subset_receipt.update(registry_sha256=registry_sha, design_mode=mode, master_seed=master)
        atomic_json(out / "subset-receipt.json", subset_receipt)
    worker = Path(__file__).with_name("worker.R").resolve()
    rscript = os.environ.get("RSCRIPT", "Rscript"); lib = os.environ.get("DRMTMB_SD_TEST_LIBRARY")
    if not lib: raise SystemExit("Set DRMTMB_SD_TEST_LIBRARY")
    command = lambda i: [rscript, str(worker), str(out), str(i)]
    states = supervise(indices, command, out, args.workers, args.case_timeout,
                       args.campaign_timeout, {"DRMTMB_SD_TEST_LIBRARY": lib,
                           "DRMTMB_SD_REGISTRY_SHA256": registry_sha},
                       registry_sha256=registry_sha, design_mode=mode)
    counts = {}
    for state in states.values(): counts[state["status"]] = counts.get(state["status"], 0) + 1
    print(json.dumps({"planned_subset": len(indices), "attempted": sum(s["status"] not in {"not_started","launch_error"} for s in states.values()),
                      "launch_errors": sum(s["status"] == "launch_error" for s in states.values()),
                      "statuses": counts}, sort_keys=True))
    receipt = json.loads((out / "supervisor-receipt.json").read_text())
    if receipt["interrupted"] or not receipt["subset_complete"] or (mode == "production" and not receipt["campaign_complete"]):
        return 2
    return 0


if __name__ == "__main__": sys.exit(main())
