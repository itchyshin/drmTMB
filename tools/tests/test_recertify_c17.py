"""Tests for tools/recertify-c17.py (issue #1591: it refused on every branch)."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import shutil
import unittest
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "recertify_c17", ROOT / "tools/recertify-c17.py"
)
assert SPEC and SPEC.loader
rc = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(rc)


class RecertifyDryRunTest(unittest.TestCase):
    def _run(self, runner_ok: bool = True) -> tuple[int, str]:
        def fake_run(*_a, **_k):
            # The runner writes a fresh folder at the hardcoded path; the
            # committed receipt must already be out of the way.
            self.assertFalse(rc.RUNNER_OUT.exists())
            if not runner_ok:
                raise RuntimeError("runner failed")
            rc.RUNNER_OUT.mkdir()
            # Reproduce the manifest's own receipt exactly so the check passes.
            prior = ROOT / rc.read_tsv(rc.MANIFEST)[0]["summary_path"]
            shutil.copy(prior, rc.RUNNER_OUT / "summary.tsv")

        out, err = io.StringIO(), io.StringIO()
        with mock.patch.object(rc.subprocess, "run", fake_run), \
                mock.patch.object(rc.sys, "argv",
                                  ["recertify-c17.py", "--label", "t", "--dry-run"]), \
                contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            try:
                code = rc.main()
            except RuntimeError:
                code = -1
        return code, out.getvalue() + err.getvalue()

    def _snapshot(self) -> dict[str, bytes]:
        return {p.name: p.read_bytes() for p in sorted(rc.RUNNER_OUT.iterdir())}

    def test_dry_run_does_not_refuse_and_restores_receipt(self):
        before = self._snapshot()
        code, text = self._run()
        self.assertEqual(code, 0, text)
        self.assertIn("new receipt:", text)
        self.assertEqual(self._snapshot(), before)
        self.assertFalse(
            rc.RUNNER_OUT.with_name(rc.RUNNER_OUT.name + ".pre-recertify").exists())

    def test_runner_failure_restores_receipt(self):
        before = self._snapshot()
        code, _ = self._run(runner_ok=False)
        self.assertEqual(code, -1)
        self.assertEqual(self._snapshot(), before)


if __name__ == "__main__":
    unittest.main()
