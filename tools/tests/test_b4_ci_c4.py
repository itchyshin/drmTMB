"""Regression contract for the approved B4-CI C4 integration."""

import subprocess
import sys
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

sys.path.insert(0, "tools")
import integrate_b4_ci_c4 as c4


class B4CIC4Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = c4.selected_source()

    def test_source_bound_c4_closure(self):
        subprocess.run([sys.executable, "tools/integrate_b4_ci_c4.py", "--check"], check=True)
        _, _, _, closure = self.source
        self.assertEqual(len(closure), 69)
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
        with mock.patch.object(c4, "selected_source", return_value=self.source):
            with self.assertRaises(SystemExit):
                c4.check()

    def test_rejects_unapproved_and_protected_row_drift(self):
        original = c4.CELL_IDS[:]
        c4.CELL_IDS.append("mc-0182")
        try:
            with self.assertRaises(SystemExit):
                c4.selected_source()
        finally:
            c4.CELL_IDS[:] = original
        for cell_id in ("mc-0102", "mc-0182", "as-0001", "mc-0570", "mc-0199"):
            with self.replace_once(c4.LEDGER / "cells.tsv", f"{cell_id}\t", f"{cell_id}-BROKEN\t"):
                self.assert_rejected()

    def test_rejects_artifact_claim_evidence_and_transition_drift(self):
        receipt = next(Path(row["path"]) for row in c4.local_rows(c4.MANIFEST)
                       if row["role"] == "receipt" and row["cell_id"] == "mc-0101")
        with self.replace_once(receipt, "mc-0101", "mc-9999"):
            self.assert_rejected()
        with self.replace_once(
            c4.LEDGER / "cells.tsv",
            "interval_feasible only for the named cell x direct q6 provider mu1-intercept SD target",
            "coverage-ready for every cell",
        ):
            self.assert_rejected()
        evidence = c4.LEDGER / "evidence.tsv"
        original = evidence.read_text()
        evidence.write_text("".join(line for line in original.splitlines(keepends=True)
                                    if not line.startswith("ev-mc-0101-q6-provider-profile")))
        try:
            self.assert_rejected()
        finally:
            evidence.write_text(original)
        transition = c4.LEDGER / "transitions.tsv"
        original = transition.read_text()
        transition.write_text("".join(line for line in original.splitlines(keepends=True)
                                      if "\tmc-0101\t" not in line))
        try:
            self.assert_rejected()
        finally:
            transition.write_text(original)


if __name__ == "__main__":
    unittest.main()
