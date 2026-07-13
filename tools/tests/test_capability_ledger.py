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

    def test_model_projection_uses_current_primary_evidence_and_claim(self):
        evidence_by_id = {
            row["evidence_id"]: row for row in self.evidence
        }
        source_cells = sorted(
            (row for row in self.cells if row["axis"] == "model_surface"),
            key=lambda row: int(row["source_order"]),
        )
        projected = ledger.model_projection(self.cells, self.evidence)
        self.assertEqual(len(source_cells), len(projected))
        for cell, row in zip(source_cells, projected):
            if cell["primary_evidence_id"]:
                self.assertEqual(
                    row["evidence_source"],
                    evidence_by_id[cell["primary_evidence_id"]]["path_or_url"],
                )
            self.assertEqual(
                row["notes"], cell["claim_boundary"] or cell["notes"]
            )

    def test_family_map_projects_current_ordinary_random_effects(self):
        rows = {
            row["family_route"]: row
            for row in ledger.family_map_rows(self.cells)
        }
        self.assertIn(
            "`mu`: int implemented / slope implemented",
            rows["binomial"]["Random (int/slope)"],
        )
        for route in ("gamma", "lognormal"):
            self.assertIn(
                "`sigma`: int implemented / slope rejected",
                rows[route]["Random (int/slope)"],
            )

    def test_family_map_aggregation_names_absence_and_partial_states(self):
        status = lambda value: {"capability_status": value}
        self.assertEqual(ledger._aggregate_state([]), "absent")
        self.assertEqual(
            ledger._aggregate_state([status("rejected_by_design")]),
            "rejected",
        )
        self.assertEqual(
            ledger._aggregate_state([status("not_implemented")]),
            "not implemented",
        )
        self.assertEqual(
            ledger._aggregate_state([
                status("rejected_by_design"), status("not_implemented")
            ]),
            "mixed (rejected 1; not implemented 1)",
        )
        self.assertEqual(
            ledger._aggregate_state([
                status("implemented"), status("rejected_by_design")
            ]),
            "scope-limited (implemented 1; rejected 1)",
        )

    def test_family_map_reml_is_not_inferred_from_ml(self):
        before = {
            row["family_route"]: row["REML"]
            for row in ledger.family_map_rows(self.cells)
        }
        cells = copy.deepcopy(self.cells)
        ml_binomial = next(
            row for row in cells
            if row["axis"] == "model_surface"
            and row["family_route"] == "binomial"
            and row["estimator"] == "ML"
            and row["effect_type"] == "ordinary_re_intercept"
        )
        ml_binomial["capability_status"] = "rejected_by_design"
        after = {
            row["family_route"]: row["REML"]
            for row in ledger.family_map_rows(cells)
        }
        self.assertEqual(before["binomial"], after["binomial"])
        self.assertIn("`mu`: rejected", before["binomial"])

    def test_arc1a_reml_provider_promotions_are_live_and_discrete(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        for cell_id in ("mc-0287", "mc-0299", "mc-0311"):
            row = by_id[cell_id]
            self.assertEqual(row["capability_status"], "implemented")
            self.assertEqual(row["work_status"], "verified")
            self.assertEqual(
                row["evidence_tier"], "inference_ready_with_caveats"
            )
            self.assertEqual(
                row["primary_evidence_id"], f"ev-{cell_id}-arc1a-coverage"
            )
            self.assertNotIn("M>=", row["claim_boundary"])
            self.assertIn("sigma ~ 1", row["claim_boundary"])
            self.assertIn("not nominal", row["claim_boundary"])

        self.assertIn("M={8,16,32}", by_id["mc-0287"]["claim_boundary"])
        self.assertIn("fixed `M=8` pedigree", by_id["mc-0299"]["claim_boundary"])
        self.assertIn("M={8,16,32}", by_id["mc-0311"]["claim_boundary"])

        gaussian = next(
            row for row in ledger.family_map_rows(self.cells)
            if row["family_route"] == "gaussian"
        )
        self.assertIn(
            "`mu`: scope-limited (implemented 8; rejected 4)",
            gaussian["REML"],
        )

    def test_highest_evidence_names_exact_cell_scope(self):
        binomial = next(
            row for row in ledger.family_map_rows(self.cells)
            if row["family_route"] == "binomial"
        )
        evidence = binomial["Highest evidence (exact scope)"]
        self.assertIn("**inference_ready_with_caveats**", evidence)
        self.assertIn("`mc-0057`", evidence)
        self.assertIn(
            "mu; fixed; provider=none; estimator=ML; dimension=univariate; q=na; variant=base",
            evidence,
        )

    def test_missing_predictor_map_matches_live_runtime_gate(self):
        runtime = ledger.validate_missing_predictor_runtime_map()
        self.assertEqual(
            runtime,
            {"gaussian", "poisson", "binomial", "nbinom2", "beta"},
        )
        rows = {
            row["family_route"]: row
            for row in ledger.family_map_rows(self.cells)
        }
        self.assertIn("broad", rows["gaussian"]["Miss-predictor mi()"])
        self.assertIn("implemented", rows["zi_poisson"]["Miss-predictor mi()"])
        self.assertIn("via `poisson`", rows["zi_poisson"]["Miss-predictor mi()"])
        self.assertIn("rejected", rows["gamma"]["Miss-predictor mi()"])

    def test_generated_surfaces_have_live_wording_and_ledger_date(self):
        generated = ledger.outputs(self.cells, self.evidence)
        markdown = generated[
            ROOT / "docs/dev-log/dashboard/capability-surface.md"
        ].decode("utf-8")
        html = generated[
            ROOT / "docs/dev-log/dashboard/capability-surface.html"
        ].decode("utf-8")
        for output in (markdown, html):
            self.assertNotIn("retained view", output.lower())
            self.assertNotIn("original whole-package map", output.lower())
            self.assertNotIn("2026-07-11-capability-surface.md", output)
        latest = max(row["updated_date"] for row in self.cells)
        self.assertIn(f"Generated {latest}", html)
        self.assertIn(f"Generated {latest}", markdown)
        widget = generated[
            ROOT / "docs/dev-log/dashboard/capability-census/_widget_data.json"
        ].decode("utf-8")
        self.assertIn(f'"generated":"{latest}"', widget)

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
