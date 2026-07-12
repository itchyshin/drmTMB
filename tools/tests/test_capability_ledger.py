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
        self.assertEqual(by_route["zi_poisson"]["test_gate"], "G0")
        self.assertEqual(by_route["zi_nbinom2"]["test_gate"], "G0")
        self.assertEqual(
            sum(row["work_status"] == "verified" for row in missing),
            len(ledger.ADMITTED),
        )

    def test_generation_is_deterministic(self):
        first = ledger.outputs(self.cells, self.evidence)
        second = ledger.outputs(self.cells, self.evidence)
        self.assertEqual(first, second)

    def test_future_g3_transition_does_not_require_generator_changes(self):
        cells = copy.deepcopy(self.cells)
        evidence = copy.deepcopy(self.evidence)
        transitions = copy.deepcopy(self.transitions)
        route = next(
            row for row in cells
            if row["axis"] == "missing_response" and row["family_route"] == "tweedie"
        )
        route["capability_status"] = "implemented"
        route["work_status"] = "verified"
        route["test_gate"] = "G3"
        route["primary_evidence_id"] = "ev-mr-tweedie-g3-test"
        evidence.extend([
            {
                "evidence_id": "ev-mr-tweedie-g2-test",
                "cell_id": route["cell_id"],
                "evidence_class": "g2_contract_test",
                "path_or_url": "tools/tests/test_capability_ledger.py",
                "commit_sha": "test",
                "run_id": "",
                "command": "unit test",
                "result": "G2_pass",
                "replicates": "",
                "reviewed_by": "unit test",
                "review_date": "2026-07-11",
                "claim_boundary": "Synthetic evidence for generator test.",
            },
            {
                "evidence_id": "ev-mr-tweedie-g3-test",
                "cell_id": route["cell_id"],
                "evidence_class": "recovery_test",
                "path_or_url": "tools/tests/test_capability_ledger.py",
                "commit_sha": "test",
                "run_id": "",
                "command": "unit test",
                "result": "G3_pass",
                "replicates": "1 synthetic DGP",
                "reviewed_by": "unit test",
                "review_date": "2026-07-11",
                "claim_boundary": "Synthetic evidence for generator test.",
            },
        ])
        transitions.append({
            "transition_id": "tr-mr-tweedie-g3-test",
            "cell_id": route["cell_id"],
            "from_work_status": "backlog",
            "to_work_status": "verified",
            "evidence_ids": "ev-mr-tweedie-g2-test;ev-mr-tweedie-g3-test",
            "reason": "Synthetic future G3 transition",
            "actor": "unit test",
            "commit_sha": "test",
            "date": "2026-07-11",
        })
        ledger.validate(cells, evidence, transitions)
        generated = ledger.outputs(cells, evidence)
        markdown = generated[
            ledger.ROOT / "docs/dev-log/dashboard/capability-surface.md"
        ].decode("utf-8")
        html = generated[
            ledger.ROOT / "docs/dev-log/dashboard/capability-surface.html"
        ].decode("utf-8")
        current_verified = sum(
            row["axis"] == "missing_response"
            and int(row["test_gate"][1:]) >= 3
            for row in self.cells
        )
        self.assertIn(f"{current_verified + 1} verified (G3+)", markdown)
        self.assertIn("G3 ✓ recovery verified", markdown)
        self.assertIn("G3 ✓ recovery verified", html)

    def test_evidence_free_g3_transition_is_rejected(self):
        cells = copy.deepcopy(self.cells)
        transitions = copy.deepcopy(self.transitions)
        route = next(
            row for row in cells
            if row["axis"] == "missing_response" and row["family_route"] == "tweedie"
        )
        route["capability_status"] = "implemented"
        route["work_status"] = "verified"
        route["test_gate"] = "G3"
        transitions.append({
            "transition_id": "tr-mr-tweedie-invalid-g3-test",
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
