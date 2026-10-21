import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("cmr_recovery_generate", ROOT / "tools/cmr_recovery_generate.py")
generator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generator)


class RecoveryManifestV7Tests(unittest.TestCase):
    def test_v7_preserves_v6_design_and_admits_only_registered_stages(self):
        manifest, manifest_sha, source_sha = generator.verify_frozen_inputs(
            ROOT / "docs/dev-log/cmr/fixtures/recovery-manifest-v7.json"
        )
        self.assertEqual(manifest["schema_version"], 7)
        self.assertEqual(manifest_sha, generator.MANIFEST_V7_SHA256)
        self.assertEqual(source_sha, generator.GENERATOR_SHA256)
        primary = manifest["primary_cells"][0]["cell"]
        screen_only = manifest["screening_only_cells"][0]["cell"]

        for row in manifest["primary_cells"]:
            for replicate in (1, 2):
                generator.authorize(manifest, "pre_run", row["cell"], replicate,
                                    None, manifest_sha, source_sha)
            for replicate in (1001, 1010):
                generator.authorize(manifest, "pilot", row["cell"], replicate,
                                    None, manifest_sha, source_sha)
        for cell in (primary, screen_only):
            with self.assertRaises(generator.AdmissionError):
                generator.authorize(manifest, "screen", cell, 1, None, manifest_sha, source_sha)
        for cell, stage, replicate in (
            (primary, "pre_run", 3), (screen_only, "pre_run", 1),
            (primary, "pilot", 1011), (screen_only, "qualification", 1),
        ):
            with self.subTest(cell=cell, stage=stage), self.assertRaises(generator.AdmissionError):
                generator.authorize(manifest, stage, cell, replicate, None, manifest_sha, source_sha)

        receipt = {
            "reviewed": True,
            "prechecks_complete": True,
            "manifest_sha256": manifest_sha,
            "generator_source_sha256": source_sha,
            "paired_source_runtime": {
                "R": {"source_manifest_sha256": "a" * 64, "dll_sha256": "b" * 64,
                      "prerun_receipts_sha256": "c" * 64, "package_version": "0.7.1",
                      "runtime_version": "R 4.6.1", "worker_threads": "1",
                      "thread_environment": "BLAS=1"},
                "Julia": {"source_manifest_sha256": "d" * 64, "project_sha256": "e" * 64,
                          "environment_manifest_sha256": "f" * 64,
                          "prerun_receipts_sha256": "0" * 64, "package_version": "0.7.2",
                          "runtime_version": "Julia 1.12.6", "worker_threads": "1",
                          "thread_environment": "BLAS=1", "module_path": "/tmp/DRModels.jl",
                          "depot_path": "/tmp/julia-depot"},
            },
        }
        with tempfile.TemporaryDirectory() as temp:
            receipt_path = Path(temp) / "review.json"
            receipt_path.write_text(json.dumps(receipt), encoding="utf-8")
            for cell in (primary, screen_only):
                generator.authorize(manifest, "screen", cell, 1, receipt_path,
                                    manifest_sha, source_sha)
            generator.authorize(manifest, "qualification", primary, 1, receipt_path,
                                manifest_sha, source_sha)
            with self.assertRaises(generator.AdmissionError):
                generator.authorize(manifest, "qualification", screen_only, 1,
                                    receipt_path, manifest_sha, source_sha)

    def test_v7_fixed_prerun_generation_is_reproducible(self):
        with tempfile.TemporaryDirectory() as temp:
            out = Path(temp) / "dataset"
            metadata = generator.generate("m1_fixed_covariate", 1, "pre_run", out,
                                          ROOT / "docs/dev-log/cmr/fixtures/recovery-manifest-v7.json")
            self.assertEqual(metadata["manifest_schema_version"], 7)
            self.assertEqual(metadata["table_schema_version"], 4)
            self.assertEqual(set(metadata["sha256"]),
                             {"histories.csv", "phi_predictors.csv", "p_predictors.csv",
                              "truth.csv", "eligibility.csv"})


if __name__ == "__main__":
    unittest.main()
