#!/usr/bin/env python3
"""Run the Q-Series v1.0 release-prep checks as one command."""

from __future__ import annotations

import argparse
import csv
import math
import os
import pathlib
import re
import subprocess
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
STATUS_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-release-status.md"
SUPPORT_PATH = ROOT / "docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv"
LEDGER_PATH = ROOT / "docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv"
REJECTION_PATH = ROOT / "docs/dev-log/dashboard/structured-re-nongaussian-structured-family-rejection-contract.tsv"
COUNT_SIGMA_REJECTION_PATH = ROOT / "docs/dev-log/dashboard/structured-re-count-slope-sigma-one-slope-rejection-contract.tsv"
COUNT_MU_REJECTION_PATH = ROOT / "docs/dev-log/dashboard/structured-re-count-structured-mu-rejection-contract.tsv"
Q2_PLUS_Q2_SIGMA_REJECTION_PATH = ROOT / "docs/dev-log/dashboard/structured-re-q2-plus-q2-sigma-rejection-contract.tsv"
DEFAULT_REPORT_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-preflight-report.md"
DEFAULT_CANDIDATE_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv"
DEFAULT_REVIEW_PACKET_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-75pct-review-packet.tsv"
DEFAULT_NINETY_PACKET_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-90pct-review-packet.tsv"
DEFAULT_NINETY_ECONOMY_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-90pct-economy-plan.tsv"
DEFAULT_FIRST_CONTRACT_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-first-candidate-design-contract.tsv"
DEFAULT_DEBUG_FIXTURE_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-first-candidate-debug-fixture-contract.tsv"
DEFAULT_FIRST_FOUR_CONTRACT_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-first-four-design-contracts.tsv"
DEFAULT_FIRST_FOUR_DEBUG_FIXTURE_PATH = ROOT / "docs/dev-log/release-audits/q-series-v1-first-four-debug-fixture-contracts.tsv"
PRIMARY_REVIEW_BAND = "next_four_after_75_percent"
PRIMARY_REVIEW_PACKET_PREFIX = "qseries_v1_post75_review"
NINETY_REVIEW_PACKET_PREFIX = "qseries_v1_to90_review"
CANDIDATE_FIELDS = (
    "review_rank",
    "target_band",
    "cell_id",
    "v1_track",
    "family_class",
    "family",
    "structure_provider",
    "dimension_pattern",
    "endpoint_set",
    "slope_class",
    "fit_status",
    "review_reason",
    "required_before_movement",
    "coverage_decision",
    "promotion_decision",
    "claim_boundary",
)
REVIEW_PACKET_FIELDS = (
    "contract_id",
    "review_rank",
    "cell_id",
    "family",
    "structure_provider",
    "model_scope",
    "minimum_design_question",
    "minimum_recovery_evidence",
    "validator_gate",
    "blocking_reviewers",
    "compute_decision",
    "coverage_decision",
    "promotion_decision",
    "claim_boundary",
    "next_action",
)
NINETY_ECONOMY_FIELDS = (
    "contract_id",
    "review_rank",
    "cell_id",
    "v1_track",
    "current_fit_status",
    "model_scope",
    "implementation_cost",
    "least_compute_next_action",
    "why_not_parallel_compute",
    "blocking_reviewers",
    "coverage_decision",
    "promotion_decision",
    "claim_boundary",
)
FIRST_CONTRACT_FIELDS = (
    "contract_id",
    "source_packet_id",
    "cell_id",
    "formula_cell",
    "family",
    "structure_provider",
    "current_v1_track",
    "current_fit_status",
    "current_interval_status",
    "current_coverage_status",
    "existing_evidence_url",
    "model_contract",
    "dgp_requirements",
    "implementation_requirements",
    "recovery_requirements",
    "failure_requirements",
    "validator_requirements",
    "blocking_reviewers",
    "compute_decision",
    "coverage_decision",
    "promotion_decision",
    "claim_boundary",
    "next_action",
)
DEBUG_FIXTURE_FIELDS = (
    "debug_contract_id",
    "source_contract_id",
    "source_rejection_id",
    "cell_id",
    "formula_cell",
    "expected_current_failure",
    "failure_stage",
    "debug_scope",
    "fixture_dgp",
    "allowed_action",
    "stop_if",
    "required_outputs",
    "validator_requirements",
    "blocking_reviewers",
    "compute_decision",
    "coverage_decision",
    "promotion_decision",
    "claim_boundary",
    "next_action",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Q-Series v1.0 ledger, claim, and Mission Control checks."
    )
    parser.add_argument(
        "--root",
        type=pathlib.Path,
        default=ROOT,
        help="Repository root. Defaults to the parent of this script.",
    )
    parser.add_argument(
        "--skip-mission-control",
        action="store_true",
        help="Skip tools/validate-mission-control.py. Useful inside validator tests.",
    )
    parser.add_argument(
        "--fast-status",
        action="store_true",
        help=(
            "Print a ledger-only v1.0 progress snapshot and exit without "
            "running validators. This is a planning shortcut, not evidence."
        ),
    )
    parser.add_argument(
        "--summary",
        action="store_true",
        help="Print a concise success summary.",
    )
    parser.add_argument(
        "--report-output",
        type=pathlib.Path,
        default=DEFAULT_REPORT_PATH,
        help="Generated Markdown preflight report path.",
    )
    parser.add_argument(
        "--write-report",
        action="store_true",
        help="Write the generated Markdown preflight report.",
    )
    parser.add_argument(
        "--check-report",
        action="store_true",
        help="Fail if the generated Markdown preflight report differs.",
    )
    parser.add_argument(
        "--candidate-output",
        type=pathlib.Path,
        default=DEFAULT_CANDIDATE_PATH,
        help="Generated TSV next-candidate review path.",
    )
    parser.add_argument(
        "--review-packet-output",
        type=pathlib.Path,
        default=DEFAULT_REVIEW_PACKET_PATH,
        help="Generated TSV 75 percent review packet path.",
    )
    parser.add_argument(
        "--ninety-packet-output",
        type=pathlib.Path,
        default=DEFAULT_NINETY_PACKET_PATH,
        help="Generated TSV next rows needed for the 90 percent review packet path.",
    )
    parser.add_argument(
        "--ninety-economy-output",
        type=pathlib.Path,
        default=DEFAULT_NINETY_ECONOMY_PATH,
        help="Generated TSV economical action plan for rows needed for the 90 percent target.",
    )
    parser.add_argument(
        "--first-contract-output",
        type=pathlib.Path,
        default=DEFAULT_FIRST_CONTRACT_PATH,
        help="Generated TSV first-candidate design contract path.",
    )
    parser.add_argument(
        "--debug-fixture-output",
        type=pathlib.Path,
        default=DEFAULT_DEBUG_FIXTURE_PATH,
        help="Generated TSV first-candidate local-debug fixture contract path.",
    )
    parser.add_argument(
        "--first-four-contract-output",
        type=pathlib.Path,
        default=DEFAULT_FIRST_FOUR_CONTRACT_PATH,
        help="Generated TSV first-four design contracts path.",
    )
    parser.add_argument(
        "--first-four-debug-output",
        type=pathlib.Path,
        default=DEFAULT_FIRST_FOUR_DEBUG_FIXTURE_PATH,
        help="Generated TSV first-four local-debug fixture contracts path.",
    )
    parser.add_argument(
        "--write-candidates",
        action="store_true",
        help="Write generated next-candidate review artifacts.",
    )
    parser.add_argument(
        "--check-candidates",
        action="store_true",
        help="Fail if generated next-candidate review artifacts differ.",
    )
    return parser.parse_args()


def run_step(
    label: str,
    command: list[str],
    root: pathlib.Path,
    env: dict[str, str],
) -> tuple[bool, str]:
    result = subprocess.run(
        command,
        cwd=root,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    combined = "\n".join(part for part in (result.stdout, result.stderr) if part)
    if result.returncode != 0:
        print(f"{label}: failed with exit {result.returncode}", file=sys.stderr)
        if combined:
            print(combined.rstrip(), file=sys.stderr)
        return False, combined
    return True, combined


def parse_status_progress(path: pathlib.Path) -> dict[str, str]:
    if not path.exists():
        return {}
    progress: dict[str, str] = {}
    pattern = re.compile(r"^\| (?P<measure>[^|]+) \| (?P<rows>[^|]+) \| (?P<pct>[^|]+) \|")
    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        measure = match.group("measure").strip()
        if measure in {"Measure", "---"}:
            continue
        progress[measure] = f"{match.group('rows').strip()} ({match.group('pct').strip()})"
    return progress


def read_tsv(path: pathlib.Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE))


