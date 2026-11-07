#!/usr/bin/env python3
"""Keep historical 97.5% evidence separate from the current 95% stage-two route."""
from pathlib import Path
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[3]
CAL = ROOT / "tools/general-sd-regression/native-calibration"
ADAPTER = CAL.parent / "native-calibration-stage-two"


class ProfileLevelHarnessTests(unittest.TestCase):
    def test_frozen_harness_files_are_unchanged(self):
        paths = [
            "tools/general-sd-regression/native-calibration/prepare.R",
            "tools/general-sd-regression/native-calibration/worker.R",
            "tools/general-sd-regression/native-calibration/run.py",
        ]
        subprocess.run(["git", "diff", "--exit-code", "HEAD", "--", *paths],
                       cwd=ROOT, check=True, capture_output=True, text=True)

    def test_versioned_worker_requests_and_verifies_0975(self):
        worker = (CAL / "worker-0975.R").read_text()
        self.assertIn('method = "profile", level = 0.975', worker)
        self.assertIn("profile_level = 0.975", worker)
        self.assertIn("returned_level <- suppressWarnings(as.numeric(ci$level))", worker)
        self.assertIn("abs(returned_level - 0.975) > 1e-12", worker)

    def test_runner_and_preparer_pin_only_the_versioned_worker(self):
        runner = (CAL / "run-0975.py").read_text()
        prepare = (CAL / "prepare-0975.R").read_text()
        self.assertIn('with_name("worker-0975.R")', runner)
        self.assertIn('"tools/general-sd-regression/native-calibration/worker-0975.R"',
                      prepare)
        self.assertIn('"tools/general-sd-regression/native-calibration/run-0975.py"',
                      prepare)
        self.assertIn('"tools/general-sd-regression/native-calibration/run.py"', prepare)
        self.assertIn('"design_id=native-bernoulli-sd-ordinary-q1-profile-0975-v1"',
                      prepare)
        self.assertIn('"profile_level=0.975"', prepare)

    def test_adapter_requires_current_095_worker_and_rejects_mixed_levels(self):
        rules = (ADAPTER / "stage-two-rules.R").read_text()
        verify = (ADAPTER / "verify-first-look.R").read_text()
        stage_two = (ADAPTER / "stage_two.py").read_text()
        qualification = (ADAPTER / "run-adapter-qualification.py").read_text()
        self.assertIn("native_sd_stage_two_validate_profile_level", rules)
        self.assertIn('"Profile attempts must all use the required 95% interval level"',
                      rules)
        self.assertIn("native_sd_stage_two_validate_profile_level(rr)", verify)
        self.assertIn('BASE / "worker-095.R"', stage_two)
        self.assertIn('BASE / "worker-095.R"', qualification)
        self.assertNotIn('BASE / "worker-0975.R"', stage_two)
        summary = (CAL / "summarize-095.R").read_text()
        self.assertIn('"native-calibration/summarize-095.R"', summary)
        self.assertIn("native_sd_stage_two_validate_profile_level(results)", summary)


if __name__ == "__main__":
    unittest.main()
