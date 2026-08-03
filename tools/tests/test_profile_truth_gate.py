#!/usr/bin/env python3
"""The truth gate over the whole profile-interval contract surface.

WHY THIS TEST EXISTS
--------------------
The reconcilers check interval SHAPE exhaustively but historically checked
nothing about interval LOCATION, because the runner recorded the true
parameter value only as prose. Three cells reached review holding intervals
that excluded their own true value; all three were caught by a human reading
that prose, not by any check. tools/profile_truth_gate.py supplies the missing
half, and this file is what makes it run.

It sweeps the full 31-cell contract surface independently of the reconcilers:
the 26 cells in arc2_profile_reconcile.CELL_CONTRACTS plus the 5 frozen Arc 1
cells. Sweeping independently is deliberate. If a reconciler ever forgets to
call the gate, the reconciler still passes -- but this test does not, because
it derives the cell list from the contract registries themselves rather than
from whoever remembered to check.

Registry constants are IMPORTED, never restated here, so the test and the
reconcilers cannot silently drift apart (the same idiom
test_b3_q6_target_promotion.py uses for C4_B3_PAIRED_MU1_IDS).

Per docs/dev-log/after-task/2026-08-03-b4-ci-mc-0207-pin-drift.md: a guard's
definition of done includes the line in CI that runs it. This one is wired
into .github/workflows/R-CMD-check.yaml in the same change that created it.
"""

from __future__ import annotations

import csv
import importlib.util
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TOOLS = ROOT / "tools"

# The one contract cell whose truth cannot be DERIVED, and therefore cannot be
# gated. mc-0282 holds an interval_feasible claim on five retained receipts
# whose binding_source names tools/run-arc2-profile-feasibility.R -- but that
# runner has never, in any commit, carried an mc-0282 registry entry (verified
# across the runner's history). Its receipts were produced by a contract that
# was never committed, so there is no committed accessor to derive truth from
# and writing one here would be declaring a truth, not deriving it.
#
# Checked manually against the truth its fixture DOES expose
# (arc2_phylo_sigma_q2_fixture's true_sd_mu = 0.6, the mu-side sibling of the
# value mc-0283 uses): all five seeds bracket it, so the claim is not in doubt.
# The gap is reproducibility, not correctness. Restoring the runner entry is
# tracked separately; see the Arc 7b after-task report.
UNGATED = {"mc-0282"}
RESULTS = ROOT / "docs/dev-log/interval-feasibility/results"
CELLS_TSV = ROOT / "docs/dev-log/dashboard/capability-ledger/cells.tsv"


def _load(name: str, filename: str):
    """Import a tools/ module by path (several have hyphenated filenames)."""
    spec = importlib.util.spec_from_file_location(name, TOOLS / filename)
    module = importlib.util.module_from_spec(spec)
    # arc2_profile_reconcile imports arc1_profile_reconcile as a bare name.
    import sys

    if str(TOOLS) not in sys.path:
        sys.path.insert(0, str(TOOLS))
    spec.loader.exec_module(module)
    return module


gate = _load("profile_truth_gate", "profile_truth_gate.py")
arc2 = _load("arc2_profile_reconcile", "arc2_profile_reconcile.py")

# The four frozen Arc 1 reconcilers. Their SEEDS/target constants are the
# authority for which receipts back each cell's claim.
ARC1_MODULES = {
    "fixed": _load("r_arc1_fixed", "reconcile-arc1-gaussian-fixed-profiles.py"),
    "meta_v": _load("r_arc1_meta", "reconcile-arc1-meta-v-profiles.py"),
    "sigma_re": _load("r_arc1_sigma", "reconcile-arc1-gaussian-sigma-re-profiles.py"),
    "reml_slope": _load("r_arc1_slope", "reconcile-arc1-gaussian-reml-slope-profiles.py"),
}


def arc1_pins() -> dict[str, frozenset[str]]:
    """cell_id -> pinned seeds, read from the Arc 1 reconcilers themselves."""
    pins: dict[str, frozenset[str]] = {}
    fixed = ARC1_MODULES["fixed"]
    for cell in fixed.CONTRACTS:
        pins[cell] = frozenset(fixed.SEEDS)
    for key, cell in (
        ("meta_v", "mc-0260m"),
        ("sigma_re", "mc-0266"),
        ("reml_slope", "mc-0269"),
    ):
        module = ARC1_MODULES[key]
        assert module.TARGET_ID.startswith(f"{cell}::"), module.TARGET_ID
        pins[cell] = frozenset(module.SEEDS)
    return pins