def parse_progress_fraction(value: str) -> tuple[int, int] | None:
    match = re.match(r"^(?P<current>[0-9]+)/(?P<total>[0-9]+)\b", value)
    if not match:
        return None
    return int(match.group("current")), int(match.group("total"))


def row_target_gaps(progress: dict[str, str]) -> list[dict[str, str | int]]:
    parsed = parse_progress_fraction(progress.get("Practical v1.0 row surface", ""))
    if parsed is None:
        return []
    current, total = parsed
    gaps: list[dict[str, str | int]] = []
    for target_percent in (75, 80, 90, 100):
        required = math.ceil(total * target_percent / 100)
        gaps.append(
            {
                "target": f"{target_percent}%",
                "required": f"{required}/{total}",
                "needed": max(required - current, 0),
            }
        )
    return gaps


def target_gap_summary(progress: dict[str, str]) -> str:
    return "; ".join(
        f"rows_to_{row['target'].rstrip('%')}={row['needed']}"
        for row in row_target_gaps(progress)
    )


def first_four_cell_summary(candidate_rows: list[dict[str, str]]) -> str:
    return ",".join(row["cell_id"] for row in candidate_rows[:4])


def render_fast_status(
    *,
    progress: dict[str, str],
    candidate_rows: list[dict[str, str]],
) -> str:
    target_summary = target_gap_summary(progress)
    return (
        "qseries_v1_fast_status: "
        "validation=skipped; ledger=not_run; claim_guard=not_run; "
        "mission_control=not_run; source=checked_in_release_status_and_ledger; "
        f"practical_v1_surface={progress.get('Practical v1.0 row surface', 'NA')}; "
        f"gaussian_core={progress.get('Gaussian v1.0 core', 'NA')}; "
        f"basic_distribution_recovery={progress.get('Basic-distribution recovery', 'NA')}; "
        f"exact_inference_ready={progress.get('Exact `inference_ready` anchors', 'NA')}; "
        f"supported_authority={progress.get('`supported` authority', 'NA')}; "
        f"post_v1={progress.get('Post-v1.0 validation/design', 'NA')}; "
        f"{target_summary}; "
        f"candidate_review_rows={len(candidate_rows)}; "
        f"first_four={first_four_cell_summary(candidate_rows)}; "
        "boundary=ledger_only_no_validation_no_promotion"
    )


def candidate_review_reason(row: dict[str, str]) -> str:
    if row["v1_track"] == "basic_distribution_post_v1_design":
        if (
            row["dimension_pattern"] == "q1"
            and row["endpoint_set"] == "mu"
            and row["slope_class"] == "intercept_only"
        ):
            return "low-dimensional family-design gap; write a DGP/extractor/recovery contract before any movement"
        if row["endpoint_set"] == "mu":
            return "count-location design gap; prove recovery scope before any movement"
        return "non-location family-parameter design gap; keep intervals and coverage deferred"
    if row["dimension_pattern"] == "q2_plus_q2":
        return "Gaussian scale-side route gap; design a supported route before any movement"
    return "Gaussian high-q design gap; leave outside v1.0 unless a narrow implementation gate lands"


def candidate_complexity(row: dict[str, str]) -> int:
    if row["cell_id"] == "qseries_nongaussian_structured_slope_neighbors_planned":
        return 2
    specialized_markers = (
        "noncanonical",
        "labelled_q2",
        "structured_plus",
        "zeroinflated",
        "simultaneous",
    )
    if any(marker in row["cell_id"] for marker in specialized_markers):
        return 1
    return 0


def candidate_sort_key(row: dict[str, str]) -> tuple[int, int, int, int, int, int, str]:
    track_order = {
        "basic_distribution_post_v1_design": 0,
        "gaussian_post_v1_validation": 1,
    }
    dimension_order = {
        "q1": 0,
        "q2_plus_q2": 1,
        "q6": 2,
        "q8": 3,
        "q12": 4,
    }
    endpoint_order = {
        "mu": 0,
        "sigma": 1,
        "sigma1+sigma2": 1,
        "nu": 2,
        "zi": 3,
        "hu": 4,
        "mu1+mu2": 5,
        "mu1+mu2+sigma1+sigma2": 6,
    }
    slope_order = {
        "intercept_only": 0,
        "independent_one_slope": 1,
        "multiple_slope": 2,
        "labelled_slope_covariance": 3,
    }
    fit_order = {"planned": 0, "unsupported": 1}
    return (
        track_order.get(row["v1_track"], 99),
        dimension_order.get(row["dimension_pattern"], 99),
        candidate_complexity(row),
        endpoint_order.get(row["endpoint_set"], 99),
        slope_order.get(row["slope_class"], 99),
        fit_order.get(row["fit_status"], 99),
        row["cell_id"],
    )


def build_candidate_rows(ledger_rows: list[dict[str, str]]) -> list[dict[str, str]]:
    post_v1_rows = [
        row
        for row in ledger_rows
        if row["v1_track"]
        in {"basic_distribution_post_v1_design", "gaussian_post_v1_validation"}
    ]
    candidates: list[dict[str, str]] = []
    for rank, row in enumerate(sorted(post_v1_rows, key=candidate_sort_key), start=1):
        if rank <= 4:
            target_band = PRIMARY_REVIEW_BAND
        elif rank <= 10:
            target_band = "additional_six_to_review_for_80_percent"
        else:
            target_band = "later_post_v1_review_queue"
        candidates.append(
            {
                "review_rank": str(rank),
                "target_band": target_band,
                "cell_id": row["cell_id"],
                "v1_track": row["v1_track"],
                "family_class": row["family_class"],
                "family": row["family"],
                "structure_provider": row["structure_provider"],
                "dimension_pattern": row["dimension_pattern"],
                "endpoint_set": row["endpoint_set"],
                "slope_class": row["slope_class"],
                "fit_status": row["fit_status"],
                "review_reason": candidate_review_reason(row),
                "required_before_movement": "row-specific implementation or recovery evidence plus Rose/Fisher/Grace review before movement",
                "coverage_decision": "coverage_not_authorized",
                "promotion_decision": "do_not_promote",
                "claim_boundary": "candidate review is not a support-cell edit, inference_ready, supported, coverage, q4/q8, REML, AI-REML, bridge, or public-support claim",
            }
        )
    return candidates


def build_review_packet_rows(candidate_rows: list[dict[str, str]]) -> list[dict[str, str]]:
    packet_rows: list[dict[str, str]] = []
    for row in candidate_rows:
        if row["target_band"] != PRIMARY_REVIEW_BAND:
            continue
        packet_rows.append(
            {
                "contract_id": f"{PRIMARY_REVIEW_PACKET_PREFIX}_{int(row['review_rank']):02d}",
                "review_rank": row["review_rank"],
                "cell_id": row["cell_id"],
                "family": row["family"],
                "structure_provider": row["structure_provider"],
                "model_scope": (
                    f"{row['family']} {row['dimension_pattern']} "
                    f"{row['endpoint_set']} "
                    f"{row['slope_class'].replace('_', '-')} "
                    f"{row['structure_provider']} route"
                ),
                "minimum_design_question": "Can this row be represented as basic recovery for v1.0 without changing formula grammar or interval claims?",
                "minimum_recovery_evidence": "document DGP, extractor expectation, one local debug recovery path, and failure mode before any surface movement",
                "validator_gate": "candidate TSV, preflight report, focused conversion-contract test, and Mission Control must remain green",
                "blocking_reviewers": "Rose/Fisher/Grace",
                "compute_decision": "no_compute_authorized",
                "coverage_decision": "coverage_not_authorized",
                "promotion_decision": "do_not_promote",
                "claim_boundary": "review packet is not implementation evidence, recovery evidence, inference_ready, supported, coverage, q4/q8, REML, AI-REML, bridge, or public-support authority",
                "next_action": "write a row-specific design/recovery contract before any code, compute, or status edit",
            }
        )
    return packet_rows


def rows_needed_for_target(progress: dict[str, str], target: str) -> int:
    for row in row_target_gaps(progress):
        if row["target"] == target:
            return int(row["needed"])
    raise ValueError(f"Unknown Q-Series v1.0 target: {target}")


