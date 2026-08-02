"""Regression contract for the approved B4-CI C3 integration."""

import subprocess
import sys
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

sys.path.insert(0, "tools")
import integrate_b4_ci_c3 as c3


class B4CIC3Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = c3.selected_source()

    def test_source_bound_c3_closure(self):
        subprocess.run([sys.executable, "tools/integrate_b4_ci_c3.py", "--check-with-later-cohorts"], check=True)
        _, _, _, closure = self.source
        self.assertEqual(len(closure), 108)
        self.assertEqual({row["role"] for row in closure}, {"receipt", "trace", "interval"})

    @contextmanager
    def replace_once(self, path, old, new):
        path = Path(path)
        original = path.read_bytes()
        self.assertIn(old.encode(), original)
        path.write_bytes(original.replace(old.encode(), new.encode(), 1))
        try:
            yield
        finally:
            path.write_bytes(original)

    def assert_rejected(self):
        with mock.patch.object(c3, "selected_source", return_value=self.source):
            with self.assertRaises(SystemExit):
                c3.check_current()

    def test_rejects_unapproved_and_protected_row_drift(self):
        original = c3.CELL_IDS[:]
        c3.CELL_IDS.append("mc-0182")
        try:
            with self.assertRaises(SystemExit):
                c3.selected_source()
        finally:
            c3.CELL_IDS[:] = original
        for cell_id in ("mc-0102", "mc-0182", "as-0001", "mc-0570"):
            with self.replace_once(c3.LEDGER / "cells.tsv", f"{cell_id}\t", f"{cell_id}-BROKEN\t"):
                self.assert_rejected()

    def test_rejects_artifact_claim_evidence_and_transition_drift(self):
        receipt = next(Path(row["path"]) for row in c3.local_rows(c3.MANIFEST)
                       if row["role"] == "receipt" and row["cell_id"] == "mc-0199")
        with self.replace_once(receipt, "mc-0199", "mc-9999"):
            self.assert_rejected()
        with self.replace_once(
            c3.LEDGER / "cells.tsv",
            "interval_feasible only for the named cell x direct q2 structured mu1/mu2 SD target",
            "coverage-ready for every cell",
        ):
            self.assert_rejected()
        evidence = c3.LEDGER / "evidence.tsv"
        original = evidence.read_text()
        evidence.write_text("".join(line for line in original.splitlines(keepends=True)
                                    if not line.startswith("ev-mc-0199-q2-production-profile-low")))
        try:
            self.assert_rejected()
        finally:
            evidence.write_text(original)
        transition = c3.LEDGER / "transitions.tsv"
        original = transition.read_text()
        transition.write_text("".join(line for line in original.splitlines(keepends=True)
                                      if "\tmc-0199\t" not in line))
        try:
            self.assert_rejected()
        finally:
            transition.write_text(original)


if __name__ == "__main__":
    unittest.main()
