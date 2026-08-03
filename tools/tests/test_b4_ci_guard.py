"""Contract for the shared B4-CI neighbour guard.

Pins the semantics the four cohort scripts now rely on: identity is frozen
forever, evidence-bearing fields may move but only with recorded provenance, and
a cohort may never claim a row outside its own allowlist.
"""

import sys
import unittest

sys.path.insert(0, "tools")
import b4_ci_guard


def row(cell_id, *, source_order="100", tier="point_fit_recovery", primary="ev-x-legacy", boundary="b"):
    return {
        "cell_id": cell_id,
        "source_order": source_order,
        "axis": "model_surface",
        "family_route": "gaussian",
        "family_type": "continuous",
        "model_type": "univariate",
        "dpar": "mu",
        "effect_type": "structured",
        "structure_provider": "phylo",
        "dimension": "univariate",
        "estimator": "ML",
        "evidence_tier": tier,
        "primary_evidence_id": primary,
        "claim_boundary": boundary,
    }


def transition(cell_id, transition_id, evidence_ids):
    return {"cell_id": cell_id, "transition_id": transition_id, "evidence_ids": evidence_ids}


class NeighbourGuardTest(unittest.TestCase):
    def test_unchanged_row_is_clean(self):
        base = {"mc-0001": row("mc-0001")}
        self.assertEqual(
            b4_ci_guard.unexplained_drift(
                protected_ids={"mc-0001"}, base_cells=base, local_cells=dict(base), transitions=[]
            ),
            [],
        )

    def test_provenance_accounted_move_is_allowed(self):
        base = {"mc-0001": row("mc-0001")}
        local = {"mc-0001": row("mc-0001", tier="interval_feasible", primary="ev-mc-0001-arcN")}
        problems = b4_ci_guard.unexplained_drift(
            protected_ids={"mc-0001"},
            base_cells=base,
            local_cells=local,
            transitions=[transition("mc-0001", "tr-mc-0001-arcN", "ev-mc-0001-arcN")],
        )
        self.assertEqual(problems, [])

    def test_move_without_a_transition_is_rejected(self):
        base = {"mc-0001": row("mc-0001")}
        local = {"mc-0001": row("mc-0001", tier="interval_feasible", primary="ev-mc-0001-arcN")}
        problems = b4_ci_guard.unexplained_drift(
            protected_ids={"mc-0001"}, base_cells=base, local_cells=local, transitions=[]
        )
        self.assertEqual(len(problems), 1)
        self.assertIn("no recorded transition", problems[0][1])

    def test_identity_change_is_always_rejected(self):
        """Even with a transition that would otherwise account for the row."""
        base = {"mc-0001": row("mc-0001")}
        local = {"mc-0001": row("mc-0001", source_order="999", primary="ev-mc-0001-arcN")}
        problems = b4_ci_guard.unexplained_drift(
            protected_ids={"mc-0001"},
            base_cells=base,
            local_cells=local,
            transitions=[transition("mc-0001", "tr-mc-0001-arcN", "ev-mc-0001-arcN")],
        )
        self.assertEqual(len(problems), 1)
        self.assertIn("identity fields changed: source_order", problems[0][1])

    def test_cohort_claiming_a_neighbour_is_rejected(self):
        """The violation the guard exists to catch, now named explicitly."""
        base = {"mc-0001": row("mc-0001")}
        local = {"mc-0001": row("mc-0001", tier="interval_feasible", primary="ev-mine")}
        problems = b4_ci_guard.unexplained_drift(
            protected_ids={"mc-0001"},
            base_cells=base,
            local_cells=local,
            transitions=[transition("mc-0001", "tr-mine", "ev-mine")],
            cohort_evidence_ids={"ev-mine"},
            cohort_transition_ids={"tr-mine"},
        )
        self.assertEqual(len(problems), 1)
        self.assertIn("this cohort claims it", problems[0][1])

    def test_a_cohorts_own_transition_cannot_account_for_a_neighbour(self):
        base = {"mc-0001": row("mc-0001")}
        local = {"mc-0001": row("mc-0001", tier="interval_feasible", primary="ev-other")}
        problems = b4_ci_guard.unexplained_drift(
            protected_ids={"mc-0001"},
            base_cells=base,
            local_cells=local,
            transitions=[transition("mc-0001", "tr-mine", "ev-other")],
            cohort_transition_ids={"tr-mine"},
        )
        self.assertEqual(len(problems), 1)

    def test_deleted_row_is_rejected(self):
        problems = b4_ci_guard.unexplained_drift(
            protected_ids={"mc-0001"},
            base_cells={"mc-0001": row("mc-0001")},
            local_cells={},
            transitions=[],
        )
        self.assertEqual(len(problems), 1)
        self.assertIn("absent", problems[0][1])

    def test_row_created_after_the_freeze_is_ignored(self):
        problems = b4_ci_guard.unexplained_drift(
            protected_ids={"mc-9999"},
            base_cells={},
            local_cells={"mc-9999": row("mc-9999")},
            transitions=[],
        )
        self.assertEqual(problems, [])

    def test_identity_digest_ignores_evidence_bearing_fields(self):
        a = [row("mc-0001", tier="point_fit_recovery", primary="ev-a", boundary="x")]
        b = [row("mc-0001", tier="interval_feasible", primary="ev-b", boundary="y")]
        self.assertEqual(b4_ci_guard.identity_digest(a), b4_ci_guard.identity_digest(b))

    def test_identity_digest_detects_identity_change(self):
        a = [row("mc-0001")]
        b = [row("mc-0001", source_order="999")]
        self.assertNotEqual(b4_ci_guard.identity_digest(a), b4_ci_guard.identity_digest(b))

    def test_unaccounted_provenance_local_only(self):
        local = {"mc-0001": row("mc-0001", primary="ev-a")}
        self.assertEqual(
            b4_ci_guard.unaccounted_provenance(
                cell_ids={"mc-0001"},
                local_cells=local,
                transitions=[transition("mc-0001", "tr-a", "ev-a")],
            ),
            [],
        )
        self.assertEqual(
            len(b4_ci_guard.unaccounted_provenance(
                cell_ids={"mc-0001"}, local_cells=local, transitions=[]
            )),
            1,
        )

    def test_semicolon_separated_evidence_ids_are_split(self):
        local = {"mc-0001": row("mc-0001", primary="ev-b")}
        self.assertEqual(
            b4_ci_guard.unaccounted_provenance(
                cell_ids={"mc-0001"},
                local_cells=local,
                transitions=[transition("mc-0001", "tr-a", "ev-a;ev-b;ev-c")],
            ),
            [],
        )


if __name__ == "__main__":
    unittest.main()
