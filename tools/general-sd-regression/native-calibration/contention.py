#!/usr/bin/env python3
"""Run five qualification repeats concurrently for timing, never calibration."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("prepared", type=Path)
    parser.add_argument("registry_sha256")
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    prepared = args.prepared.resolve(strict=True)
    if hashlib.sha256((prepared / "source-hashes.csv").read_bytes()).hexdigest() != args.registry_sha256:
        raise SystemExit("External registry seal mismatch")
    output = args.output.resolve()
    output.mkdir(exist_ok=False)
    runner = Path(__file__).with_name("run.py").resolve(strict=True)
    active = []
    began = time.monotonic()
    interrupted = None
    states = []

    def interrupted_signal(signum, _frame):
        raise InterruptedError(f"signal {signum}")

    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, interrupted_signal)

    try:
        for repeat in range(1, 6):
            subset = output / f"repeat-{repeat:02d}"
            log = (output / f"repeat-{repeat:02d}.log").open("wb")
            command = [sys.executable, str(runner), str(prepared), "--indices", "1,1001,2001",
                       "--subset-output", str(subset), "--workers", "3", "--case-timeout", "120",
                       "--campaign-timeout", "120", "--registry-sha256", args.registry_sha256]
            try:
                process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                                           start_new_session=True)
            except BaseException:
                log.close()
                raise
            active.append((process, log, subset))
        while any(process.poll() is None for process, _, _ in active):
            if time.monotonic() - began >= 120:
                raise TimeoutError("120-second outer contention cap")
            time.sleep(0.1)
        if time.monotonic() - began >= 120:
            raise TimeoutError("120-second outer contention cap at completion")
    except BaseException as error:
        interrupted = f"{type(error).__name__}: {error}"
    finally:
        for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            signal.signal(sig, signal.SIG_IGN)
        # Each reviewed runner handles SIGTERM by killing and waiting its own
        # worker process groups. Only these five owned supervisors receive it.
        for process, _, _ in active:
            if process.poll() is None:
                process.terminate()
        grace = time.monotonic() + 5
        for process, _, subset in active:
            remaining = max(0.01, grace - time.monotonic())
            try:
                process.wait(timeout=remaining)
            except subprocess.TimeoutExpired:
                # A stuck supervisor must not leave owned worker sessions.
                receipt = subset / "supervisor-receipt.json"
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
        for process, log, subset in active:
            log.close()
            states.append({"supervisor_pid": process.pid, "returncode": process.returncode,
                           "subset": str(subset)})
        receipt = {"purpose": "15-process contention timing; five repeats of the same three seeds",
                   "independent_replicates": False, "registry_sha256": args.registry_sha256,
                   "outer_cap_seconds": 120, "elapsed_seconds": time.monotonic() - began,
                   "interrupted": interrupted, "supervisors": states,
                   "orchestrator_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
        (output / "contention-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return 0 if not interrupted and len(states) == 5 and all(s["returncode"] == 0 for s in states) else 1


if __name__ == "__main__":
    sys.exit(main())
