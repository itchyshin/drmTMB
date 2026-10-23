"""Tests for tools/recertify-c17.py (issue #1591: it refused on every branch)."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import tempfile
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
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.runner_out = self.root / "receipt"
        self.runner_out.mkdir()
        (self.runner_out / "committed.txt").write_text("committed", encoding="utf-8")
        self.manifest = self.root / "manifest.tsv"
        self.summary = self.root / "prior.tsv"
        self.summary.write_text(
            "cell_id\tmean_tau_relative_error\n"
            "mc-0568\t0.1\nmc-0569\t0.2\nmc-0576\t0.3\n",
            encoding="utf-8",
        )
        self.manifest.write_text(
            "summary_path\nprior.tsv\n", encoding="utf-8"
        )
        self.patches = mock.patch.multiple(
            rc, ROOT=self.root, RUNNER_OUT=self.runner_out, MANIFEST=self.manifest
        )
        self.patches.start()
        self.addCleanup(self.patches.stop)

    def _run(self, runner_ok: bool = True, dry_run: bool = True,
             drift: bool = False) -> tuple[int, str]:
        def fake_run(*_a, **_k):
            # The runner writes a fresh folder at the hardcoded path; the
            # committed receipt must already be out of the way.
            self.assertFalse(rc.RUNNER_OUT.exists())
            if not runner_ok:
                rc.RUNNER_OUT.mkdir()
                (rc.RUNNER_OUT / "partial.txt").write_text("partial", encoding="utf-8")
                raise RuntimeError("runner failed")
            rc.RUNNER_OUT.mkdir()
            first = "0.4" if drift else "0.1"
            (rc.RUNNER_OUT / "summary.tsv").write_text(
                "cell_id\tmean_tau_relative_error\n"
                f"mc-0568\t{first}\nmc-0569\t0.2\nmc-0576\t0.3\n",
                encoding="utf-8",
            )

        out, err = io.StringIO(), io.StringIO()
        with mock.patch.object(rc.subprocess, "run", fake_run), \
                mock.patch.object(rc.sys, "argv", [
                    "recertify-c17.py", "--label", "t",
                    *( ["--dry-run"] if dry_run else []),
                ]), \
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

    def test_invalid_labels_refuse_before_moving_receipt_or_running_runner(self):
        before_receipt = self._snapshot()
        before_manifest = self.manifest.read_bytes()

        def fake_run(*_a, **_k):
            rc.RUNNER_OUT.mkdir()
            (rc.RUNNER_OUT / "summary.tsv").write_text(
                "cell_id\tmean_tau_relative_error\n"
                "mc-0568\t0.1\nmc-0569\t0.2\nmc-0576\t0.3\n",
                encoding="utf-8",
            )

        for label in ("../escape", "bad label"):
            with self.subTest(label=label):
                out, err = io.StringIO(), io.StringIO()
                with mock.patch.object(rc.subprocess, "run", side_effect=fake_run) as runner, \
                        mock.patch.object(rc.sys, "argv", [
                            "recertify-c17.py", "--label", label,
                        ]), \
                        contextlib.redirect_stdout(out), \
                        contextlib.redirect_stderr(err):
                    code = rc.main()

                self.assertEqual(code, 2, out.getvalue() + err.getvalue())
                runner.assert_not_called()
                self.assertEqual(self._snapshot(), before_receipt)
                self.assertEqual(self.manifest.read_bytes(), before_manifest)
                self.assertFalse(rc.RUNNER_OUT.with_name(
                    rc.RUNNER_OUT.name + ".pre-recertify").exists())

    def test_runner_failure_restores_receipt(self):
        before = self._snapshot()
        code, _ = self._run(runner_ok=False)
        self.assertEqual(code, -1)
        self.assertEqual(self._snapshot(), before)
        failed = rc.RUNNER_OUT.with_name(rc.RUNNER_OUT.name + ".failed-t")
        self.assertEqual((failed / "partial.txt").read_text(encoding="utf-8"), "partial")

    def test_destination_collision_preserves_completed_run(self):
        destination = rc.RUNNER_OUT.parent / (
            f"{rc._dt.date.today().isoformat()}-t-c17c2-c14-final-source-compatibility"
        )
        destination.mkdir()
        (destination / "existing.txt").write_text("existing", encoding="utf-8")
        before = self._snapshot()

        code, _ = self._run(dry_run=False)

        self.assertEqual(code, 2)
        self.assertEqual(self._snapshot(), before)
        self.assertEqual((destination / "existing.txt").read_text(encoding="utf-8"), "existing")
        collision = rc.RUNNER_OUT.with_name(rc.RUNNER_OUT.name + ".collision-t")
        self.assertEqual((collision / "summary.tsv").read_text(encoding="utf-8").splitlines()[0],
                         "cell_id\tmean_tau_relative_error")

    def test_rejected_receipt_collision_preserves_both_runs_as_siblings(self):
        rejected = rc.RUNNER_OUT.with_name(rc.RUNNER_OUT.name + ".rejected-t")
        rejected.mkdir()
        (rejected / "existing.txt").write_text("existing", encoding="utf-8")

        code, _ = self._run(drift=True)

        self.assertEqual(code, 1)
        self.assertEqual((rejected / "existing.txt").read_text(encoding="utf-8"), "existing")
        second = rc.RUNNER_OUT.with_name(rc.RUNNER_OUT.name + ".rejected-t-2")
        self.assertEqual((second / "summary.tsv").read_text(encoding="utf-8").splitlines()[1],
                         "mc-0568\t0.4")


if __name__ == "__main__":
    unittest.main()
