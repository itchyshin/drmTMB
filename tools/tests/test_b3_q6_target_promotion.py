"""Focused fail-closed tests for the Lane B3 q6 mu2 target promotion."""

from __future__ import annotations

import csv
import hashlib
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DASHBOARD = ROOT / "docs/dev-log/dashboard"
EXPECTED = {
    "mc-0102": ("phylo", "qseries_phylo_q6_planned", "mc-0102::sd:mu:mu2:phylo(1 | p | species)", "4573d5b76c0bd342fb382991fd5ab62005d3efa375139a4df33dda0c10492917", "174c96a1809caec6b8e6ce1ec872e290578844ce563d03266cecb46d8edce839"),
    "mc-0124": ("spatial", "qseries_spatial_q6_planned", "mc-0124::sd:mu:mu2:spatial(1 | p | site)", "ea0c6a064f54807546ae1fcb1a9b40a01b7b085359691d6f8e28532f811c9b56", "395ee46e5000fca21be1dea88ea55cb93a6d01406315bbf7ae5a89515c0d28e5"),
    "mc-0146": ("animal", "qseries_animal_q6_planned", "mc-0146::sd:mu:mu2:animal(1 | p | id)", "2645fa58735c110034d8710d059683f03d7ddba889f2f6686c623d67f1fe694e", "f54b42ae98e0e4338a9a96aab851c31797fd3bf4284b6e3cf4f2371c1b485612"),
    "mc-0168": ("relmat", "qseries_relmat_q6_planned", "mc-0168::sd:mu:mu2:relmat(1 | p | id)", "93e394e8b65c586afef5f581c9370417256ce6d5a20b83ef0bd954ecf5d0acc9", "3ed4b7acc10f60b0e4fd1f68cfb441efce50af6c15071e8739865a127ed5aed7"),
}


def rows(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


class B3Q6TargetPromotionTests(unittest.TestCase):
    def test_packet_sidecar_and_ledger_are_exactly_four_target_rows(self):
        packet = {
            row["cell_id"]: row
            for row in rows(ROOT / "docs/dev-log/evidence/2026-08-01-b3-q6-target-promotion-packet.tsv")
        }
        sidecar = {
            row["cell_id"]: row
            for row in rows(DASHBOARD / "structured-re-q6-mu2-target-interval-feasible.tsv")
        }
        cells = {
            row["cell_id"]: row
            for row in rows(DASHBOARD / "capability-ledger/cells.tsv")
        }
        self.assertEqual(set(packet), set(EXPECTED))
        self.assertEqual(set(sidecar), set(EXPECTED))
        promoted = {
            cell_id
            for cell_id, row in cells.items()
            if row["q_gate"] == "q6"
            and row["dpar"] == "mu2"
            and row["effect_type"] == "structured"
            and row["estimator"] == "ML"
            and row["evidence_tier"] == "interval_feasible"
        }
        self.assertEqual(promoted, set(EXPECTED))
        for cell_id, (provider, whole, target, trace_sha, interval_sha) in EXPECTED.items():
            self.assertEqual(packet[cell_id]["target_id"], target)
            self.assertEqual(packet[cell_id]["provider"], provider)
            self.assertEqual(packet[cell_id]["target_truth"], "0.4")
            self.assertEqual(packet[cell_id]["target_truth_scale"], "response_sd")
            self.assertIn("latent_log_sd", packet[cell_id]["source_metadata_correction"])
            self.assertIn("response-SD", packet[cell_id]["source_metadata_correction"])
            self.assertEqual(sidecar[cell_id]["target_id"], target)
            self.assertEqual(sidecar[cell_id]["linked_whole_cell_id"], whole)
            self.assertEqual(sidecar[cell_id]["whole_interval_status"], "planned")
            self.assertEqual(sidecar[cell_id]["whole_coverage_status"], "planned")
            self.assertEqual(cells[cell_id]["evidence_tier"], "interval_feasible")
            receipt = ROOT / packet[cell_id]["evidence_path"]
            self.assertTrue(receipt.is_file())
            trace = Path(str(receipt).replace("-receipt.tsv", "-trace.tsv"))
            interval = Path(str(receipt).replace("-receipt.tsv", "-interval.tsv"))
            self.assertEqual(hashlib.sha256(trace.read_bytes()).hexdigest(), trace_sha)
            self.assertEqual(hashlib.sha256(interval.read_bytes()).hexdigest(), interval_sha)

    def test_whole_q6_and_paired_mu1_rows_remain_planned_and_recovery_only(self):
        support = {
            row["cell_id"]: row
            for row in rows(DASHBOARD / "structured-re-q-series-support-cells.tsv")
        }
        cells = {
            row["cell_id"]: row
            for row in rows(DASHBOARD / "capability-ledger/cells.tsv")
        }
        paired_mu1 = {
            "mc-0102": "mc-0101",
            "mc-0124": "mc-0123",
            "mc-0146": "mc-0145",
            "mc-0168": "mc-0167",
        }
        for cell_id, (_, whole, _, _, _) in EXPECTED.items():
            self.assertEqual(support[whole]["fit_status"], "point_fit")
            self.assertEqual(support[whole]["interval_status"], "planned")
            self.assertEqual(support[whole]["coverage_status"], "planned")
            self.assertEqual(cells[paired_mu1[cell_id]]["evidence_tier"], "point_fit_recovery")

    def test_exactly_four_evidence_and_transition_rows_are_bound(self):
        evidence = {
            row["evidence_id"]: row
            for row in rows(DASHBOARD / "capability-ledger/evidence.tsv")
        }
        transitions = {
            row["transition_id"]: row
            for row in rows(DASHBOARD / "capability-ledger/transitions.tsv")
        }
        for cell_id in EXPECTED:
            evidence_id = f"ev-{cell_id}-b3-q6-mu2-interval"
            transition_id = f"tr-{cell_id}-b3-q6-mu2-interval"
            self.assertEqual(evidence[evidence_id]["cell_id"], cell_id)
            self.assertEqual(evidence[evidence_id]["result"], "interval_feasible")
            self.assertEqual(transitions[transition_id]["from_work_status"], "verified")
            self.assertEqual(transitions[transition_id]["to_work_status"], "verified")
            self.assertEqual(transitions[transition_id]["evidence_ids"], evidence_id)


if __name__ == "__main__":
    unittest.main()
