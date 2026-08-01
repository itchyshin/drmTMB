"""Regression contract for the approved B4-CI C1 integration."""

import subprocess
import sys
import unittest
from contextlib import contextmanager
from pathlib import Path

sys.path.insert(0, "tools")
import integrate_b4_ci_c1 as c1


class B4CIC1Test(unittest.TestCase):
    def test_source_bound_c1_closure(self):
        subprocess.run([sys.executable, "tools/integrate_b4_ci_c1.py", "--check-current"], check=True)

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

    def assert_current_rejects(self):
        with self.assertRaises(SystemExit):
            c1.check_current()

    def test_rejects_unapproved_id(self):
        with self.assertRaises(SystemExit):
            original = c1.CELL_IDS[:]
            c1.CELL_IDS.append("mc-0182")
            try:
                c1.selected_source()
            finally:
                c1.CELL_IDS[:] = original

    def test_rejects_b3_and_exclusion_breaches(self):
        with self.replace_once(c1.LEDGER / "cells.tsv", "mc-0102\t102", "mc-0102\tBROKEN"):
            self.assert_current_rejects()
        with self.replace_once(c1.LEDGER / "cells.tsv", "mc-0182\t182", "mc-0182\tBROKEN"):
            self.assert_current_rejects()

    def test_rejects_artifact_target_scale_and_wording_drift(self):
        receipt = next(Path(row["path"]) for row in c1.local_rows(c1.MANIFEST)
                       if row["role"] == "receipt" and row["cell_id"] == "mc-0005")
        with self.replace_once(receipt, "0.55 on beta latent/link-scale mu SD", "BROKEN SCALE"):
            self.assert_current_rejects()
        interval = next(Path(row["path"]) for row in c1.local_rows(c1.MANIFEST) if row["role"] == "interval")
        with self.replace_once(interval, "mc-0005::", "mc-9999::"):
            self.assert_current_rejects()
        with self.replace_once(c1.LEDGER / "cells.tsv", "interval_feasible only for the named cell", "coverage-ready for every cell"):
            self.assert_current_rejects()
        with self.replace_once(c1.LEDGER / "evidence.tsv", "computational interval feasibility only", "coverage and public guidance established"):
            self.assert_current_rejects()

    def test_rejects_evidence_transition_cardinality_and_blob_mismatch(self):
        evidence = c1.LEDGER / "evidence.tsv"
        original = evidence.read_text()
        lines = original.splitlines(keepends=True)
        evidence.write_text("".join(line for line in lines if not line.startswith("ev-mc-0005-")))
        try:
            self.assert_current_rejects()
        finally:
            evidence.write_text(original)
        transition = c1.LEDGER / "transitions.tsv"
        original = transition.read_text()
        lines = original.splitlines(keepends=True)
        transition.write_text("".join(line for line in lines if "\tmc-0005\t" not in line))
        try:
            self.assert_current_rejects()
        finally:
            transition.write_text(original)
        artifact = next(Path(row["path"]) for row in c1.local_rows(c1.MANIFEST))
        with self.replace_once(artifact, "mc-0005", "mc-9999"):
            self.assert_current_rejects()


if __name__ == "__main__":
    unittest.main()

