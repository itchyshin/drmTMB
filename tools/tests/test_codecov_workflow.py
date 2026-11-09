"""Guard the Codecov producer/uploader split.

The producer must measure coverage without OIDC or a Codecov token. The
uploader may use GitHub OIDC only after a successful same-repo main push of
test-coverage. stdlib only; fails closed if a required string is missing or
appears only in a comment.
"""

from __future__ import annotations

import re
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PRODUCER = ROOT / ".github" / "workflows" / "test-coverage.yaml"
UPLOADER = ROOT / ".github" / "workflows" / "codecov-upload.yaml"
LAYOUT = ROOT / "tools" / "covr-source-tree-layout.sh"
JULIA_TESTTHAT = ROOT / "tools" / "covr-julia-bridge-testthat.R"
JULIA_PLANT = ROOT / "tools" / "covr-plant-julia-bridge-testthat.sh"

CODECOV_ACTION = (
    "codecov/codecov-action@0fb7174895f61a3b6b78fc075e0cd60383518dac"
)
CHECKOUT_ACTION = (
    "actions/checkout@11d5960a326750d5838078e36cf38b85af677262"
)
DOWNLOAD_ACTION = (
    "actions/download-artifact@d3f86a106a0bac45b974a628896c90dbdf5c8093"
)
UPLOAD_ARTIFACT = (
    "actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02"
)


def _noncomment_text(path: Path) -> str:
    lines = []
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("#"):
            lines.append(line)
    return "\n".join(lines)


def _active_lines(path: Path) -> list[str]:
    return [
        line.rstrip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]


