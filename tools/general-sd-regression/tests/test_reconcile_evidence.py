import csv
import hashlib
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "reconcile_evidence.py"
spec = importlib.util.spec_from_file_location("sd_evidence", SCRIPT)
evidence = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(evidence)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class EvidenceReconciliationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="sd-evidence-")
        self.root = Path(self.tmp.name)
        self.rows_path = self.root / "required-rows.tsv"
        self.evidence_path = self.root / "evidence.tsv"
        self.receipt = self.root / "receipt.log"
        self.manifest = self.root / "source-manifest.csv"
        self.test_source = self.root / "tests" / "test.R"
        self.summary = self.root / "summary.md"
        self.receipt.write_text("TEST_PASS\n", encoding="utf-8")
        self.test_source.parent.mkdir()
        self.test_source.write_text("test fixture\n", encoding="utf-8")
        self.manifest.write_text(
            f"{digest(self.test_source)}  {self.test_source.resolve()}\n", encoding="utf-8"
        )
        self.rows = [
            {
                "row_key": '["native","binomial","univariate","mu","iid_intercept"]',
                "engine": "native", "family_route": "binomial", "mechanism_id": "iid_intercept",
                "provider": "iid", "effect_type": "random intercept", "direct_sd_claim": "none",
            },
            {
                "row_key": '["Julia","binomial","univariate","mu","iid_intercept"]',
                "engine": "Julia", "family_route": "binomial", "mechanism_id": "iid_intercept",
                "provider": "iid", "effect_type": "random intercept", "direct_sd_claim": "none",
            },
        ]
        self.write_tsv(self.rows_path, self.rows)
        self.record = {
            "row_key": self.rows[0]["row_key"],
            "evidence_id": "native-smoke-1",
            "evidence_grade": "focused_test",
            "receipt_path": "receipt.log",
            "receipt_sha256": digest(self.receipt),
            "source_manifest_path": "source-manifest.csv",
            "source_manifest_sha256": digest(self.manifest),
            "test_path": "tests/test.R",
            "test_sha256": digest(self.test_source),
            "test_command": "Rscript test-focused.R",
            "result_summary": "TEST_PASS; 12 assertions",
            "review_status": "unreviewed",
        }
        self.write_tsv(self.evidence_path, [self.record])

    def tearDown(self):
        self.tmp.cleanup()

    @staticmethod
    def write_tsv(path, rows):
        with path.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]), delimiter="\t", lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)

    def reconcile(self):
        return evidence.reconcile(
            self.rows_path, self.evidence_path, self.root, self.summary
        )

    def test_exact_row_receipt_is_linked_without_promoting_support(self):
        result = self.reconcile()
        self.assertEqual(result["linked_rows"], 1)
        self.assertEqual(result["unlinked_rows"], 1)
        self.assertIn("evidence-only join", self.summary.read_text(encoding="utf-8"))
        self.assertEqual(evidence.read_tsv(self.rows_path)[0]["direct_sd_claim"], "none")

    def test_summary_distinguishes_receipt_records_from_candidate_rows(self):
        second = self.record.copy()
        second["evidence_id"] = "native-smoke-2"
        self.write_tsv(self.evidence_path, [self.record, second])
        result = self.reconcile()
        self.assertEqual(result["linked_rows"], 1)
        summary = self.summary.read_text(encoding="utf-8")
        self.assertIn("Evidence receipt records: 2.", summary)
        self.assertIn("Distinct candidate rows with at least one hash-verified receipt: 1.", summary)

    def test_unknown_or_partial_key_is_rejected(self):
        self.record["row_key"] = '["native","binomial"]'
        self.write_tsv(self.evidence_path, [self.record])
        with self.assertRaisesRegex(ValueError, "unknown row_key"):
            self.reconcile()

    def test_duplicate_evidence_identity_is_rejected(self):
        self.write_tsv(self.evidence_path, [self.record, self.record.copy()])
        with self.assertRaisesRegex(ValueError, "duplicate evidence identity"):
            self.reconcile()

    def test_receipt_hash_mismatch_is_rejected(self):
        self.record["receipt_sha256"] = "0" * 64
        self.write_tsv(self.evidence_path, [self.record])
        with self.assertRaisesRegex(ValueError, "receipt SHA-256 mismatch"):
            self.reconcile()

    def test_source_manifest_hash_mismatch_is_rejected(self):
        self.record["source_manifest_sha256"] = "0" * 64
        self.write_tsv(self.evidence_path, [self.record])
        with self.assertRaisesRegex(ValueError, "source manifest SHA-256 mismatch"):
            self.reconcile()

    def test_unknown_grade_and_missing_command_are_rejected(self):
        self.record["evidence_grade"] = "supported"
        self.write_tsv(self.evidence_path, [self.record])
        with self.assertRaisesRegex(ValueError, "unknown evidence_grade"):
            self.reconcile()
        self.record["evidence_grade"] = "focused_test"
        self.record["test_command"] = ""
        self.write_tsv(self.evidence_path, [self.record])
        with self.assertRaisesRegex(ValueError, "missing test_command"):
            self.reconcile()

    def test_candidate_promotion_is_rejected(self):
        self.rows[0]["direct_sd_claim"] = "supported"
        self.write_tsv(self.rows_path, self.rows)
        with self.assertRaisesRegex(ValueError, "direct_sd_claim=none"):
            self.reconcile()

    def test_test_source_must_be_bound_by_the_manifest(self):
        self.manifest.write_text("unrelated-file-hash  other-test.R\n", encoding="utf-8")
        self.record["source_manifest_sha256"] = digest(self.manifest)
        self.write_tsv(self.evidence_path, [self.record])
        with self.assertRaisesRegex(ValueError, "test source is not listed in source manifest"):
            self.reconcile()

    def test_json_manifest_binds_test_path_and_hash_as_fields(self):
        self.manifest = self.root / "source-manifest.json"
        self.manifest.write_text(
            json.dumps(
                {
                    "files": [
                        {"file": "tests/test.R", "sha256": digest(self.test_source)}
                    ]
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        self.record["source_manifest_path"] = "source-manifest.json"
        self.record["source_manifest_sha256"] = digest(self.manifest)
        self.write_tsv(self.evidence_path, [self.record])
        result = self.reconcile()
        self.assertEqual(result["linked_rows"], 1)

    def test_json_manifest_rejects_split_path_and_hash_from_different_entries(self):
        self.manifest = self.root / "source-manifest.json"
        self.manifest.write_text(
            json.dumps(
                {
                    "files": [
                        {"file": "tests/test.R", "sha256": "wrong"},
                        {"file": "tests/other.R", "sha256": digest(self.test_source)},
                    ]
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        self.record["source_manifest_path"] = "source-manifest.json"
        self.record["source_manifest_sha256"] = digest(self.manifest)
        self.write_tsv(self.evidence_path, [self.record])
        with self.assertRaisesRegex(ValueError, "test source is not listed in source manifest"):
            self.reconcile()


if __name__ == "__main__":
    unittest.main()