def receipt_index() -> dict[tuple[str, str], list[dict[str, str]]]:
    """(cell_id, seed) -> retained receipt rows, across every results tree."""
    index: dict[tuple[str, str], list[dict[str, str]]] = {}
    for path in RESULTS.rglob("*-receipt.tsv"):
        with path.open(newline="") as stream:
            for row in csv.DictReader(stream, delimiter="\t"):
                index.setdefault((row["cell_id"], row["seed"]), []).append(row)
    return index


def ledger_tiers() -> dict[str, str]:
    with CELLS_TSV.open(newline="") as stream:
        return {r["cell_id"]: r["evidence_tier"] for r in csv.DictReader(stream, delimiter="\t")}


def endpoints(row: dict[str, str]) -> tuple[float, float]:
    return float(row["lower"]), float(row["upper"])


class ProfileTruthGateTests(unittest.TestCase):
    maxDiff = None

    @classmethod
    def setUpClass(cls) -> None:
        cls.manifest = gate.load_truth_manifest()
        cls.arc2_contracts = arc2.CELL_CONTRACTS
        cls.arc1 = arc1_pins()
        cls.receipts = receipt_index()
        cls.tiers = ledger_tiers()

    # ---- coverage: the gate must not be able to skip a cell -------------

    def test_contract_surface_is_thirty_one_cells(self):
        surface = set(self.arc2_contracts) | set(self.arc1)
        self.assertEqual(len(self.arc2_contracts), 26)
        self.assertEqual(len(self.arc1), 5)
        self.assertEqual(len(surface), 31, sorted(surface))

    def test_every_contract_cell_has_a_derived_finite_truth(self):
        """Fail-closed coverage: a cell with no truth must not slip through.

        mc-0263 is the live example -- its truth is a structural zero, so any
        'parse the leading number from the prose' heuristic skips it silently.
        """
        for cell in sorted((set(self.arc2_contracts) | set(self.arc1)) - UNGATED):
            with self.subTest(cell=cell):
                value = gate.truth_for(cell, self.manifest)
                self.assertTrue(math.isfinite(value))

    def test_the_ungated_exemption_set_is_exactly_one_known_cell(self):
        """UNGATED must never grow quietly.

        Left unbounded, an exemption list is how a gate stops gating. This
        pins it to the single documented case, so adding a second one is an
        explicit, reviewable edit rather than a silent omission -- the same
        reason .github/workflows/R-CMD-check.yaml names the un-wired B4-CI
        files in a comment instead of dropping them.
        """
        self.assertEqual(UNGATED, {"mc-0282"})
        self.assertNotIn("mc-0282", self.manifest)
        self.assertIn("mc-0282", self.arc2_contracts)

    def test_ungated_cells_are_still_reconciled_for_shape(self):
        """mc-0282's exemption is about truth derivation, not about shape.

        It keeps its arc2 contract entry, so every non-truth check still
        applies to it. Only the numeric truth is underivable, because the
        runner contract that produced its receipts was never committed.
        """
        for cell in sorted(UNGATED):
            with self.subTest(cell=cell):
                contract = self.arc2_contracts[cell]
                self.assertIn("information_rung", contract)
                self.assertTrue(contract["seeds"])

    def test_every_arc1_reconciler_on_disk_is_swept(self):
        """A new Arc 1 cohort cannot be added without falling under the gate.

        The Arc 1 reconcilers do not call the gate themselves (see
        tools/arc1_profile_reconcile.py for why), so this sweep is their only
        coverage. If someone adds a fifth reconcile-arc1-*.py and does not wire
        it into ARC1_MODULES, that cell would be silently ungated -- which is
        precisely the failure mode this arc exists to close.
        """
        on_disk = {p.name for p in TOOLS.glob("reconcile-arc1-*.py")}
        wired = {Path(m.__file__).name for m in ARC1_MODULES.values()}
        self.assertEqual(on_disk, wired, "an Arc 1 reconciler is not swept by this test")

    def test_every_arc2_contract_pins_a_cohort_and_seeds(self):
        for cell, contract in sorted(self.arc2_contracts.items()):
            with self.subTest(cell=cell):
                self.assertIn("information_rung", contract)
                self.assertIn("seeds", contract)
                self.assertTrue(contract["seeds"], "empty pinned seed set")

    def test_every_pinned_receipt_resolves_to_one_retained_row(self):
        """Every pinned seed must resolve to exactly one set of endpoints.

        Duplicates across results trees are tolerated only when byte-identical
        (mc-0277 has such copies). Two receipts disagreeing on the interval for
        one pinned seed would make the verdict depend on glob order, so it is
        an error rather than a coin flip. Arc 1 has no duplicates today; it is
        checked anyway so a future cohort cannot introduce one silently.
        """
        pins = [
            (cell, seed, contract["information_rung"])
            for cell, contract in self.arc2_contracts.items()
            for seed in contract["seeds"]
        ] + [(cell, seed, None) for cell, seeds in self.arc1.items() for seed in seeds]
        for cell, seed, rung in sorted(pins, key=lambda p: (p[0], p[1])):
            with self.subTest(cell=cell, seed=seed):
                rows = [
                    r
                    for r in self.receipts.get((cell, seed), [])
                    if rung is None or r.get("execution_information_rung") == rung
                ]
                self.assertTrue(rows, "pinned receipt not found on disk")
                values = {(r["lower"], r["upper"]) for r in rows}
                self.assertEqual(len(values), 1, f"conflicting duplicates: {values}")

    # ---- the standing guard ---------------------------------------------

    def test_every_interval_feasible_contract_cell_passes_the_gate(self):
        """The invariant this whole arc exists to enforce."""
        for cell in sorted((set(self.arc2_contracts) | set(self.arc1)) - UNGATED):
            if self.tiers.get(cell) != "interval_feasible":
                continue
            with self.subTest(cell=cell):
                verdict = self.verdict_for(cell)
                self.assertTrue(
                    verdict["passed"],
                    f"{cell} claims interval_feasible but fails the truth gate: "
                    f"{verdict['reasons']}",
                )

    # ---- red tests: prove the gate actually bites ------------------------

    def test_gate_rejects_mc0423_the_documented_truth_miss(self):
        verdict = self.verdict_for("mc-0423")
        self.assertFalse(verdict["passed"])
        self.assertEqual(verdict["n_misses"], 1)
        self.assertGreater(verdict["worst_relative_miss"], gate.MISS_MAGNITUDE_TOL)
        self.assertNotEqual(self.tiers["mc-0423"], "interval_feasible")

    def test_gate_rejects_mc0424_the_cell_this_arc_demotes(self):
        verdict = self.verdict_for("mc-0424")
        self.assertFalse(verdict["passed"])
        self.assertFalse(verdict["per_seed"]["2026080301"]["brackets_truth"])
        self.assertNotEqual(self.tiers["mc-0424"], "interval_feasible")

    def test_gate_rejects_mc0260m_the_meta_v_truth_miss(self):
        verdict = self.verdict_for("mc-0260m")
        self.assertFalse(verdict["passed"])
        self.assertFalse(verdict["per_seed"]["2026080233"]["brackets_truth"])
        self.assertNotEqual(self.tiers["mc-0260m"], "interval_feasible")

    def test_gate_accepts_the_repaired_mc0409_family(self):
        """The n_each 8->24 repair produced five seeds that all bracket truth."""
        verdict = self.verdict_for("mc-0409")
        self.assertTrue(verdict["passed"], verdict["reasons"])
        self.assertEqual(verdict["n_seeds"], 5)
        self.assertEqual(verdict["n_misses"], 0)

    def test_superseded_mc0409_cohort_is_excluded_by_the_pin(self):
        """Both mc-0409 cohorts share seeds 2026080401-05.

        Pinning seeds alone would still pull in the superseded each8 receipts,
        one of which misses truth. The information_rung is what discriminates.
        """
        contract = self.arc2_contracts["mc-0409"]
        self.assertEqual(contract["information_rung"], "star_np8_npo8_each24")
        superseded = [
            r
            for r in self.receipts[("mc-0409", "2026080405")]
            if r.get("execution_information_rung") == "star_np8_npo8_each8"
        ]
        self.assertTrue(superseded, "expected a superseded each8 receipt to exist")
        lower, upper = endpoints(superseded[0])
        truth = gate.truth_for("mc-0409", self.manifest)
        self.assertFalse(lower <= truth <= upper, "fixture assumption broke")

    def test_a_single_narrow_miss_does_not_demote(self):
        """Defence in depth behind the pin, and the reason for the rule shape.

        A 95% interval is expected to miss sometimes. Even if the superseded
        mc-0409 cohort leaked past the pin, its worst miss is ~1.7% of truth
        and one narrow miss must not demote a cell.
        """
        truth = gate.truth_for("mc-0409", self.manifest)
        leaked = {
            r["seed"]: endpoints(r)
            for key, rows in self.receipts.items()
            if key[0] == "mc-0409"
            for r in rows
            if r.get("execution_information_rung") == "star_np8_npo8_each8"
        }
        verdict = gate.evaluate_cell("mc-0409-leaked", truth, leaked)
        self.assertEqual(verdict["n_misses"], 1)
        self.assertLess(verdict["worst_relative_miss"], gate.MISS_MAGNITUDE_TOL)
        self.assertTrue(verdict["passed"])

    def test_structural_zero_cell_is_evaluated_not_skipped(self):
        """mc-0263's true fixef:sigma:x is 0 by construction, not missing."""
        truth = gate.truth_for("mc-0263", self.manifest)
        self.assertEqual(truth, 0.0)
        verdict = self.verdict_for("mc-0263")
        self.assertEqual(verdict["n_seeds"], len(self.arc2_contracts["mc-0263"]["seeds"]))
        self.assertTrue(verdict["passed"], verdict["reasons"])

    # ---- fail-closed -----------------------------------------------------

    def test_unusable_truth_is_an_error_not_a_skip(self):
        for label, manifest in (
            ("absent cell", {}),
            ("blank", {"mc-x": {"cell_id": "mc-x", "true_value": ""}}),
            ("unparseable", {"mc-x": {"cell_id": "mc-x", "true_value": "zero"}}),
            ("non-finite", {"mc-x": {"cell_id": "mc-x", "true_value": "nan"}}),
        ):
            with self.subTest(case=label):
                with self.assertRaises(gate.TruthGateError):
                    gate.truth_for("mc-x", manifest)

    def test_degenerate_inputs_are_errors(self):
        with self.assertRaises(gate.TruthGateError):
            gate.evaluate_cell("mc-x", 0.5, {})
        with self.assertRaises(gate.TruthGateError):
            gate.evaluate_cell("mc-x", 0.5, {"s": (0.1, float("nan"))})
        with self.assertRaises(gate.TruthGateError):
            gate.evaluate_cell("mc-x", 0.5, {"s": (0.9, 0.2)})

    def test_missing_manifest_is_an_error(self):
        with self.assertRaises(gate.TruthGateError):
            gate.load_truth_manifest(ROOT / "tools" / "no-such-manifest.tsv")

    # ---- drift ------------------------------------------------------------

    def test_derived_truth_agrees_with_the_receipt_prose(self):
        """The manifest is derived; the prose was hand-written. They must agree.

        A disagreement means either the accessor reads the wrong element or the
        prose was mistyped -- exactly the class of defect this arc closes. Only
        prose that opens with a number is comparable; mc-0263's does not, which
        is why it is exempted here and covered by its own test above.
        """
        for cell in sorted((set(self.arc2_contracts) | set(self.arc1)) - UNGATED):
            rows = [r for key, rs in self.receipts.items() if key[0] == cell for r in rs]
            if not rows:
                continue
            lead = re.match(r"\s*([0-9]*\.?[0-9]+)\s", rows[0].get("true_parameter_scale", ""))
            if not lead:
                continue
            with self.subTest(cell=cell):
                self.assertAlmostEqual(
                    gate.truth_for(cell, self.manifest),
                    float(lead.group(1)),
                    places=9,
                    msg=f"{cell}: derived truth disagrees with its own receipt prose",
                )

    # ---- helper -----------------------------------------------------------

    def verdict_for(self, cell: str) -> dict[str, object]:
        truth = gate.truth_for(cell, self.manifest)
        contract = self.arc2_contracts.get(cell)
        if contract is not None:
            rung, seeds = contract["information_rung"], contract["seeds"]
        else:
            rung, seeds = None, sorted(self.arc1[cell])
        pinned: dict[str, tuple[float, float]] = {}
        for seed in seeds:
            rows = [
                r
                for r in self.receipts.get((cell, seed), [])
                if rung is None or r.get("execution_information_rung") == rung
            ]
            self.assertTrue(rows, f"{cell} seed {seed}: no retained receipt")
            pinned[seed] = endpoints(rows[0])
        return gate.evaluate_cell(cell, truth, pinned)


if __name__ == "__main__":
    unittest.main()
