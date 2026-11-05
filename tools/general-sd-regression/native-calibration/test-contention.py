"""No-fit tests for contention launch, interruption, and the completion cap."""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
with tempfile.TemporaryDirectory(prefix="sd-contention-logic-") as temporary:
    root = Path(temporary)
    shutil.copyfile(HERE / "contention.py", root / "contention.py")
    prepared = root / "prepared"
    prepared.mkdir()
    registry = prepared / "source-hashes.csv"
    registry.write_text("synthetic seal fixture\n")
    seal = hashlib.sha256(registry.read_bytes()).hexdigest()
    fake = root / "run.py"
    fake.write_text("import time\ntime.sleep(0.05)\n")
    command = [sys.executable, str(root / "contention.py"), str(prepared), seal]
    result = subprocess.run(command + [str(root / "positive")], capture_output=True, timeout=10)
    assert result.returncode == 0, result.stderr
    receipt = json.loads((root / "positive/contention-receipt.json").read_text())
    assert len(receipt["supervisors"]) == 5 and not receipt["independent_replicates"]

    fake.write_text("import time\ntime.sleep(30)\n")
    child = subprocess.Popen(command + [str(root / "interrupted")],
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    time.sleep(0.4)
    child.send_signal(signal.SIGTERM)
    _, stderr = child.communicate(timeout=10)
    assert child.returncode == 1, stderr
    receipt = json.loads((root / "interrupted/contention-receipt.json").read_text())
    assert receipt["interrupted"] and len(receipt["supervisors"]) == 5
    for supervisor in receipt["supervisors"]:
        try:
            os.kill(supervisor["supervisor_pid"], 0)
        except ProcessLookupError:
            pass
        else:
            raise AssertionError("Owned supervisor survived cleanup")

    spec = importlib.util.spec_from_file_location("contention_test", root / "contention.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    class FinishedProcess:
        pid = 999999
        returncode = 0
        def poll(self): return 0
        def wait(self, timeout=None): return 0

    ticks = iter([0])
    clock = lambda: next(ticks, 121)
    with patch.object(sys, "argv", [str(root / "contention.py"), str(prepared), seal,
                                   str(root / "late_completion")]), \
         patch.object(module.subprocess, "Popen", return_value=FinishedProcess()), \
         patch.object(module.time, "monotonic", side_effect=clock):
        assert module.main() == 1
    receipt = json.loads((root / "late_completion/contention-receipt.json").read_text())
    assert "TimeoutError" in receipt["interrupted"] and receipt["elapsed_seconds"] == 121
print("CONTENTION_LOGIC_PASS positive5 interrupted5 completion_over_cap_rejected")
