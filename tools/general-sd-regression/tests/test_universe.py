import copy
import importlib.util
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "universe.py"
spec = importlib.util.spec_from_file_location("sd_universe", SCRIPT)
universe = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(universe)


class RequiredUniverseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.endpoints = universe.read_tsv(universe.ENDPOINTS_PATH)
        cls.mechanisms = universe.read_tsv(universe.MECHANISMS_PATH)
        cls.links = universe.read_tsv(universe.LINKS_PATH)
        cls.block_rules = universe.read_tsv(universe.BLOCK_RULES_PATH)
        cls.rows = universe.generate_rows(cls.endpoints, cls.mechanisms, cls.links, cls.block_rules)

    def test_expansion_is_deterministic_and_has_unique_keys(self):
        again = universe.generate_rows(self.endpoints, self.mechanisms, self.links, self.block_rules)
        self.assertEqual(self.rows, again)
        keys = [row["row_key"] for row in self.rows]
        self.assertEqual(len(keys), len(set(keys)))
        self.assertGreater(len(self.rows), 5438)

    def test_each_endpoint_mechanism_is_retained_for_both_engines(self):
        scalar_mechanisms = {
            row["template_id"] for row in self.mechanisms
            if not row["template_id"].endswith("labelled_block")
            and row["template_id"] != "iid_labelled_cross_parameter"
        }
        expected = {
            (engine, endpoint["family_route"], endpoint["endpoint"], mechanism)
            for engine in universe.ENGINES
            for endpoint in self.endpoints
            for mechanism in scalar_mechanisms
        }
        observed = {
            (row["engine"], row["family_route"], row["endpoint"], row["mechanism_id"])
            for row in self.rows
            if row["mechanism_id"] in scalar_mechanisms
        }
        self.assertEqual(expected, observed)

    def test_link_variants_are_not_lost(self):
        observed = {
            (row["engine"], row["link_variant"])
            for row in self.rows
            if row["family_route"] == "binomial"
        }
        self.assertEqual(
            observed,
            {("native", "logit"), ("native", "probit"),
             ("native", "cloglog"), ("Julia", "logit"),
             ("Julia", "probit"), ("Julia", "cloglog")},
        )
        incomplete = [row for row in self.links if not (row["engine"] == "Julia" and row["family_route"] == "binomial" and row["link_variant"] == "probit")]
        with self.assertRaisesRegex(ValueError, "link registry coverage mismatch"):
            universe.check_inputs(self.endpoints, self.mechanisms, incomplete, self.block_rules)
        incomplete = [row for row in self.links if not (row["engine"] == "Julia" and row["family_route"] == "binomial" and row["link_variant"] == "cloglog")]
        with self.assertRaisesRegex(ValueError, "link registry coverage mismatch"):
            universe.check_inputs(self.endpoints, self.mechanisms, incomplete, self.block_rules)
        incorrectly_admitted = copy.deepcopy(self.links)
        row = next(r for r in incorrectly_admitted if r["engine"] == "Julia" and r["family_route"] == "binomial" and r["link_variant"] == "probit")
        row["base_link_status"] = "admitted"
        with self.assertRaisesRegex(ValueError, "base-link status mismatch"):
            universe.check_inputs(self.endpoints, self.mechanisms, incorrectly_admitted, self.block_rules)
        # Negative control: a non-binomial singleton link cannot silently fall
        # back to an implicit default.
        incomplete = [row for row in self.links if not (row["engine"] == "Julia" and row["family_route"] == "student")]
        with self.assertRaisesRegex(ValueError, "link registry family coverage mismatch"):
            universe.check_inputs(self.endpoints, self.mechanisms, incomplete, self.block_rules)
        self.assertFalse(any(row["link_variant"] == "single_or_family_default" for row in self.rows))
        added = [r for r in self.rows if r["engine"] == "Julia" and r["family_route"] == "binomial" and r["link_variant"] in {"probit", "cloglog"}]
        self.assertEqual(len(added), 122)
        self.assertEqual(sum(r["status"] == "structural_inapplicable" for r in added), 18)
        self.assertEqual(sum(r["status"] == "blocked_base_plumbing" for r in added), 104)
        self.assertTrue(all("base link route is not admitted" in r["status_reason"]
                            for r in added if r["status"] != "structural_inapplicable"))
        promoted_link = copy.deepcopy(self.rows)
        row = next(r for r in promoted_link if r["engine"] == "Julia" and r["family_route"] == "binomial" and r["link_variant"] == "probit" and r["status"] == "blocked_base_plumbing")
        row["status"] = "required"
        with self.assertRaisesRegex(ValueError, "contents differ"):
            universe.validate_rows(promoted_link, self.endpoints, self.mechanisms, self.links, self.block_rules)
        with self.assertRaisesRegex(ValueError, "duplicate engine/family/link"):
            universe.check_inputs(self.endpoints, self.mechanisms, self.links + [self.links[0]], self.block_rules)

    def test_missing_or_duplicate_endpoint_source_fails_closed(self):
        with self.assertRaisesRegex(ValueError, "expected 54 endpoint rows"):
            universe.check_inputs(self.endpoints[:-1], self.mechanisms, self.links, self.block_rules)
        duplicate = self.endpoints[:-1] + [self.endpoints[0]]
        with self.assertRaisesRegex(ValueError, "duplicate family/dimension/endpoint"):
            universe.check_inputs(duplicate, self.mechanisms, self.links, self.block_rules)

    def test_missing_endpoint_or_engine_rows_fail_coverage(self):
        removed_endpoint = copy.deepcopy(self.rows)
        removed_endpoint.pop(0)
        with self.assertRaisesRegex(ValueError, "coverage mismatch"):
            universe.validate_rows(removed_endpoint, self.endpoints, self.mechanisms, self.links, self.block_rules)
        removed_engine = [row for row in self.rows if row["engine"] != "Julia"]
        with self.assertRaisesRegex(ValueError, "coverage mismatch"):
            universe.validate_rows(removed_engine, self.endpoints, self.mechanisms, self.links, self.block_rules)

    def test_duplicate_keys_and_support_promotion_fail_closed(self):
        duplicate = self.rows + [self.rows[0]]
        with self.assertRaisesRegex(ValueError, "duplicate row_key"):
            universe.validate_rows(duplicate, self.endpoints, self.mechanisms, self.links, self.block_rules)
        promoted = copy.deepcopy(self.rows)
        promoted[0]["status"] = "supported"
        with self.assertRaisesRegex(ValueError, "unsupported status"):
            universe.validate_rows(promoted, self.endpoints, self.mechanisms, self.links, self.block_rules)
        narrowed = copy.deepcopy(self.rows)
        required = next(row for row in narrowed if row["status"] == "required")
        required["status"] = "blocked_base_plumbing"
        with self.assertRaisesRegex(ValueError, "contents differ"):
            universe.validate_rows(narrowed, self.endpoints, self.mechanisms, self.links, self.block_rules)
        promoted = copy.deepcopy(self.rows)
        promoted[0]["direct_sd_claim"] = "supported"
        with self.assertRaisesRegex(ValueError, "must not claim"):
            universe.validate_rows(promoted, self.endpoints, self.mechanisms, self.links, self.block_rules)

    def test_provider_inputs_layouts_and_phylo_matrix_omission_are_visible(self):
        inputs = {
            row["mechanism_id"]: {r["provider_input"] for r in self.rows if r["mechanism_id"] == row["mechanism_id"]}
            for row in self.rows
        }
        self.assertEqual(inputs["animal_intercept"], {"pedigree", "A_covariance", "Ainv_precision"})
        self.assertEqual(inputs["relmat_intercept"], {"K_covariance", "Q_precision"})
        self.assertEqual(inputs["spatial_coordinate_intercept"], {"coordinates"})
        self.assertEqual(inputs["spatial_mesh_intercept"], {"mesh_precision_fixed_kappa"})
        additive = [row for row in self.rows if row["mechanism_id"] == "iid_additive_terms"]
        self.assertEqual({row["layout"] for row in additive}, {"crossed", "nested"})
        iid_pairs = {
            row["provider_input"] for row in self.rows
            if row["mechanism_id"] == "simultaneous_iid_structured"
        }
        self.assertEqual(len(iid_pairs), 6)
        self.assertTrue(any("iid:group_factor+phylo:tree" == item for item in iid_pairs))
        self.assertTrue(any("iid:group_factor+animal:Ainv_precision" == item for item in iid_pairs))
        structured_pairs = {
            row["provider_input"] for row in self.rows
            if row["mechanism_id"] == "simultaneous_structured_structured"
        }
        self.assertEqual(len(structured_pairs), 12)
        self.assertIn("phylo:tree+spatial:coordinates", structured_pairs)
        self.assertIn("animal:Ainv_precision+relmat:Q_precision", structured_pairs)
        phylo_matrix = [
            row for row in self.rows
            if row["mechanism_id"] == "phylo_intercept"
            and row["engine"] == "Julia"
            and row["provider_input"] in {"phylo_covariance_matrix", "phylo_precision_matrix"}
        ]
        self.assertTrue(phylo_matrix)
        self.assertTrue(all(row["status"] == "blocked_base_plumbing" for row in phylo_matrix))
        self.assertEqual({row["mechanism_id"] for row in phylo_matrix}, {"phylo_intercept"})
        native_temporal = [
            row for row in self.rows
            if row["engine"] == "native" and row["mechanism_id"].startswith("temporal_")
        ]
        self.assertTrue(native_temporal)
        self.assertTrue(all(row["status"] == "blocked_base_plumbing" for row in native_temporal))

    def test_missing_block_dimension_rule_fails_closed(self):
        with self.assertRaisesRegex(ValueError, "expected 148 block-dimension rules"):
            universe.check_inputs(self.endpoints, self.mechanisms, self.links,
                                  self.block_rules[:-1])

    def test_block_rules_materialize_member_and_q_dimensions(self):
        q2 = [r for r in self.rows if r["family_route"] == "biv_gaussian" and
              r["engine"] == "native" and r["mechanism_id"] == "iid_labelled_cross_parameter" and
              r["block_rule_id"] == "O-biv-mean2-I"]
        self.assertEqual({r["target_member"] for r in q2}, {"mu1:I", "mu2:I"})
        self.assertTrue(all(r["endpoint_members"] == "mu1,mu2" and r["q_value"] == "2" for r in q2))
        q4 = [r for r in self.rows if r["family_route"] == "biv_gaussian" and
              r["engine"] == "native" and r["block_rule_id"] == "O-biv-mean-m-q4-anchor"]
        self.assertEqual({r["target_member"] for r in q4},
                         {f"{d}:{coef}" for d in ("mu1", "mu2") for coef in ("I", "x1")})
        q3 = [r for r in self.rows if r["family_route"] == "gaussian" and
              r["engine"] == "native" and r["mechanism_id"] == "iid_correlated_block" and
              r["block_rule_id"] == "O-multi-within-q3-anchor"]
        self.assertEqual({r["target_member"] for r in q3}, {"mu:I", "mu:x1", "mu:x2", "sigma:I", "sigma:x1", "sigma:x2"})
        structured_q12 = [r for r in self.rows if r["family_route"] == "biv_gaussian" and
              r["engine"] == "native" and r["block_rule_id"] == "S-biv-all4-m-q12-anchor"]
        self.assertEqual(len(structured_q12), 96)
        self.assertTrue(all(r["q_value"] == "12" for r in structured_q12))
        block_diagonal = [r for r in self.rows if r["family_route"] == "biv_gaussian" and
              r["engine"] == "native" and r["block_rule_id"].startswith("S-biv-all4-blockdiag")]
        self.assertEqual({r["block_rule_id"] for r in block_diagonal},
                         {"S-biv-all4-blockdiag-mu", "S-biv-all4-blockdiag-sigma"})
        symbolic = [r for r in self.rows if r["block_rule_id"] == "O-biv-mean-m"]
        self.assertTrue(symbolic)
        self.assertTrue(all("p>=1" in r["q_domain"] for r in symbolic))
        julia_partitions = {r["partition_rule"] for r in self.rows
            if r["engine"] == "Julia" and r["family_route"] == "biv_gaussian"
            and r["block_rule_id"] == "J-biv-structured4-tagged-partitions"}
        self.assertEqual(len(julia_partitions), 15)
        self.assertFalse(any(r["endpoint_members"] == "unresolved_multi_endpoint_member_set" for r in self.rows))
        self.assertFalse(any(r["block_rule_id"] == "unreviewed_exact_endpoint_tuple" for r in self.rows))
        self.assertFalse(any(r["status"] == "supported" or r["direct_sd_claim"] != "none" for r in self.rows))

    def test_cross_engine_tagged_q4_partitions_are_mirrored_as_blocked_native_rows(self):
        mirror_rules = [r for r in self.block_rules
                        if r["engine"] == "native"
                        and r["rule_id"] == "J-biv-structured4-tagged-partitions"]
        self.assertEqual(len(mirror_rules), 4)
        self.assertTrue(all("Julia@" in r["source_pin"] for r in mirror_rules))
        self.assertTrue(all("native tagged-partition plumbing is absent" in r["source_shape_note"]
                            for r in mirror_rules))
        tagged = [r for r in self.rows if r["engine"] == "Julia"
                  and r["q_value"] == "4" and r["partition_rule"].startswith("tagged:")]
        self.assertTrue(tagged)
        fields = [name for name in universe.KEY_FIELDS if name != "engine"]
        native = {tuple(r[name] for name in fields): r for r in self.rows
                  if r["engine"] == "native"}
        for row in tagged:
            counterpart = native.get(tuple(row[name] for name in fields))
            self.assertIsNotNone(counterpart, row["row_key"])
            self.assertEqual(counterpart["status"], "blocked_base_plumbing")
            self.assertIn("native", counterpart["status_reason"].lower())
        # Negative control: removing even one exact engine mirror must fail.
        without_mirror = [r for r in self.rows if not (
            r["engine"] == "native"
            and r["block_rule_id"] == "J-biv-structured4-tagged-partitions"
            and r["partition_rule"].startswith("tagged:")
        )]
        with self.assertRaisesRegex(ValueError, "coverage mismatch"):
            universe.validate_rows(without_mirror, self.endpoints, self.mechanisms,
                                   self.links, self.block_rules)

    def test_candidate_cross_endpoint_sets_cover_actual_family_subsets(self):
        candidates = [r for r in self.rows if r["block_rule_id"].startswith("candidate-")]
        self.assertTrue(candidates)
        for family in {r["family_route"] for r in self.endpoints}:
            endpoints = sorted({r["endpoint"] for r in self.endpoints
                                if r["family_route"] == family})
            if len(endpoints) < 2:
                continue
            for mechanism in universe.CROSS_ENDPOINT_BLOCKS:
                source_sets = universe.source_member_sets(
                    family, mechanism, self.block_rules
                )
                expected = {
                    tuple(combo)
                    for size in range(2, len(endpoints) + 1)
                    for combo in __import__("itertools").combinations(endpoints, size)
                    if tuple(combo) not in source_sets
                }
                observed = {
                    tuple(r["endpoint_members"].split(","))
                    for r in candidates
                    if r["engine"] == "native" and r["family_route"] == family
                    and r["mechanism_id"] == mechanism
                }
                self.assertEqual(expected, observed, (family, mechanism))
        self.assertTrue(all(r["status"] in {"unresolved", "blocked_base_plumbing"}
                            for r in candidates))
        self.assertTrue(all(r["direct_sd_claim"] == "none" for r in candidates))
        self.assertTrue(all("candidate_contract=" in r["source_evidence"] for r in candidates))
        # Negative control: dropping one entire endpoint member subset across
        # engines/providers/targets must fail closed.
        candidate = next(r for r in candidates if r["engine"] == "native")
        lost_subset = (candidate["family_route"], candidate["mechanism_id"],
                       candidate["endpoint_members"], candidate["block_rule_id"])
        without_candidate = [r for r in self.rows if (
            r["family_route"], r["mechanism_id"], r["endpoint_members"],
            r["block_rule_id"]
        ) != lost_subset]
        with self.assertRaisesRegex(ValueError, "coverage mismatch"):
            universe.validate_rows(without_candidate, self.endpoints, self.mechanisms,
                                   self.links, self.block_rules)

    def test_mesh_q1_limit_is_not_a_structural_exclusion(self):
        mesh_blocks = [r for r in self.rows if r["mechanism_id"] ==
                       "spatial_coordinate_labelled_block"
                       and r["provider_input"] == "mesh_precision"
                       and r["q_value"]
                       and len({ep["endpoint"] for ep in self.endpoints
                                if ep["family_route"] == r["family_route"]}) > 1]
        self.assertTrue(mesh_blocks)
        self.assertTrue(all(r["status"] == "blocked_base_plumbing" for r in mesh_blocks))
        self.assertTrue(all(
            "q1" in r["status_reason"] or "tagged-partition plumbing is absent" in r["status_reason"]
            for r in mesh_blocks if r["engine"] == "native"
        ))
        self.assertTrue(all("mesh" in r["status_reason"] for r in mesh_blocks
                            if r["engine"] == "Julia"))
        # Negative control: a q1-only source boundary cannot be relabeled as
        # mathematical inapplicability without changing the deterministic row.
        mislabeled = copy.deepcopy(self.rows)
        row = next(r for r in mislabeled if r["mechanism_id"] ==
                   "spatial_coordinate_labelled_block"
                   and r["provider_input"] == "mesh_precision"
                   and r["q_value"])
        row["status"] = "structural_inapplicable"
        with self.assertRaisesRegex(ValueError, "contents differ"):
            universe.validate_rows(mislabeled, self.endpoints, self.mechanisms,
                                   self.links, self.block_rules)

    def test_block_rule_provenance_is_mandatory(self):
        missing_source = copy.deepcopy(self.block_rules)
        missing_source[0]["source_pin"] = ""
        with self.assertRaisesRegex(ValueError, "block rule missing source provenance"):
            universe.check_inputs(self.endpoints, self.mechanisms, self.links,
                                  missing_source)

    def test_single_endpoint_never_becomes_a_one_member_block(self):
        rows = [
            row for row in self.rows
            if row["family_route"] == "binomial"
            and row["mechanism_id"] == "iid_labelled_cross_parameter"
        ]
        self.assertTrue(rows)
        self.assertTrue(all(row["status"] == "structural_inapplicable" for row in rows))
        self.assertTrue(all(row["endpoint_members"] == "none" for row in rows))


if __name__ == "__main__":
    unittest.main()
