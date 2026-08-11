"""Tests for the deterministic capability-ledger generator."""

from __future__ import annotations

import importlib.util
import copy
import csv
import re
import shutil
import subprocess
import tempfile
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "capability_ledger", ROOT / "tools/capability_ledger.py"
)
assert SPEC and SPEC.loader
ledger = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ledger)
INTERNAL_ROADMAP = ROOT / "docs" / "dev-log" / "internal-roadmap.md"


class CapabilityLedgerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cells, cls.evidence, cls.transitions = ledger.load_sources()

    def test_denominators_and_truthful_missing_response_state(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        missing = [row for row in self.cells if row["axis"] == "missing_response"]
        association = [row for row in self.cells if row["axis"] == "association"]
        # 697 = the 676 frozen census rows, mc-0260m, ten C14 q2-plus boundary
        # leaves paired with the exact q1 mu/sigma structured leaves, and ten
        # C18 q2-plus boundary leaves paired with the exact q1 zoi/coi atom
        # leaves. Splitting itself promotes nothing (not_implemented stayed
        # at 17 immediately after the split); C18 separately promotes seven
        # of the ten atom leaves from recovery evidence, leaving 10.
        # 697 -> 699: Arc 4b splits mc-0207 (a single legacy row representing
        # q4/q6/q8 ordinary bivariate REML blocks) into exact per-q leaves;
        # mc-0207 becomes the q4 leaf in place, mc-0715/mc-0716 are new q6/q8
        # leaves. The split promotes nothing.
        self.assertEqual(len(model), 699)
        self.assertEqual(len(missing), 18)
        self.assertEqual(len(association), 6)
        by_association = {row["cell_id"]: row for row in association}
        self.assertEqual(
            by_association["as-0004"]["evidence_tier"],
            "inference_ready_with_caveats",
        )
        self.assertEqual(by_association["as-0004"]["dpar"], "alpha")
        self.assertEqual(
            sum(
                row["evidence_tier"] == "interval_feasible"
                for row in association
            ),
            5,
        )
        self.assertEqual(
            sum(
                row["evidence_tier"] == "inference_ready_with_caveats"
                for row in association
            ),
            1,
        )
        self.assertTrue(all(
            row["capability_status"] == "implemented" for row in association
        ))
        self.assertTrue(all(
            row["work_status"] == "verified" for row in association
        ))
        self.assertTrue(all(row["primary_evidence_id"] for row in association))
        self.assertEqual(
            ledger.TIER_ORDER[:3],
            ["supported", "inference_ready_with_caveats", "interval_feasible"],
        )
        # 2026-08-11 D-43 panel (Fisher/Noether/Rose) + addendum: eight
        # exhaustively campaigned routes promote G3 (point_fit_recovery) ->
        # G5 (inference_ready_with_caveats); the remaining ten admitted
        # routes stay at G3. See docs/dev-log/2026-08-11-g5-admission-set-exhaustiveness.md.
        g5_promoted = {
            "gaussian", "biv_gaussian", "gamma", "beta_binomial",
            "binomial", "zero_one_beta", "zi_poisson", "lognormal",
        }
        self.assertEqual(
            {
                row["family_route"]
                for row in missing
                if row["test_gate"] in ("G3", "G5") and row["work_status"] == "verified"
            },
            ledger.ADMITTED,
        )
        self.assertEqual(
            {
                row["family_route"]
                for row in missing
                if row["test_gate"] == "G5" and row["work_status"] == "verified"
            },
            g5_promoted,
        )
        self.assertEqual(
            {
                row["family_route"]
                for row in missing
                if row["test_gate"] == "G3" and row["work_status"] == "verified"
            },
            ledger.ADMITTED - g5_promoted,
        )
        self.assertEqual(
            {row["family_route"] for row in missing if row["test_gate"] == "G0"},
            {route for _, route, _, _, _ in ledger.ROUTES} - ledger.ADMITTED,
        )
        by_route = {row["family_route"]: row for row in missing}
        self.assertEqual(by_route["zi_poisson"]["test_gate"], "G5")
        self.assertEqual(by_route["zi_nbinom2"]["test_gate"], "G3")
        self.assertEqual(by_route["hurdle_nbinom2"]["test_gate"], "G3")
        self.assertEqual(
            sum(row["work_status"] == "verified" for row in missing),
            len(ledger.ADMITTED),
        )

    def test_c14_boundary_restoration_is_source_pinned_and_non_promoting(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        by_id = {row["cell_id"]: row for row in model}
        source_ids = {
            row["cell_id"] for row in ledger.c14_boundary_source_rows()
        }
        self.assertEqual(len(source_ids), ledger.C14_BOUNDARY_COUNT)
        self.assertTrue(source_ids <= set(by_id))
        self.assertEqual(
            {
                cell_id for cell_id in source_ids
                if by_id[cell_id]["capability_status"] == "implemented"
            },
            ledger.CAPABILITY_TRUTH_C14_IMPLEMENTED_OVERRIDES,
        )
        for cell_id in source_ids:
            row = by_id[cell_id]
            if cell_id in ledger.CAPABILITY_TRUTH_C14_IMPLEMENTED_OVERRIDES:
                self.assertEqual(row["work_status"], "verified")
                self.assertEqual(row["evidence_tier"], "diagnostic_only")
                continue
            self.assertEqual(row["capability_status"], "rejected_by_design")
            self.assertEqual(row["work_status"], "deferred")
            self.assertEqual(row["evidence_tier"], "none")

    def test_07_capability_truth_cells_are_exact_and_evidence_bound(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        evidence = {row["evidence_id"]: row for row in self.evidence}
        expected = {
            "mc-0058": ("rejected_by_design", "deferred", "none", "ev-mc-0058-capability-truth-rejection"),
            "mc-0060": ("implemented", "verified", "diagnostic_only", "ev-mc-0060-capability-truth-o2"),
            "mc-0062": ("implemented", "verified", "diagnostic_only", "ev-mc-0062-capability-truth-o2"),
            "mc-0068": ("rejected_by_design", "deferred", "none", "ev-mc-0068-capability-truth-rejection"),
            "mc-0227": ("implemented", "verified", "point_fit_recovery", "ev-mc-0227-arc2b"),
        }
        for cell_id, state in expected.items():
            row = by_id[cell_id]
            self.assertEqual(
                tuple(row[field] for field in (
                    "capability_status", "work_status", "evidence_tier",
                    "primary_evidence_id",
                )),
                state,
            )
            self.assertEqual(row["tranche_id"], "07-capability-truth")
            self.assertEqual(row["updated_date"], "2026-08-08")

        for cell_id in ("mc-0060", "mc-0062"):
            comparator = evidence[f"ev-{cell_id}-capability-truth-o2"]
            self.assertEqual(comparator["evidence_class"], "external_comparator")
            self.assertIn("glmmTMB", comparator["run_id"])
            self.assertIn("WEAK INDEPENDENCE", comparator["claim_boundary"])
            self.assertIn("same joint-Laplace", comparator["claim_boundary"])

        self.assertIn(
            "unavailable through drmTMB()",
            evidence["ev-mc-0227-o3"]["claim_boundary"],
        )
        transitions = {row["transition_id"] for row in self.transitions}
        self.assertEqual(
            {
                f"tr-{cell_id}-07-capability-truth"
                for cell_id in ledger.CAPABILITY_TRUTH_CELL_IDS
            } - transitions,
            set(),
        )

    def test_internal_o3_evidence_cannot_grant_public_reporting_permission(self):
        cells = copy.deepcopy(self.cells)
        row = next(item for item in cells if item["cell_id"] == "mc-0227")
        row["primary_evidence_id"] = "ev-mc-0227-o3"
        row["evidence_tier"] = "inference_ready_with_caveats"
        with self.assertRaisesRegex(
            SystemExit,
            "internal estimator evidence grants public reporting permission",
        ):
            ledger.validate(cells, self.evidence, self.transitions)

    def test_c14_structured_zero_one_beta_leaves_preserve_q2plus_boundaries(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        self.assertEqual(len(ledger.C14_ZOB_LEAF_TAXONOMY), 10)
        for index, (q1_id, q2plus_id) in enumerate(ledger.C14_ZOB_LEAF_TAXONOMY):
            q1 = by_id[q1_id]
            q2plus = by_id[q2plus_id]
            self.assertEqual(q1["q_gate"], "q1")
            self.assertEqual(q1["route_variant"], "c14_exact_q1_structured_intercept")
            if q1_id in {
                "mc-0583", "mc-0584", "mc-0585", "mc-0586", "mc-0587",
                "mc-0593", "mc-0594", "mc-0595", "mc-0596", "mc-0597",
            }:
                self.assertEqual(q1["capability_status"], "implemented")
                self.assertEqual(q1["work_status"], "verified")
                # 135-trace promoted relmat/spatial sigma leaves only
                # (mc-0595, mc-0596). Sibling structured-sigma leaves stay
                # point_fit_recovery after honest WITHHOLD.
                if q1_id in {"mc-0595", "mc-0596"}:
                    self.assertEqual(q1["evidence_tier"], "interval_feasible")
                else:
                    self.assertEqual(q1["evidence_tier"], "point_fit_recovery")
            else:
                self.assertEqual(q1["capability_status"], "not_implemented")
                self.assertEqual(q1["work_status"], "backlog")
            self.assertEqual(q2plus["q_gate"], "q2plus")
            self.assertEqual(q2plus["route_variant"], "c14_q2plus_structured_boundary")
            self.assertEqual(q2plus["capability_status"], "rejected_by_design")
            self.assertEqual(q2plus["work_status"], "deferred")
            self.assertEqual(q2plus["source_order"], str(695 + index))
            self.assertEqual(q1["dpar"], q2plus["dpar"])
            self.assertEqual(q1["structure_provider"], q2plus["structure_provider"])

    def test_c14_candidate_manifest_is_complete_and_source_resolved(self):
        manifest = (
            ROOT / "docs/dev-log/dashboard/capability-ledger/"
            "c14-candidate-evidence-manifest.tsv"
        )
        with manifest.open(newline="", encoding="utf-8") as handle:
            rows = list(csv.DictReader(handle, delimiter="\t"))
        expected = {
            "mc-0418", "mc-0425", "mc-0436", "mc-0446", "mc-0450", "mc-0454",
            "mc-0568", "mc-0569", "mc-0576", "mc-0577",
            "mc-0583", "mc-0584", "mc-0585", "mc-0586", "mc-0587",
            "mc-0593", "mc-0594", "mc-0595", "mc-0596", "mc-0597",
        }
        self.assertEqual({row["cell_id"] for row in rows}, expected)
        self.assertTrue(all((ROOT / row["retained_receipt"]).exists() for row in rows))
        self.assertTrue(all(row["c14_decision"] for row in rows))

    def test_c14_receipt_equivalence_keeps_raw_sources_separate(self):
        ledger.check_c14_receipt_equivalence()

    def test_c17_c14_bridge_is_current_source_and_fail_closed(self):
        current = ledger.c14_model15_source_fingerprint()
        ledger.check_c17_c14_current_source_compatibility(current)

        original = ledger.C17_C14_CURRENT_SOURCE_COMPATIBILITY
        with tempfile.TemporaryDirectory() as directory:
            tampered = Path(directory) / "compatibility.tsv"
            rows = ledger.read_tsv(original)
            rows[0]["passed"] = "3"
            tampered.write_bytes(ledger.tsv_bytes(list(rows[0]), rows))
            ledger.C17_C14_CURRENT_SOURCE_COMPATIBILITY = tampered
            try:
                with self.assertRaisesRegex(SystemExit, "did not pass 4/4"):
                    ledger.check_c17_c14_current_source_compatibility(current)
            finally:
                ledger.C17_C14_CURRENT_SOURCE_COMPATIBILITY = original

    def test_c17_failure_modes_give_opposite_fingerprint_instructions(self):
        """The two C17 failures need opposite remediation; say so, don't converge.

        A fingerprint mismatch means the authenticated model-15 surface moved, so
        source_fingerprint must be updated after re-measuring. A blob mismatch
        means only a pinned file moved and the surface did not, so updating
        source_fingerprint there would widen the claim past what was re-measured.
        Both once reported a bare one-line message, which is how a real model-15
        change came to look identical to a merely stale receipt.
        """
        current = ledger.c14_model15_source_fingerprint()
        recorded = ledger.read_tsv(ledger.C17_C14_CURRENT_SOURCE_COMPATIBILITY)[0][
            "source_fingerprint"
        ]

        with self.assertRaises(SystemExit) as caught:
            ledger.check_c17_c14_current_source_compatibility("0" * 64)
        fingerprint_message = str(caught.exception)
        self.assertIn("current model-15 fingerprint differs", fingerprint_message)
        self.assertIn("update source_fingerprint", fingerprint_message)
        # Assert on the two values the message actually reports: what the manifest
        # RECORDS, and what it was HANDED. Asserting the live fingerprint appears
        # would couple this test to the ledger being up to date, so it would fail
        # on precisely the stale tree it exists to explain -- observed for real on
        # the MSPL and offset branches, where recorded and live legitimately differ
        # until re-certification.
        self.assertIn(recorded, fingerprint_message)
        self.assertIn("0" * 64, fingerprint_message)

        original = ledger.C17_C14_CURRENT_SOURCE_COMPATIBILITY
        rows = ledger.read_tsv(original)
        receipt_source = ROOT / Path(rows[0]["provenance_path"]).parent
        receipt = ROOT / "tmp_c17_failure_mode_probe"
        with tempfile.TemporaryDirectory() as directory:
            shutil.copytree(receipt_source, receipt)
            try:
                provenance = receipt / "provenance.tsv"
                provenance.write_text(
                    "\n".join(
                        "git_blob:R/methods.R\t" + "d" * 40
                        if line.startswith("git_blob:R/methods.R\t")
                        else line
                        for line in provenance.read_text(encoding="utf-8").splitlines()
                    )
                    + "\n",
                    encoding="utf-8",
                )
                for row in rows:
                    for field, leaf in (
                        ("raw_attempts_path", "raw-attempts.tsv"),
                        ("provenance_path", "provenance.tsv"),
                        ("summary_path", "summary.tsv"),
                    ):
                        row[field] = str((receipt / leaf).relative_to(ROOT))
                tampered = Path(directory) / "compatibility.tsv"
                tampered.write_bytes(ledger.tsv_bytes(list(rows[0]), rows))
                ledger.C17_C14_CURRENT_SOURCE_COMPATIBILITY = tampered
                # Hand it the RECORDED fingerprint, not the live one. The blob
                # check sits behind the fingerprint check, so passing the live
                # value would make this half unreachable whenever the ledger is
                # legitimately stale -- the same coupling fixed above.
                #
                # The manifest deliberately lives outside ROOT here, exactly as
                # the other C17 test arranges it. An unguarded relative_to() in
                # the remediation text raises ValueError, replacing a clean
                # diagnostic with a traceback.
                with self.assertRaises(SystemExit) as caught:
                    ledger.check_c17_c14_current_source_compatibility(recorded)
                blob_message = str(caught.exception)
            finally:
                ledger.C17_C14_CURRENT_SOURCE_COMPATIBILITY = original
                shutil.rmtree(receipt, ignore_errors=True)

        self.assertIn("current source blob differs for R/methods.R", blob_message)
        self.assertIn("LEAVE source_fingerprint alone", blob_message)
        self.assertNotIn("update source_fingerprint", blob_message)

    def test_c17b_promotes_only_the_exact_same_symbol_zoi_slope(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        row = by_id["mc-0577"]
        self.assertEqual(row["capability_status"], "implemented")
        self.assertEqual(row["work_status"], "verified")
        self.assertEqual(row["evidence_tier"], "point_fit_recovery")
        self.assertEqual(row["test_gate"], "G3")
        self.assertEqual(row["primary_evidence_id"], "ev-mc-0577-c17b-recovery")
        self.assertIn("same raw symbol", row["claim_boundary"])
        self.assertIn("Profiles, intervals, coverage", row["next_gate"])

        evidence = {
            item["evidence_id"]: item
            for item in self.evidence
            if item["cell_id"] == "mc-0577"
        }
        for evidence_id in (
            "ev-mc-0577-c17b-contract",
            "ev-mc-0577-c17b-recovery",
        ):
            self.assertEqual(evidence[evidence_id]["reviewed_by"], "Fisher; Noether; Rose")

        transitions = [
            item for item in self.transitions
            if item["transition_id"] == "tr-mc-0577-c17b-promote"
        ]
        self.assertEqual(len(transitions), 1)
        self.assertEqual(transitions[0]["from_work_status"], "backlog")
        self.assertEqual(transitions[0]["to_work_status"], "verified")

    def test_c17c1_promotes_only_the_exact_coi_random_intercept(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        row = by_id["mc-0570"]
        self.assertEqual(row["capability_status"], "implemented")
        self.assertEqual(row["work_status"], "verified")
        self.assertEqual(row["evidence_tier"], "point_fit_recovery")
        self.assertEqual(row["test_gate"], "G3")
        self.assertEqual(row["primary_evidence_id"], "ev-mc-0570-c17c1-recovery")
        self.assertIn("coi ~ 1 + (1 | id)", row["claim_boundary"])
        self.assertIn("Sparse observed zeroes or ones", row["next_gate"])
        for excluded in (
            "Profiles", "intervals", "coverage", "coi slopes",
            "structured/q2-plus", "missing responses", "REML", "AGHQ",
        ):
            self.assertIn(excluded, row["next_gate"])

        evidence = {
            item["evidence_id"]: item
            for item in self.evidence
            if item["cell_id"] == "mc-0570"
        }
        for evidence_id in (
            "ev-mc-0570-c17c1-contract",
            "ev-mc-0570-c17c1-compatibility",
            "ev-mc-0570-c17c1-recovery",
            "ev-mc-0570-c17c1-support-warning",
        ):
            self.assertEqual(evidence[evidence_id]["reviewed_by"], "Fisher; Noether; Rose")
        warning_command = evidence["ev-mc-0570-c17c1-support-warning"]["command"]
        self.assertIn(
            "tools/check-lane-c-c17c1-support-floor-attainability.R",
            warning_command,
        )
        self.assertTrue(
            (ROOT / "tools/check-lane-c-c17c1-support-floor-attainability.R").is_file()
        )
        self.assertIn(
            "strict current-source C14 landing guard accepts only the separate",
            evidence["ev-mc-0570-c17c1-compatibility"]["claim_boundary"],
        )

        transitions = [
            item for item in self.transitions
            if item["transition_id"] == "tr-mc-0570-c17c1-promote"
        ]
        self.assertEqual(len(transitions), 1)
        self.assertEqual(transitions[0]["from_work_status"], "backlog")
        self.assertEqual(transitions[0]["to_work_status"], "verified")

    def test_c17c2_promotes_only_the_exact_coi_same_symbol_slope(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        row = by_id["mc-0578"]
        self.assertEqual(row["capability_status"], "implemented")
        self.assertEqual(row["work_status"], "verified")
        self.assertEqual(row["evidence_tier"], "point_fit_recovery")
        self.assertEqual(row["test_gate"], "G3")
        self.assertEqual(row["primary_evidence_id"], "ev-mc-0578-c17c2-recovery")
        self.assertIn("coi ~ x + (0 + x | id)", row["claim_boundary"])
        self.assertIn("same untransformed raw symbol", row["claim_boundary"])
        for excluded in (
            "Profiles", "intervals", "coverage", "inference readiness",
            "transformed or mismatched slopes", "structured/q2-plus",
            "missing responses", "REML", "AGHQ",
        ):
            self.assertIn(excluded, row["next_gate"])

        evidence = {
            item["evidence_id"]: item
            for item in self.evidence
            if item["cell_id"] == "mc-0578"
        }
        for evidence_id in (
            "ev-mc-0578-c17c2-contract",
            "ev-mc-0578-c17c2-compatibility",
            "ev-mc-0578-c17c2-recovery",
            "ev-mc-0578-c17c2-boundary-spread-warning",
        ):
            self.assertIn(evidence_id, evidence)

        transitions = [
            item for item in self.transitions
            if item["transition_id"] == "tr-mc-0578-c17c2-promote"
        ]
        self.assertEqual(len(transitions), 1)
        self.assertEqual(transitions[0]["from_work_status"], "backlog")
        self.assertEqual(transitions[0]["to_work_status"], "verified")

    def test_c18_promotes_seven_of_ten_structured_atom_leaves(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        evidence_by_id = {row["evidence_id"]: row for row in self.evidence}
        promoted = (
            "mc-0603", "mc-0604", "mc-0605", "mc-0607",
            "mc-0613", "mc-0614", "mc-0617",
        )
        for cell_id in promoted:
            row = by_id[cell_id]
            self.assertEqual(row["capability_status"], "implemented")
            self.assertEqual(row["work_status"], "verified")
            self.assertEqual(row["evidence_tier"], "point_fit_recovery")
            self.assertEqual(row["test_gate"], "G3")
            self.assertEqual(row["tranche_id"], "lane-c-c18-atom-promotion")
            self.assertEqual(row["primary_evidence_id"], f"ev-{cell_id}-c18-recovery")
            self.assertIn("Point-fit recovery only", row["claim_boundary"])
            self.assertIn("NOT profile-, interval-, coverage-", row["claim_boundary"])
            self.assertIn("Profiles, intervals, coverage", row["next_gate"])

            evidence = evidence_by_id[row["primary_evidence_id"]]
            self.assertEqual(evidence["cell_id"], cell_id)
            self.assertEqual(evidence["evidence_class"], "recovery_test")
            self.assertEqual(evidence["result"], "G3_pass")
            self.assertEqual(evidence["replicates"], "4")
            self.assertTrue((ROOT / evidence["path_or_url"]).is_file())

            transitions = [
                item for item in self.transitions
                if item["transition_id"] == f"tr-{cell_id}-c18-promote"
            ]
            self.assertEqual(len(transitions), 1)
            self.assertEqual(transitions[0]["from_work_status"], "backlog")
            self.assertEqual(transitions[0]["to_work_status"], "verified")

        # mc-0615 is not promoted; its blocked attempt is recorded but the
        # cell stays not_implemented/backlog.
        blocked = by_id["mc-0615"]
        self.assertEqual(blocked["capability_status"], "not_implemented")
        self.assertEqual(blocked["work_status"], "backlog")
        self.assertEqual(blocked["evidence_tier"], "none")
        blocked_evidence = evidence_by_id["ev-mc-0615-c18-blocked"]
        self.assertEqual(blocked_evidence["result"], "BLOCKED_LOCAL_FIXTURE")
        self.assertIn("0.324", blocked_evidence["claim_boundary"])
        # The corrected mechanism is a GMRF variance-component boundary, not a
        # repeated design-doc F3 attribution; the record must retract F3
        # rather than assert it as the cause.
        self.assertIn("retracted", blocked_evidence["claim_boundary"])
        self.assertIn(
            "not by finding F3", blocked_evidence["claim_boundary"]
        )
        blocked_transitions = [
            item for item in self.transitions
            if item["transition_id"] == "tr-mc-0615-c18-blocked"
        ]
        self.assertEqual(len(blocked_transitions), 1)
        self.assertEqual(blocked_transitions[0]["from_work_status"], "backlog")
        self.assertEqual(blocked_transitions[0]["to_work_status"], "backlog")

        # Spatial atoms stay untouched: deferred by owner decision and refused
        # in code, not part of this recovery/promotion tranche.
        for cell_id in ("mc-0606", "mc-0616"):
            spatial_row = by_id[cell_id]
            self.assertEqual(spatial_row["capability_status"], "not_implemented")
            self.assertEqual(spatial_row["work_status"], "backlog")
            self.assertEqual(spatial_row["tranche_id"], "lane-c-c18-atom-leaf-taxonomy")

    def test_arc3a_cells_are_narrow_and_evidence_backed(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        by_id = {row["cell_id"]: row for row in model}
        evidence_by_id = {row["evidence_id"]: row for row in self.evidence}

        # Arc 4b raised implemented 337 -> 339. The exact 0.7 capability-truth
        # reconciliation then corrects the two C14 false negatives mc-0060 and
        # mc-0062, so implemented becomes 341 and rejected_by_design becomes 348.
        self.assertEqual(
            {status: sum(row["capability_status"] == status for row in model)
             for status in ("implemented", "not_implemented", "rejected_by_design")},
            {"implemented": 341, "not_implemented": 10, "rejected_by_design": 348},
        )
        for cell_id in ("mc-0251", "mc-0386", "mc-0388"):
            row = by_id[cell_id]
            self.assertEqual(row["q_gate"], "q1")
            self.assertEqual(row["estimator"], "ML")
            self.assertEqual(row["capability_status"], "implemented")
            self.assertEqual(row["work_status"], "verified")
            self.assertEqual(
                row["evidence_tier"], "interval_feasible"
            )
            self.assertIn("interval_feasible only", row["claim_boundary"])
            for excluded in ("reml", "coverage", "inference readiness"):
                self.assertIn(excluded, row["claim_boundary"].lower())
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
        self.assertEqual(comparator["primary_evidence_id"], "ev-mc-0248-q1-expanded-targetwise-profile-low")
        self.assertEqual(comparator["evidence_tier"], "interval_feasible")
        self.assertIn("interval_feasible only", comparator["claim_boundary"])

    def test_arc1b_s1_cells_are_exact_and_preserve_the_not_implemented_remainder(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        by_id = {row["cell_id"]: row for row in model}
        evidence_by_id = {row["evidence_id"]: row for row in self.evidence}
        evidence_by_cell = {
            cell_id: [row for row in self.evidence if row["cell_id"] == cell_id]
            for cell_id in ("mc-0199", "mc-0672", "mc-0673")
        }

        # Arc 4b plus the exact two-row 0.7 capability-truth override (see above).
        self.assertEqual(
            {status: sum(row["capability_status"] == status for row in model)
             for status in ("implemented", "not_implemented", "rejected_by_design")},
            {"implemented": 341, "not_implemented": 10, "rejected_by_design": 348},
        )
        # Two assertions, because one number cannot express both facts.
        #
        # The FROZEN CENSUS -- the original 676 model_surface rows, source_order <= 676 --
        # contains 84 point_fit_recovery cells after the explicit C12 mc-0653,
        # six-cell count tranche, ten named C16 structured zero-one-beta
        # promotions, four B3 q6 mu2 promotions, the exact C17-B mc-0577
        # promotion, the exact 24/25/36/23-cell B4-CI C1--C4 interval
        # promotions, the exact C17-C1 mc-0570 and C17-C2 mc-0578
        # promotions, and the target-specific Arc 1 mc-0260/mc-0262
        # promotions, plus the target-specific Arc 1 mc-0266 and mc-0269
        # promotions, plus the target-specific Arc 2 mc-0186, mc-0263, and
        # mc-0274 promotions.
        # C18 then adds seven exact q1 structured zero-one-beta ATOM
        # (zoi/coi) promotions (mc-0603, mc-0604, mc-0605, mc-0607, mc-0613,
        # mc-0614, mc-0617); mc-0615 stays not promoted.
        # Future changes require a
        # named transition and evidence receipt;
        # raising it without one is how a promotion gets laundered.
        # This asserts against the module constant rather than a literal so the
        # test and the validator cannot drift apart; capability_ledger.py binds
        # each promoted frozen cell to its exact target in ARC1_*/ARC2_TARGETS,
        # so lowering the constant alone still fails there.
        frozen = [row for row in model if int(row["source_order"]) <= 676]
        self.assertEqual(len(frozen), 676)
        self.assertEqual(
            sum(row["evidence_tier"] == "point_fit_recovery" for row in frozen),
            ledger.FROZEN_CENSUS_POINT_FIT_RECOVERY,
        )
        # The TOTAL may differ from the frozen count only through approved row inserts.
        # mc-0260m (source_order 694) is such an insert: it sits outside the frozen
        # window, so it moves this total without moving the constant above. Arc 7b's
        # truth gate returned it to point_fit_recovery, so it contributes again.
        # Checking both numbers catches a promotion hidden behind a simultaneous
        # insert, which either number alone would miss.
        # Deliberately a literal, NOT the module constant: tying both assertions to
        # one constant would destroy exactly the independence this check exists for.
        # 77 -> 71 for the six Arc 2 promotions (mc-0186/0263/0274/0277 + mc-0013/0015).
        # 67 -> 66 for mc-0321's Arc 3 phylo_interaction mu-SD promotion; its NB2
        # sibling mc-0409 was withheld on Fisher's tightened gate and stayed counted.
        # 73 -> 72: mc-0409 was then re-gated at n_each = 24 (fixing a diagnosed NB2
        # dispersion/interaction-SD confound) and promoted on a fresh five-seed
        # Totoro campaign that brackets the truth on every seed.
        # 72 -> 71: Arc 4b demotes mc-0207 from point_fit_recovery to none (see
        # FROZEN_CENSUS_POINT_FIT_RECOVERY); its two new sibling leaves
        # (mc-0715, mc-0716) are born at evidence_tier=none, so they add zero.
        # 72 -> 71: mc-0417 (the two-provider AGGREGATE count cell, BOUND to its
        # spatial+relmat pair) is promoted on its primary target
        # sd:mu:spatial(1 | site) after a fresh five-seed Totoro campaign that
        # brackets the truth on every seed.
        # Both land in the same merge: 72 -> 70. This literal is computed
        # directly from cells.tsv (all model_surface rows, not just the
        # frozen 676), independently of ledger.FROZEN_CENSUS_POINT_FIT_RECOVERY,
        # so a promotion hidden behind a simultaneous row insert cannot slip
        # through both checks at once.
        # 70 -> 67: Arc 5 promotes the final three Prong A cells -- mc-0123
        # (q6 spatial mu1 SD, the independently-fixtured sibling of mc-0124's
        # already-promoted mu2 SD) and mc-0205/mc-0206 (the mu1/sigma1
        # marginal SDs of one labelled bivariate REML mu-sigma correlated
        # block, replacing the point-estimate-only sim3() harness) -- each
        # after Fisher's tightened five-seed, truth-bracketing gate passes
        # 5/5. All three sit inside the frozen window, so this TOTAL and the
        # frozen-only count above move together; recounted directly from the
        # merged cells.tsv, not derived from the module constant.
        # 67 -> 58: Arc 6 promotes nine Gaussian structured cells (mc-0286, mc-0298,
        # mc-0282, mc-0291, mc-0303, mc-0315, mc-0279, mc-0304, mc-0316), each after a
        # five-seed Totoro campaign that brackets the truth on every seed. A tenth
        # sibling, mc-0292 (q2 matched sigma spatial), is WITHHELD -- its seed-303
        # receipt excludes the true 0.7 -- and stays counted here. All nine sit inside
        # the frozen window and none overlaps Arc 5's three or the mc-0207 split, so
        # this TOTAL and the frozen-only count above move together again; recounted
        # directly from the merged cells.tsv, not derived from the module constant.
        # 58 -> 60: Arc 7b installs a mechanical truth gate over the profile-interval
        # contract surface (tools/profile_truth_gate.py) and TWO cells fail it, falling
        # back from interval_feasible to point_fit_recovery. mc-0424's seed 2026080301
        # interval [0.2567, 0.5156] excludes the true 0.55; mc-0260m's seed 2026080233
        # interval [0.2335, 0.4232] excludes the true pooled mean 0.20. Both had passed
        # every shape check, which is why no reconciler caught them -- the same failure
        # mc-0292 and mc-0409 hit, but those two were caught by a human reading the
        # prose. Note this TOTAL and the frozen-only count DIVERGE here for the first
        # time: mc-0424 is source_order 424 (inside the frozen <=676 window) but
        # mc-0260m is 694 (outside it), so FROZEN_CENSUS_POINT_FIT_RECOVERY moves
        # 58 -> 59 while this literal moves 58 -> 60. Recounted directly from cells.tsv.
        # 60 -> 55: 135-trace Prong B promotes five PASS cells (mc-0568, mc-0576,
        # mc-0595, mc-0596, mc-0653) after Totoro five-seed receipts clear the
        # ten-clause contract; nine siblings withheld. All five sit inside the
        # frozen window, so FROZEN_CENSUS_POINT_FIT_RECOVERY moves 59 -> 54 with
        # this total. Recounted directly from cells.tsv.
        self.assertEqual(
            sum(row["evidence_tier"] == "point_fit_recovery" for row in model),
            56,
        )

        by_id = {row["cell_id"]: row for row in model}
        evidence = {row["evidence_id"]: row for row in self.evidence}
        for cell_id, target_id in ledger.ARC1_GAUSSIAN_FIXED_TARGETS.items():
            direct_target = target_id.split("::", 1)[1]
            evidence_id = f"ev-{cell_id}-arc1-fixed-profile"
            transition_id = f"tr-{cell_id}-arc1-fixed-profile"
            transition = next(
                row for row in self.transitions
                if row["transition_id"] == transition_id
            )
            self.assertEqual(by_id[cell_id]["evidence_tier"], "interval_feasible")
            self.assertEqual(by_id[cell_id]["primary_evidence_id"], evidence_id)
            self.assertIn(direct_target, by_id[cell_id]["claim_boundary"])
            self.assertEqual(
                evidence[evidence_id]["path_or_url"],
                ledger.ARC1_GAUSSIAN_FIXED_RECONCILIATION,
            )
            self.assertEqual(evidence[evidence_id]["result"], "interval_feasible")
            self.assertIn(direct_target, evidence[evidence_id]["claim_boundary"])
            self.assertEqual(transition["evidence_ids"], evidence_id)

        for cell_id, contract in ledger.ARC1_ADDITIONAL_TARGETS.items():
            direct_target = contract["target_id"].split("::", 1)[1]
            evidence_id = contract["evidence_id"]
            transition = next(
                row for row in self.transitions
                if row["transition_id"] == contract["transition_id"]
            )
            self.assertEqual(by_id[cell_id]["evidence_tier"], "interval_feasible")
            self.assertEqual(by_id[cell_id]["primary_evidence_id"], evidence_id)
            self.assertIn(direct_target, by_id[cell_id]["claim_boundary"])
            self.assertEqual(
                evidence[evidence_id]["path_or_url"], contract["reconciliation"]
            )
            self.assertEqual(evidence[evidence_id]["result"], "interval_feasible")
            self.assertIn(direct_target, evidence[evidence_id]["claim_boundary"])
            self.assertEqual(transition["evidence_ids"], evidence_id)

        b3 = {
            row["cell_id"]: row
            for row in model
            if row["q_gate"] == "q6"
            and row["dpar"] == "mu2"
            and row["effect_type"] == "structured"
            and row["estimator"] == "ML"
            and row["evidence_tier"] == "interval_feasible"
        }
        self.assertEqual(set(b3), set(ledger.B3_Q6_MU2_TARGETS))
        for cell_id, (provider, paired_mu1, target_id) in ledger.B3_Q6_MU2_TARGETS.items():
            self.assertEqual(b3[cell_id]["structure_provider"], provider)
            self.assertEqual(b3[cell_id]["primary_evidence_id"], f"ev-{cell_id}-b3-q6-mu2-interval")
            expected_tier = "interval_feasible" if paired_mu1 in ledger.C4_B3_PAIRED_MU1_IDS else "point_fit_recovery"
            self.assertEqual(by_id[paired_mu1]["evidence_tier"], expected_tier)
            self.assertIn(target_id, ledger.B3_Q6_MU2_PACKET.read_text(encoding="utf-8"))

        c12 = by_id["mc-0653"]
        self.assertEqual(c12["capability_status"], "implemented")
        self.assertEqual(c12["work_status"], "verified")
        # 135-trace promoted this C12 leaf after five-seed Totoro receipts.
        self.assertEqual(c12["evidence_tier"], "interval_feasible")
        self.assertEqual(c12["primary_evidence_id"], "ev-mc-0653-135trace-profile")

        for cell_id, dpar in (("mc-0199", "mu1"), ("mc-0672", "mu2")):
            row = by_id[cell_id]
            self.assertEqual(row["dpar"], dpar)
            self.assertEqual(row["route_variant"], "arc1b_s1_exact_q2_intercept")
            self.assertEqual(row["structure_provider"], "spatial")
            self.assertEqual(row["q_gate"], "q2")
            self.assertEqual(row["estimator"], "REML")
            self.assertEqual(row["capability_status"], "implemented")
            self.assertEqual(row["work_status"], "verified")
            self.assertEqual(
                row["evidence_tier"], "inference_ready_with_caveats"
            )
            self.assertEqual(
                row["primary_evidence_id"],
                f"ev-{cell_id}-spatial-q2-confidence-eye",
            )
            if cell_id == "mc-0199":
                self.assertEqual(
                    row["legacy_evidence_source"], "R/drmTMB.R:2056-2113"
                )
            self.assertEqual(
                evidence_by_id[row["primary_evidence_id"]]["evidence_class"],
                "coverage_study",
            )
            for earned_boundary in (
                "M (36 sites x 3)",
                "H (36 x 8)",
                "L (12 x 3) failed",
                "baseline-ring",
                "Fixed-kappa bivariate-Gaussian REML only",
                "no mesh intervals",
                "geometry robustness",
                "supported-tier claim",
            ):
                self.assertIn(earned_boundary, row["claim_boundary"])
            historical_claim = evidence_by_id[
                f"ev-{cell_id}-arc1b-recovery"
            ]["claim_boundary"]
            self.assertIn("1,200-attempt Totoro campaign", historical_claim)
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
                self.assertIn(excluded, historical_claim)
            for admitted_condition in (
                "response pairs are complete", "weights are one",
                "no known `meta_V()`", "no additional ordinary random effect",
                "direct-SD formula", "`corpair()` regression",
            ):
                self.assertIn(admitted_condition, historical_claim)
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
                comparator["primary_evidence_id"], f"ev-{cell_id}-q2-production-profile-low"
            )
            self.assertEqual(comparator["evidence_tier"], "interval_feasible")

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
            self.assertEqual(row["evidence_tier"], "interval_feasible")
            self.assertEqual(
                evidence_by_id[row["primary_evidence_id"]]["evidence_class"],
                "contract_test",
            )
            self.assertIn("exact retained unclamped tmbprofile receipt", row["claim_boundary"])
            historical_claim = evidence_by_id[
                f"ev-{cell_id}-arc1b-s2r-recovery"
            ]["claim_boundary"]
            for required in (
                "matching labelled `relmat(1 | p | id, K = K)`",
                "same label, grouping levels and order",
                "identical named supplied covariance `K`",
                "2,400-attempt recovery evidence",
                "point-fit recovery only",
                "Supplied precision `Q`",
                "slopes", "q4+", "scale-side", "missing/weighted pairs",
                "additional random layers",
                "non-Gaussian", "interval", "coverage", "supported",
            ):
                self.assertIn(required, historical_claim)

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
                by_id[cell_id]["primary_evidence_id"], f"ev-{cell_id}-q2-production-profile-low"
            )
            self.assertEqual(by_id[cell_id]["evidence_tier"], "interval_feasible")
        self.assertEqual(by_id["mc-0200"]["capability_status"], "rejected_by_design")
        for cell_id in ("mc-0199", "mc-0672"):
            self.assertEqual(by_id[cell_id]["structure_provider"], "spatial")
            self.assertEqual(
                by_id[cell_id]["evidence_tier"],
                "inference_ready_with_caveats",
            )
        self.assertEqual(by_id["mc-0673"]["capability_status"], "rejected_by_design")

    def test_beta_phylo_q1_cell_is_exact_and_remainder_stays_not_implemented(self):
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        by_id = {row["cell_id"]: row for row in model}
        evidence_by_id = {row["evidence_id"]: row for row in self.evidence}

        admitted = by_id["mc-0017"]
        self.assertEqual(admitted["route_variant"], "beta_phylo_q1_direct_sd")
        self.assertEqual(admitted["structure_provider"], "phylo")
        self.assertEqual(admitted["q_gate"], "q1")
        self.assertEqual(admitted["estimator"], "ML")
        self.assertEqual(admitted["capability_status"], "implemented")
        self.assertEqual(admitted["work_status"], "verified")
        # S5 ratified after D-43 round 2 and maintainer PR review: promoted from
        # point_fit_recovery to inference_ready_with_caveats on the frozen
        # g=1024,m=4 coverage campaign.
        self.assertEqual(admitted["evidence_tier"], "inference_ready_with_caveats")
        self.assertEqual(
            evidence_by_id[admitted["primary_evidence_id"]]["evidence_class"],
            "coverage_study",
        )
        for required in (
            "sd(spp_id, level = \"phylogenetic\") ~ x_tau",
            "machine-strict conditional-Beta",
            "g=1024,m=4",
            "shared g=256,m=2",
            "Tau is latent location SD",
            "REML",
            "random/hierarchical RHS in sd()",
            "intervals",
            "coverage",
            "supported",
            "mildly anti-conservative",
            "D-43 round 2 passed",
        ):
            self.assertIn(required, admitted["claim_boundary"])

        remainder = by_id["mc-0676"]
        self.assertEqual(remainder["route_variant"], "beta_phylo_remainder")
        self.assertEqual(remainder["capability_status"], "rejected_by_design")
        self.assertEqual(remainder["work_status"], "deferred")
        self.assertEqual(remainder["evidence_tier"], "none")
        self.assertIn("mc-0017", remainder["claim_boundary"])
        self.assertEqual(
            evidence_by_id[remainder["primary_evidence_id"]]["evidence_class"],
            "rejection_test",
        )

    def test_generation_is_deterministic(self):
        first = ledger.outputs(self.cells, self.evidence)
        second = ledger.outputs(self.cells, self.evidence)
        self.assertEqual(first, second)

    def test_internal_roadmap_replaces_root_roadmap(self):
        self.assertFalse((ROOT / "ROADMAP.md").exists())
        self.assertTrue(INTERNAL_ROADMAP.is_file())
        self.assertNotIn("^ROADMAP\\.md$", (ROOT / ".Rbuildignore").read_text())
        live_pointers = (
            ROOT / "docs/design/62-implementation-map-slices-303-310.md",
            ROOT / "docs/design/69-comprehensive-function-page-figure-audit.md",
            ROOT / "docs/design/168-r-julia-finish-capability-matrix.md",
            ROOT / "docs/design/180-r-julia-100-slice-finish-run.md",
            ROOT / "docs/dev-log/dashboard/README.md",
            ROOT / "docs/dev-log/dashboard/status.json",
        )
        for path in live_pointers:
            self.assertNotIn("ROADMAP.md", path.read_text(), str(path))
            self.assertNotRegex(path.read_text(), r"\bREADME, ROADMAP\b", str(path))

    def test_reader_summary_is_model_surface_only_and_reconciles_selected_routes(self):
        summary = ledger.reader_summary_value(self.cells)
        model = [row for row in self.cells if row["axis"] == "model_surface"]
        by_id = {row["cell_id"]: row for row in model}

        self.assertEqual(summary["ledger_updated"], ledger.ledger_updated_date(self.cells))
        self.assertEqual(summary["model_surface_total"], len(model))
        self.assertEqual(
            summary["runtime_counts"],
            dict(Counter(row["capability_status"] for row in model)),
        )
        self.assertEqual(
            summary["evidence_counts"],
            dict(Counter(
                row["evidence_tier"]
                for row in model
                if row["capability_status"] == "implemented"
            )),
        )
        self.assertEqual(
            [row["cell_id"] for row in summary["rows"]],
            [spec["cell_id"] for spec in ledger.READER_SUMMARY_SPECS],
        )
        for reader_row in summary["rows"]:
            source = by_id[reader_row["cell_id"]]
            self.assertEqual(reader_row["ledger"]["axis"], "model_surface")
            for field, value in reader_row["ledger"].items():
                self.assertEqual(value, source[field])
            for field in (
                "fit_permission", "point_report_permission",
                "interval_method_report_permission", "scope_caveat", "fallback",
            ):
                self.assertTrue(reader_row[field].strip(), field)
            if (
                source["capability_status"] != "implemented"
                or source["evidence_tier"] in {"none", "diagnostic_only"}
            ):
                self.assertGreater(len(reader_row["fallback"]), 40)
                self.assertRegex(reader_row["fallback"].lower(), r"\b(use|fit|reduce)\b")

    def test_reader_summary_derives_date_and_counts_without_manual_constants(self):
        changed = copy.deepcopy(self.cells)
        changed[0]["updated_date"] = "2099-12-31"
        extra = copy.deepcopy(changed[0])
        extra["cell_id"] = "reader-summary-test-only"
        changed.append(extra)

        summary = ledger.reader_summary_value(changed)
        self.assertEqual(summary["ledger_updated"], "2099-12-31")
        self.assertEqual(summary["model_surface_total"], 1 + sum(
            row["axis"] == "model_surface" for row in self.cells
        ))

    def test_reader_summary_fails_when_canonical_claim_boundary_drifts(self):
        changed = copy.deepcopy(self.cells)
        selected = next(row for row in changed if row["cell_id"] == "mc-0061")
        selected["claim_boundary"] = "Contradictory replacement boundary"
        with self.assertRaisesRegex(SystemExit, "Reader summary scope is stale"):
            ledger.reader_summary_value(changed)

    def test_legacy_supported_label_does_not_authorize_an_interval(self):
        fit, point, interval = ledger.reader_reporting_permissions(
            {"capability_status": "implemented", "evidence_tier": "supported"},
            "Wald interval",
        )
        self.assertTrue(fit.startswith("Yes"))
        self.assertTrue(point.startswith("Yes"))
        self.assertTrue(interval.startswith("No"))
        self.assertIn("legacy supported label", interval)

    def test_reader_summary_is_packaged_and_free_of_internal_cell_jargon(self):
        generated = ledger.outputs(self.cells, self.evidence)
        rendered = generated[ledger.READER_SUMMARY].decode("utf-8")
        self.assertTrue(ledger.READER_SUMMARY.is_relative_to(ROOT / "vignettes/includes"))
        self.assertIn("## Reader routes", rendered)
        self.assertIn("<summary>Technical ledger snapshot</summary>", rendered)
        reader_start = rendered.index("## Reader routes")
        technical_start = rendered.index("<details>")
        self.assertLess(reader_start, technical_start)
        first_screen = rendered[:technical_start]
        self.assertNotIn("point-fit recovery", first_screen)
        self.assertNotIn("supported", first_screen)
        self.assertNotIn("Model-surface total", first_screen)
        self.assertNotIn("docs/dev-log", rendered)
        self.assertNotRegex(rendered, r"\bmc-[0-9]+\b")
        self.assertNotRegex(rendered, r"\bq[0-9]+\b")
        self.assertEqual(rendered.count(".drmtmb-route-card"), 8)
        self.assertIn(".drmtmb-route-interval", rendered)
        self.assertIn(".drmtmb-route-point", rendered)
        self.assertIn(".drmtmb-route-unavailable", rendered)
        for heading in (
            "Beta location", "Binomial location", "Poisson phylogenetic",
            "Negative-binomial", "Tweedie location", "Lognormal location",
            "meta_V(V = V)", "rho12",
        ):
            self.assertIn(heading, rendered)

    def test_cli_check_covers_the_reader_summary_output(self):
        result = subprocess.run(
            ["python3", "tools/capability_ledger.py", "--check"],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("capability-ledger: OK", result.stdout)

    def test_reader_navigation_redirect_and_public_language_contract(self):
        config = (ROOT / "_pkgdown.yml").read_text()
        self.assertIn(
            '- ["ROADMAP.html", "articles/capability-and-limits.html"]',
            config,
        )
        intro = config.split("    intro:", 1)[1].split("    model_guides:", 1)[0]
        intro_pairs = re.findall(
            r"- text: ([^\n]+)\n\s+href: ([^\n]+)", intro
        )
        self.assertEqual(
            intro_pairs,
            [
                ("Overview and first model", "articles/drmTMB.html"),
                ("Can I fit and report this?", "articles/capability-and-limits.html"),
                ("Choose a family", "articles/distribution-families.html"),
                ("Function map and cheat sheet", "articles/function-map-cheatsheet.html"),
                ("Check and report a fitted model", "articles/model-workflow.html"),
            ],
        )
        model_guides = config.split("    model_guides:", 1)[1].split("    tutorials:", 1)[0]
        self.assertNotIn("capability-and-limits", model_guides)
        model_guide_pairs = re.findall(
            r"- text: ([^\n]+)\n\s+href: ([^\n]+)", model_guides
        )
        self.assertEqual(
            model_guide_pairs[0],
            ("What can I fit today?", "articles/model-map.html"),
        )
        self.assertEqual(
            model_guide_pairs.count(
                ("What can I fit today?", "articles/model-map.html")
            ),
            1,
        )
        getting_started = config.split("  - title: Getting Started", 1)[1].split(
            "  - title: Capability and Model Choice", 1
        )[0]
        capability_choice = config.split(
            "  - title: Capability and Model Choice", 1
        )[1].split("  - title: Location and Scale", 1)[0]
        article_entry_pattern = r"^\s{6}- ([A-Za-z0-9][A-Za-z0-9-]*)\s*$"
        getting_started_entries = re.findall(
            article_entry_pattern, getting_started, re.MULTILINE
        )
        capability_choice_entries = re.findall(
            article_entry_pattern, capability_choice, re.MULTILINE
        )
        self.assertEqual(getting_started_entries.count("function-map-cheatsheet"), 1)
        self.assertNotIn("model-map", getting_started_entries)
        self.assertEqual(capability_choice_entries.count("model-map"), 1)
        self.assertNotIn("function-map-cheatsheet", capability_choice_entries)

        learning_path = (ROOT / "vignettes" / "drmTMB.Rmd").read_text().split(
            "## Learning path", 1
        )[1]
        learning_links = (
            "capability-and-limits.html",
            "distribution-families.html",
            "function-map-cheatsheet.html",
            "model-workflow.html",
        )
        learning_positions = [learning_path.index(link) for link in learning_links]
        self.assertEqual(learning_positions, sorted(learning_positions))

        design = (ROOT / "docs" / "design" / "226-reader-learning-path.md").read_text()
        vignette_stems = {path.stem for path in (ROOT / "vignettes").glob("*.Rmd")}
        vignette_count = len(vignette_stems)
        self.assertIn(f"across {vignette_count} vignettes", design.splitlines()[0])
        self.assertIn(f"{vignette_count} rows.", design)
        design_stems = re.findall(
            r"^\| [^|]+ \| `([^`]+)` \|", design, re.MULTILINE
        )
        self.assertEqual(len(design_stems), len(set(design_stems)))
        self.assertEqual(set(design_stems), vignette_stems)
        article_index = config.split("\narticles:", 1)[1]
        article_stems = re.findall(
            article_entry_pattern, article_index, re.MULTILINE
        )
        self.assertEqual(len(article_stems), len(set(article_stems)))
        self.assertEqual(set(article_stems), vignette_stems)

        public_paths = [ROOT / "README.md", *sorted((ROOT / "vignettes").glob("*.Rmd"))]
        public_text = "\n".join(path.read_text() for path in public_paths)
        for stale in (
            "ROADMAP.html", "ROADMAP.md", "check the roadmap",
            "What drmTMB can and can't do", "What can I trust?",
        ):
            self.assertNotIn(stale, public_text)

    def test_capability_article_has_reporting_rule_and_stable_terms(self):
        article = (ROOT / "vignettes/capability-and-limits.Rmd").read_text()
        css = (ROOT / "pkgdown" / "extra.css").read_text()
        self.assertIn('title: "Can I fit and report this model?"', article)
        self.assertIn("## Before reporting", article)
        self.assertIn("## Evidence and exact tested scopes", article)
        for token in (
            "`mu`", "`sigma`", "`nu`", "`rho12`", "`sd(group)`",
            "`phylo()`", "`spatial()`", "`meta_V(V = V)`",
            "`check_drm(fit)`", "`conf.status`", "`profile.boundary`",
            "failed bootstrap refits",
        ):
            self.assertIn(token, article)
        self.assertEqual(article.count("meta_known_V(V = V)"), 1)
        self.assertEqual(len(re.findall(r"\btau\b", article)), 1)
        self.assertIn('<details class="drmtmb-notation">', article)
        self.assertIn("Supported (legacy ledger label)", article)
        self.assertNotIn("Five non-Gaussian families now carry", article)
        self.assertNotIn("All five admitted fixed-effect", article)
        self.assertNotRegex(
            article,
            r"\b(?:two|three|four|five)\s+(?:certified\s+|Arc\s+1a\s+REML\s+)?"
            r"(?:q[0-9]+\s+[^\n]{0,24})?(?:rows|cells|classes|families)\b",
        )
        for token in (
            ".drmtmb-reader-routes",
            ".drmtmb-route-interval",
            "Scroll horizontally to see all columns",
            "min-width: 9rem",
        ):
            self.assertIn(token, css)

    def test_unsupported_fit_errors_name_reader_compatible_fallbacks(self):
        source = (ROOT / "R" / "drmTMB.R").read_text()
        self.assertIn(
            "Use an unlabelled intercept with {.fn phylo} or {.fn relmat}, "
            "or remove the structured term.",
            source,
        )

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
                "`sigma`: int implemented / slope not currently supported",
                rows[route]["Random (int/slope)"],
            )

    def test_family_map_aggregation_names_absence_and_partial_states(self):
        status = lambda value: {"capability_status": value}
        self.assertEqual(ledger._aggregate_state([]), "absent")
        self.assertEqual(
            ledger._aggregate_state([status("not_implemented")]),
            "not implemented",
        )
        self.assertEqual(
            ledger._aggregate_state([status("rejected_by_design")]),
            "not currently supported",
        )
        self.assertEqual(
            ledger._aggregate_state([
                status("not_implemented"), status("scaffolded")
            ]),
            "mixed (not implemented 1; scaffolded 1)",
        )
        self.assertEqual(
            ledger._aggregate_state([
                status("implemented"), status("not_implemented")
            ]),
            "scope-limited (implemented 1; not implemented 1)",
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
        ml_binomial["capability_status"] = "not_implemented"
        after = {
            row["family_route"]: row["REML"]
            for row in ledger.family_map_rows(cells)
        }
        self.assertEqual(before["binomial"], after["binomial"])
        self.assertEqual(
            before["binomial"],
            "`mu`: scope-limited (implemented 2; not currently supported 2)",
        )

    def test_planning_class_keeps_unimplemented_work_visible(self):
        by_id = {row["cell_id"]: row for row in self.cells}
        self.assertEqual(ledger.planning_class(by_id["mc-0001"]), "available")
        self.assertEqual(
            ledger.planning_class(by_id["mc-0002"]), "estimator method"
        )
        self.assertEqual(
            ledger.planning_class(by_id["mc-0009"]), "admission candidate"
        )
        self.assertEqual(
            ledger.planning_class(by_id["mc-0014"]),
            "covariance / model method",
        )

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
            "`mu`: scope-limited (implemented 8; not currently supported 4)",
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

    def test_missing_data_vignette_matrix_matches_the_ledger_routes(self):
        # `missing-data.Rmd` restates the 18 response-missingness routes by hand.
        # `--check` compares only the generated include, so without this guard a
        # demotion would self-correct in `capability-and-limits.Rmd` while the
        # vignette kept its tick -- drift in the over-claiming direction, on the
        # largest single claim surface for this axis.
        text = (ROOT / "vignettes/missing-data.Rmd").read_text()
        marker = '| Response family | `response = "include"`'
        block = text[text.index(marker):].split("\n\n", 1)[0].splitlines()
        rows = [line for line in block if line.startswith("|")][2:]
        labels = {line.split("|")[1].strip() for line in rows}
        expected = {
            "`gaussian()`",
            "bivariate Gaussian",
            "`binomial()`",
            "`poisson()`",
            "`nbinom2()`",
            "`beta()`",
            "`student()`",
            "`lognormal()`",
            '`Gamma(link = "log")`',
            "`skew_normal()`",
            "`tweedie()`",
            "`zero_one_beta()`",
            "`beta_binomial()`",
            "`cumulative_logit()`",
            "`truncated_nbinom2()`",
            "zero-inflated Poisson",
            "zero-inflated NB2",
            "hurdle NB2",
        }
        self.assertEqual(labels, expected)
        missing = [row for row in self.cells if row["axis"] == "missing_response"]
        self.assertEqual(len(rows), len(missing))
        self.assertEqual(len(rows), len(ledger.ADMITTED))

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
        surfaces["internal-roadmap.md"] = INTERNAL_ROADMAP.read_text()
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
            "exact ordinary `zoi` and `coi` q1 intercept/same-raw-symbol slope routes are point-fit-only",
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
        self.assertIn("exact `mc-0539` is inference-ready with caveats", surfaces["implementation-map.Rmd"])
        self.assertIn("exact `mc-0575` is inference-ready with caveats", surfaces["implementation-map.Rmd"])
        self.assertIn(
            "zero_one_beta()` | `mu` logit",
            surfaces["02-family-registry.md"],
        )
        for cell in ("mc-0227", "mc-0464", "mc-0539", "mc-0575"):
            self.assertIn(cell, surfaces["02-family-registry.md"])
        self.assertNotIn(
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
            "internal-roadmap.md",
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
                "internal-roadmap.md",
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
            "Can I fit and report this model?",
            surfaces["drmTMB.Rmd"],
        )
        self.assertNotIn("fixed-effect zero-one beta", surfaces["drmTMB.Rmd"])
        self.assertIn(
            "each has ordinary `mu` random intercepts and independent numeric slopes",
            surfaces["model-map.Rmd"],
        )
        self.assertIn("design-specific inference-ready-with-caveats evidence", surfaces["model-map.Rmd"])
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

        roadmap = INTERNAL_ROADMAP.read_text()
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
                INTERNAL_ROADMAP,
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
        self.assertEqual(by_id["mc-0494"]["evidence_tier"], "interval_feasible")
        self.assertEqual(by_id["mc-0495"]["evidence_tier"], "diagnostic_only")
        self.assertEqual(by_id["mc-0641"]["evidence_tier"], "diagnostic_only")
        for cell_id in ("mc-0229", "mc-0364", "mc-0641", "mc-0662", "mc-0667"):
            self.assertEqual(by_id[cell_id]["evidence_tier"], "diagnostic_only")
            self.assertIn("recovery", by_id[cell_id]["claim_boundary"].lower())
            self.assertIn("no_denominator_local_debug_only", by_id[cell_id]["claim_boundary"])
        self.assertEqual(by_id["mc-0248"]["evidence_tier"], "interval_feasible")
        self.assertIn("interval_feasible only", by_id["mc-0248"]["claim_boundary"])

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
            "Capability tiers, defined once",
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
                INTERNAL_ROADMAP,
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
            INTERNAL_ROADMAP,
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
            "ROADMAP": INTERNAL_ROADMAP.read_text(),
            "NEWS": (ROOT / "NEWS.md").read_text(),
            "capability": (
                ROOT / "vignettes/capability-and-limits.Rmd"
            ).read_text(),
        }
        self.assertIn("Poisson slope-only `mu ~ spatial(0 + x", public["README"])
        self.assertIn("Poisson `mu ~ spatial(1 | site", public["README"])
        self.assertIn("ten Q-Series v1.0 rows", public["ROADMAP"])
        self.assertIn("ten row-specific\n  diagnostic-only gates", public["NEWS"])
        self.assertIn("Row-specific single-smoke slices", public["capability"])
        # pkgdown-site/llms.txt is a git-ignored pkgdown BUILD artifact, not a ledger
        # output. Assert on it only when it is version-controlled; a git-ignored local
        # build may be stale or absent, and the authoritative surface check is the README
        # assertion above (identical strings). When llms.txt is tracked (or built fresh in
        # CI) the check still runs and would catch a real content regression. A stale or
        # untracked llms.txt is treated as absent (llms = None), skipping every
        # `if llms is not None` block below, exactly as an absent file already did.
        llms_path = ROOT / "pkgdown-site/llms.txt"

        def _git_tracked(path):
            try:
                return (
                    subprocess.run(
                        ["git", "-C", str(ROOT), "ls-files", "--error-unmatch", str(path)],
                        capture_output=True,
                    ).returncode
                    == 0
                )
            except OSError:
                return False

        llms = (
            llms_path.read_text()
            if (llms_path.exists() and _git_tracked(llms_path))
            else None
        )
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
        # Same rule as llms.txt above: the rendered article is a git-ignored pkgdown
        # build artifact; assert on it only when version-controlled, so a stale local
        # render cannot fail this ledger test. The tracked count source (asserted in the
        # loop) is the authoritative surface.
        count_rendered_path = ROOT / "pkgdown-site/articles/count-nbinom2.md"
        if count_rendered_path.exists() and _git_tracked(count_rendered_path):
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
            "Gaussian structured random effects: selected anchor cells",
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
        roadmap = INTERNAL_ROADMAP.read_text()
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
            self.assertNotIn("G4/G5 interval and coverage evidence are outside this arc.", output)
            self.assertIn("Current G4/G5 evidence (target-rung grain)", output)
            self.assertIn("eight reconciled cohorts: 98 of 130 exact cells pass", output)
        # 2026-08-11 D-43 panel + addendum: the generic "campaign stopped
        # before route-wide reconciliation" placeholder is no longer true
        # for ANY of the 18 missing_response rows (eight promoted, ten held
        # for their own distinct, real reasons), so it must not appear, and
        # each held route's real per-route next_gate reason must. The v1
        # "all-1200 interval-usability rule" was itself superseded within
        # the same review by mr-g5-calibration-v2 (availability >= 0.99
        # floor); v1 wording must not linger, and the named gate version
        # must appear so a future gate change is visible rather than silent.
        self.assertNotIn(
            "G4/G5 framework is ready and partial calibration evidence is retained",
            markdown,
        )
        self.assertNotIn("the all-1200 interval-usability rule", markdown)
        self.assertIn("mr-g5-calibration-v2", markdown)
        self.assertIn("route evidence is incomplete, not failing", markdown)
        self.assertIn("structural, not evidential, grounds", markdown)
        self.assertNotIn("Missing-response execution board", html)
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

    def _parity_promotion_claims(self):
        """(cell_id, claimed_tier) for every parity-triage row asserting a promotion."""
        import re

        pattern = re.compile(
            r"promoted this cell to (" + "|".join(sorted(ledger.EVIDENCE_TIERS)) + r")\b"
        )
        claims = []
        for row in ledger.read_tsv(ledger.PARITY_TRIAGE):
            match = pattern.search(row.get("rationale", ""))
            if match:
                claims.append((row["cell_id"], match.group(1)))
        return claims

    def test_parity_triage_promotion_claims_match_the_live_ledger(self):
        """A rationale saying a campaign promoted a cell must be true of cells.tsv.

        Nine rows once claimed promotion to interval_feasible while the ledger
        still read point_fit_recovery: one PR wrote the rationale for twelve
        cells but promoted only three. Nothing caught it.
        """
        claims = self._parity_promotion_claims()
        self.assertGreater(len(claims), 0, "the promotion-claim phrasing has disappeared; "
                                           "the guard in validate() is now dead code")
        tiers = {row["cell_id"]: row["evidence_tier"] for row in self.cells}
        mismatched = [
            (cell_id, claimed, tiers.get(cell_id))
            for cell_id, claimed in claims
            if tiers.get(cell_id) != claimed
        ]
        self.assertEqual(mismatched, [])

    def test_parity_triage_promotion_claim_contradicting_the_ledger_is_rejected(self):
        claims = self._parity_promotion_claims()
        target_id, claimed = claims[0]
        cells = copy.deepcopy(self.cells)
        target = next(row for row in cells if row["cell_id"] == target_id)
        # Demote below what parity-triage asserts. The row keeps claiming the
        # promotion, so validate() must reject the pair.
        target["evidence_tier"] = "point_fit_recovery" if claimed != "point_fit_recovery" else "none"
        with self.assertRaisesRegex(SystemExit, f"{target_id}: parity triage claims promotion"):
            ledger.validate(cells, self.evidence, self.transitions)

    def test_parked_parity_rationales_are_deliberately_unchecked(self):
        """Guard against widening the check onto the parked template.

        116 rows say "Parked: next_gate directs preserving the existing
        model-surface evidence tier, so no comparator or interval/coverage
        campaign is being pursued". As of 2026-08-03, 89 of them sit at
        interval_feasible or above, so that clause is unmaintained boilerplate
        rather than a live claim. Checking it would report ~89 failures on a
        clean tree. If someone repairs that corpus and this test starts failing,
        the check in validate() can be widened -- until then it must not be.
        """
        parked = "Parked: next_gate directs preserving the existing model-surface evidence tier"
        tiers = {row["cell_id"]: row["evidence_tier"] for row in self.cells}
        promoted_anyway = [
            row["cell_id"] for row in ledger.read_tsv(ledger.PARITY_TRIAGE)
            if row.get("rationale", "").startswith(parked)
            and tiers.get(row["cell_id"]) in {"interval_feasible", "inference_ready_with_caveats", "supported"}
        ]
        self.assertGreater(
            len(promoted_anyway), 1,
            "the parked-rationale corpus appears to have been repaired; revisit whether "
            "validate() should now also check the parked template",
        )

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

    def test_external_comparator_evidence_states_what_it_does_not_cover(self):
        """Agreement with another package is not an interval or coverage claim.

        Every external_comparator record must say so in its own claim_boundary, so the
        limit travels with the evidence instead of living only in a reviewer's head.
        """
        rows = [
            row for row in self.evidence
            if row["evidence_class"] == "external_comparator"
        ]
        self.assertTrue(rows, "expected at least one external_comparator record")
        for row in rows:
            boundary = row["claim_boundary"].lower()
            for token in ("interval", "coverage", "single-seed"):
                self.assertIn(
                    token, boundary,
                    f"{row['evidence_id']}: claim_boundary must state {token!r}",
                )
            # Without an independence token the surface renders "pkg (unclassified)",
            # which tells a reader nothing about whether the comparator shares drmTMB's
            # estimation engine. Require the row to declare it.
            self.assertTrue(
                "strong independence" in boundary or "weak independence" in boundary,
                f"{row['evidence_id']}: claim_boundary must declare STRONG or WEAK "
                "INDEPENDENCE",
            )
            self.assertTrue(
                ledger.source_path_exists(row["path_or_url"]),
                f"{row['evidence_id']}: unresolved path {row['path_or_url']}",
            )

    def test_external_comparator_never_becomes_a_family_level_badge(self):
        """Comparator evidence is per cell and must never be aggregated to a family.

        family_map_rows() buckets every row sharing a family_route -- fixed, random,
        structured, phylogenetic, spatial and bivariate together -- and reports one
        highest-evidence string per family. A comparator name surfacing there would read
        as covering frontier routes that have no external comparator at all. Parity
        licenses the overlap region only.
        """
        by_cell = ledger.external_comparator_by_cell(self.evidence)
        self.assertTrue(by_cell, "expected comparator annotations for some cells")
        cell_ids = {row["cell_id"] for row in self.cells}
        for cell_id in by_cell:
            self.assertIn(cell_id, cell_ids)

        family_map = (
            ROOT / "vignettes/includes/capability-ledger-family-map.md"
        ).read_text(encoding="utf-8")

        # Forbid the hand-maintained tuple AND every badge actually rendered today. The
        # tuple alone would miss a future comparator (nlme, coxme) that nobody remembered
        # to add to it, so derive the second half from the evidence rows themselves.
        forbidden = set(ledger.COMPARATOR_PACKAGES)
        forbidden.update(by_cell.values())
        for token in sorted(forbidden):
            self.assertNotIn(
                token, family_map,
                f"{token!r} leaked into the family map; comparator evidence must stay "
                "scoped to individual cells",
            )

    def test_evidence_class_is_a_closed_vocabulary(self):
        """A typo in evidence_class used to yield zero badges and a green --check."""
        for row in self.evidence:
            self.assertIn(
                row["evidence_class"], ledger.EVIDENCE_CLASSES,
                f"{row['evidence_id']}: unknown evidence_class",
            )
        broken = copy.deepcopy(self.evidence)
        broken[0]["evidence_class"] = "external_comparitor"
        with self.assertRaises(SystemExit):
            ledger.validate(copy.deepcopy(self.cells), broken, copy.deepcopy(self.transitions))


if __name__ == "__main__":
    unittest.main()
