"""Tests for the deterministic capability-ledger generator."""

from __future__ import annotations

import importlib.util
import copy
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "capability_ledger", ROOT / "tools/capability_ledger.py"
)
assert SPEC and SPEC.loader
ledger = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ledger)


class CapabilityLedgerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cells, cls.evidence, cls.transitions = ledger.load_sources()

    def test_denominators_and_truthful_missing_response_baseline(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        missing = [row for row in self.cells if row["axis"] == "missing_response"]
        self.assertEqual(len(model), 668)
        self.assertEqual(len(missing), 18)
        self.assertEqual(
            {row["family_route"] for row in missing if row["test_gate"] == "G1"},
            ledger.ADMITTED,
        )
        self.assertEqual(
            {row["family_route"] for row in missing if row["test_gate"] == "G0"},
            {route for _, route, _, _, _ in ledger.ROUTES} - ledger.ADMITTED,
        )
        by_route = {row["family_route"]: row for row in missing}
        self.assertEqual(by_route["zi_poisson"]["test_gate"], "G0")
        self.assertEqual(by_route["zi_nbinom2"]["test_gate"], "G0")
        self.assertFalse(any(row["work_status"] == "verified" for row in missing))

    def test_generation_is_deterministic(self):
        first = ledger.outputs(self.cells, self.evidence)
        second = ledger.outputs(self.cells, self.evidence)
        self.assertEqual(first, second)

    def test_future_g3_transition_does_not_require_generator_changes(self):
        cells = copy.deepcopy(self.cells)
        transitions = copy.deepcopy(self.transitions)
        student = next(
            row for row in cells
            if row["axis"] == "missing_response" and row["family_route"] == "student"
        )
        student["capability_status"] = "implemented"
        student["work_status"] = "verified"
        student["test_gate"] = "G3"
        transition = next(
            row for row in transitions if row["cell_id"] == student["cell_id"]
        )
        transition["to_work_status"] = "verified"
        ledger.validate(cells, self.evidence, transitions)
        generated = ledger.outputs(cells, self.evidence)
        markdown = generated[
            ledger.ROOT / "docs/dev-log/dashboard/capability-surface.md"
        ].decode("utf-8")
        html = generated[
            ledger.ROOT / "docs/dev-log/dashboard/capability-surface.html"
        ].decode("utf-8")
        self.assertIn("1 verified (G3+)", markdown)
        self.assertIn("G3 ✓ recovery verified", markdown)
        self.assertIn("G3 ✓ recovery verified", html)

    def test_check_detects_one_byte_stale_output(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "generated.txt"
            expected = b"expected\n"
            path.write_bytes(expected)
            ledger.check_outputs({path: expected})
            path.write_bytes(b"Expected\n")
            with self.assertRaisesRegex(SystemExit, "stale"):
                ledger.check_outputs({path: expected})

    def test_check_detects_missing_output(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "missing.txt"
            with self.assertRaisesRegex(SystemExit, "missing"):
                ledger.check_outputs({path: b"expected\n"})


if __name__ == "__main__":
    unittest.main()