def build_ninety_review_packet_rows(
    candidate_rows: list[dict[str, str]],
    progress: dict[str, str],
) -> list[dict[str, str]]:
    needed = rows_needed_for_target(progress, "90%")
    if needed > len(candidate_rows):
        raise ValueError(
            "Q-Series v1.0 90 percent packet needs "
            f"{needed} rows, but only {len(candidate_rows)} candidate rows exist"
        )
    packet_rows: list[dict[str, str]] = []
    for row in candidate_rows[:needed]:
        packet_rows.append(
            {
                "contract_id": f"{NINETY_REVIEW_PACKET_PREFIX}_{int(row['review_rank']):02d}",
                "review_rank": row["review_rank"],
                "cell_id": row["cell_id"],
                "family": row["family"],
                "structure_provider": row["structure_provider"],
                "model_scope": (
                    f"{row['family']} {row['dimension_pattern']} "
                    f"{row['endpoint_set']} "
                    f"{row['slope_class'].replace('_', '-')} "
                    f"{row['structure_provider']} route"
                ),
                "minimum_design_question": "What is the least row-specific evidence that could move this row into the practical v1.0 surface without changing interval, coverage, or support status?",
                "minimum_recovery_evidence": "row-specific design, DGP/extractor expectation, local debug or explicit rejection evidence, and Rose/Fisher/Grace review before any surface movement",
                "validator_gate": "candidate TSV, 90 percent packet, preflight report, focused conversion-contract test, and Mission Control must remain green",
                "blocking_reviewers": "Rose/Fisher/Grace",
                "compute_decision": "no_compute_authorized",
                "coverage_decision": "coverage_not_authorized",
                "promotion_decision": "do_not_promote",
                "claim_boundary": "90 percent review packet is not implementation evidence, recovery evidence, support-cell movement, inference_ready, supported, coverage, q4/q8, REML, AI-REML, bridge, or public-support authority",
                "next_action": "choose one row for a reviewed design/recovery contract before any code, compute, or support-cell edit",
            }
        )
    return packet_rows


def ninety_economy_detail(row: dict[str, str]) -> dict[str, str]:
    cell_id = row["cell_id"]
    # Row 105 (qseries_count_mu_simultaneous_structured_types_rejected) was
    # admitted recovery-only in M5, so it is no longer a post-v1 candidate and no
    # longer needs a "one-provider gate" economy note.
    if cell_id == "qseries_nongaussian_structured_slope_neighbors_planned":
        return {
            "implementation_cost": "medium_row_selection",
            "least_compute_next_action": "split the broad planned row into one family-provider DGP/extractor/recovery contract before runtime work",
            "why_not_parallel_compute": "the row is a planned design bucket, not an executable family/provider compute fixture",
        }
    if cell_id.endswith("_q2_plus_q2_sigma_rejected"):
        return {
            "implementation_cost": "high_math_route",
            "least_compute_next_action": "review the scale-side q2-plus-q2 covariance route and failure taxonomy before any parser edit or smoke",
            "why_not_parallel_compute": "partial location-scale blocks are intentionally rejected; compute would not create a valid practical-surface row without a route contract",
        }
    return {
        "implementation_cost": "review_required",
        "least_compute_next_action": "write a row-specific DGP/extractor/recovery contract before code or compute",
        "why_not_parallel_compute": "candidate movement needs Rose/Fisher/Grace review before local or host work",
    }


def build_ninety_economy_rows(
    candidate_rows: list[dict[str, str]],
    progress: dict[str, str],
) -> list[dict[str, str]]:
    needed = rows_needed_for_target(progress, "90%")
    if needed > len(candidate_rows):
        raise ValueError(
            "Q-Series v1.0 90 percent economy plan needs "
            f"{needed} rows, but only {len(candidate_rows)} candidate rows exist"
        )
    economy_rows: list[dict[str, str]] = []
    for row in candidate_rows[:needed]:
        detail = ninety_economy_detail(row)
        economy_rows.append(
            {
                "contract_id": f"qseries_v1_to90_economy_{int(row['review_rank']):02d}",
                "review_rank": row["review_rank"],
                "cell_id": row["cell_id"],
                "v1_track": row["v1_track"],
                "current_fit_status": row["fit_status"],
                "model_scope": (
                    f"{row['family']} {row['dimension_pattern']} "
                    f"{row['endpoint_set']} "
                    f"{row['slope_class'].replace('_', '-')} "
                    f"{row['structure_provider']} route"
                ),
                "implementation_cost": detail["implementation_cost"],
                "least_compute_next_action": detail["least_compute_next_action"],
                "why_not_parallel_compute": detail["why_not_parallel_compute"],
                "blocking_reviewers": "Rose/Fisher/Grace",
                "coverage_decision": "coverage_not_authorized",
                "promotion_decision": "do_not_promote",
                "claim_boundary": "90 percent economy plan is planning-only; it is not implementation evidence, recovery evidence, support-cell movement, inference_ready, supported, coverage, q4/q8, REML, AI-REML, bridge, or public-support authority",
            }
        )
    return economy_rows