class CodecovWorkflowTest(unittest.TestCase):
    def setUp(self) -> None:
        self.assertTrue(PRODUCER.is_file(), f"missing {PRODUCER}")
        self.assertTrue(UPLOADER.is_file(), f"missing {UPLOADER}")
        self.producer = _noncomment_text(PRODUCER)
        self.uploader = _noncomment_text(UPLOADER)

    def test_producer_has_no_oidc_or_codecov_token(self) -> None:
        self.assertNotIn("id-token", self.producer)
        self.assertNotIn("codecov/", self.producer)
        self.assertNotIn("CODECOV_TOKEN", self.producer)
        self.assertNotIn("pull_request_target", self.producer)

    def test_producer_partitions_one_os_four_shards(self) -> None:
        self.assertIn("runs-on: ubuntu-24.04", self.producer)
        self.assertIn("shard: [1, 2, 3, 4]", self.producer)
        self.assertIn('DRMTMB_TEST_SHARD: ${{ format(\'{0}/4\', matrix.shard) }}', self.producer)
        self.assertIn("NOT_CRAN: true", self.producer)
        self.assertIn("type = \"tests\"", self.producer)
        self.assertIn("covr::package_coverage(", self.producer)
        self.assertIn("covr::to_cobertura(cov, filename = \"cobertura.xml\")", self.producer)
        self.assertNotIn("macos", self.producer.lower())
        self.assertNotIn("windows", self.producer.lower())

    def test_trusted_artifact_is_main_push_only(self) -> None:
        self.assertIn(
            "if: github.event_name == 'push' && github.ref == 'refs/heads/main'",
            self.producer,
        )
        self.assertIn("name: main-coverage-shard-${{ matrix.shard }}", self.producer)
        self.assertIn("path: cobertura.xml", self.producer)
        self.assertIn(UPLOAD_ARTIFACT, self.producer)
        self.assertIn(
            "if: github.event_name == 'pull_request'",
            self.producer,
        )
        self.assertIn("name: pr-coverage-shard-${{ matrix.shard }}", self.producer)

    def test_uploader_is_main_workflow_run_oidc_only(self) -> None:
        self.assertIn("workflows: [test-coverage]", self.uploader)
        self.assertIn("branches: [main]", self.uploader)
        self.assertIn("github.event.workflow_run.event == 'push' &&", self.uploader)
        self.assertIn(
            "github.event.workflow_run.head_branch == 'main' &&",
            self.uploader,
        )
        self.assertIn(
            "github.event.workflow_run.head_repository.full_name == github.repository &&",
            self.uploader,
        )
        self.assertIn(
            "github.event.workflow_run.conclusion == 'success'",
            self.uploader,
        )
        self.assertIn("id-token: write", self.uploader)
        self.assertIn("use_oidc: true", self.uploader)
        self.assertIn("fail_ci_if_error: true", self.uploader)
        self.assertIn("disable_search: true", self.uploader)
        self.assertIn("plugins: noop", self.uploader)
        self.assertIn("version: v11.3.2", self.uploader)
        self.assertIn(CODECOV_ACTION, self.uploader)
        self.assertIn(CHECKOUT_ACTION, self.uploader)
        self.assertIn(DOWNLOAD_ACTION, self.uploader)
        self.assertIn("pattern: main-coverage-*", self.uploader)
        self.assertIn(
            "override_commit: ${{ github.event.workflow_run.head_sha }}",
            self.uploader,
        )
        self.assertNotIn("CODECOV_TOKEN", self.uploader)
        self.assertNotIn("pull_request_target", self.uploader)
        self.assertNotIn("secrets.CODECOV_TOKEN", self.uploader)
        self.assertNotIn("token: ${{ secrets", self.uploader)

    def test_uploader_pins_all_four_shard_reports(self) -> None:
        shard_files = [
            line
            for line in _active_lines(UPLOADER)
            if "files:" in line and "main-coverage-shard-" in line
        ]
        self.assertEqual(len(shard_files), 1)
        files_line = shard_files[0]
        for shard in (1, 2, 3, 4):
            self.assertIn(
                f"main-coverage-shard-{shard}/cobertura.xml",
                files_line,
            )

    def test_uploader_pins_julia_bridge_report_with_flag(self) -> None:
        julia_lines = [
            line
            for line in _active_lines(UPLOADER)
            if "main-coverage-julia-bridge/cobertura.xml" in line
        ]
        self.assertEqual(len(julia_lines), 1)
        self.assertIn("flags: julia-bridge", self.uploader)

    def test_producer_has_separate_julia_bridge_job(self) -> None:
        self.assertIn("julia-bridge-coverage:", self.producer)
        self.assertIn("DRMTMB_JULIA_TESTS: true", self.producer)
        self.assertIn("DRMODELS_JL_PATH:", self.producer)
        self.assertIn("julia-actions/setup-julia@v3", self.producer)
        self.assertIn("main-coverage-julia-bridge", self.producer)
        self.assertIn("tools/covr-plant-julia-bridge-testthat.sh", self.producer)
        self.assertIn("DRMTMB_COVERAGE_JULIA_FILTER", self.producer)

    def test_comment_cannot_satisfy_oidc_gate(self) -> None:
        mutated = re.sub(
            r"github\.event\.workflow_run\.event == 'push' &&",
            "",
            self.uploader,
            count=1,
        )
        self.assertNotIn(
            "github.event.workflow_run.event == 'push' &&",
            mutated,
        )

    def test_producer_plants_rcheck_layout_and_records_shas(self) -> None:
        self.assertIn("timeout-minutes: 180", self.producer)
        self.assertNotIn("timeout-minutes: 90", self.producer)
        self.assertNotIn("timeout-minutes: 120", self.producer)
        self.assertIn("tools/covr-source-tree-layout.sh", self.producer)
        self.assertIn("00_pkg_src", self.producer)
        self.assertIn("checkout_sha=", self.producer)
        self.assertIn("coverage_commit=", self.producer)
        self.assertIn("branch_head=", self.producer)
        self.assertIn(
            "github.event.pull_request.head.sha || github.sha",
            self.producer,
        )
        self.assertIn("sha_note=pull_request_merge_sha_is_not_branch_head", self.producer)
        self.assertNotIn("skip_on_covr", self.producer)

    def test_julia_bridge_plant_script_and_driver_exist(self) -> None:
        self.assertTrue(JULIA_TESTTHAT.is_file(), f"missing {JULIA_TESTTHAT}")
        self.assertTrue(JULIA_PLANT.is_file(), f"missing {JULIA_PLANT}")
        driver = JULIA_TESTTHAT.read_text(encoding="utf-8")
        self.assertIn("DRMTMB_JULIA_TESTS", driver)
        self.assertIn('filter = julia_filter', driver)

    def test_layout_script_plants_locator_walkup(self) -> None:
        self.assertTrue(LAYOUT.is_file(), f"missing {LAYOUT}")
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.check_call(
                ["bash", str(LAYOUT), tmp, str(ROOT)],
                cwd=str(ROOT),
            )
            planted = Path(tmp) / "00_pkg_src" / "drmTMB"
            for rel in (
                "DESCRIPTION",
                "R/drmTMB.R",
                "man/is_converged.Rd",
                "src/drmTMB.cpp",
            ):
                self.assertTrue(
                    (planted / rel).exists(),
                    f"missing planted {rel}",
                )
            # covr testInstalledPackage cwd:
            # <lib>/drmTMB/drmTMB-tests/testthat. Walk-up parent 3 is <lib>.
            fake_testthat = (
                Path(tmp) / "drmTMB" / "drmTMB-tests" / "testthat"
            )
            fake_testthat.mkdir(parents=True)
            lib_root = fake_testthat.parents[2]
            self.assertEqual(lib_root, Path(tmp).resolve())
            self.assertTrue(
                (lib_root / "00_pkg_src" / "drmTMB" / "src" / "drmTMB.cpp").is_file()
            )
            self.assertTrue(
                (lib_root / "00_pkg_src" / "drmTMB" / "man" / "is_converged.Rd").is_file()
            )
            self.assertTrue(
                (lib_root / "00_pkg_src" / "drmTMB" / "R" / "drmTMB.R").is_file()
            )


if __name__ == "__main__":
    unittest.main()
