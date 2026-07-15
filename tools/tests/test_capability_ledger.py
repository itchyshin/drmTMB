"""Tests for the deterministic capability-ledger generator."""

from __future__ import annotations

import importlib.util
import copy
import csv
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
        self.assertEqual(len(model), 675)
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

    def test_arc3a_cells_are_narrow_and_evidence_backed(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        by_id = {row["cell_id"]: row for row in model}
        evidence_by_id = {row["evidence_id"]: row for row in self.evidence}

        self.assertEqual(
            {status: sum(row["capability_status"] == status for row in model)
             for status in ("implemented", "rejected_by_design", "not_implemented")},
            {"implemented": 305, "rejected_by_design": 330, "not_implemented": 40},
        )
        for cell_id in ("mc-0251", "mc-0386", "mc-0388"):
            row = by_id[cell_id]
            self.assertEqual(row["q_gate"], "q1")
            self.assertEqual(row["estimator"], "ML")
            self.assertEqual(row["capability_status"], "implemented")
            self.assertEqual(row["work_status"], "verified")
            self.assertEqual(row["evidence_tier"], "point_fit_recovery")
            self.assertIn("unlabelled q1 structured intercept", row["claim_boundary"])
            for excluded in ("REML", "intervals", "coverage", "inference-ready", "supported"):
                self.assertIn(excluded, row["claim_boundary"])
            self.assertEqual(
                evidence_by_id[row["primary_evidence_id"]]["cell_id"], cell_id
            )

        for cell_id in ("mc-0669", "mc-0670", "mc-0671"):
            row = by_id[cell_id]
            self.assertEqual(row["route_variant"], "arc3a_beyond_intercept")
            self.assertEqual(row["q_gate"], "q2")
            self.assertEqual(row["capability_status"], "rejected_by_design")
            self.assertEqual(row["work_status"], "deferred")
            self.assertEqual(row["evidence_tier"], "none")
            for excluded in ("slope", "labelled", "q2", "structured `sigma`", "simultaneous"):
                self.assertIn(excluded, row["claim_boundary"])

        comparator = by_id["mc-0248"]
        self.assertEqual(comparator["primary_evidence_id"], "ev-mc-0248-legacy")
        self.assertEqual(comparator["evidence_tier"], "point_fit_recovery")
        self.assertIn("90/90-converged", comparator["claim_boundary"])

    def test_arc1b_s1_cells_are_exact_and_preserve_the_rejected_remainder(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        by_id = {row["cell_id"]: row for row in model}
        evidence_by_id = {row["evidence_id"]: row for row in self.evidence}
        evidence_by_cell = {
            cell_id: [row for row in self.evidence if row["cell_id"] == cell_id]
            for cell_id in ("mc-0199", "mc-0672", "mc-0673")
        }

        self.assertEqual(
            {status: sum(row["capability_status"] == status for row in model)
             for status in ("implemented", "rejected_by_design", "not_implemented")},
            {"implemented": 305, "rejected_by_design": 330, "not_implemented": 40},
        )
        self.assertEqual(
            sum(row["evidence_tier"] == "point_fit_recovery" for row in model),
            163,
        )

        for cell_id, dpar in (("mc-0199", "mu1"), ("mc-0672", "mu2")):
            row = by_id[cell_id]
            self.assertEqual(row["dpar"], dpar)
            self.assertEqual(row["route_variant"], "arc1b_s1_exact_q2_intercept")
            self.assertEqual(row["structure_provider"], "spatial")
            self.assertEqual(row["q_gate"], "q2")
            self.assertEqual(row["estimator"], "REML")
            self.assertEqual(row["capability_status"], "implemented")
            self.assertEqual(row["work_status"], "verified")
            self.assertEqual(row["evidence_tier"], "point_fit_recovery")
            if cell_id == "mc-0199":
                self.assertEqual(
                    row["legacy_evidence_source"], "R/drmTMB.R:2056-2113"
                )
            self.assertEqual(
                evidence_by_id[row["primary_evidence_id"]]["evidence_class"],
                "model_recovery",
            )
            self.assertIn("1,200-attempt Totoro campaign", row["claim_boundary"])
            for excluded in (
                "unlabelled", "unmatched", "mismatched-label/group/coordinate",
                "multiple-label", "slope-only", "predictor-dependent",
                "q4+", "scale-only q2", "q2-plus-q2", "mesh/range-estimating",
                "incomplete-pair", "non-unit-weight", "known-`meta_V()`",
                "additional-random-layer", "direct-SD", "spatial-`corpair()`",
                "random-`rho12`", "animal", "relmat", "non-Gaussian",
                "AI-REML", "interval", "coverage", "inference-ready",
                "supported",
            ):
                self.assertIn(excluded, row["claim_boundary"])
            for admitted_condition in (
                "response pairs are complete", "weights are one",
                "no known `meta_V()`", "no additional ordinary random effect",
                "direct-SD formula", "`corpair()` regression",
            ):
                self.assertIn(admitted_condition, row["claim_boundary"])
            self.assertEqual(
                {item["evidence_class"] for item in evidence_by_cell[cell_id]
                 if "arc1b" in item["evidence_id"]},
                {"contract_test", "model_recovery"},
            )

        remainder = by_id["mc-0673"]
        self.assertEqual(remainder["route_variant"], "arc1b_s1_remaining_spatial_reml")
        self.assertEqual(remainder["estimator"], "REML")
        self.assertEqual(remainder["capability_status"], "rejected_by_design")
        self.assertEqual(remainder["work_status"], "deferred")
        self.assertEqual(remainder["evidence_tier"], "none")
        self.assertIn("mc-0199` and `mc-0672", remainder["claim_boundary"])
        for rejected_neighbour in (
            "incomplete response pairs", "known `meta_V()` covariance",
            "direct-SD formulae", "spatial `corpair()` regressions",
            "random `rho12` effects", "q2-plus-q2", "mesh/range-estimating",
        ):
            self.assertIn(rejected_neighbour, remainder["claim_boundary"])
        self.assertEqual(
            evidence_by_id[remainder["primary_evidence_id"]]["evidence_class"],
            "rejection_test",
        )

        for cell_id, dpar in (("mc-0107", "mu1"), ("mc-0108", "mu2")):
            comparator = by_id[cell_id]
            self.assertEqual(comparator["dpar"], dpar)
            self.assertEqual(comparator["estimator"], "ML")
            self.assertEqual(
                comparator["primary_evidence_id"], f"ev-{cell_id}-legacy"
            )

    def test_arc1b_s2r_cells_are_exact_and_preserve_relmat_rejections(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        by_id = {row["cell_id"]: row for row in model}
        evidence_by_id = {row["evidence_id"]: row for row in self.evidence}

        for cell_id, dpar in (("mc-0201", "mu1"), ("mc-0674", "mu2")):
            row = by_id[cell_id]
            self.assertEqual(row["dpar"], dpar)
            self.assertEqual(
                row["route_variant"], "arc1b_s2r_exact_q2_intercept"
            )
            self.assertEqual(row["structure_provider"], "relmat")
            self.assertEqual(row["q_gate"], "q2")
            self.assertEqual(row["estimator"], "REML")
            self.assertEqual(row["capability_status"], "implemented")
            self.assertEqual(row["work_status"], "verified")
            self.assertEqual(row["evidence_tier"], "point_fit_recovery")
            self.assertEqual(
                evidence_by_id[row["primary_evidence_id"]]["evidence_class"],
                "model_recovery",
            )
            for required in (
                "matching labelled `relmat(1 | p | id, K = K)`",
                "same label, grouping levels and order",
                "identical named supplied covariance `K`",
                "2,400-attempt Totoro campaign",
                "point-fit recovery only",
                "supplied precision `Q`",
                "slopes", "q4+", "scale-side", "incomplete pairs",
                "non-unit weights", "additional random layers",
                "non-Gaussian", "interval", "coverage", "supported",
            ):
                self.assertIn(required, row["claim_boundary"])

        remainder = by_id["mc-0675"]
        self.assertEqual(
            remainder["route_variant"], "arc1b_s2r_remaining_relmat_reml"
        )
        self.assertEqual(remainder["capability_status"], "rejected_by_design")
        self.assertEqual(remainder["work_status"], "deferred")
        self.assertEqual(remainder["evidence_tier"], "none")
        self.assertIn("`mc-0201` and `mc-0674`", remainder["claim_boundary"])
        self.assertEqual(
            evidence_by_id[remainder["primary_evidence_id"]]["evidence_class"],
            "rejection_test",
        )

        for cell_id in ("mc-0151", "mc-0152"):
            self.assertEqual(by_id[cell_id]["estimator"], "ML")
            self.assertEqual(
                by_id[cell_id]["primary_evidence_id"], f"ev-{cell_id}-legacy"
            )
        self.assertEqual(by_id["mc-0200"]["capability_status"], "rejected_by_design")
        for cell_id in ("mc-0199", "mc-0672"):
            self.assertEqual(by_id[cell_id]["structure_provider"], "spatial")
            self.assertEqual(by_id[cell_id]["evidence_tier"], "point_fit_recovery")
        self.assertEqual(by_id["mc-0673"]["capability_status"], "rejected_by_design")

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
            self.assertIn(
                "structured SD scale `s_j` gives covariance `s_j^2 K_h`",
                row["claim_boundary"],
            )
            self.assertIn(
                "marginal SD `s_j sqrt(K_h[ii])`",
                row["claim_boundary"],
            )
            self.assertNotIn(
                "structured covariance-scale multiplier",
                row["claim_boundary"],
            )

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

    def test_inference_ready_structured_sd_rows_name_their_interval_channel(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        for cell_id in (
            "mc-0085", "mc-0086", "mc-0153", "mc-0154",
            "mc-0272", "mc-0285", "mc-0309",
        ):
            boundary = by_id[cell_id]["claim_boundary"]
            self.assertIn(
                "location-axis bias-corrected small-sample-t Wald",
                boundary,
            )
            self.assertIn("inference-ready with caveats", boundary)
            self.assertIn("not nominal", boundary)

        for cell_id in ("mc-0276", "mc-0301", "mc-0313"):
            boundary = by_id[cell_id]["claim_boundary"]
            self.assertIn("raw uncorrected log-SD Wald-z", boundary)
            self.assertIn(
                "location-axis bias+t correction does not apply to sigma",
                boundary,
            )
            self.assertIn("profile is diagnostic-only at g=8", boundary)
            self.assertIn("inference-ready with caveats", boundary)
            self.assertIn("not supported", boundary)

    def test_reader_surfaces_do_not_erase_structured_sigma_slope_support(self):
        surfaces = {
            name: (ROOT / "vignettes" / name).read_text()
            for name in (
                "animal-models.Rmd",
                "count-nbinom2.Rmd",
                "distribution-families.Rmd",
                "formula-grammar.Rmd",
                "implementation-map.Rmd",
                "model-map.Rmd",
                "phylogenetic-spatial.Rmd",
                "proportion-beta-binomial.Rmd",
                "relmat-known-matrices.Rmd",
                "source-map.Rmd",
                "spatial-models.Rmd",
                "structural-dependence.Rmd",
            )
        }
        surfaces["README.md"] = (ROOT / "README.md").read_text()
        surfaces["drmTMB.Rmd"] = (ROOT / "vignettes/drmTMB.Rmd").read_text()
        surfaces["structured-re-balance-100-slices.tsv"] = (
            ROOT / "docs/dev-log/dashboard/structured-re-balance-100-slices.tsv"
        ).read_text()
        surfaces["structured-re-scope-gate-status.tsv"] = (
            ROOT / "docs/dev-log/dashboard/structured-re-scope-gate-status.tsv"
        ).read_text()
        surfaces["45-cross-dpar-correlation-gate.md"] = (
            ROOT / "docs/design/45-cross-dpar-correlation-gate.md"
        ).read_text()
        surfaces["59-structural-slope-and-non-gaussian-map.md"] = (
            ROOT / "docs/design/59-structural-slope-and-non-gaussian-map.md"
        ).read_text()
        for name in (
            "01-formula-grammar.md",
            "02-family-registry.md",
            "03-likelihoods.md",
            "04-random-effects.md",
            "06-distribution-roadmap.md",
            "33-phase-6c-core-random-effects.md",
            "34-validation-debt-register.md",
            "41-phase-18-simulation-programme.md",
            "46-pre-simulation-readiness-matrix.md",
            "57-structural-parity-next-slices.md",
            "61-structural-parity-slices-83-140.md",
            "70-phase-18-poisson-structured-q1-ademp.md",
            "79-supported-nongaussian-evidence-goal.md",
            "109-phase-18-core-family-completion-map-slices-1279-1288.md",
            "112-phase-18-ordinal-fixed-effect-artifacts-slices-1309-1318.md",
            "134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md",
            "143-phase-18-structured-workflow-registry.md",
            "168-r-julia-finish-capability-matrix.md",
            "80-four-week-random-slope-digital-twin-sprint.md",
            "204-ayumi-literature-docs-summary.md",
            "205-ayumi-reply-readiness-gate.md",
            "211-structured-reml-status.md",
            "25-ordinal-scale-discrimination.md",
        ):
            surfaces[name] = (ROOT / "docs/design" / name).read_text()
        surfaces["known-limitations.md"] = (
            ROOT / "docs/dev-log/known-limitations.md"
        ).read_text()
        surfaces["which-scale.Rmd"] = (
            ROOT / "vignettes/which-scale.Rmd"
        ).read_text()
        surfaces["NEWS.md"] = (ROOT / "NEWS.md").read_text()
        surfaces["ROADMAP.md"] = (ROOT / "ROADMAP.md").read_text()
        surfaces["README.md"] = (ROOT / "README.md").read_text()
        surfaces["113-phase-18-count-first-wave-closure-slices-1319-1328.md"] = (
            ROOT / "docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md"
        ).read_text()
        combined = "\n".join(surfaces.values())
        for stale in (
            "residual-scale structured slopes remain planned",
            "structured residual-scale slopes remain planned",
            "residual-scale structured slopes;",
            "no correlated scale slopes yet",
            "correlated univariate residual-scale slope covariance",
            "correlated `sigma` slopes, coefficient-specific",
            "correlated residual-scale slope blocks in `sigma`",
            "residual-scale slope correlations are fixed at zero in this phase",
            "Sparse known covariance, correlated residual-scale slope",
            "Correlated residual-scale intercept-slope",
            "Correlated residual-scale slope blocks and labelled",
            "not correlated scale-slope blocks",
            "correlations fixed at zero. Correlated residual-scale",
            "correlated residual-scale slope blocks and coefficient-specific",
            "structured slope-correlation, correlated univariate residual-scale",
            "univariate correlated residual-scale random-slope blocks",
            "structured `sigma` effects remain planned",
            "structured NB2 `sigma` effects",
            "NB2 structured `sigma`, simultaneous structured types",
            "local-fit gates, NB2 structured `sigma`, q2/q4 count covariance",
            "NB2 `sigma` structured effects remain planned",
            "no structured count `mu` slopes yet",
            "and structured `sigma`. |",
            "non-Gaussian residual-scale structured effects remain planned",
            "Structured count slopes, labelled q=2/q=4 count blocks",
            "structured slopes, `sigma` relatedness models, bivariate relatedness covariance",
            "NB2 phylogenetic slopes, NB2 `sigma` phylogeny",
            "animal-model location SDs",
            "animal-model endpoint SDs",
            "lower-level relatedness location SDs",
            "lower-level relatedness endpoint SDs",
            "other scale-side count routes remain fixed-effect only",
            "q=1 structured `mu` intercept routes using one of",
            "ordinary Poisson/NB2 q=1 `mu` intercepts | broader",
            "| NB2 structured count model | ordinary NB2 q=1 `phylo()`, `spatial()`, `animal()`, or `relmat()` in `mu`",
            "| Poisson structured count slopes | ordinary Poisson/NB2 independent numeric `mu` slopes",
            "Fitted only for ordinary non-zero-inflated NB2",
            "simultaneous structured types, zero-inflation, scale,",
        ):
            self.assertNotIn(stale, combined)

        self.assertIn(
            "exact A-matrix q1 `sigma` one-slope route",
            surfaces["animal-models.Rmd"],
        )
        self.assertIn(
            "exact K/Q q1 `sigma` one-slope route",
            surfaces["relmat-known-matrices.Rmd"],
        )
        self.assertIn(
            "q1 structured `sigma` one-slope paths fit for",
            surfaces["phylogenetic-spatial.Rmd"],
        )
        self.assertIn(
            "a q1 `sigma` one-slope point-fit/extractor route",
            surfaces["implementation-map.Rmd"],
        )
        self.assertIn(
            "unlabelled correlated intercept-slope and multi-slope blocks",
            surfaces["implementation-map.Rmd"],
        )
        self.assertIn(
            "Unlabelled ordinary correlated residual-scale intercept-slope",
            surfaces["02-family-registry.md"],
        )
        self.assertIn(
            "reports them in `corpars$sigma`",
            surfaces["04-random-effects.md"],
        )
        self.assertIn(
            "Exact q1 structured `sigma` intercept-plus-one-slope routes",
            surfaces["formula-grammar.Rmd"],
        )
        self.assertIn(
            "sigma ~ z + (1 + w | id)",
            surfaces["formula-grammar.Rmd"],
        )
        self.assertIn(
            "exact q1 structured `sigma` intercept-plus-one-slope routes",
            surfaces["02-family-registry.md"],
        )
        self.assertIn(
            "`mu` intercept-plus-one-slope routes using one of",
            surfaces["distribution-families.Rmd"],
        )
        self.assertIn(
            "Poisson/NB2 q=1 `phylo()`/`spatial()`/`animal()`/`relmat()` `mu` intercept-plus-one-slope routes",
            surfaces["model-map.Rmd"],
        )
        self.assertIn(
            "separate recovery-grade NB2 q=1 structured `sigma` routes",
            surfaces["model-map.Rmd"],
        )
        self.assertIn(
            "Poisson/NB2 q1 single-provider structured `mu`",
            surfaces["implementation-map.Rmd"],
        )
        self.assertIn(
            "Ordinary non-zero-inflated NB2 fits a plain log-`sigma` random intercept",
            surfaces["34-validation-debt-register.md"],
        )
        self.assertIn(
            "q=1 `hu ~ relmat(1 | id, K/Q = ...)` intercept route",
            surfaces["distribution-families.Rmd"],
        )
        self.assertIn(
            "one truncated-NB2 q=1 `hu ~ relmat(1 | id, K/Q = ...)` diagnostic-only route",
            surfaces["model-map.Rmd"],
        )
        self.assertIn(
            "one diagnostic-only truncated-NB2 q=1 `hu ~ relmat(K/Q)` intercept",
            surfaces["implementation-map.Rmd"],
        )
        self.assertIn(
            "exact recovery-grade NB2\n  q=1 `sigma` intercept-plus-one-slope routes",
            surfaces["known-limitations.md"],
        )
        self.assertNotIn(
            "fixed effects only; `hu` random effects planned",
            surfaces["distribution-families.Rmd"],
        )
        self.assertNotIn(
            "`zi` and `hu` are currently fixed-effect probability components",
            surfaces["implementation-map.Rmd"],
        )
        self.assertNotIn(
            "but structured `sigma`, structured slopes",
            surfaces["known-limitations.md"],
        )
        self.assertNotIn(
            "Ordinal `mu` random-effect bar terms now error",
            surfaces["known-limitations.md"],
        )
        self.assertIn(
            "cumulative-logit `mu ~ phylo(1 | id, tree = tree)`",
            surfaces["known-limitations.md"],
        )
        self.assertIn(
            "Hurdle NB2 also fits one diagnostic-only q=1",
            surfaces["02-family-registry.md"],
        )
        self.assertIn(
            "truncated-NB2 q=1 `hu ~ relmat(K/Q)` intercept",
            surfaces["34-validation-debt-register.md"],
        )
        self.assertIn(
            "four exact diagnostic-only structured gates: q1 Poisson `zi ~ spatial()`, fixed-`zi` Poisson `mu ~ spatial()`, fixed-`zi` NB2 `mu ~ spatial()`, and truncated-NB2 `hu ~ relmat(K/Q)` intercepts",
            surfaces["46-pre-simulation-readiness-matrix.md"],
        )
        self.assertIn(
            "truncated NB2 has one diagnostic-only q1 `hu ~ relmat(K/Q)` intercept",
            surfaces["59-structural-slope-and-non-gaussian-map.md"],
        )
        self.assertIn(
            "Poisson `zi ~ spatial()` and truncated-NB2 `hu ~ relmat(K/Q)`",
            surfaces["41-phase-18-simulation-programme.md"],
        )
        self.assertIn(
            "q1 `mu ~ phylo(1 | id, tree = tree)` intercept",
            surfaces["41-phase-18-simulation-programme.md"],
        )
        self.assertIn(
            "Student-t `nu ~ phylo(1 | id, tree = tree)`",
            surfaces["34-validation-debt-register.md"],
        )
        self.assertIn(
            "Poisson `zi ~ spatial()` and truncated-NB2 `hu ~ relmat(K/Q)`",
            surfaces["46-pre-simulation-readiness-matrix.md"],
        )
        self.assertIn(
            "cumulative-logit `mu ~ phylo()`",
            surfaces["59-structural-slope-and-non-gaussian-map.md"],
        )
        self.assertIn(
            "zi ~ spatial(1 | id, coords = coords)",
            surfaces["count-nbinom2.Rmd"],
        )
        self.assertIn(
            "hu ~ relmat(1 | id, K = K)",
            surfaces["count-nbinom2.Rmd"],
        )
        self.assertNotIn(
            "Fixed-effect `mu` and fixed-effect `zi` only",
            surfaces["02-family-registry.md"],
        )
        self.assertNotIn(
            "Cumulative-logit fixed-effect models fit; ordinal random effects are blocked",
            surfaces["34-validation-debt-register.md"],
        )
        self.assertNotIn(
            "random-intercept and random-slope requests in `zi`, `hu`, `zoi`, and `coi` are blocked",
            surfaces["46-pre-simulation-readiness-matrix.md"],
        )
        self.assertIn(
            "The exact q1 `mu ~ spatial(1 + x | ...)` route is point/recovery-grade; intercept-only `mu ~ spatial(1 | ...)` and `nu ~ phylo()` are diagnostic-only single-smoke gates.",
            surfaces["79-supported-nongaussian-evidence-goal.md"],
        )
        self.assertIn(
            "one exact q1 `hu ~ relmat(K/Q)` intercept",
            surfaces["79-supported-nongaussian-evidence-goal.md"],
        )
        for name in (
            "34-validation-debt-register.md",
            "41-phase-18-simulation-programme.md",
            "59-structural-slope-and-non-gaussian-map.md",
            "79-supported-nongaussian-evidence-goal.md",
            "implementation-map.Rmd",
            "known-limitations.md",
        ):
            self.assertIn("crossed", surfaces[name])
            self.assertIn("spatial", surfaces[name])
            self.assertIn("relmat", surfaces[name])
        self.assertIn(
            "simultaneous structured count types beyond the exact crossed NB2",
            surfaces["59-structural-slope-and-non-gaussian-map.md"],
        )
        for name in (
            "01-formula-grammar.md",
            "03-likelihoods.md",
            "34-validation-debt-register.md",
            "46-pre-simulation-readiness-matrix.md",
            "109-phase-18-core-family-completion-map-slices-1279-1288.md",
            "count-nbinom2.Rmd",
            "distribution-families.Rmd",
            "formula-grammar.Rmd",
            "model-map.Rmd",
        ):
            self.assertIn("exact crossed", surfaces[name])
            self.assertIn("NB2", surfaces[name])
            self.assertIn("spatial", surfaces[name])
            self.assertIn("relmat", surfaces[name])
        self.assertIn(
            "Superseded boundary (2026-07-14)",
            surfaces["134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md"],
        )
        self.assertIn(
            "zero-inflation beyond the exact Poisson q1 `zi ~ spatial()`, fixed-`zi` Poisson `mu ~ spatial()`, and fixed-`zi` NB2 `mu ~ spatial()` gates",
            surfaces["80-four-week-random-slope-digital-twin-sprint.md"],
        )
        self.assertIn(
            "Native `REML = TRUE` is exact-Gaussian and row-specific",
            surfaces["01-formula-grammar.md"],
        )
        self.assertNotIn(
            "mean-side-only in current drmTMB",
            surfaces["01-formula-grammar.md"],
        )
        for name in (
            "204-ayumi-literature-docs-summary.md",
            "205-ayumi-reply-readiness-gate.md",
        ):
            self.assertIn("Current-status correction (2026-07-14)", surfaces[name])
            self.assertIn("q4", surfaces[name])
            self.assertNotIn("mean-side-only", surfaces[name])
        self.assertNotIn(
            "native q4 REML and R-via-Julia bridge promotion are not available",
            surfaces["204-ayumi-literature-docs-summary.md"],
        )
        self.assertIn(
            "q4 recovery evidence",
            surfaces["211-structured-reml-status.md"],
        )
        for name in ("01-formula-grammar.md", "formula-grammar.Rmd"):
            self.assertIn("ordinary `mu` random intercepts", surfaces[name])
            self.assertIn("`nu ~ phylo", surfaces[name])
            self.assertIn("`hu ~ relmat", surfaces[name])
            self.assertIn("`zi ~ spatial", surfaces[name])
        self.assertNotIn(
            "Poisson and NB2 phylogenetic count slopes remain planned",
            surfaces["formula-grammar.Rmd"],
        )
        self.assertNotIn(
            "Ordinary ordinal random effects, other structured routes",
            surfaces["formula-grammar.Rmd"],
        )
        self.assertIn(
            "eligible cumulative-logit, Student-t, beta, Tweedie, skew-normal, and zero-one-beta routes",
            surfaces["implementation-map.Rmd"],
        )
        self.assertIn(
            "zero_one_beta()` | `mu` logit",
            surfaces["02-family-registry.md"],
        )
        self.assertIn(
            "ordinary unlabelled `mu` random intercepts and independent numeric slopes at recovery grade",
            surfaces["02-family-registry.md"],
        )
        self.assertNotIn(
            "Fixed effects only for continuous `[0, 1]` responses",
            surfaces["02-family-registry.md"],
        )
        self.assertIn(
            "The current REML surface is row-specific rather than blanket-narrow",
            surfaces["03-likelihoods.md"],
        )
        self.assertIn(
            "Arc 1a adds pure-`mu`",
            surfaces["03-likelihoods.md"],
        )
        self.assertNotIn(
            "structured `phylo()`/`spatial()`/`animal()`/`relmat()` effects, direct `sd()`",
            surfaces["03-likelihoods.md"],
        )
        for gate in (
            "`zi ~ spatial(1 | id, coords = coords)`",
            "fixed-`zi` local-fit gate admits `mu ~ spatial(1 | id, coords = coords)`",
            "`hu ~ relmat(1 | id, K/Q = ...)`",
            "ordinary recovery-grade `mu` random intercepts and independent numeric",
            "a separate ordinary `sigma` random intercept",
            "`mu ~ relmat()` intercept or one-slope route",
            "The current `skew_normal()` route keeps `sigma`/`nu` random effects",
        ):
            self.assertIn(gate, surfaces["06-distribution-roadmap.md"])
        self.assertNotIn(
            "zero-inflated NB2 random effects remain planned",
            surfaces["06-distribution-roadmap.md"],
        )
        self.assertNotIn(
            "fixed-effect hurdle NB2 path",
            surfaces["06-distribution-roadmap.md"],
        )
        for stale in (
            "fixed-effect `mu`\n  only, no `sigma`, no random effects",
            "implemented first fixed-effect route for non-negative",
            "Start with `skew_normal()` after Student-t is stable",
        ):
            self.assertNotIn(stale, surfaces["06-distribution-roadmap.md"])
        self.assertIn(
            "mu_i = X_mu[i, ] beta_mu + Z_mu[i, ] b_mu",
            surfaces["06-distribution-roadmap.md"],
        )
        self.assertIn(
            "exact q1 `mu ~ phylo(1 | id, tree = tree)` intercept",
            surfaces["06-distribution-roadmap.md"],
        )
        self.assertIn(
            "Tweedie and\n  skew-normal both fit ordinary unlabelled `mu` random intercepts",
            surfaces["README.md"],
        )
        self.assertIn(
            "Ordinary\n  unlabelled `mu` random intercepts and independent numeric slopes are\n  recovery-grade",
            surfaces["README.md"],
        )
        self.assertNotIn(
            "coi` is the probability that a boundary outcome is exactly 1. Random\n  effects",
            surfaces["README.md"],
        )
        for name in (
            "25-ordinal-scale-discrimination.md",
            "known-limitations.md",
            "ROADMAP.md",
        ):
            text = surfaces[name].lower()
            self.assertIn("ordinary", text)
            self.assertIn("cumulative-logit", text)
            self.assertIn("random intercept", text)
            self.assertIn("independent", text)
            self.assertIn("phylo", text)
        ordinal_combined = "\n".join(
            surfaces[name]
            for name in (
                "25-ordinal-scale-discrimination.md",
                "known-limitations.md",
                "ROADMAP.md",
            )
        )
        for stale in (
            "ready only for fixed-effect",
            "mu random-effect bar terms before fitting",
            "Other ordinal mu random-effect terms error",
            "Ordinary grouped intercepts such as `(1 | id)`, ordinal random slopes",
        ):
            self.assertNotIn(stale, ordinal_combined)
        self.assertNotIn("skew-normal is a fixed-effect first slice", surfaces["README.md"])
        self.assertIn(
            "Every fitted univariate\nnon-Gaussian family has an ordinary recovery-grade `mu` random intercept and\nindependent numeric slope",
            surfaces["README.md"],
        )
        self.assertIn(
            "zero-one beta fixed effects plus ordinary recovery-grade `mu` random intercepts",
            surfaces["drmTMB.Rmd"],
        )
        self.assertNotIn("fixed-effect zero-one beta", surfaces["drmTMB.Rmd"])
        self.assertIn(
            "each has ordinary recovery-grade `mu` random intercepts and independent numeric slopes",
            surfaces["model-map.Rmd"],
        )
        self.assertNotIn("fixed-effect `zero_one_beta()`", surfaces["model-map.Rmd"])
        self.assertIn(
            "non-Gaussian paths outside the exact ordinary Poisson/NB2 q1 spatial `mu`",
            surfaces["model-map.Rmd"],
        )
        self.assertNotIn("and non-Gaussian paths remain planned", surfaces["model-map.Rmd"])
        for name in (
            "README.md",
            "model-map.Rmd",
            "phylogenetic-spatial.Rmd",
            "implementation-map.Rmd",
            "spatial-models.Rmd",
        ):
            self.assertIn("non-Gaussian spatial", surfaces[name])
            self.assertIn("outside the", surfaces[name])
            self.assertNotIn("non-Gaussian spatial effects are still", surfaces[name])
            self.assertNotIn("non-Gaussian spatial effects, and", surfaces[name])
        for name in (
            "README.md",
            "model-map.Rmd",
            "phylogenetic-spatial.Rmd",
            "implementation-map.Rmd",
            "spatial-models.Rmd",
            "source-map.Rmd",
            "which-scale.Rmd",
        ):
            normalized = " ".join(surfaces[name].split())
            for gate in (
                "ordinary Poisson/NB2 q1 spatial `mu`",
                "recovery-grade NB2 q1 spatial `sigma`",
                "Student-t spatial `mu`",
                "Poisson spatial `zi`",
                "fixed-`zi` NB2 spatial `mu`",
            ):
                self.assertIn(gate, normalized)
        self.assertNotIn(
            "gates outside the exact ordinary Poisson/NB2",
            surfaces["spatial-models.Rmd"],
        )
        for name in ("README.md", "model-map.Rmd"):
            self.assertIn(
                "non-Gaussian phylogenetic slopes outside the exact unlabelled Poisson/NB2 q1 intercept-plus-one-slope gates",
                surfaces[name],
            )
            self.assertNotIn(
                "multiple or labelled phylogenetic slopes, non-Gaussian phylogenetic slopes,",
                surfaces[name],
            )
        self.assertNotIn(
            "simultaneous structured types, and broader count covariance",
            surfaces["implementation-map.Rmd"],
        )
        self.assertIn(
            "The eligible ordinary routes accept unlabelled `mu` random intercepts",
            surfaces["distribution-families.Rmd"],
        )
        self.assertIn(
            "an active `hu` formula does not",
            surfaces["distribution-families.Rmd"],
        )
        self.assertIn(
            "exact q=1 `mu`/`sigma ~ animal()` recovery-grade gates",
            surfaces["distribution-families.Rmd"],
        )
        self.assertNotIn(
            "skew-normal is currently fixed-effect only",
            surfaces["distribution-families.Rmd"],
        )
        self.assertNotIn(
            "Tweedie is currently fixed-effect only",
            surfaces["distribution-families.Rmd"],
        )
        self.assertIn(
            "Eligible ordinary routes across Student-t, skew-normal",
            surfaces["model-map.Rmd"],
        )
        self.assertIn(
            "The current R engine",
            surfaces["proportion-beta-binomial.Rmd"],
        )
        self.assertIn(
            "ordinary unlabelled `mu` random intercepts and independent numeric",
            surfaces["proportion-beta-binomial.Rmd"],
        )
        for family in ("Skew-normal", "Tweedie", "Zero-one beta", "Cumulative-logit"):
            self.assertIn(family, surfaces["source-map.Rmd"])
        self.assertNotIn(
            "keep the first slice fixed-effect only",
            surfaces["source-map.Rmd"],
        )
        self.assertIn(
            "Ordinary unlabelled `mu` random intercepts and independent numeric slopes are recovery-grade",
            surfaces["79-supported-nongaussian-evidence-goal.md"],
        )
        for historical in (
            "57-structural-parity-next-slices.md",
            "61-structural-parity-slices-83-140.md",
            "70-phase-18-poisson-structured-q1-ademp.md",
            "143-phase-18-structured-workflow-registry.md",
        ):
            self.assertIn("superseded 2026-07-14", surfaces[historical])
        self.assertIn(
            "Exact q1 NB2 structured `sigma` intercept-plus-one-slope routes",
            surfaces["NEWS.md"],
        )
        self.assertIn(
            "exact q=1 NB2 structured `sigma` intercept-plus-one-slope routes",
            surfaces["README.md"],
        )

        common_math = (ROOT / "docs/design/16-phylo-spatial-common-math.md").read_text()
        self.assertIn("marginal SD at node `i` is `sigma_z * sqrt(K[i, i])`", common_math)
        self.assertNotIn("`sigma_z` is the unknown marginal SD", common_math)

        roadmap = (ROOT / "ROADMAP.md").read_text()
        self.assertIn(
            "q1 structured `sigma` one-slope paths also fit for all four providers",
            roadmap,
        )
        self.assertNotIn(
            "NB2 `sigma` slopes or structured effects",
            roadmap,
        )
        self.assertNotIn(
            "non-Gaussian `sigma` random effects outside the ordinary NB2, lognormal, and Gamma intercept gates,",
            roadmap,
        )
        self.assertIn(
            "exact q1 NB2 structured `sigma` intercept-plus-one-slope routes",
            roadmap,
        )

    def test_provider_claims_name_exact_nongaussian_gates(self):
        phylo_surfaces = {
            name: " ".join((ROOT / "vignettes" / name).read_text().split())
            for name in (
                "implementation-map.Rmd",
                "phylogenetic-models.Rmd",
                "phylogenetic-spatial.Rmd",
                "structural-dependence.Rmd",
            )
        }
        for name, text in phylo_surfaces.items():
            for gate in (
                "Poisson/NB2 q1 phylogenetic `mu` intercept-plus-one-slope",
                "NB2 q1 phylogenetic `sigma`",
                "Student-t q1 phylogenetic `nu`",
                "cumulative-logit q1 phylogenetic `mu`",
            ):
                self.assertIn(gate, text, name)
        provider_map = " ".join(
            (ROOT / "vignettes/structural-dependence.Rmd").read_text().split()
        )
        for gate in (
            "Poisson/NB2 q1 animal `mu` intercept-plus-one-slope",
            "NB2 q1 animal `sigma`",
            "beta animal route",
            "Poisson/NB2 q1 relmat `mu` intercept-plus-one-slope",
            "NB2 q1 relmat `sigma`",
            "Gamma q1 relmat `mu`",
            "truncated-NB2 q1 relmat `hu`",
        ):
            self.assertIn(gate, provider_map)
        combined = "\n".join(
            path.read_text()
            for path in (
                ROOT / "NEWS.md",
                ROOT / "ROADMAP.md",
                ROOT / "docs/design/34-validation-debt-register.md",
                ROOT / "docs/design/46-pre-simulation-readiness-matrix.md",
                ROOT / "docs/design/59-structural-slope-and-non-gaussian-map.md",
                ROOT / "docs/dev-log/known-limitations.md",
                ROOT / "vignettes/implementation-map.Rmd",
                ROOT / "vignettes/phylogenetic-models.Rmd",
                ROOT / "vignettes/phylogenetic-spatial.Rmd",
                ROOT / "vignettes/structural-dependence.Rmd",
            )
        )
        for stale in (
            "and non-Gaussian effects |",
            "non-Gaussian phylogenetic effects planned",
            "non-Gaussian relatedness effects, and",
            "only the q=1 intercept is fitted for counts",
            "non-Gaussian routes, and spatial `corpair()` routes remain planned",
        ):
            self.assertNotIn(stale, combined)

    def test_spatial_inflation_surfaces_name_all_exact_gates(self):
        surfaces = {
            "readiness": ROOT / "docs/design/46-pre-simulation-readiness-matrix.md",
            "programme": ROOT / "docs/design/41-phase-18-simulation-programme.md",
            "debt": ROOT / "docs/design/34-validation-debt-register.md",
            "model_map": ROOT / "vignettes/model-map.Rmd",
            "implementation_map": ROOT / "vignettes/implementation-map.Rmd",
        }
        normalized = {
            name: " ".join(path.read_text().split())
            for name, path in surfaces.items()
        }
        for name, text in normalized.items():
            self.assertIn("fixed-`zi` NB2", text, name)
            self.assertIn("fixed-`zi` Poisson", text, name)
            self.assertIn("diagnostic-only", text, name)
            self.assertIn("diagnostic-only", text, name)
            self.assertIn("Poisson `zi`", text, name)
        stale_by_surface = {
            "readiness": "beyond the two exact q1 intercept gates",
            "debt": "zero-inflated spatial effects beyond the exact Poisson gate",
            "model_map": "and zero-inflated spatial effects |",
            "implementation_map": "beyond the exact Poisson `zi`, fixed-`zi` Poisson `mu`, and fixed-`zi` NB2 `mu` gates",
        }
        for name, stale in stale_by_surface.items():
            self.assertNotIn(stale, normalized[name], name)
        spatial_row = next(
            line
            for line in surfaces["readiness"].read_text().splitlines()
            if line.startswith("| Spatial models |")
        )
        for gate in (
            "diagnostic-only Poisson q1 `zi ~ spatial()` intercept",
            "diagnostic-only fixed-`zi` Poisson q1 `mu ~ spatial()` route",
            "diagnostic-only fixed-`zi` NB2 q1 `mu ~ spatial()` route",
            "zero-inflated spatial effects outside the exact Poisson `zi`, fixed-`zi` Poisson `mu`, and fixed-`zi` NB2 `mu` gates",
            "fixed-`zi` NB2 route has no recovery, interval, or coverage promotion",
        ):
            self.assertIn(gate, spatial_row)
        self.assertNotIn(
            "zero-inflated spatial effects, and q=4 recovery/coverage evidence remain",
            normalized["debt"],
        )

    def test_student_structured_tiers_fail_closed_to_live_ledger(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        self.assertEqual(by_id["mc-0493"]["evidence_tier"], "diagnostic_only")
        self.assertEqual(by_id["mc-0494"]["evidence_tier"], "point_fit_recovery")
        self.assertEqual(by_id["mc-0495"]["evidence_tier"], "diagnostic_only")
        self.assertEqual(by_id["mc-0641"]["evidence_tier"], "diagnostic_only")
        for cell_id in ("mc-0229", "mc-0364", "mc-0641", "mc-0662", "mc-0667"):
            self.assertEqual(by_id[cell_id]["evidence_tier"], "diagnostic_only")
            self.assertIn("recovery", by_id[cell_id]["claim_boundary"].lower())
            self.assertIn("no_denominator_local_debug_only", by_id[cell_id]["claim_boundary"])
        self.assertEqual(by_id["mc-0248"]["evidence_tier"], "point_fit_recovery")
        self.assertIn("90/90-converged", by_id["mc-0248"]["claim_boundary"])

        no_denominator_recovery = [
            row["cell_id"]
            for row in self.cells
            if row["evidence_tier"] == "point_fit_recovery"
            and "no_denominator_local_debug_only" in row["claim_boundary"]
            and "recovery ladder" not in row["claim_boundary"].lower()
        ]
        self.assertEqual(no_denominator_recovery, [])

        surfaces = "\n".join(
            path.read_text()
            for path in (
                ROOT / "docs/design/01-formula-grammar.md",
                ROOT / "docs/design/03-likelihoods.md",
                ROOT / "docs/design/34-validation-debt-register.md",
                ROOT / "docs/design/41-phase-18-simulation-programme.md",
                ROOT / "docs/design/46-pre-simulation-readiness-matrix.md",
                ROOT / "vignettes/capability-and-limits.Rmd",
                ROOT / "vignettes/distribution-families.Rmd",
                ROOT / "vignettes/formula-grammar.Rmd",
                ROOT / "vignettes/implementation-map.Rmd",
            )
        )
        for claim in (
            "diagnostic-only Student-t q1 `nu ~ phylo",
            "intercept-only `mu ~ spatial(1 | ...)`",
            "`mu ~ spatial(1 + x | ...)` is recovery-grade",
            "Four tiers, defined once",
            "fixed-`zi` Poisson",
            "diagnostic-only fixed-`zi` NB2",
        ):
            self.assertIn(claim, surfaces)
        for stale in (
            "exact recovery-grade Student-t q1 `nu ~ phylo",
            "Student-t `nu ~ phylo(1 | id, tree = tree)` intercept at local point-fit/recovery grade",
            "exact q=1 `mu ~ spatial()` and `nu ~ phylo()` recovery-grade gates",
            "Student-t `nu ~ phylo()`, ordinal `mu ~ phylo()`, beta `animal()` on `mu`/`sigma`, Student-t `mu ~ spatial()`",
        ):
            self.assertNotIn(stale, surfaces)

    def test_spatial_inflation_tiers_propagate_across_current_surfaces(self):
        surfaces = "\n".join(
            path.read_text()
            for path in (
                ROOT / "README.md",
                ROOT / "ROADMAP.md",
                ROOT / "NEWS.md",
                ROOT / "docs/design/03-likelihoods.md",
                ROOT / "docs/design/45-cross-dpar-correlation-gate.md",
                ROOT / "docs/design/59-structural-slope-and-non-gaussian-map.md",
                ROOT / "docs/design/80-four-week-random-slope-digital-twin-sprint.md",
                ROOT / "vignettes/structural-dependence.Rmd",
            )
        )
        for claim in (
            "diagnostic-only zero-inflated Poisson `zi ~ spatial(1 | id, coords = coords)`",
            "diagnostic-only fixed-`zi` Poisson `mu ~ spatial(1 | id, coords = coords)`",
            "diagnostic-only fixed-`zi` NB2 `mu ~ spatial(1 | id, coords = coords)`",
            "diagnostic-only fixed-`zi` `mu ~ spatial()` intercept gate",
        ):
            self.assertIn(claim, surfaces)
        for stale in (
            "zero-inflation beyond the exact Poisson q1 `zi ~ spatial()` gate",
            "three later Q-Series rows add local fit-only/extractor evidence",
            "zero-inflated NB2 random effects remain planned.",
        ):
            self.assertNotIn(stale, surfaces)

    def test_single_smoke_routes_never_read_as_recovery_grade(self):
        active_paths = (
            ROOT / "README.md",
            ROOT / "ROADMAP.md",
            ROOT / "docs/design/01-formula-grammar.md",
            ROOT / "docs/design/02-family-registry.md",
            ROOT / "docs/design/03-likelihoods.md",
            ROOT / "docs/design/79-supported-nongaussian-evidence-goal.md",
            ROOT / "docs/dev-log/known-limitations.md",
            ROOT / "vignettes/capability-and-limits.Rmd",
            ROOT / "vignettes/distribution-families.Rmd",
            ROOT / "vignettes/formula-grammar.Rmd",
            ROOT / "vignettes/implementation-map.Rmd",
            ROOT / "vignettes/source-map.Rmd",
        )
        active_paths += tuple(sorted((ROOT / "docs/design").glob("*.md")))
        surfaces = "\n".join(path.read_text() for path in active_paths)
        forbidden = (
            "recovery-grade q=1 Poisson `zi ~ spatial",
            "recovery-grade Poisson `zi ~ spatial",
            "point/recovery fixed-`zi` Poisson `mu ~ spatial",
            "fixed-`zi` Poisson at point/recovery grade",
            "recovery-grade q1 `hu ~ relmat",
            "recovery-grade truncated-NB2 q1 `hu ~ relmat",
            "one exact Poisson q1 `zi ~ spatial()` intercept is recovery-grade",
            "recovery-grade q1 truncated-NB2 `hu ~ relmat",
            "cumulative-logit q1 `mu ~ phylo()` intercept at recovery grade",
            "cumulative-logit q1 phylogenetic `mu` is point/recovery-grade",
            "local fit-only recovery evidence",
        )
        for stale in forbidden:
            self.assertNotIn(stale, surfaces, stale)

        for claim in (
            "diagnostic-only q=1 Poisson `zi ~ spatial",
            "diagnostic-only q1 `hu ~ relmat",
            "diagnostic-only q1 `mu ~ phylo",
            "diagnostic-only fixed-`zi` Poisson",
        ):
            self.assertIn(claim, surfaces, claim)

    def test_provider_tutorials_name_exact_nongaussian_rows(self):
        phylo = " ".join(
            (ROOT / "vignettes/phylogenetic-models.Rmd").read_text().split()
        )
        for claim in (
            "Poisson has no residual `sigma` formula",
            "NB2 overdispersion deviations",
            "Student-t tail-weight deviations",
            "cumulative-logit location deviations",
            "unlabelled intercept plus one independent slope at recovery grade",
        ):
            self.assertIn(claim, phylo)
        self.assertNotIn("count families have no residual `sigma` formula", phylo)

        animal = " ".join(
            (ROOT / "vignettes/animal-models.Rmd").read_text().split()
        )
        self.assertIn(
            "Poisson, NB2, and beta `mu` accept an unlabelled intercept plus one independent slope",
            animal,
        )
        self.assertIn("beta `sigma` accepts an intercept only", animal)
        self.assertNotIn("a `beta()` animal intercept in `mu` or `sigma`", animal)

        relmat = " ".join(
            (ROOT / "vignettes/relmat-known-matrices.Rmd").read_text().split()
        )
        for claim in (
            "`Gamma()`, `poisson()`, and `nbinom2()` each accept a `mu` intercept plus one independent slope",
            "`nbinom2()` also accepts a `sigma` intercept plus one independent slope",
        ):
            self.assertIn(claim, relmat)
        self.assertIn(
            "diagnostic-only intercept-only `hu` gate",
            relmat,
        )
        self.assertIn(
            "it does not establish point-estimate recovery",
            relmat,
        )
        self.assertNotIn(
            "structured gate at recovery grade. Trust the point estimate",
            relmat,
        )

    def test_active_qseries_surfaces_keep_debug_only_routes_diagnostic(self):
        route_ids = (
            "qseries_student_mu_spatial_rejected",
            "qseries_ordinal_mu_phylo_rejected",
            "qseries_student_nu_phylo_rejected",
            "qseries_poisson_zi_spatial_rejected",
            "qseries_truncnbinom2_hu_relmat_rejected",
            "qseries_count_mu_noncanonical_term_rejected",
            "qseries_count_mu_labelled_q2_rejected",
            "qseries_count_mu_structured_plus_ordinary_rejected",
            "qseries_count_mu_zeroinflated_poisson_structured_rejected",
            "qseries_count_mu_zeroinflated_nbinom2_structured_rejected",
        )
        active_surfaces = (
            ROOT / "docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv",
            ROOT / "docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv",
            ROOT / "docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv",
        )
        for path in active_surfaces:
            with path.open(newline="") as handle:
                rows = list(csv.DictReader(handle, delimiter="\t"))
            for route_id in route_ids:
                matching = [row for row in rows if route_id in row.values()]
                self.assertEqual(len(matching), 1, f"{path}: {route_id}")
                row = matching[0]
                if "fit_status" in row:
                    self.assertEqual(row["fit_status"], "diagnostic_only")
                if "v1_release_role" in row:
                    self.assertIn("diagnostic candidate", row["v1_release_role"])
                joined = " ".join(row.values())
                self.assertIn("diagnostic", joined.lower())
                self.assertIn("does not establish point-estimate recovery", joined)
                self.assertNotIn("local fit-only recovery", joined.lower())
        status = (
            ROOT / "docs/dev-log/release-audits/q-series-v1-release-status.md"
        ).read_text()
        self.assertIn("27 non-Gaussian recovery\nrows", status)
        self.assertIn("10 non-Gaussian diagnostic-only rows", status)
        self.assertIn("Basic-distribution recovery evidence | 27/37", status)
        self.assertIn("Basic-distribution diagnostic only | 10/37", status)
        preflight = (
            ROOT / "docs/dev-log/release-audits/q-series-v1-preflight-report.md"
        ).read_text()
        self.assertIn("Basic-distribution recovery evidence | 27/37", preflight)
        self.assertIn("Basic-distribution diagnostic only | 10/37", preflight)

        public = {
            "README": (ROOT / "README.md").read_text(),
            "ROADMAP": (ROOT / "ROADMAP.md").read_text(),
            "NEWS": (ROOT / "NEWS.md").read_text(),
            "capability": (
                ROOT / "vignettes/capability-and-limits.Rmd"
            ).read_text(),
        }
        self.assertIn("Poisson slope-only `mu ~ spatial(0 + x", public["README"])
        self.assertIn("Poisson `mu ~ spatial(1 | site", public["README"])
        self.assertIn("ten Q-Series v1.0 rows", public["ROADMAP"])
        self.assertIn("ten row-specific\n  diagnostic-only gates", public["NEWS"])
        self.assertIn("Ten exact structured routes", public["capability"])
        llms_path = ROOT / "pkgdown-site/llms.txt"
        llms = llms_path.read_text() if llms_path.exists() else None
        if llms is not None:
            self.assertIn("Poisson slope-only `mu ~ spatial(0 + x", llms)
            self.assertIn("Poisson `mu ~ spatial(1 | site", llms)

        count = (ROOT / "vignettes/count-nbinom2.Rmd").read_text()
        self.assertIn("diagnostic-only probability-component", count)
        self.assertNotIn("recovery-grade probability-component", count)
        count_surfaces = {
            "README": public["README"],
            "count source": count,
        }
        count_rendered_path = ROOT / "pkgdown-site/articles/count-nbinom2.md"
        if count_rendered_path.exists():
            count_surfaces["count rendered"] = count_rendered_path.read_text()
        if llms is not None:
            count_surfaces["llms"] = llms
        for name, text in count_surfaces.items():
            normalized = " ".join(text.split())
            self.assertIn("fixed-`zi`", normalized, name)
            self.assertIn("Poisson", normalized, name)
            self.assertIn("NB2", normalized, name)
            self.assertIn("diagnostic-only", normalized, name)
            self.assertIn(
                "do not establish point-estimate recovery, intervals, or coverage",
                normalized,
                name,
            )
        model_map = (ROOT / "vignettes/model-map.Rmd").read_text()
        self.assertIn(
            "both fixed-`zi` spatial-`mu` gates have no recovery, interval, or coverage promotion",
            model_map,
        )
        spatial = (ROOT / "vignettes/spatial-models.Rmd").read_text()
        self.assertIn("Response units per depth unit", spatial)
        self.assertIn("Spatial intercept and slope SDs have different units", spatial)

    def test_capability_vignette_names_arc1a_reml_boundary(self):
        vignette = (ROOT / "vignettes/capability-and-limits.Rmd").read_text()
        self.assertIn(
            "Gaussian structured random effects: eleven anchor cells",
            vignette,
        )
        for provider in ("spatial", "animal", "relmat"):
            self.assertIn(f"fit_{provider}_reml <- drmTMB(", vignette)
        self.assertIn("animal `A`, and relmat `K`", (ROOT / "NEWS.md").read_text())
        self.assertIn(
            "Pedigree and `Ainv` animal inputs and relmat `Q`",
            vignette,
        )

    def test_provider_vignettes_show_exact_arc1a_reml_calls_and_sd_semantics(self):
        vignette = (ROOT / "vignettes/capability-and-limits.Rmd").read_text()
        providers = {
            "spatial": (ROOT / "vignettes/spatial-models.Rmd").read_text(),
            "animal": (ROOT / "vignettes/animal-models.Rmd").read_text(),
            "relmat": (ROOT / "vignettes/relmat-known-matrices.Rmd").read_text(),
        }
        for name, text in providers.items():
            self.assertIn(f"fit_{name}_reml <- drmTMB(", text)
            self.assertIn("REML = TRUE", text)
            self.assertIn("sigma ~ 1", text)
        self.assertIn("animal(1 + x | individual, A = A)", providers["animal"])
        self.assertIn("representation-parity evidence only", providers["animal"])
        self.assertIn("relmat(1 + x | line, K = K)", providers["relmat"])
        self.assertIn("representation-parity evidence only", providers["relmat"])
        self.assertIn("individual `i` has marginal SD `s sqrt(A[i, i])`", providers["animal"])
        self.assertIn("animal_scale * sqrt(diag(A))", providers["animal"])
        self.assertNotIn("Read the fitted animal-model location SD", providers["animal"])
        self.assertNotIn("animal endpoint standard deviations", providers["animal"])
        self.assertIn(
            "Arc 1a additionally accepts a\n"
            "pure-`mu`, univariate `spatial()`, `animal()`, or `relmat()` term",
            vignette,
        )
        self.assertNotIn("eight anchor cells", vignette.lower())
        self.assertNotIn(
            "rejects non-phylogenetic\nmean-side structured effects",
            vignette,
        )
        self.assertIn(
            "q1 `mu` and the exact phylo/relmat slope-only q2 `mu1:x`/`mu2:x` SD rows use\n"
            "the default location-axis bias-corrected, small-sample-t Wald channel",
            vignette,
        )
        self.assertIn(
            "raw uncorrected log-SD Wald-z",
            vignette,
        )
        self.assertIn("diagnostic-only at `g = 8`", vignette)
        self.assertIn("the covariance is `s_j^2 K_h`", vignette)
        self.assertIn("marginal\nSD `s_j sqrt(K_h[ii])`", vignette)
        self.assertIn("`M` is the number of structured levels", vignette)
        self.assertNotIn(
            "structured-RE anchor cells above, `method = \"profile\"`",
            vignette,
        )

    def test_relmat_vignette_uses_sd_squared_covariance_contract(self):
        vignette = (ROOT / "vignettes/relmat-known-matrices.Rmd").read_text()
        self.assertIn("latent covariance is `s^2 G`", vignette)
        self.assertIn("marginal SD `s sqrt(G[i, i])`", vignette)
        self.assertIn("latent covariance is `s^2 C`", vignette)
        self.assertIn("marginal SD\n`s sqrt(C[i, i])`", vignette)
        self.assertIn("level `i` has marginal SD `s sqrt(K[i, i])`", vignette)
        self.assertIn("node_multiplier <- sqrt(diag(K))", vignette)
        self.assertIn("relmat_sd$lower[-1]", vignette)
        self.assertNotIn("Read the fitted known-matrix location SD", vignette)
        self.assertNotIn("known-matrix location SD from a univariate", vignette)
        self.assertNotIn("known-matrix endpoint standard deviations", vignette)
        self.assertNotIn("SD that multiplies that known relatedness matrix", vignette)

        count_vignette = (ROOT / "vignettes/count-nbinom2.Rmd").read_text()
        count_intro = count_vignette.split("The source motivation", maxsplit=1)[0]
        self.assertIn(
            "exact q1 structured `sigma`\nintercept-plus-one-slope routes",
            count_intro,
        )
        self.assertIn("at recovery grade", count_intro)

        historical_count = (
            ROOT / "docs/design/67-sdstar-p8-poisson-q1.md"
        ).read_text()
        self.assertIn("Status supersession (2026-07-14)", historical_count)
        self.assertIn(
            "exact q1 NB2 structured `sigma`\n> intercept-plus-one-slope routes at recovery grade",
            historical_count,
        )
        historical_nb2 = (
            ROOT / "docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md"
        ).read_text()
        self.assertIn("Status supersession (2026-07-14)", historical_nb2)
        self.assertIn(
            "phylogenetic `sigma` intercept-plus-one-slope route at recovery grade",
            historical_nb2,
        )
        self.assertNotIn("estimates the SD of the latent site field", vignette)

    def test_phylogenetic_spatial_vignette_uses_row_specific_intervals(self):
        vignette = (ROOT / "vignettes/phylogenetic-spatial.Rmd").read_text()
        self.assertIn(
            "exact phylo/relmat slope-only q2 `mu1:x`/`mu2:x` SD rows\n"
            "use the default location-axis bias-corrected, small-sample-t Wald channel",
            vignette,
        )
        self.assertIn("diagnostic-only at `g = 8`", vignette)
        self.assertNotIn(
            "profile-likelihood intervals are preferable to symmetric Wald intervals",
            vignette,
        )
        self.assertNotIn("follow it with a targeted profile", vignette)
        for fit_name in (
            "fit_animal_q2_known",
            "fit_relmat_q2_known",
            "fit_spatial_mean",
            "fit_phylo_sd",
            "fit_phylo_q4",
            "fit_biv_phylo",
            "fit_biv_sd_phylo",
            "fit_biv_phylo_q4",
        ):
            self.assertNotRegex(
                vignette,
                rf"(?s)corpairs\(\s*{fit_name}[^\)]*conf\.int\s*=\s*TRUE",
            )
        self.assertNotIn("Eye is a 95% profile interval", vignette)
        self.assertNotIn("a direct profile interval is available", vignette)

    def test_intercept_q2_tutorials_do_not_present_unvalidated_intervals(self):
        tutorials = {
            "animal-models.Rmd": ("fit_animal_q2", "fit_animal_q2_example"),
            "relmat-known-matrices.Rmd": (
                "fit_relmat_q2",
                "fit_relmat_q2_example",
            ),
            "spatial-models.Rmd": ("fit_spatial_q2_example",),
            "bivariate-coscale.Rmd": ("fit_group",),
        }
        for name, fit_names in tutorials.items():
            vignette = (ROOT / "vignettes" / name).read_text()
            for fit_name in fit_names:
                self.assertNotRegex(
                    vignette,
                    rf"(?s)corpairs\(\s*{fit_name}[^\)]*conf\.int\s*=\s*TRUE",
                )
            self.assertNotIn("Eye is a 95% profile interval", vignette)
            self.assertNotIn("has profile interval support", vignette)
            self.assertNotRegex(
                vignette,
                r"(?s)corpairs\([^\)]*(?:ystep|ytol)\s*=",
            )
        workflow = (ROOT / "vignettes/model-workflow.Rmd").read_text()
        self.assertIn(
            "profile availability alone is not that evidence",
            workflow,
        )
        phylo = (ROOT / "vignettes/phylogenetic-spatial.Rmd").read_text()
        self.assertIn(
            "Neither predictor-dependent q2 example above\n"
            "has coverage-backed interval validation",
            phylo,
        )
        self.assertNotIn(
            "For a 95% interval at a chosen group-level\npredictor value",
            phylo,
        )
        self.assertNotRegex(
            phylo,
            r"(?s)corpairs\([^\)]*(?:ystep|ytol)\s*=",
        )
        animal = (ROOT / "vignettes/animal-models.Rmd").read_text()
        self.assertNotIn(
            'confint(fit_animal, parm = "variance_components")',
            animal,
        )
        self.assertNotIn("The SD plot is model-estimated\nuncertainty", animal)
        spatial = (ROOT / "vignettes/spatial-models.Rmd").read_text()
        self.assertNotIn(
            'confint(fit_spatial_slope, parm = "variance_components")',
            spatial,
        )
        self.assertIn("q=4 correlations are derived and unavailable for intervals", spatial)
        relmat = (ROOT / "vignettes/relmat-known-matrices.Rmd").read_text()
        self.assertIn("relmat(1 | line, K = K)", relmat)
        bivariate = (ROOT / "vignettes/bivariate-coscale.Rmd").read_text()
        self.assertIn("group_cor_dpar <-", bivariate)
        self.assertNotIn("response-scale correlation interval used in the plot", bivariate)

    def test_arc1a_news_defines_discrete_campaign_symbols(self):
        news = (ROOT / "NEWS.md").read_text()
        self.assertIn("`M` is the number of structured levels", news)
        self.assertIn(
            "`n_each` is the number of observations per structured level",
            news,
        )
        self.assertIn(
            "Historical note, superseded by the cell-specific 0.6.0 guidance",
            news,
        )
        self.assertNotIn("are the headline recommended inference method", news)
        self.assertNotIn(
            "profile-likelihood confidence intervals remain the recommended interval route",
            news,
        )
        self.assertNotIn(
            "Mean-side non-phylogenetic structured effects under REML remain unvalidated",
            news,
        )
        self.assertNotIn(
            "non-phylogenetic structured effects (spatial, animal, relatedness) under REML remain rejected",
            news,
        )
        self.assertIn(
            "independent intercept-plus-one-numeric-\n  slope REML cells",
            news,
        )
        roadmap = (ROOT / "ROADMAP.md").read_text()
        self.assertIn(
            "Arc 1a admits REML only for the exact unlabelled intercept and independent intercept-plus-one-slope spatial/animal/relmat cells",
            roadmap,
        )
        self.assertNotIn(
            "intercept-plus-one-slope phylo/spatial/animal/relmat cells",
            roadmap,
        )
        self.assertNotIn(
            "intervals, coverage, REML, AI-REML, and slope correlations remain planned",
            roadmap,
        )

    def test_model_map_marks_intercept_q2_profiles_diagnostic(self):
        model_map = (ROOT / "vignettes/model-map.Rmd").read_text()
        self.assertIn(
            "profile availability alone is diagnostic and does not validate an interval",
            model_map,
        )
        self.assertIn("derived and unavailable for intervals", model_map)
        self.assertIn(
            "this intercept-only q2\nrow is not interval-validated",
            model_map,
        )
        self.assertNotIn(
            "when a direct profile interval is worth the extra compute",
            model_map,
        )

    def test_native_sigma_phylo_reml_machine_surfaces_are_admission_scoped(self):
        gate = (
            ROOT
            / "docs/dev-log/dashboard/structured-re-reml-scope-gate.tsv"
        ).read_text()
        status = (
            ROOT
            / "docs/dev-log/dashboard/structured-re-native-reml-scope-status.tsv"
        ).read_text()
        finish = (
            ROOT
            / "docs/dev-log/dashboard/structured-re-finish-100-slices.tsv"
        ).read_text()
        self.assertIn(
            "Native TMB pure sigma-side phylogenetic REML is implemented",
            gate,
        )
        self.assertIn(
            "q1_sigma_native_reml_admission\tSR153",
            status,
        )
        self.assertIn("\tREML\tpoint_fit_recovery\t", status)
        self.assertIn(
            "q1 sigma-side phylogenetic REML admission",
            finish,
        )
        for surface in (gate, status, finish):
            self.assertNotIn("sigma-side native REML rejection", surface)
            self.assertNotIn("Native TMB sigma-side REML remains planned", surface)

    def test_native_q2_q4_phylo_reml_machine_surfaces_are_admission_scoped(self):
        gate = (
            ROOT / "docs/dev-log/dashboard/structured-re-reml-scope-gate.tsv"
        ).read_text()
        status = (
            ROOT / "docs/dev-log/dashboard/structured-re-native-reml-scope-status.tsv"
        ).read_text()
        audit = (
            ROOT
            / "docs/dev-log/dashboard/structured-re-q4-reml-requested-effective-audit.tsv"
        ).read_text()
        target_map = (
            ROOT / "docs/dev-log/dashboard/phylo-q2-q4-target-map.tsv"
        ).read_text()
        finish = (
            ROOT / "docs/dev-log/dashboard/structured-re-finish-100-slices.tsv"
        ).read_text()

        self.assertIn("reml_q2_gate", gate)
        self.assertIn("reml_q4_gate", gate)
        self.assertIn("q2_native_reml_admission\tSR154", status)
        self.assertIn("q4_native_reml_admission\tSR155", status)
        self.assertIn("native_tmb_q4_reml_admission", audit)
        self.assertIn("q2_reml_point_fit", target_map)
        self.assertIn("native_reml_recovery", target_map)
        self.assertIn("q2 native phylogenetic REML admission", finish)
        self.assertIn("q4 native phylogenetic REML admission", finish)

        combined = "\n".join((gate, status, audit, target_map, finish))
        for stale in (
            "native_tmb_q4_reml_rejection",
            "unsupported_no_native_q4_reml",
            "q2_reml_unimplemented",
            "native_reml_rejected",
            "Q2 REML is not implemented by current native route",
            "Native q4 REML and HSquared AI-REML are not promoted",
        ):
            self.assertNotIn(stale, combined)

    def test_q2_profile_example_is_diagnostic_not_reporting_guidance(self):
        vignette = (ROOT / "vignettes/phylogenetic-spatial.Rmd").read_text()
        self.assertIn(
            "The intercept-only bivariate q2 example below is diagnostic-only under\n"
            "both Wald and profile channels",
            vignette,
        )
        self.assertIn(
            "Do not report\neither interval above as validated for this intercept-only q2 fit",
            vignette,
        )
        self.assertIn(
            "q2 reporting channel belongs only to the exact phylo/relmat slope-only SD rows",
            vignette,
        )
        self.assertNotIn(
            'corpairs(fit_phylo_mean, level = "phylogenetic", conf.int = TRUE)',
            vignette,
        )
        self.assertNotIn("important enough for final\nreporting", vignette)

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
