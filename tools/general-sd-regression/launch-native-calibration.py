#!/usr/bin/env python3
"""Keep one approved production supervisor owned across SSH interruptions."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import signal
import subprocess
import sys
import time

parser = argparse.ArgumentParser()
parser.add_argument("job", type=Path)
parser.add_argument("registry_sha256")
args = parser.parse_args()
job = args.job.resolve(strict=True)
source = job / "source/drmTMB"
output = job / "production-prepared"
if hashlib.sha256((output / "source-hashes.csv").read_bytes()).hexdigest() != args.registry_sha256:
    raise SystemExit("Production external seal mismatch")
pidfile = job / "production-supervisor.pid"
if pidfile.exists():
    raise SystemExit("Production launch already exists; no retries")

def interrupt(signum, _frame):
    raise InterruptedError(f"signal {signum}")

for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
    signal.signal(sig, interrupt)
process = None
interruption = None
began = time.time()
with (job / "production-run.log").open("xb") as log:
    try:
        process = subprocess.Popen(
            [sys.executable, str(source / "tools/general-sd-regression/native-calibration/run.py"),
             str(output), "--workers", "16", "--case-timeout", "120", "--campaign-timeout", "3600",
             "--registry-sha256", args.registry_sha256], cwd=source, stdout=log,
            stderr=subprocess.STDOUT, start_new_session=True)
        pidfile.write_text(str(process.pid) + "\n")
        print(f"PRODUCTION_SUPERVISOR_PID={process.pid}", flush=True)
        process.wait()
    except BaseException as error:
        interruption = f"{type(error).__name__}: {error}"
    finally:
        for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            signal.signal(sig, signal.SIG_IGN)
        if process is not None and process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                receipt = output / "supervisor-receipt.json"
                if receipt.exists():
                    for case in json.loads(receipt.read_text()).get("cases", []):
                        pid = case.get("pid")
                        if not isinstance(pid, int) or pid <= 1:
                            continue
                        try:
                            stat = Path(f"/proc/{pid}/stat").read_text().rsplit(") ", 1)[1].split()
                            if int(stat[1]) == process.pid and os.getpgid(pid) == pid:
                                os.killpg(pid, signal.SIGKILL)
                        except (FileNotFoundError, ProcessLookupError):
                            pass
                process.kill()
                process.wait()
        result = {"registry_sha256": args.registry_sha256, "started_at": began,
                  "finished_at": time.time(), "interruption": interruption,
                  "supervisor_pid": process.pid if process else None,
                  "supervisor_returncode": process.returncode if process else None,
                  "launcher_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
        (job / "production-launch-receipt.json").write_text(json.dumps(result, indent=2) + "\n")

if process is None or process.returncode != 0 or interruption:
    raise SystemExit(1)
with (job / "production-summary.log").open("xb") as log:
    result = subprocess.run(
        ["Rscript", str(source / "tools/general-sd-regression/native-calibration/summarize.R"),
         str(output), args.registry_sha256], cwd=source, stdout=log, stderr=subprocess.STDOUT,
        timeout=120)
raise SystemExit(result.returncode)
