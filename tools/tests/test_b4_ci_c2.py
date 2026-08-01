"""Regression contract for the approved B4-CI C2 integration."""

import subprocess
import sys
import unittest
from contextlib import contextmanager
from pathlib import Path

sys.path.insert(0, "tools")
import integrate_b4_ci_c2 as c2


class B4CIC2Test(unittest.TestCase):
    def test_source_bound_c2_closure(self):
        subprocess.run([sys.executable, "tools/integrate_b4_ci_c2.py", "--check"], check=True)

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
        with self.assertRaises(SystemExit):
            c2.check_current()

    def test_rejects_unapproved_ids_and_protected_row_drift(self):
        original = c2.CELL_IDS[:]
        c2.CELL_IDS.append("mc-0182")
        try:
            with self.assertRaises(SystemExit):
                c2.selected_source()
        finally:
            c2.CELL_IDS[:] = original
        with self.replace_once(c2.LEDGER / "cells.tsv", "mc-0102\t102", "mc-0102\tBROKEN"):
            self.assert_rejected()
        with self.replace_once(c2.LEDGER / "cells.tsv", "mc-0182\t182", "mc-0182\tBROKEN"):
            self.assert_rejected()

    def test_rejects_direct_trace_evidence_transition_claim_and_blob_drift(self):
        direct = next(Path(row["path"]) for row in c2.local_rows(c2.MANIFEST)
                      if row["role"] == "direct_trace")
        with self.replace_once(direct, "mc-0297", "mc-9999"):
            self.assert_rejected()
        with self.replace_once(c2.LEDGER / "cells.tsv", "interval_feasible only", "coverage-ready for every cell"):
            self.assert_rejected()
        evidence = c2.LEDGER / "evidence.tsv"
        original = evidence.read_text()
        evidence.write_text("".join(line for line in original.splitlines(keepends=True)
                                  if not line.startswith("ev-mc-0297-")))
        try:
            self.assert_rejected()
        finally:
            evidence.write_text(original)
        transition = c2.LEDGER / "transitions.tsv"
        original = transition.read_text()
        transition.write_text("".join(line for line in original.splitlines(keepends=True)
                                    if "\tmc-0297\t" not in line))
        try:
            self.assert_rejected()
        finally:
            transition.write_text(original)


if __name__ == "__main__":
    unittest.main()
