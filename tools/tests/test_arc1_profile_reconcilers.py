"""Adversarial tests for the Arc 1 target-specific profile reconcilers."""

from __future__ import annotations

import csv
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SOURCE_SHA = "c8e04258d9d550384b037b1e2a91734c22aaaab5"
RESULTS = ROOT / "docs/dev-log/interval-feasibility/results" / SOURCE_SHA
FIXED = RESULTS / "arc1-gaussian-fixed-profile-feasibility/totoro"
META = RESULTS / "arc1-meta-v-profile-feasibility/totoro"
SIGMA_RE = RESULTS / "arc1-gaussian-sigma-re-profile-feasibility/totoro"
REML_SLOPE = RESULTS / "arc1-gaussian-reml-slope-profile-feasibility/totoro"


def rewrite_tsv(path: Path, mutate) -> None:
    with path.open(newline="") as stream:
        rows = list(csv.DictReader(stream, delimiter="\t"))
        fieldnames = list(rows[0])
    mutate(rows)
    with path.open("w", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)


class Arc1ProfileReconcilerTests(unittest.TestCase):
    maxDiff = None

    def run_reconciler(
        self,
        script: str,
        root: Path,
        expect_success: bool,
        compare_tracked: bool = False,
    ) -> None:
        with tempfile.TemporaryDirectory() as out_dir:
            output = Path(out_dir) / "reconciliation.tsv"
            result = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "tools" / script),
                    "--root",
                    str(root),
                    "--out",
                    str(output),
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=False,
            )
            if expect_success:
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                if compare_tracked:
                    self.assertEqual(output.read_bytes(), (root / "reconciliation.tsv").read_bytes())
            else:
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_retained_denominators_reconcile(self) -> None:
        contracts = [
            ("reconcile-arc1-gaussian-fixed-profiles.py", FIXED),
            ("reconcile-arc1-meta-v-profiles.py", META),
            ("reconcile-arc1-gaussian-sigma-re-profiles.py", SIGMA_RE),
            ("reconcile-arc1-gaussian-reml-slope-profiles.py", REML_SLOPE),
        ]
        for script, root in contracts:
            with self.subTest(script=script):
                self.run_reconciler(
                    script, root, expect_success=True, compare_tracked=True
                )

    def test_fixed_reconciler_rejects_artifact_mutations(self) -> None:
        def mutate_receipt(field: str, value: str):
            def mutation(root: Path) -> None:
                receipt = sorted(root.glob("seed-*/*-receipt.tsv"))[0]
                rewrite_tsv(receipt, lambda rows: rows[0].__setitem__(field, value))
            return mutation

        def mutate_fixture(root: Path) -> None:
            fixture = sorted(root.glob("seed-*/*fixture*.tsv"))[0]
            fixture.write_text(fixture.read_text() + "# mutated\n")

        def mutate_endpoint(root: Path) -> None:
            interval = sorted(root.glob("seed-*/*-interval.tsv"))[0]
            rewrite_tsv(interval, lambda rows: rows[0].__setitem__("lower", "-999"))

        def mutate_trace_status(root: Path) -> None:
            trace = sorted(root.glob("seed-*/*-trace.tsv"))[0]
            rewrite_tsv(trace, lambda rows: rows[0].__setitem__("conf.status", "mutated"))

        def duplicate_seed(root: Path) -> None:
            receipt = sorted(root.glob("seed-2026080224/*-receipt.tsv"))[0]
            rewrite_tsv(receipt, lambda rows: rows[0].__setitem__("seed", "2026080223"))

        def missing_seed(root: Path) -> None:
            receipt = sorted(root.glob("seed-2026080224/*-receipt.tsv"))[0]
            receipt.unlink()

        mutations = {
            "wrong estimator": mutate_receipt("estimator", "REML"),
            "wrong runner hash": mutate_receipt("runner_sha256", "0" * 64),
            "wrong target": mutate_receipt("target_id", "mc-0260::wrong"),
            "wrong fixture": mutate_fixture,
            "wrong endpoint": mutate_endpoint,
            "wrong trace status": mutate_trace_status,
            "duplicate seed": duplicate_seed,
            "missing seed": missing_seed,
        }
        for label, mutate in mutations.items():
            with self.subTest(mutation=label), tempfile.TemporaryDirectory() as temp_dir:
                copied = Path(temp_dir) / "fixed"
                shutil.copytree(FIXED, copied)
                mutate(copied)
                self.run_reconciler(
                    "reconcile-arc1-gaussian-fixed-profiles.py",
                    copied,
                    expect_success=False,
                )

    def test_each_single_target_reconciler_rejects_duplicate_and_missing_seed(self) -> None:
        contracts = [
            (
                "reconcile-arc1-meta-v-profiles.py",
                META,
                "2026080234",
                "2026080233",
            ),
            (
                "reconcile-arc1-gaussian-sigma-re-profiles.py",
                SIGMA_RE,
                "2026080244",
                "2026080243",
            ),
            (
                "reconcile-arc1-gaussian-reml-slope-profiles.py",
                REML_SLOPE,
                "2026080254",
                "2026080253",
            ),
        ]
        for script, source, last_seed, duplicate_value in contracts:
            for mode in ("duplicate", "missing"):
                with (
                    self.subTest(script=script, mode=mode),
                    tempfile.TemporaryDirectory() as temp_dir,
                ):
                    copied = Path(temp_dir) / "receipts"
                    shutil.copytree(source, copied)
                    receipt = next(copied.glob(f"seed-{last_seed}/*-receipt.tsv"))
                    if mode == "duplicate":
                        rewrite_tsv(
                            receipt,
                            lambda rows: rows[0].__setitem__("seed", duplicate_value),
                        )
                    else:
                        receipt.unlink()
                    self.run_reconciler(script, copied, expect_success=False)


if __name__ == "__main__":
    unittest.main()
