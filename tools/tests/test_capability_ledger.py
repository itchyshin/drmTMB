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

    def test_denominators_and_truthful_missing_response_state(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        missing = [row for row in self.cells if row["axis"] == "missing_response"]
        self.assertEqual(len(model), 668)
        self.assertEqual(len(missing), 18)
        self.assertEqual(
            {
                row["family_route"]
                for row in missing
                if row["test_gate"] == "G3" and row["work_status"] == "verified"
            },
            ledger.ADMITTED,
        )
        self.assertEqual(
            {row["family_route"] for row in missing if row["test_gate"] == "G0"},
            {route for _, route, _, _, _ in ledger.ROUTES} - ledger.ADMITTED,
        )
        by_route = {row["family_route"]: row for row in missing}
        self.assertEqual(by_route["zi_poisson"]["test_gate"], "G3")
        self.assertEqual(by_route["zi_nbinom2"]["test_gate"], "G3")
        self.assertEqual(by_route["hurdle_nbinom2"]["test_gate"], "G3")
        self.assertEqual(
            sum(row["work_status"] == "verified" for row in missing),
            len(ledger.ADMITTED),
        )

    def test_generation_is_deterministic(self):
        first = ledger.outputs(self.cells, self.evidence)
        second = ledger.outputs(self.cells, self.evidence)
        self.assertEqual(first, second)

    def test_mixture_routes_have_independent_recovery_evidence(self):
        evidence_by_id = {row["evidence_id"]: row for row in self.evidence}
        cells_by_route = {
            row["family_route"]: row
            for row in self.cells if row["axis"] == "missing_response"
        }
        for route in ("zi_poisson", "zi_nbinom2", "hurdle_nbinom2"):
            cell = cells_by_route[route]
            primary = evidence_by_id[cell["primary_evidence_id"]]
            self.assertIn(route.replace("_", "-"), primary["evidence_id"])
            self.assertEqual(primary["cell_id"], cell["cell_id"])
            self.assertEqual(primary["evidence_class"], "recovery_test")

    def test_evidence_free_g3_transition_is_rejected(self):
        cells = copy.deepcopy(self.cells)
        transitions = copy.deepcopy(self.transitions)
        route = next(
            row for row in cells
            if row["axis"] == "missing_response" and row["family_route"] == "truncated_nbinom2"
        )
        route["capability_status"] = "implemented"
        route["work_status"] = "verified"
        route["test_gate"] = "G3"
        transitions.append({
            "transition_id": "tr-mr-truncated-nbinom2-invalid-g3-test",
            "cell_id": route["cell_id"],
            "from_work_status": "backlog",
            "to_work_status": "verified",
            "evidence_ids": route["primary_evidence_id"],
            "reason": "Invalid evidence-free promotion",
            "actor": "unit test",
            "commit_sha": "test",
            "date": "2026-07-11",
        })
        with self.assertRaisesRegex(SystemExit, "G2.*(requires|must cite)|G3.*requires"):
            ledger.validate(cells, self.evidence, transitions)

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
