import importlib.util
import csv
import hashlib
import json
import os
import sys
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

HERE = Path(__file__).resolve().parent
RUNNER_PATH = HERE / "run-0975.py"
spec = importlib.util.spec_from_file_location("run_0975", RUNNER_PATH)
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class TimingDesignTests(unittest.TestCase):
    def test_qualification_subset_receipt_pins_validated_master_seed_before_workers(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "prepared"
            source.mkdir()
            manifest_path = source / "manifest.csv"
            with manifest_path.open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=["index", "design_mode", "master_seed"])
                writer.writeheader()
                writer.writerows({"index": i, "design_mode": "qualification",
                                  "master_seed": 2026101704}
                                 for i in range(1, 3001))
            (source / "source-hashes.csv").write_text("path,sha256\nsource.R,abc\n")
            (source / "design-receipt.txt").write_text(
                "design_mode=qualification\nmaster_seed=2026101704\n")
            registry_sha = hashlib.sha256((source / "source-hashes.csv").read_bytes()).hexdigest()
            subset = root / "subset"

            def record_without_launch(indices, command_factory, outdir, *args, **kwargs):
                receipt = json.loads((outdir / "subset-receipt.json").read_text())
                self.assertEqual(receipt["master_seed"], 2026101704)
                self.assertEqual(receipt["design_mode"], "qualification")
                (outdir / "supervisor-receipt.json").write_text(json.dumps({
                    "interrupted": False, "subset_complete": True, "campaign_complete": False
                }))
                return {i: {"status": "completed"} for i in indices}

            with patch.object(sys, "argv", [str(RUNNER_PATH), str(source),
                                            "--indices", "1,1001,2001",
                                            "--subset-output", str(subset),
                                            "--registry-sha256", registry_sha]), \
                    patch.object(runner, "verify"), \
                    patch.object(runner, "supervise", side_effect=record_without_launch), \
                    patch.dict(os.environ, {"DRMTMB_SD_TEST_LIBRARY": str(root / "library")}):
                self.assertEqual(runner.main(), 0)

    def test_invalid_qualification_seed_never_launches_workers(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "prepared"
            source.mkdir()
            with (source / "manifest.csv").open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=["index", "design_mode", "master_seed"])
                writer.writeheader()
                writer.writerows({"index": i, "design_mode": "qualification",
                                  "master_seed": 2026101703}
                                 for i in range(1, 3001))
            (source / "source-hashes.csv").write_text("path,sha256\nsource.R,abc\n")
            (source / "design-receipt.txt").write_text(
                "design_mode=qualification\nmaster_seed=2026101703\n")
            registry_sha = hashlib.sha256((source / "source-hashes.csv").read_bytes()).hexdigest()
            with patch.object(sys, "argv", [str(RUNNER_PATH), str(source),
                                            "--indices", "1,1001,2001",
                                            "--subset-output", str(root / "subset"),
                                            "--registry-sha256", registry_sha]), \
                    patch.object(runner, "verify"), \
                    patch.object(runner, "supervise") as launch:
                with self.assertRaisesRegex(ValueError, "Qualification runs require"):
                    runner.main()
                launch.assert_not_called()
            self.assertFalse((root / "subset").exists(),
                             "invalid designs must be rejected before creating subset output")

    def test_missing_test_library_does_not_create_subset_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "prepared"
            source.mkdir()
            with (source / "manifest.csv").open("w", newline="") as stream:
                writer = csv.DictWriter(stream, fieldnames=["index", "design_mode", "master_seed"])
                writer.writeheader()
                writer.writerows({"index": i, "design_mode": "qualification",
                                  "master_seed": 2026101704}
                                 for i in range(1, 3001))
            (source / "source-hashes.csv").write_text("path,sha256\nsource.R,abc\n")
            (source / "design-receipt.txt").write_text(
                "design_mode=qualification\nmaster_seed=2026101704\n")
            registry_sha = hashlib.sha256((source / "source-hashes.csv").read_bytes()).hexdigest()
            subset = root / "subset"
            with patch.object(sys, "argv", [str(RUNNER_PATH), str(source),
                                            "--indices", "1,1001,2001",
                                            "--subset-output", str(subset),
                                            "--registry-sha256", registry_sha]), \
                    patch.object(runner, "verify"), \
                    patch.dict(os.environ, {}, clear=True):
                with self.assertRaisesRegex(SystemExit, "Set DRMTMB_SD_TEST_LIBRARY"):
                    runner.main()
            self.assertFalse(subset.exists(),
                             "missing worker configuration must be rejected before subset output")

    def test_runner_accepts_only_the_full_timing_design(self):
        self.assertTrue(hasattr(runner, "validate_design"))
        rows = [
            {"index": str(i), "design_mode": "timing_only", "master_seed": "2026101903"}
            for i in range(1, 46)
        ]
        design = {"design_mode": "timing_only", "master_seed": "2026101903",
                  "planned_attempts": "45", "profile_level": "0.975",
                  "calibration_claim": "false"}
        self.assertFalse(runner.validate_design(rows, design,
                                                indices=list(range(1, 46)), subset=False))
        for bad_rows, bad_design, bad_indices in [
            (rows, {**design, "master_seed": "2026101703"}, list(range(1, 46))),
            ([{**r, "design_mode": "production"} for r in rows], design, list(range(1, 46))),
            (rows[:-1], design, list(range(1, 45))),
            (rows[1:] + rows[:1], design, list(range(1, 46))),
            (rows, design, [1, 2]),
        ]:
            with self.assertRaises((ValueError, SystemExit)):
                runner.validate_design(bad_rows, bad_design, indices=bad_indices,
                                       subset=(len(bad_indices) != 45))

    def test_timing_supervisor_receipt_is_explicitly_non_calibration(self):
        class FinishedProcess:
            pid = 12345
            returncode = 0

            def poll(self):
                return 0

        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            (out / "manifest.csv").write_text("index\n1\n")
            with patch.object(runner.subprocess, "Popen", return_value=FinishedProcess()):
                runner.supervise([1], lambda _: ["mock-worker"], out,
                                 design_mode="timing_only", calibration_claim=False)
            import json
            receipt = json.loads((out / "supervisor-receipt.json").read_text())
            self.assertEqual(receipt["design_mode"], "timing_only")
            self.assertIs(receipt["calibration_claim"], False)
            with self.assertRaises(ValueError):
                runner.supervise([1], lambda _: ["mock-worker"], out / "bounded",
                                 workers=17, design_mode="timing_only",
                                 calibration_claim=False)

    def test_timing_receipt_cannot_claim_calibration_or_coverage(self):
        self.assertIn('"calibration_claim": bool(calibration_claim)',
                      RUNNER_PATH.read_text())
        self.assertIn('calibration_claim=calibration_claim', RUNNER_PATH.read_text())
        self.assertIn('return False', RUNNER_PATH.read_text())

    def test_preparer_exposes_strict_clean_timing_validation(self):
        source = (HERE / "prepare-0975.R").read_text()
        self.assertIn("validate_timing_manifest", source)
        self.assertIn("build_clean_bernoulli_manifests()$timing", source)
        self.assertIn('"tools/general-sd-regression/native-calibration/clean-manifests.R"', source)
        self.assertIn('"tools/general-sd-regression/native-calibration/summarize-timing-0975.R"', source)
        r_code = "\n".join([
            f"source({str(HERE / 'clean-manifests.R')!r})",
            f"source({str(HERE / 'prepare-0975.R')!r})",
            "expected <- build_clean_bernoulli_manifests()$timing",
            "root <- tempfile('timing-manifest-'); dir.create(root)",
            "write.csv(expected, file.path(root, 'good.csv'), row.names=FALSE)",
            "stopifnot(nrow(validate_timing_manifest(file.path(root, 'good.csv'))) == 45L)",
            "check_bad <- function(x) { write.csv(x, file.path(root, 'bad.csv'), row.names=FALSE); inherits(try(validate_timing_manifest(file.path(root, 'bad.csv')), silent=TRUE), 'try-error') }",
            "bad <- expected; bad$master_seed[] <- 2026101703L; stopifnot(check_bad(bad))",
            "bad <- expected; bad$design_mode[] <- 'clean_current'; stopifnot(check_bad(bad))",
            "stopifnot(check_bad(expected[-45L, ]))",
            "bad <- expected[c(2:45, 1), ]; stopifnot(check_bad(bad))",
            "unlink(root, recursive=TRUE)",
        ])
        result = subprocess.run(["Rscript", "-e", r_code], cwd=HERE.parents[2],
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_preparer_pins_the_first_look_summarizer(self):
        source = (HERE / "prepare-0975.R").read_text()
        self.assertIn('"tools/general-sd-regression/native-calibration/summarize-0975.R"', source)

    def test_first_look_summary_records_its_own_digest_when_not_campaign_pinned(self):
        source = (HERE / "summarize-0975.R").read_text()
        self.assertIn("analysis_script_sha256", source)
        self.assertIn("summary-tool-receipt.json", source)
        self.assertIn("summary_tool_registered", source)


if __name__ == "__main__":
    unittest.main()