FIRST_FOUR_CONTRACT_DETAIL = {
    "qseries_beta_mu_animal_rejected": {
        "contract_id": "qseries_v1_beta_mu_animal_design_contract",
        "model_contract": "y_i ~ beta(mu_i, phi); logit(mu_i) = X_i beta + u_id[i]; u ~ N(0, sigma_animal^2 A); phi = 1 / sigma^2",
        "dgp_requirements": "strict response support 0 < y < 1; named animal levels matching A/pedigree/Ainv; fixed sigma/precision route; no exact zero-one mass",
        "implementation_requirements": "reuse beta() mu likelihood and animal() known-covariance parser shape; do not change formula grammar, public API, sigma random effects, zoi/coi, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, animal SD on the correct scale, extractor visibility, and deterministic seed provenance; not a denominator or coverage run",
        "next_action": "review this contract before any beta animal code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_gamma_mu_relmat_rejected": {
        "contract_id": "qseries_v1_gamma_mu_relmat_design_contract",
        "model_contract": "y_i ~ Gamma(mu_i, dispersion); log(mu_i) = X_i beta + u_id[i]; u ~ N(0, sigma_relmat^2 K); family dispersion fixed during first debug fixture",
        "dgp_requirements": "strict positive response support y > 0; named relmat levels matching K/Q input; fixed dispersion route; no zero, negative, or missing matrix levels",
        "implementation_requirements": "reuse Gamma() mu likelihood and relmat() known-covariance parser shape; do not change formula grammar, public API, sigma random effects, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, relmat SD on the correct scale, extractor visibility, and deterministic seed provenance; not a denominator or coverage run",
        "next_action": "review this contract before any Gamma relmat code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_ordinal_mu_phylo_rejected": {
        "contract_id": "qseries_v1_ordinal_mu_phylo_design_contract",
        "model_contract": "y_i ~ cumulative_logit(mu_i, cutpoints); latent location shift eta_i = X_i beta + u_tip[i]; u ~ N(0, sigma_phylo^2 A_phylo); cutpoints fixed during first debug fixture",
        "dgp_requirements": "ordered response with at least three observed levels; named phylo tips matching data levels; fixed cutpoint route; no empty level or missing-tip mismatch",
        "implementation_requirements": "reuse cumulative_logit() location shape and phylo() known-covariance parser shape; do not change formula grammar, public API, threshold parameterization, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, phylo SD on the correct scale, extractor visibility, and deterministic seed provenance; not a denominator or coverage run",
        "next_action": "review this contract before any ordinal phylo code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_student_mu_spatial_rejected": {
        "contract_id": "qseries_v1_student_mu_spatial_design_contract",
        "model_contract": "y_i ~ student(mu_i, sigma, nu); mu_i = X_i beta + u_site[i]; u ~ N(0, sigma_spatial^2 C(distance)); sigma and nu fixed during first debug fixture",
        "dgp_requirements": "real-valued response; named spatial levels with valid coordinates and distance structure; fixed sigma and nu route; no duplicate or missing coordinate levels",
        "implementation_requirements": "reuse student() mu likelihood and spatial() covariance parser shape; do not change formula grammar, public API, sigma random effects, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, spatial SD on the correct scale, extractor visibility, and deterministic seed provenance; not a denominator or coverage run",
        "next_action": "review this contract before any Student spatial code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_student_nu_phylo_rejected": {
        "contract_id": "qseries_v1_student_nu_phylo_design_contract",
        "model_contract": "y_i ~ student(mu_i, sigma, nu_i); mu_i = X_i beta; log(nu_i) or supported shape link receives u_tip[i] only after the Student shape parameterization is reviewed; u ~ N(0, sigma_phylo^2 A_phylo)",
        "dgp_requirements": "real-valued response with stable tail information; named phylo tips matching the tree; fixed mu and sigma route; explicit lower-bound or link policy for nu before any fit",
        "implementation_requirements": "derive and document the Student shape-link mapping before reusing phylo() parser shape; do not change formula grammar, public API, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, phylo shape-side SD extraction, extractor visibility, and deterministic seed provenance only after the shape-link contract is reviewed; not a denominator or coverage run",
        "next_action": "review the Student nu link/design contract before any Student shape code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_beta_sigma_animal_rejected": {
        "contract_id": "qseries_v1_beta_sigma_animal_design_contract",
        "model_contract": "y_i ~ beta(mu_i, phi_i); logit(mu_i) = X_i beta; log(sigma_i) = Z_i gamma + u_id[i]; u ~ N(0, sigma_animal^2 A); beta precision mapping must remain explicit before implementation",
        "dgp_requirements": "strict response support 0 < y < 1; named animal levels matching A/pedigree/Ainv; fixed mu route; no exact zero-one mass; scale-link interpretation documented before fitting",
        "implementation_requirements": "reuse beta() scale likelihood and animal() known-covariance parser shape only after the scale-side mapping is reviewed; do not change formula grammar, public API, zoi/coi, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, animal scale-side SD on the correct scale, extractor visibility, and deterministic seed provenance; not a denominator or coverage run",
        "next_action": "review this contract before any beta sigma animal code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_animal_nbinom2_q1_sigma_one_slope_rejected": {
        "contract_id": "qseries_v1_animal_nbinom2_sigma_one_slope_design_contract",
        "model_contract": "y_i ~ NB2(mu_i, phi_i); log(mu_i) = X_i beta; log(sigma_i) = Z_i gamma + u0_id[i] + u1_id[i] x_i; [u0, u1] use an A-matrix animal covariance only after the count scale-side mapping is reviewed",
        "dgp_requirements": "count response y >= 0; named animal levels matching Ainv/Q; finite positive dispersion; one ordinary predictor x with within-animal replication and no missing matrix levels",
        "implementation_requirements": "reuse nbinom2() sigma likelihood and animal() known-covariance parser shape only after scale-side interpretation is reviewed; do not change formula grammar, public API, mu routes, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, animal sigma-side SD extraction for intercept and slope, extractor visibility, and deterministic seed provenance; not a denominator or coverage run",
        "next_action": "review this contract before any count NB2 sigma animal code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_phylo_nbinom2_q1_sigma_one_slope_rejected": {
        "contract_id": "qseries_v1_phylo_nbinom2_sigma_one_slope_design_contract",
        "model_contract": "y_i ~ NB2(mu_i, phi_i); log(mu_i) = X_i beta; log(sigma_i) = Z_i gamma + u0_tip[i] + u1_tip[i] x_i; [u0, u1] use a phylogenetic covariance only after the count scale-side mapping is reviewed",
        "dgp_requirements": "count response y >= 0; named phylo tips matching the tree; finite positive dispersion; one ordinary predictor x with within-tip replication and no missing tips",
        "implementation_requirements": "reuse nbinom2() sigma likelihood and phylo() covariance parser shape only after scale-side interpretation is reviewed; do not change formula grammar, public API, mu routes, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, phylo sigma-side SD extraction for intercept and slope, extractor visibility, and deterministic seed provenance; not a denominator or coverage run",
        "next_action": "review this contract before any count NB2 sigma phylo code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_relmat_nbinom2_q1_sigma_one_slope_rejected": {
        "contract_id": "qseries_v1_relmat_nbinom2_sigma_one_slope_design_contract",
        "model_contract": "y_i ~ NB2(mu_i, phi_i); log(mu_i) = X_i beta; log(sigma_i) = Z_i gamma + u0_id[i] + u1_id[i] x_i; [u0, u1] use a K/Q relmat covariance only after the count scale-side mapping is reviewed",
        "dgp_requirements": "count response y >= 0; named relmat levels matching K/Q input; finite positive dispersion; one ordinary predictor x with within-level replication and no missing matrix levels",
        "implementation_requirements": "reuse nbinom2() sigma likelihood and relmat() known-covariance parser shape only after scale-side interpretation is reviewed; do not change formula grammar, public API, mu routes, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, relmat sigma-side SD extraction for intercept and slope, extractor visibility, and deterministic seed provenance; not a denominator or coverage run",
        "next_action": "review this contract before any count NB2 sigma relmat code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_poisson_zi_spatial_rejected": {
        "contract_id": "qseries_v1_poisson_zi_spatial_design_contract",
        "model_contract": "y_i ~ zero-inflated Poisson(mu_i, pi_i); log(mu_i) = X_i beta; logit(pi_i) = Z_i gamma + u_site[i]; u ~ N(0, sigma_spatial^2 C(distance))",
        "dgp_requirements": "count response y >= 0; enough observed zeros to identify zero inflation; named spatial levels with valid coordinates; fixed mu route; no duplicate or missing coordinate levels",
        "implementation_requirements": "review zero-inflation link and extractor naming before reusing spatial() parser shape; do not change formula grammar, public API, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, spatial zero-inflation SD extraction, extractor visibility, and deterministic seed provenance only after the zero-inflation route is reviewed; not a denominator or coverage run",
        "next_action": "review the Poisson zi spatial design contract before any zero-inflation code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_truncnbinom2_hu_relmat_rejected": {
        "contract_id": "qseries_v1_truncnbinom2_hu_relmat_design_contract",
        "model_contract": "y_i ~ hurdle NB2(mu_i, sigma_i, pi_i); log(mu_i) = X_i beta; logit(pi_i) = Z_i gamma + u_id[i]; u ~ N(0, sigma_relmat^2 K)",
        "dgp_requirements": "non-negative count response with hurdle zeros and positive truncated counts; named relmat levels matching K/Q input; fixed mu and sigma route; no missing matrix levels",
        "implementation_requirements": "review hurdle-link likelihood routing and extractor naming before reusing relmat() parser shape; do not change formula grammar, public API, q2/q4, REML, or AI-REML",
        "recovery_requirements": "one local debug fixture may check finite fit, relmat hurdle-side SD extraction, extractor visibility, and deterministic seed provenance only after the hurdle route is reviewed; not a denominator or coverage run",
        "next_action": "review the truncated NB2 hu relmat design contract before any hurdle code, local debug fit, host compute, or support-cell edit",
    },
    "qseries_count_mu_labelled_q2_rejected": {
        "contract_id": "qseries_v1_count_mu_labelled_q2_design_contract",
        "model_contract": "y_i ~ Poisson(mu_i); log(mu_i) = X_i beta + u_endpoint,site[i]; labelled q=2 structured count-mu covariance would require an explicit endpoint/block mapping before parser admission",
        "dgp_requirements": "count response y >= 0; named spatial levels and valid coordinates; labelled endpoint/block syntax present; enough within-level replication to detect labelled covariance mistakes",
        "implementation_requirements": "derive the labelled structured count-mu covariance contract before changing the formula gate; do not change formula grammar, public API, q4, REML, AI-REML, or interval/coverage wording",
        "recovery_requirements": "one local debug fixture may only reproduce the current labelled q=2 rejection or, after review, check parser diagnostics; not a denominator or coverage run",
        "next_action": "review the labelled q=2 structured count-mu design before any parser edit, local debug fit, host compute, or support-cell edit",
    },
    # Row 105 (qseries_count_mu_simultaneous_structured_types_rejected) was
    # admitted recovery-only in M5: the crossed spatial+relmat NB2 model now
    # BUILDS instead of rejecting, so it is no longer a post-v1 design-contract
    # candidate and its stale "one-structured-provider gate" contract entry is
    # removed.
    "qseries_animal_q2_plus_q2_sigma_rejected": {
        "contract_id": "qseries_v1_animal_q2_plus_q2_sigma_design_contract",
        "model_contract": "biv_gaussian() with animal(1 | ps | id, A/Ainv = A) in sigma1 and sigma2 has native point-fit/extractor evidence only; scale-scale profile geometry, retained denominator policy, and bridge payload policy remain unadmitted",
        "dgp_requirements": "two-response Gaussian data; named animal levels matching A/Ainv/pedigree input; separate labelled scale-side block; enough within-level replication to identify sigma1, sigma2, and their scale-scale relationship",
        "implementation_requirements": "review the animal scale-side q2-plus-q2 interval/denominator route before any status promotion; do not change formula grammar broadly, public API, q4/q8, REML, AI-REML, interval, or coverage wording",
        "recovery_requirements": "local point-fit/extractor fixture is already banked; any next local debug may only inspect scale-scale profile geometry or denominator design, not claim coverage",
        "next_action": "review the animal q2-plus-q2 sigma scale-scale profile and retained-denominator design before any host compute or support-cell edit",
    },
    "qseries_relmat_q2_plus_q2_sigma_rejected": {
        "contract_id": "qseries_v1_relmat_q2_plus_q2_sigma_design_contract",
        "model_contract": "biv_gaussian() with relmat(1 | ps | id, K/Q = K/Q) in sigma1 and sigma2 has native point-fit/extractor evidence only; scale-scale profile geometry, retained denominator policy, and bridge payload policy remain unadmitted",
        "dgp_requirements": "two-response Gaussian data; named relmat levels matching K/Q input; separate labelled scale-side block; enough within-level replication to identify sigma1, sigma2, and their scale-scale relationship",
        "implementation_requirements": "review the relmat scale-side q2-plus-q2 interval/denominator route before any status promotion; do not change formula grammar broadly, public API, q4/q8, REML, AI-REML, interval, or coverage wording",
        "recovery_requirements": "local point-fit/extractor fixture is already banked; any next local debug may only inspect scale-scale profile geometry or denominator design, not claim coverage",
        "next_action": "review the relmat q2-plus-q2 sigma scale-scale profile and retained-denominator design before any host compute or support-cell edit",
    },
    "qseries_spatial_q2_plus_q2_sigma_rejected": {
        "contract_id": "qseries_v1_spatial_q2_plus_q2_sigma_design_contract",
        "model_contract": "biv_gaussian() with spatial(1 | ps | site, coords = coords) in sigma1 and sigma2 has native point-fit/extractor evidence only; scale-scale profile geometry, retained denominator policy, and bridge payload policy remain unadmitted",
        "dgp_requirements": "two-response Gaussian data; named spatial levels with valid coordinates; separate labelled scale-side block; enough within-level replication to identify sigma1, sigma2, and their scale-scale relationship",
        "implementation_requirements": "review the spatial scale-side q2-plus-q2 interval/denominator route before any status promotion; do not change formula grammar broadly, public API, q4/q8, REML, AI-REML, interval, or coverage wording",
        "recovery_requirements": "local point-fit/extractor fixture is already banked; any next local debug may only inspect scale-scale profile geometry or denominator design, not claim coverage",
        "next_action": "review the spatial q2-plus-q2 sigma scale-scale profile and retained-denominator design before any host compute or support-cell edit",
    },
    "qseries_nongaussian_structured_slope_neighbors_planned": {
        "contract_id": "qseries_v1_nongaussian_structured_slope_neighbors_design_contract",
        "model_contract": "family-specific non-Gaussian structured one-slope neighbors must be split into explicit family/provider/endpoint routes before any runtime gate; no pooled all-family likelihood contract exists",
        "dgp_requirements": "one named family per fixture; valid response support; one structured provider at a time; one ordinary predictor with within-level replication; no labelled covariance, multiple slopes, q2/q4, or endpoint pooling",
        "implementation_requirements": "choose a single family/provider/endpoint slice and write the parser, extractor, and likelihood contract before code; do not change formula grammar broadly, public API, q2/q4, REML, AI-REML, interval, or coverage wording",
        "recovery_requirements": "one local debug fixture may only document the planned design boundary or, after review, check a single-family finite fit and extractor visibility; not a denominator or coverage run",
        "next_action": "split the slope-neighbor row into one family/provider/endpoint design before any code, local debug fit, host compute, or support-cell edit",
    },
}


def build_first_four_contract_rows(
    *,
    support_rows: list[dict[str, str]],
    ledger_rows: list[dict[str, str]],
    review_packet_rows: list[dict[str, str]],
) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for packet_row in review_packet_rows:
        cell_id = packet_row["cell_id"]
        support_row = next(row for row in support_rows if row["cell_id"] == cell_id)
        ledger_row = next(row for row in ledger_rows if row["cell_id"] == cell_id)
        detail = FIRST_FOUR_CONTRACT_DETAIL.get(cell_id)
        if detail is None:
            contract_slug = cell_id.removeprefix("qseries_")
            contract_slug = contract_slug.replace("_planned", "")
            contract_slug = contract_slug.replace("_rejected", "")
            detail = {
                "contract_id": f"qseries_v1_{contract_slug}_design_contract",
                "model_contract": (
                    f"{support_row['formula_cell']} remains a planned "
                    f"{support_row['family']} {support_row['dimension_pattern']} "
                    f"{support_row['endpoint_set']} route until a row-specific "
                    "runtime, extractor, and recovery contract is written"
                ),
                "dgp_requirements": (
                    "row-specific data-generating process, named grouping levels, "
                    "structured covariance input, and extractor target identities "
                    "must be documented before implementation"
                ),
                "implementation_requirements": (
                    "write the row-specific parser, TMB routing, extractor, and "
                    "recovery test contract; do not change formula grammar, public "
                    "API, q4/q8 scope, REML, AI-REML, interval, or coverage wording"
                ),
                "recovery_requirements": (
                    "one local debug fixture may check finite fit and extractor "
                    "visibility after design review; not a denominator or coverage run"
                ),
                "next_action": (
                    "review the planned-row design contract before any code, local "
                    "debug fit, host compute, or support-cell edit"
                ),
            }
        rows.append(
            {
                "contract_id": detail["contract_id"],
                "source_packet_id": packet_row["contract_id"],
                "cell_id": cell_id,
                "formula_cell": support_row["formula_cell"],
                "family": support_row["family"],
                "structure_provider": support_row["structure_provider"],
                "current_v1_track": ledger_row["v1_track"],
                "current_fit_status": support_row["fit_status"],
                "current_interval_status": support_row["interval_status"],
                "current_coverage_status": support_row["coverage_status"],
                "existing_evidence_url": support_row["evidence_url"],
                "model_contract": detail["model_contract"],
                "dgp_requirements": detail["dgp_requirements"],
                "implementation_requirements": detail["implementation_requirements"],
                "recovery_requirements": detail["recovery_requirements"],
                "failure_requirements": "if the current pre-optimization rejection remains, keep unsupported status and record the failure class before any code or compute proposal",
                "validator_requirements": "preflight report, candidate TSV, next-four packet, focused conversion-contract test, claim guard, and Mission Control must remain green",
                "blocking_reviewers": "Rose/Fisher/Grace",
                "compute_decision": "no_compute_authorized",
                "coverage_decision": "coverage_not_authorized",
                "promotion_decision": "do_not_promote",
                "claim_boundary": "this design contract is not implementation evidence, recovery evidence, inference_ready, supported, coverage, q4/q8, REML, AI-REML, bridge, or public-support authority",
                "next_action": detail["next_action"],
            }
        )
    return rows


def build_first_contract_rows(
    *,
    support_rows: list[dict[str, str]],
    ledger_rows: list[dict[str, str]],
    review_packet_rows: list[dict[str, str]],
) -> list[dict[str, str]]:
    return build_first_four_contract_rows(
        support_rows=support_rows,
        ledger_rows=ledger_rows,
        review_packet_rows=review_packet_rows,
    )[:1]


def build_debug_fixture_rows(
    *,
    first_contract_rows: list[dict[str, str]],
    rejection_rows: list[dict[str, str]],
) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    for contract_row in first_contract_rows:
        cell_id = contract_row["cell_id"]
        rejection_row = next(
            (row for row in rejection_rows if row["cell_id"] == cell_id),
            None,
        )
        if rejection_row is None:
            rejection_slug = cell_id.removesuffix("_planned")
            rejection_row = {
                "rejection_id": f"{rejection_slug}_planned_boundary",
                "expected_error_pattern": "not_run_planned_design",
                "rejection_stage": "planned_design_boundary",
            }
        rows.append(
            {
                "debug_contract_id": contract_row["contract_id"].replace(
                    "_design_contract",
                    "_local_debug_contract",
                ),
                "source_contract_id": contract_row["contract_id"],
                "source_rejection_id": rejection_row["rejection_id"],
                "cell_id": cell_id,
                "formula_cell": contract_row["formula_cell"],
                "expected_current_failure": rejection_row["expected_error_pattern"],
                "failure_stage": rejection_row["rejection_stage"],
                "debug_scope": "local_debug_only_no_denominator",
                "fixture_dgp": contract_row["dgp_requirements"],
                "allowed_action": "future local debug fixture may either reproduce current pre-optimization rejection or, after implementation review, check finite fit and extractor visibility",
                "stop_if": "current rejection message changes without contract update; formula grammar changes; response has invalid support values; host path is used; denominator rows are created; fit result is interpreted as coverage or status evidence",
                "required_outputs": "one log, one seed, session info, fixture summary, exact error or finite fit summary, no support-cell edit",
                "validator_requirements": "preflight report, candidate TSV, next-four packet, first-four design contracts, focused conversion-contract test, claim guard, and Mission Control must remain green",
                "blocking_reviewers": "Rose/Fisher/Grace",
                "compute_decision": "no_compute_authorized",
                "coverage_decision": "coverage_not_authorized",
                "promotion_decision": "do_not_promote",
                "claim_boundary": "debug fixture contract is not implementation evidence, recovery evidence, inference_ready, supported, coverage, q4/q8, REML, AI-REML, bridge, or public-support authority",
                "next_action": "write or review a fail-closed local debug fixture runner contract before executing any local fit",
            }
        )
    return rows


def render_tsv(rows: list[dict[str, str]], fields: tuple[str, ...]) -> str:
    lines = ["\t".join(fields)]
    for row in rows:
        lines.append("\t".join(row[field] for field in fields))
    return "\n".join(lines) + "\n"


def render_candidate_report_rows(candidate_rows: list[dict[str, str]]) -> str:
    selected = candidate_rows[:10]
    return "\n".join(
        (
            f"| {row['review_rank']} | {row['target_band']} | "
            f"`{row['cell_id']}` | {row['family']} | "
            f"{row['structure_provider']} | {row['review_reason']} |"
        )
        for row in selected
    )


def render_review_packet_report_rows(packet_rows: list[dict[str, str]]) -> str:
    return "\n".join(
        (
            f"| {row['review_rank']} | `{row['cell_id']}` | {row['model_scope']} | "
            f"{row['minimum_recovery_evidence']} | {row['next_action']} |"
        )
        for row in packet_rows
    )


def render_ninety_economy_report_rows(economy_rows: list[dict[str, str]]) -> str:
    return "\n".join(
        (
            f"| {row['review_rank']} | `{row['cell_id']}` | "
            f"{row['implementation_cost']} | {row['least_compute_next_action']} | "
            f"{row['why_not_parallel_compute']} |"
        )
        for row in economy_rows
    )


def render_first_contract_report_rows(contract_rows: list[dict[str, str]]) -> str:
    return "\n".join(
        (
            f"| `{row['cell_id']}` | {row['formula_cell']} | "
            f"{row['model_contract']} | {row['recovery_requirements']} | "
            f"{row['promotion_decision']} |"
        )
        for row in contract_rows
    )


def render_debug_fixture_report_rows(debug_rows: list[dict[str, str]]) -> str:
    return "\n".join(
        (
            f"| `{row['cell_id']}` | {row['debug_scope']} | "
            f"{row['expected_current_failure']} | {row['stop_if']} | "
            f"{row['promotion_decision']} |"
        )
        for row in debug_rows
    )


def last_nonempty_line(text: str) -> str:
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return lines[-1] if lines else ""


def output_has_marker(output: str, marker: str) -> bool:
    return any(marker in line for line in output.splitlines())


def render_report(
    *,
    progress: dict[str, str],
    candidate_rows: list[dict[str, str]],
    review_packet_rows: list[dict[str, str]],
    ninety_packet_rows: list[dict[str, str]],
    ninety_economy_rows: list[dict[str, str]],
    first_contract_rows: list[dict[str, str]],
    debug_fixture_rows: list[dict[str, str]],
    first_four_contract_rows: list[dict[str, str]],
    first_four_debug_rows: list[dict[str, str]],
    outputs: dict[str, str],
    mission_status: str,
    skip_mission_control: bool,
) -> str:
    ledger_status = "ok" if output_has_marker(outputs.get("qseries_v1_release_ledger", ""), "qseries_v1_release_ledger:") else "unknown"
    claim_guard_status = "ok" if output_has_marker(outputs.get("qseries_v1_claim_guard", ""), "qseries_v1_claim_guard_ok:") else "unknown"
    mission_boundary = (
        "Mission Control was skipped for this generated report."
        if skip_mission_control
        else "Mission Control passed in this generated report."
    )
    target_rows = row_target_gaps(progress)
    target_table = "\n".join(
        f"| {row['target']} practical surface | {row['required']} | {row['needed']} |"
        for row in target_rows
    )
    candidate_table = render_candidate_report_rows(candidate_rows)
    review_packet_table = render_review_packet_report_rows(review_packet_rows)
    ninety_packet_table = render_review_packet_report_rows(ninety_packet_rows)
    ninety_economy_table = render_ninety_economy_report_rows(ninety_economy_rows)
    first_contract_table = render_first_contract_report_rows(first_contract_rows)
    debug_fixture_table = render_debug_fixture_report_rows(debug_fixture_rows)
    first_four_contract_table = render_first_contract_report_rows(first_four_contract_rows)
    first_four_debug_table = render_debug_fixture_report_rows(first_four_debug_rows)
    return f"""# Q-Series v1.0 Preflight Report

Generated by `tools/qseries_v1_release_check.py`.

## Summary

The Q-Series v1.0 release preflight status is:

- Generated ledger/status: `{ledger_status}`
- Public claim guard: `{claim_guard_status}`
- Mission Control: `{mission_status}`

{mission_boundary}

## Row Accounting

| Measure | Rows and percent |
| --- | --- |
| Practical v1.0 row surface | {progress.get('Practical v1.0 row surface', 'NA')} |
| Gaussian v1.0 core | {progress.get('Gaussian v1.0 core', 'NA')} |
| Basic-distribution recovery | {progress.get('Basic-distribution recovery', 'NA')} |
| Exact `inference_ready` anchors | {progress.get('Exact `inference_ready` anchors', 'NA')} |
| `supported` authority | {progress.get('`supported` authority', 'NA')} |
| Post-v1.0 validation/design | {progress.get('Post-v1.0 validation/design', 'NA')} |

## Distance To Row-Accounting Targets

These counters are planning aids only. They do not authorize row movement,
coverage jobs, public release claims, `inference_ready`, or `supported` status.

| Target | Required practical-surface rows | Rows still needed |
| --- | ---: | ---: |
{target_table}

## Next Candidate Review Queue

This queue ranks post-v1.0 rows for review only. It is designed to make the
next 80% practical-surface discussion faster, not to promote rows.
Every generated candidate remains `coverage_not_authorized` and
`do_not_promote` until row-specific evidence and review exist.

| Rank | Target band | Cell | Family | Provider | Review reason |
| ---: | --- | --- | --- | --- | --- |
{candidate_table}

## Next Rows To 90% Review Packet

This generated packet expands the current `rows_to_90` counter into the exact
rows that would need row-specific evidence before the practical v1.0 surface
could reach 90%. It is a review queue only: every row remains
`coverage_not_authorized` and `do_not_promote`.

| Rank | Cell | Model scope | Minimum recovery evidence | Next action |
| ---: | --- | --- | --- | --- |
{ninety_packet_table}

## Next Rows To 90% Economy Plan

This generated economy view records the least-compute next action for the same
rows needed to reach 90% practical-surface accounting. It is planning-only:
it does not authorize local fits, host jobs, support-cell movement, coverage,
`inference_ready`, `supported`, REML, AI-REML, bridge, or public-support
wording.

| Rank | Cell | Implementation cost | Least-compute next action | Why parallel compute waits |
| ---: | --- | --- | --- | --- |
{ninety_economy_table}

## Next-Four After 75% Review Packet

These four rows are the current generated review packet after reaching the 75%
practical-surface threshold. The packet is a design/recovery checklist only: it
does not authorize code changes, compute, status edits, coverage, or promotion.

| Rank | Cell | Model scope | Minimum recovery evidence | Next action |
| ---: | --- | --- | --- | --- |
{review_packet_table}

## First Candidate Design Contract

The first next-four packet row has a generated design/recovery contract. This is a
pre-code review artifact: it specifies the model and minimum evidence needed
before any local debug fit, host compute, or support-cell edit is proposed.

| Cell | Formula cell | Model contract | Minimum recovery evidence | Promotion decision |
| --- | --- | --- | --- | --- |
{first_contract_table}

## First Candidate Local-Debug Fixture Contract

The first design contract now has a generated local-debug fixture contract.
This still authorizes no fit: it records the current failure signature, the
allowed future local fixture shape, and the stop rules that prevent a debug run
from becoming denominator, coverage, status, or public-support evidence.
The debug fixture contract is not implementation evidence, recovery evidence,
`inference_ready`, `supported`, coverage, q4/q8, REML, AI-REML, bridge, or
public-support authority.

| Cell | Debug scope | Expected current failure | Stop if | Promotion decision |
| --- | --- | --- | --- | --- |
{debug_fixture_table}

## Next-Four After 75% Design Contracts

The complete first-four packet now has generated row-specific design contracts.
These contracts are review artifacts only. They specify the minimum model,
data-generating, recovery, and failure boundary before any local debug runner or
status movement is proposed.

| Cell | Formula cell | Model contract | Minimum recovery evidence | Promotion decision |
| --- | --- | --- | --- | --- |
{first_four_contract_table}

## Next-Four After 75% Local-Debug Fixture Contracts

The complete first-four packet also has generated local-debug fixture
contracts. They keep the current rejection signature, local-only fixture scope,
and stop rules visible for every candidate row.

To reproduce the current fail-closed rejection baseline before any
implementation attempt, run:

```sh
R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R
```

That smoke is local gate evidence only. It creates no fit denominator,
coverage evidence, status movement, or public support.

| Cell | Debug scope | Expected current failure | Stop if | Promotion decision |
| --- | --- | --- | --- | --- |
{first_four_debug_table}

## Boundary

This report is release-prep evidence only. It promotes no support-cell status,
authorizes no compute, and makes no coverage, q4/q8, REML, AI-REML, broad
bridge-support, `supported`, or public-support claim.

## Routine Command

```sh
python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates
```

For a fast planning snapshot only, run:

```sh
python3 tools/qseries_v1_release_check.py --fast-status
```

The fast status mode reads checked-in release artifacts and intentionally skips
ledger regeneration, the claim guard, and Mission Control. Use the routine
preflight before banking evidence, status movement, or public wording.
"""


def main() -> int:
    args = parse_args()
    root = args.root.resolve()
    python = sys.executable or "python3"
    env = os.environ.copy()
    env.update(
        {
            "PYTHONDONTWRITEBYTECODE": "1",
            "R_PROFILE_USER": "/dev/null",
            "NOT_CRAN": "true",
        }
    )

    if args.fast_status:
        progress = parse_status_progress(root / STATUS_PATH.relative_to(ROOT))
        if "Practical v1.0 row surface" not in progress:
            print(
                f"{root / STATUS_PATH.relative_to(ROOT)}: missing v1.0 progress table",
                file=sys.stderr,
            )
            return 1
        ledger_path = root / LEDGER_PATH.relative_to(ROOT)
        if not ledger_path.exists():
            print(f"{ledger_path}: missing generated v1.0 release ledger", file=sys.stderr)
            return 1
        ledger_rows = read_tsv(ledger_path)
        candidate_rows = build_candidate_rows(ledger_rows)
        print(render_fast_status(progress=progress, candidate_rows=candidate_rows))
        return 0

    steps = [
        (
            "qseries_v1_release_ledger",
            [
                python,
                "tools/qseries_v1_release_ledger.py",
                "--check",
                "--check-status",
                "--summary",
            ],
        ),
        (
            "qseries_v1_claim_guard",
            [python, "tools/qseries_v1_claim_guard.py", "--root", str(root), "--summary"],
        ),
    ]
    if not args.skip_mission_control:
        steps.append(
            (
                "mission_control",
                [python, "tools/validate-mission-control.py"],
            )
        )

    outputs: dict[str, str] = {}
    ok = True
    for label, command in steps:
        step_ok, output = run_step(label, command, root, env)
        outputs[label] = output
        ok = ok and step_ok
    if not ok:
        return 1

    progress = parse_status_progress(root / STATUS_PATH.relative_to(ROOT))
    mission_status = "skipped"
    if not args.skip_mission_control:
        mission_line = last_nonempty_line(outputs.get("mission_control", ""))
        mission_status = "ok" if mission_line.startswith("mission_control_ok:") else "unknown"
    support_rows = read_tsv(root / SUPPORT_PATH.relative_to(ROOT))
    ledger_rows = read_tsv(root / LEDGER_PATH.relative_to(ROOT))
    rejection_rows = read_tsv(root / REJECTION_PATH.relative_to(ROOT))
    rejection_rows.extend(
        read_tsv(root / COUNT_SIGMA_REJECTION_PATH.relative_to(ROOT))
    )
    rejection_rows.extend(
        read_tsv(root / COUNT_MU_REJECTION_PATH.relative_to(ROOT))
    )
    rejection_rows.extend(
        read_tsv(root / Q2_PLUS_Q2_SIGMA_REJECTION_PATH.relative_to(ROOT))
    )
    rejection_rows.append(
        {
            "rejection_id": "nongaussian_structured_slope_neighbors_planned_boundary",
            "cell_id": "qseries_nongaussian_structured_slope_neighbors_planned",
            "formula_cell": "non-count or labelled/multiple structured non-Gaussian slope variants",
            "family": "non-count or extended count families",
            "structured_type": "all_structured",
            "dimension": "q1",
            "endpoint": "mu",
            "slope_class": "independent_one_slope",
            "expected_error_pattern": "not_run_planned_design",
            "rejection_stage": "planned_design_boundary",
            "fit_status": "planned",
            "extractor_status": "planned",
            "bridge_status": "planned",
            "interval_status": "unsupported",
            "coverage_status": "planned",
            "evidence_url": "docs/design/59-structural-slope-and-non-gaussian-map.md",
            "claim_boundary": "planned design boundary only; no runtime rejection, fit, denominator, interval, coverage, inference_ready, supported, REML, AI-REML, bridge, q2/q4, or public-support claim",
            "next_gate": "Split by family/DGP/extractor/recovery contract before runtime work.",
        }
    )
    candidate_rows = build_candidate_rows(ledger_rows)
    review_packet_rows = build_review_packet_rows(candidate_rows)
    ninety_packet_rows = build_ninety_review_packet_rows(candidate_rows, progress)
    ninety_economy_rows = build_ninety_economy_rows(candidate_rows, progress)
    first_four_contract_rows = build_first_four_contract_rows(
        support_rows=support_rows,
        ledger_rows=ledger_rows,
        review_packet_rows=review_packet_rows,
    )
    first_contract_rows = build_first_contract_rows(
        support_rows=support_rows,
        ledger_rows=ledger_rows,
        review_packet_rows=review_packet_rows,
    )
    debug_fixture_rows = build_debug_fixture_rows(
        first_contract_rows=first_contract_rows,
        rejection_rows=rejection_rows,
    )
    first_four_debug_rows = build_debug_fixture_rows(
        first_contract_rows=first_four_contract_rows,
        rejection_rows=rejection_rows,
    )
    report = render_report(
        progress=progress,
        candidate_rows=candidate_rows,
        review_packet_rows=review_packet_rows,
        ninety_packet_rows=ninety_packet_rows,
        ninety_economy_rows=ninety_economy_rows,
        first_contract_rows=first_contract_rows,
        debug_fixture_rows=debug_fixture_rows,
        first_four_contract_rows=first_four_contract_rows,
        first_four_debug_rows=first_four_debug_rows,
        outputs=outputs,
        mission_status=mission_status,
        skip_mission_control=args.skip_mission_control,
    )
    candidates = render_tsv(candidate_rows, CANDIDATE_FIELDS)
    review_packet = render_tsv(review_packet_rows, REVIEW_PACKET_FIELDS)
    ninety_packet = render_tsv(ninety_packet_rows, REVIEW_PACKET_FIELDS)
    ninety_economy = render_tsv(ninety_economy_rows, NINETY_ECONOMY_FIELDS)
    first_contract = render_tsv(first_contract_rows, FIRST_CONTRACT_FIELDS)
    debug_fixture = render_tsv(debug_fixture_rows, DEBUG_FIXTURE_FIELDS)
    first_four_contracts = render_tsv(first_four_contract_rows, FIRST_CONTRACT_FIELDS)
    first_four_debug = render_tsv(first_four_debug_rows, DEBUG_FIXTURE_FIELDS)

    report_path = args.report_output
    if not report_path.is_absolute():
        report_path = root / report_path
    if args.check_report:
        if not report_path.exists():
            print(f"{report_path}: missing generated preflight report", file=sys.stderr)
            return 1
        current_report = report_path.read_text(encoding="utf-8")
        if current_report != report:
            print(f"{report_path}: differs from generated preflight report", file=sys.stderr)
            return 1
    if args.write_report:
        report_path.write_text(report, encoding="utf-8")

    candidate_path = args.candidate_output
    if not candidate_path.is_absolute():
        candidate_path = root / candidate_path
    if args.check_candidates:
        if not candidate_path.exists():
            print(
                f"{candidate_path}: missing generated next-candidate review",
                file=sys.stderr,
            )
            return 1
        current_candidates = candidate_path.read_text(encoding="utf-8")
        if current_candidates != candidates:
            print(
                f"{candidate_path}: differs from generated next-candidate review",
                file=sys.stderr,
            )
            return 1
        review_packet_path = args.review_packet_output
        if not review_packet_path.is_absolute():
            review_packet_path = root / review_packet_path
        if not review_packet_path.exists():
            print(
                f"{review_packet_path}: missing generated 75 percent review packet",
                file=sys.stderr,
            )
            return 1
        current_review_packet = review_packet_path.read_text(encoding="utf-8")
        if current_review_packet != review_packet:
            print(
                f"{review_packet_path}: differs from generated 75 percent review packet",
                file=sys.stderr,
            )
            return 1
        ninety_packet_path = args.ninety_packet_output
        if not ninety_packet_path.is_absolute():
            ninety_packet_path = root / ninety_packet_path
        if not ninety_packet_path.exists():
            print(
                f"{ninety_packet_path}: missing generated 90 percent review packet",
                file=sys.stderr,
            )
            return 1
        current_ninety_packet = ninety_packet_path.read_text(encoding="utf-8")
        if current_ninety_packet != ninety_packet:
            print(
                f"{ninety_packet_path}: differs from generated 90 percent review packet",
                file=sys.stderr,
            )
            return 1
        ninety_economy_path = args.ninety_economy_output
        if not ninety_economy_path.is_absolute():
            ninety_economy_path = root / ninety_economy_path
        if not ninety_economy_path.exists():
            print(
                f"{ninety_economy_path}: missing generated 90 percent economy plan",
                file=sys.stderr,
            )
            return 1
        current_ninety_economy = ninety_economy_path.read_text(encoding="utf-8")
        if current_ninety_economy != ninety_economy:
            print(
                f"{ninety_economy_path}: differs from generated 90 percent economy plan",
                file=sys.stderr,
            )
            return 1
        first_contract_path = args.first_contract_output
        if not first_contract_path.is_absolute():
            first_contract_path = root / first_contract_path
        if not first_contract_path.exists():
            print(
                f"{first_contract_path}: missing generated first-candidate design contract",
                file=sys.stderr,
            )
            return 1
        current_first_contract = first_contract_path.read_text(encoding="utf-8")
        if current_first_contract != first_contract:
            print(
                f"{first_contract_path}: differs from generated first-candidate design contract",
                file=sys.stderr,
            )
            return 1
        debug_fixture_path = args.debug_fixture_output
        if not debug_fixture_path.is_absolute():
            debug_fixture_path = root / debug_fixture_path
        if not debug_fixture_path.exists():
            print(
                f"{debug_fixture_path}: missing generated first-candidate debug fixture contract",
                file=sys.stderr,
            )
            return 1
        current_debug_fixture = debug_fixture_path.read_text(encoding="utf-8")
        if current_debug_fixture != debug_fixture:
            print(
                f"{debug_fixture_path}: differs from generated first-candidate debug fixture contract",
                file=sys.stderr,
            )
            return 1
        first_four_contract_path = args.first_four_contract_output
        if not first_four_contract_path.is_absolute():
            first_four_contract_path = root / first_four_contract_path
        if not first_four_contract_path.exists():
            print(
                f"{first_four_contract_path}: missing generated first-four design contracts",
                file=sys.stderr,
            )
            return 1
        current_first_four_contracts = first_four_contract_path.read_text(encoding="utf-8")
        if current_first_four_contracts != first_four_contracts:
            print(
                f"{first_four_contract_path}: differs from generated first-four design contracts",
                file=sys.stderr,
            )
            return 1
        first_four_debug_path = args.first_four_debug_output
        if not first_four_debug_path.is_absolute():
            first_four_debug_path = root / first_four_debug_path
        if not first_four_debug_path.exists():
            print(
                f"{first_four_debug_path}: missing generated first-four debug fixture contracts",
                file=sys.stderr,
            )
            return 1
        current_first_four_debug = first_four_debug_path.read_text(encoding="utf-8")
        if current_first_four_debug != first_four_debug:
            print(
                f"{first_four_debug_path}: differs from generated first-four debug fixture contracts",
                file=sys.stderr,
            )
            return 1
    if args.write_candidates:
        candidate_path.write_text(candidates, encoding="utf-8")
        review_packet_path = args.review_packet_output
        if not review_packet_path.is_absolute():
            review_packet_path = root / review_packet_path
        review_packet_path.write_text(review_packet, encoding="utf-8")
        ninety_packet_path = args.ninety_packet_output
        if not ninety_packet_path.is_absolute():
            ninety_packet_path = root / ninety_packet_path
        ninety_packet_path.write_text(ninety_packet, encoding="utf-8")
        ninety_economy_path = args.ninety_economy_output
        if not ninety_economy_path.is_absolute():
            ninety_economy_path = root / ninety_economy_path
        ninety_economy_path.write_text(ninety_economy, encoding="utf-8")
        first_contract_path = args.first_contract_output
        if not first_contract_path.is_absolute():
            first_contract_path = root / first_contract_path
        first_contract_path.write_text(first_contract, encoding="utf-8")
        debug_fixture_path = args.debug_fixture_output
        if not debug_fixture_path.is_absolute():
            debug_fixture_path = root / debug_fixture_path
        debug_fixture_path.write_text(debug_fixture, encoding="utf-8")
        first_four_contract_path = args.first_four_contract_output
        if not first_four_contract_path.is_absolute():
            first_four_contract_path = root / first_four_contract_path
        first_four_contract_path.write_text(first_four_contracts, encoding="utf-8")
        first_four_debug_path = args.first_four_debug_output
        if not first_four_debug_path.is_absolute():
            first_four_debug_path = root / first_four_debug_path
        first_four_debug_path.write_text(first_four_debug, encoding="utf-8")

    if args.summary:
        target_summary = target_gap_summary(progress)
        print(
            (
                "qseries_v1_release_check_ok: "
                f"ledger=ok; claim_guard=ok; mission_control={mission_status}; "
                f"practical_v1_surface={progress.get('Practical v1.0 row surface', 'NA')}; "
                f"gaussian_core={progress.get('Gaussian v1.0 core', 'NA')}; "
                f"basic_distribution_recovery={progress.get('Basic-distribution recovery', 'NA')}; "
                f"exact_inference_ready={progress.get('Exact `inference_ready` anchors', 'NA')}; "
                f"supported_authority={progress.get('`supported` authority', 'NA')}; "
                f"post_v1={progress.get('Post-v1.0 validation/design', 'NA')}; "
                f"{target_summary}; "
                f"candidate_review_rows={len(candidate_rows)}; "
                f"ninety_review_packet_rows={len(ninety_packet_rows)}; "
                f"ninety_economy_rows={len(ninety_economy_rows)}; "
                f"first_four_review_packet_rows={len(review_packet_rows)}; "
                f"first_candidate_contract_rows={len(first_contract_rows)}; "
                f"debug_fixture_contract_rows={len(debug_fixture_rows)}; "
                f"first_four_contract_rows={len(first_four_contract_rows)}; "
                f"first_four_debug_fixture_rows={len(first_four_debug_rows)}"
            ),
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
