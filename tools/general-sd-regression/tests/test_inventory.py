import importlib.util
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "inventory.py"
SPEC = importlib.util.spec_from_file_location("sd_inventory", MODULE_PATH)
inventory = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(inventory)


class JuliaRegistryTests(unittest.TestCase):
    def test_default_revisions_are_immutable_paired_baselines(self):
        self.assertEqual(
            inventory.NATIVE_BASE_PIN,
            "d89db50975d96d9c2bcb13046453ae34c7fcf49b",
        )
        self.assertEqual(
            inventory.JULIA_BASE_PIN,
            "b1832c7a686decf4e3d7a06ad8382bf164b9d8d4",
        )

    def test_registry_rows_preserve_wildcards_enumerations_and_flags(self):
        source = '''drm_julia_family_registry <- function() {
  list(
    spec("gaussian", predictor_dpars = "*",
         fe = TRUE, locscale_phylo = TRUE, structured = TRUE),
    spec("biv_gaussian", predictor_dpars = c("mu1", "sigma1"),
         fe = TRUE)
  )
}'''
        rows = inventory.parse_julia_registry(source)
        self.assertEqual([row["family"] for row in rows], ["gaussian", "biv_gaussian"])
        self.assertEqual(rows[0]["predictor_dpars"], "*")
        self.assertEqual(rows[0]["flags"]["locscale_phylo"], True)
        self.assertEqual(rows[1]["predictor_dpars"], ["mu1", "sigma1"])
        self.assertEqual(rows[1]["flags"]["locscale_phylo"], False)

    def test_negative_control_keeps_family_missing_from_registry_visible(self):
        # If a registry row is accidentally omitted, the inventory must retain
        # that route as required work rather than silently calling it unsupported.
        rows = inventory.registry_family_coverage(
            ["gaussian", "bernoulli", "gamma"], {"gaussian", "gamma"}
        )
        self.assertEqual(
            [(row["family_route"], row["status"]) for row in rows],
            [
                ("bernoulli", "required"),
                ("gamma", "structural_reviewed"),
                ("gaussian", "structural_reviewed"),
            ],
        )
        self.assertIsNone(rows[0]["registry_family"])

    def test_duplicate_registry_rows_fail_closed(self):
        source = '''spec("gaussian", predictor_dpars = "*"),
spec("gaussian", predictor_dpars = "*")'''
        with self.assertRaisesRegex(ValueError, "duplicate family"):
            inventory.parse_julia_registry(source)


class LedgerSummaryTests(unittest.TestCase):
    def test_marginal_axes_do_not_invent_crossproduct_rows(self):
        rows = [
            {"family_route": "gaussian", "structure_provider": "none", "axis": "model_surface"},
            {"family_route": "beta", "structure_provider": "animal", "axis": "model_surface"},
        ]
        self.assertEqual(inventory.axis_values(rows, "family_route"), ["beta", "gaussian"])
        self.assertEqual(inventory.count_axis(rows, "structure_provider"), {"animal": 1, "none": 1})
        self.assertEqual(len(rows), 2)


if __name__ == "__main__":
    unittest.main()
