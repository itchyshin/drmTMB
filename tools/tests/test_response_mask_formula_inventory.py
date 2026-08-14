import importlib.util
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = ROOT / "tools/response_mask_formula_inventory.py"
SPEC = importlib.util.spec_from_file_location("response_mask_formula_inventory", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class TestResponseMaskFormulaInventory(unittest.TestCase):
    def test_every_model_cell_has_one_formula_inventory_row(self):
        cells = MODULE.read_tsv(MODULE.CELLS)
        inventory = MODULE.build(cells)
        model_ids = {row["cell_id"] for row in cells if row["axis"] == "model_surface"}
        inventory_model_ids = {row["model_cell_id"] for row in inventory if row["model_cell_id"]}
        self.assertEqual(inventory_model_ids, model_ids)
        self.assertEqual(len(inventory), len(model_ids) + len(MODULE.EXPLICIT_BOUNDARIES))

    def test_blocked_reml_and_dense_bivariate_known_v_are_never_promoted_from_family_masks(self):
        cells = MODULE.read_tsv(MODULE.CELLS)
        inventory = MODULE.build(cells)
        self.assertTrue(any(row["formula_status"] == "blocked_reml" for row in inventory))
        self.assertTrue(any(row["formula_status"] == "blocked_dense_known_V" for row in inventory))
        self.assertTrue(all(
            row["formula_mask_gate"] == "G0"
            for row in inventory if row["formula_status"] == "blocked_reml"
        ))
        self.assertTrue(all(
            row["formula_mask_gate"] == "G0"
            for row in inventory if row["formula_status"] == "blocked_dense_known_V"
        ))

    def test_named_gaussian_reml_formula_records_its_own_g2_g3_evidence(self):
        cells = MODULE.read_tsv(MODULE.CELLS)
        inventory = MODULE.build(cells)
        row = next(row for row in inventory if row["model_cell_id"] == "mc-0265")
        self.assertEqual(row["formula_status"], "formula_validated")
        self.assertEqual(row["formula_mask_gate"], "G3")

    def test_non_fixed_implemented_cells_require_formula_specific_evidence(self):
        cells = MODULE.read_tsv(MODULE.CELLS)
        inventory = MODULE.build(cells)
        self.assertTrue(any(
            row["formula_status"] == "needs_formula_evidence"
            for row in inventory
        ))


if __name__ == "__main__":
    unittest.main()
