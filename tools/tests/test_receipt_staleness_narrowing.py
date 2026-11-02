"""Self-test for the narrowed receipt-staleness rule (tools/ci-receipt-staleness.sh).

The guard fails on a differing R/ file only when the receipt's runner can reach
that file (tools/receipt-exercised-files.R); a differing file off that path is a
NOTE. This builds a tiny fixture repo (a fake runner, three R/ files, a receipt
recording their hashes, stub checker and ledger) and runs the REAL guard script
and the REAL path tool against it. It needs only python3 and Rscript.

Fixture call graph: runner -> drmTMB() in R/drmTMB.R -> helper() in R/helper.R;
R/docs_only.R defines a function nothing reaches.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
RECEIPT = "docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json"

FILES = {
    "tools/run-julia-phylo-labels-public.R": "fit <- drmTMB(1)\n",
    "R/drmTMB.R": "drmTMB <- function(x) helper(x) + 1\n",
    "R/helper.R": "helper <- function(x) x * 2\n",
    "R/docs_only.R": "unused_doc_helper <- function() 'roxygen wording lives here'\n",
    "tools/check-julia-phylo-labels-receipt.R": "quit(status = 0L)\n",
    "tools/capability_ledger.py": "def check_c14_receipt_equivalence():\n    pass\n",
}


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class NarrowedGuard(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        for rel, text in FILES.items():
            self._write(rel, text)
        for rel in ("tools/ci-receipt-staleness.sh", "tools/receipt-exercised-files.R"):
            (self.root / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(REPO / rel, self.root / rel)
        recorded = {p: sha(self.root / p) for p in ("R/drmTMB.R", "R/helper.R", "R/docs_only.R")}
        receipt = {
            "status": "PASS",
            "source_unchanged": True,
            "source_before": recorded,
            "source_after": recorded,
            "runner_sha256": sha(self.root / "tools/run-julia-phylo-labels-public.R"),
        }
        self._write(RECEIPT, json.dumps(receipt))

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def _write(self, rel: str, text: str) -> None:
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def guard(self) -> subprocess.CompletedProcess:
        return subprocess.run(
            ["bash", "tools/ci-receipt-staleness.sh"],
            cwd=self.root, capture_output=True, text=True, check=False,
        )

    def test_unchanged_tree_is_fresh(self) -> None:
        r = self.guard()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("FRESH", r.stdout)

    def test_change_off_the_call_path_is_a_note_not_a_failure(self) -> None:
        self._write("R/docs_only.R", "# reworded roxygen\nunused_doc_helper <- function() 'new text'\n")
        r = self.guard()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertRegex(r.stdout, r"NOTE .*not on the runner's call path: R/docs_only\.R")
        self.assertNotIn("STALE  ", r.stdout)

    def test_change_to_the_entry_function_fails(self) -> None:
        self._write("R/drmTMB.R", "drmTMB <- function(x) helper(x) + 2\n")
        r = self.guard()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertRegex(r.stdout, r"STALE .*R/drmTMB\.R \(on the runner's call path\)")

    def test_change_two_calls_deep_fails(self) -> None:
        self._write("R/helper.R", "helper <- function(x) x * 3\n")
        r = self.guard()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertRegex(r.stdout, r"STALE .*R/helper\.R \(on the runner's call path\)")

    def test_a_comment_only_edit_on_the_path_still_fails(self) -> None:
        # The receipt records whole-file hashes, so a roxygen edit in a file the
        # runner reaches is still drift; only files off the path are relaxed.
        self._write("R/helper.R", "#' reworded\nhelper <- function(x) x * 2\n")
        r = self.guard()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)

    def test_runner_change_fails(self) -> None:
        self._write("tools/run-julia-phylo-labels-public.R", "fit <- drmTMB(2)\n")
        r = self.guard()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("current runner hash differs from receipt", r.stdout)

    def test_deleted_recorded_file_fails_even_off_the_path(self) -> None:
        (self.root / "R/docs_only.R").unlink()
        r = self.guard()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertIn("recorded source path is absent now: R/docs_only.R", r.stdout)

    def test_new_unrecorded_file_off_the_path_is_a_note(self) -> None:
        self._write("R/new_unused.R", "brand_new_unused <- function() 1\n")
        r = self.guard()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertRegex(r.stdout, r"NOTE .*not recorded in receipt .*R/new_unused\.R")

    def test_new_unrecorded_file_the_runner_reaches_fails(self) -> None:
        # A new file the runner itself reaches. The runner is re-recorded below so
        # that only the unrecorded-file rule can fire.
        self._write("R/new_reached.R", "reached_helper <- function() 1\n")
        self._write("tools/run-julia-phylo-labels-public.R", "fit <- drmTMB(1); reached_helper()\n")
        receipt = json.loads((self.root / RECEIPT).read_text(encoding="utf-8"))
        receipt["runner_sha256"] = sha(self.root / "tools/run-julia-phylo-labels-public.R")
        self._write(RECEIPT, json.dumps(receipt))
        r = self.guard()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertRegex(r.stdout, r"STALE .*not recorded in receipt .*on the runner's call path: R/new_reached\.R")

    def test_s3_method_of_a_called_generic_is_on_the_path(self) -> None:
        self._write("R/drmTMB.R", "drmTMB <- function(x) summary(x)\n")
        self._write("R/s3.R", "summary.thing <- function(object, ...) 1\n")
        receipt = json.loads((self.root / RECEIPT).read_text(encoding="utf-8"))
        for key in ("source_before", "source_after"):
            receipt[key]["R/drmTMB.R"] = sha(self.root / "R/drmTMB.R")
            receipt[key]["R/s3.R"] = sha(self.root / "R/s3.R")
        self._write(RECEIPT, json.dumps(receipt))
        self.assertEqual(self.guard().returncode, 0)
        self._write("R/s3.R", "summary.thing <- function(object, ...) 2\n")
        r = self.guard()
        self.assertEqual(r.returncode, 1, r.stdout + r.stderr)
        self.assertRegex(r.stdout, r"STALE .*R/s3\.R")

    def test_unusable_path_tool_is_an_error_not_a_pass(self) -> None:
        # Without R/drmTMB.R the plausibility floor refuses to trust the computed
        # list: exit 2 (environment error), never a silent pass.
        (self.root / "R/drmTMB.R").unlink()
        r = self.guard()
        self.assertEqual(r.returncode, 2, r.stdout + r.stderr)


if __name__ == "__main__":
    unittest.main()
