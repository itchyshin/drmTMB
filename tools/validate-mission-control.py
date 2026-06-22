#!/usr/bin/env python3
"""Validate the local drmTMB mission-control dashboard files.

This script deliberately uses only the Python standard library. It is a
developer guard for status drift; it is not part of the R package runtime.
"""

from __future__ import annotations

import json
import pathlib
import re
import sys


ROOT = pathlib.Path(__file__).resolve().parents[1]
DASHBOARD = ROOT / "docs" / "dev-log" / "dashboard"
DESIGN_MATRIX = ROOT / "docs" / "design" / "168-r-julia-finish-capability-matrix.md"
GATE_REGISTRY = DASHBOARD / "julia-gates.tsv"
CAPABILITY_REGISTRY = DASHBOARD / "julia-capabilities.tsv"
HUNDRED_SLICE_LEDGER = DASHBOARD / "finish-100-slices.tsv"
Q4_TARGET_INVENTORY = DASHBOARD / "q4-target-inventory.tsv"
PHYLO_BALANCE_INVENTORY = DASHBOARD / "phylo-balance-inventory.tsv"
SCALE_PHYLO_DIAGNOSTICS = DASHBOARD / "scale-phylo-diagnostics.tsv"
PHYLO_PROFILE_LOGLIK_STATUS = DASHBOARD / "phylo-profile-loglik-status.tsv"
BOOTSTRAP_REFIT_ACCOUNTING = DASHBOARD / "bootstrap-refit-accounting.tsv"
PHYLO_Q2_Q4_TARGET_MAP = DASHBOARD / "phylo-q2-q4-target-map.tsv"
PHYLO_EXTRACTOR_STATUS = DASHBOARD / "phylo-extractor-status.tsv"
BRIDGE_PAYLOAD_SCHEMA = DASHBOARD / "bridge-payload-schema.tsv"
BRIDGE_PROVENANCE_FIELDS = DASHBOARD / "bridge-provenance-fields.tsv"
LOCONLY_BRIDGE_DRAFT = DASHBOARD / "loconly-bridge-draft.tsv"
BRIDGE_SERIALIZATION_STATUS = DASHBOARD / "bridge-serialization-status.tsv"
BRIDGE_RECONSTRUCTION_STATUS = DASHBOARD / "bridge-reconstruction-status.tsv"
JULIA_HOME_SMOKE = DASHBOARD / "julia-home-smoke.tsv"
BRIDGE_REJECTION_MESSAGES = DASHBOARD / "bridge-rejection-messages.tsv"
CAPABILITY_REGENERATION_STATUS = DASHBOARD / "capability-regeneration-status.tsv"
BRIDGE_PARITY_SMOKE_STATUS = DASHBOARD / "bridge-parity-smoke-status.tsv"
BINOMIAL_BRIDGE_MAP = DASHBOARD / "binomial-bridge-map.tsv"
BINOMIAL_PROFILE_STATUS = DASHBOARD / "binomial-profile-status.tsv"
AYUMI_BALANCE_SLICE_LEDGER = DASHBOARD / "ayumi-phylo-balance-100-slices.tsv"
AYUMI_BALANCE_VOCABULARY = DASHBOARD / "ayumi-phylo-balance-vocabulary.tsv"
AYUMI_BALANCE_TRACKERS = DASHBOARD / "ayumi-phylo-balance-trackers.tsv"
AYUMI_INFERENCE_COVERAGE = DASHBOARD / "ayumi-inference-coverage-ledger.tsv"
AYUMI_BOUNDARY_STATUS = DASHBOARD / "ayumi-boundary-status-ledger.tsv"
CLAIM_MATRIX_REF = "docs/design/168-r-julia-finish-capability-matrix.md"
PUBLIC_CLAIM_REFERENCE_FILES = (
    ROOT / "README.md",
    ROOT / "ROADMAP.md",
    ROOT / "NEWS.md",
    ROOT / "_pkgdown.yml",
    ROOT / "docs" / "dev-log" / "dashboard" / "README.md",
    ROOT / "docs" / "dev-log" / "known-limitations.md",
)
PUBLIC_CLAIM_SCAN_FILES = PUBLIC_CLAIM_REFERENCE_FILES + (
    ROOT / "docs" / "design" / "168-r-julia-finish-capability-matrix.md",
)
RELEASE_READY_PATTERN = re.compile(
    r"\b(release[- ]ready|ready (?:for|to) release|CRAN[- ]ready)\b",
    re.I,
)
RESERVED_PUBLIC_CONTROL_PATTERN = re.compile(r"\bengine_control\b")
COVERAGE_NOT_EVALUATED_PATTERN = re.compile(
    r"\bcoverage(?:_status)?\s*(?:=|is)?\s*not[_ -]evaluated\b",
    re.I,
)
AI_REML_READY_TRUE_PATTERN = re.compile(r"\bai_reml_ready\s*=\s*true\b", re.I)
PROMOTED_AI_REML_GATE_PATTERN = re.compile(
    r"\bpromoted[_ -]ai[_ -]reml[_ -]optimizer[_ -]gate\b",
    re.I,
)

SLICE_STATUSES = {"queued", "active", "blocked", "verified", "banked", "deferred"}
PHASE_STATUSES = SLICE_STATUSES
MATRIX_STATUSES = {"covered", "partial", "experimental", "planned", "unsupported"}
FINISH_STATUSES = SLICE_STATUSES | MATRIX_STATUSES | {"active", "blocked", "guard"}
FINISH_LANES = {
    "Critical Path",
    "Issue Ledger",
    "Twin Claim Board",
    "Cross-Package Lessons",
    "Evidence Gates",
    "Release Readiness",
}
FINISH_STATUS_FIELDS = (
    "status",
    "engine_tmb",
    "engine_julia",
    "point",
    "wald",
    "profile",
    "bootstrap",
    "tests",
    "docs",
    "visual",
    "simulation",
    "release_gate",
)
GATE_FIELDS = (
    "gate_id",
    "route",
    "guard",
    "family_type",
    "syntax",
    "r_bridge_status",
    "drmjl_status",
    "message_pattern",
    "review_due",
    "evidence_url",
    "action",
    "evidence",
    "issue",
)
CAPABILITY_FIELDS = (
    "capability_id",
    "route",
    "syntax",
    "r_bridge_status",
    "drmjl_status",
    "claim_status",
    "evidence_url",
    "claim_boundary",
    "next_action",
    "issue",
)
HUNDRED_SLICE_FIELDS = (
    "slice_id",
    "wave",
    "order",
    "area",
    "repo",
    "route",
    "primary_gate",
    "status",
    "bridge_status",
    "claim_boundary",
    "depends_on",
    "evidence_url",
    "next_action",
)
Q4_TARGET_FIELDS = (
    "target_id",
    "route",
    "engine",
    "estimator",
    "axes",
    "point_status",
    "wald_status",
    "profile_status",
    "bootstrap_status",
    "bridge_status",
    "claim_boundary",
    "evidence_url",
    "next_gate",
)
PHYLO_BALANCE_FIELDS = (
    "balance_id",
    "model_scope",
    "route",
    "engine",
    "estimator",
    "axes",
    "fit_status",
    "test_status",
    "inference_status",
    "bridge_status",
    "balance_class",
    "claim_boundary",
    "evidence_url",
    "next_gate",
)
SCALE_PHYLO_DIAGNOSTIC_FIELDS = (
    "diagnostic_id",
    "model_scope",
    "route",
    "condition",
    "expected_check",
    "expected_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
PHYLO_PROFILE_LOGLIK_FIELDS = (
    "status_id",
    "model_scope",
    "route",
    "engine",
    "estimator",
    "target",
    "loglik_status",
    "profile_status",
    "interval_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
BOOTSTRAP_REFIT_ACCOUNTING_FIELDS = (
    "accounting_id",
    "route",
    "engine",
    "estimator",
    "target_scope",
    "requested_refits",
    "successful_refits",
    "failed_refits",
    "failure_reason_status",
    "diagnostics_status",
    "interval_claim_status",
    "evidence_url",
    "next_gate",
)
PHYLO_Q2_Q4_TARGET_MAP_FIELDS = (
    "map_id",
    "model_scope",
    "route",
    "engine",
    "estimator",
    "dimension",
    "axes",
    "correlation_targets",
    "profile_target_status",
    "diagnostic_status",
    "bridge_status",
    "relation",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
PHYLO_EXTRACTOR_STATUS_FIELDS = (
    "extractor_id",
    "model_scope",
    "route",
    "engine",
    "estimator",
    "dimension",
    "extractor",
    "status_fields",
    "expected_status",
    "interval_source_status",
    "wald_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
BRIDGE_PAYLOAD_SCHEMA_FIELDS = (
    "schema_id",
    "route",
    "source_repo",
    "target",
    "estimator",
    "payload_fields",
    "required_evidence",
    "r_bridge_status",
    "drmjl_status",
    "claim_boundary",
    "evidence_url",
    "next_gate",
)
BRIDGE_PROVENANCE_FIELDS_FIELDS = (
    "provenance_id",
    "route",
    "applies_to",
    "field_group",
    "required_fields",
    "source_system",
    "verification_status",
    "r_bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
LOCONLY_BRIDGE_DRAFT_FIELDS = (
    "draft_id",
    "target",
    "estimator",
    "native_r_status",
    "direct_drmjl_status",
    "r_via_julia_status",
    "payload_schema_status",
    "provenance_status",
    "parity_status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
BRIDGE_SERIALIZATION_STATUS_FIELDS = (
    "serialization_id",
    "target",
    "format",
    "schema_fields",
    "roundtrip_status",
    "missing_field_status",
    "test_status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
BRIDGE_RECONSTRUCTION_STATUS_FIELDS = (
    "reconstruction_id",
    "target",
    "object_status",
    "payload_status",
    "coefficient_status",
    "vcov_status",
    "profile_target_status",
    "corpairs_status",
    "bridge_status",
    "test_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
JULIA_HOME_SMOKE_FIELDS = (
    "smoke_id",
    "helper",
    "environment_case",
    "expected_behavior",
    "observed_status",
    "test_status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
BRIDGE_REJECTION_MESSAGE_FIELDS = (
    "message_id",
    "gate_id",
    "route",
    "guard",
    "message_pattern",
    "guidance_status",
    "pre_juliacall_status",
    "test_status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
CAPABILITY_REGENERATION_STATUS_FIELDS = (
    "artifact_id",
    "source_function",
    "writer_script",
    "dashboard_output",
    "extdata_output",
    "registry_rows",
    "artifact_rows",
    "test_status",
    "regeneration_status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
BRIDGE_PARITY_SMOKE_STATUS_FIELDS = (
    "smoke_id",
    "route",
    "model_cell",
    "native_tmb_status",
    "r_via_julia_status",
    "direct_drmjl_status",
    "parity_target",
    "parity_status",
    "tolerance_status",
    "test_status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
BINOMIAL_BRIDGE_MAP_FIELDS = (
    "map_id",
    "route",
    "family_scope",
    "response_encoding",
    "model_structure",
    "native_tmb_status",
    "r_bridge_status",
    "drmjl_status",
    "parity_status",
    "inference_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
BINOMIAL_PROFILE_STATUS_FIELDS = (
    "status_id",
    "family_scope",
    "response_encoding",
    "target_scope",
    "profile_target_status",
    "default_profile_status",
    "explicit_profile_status",
    "interval_claim_status",
    "test_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
AYUMI_BALANCE_SLICE_FIELDS = (
    "slice_id",
    "wave",
    "order",
    "area",
    "repo",
    "route",
    "primary_gate",
    "status",
    "bridge_status",
    "claim_boundary",
    "depends_on",
    "evidence_url",
    "next_action",
)
AYUMI_BALANCE_VOCABULARY_FIELDS = (
    "term_id",
    "term",
    "applies_to",
    "definition",
    "allowed_status",
    "forbidden_wording",
    "evidence_url",
    "next_gate",
)
AYUMI_BALANCE_TRACKER_FIELDS = (
    "tracker_id",
    "source",
    "issue_url",
    "issue_status",
    "scope",
    "current_evidence",
    "blocker_status",
    "bridge_status",
    "claim_boundary",
    "next_gate",
)
AYUMI_INFERENCE_COVERAGE_FIELDS = (
    "coverage_id",
    "model_cell",
    "route",
    "engine",
    "estimator",
    "target_scope",
    "wald_status",
    "profile_status",
    "bootstrap_status",
    "coverage_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
AYUMI_BOUNDARY_STATUS_FIELDS = (
    "boundary_id",
    "model_cell",
    "route",
    "engine",
    "estimator",
    "target",
    "boundary_signal",
    "fit_status",
    "interval_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
HUNDRED_SLICE_WAVES = (
    "Truth freeze",
    "DRM exact Gaussian",
    "Native R Gaussian phylo",
    "R-Julia bridge",
    "Native non-Gaussian",
    "Correlations slopes",
    "Structural dependencies",
    "Missing values",
    "Validation benchmarks",
    "Public finish",
)
AYUMI_BALANCE_WAVES = (
    "Rehydrate",
    "Semantics",
    "Native ML",
    "Native REML",
    "Julia Bridge",
    "Bivariate q4",
    "Ayumi Data",
    "Inference",
    "Literature Docs",
    "Reply Prep",
)
R_BRIDGE_STATUSES = {"supported", "experimental", "intentional_error", "planned", "unsupported"}
CAPABILITY_CLAIM_STATUSES = MATRIX_STATUSES | {"blocked"}
Q4_TARGET_STATUSES = MATRIX_STATUSES | {"blocked"}
Q4_ENGINES = {"tmb", "julia"}
Q4_ESTIMATORS = {"ML", "REML", "ML_or_REML"}
PHYLO_BALANCE_STATUSES = MATRIX_STATUSES | {"blocked"}
PHYLO_BALANCE_SCOPES = {"univariate_gaussian", "bivariate_gaussian"}
PHYLO_BALANCE_ROUTES = {"native_tmb", "r_to_julia"}
PHYLO_BALANCE_CLASSES = {
    "asymmetric_supported",
    "balanced_supported",
    "reml_mean_only_supported",
    "intentional_reml_asymmetry",
    "bridge_experimental",
    "balanced_q4_ml_diagnostic",
}
SCALE_PHYLO_EXPECTED_STATUSES = {"ok", "note", "warning", "null"}
PHYLO_LOGLIK_STATUSES = {"finite", "partial", "unsupported"}
PHYLO_PROFILE_STATUSES = {
    "direct_ready",
    "derived_not_ready",
    "partial",
    "unsupported",
}
PHYLO_INTERVAL_STATUSES = {
    "not_evaluated",
    "derived_interval_unavailable",
    "unsupported",
}
BOOTSTRAP_REFIT_FAILURE_STATUSES = {
    "none_observed",
    "diagnostic_attribute",
    "refit_failure_messages_recorded",
}
BOOTSTRAP_REFIT_DIAGNOSTIC_STATUSES = {"covered", "experimental"}
BOOTSTRAP_INTERVAL_CLAIM_STATUSES = {
    "not_calibrated_coverage",
    "plumbing_only",
    "unavailable",
}
PHYLO_Q2_Q4_DIMENSIONS = {"q2", "q4", "q2_plus_q2"}
PHYLO_Q2_Q4_RELATIONS = {
    "baseline_q2",
    "q2_covariate_correlation",
    "q2_reml_unimplemented",
    "full_q4",
    "block_diagonal_q4",
    "native_reml_rejected",
    "bridge_experimental",
}
PHYLO_EXTRACTOR_EXPECTED_STATUSES = {
    "not_requested",
    "newdata_required",
    "derived_interval_unavailable",
    "profile_ready_false;derived_unstructured_correlation",
}
PHYLO_EXTRACTOR_INTERVAL_SOURCE_STATUSES = {
    "not_available",
    "not_applicable",
    "not_reported_by_summary_covariance",
}
PHYLO_EXTRACTOR_WALD_STATUSES = {"no_wald_interval"}
BRIDGE_SCHEMA_ROUTES = {
    "base",
    "loconly_reml",
    "univariate_phylo",
    "bivariate_phylo",
    "phylo_count",
    "structured",
    "cross_family",
    "intentional_guards",
}
BRIDGE_SCHEMA_SOURCE_REPOS = {"drmTMB", "DRM.jl", "drmTMB+DRM.jl"}
BRIDGE_SCHEMA_ESTIMATORS = Q4_ESTIMATORS | {
    "supplied_variance_reml",
    "none",
}
BRIDGE_PROVENANCE_ROUTES = BRIDGE_SCHEMA_ROUTES | {"all_bridge", "structured_and_phylo"}
BRIDGE_PROVENANCE_SOURCE_SYSTEMS = {"R", "Julia", "R_and_Julia"}
BRIDGE_PROVENANCE_STATUSES = {"required", "partial", "planned", "guard"}
LOCONLY_BRIDGE_DRAFT_STATUSES = MATRIX_STATUSES | {"covered"}
BRIDGE_SERIALIZATION_FORMATS = {"TSV", "JSON"}
BRIDGE_SERIALIZATION_STATUSES = MATRIX_STATUSES | {"covered"}
BRIDGE_RECONSTRUCTION_STATUSES = MATRIX_STATUSES | {
    "covered",
    "missing_reported",
    "present",
    "absent",
    "partial",
    "ok",
    "diagnostic_only",
}
JULIA_HOME_SMOKE_HELPERS = {
    "drm_test_julia_home",
    "drm_test_set_julia_home",
    "drm_test_local_julia_home",
}
JULIA_HOME_SMOKE_STATUSES = MATRIX_STATUSES | {"covered"}
BRIDGE_REJECTION_MESSAGE_STATUSES = MATRIX_STATUSES | {"covered"}
CAPABILITY_REGENERATION_STATUSES = MATRIX_STATUSES | {"covered"}
BRIDGE_PARITY_SMOKE_STATUSES = MATRIX_STATUSES | {
    "covered",
    "blocked",
    "skipped",
    "not_required",
}
BINOMIAL_BRIDGE_ROUTES = {"native_tmb", "r_to_julia", "direct_drmjl"}
BINOMIAL_BRIDGE_STATUSES = MATRIX_STATUSES | {
    "covered",
    "not_applicable",
    "intentional_error",
}
BINOMIAL_PARITY_STATUSES = {
    "glm_parity",
    "intentional_error",
    "finite_sane_no_native_twin",
    "not_applicable",
    "planned",
}
BINOMIAL_INFERENCE_STATUSES = {
    "wald_fixed_effect",
    "unsupported",
    "point_only",
    "not_applicable",
    "planned",
}
BINOMIAL_PROFILE_TARGET_STATUSES = {"direct_ready", "planned", "unsupported"}
BINOMIAL_DEFAULT_PROFILE_STATUSES = {"explicit_parm_required", "not_evaluated"}
BINOMIAL_EXPLICIT_PROFILE_STATUSES = {
    "not_evaluated",
    "profile_failed_nonfinite_interval",
    "covered",
}
BINOMIAL_INTERVAL_CLAIM_STATUSES = {"not_promoted", "planned", "unsupported"}
AYUMI_TRACKER_SOURCES = {"external", "internal", "internal_tracker"}
AYUMI_TRACKER_ISSUE_STATUSES = {
    "open",
    "closed",
    "inaccessible",
    "unverified_from_here",
}
AYUMI_TRACKER_BLOCKER_STATUSES = {"open", "closed", "partial", "blocked"}
AYUMI_BALANCE_ALLOWED_TERM_STATUSES = (
    MATRIX_STATUSES
    | SLICE_STATUSES
    | R_BRIDGE_STATUSES
    | {"covered", "partial"}
)
AYUMI_INFERENCE_ROUTES = {"native_tmb", "r_to_julia", "direct_drmjl"}
AYUMI_WALD_STATUSES = {
    "available_when_pdHess_true",
    "unsafe_pdHess_false",
    "no_wald_interval",
    "unsupported",
    "not_evaluated",
}
AYUMI_PROFILE_STATUSES = {
    "direct_ready",
    "derived_unavailable",
    "profile_failed",
    "timeout_status",
    "direct_julia_available",
    "unsupported",
    "not_evaluated",
}
AYUMI_BOOTSTRAP_STATUSES = {
    "plumbing_only",
    "not_calibrated_coverage",
    "unavailable",
    "direct_julia_available",
    "unsupported",
    "not_evaluated",
}
AYUMI_COVERAGE_STATUSES = {
    "not_evaluated",
    "undercoverage_known",
    "not_claimed",
    "unsupported",
}
AYUMI_BOUNDARY_SIGNALS = {
    "none_observed",
    "pdHess_false",
    "rho12_near_boundary",
    "q4_covariance_warning",
    "logsigma_clamp_warning",
    "collapsed_axis",
    "unknown",
}
AYUMI_BOUNDARY_FIT_STATUSES = {
    "ok",
    "diagnostic",
    "nonconverged",
    "experimental",
    "unsupported",
}
AYUMI_BOUNDARY_INTERVAL_STATUSES = {
    "not_evaluated",
    "unsafe",
    "profile_failed",
    "unavailable",
    "direct_julia_only",
    "not_claimed",
}
EVIDENCE_STATUSES = {"verified", "banked", "covered"}
STANDING_REVIEW_NAMES = {
    "Ada",
    "Boole",
    "Gauss",
    "Noether",
    "Darwin",
    "Florence",
    "Fisher",
    "Pat",
    "Jason",
    "Curie",
    "Emmy",
    "Grace",
    "Rose",
}
SYSTEM_ACTORS = {
    "Codex",
    "GitHub",
    "Ayumi",
    "Dashboard",
    "Issue ledger",
    "Status matrix",
}
CANONICAL_ACTORS = STANDING_REVIEW_NAMES | SYSTEM_ACTORS


def owner_names(owner: str | None) -> list[str]:
    if not owner:
        return []
    normalized = owner.replace(",", "+")
    return [part.strip() for part in normalized.split("+") if part.strip()]


def read_json(path: pathlib.Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def read_tsv(path: pathlib.Path) -> list[dict[str, str]]:
    import csv

    with path.open("r", encoding="utf-8", newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t", quoting=csv.QUOTE_NONE))


def rel_path(path: pathlib.Path) -> str:
    return path.relative_to(ROOT).as_posix()


def text_line_number(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def local_documenter_claim_paths() -> list[pathlib.Path]:
    """Return local Documenter.jl claim files if this repo ever grows them."""

    paths: list[pathlib.Path] = []
    docs_src = ROOT / "docs" / "src"
    if docs_src.exists():
        paths.extend(path for path in docs_src.rglob("*") if path.is_file())
    for name in ("make.jl", "Documenter.toml", "Project.toml"):
        path = ROOT / "docs" / name
        if path.exists():
            paths.append(path)
    return sorted(set(paths))


def public_claim_scan_paths() -> list[pathlib.Path]:
    paths = list(PUBLIC_CLAIM_SCAN_FILES)
    paths.extend(sorted((ROOT / "vignettes").glob("*.Rmd")))
    paths.extend(local_documenter_claim_paths())
    return [path for path in sorted(set(paths)) if path.exists()]


def matrix_row_count_from_design(path: pathlib.Path) -> int:
    text = path.read_text(encoding="utf-8")
    match = re.search(r"## Finish Matrix\n(?P<table>.*?)\n## Issue-Led", text, re.S)
    if not match:
        return -1
    rows = []
    for line in match.group("table").splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        if set(line.replace("|", "").replace(" ", "")) == {"-"}:
            continue
        if line.startswith("| Area "):
            continue
        rows.append(line)
    return len(rows)


def evidence_reference_exists(reference: str) -> bool:
    if reference in {"", "planned", "none"}:
        return False
    if re.match(r"^https://github\.com/[^/]+/[^/]+/(issues|pull)/[0-9]+", reference):
        return True
    path = pathlib.Path(reference)
    if path.is_absolute():
        return path.exists()
    return (ROOT / reference).exists()


def main() -> int:
    errors: list[str] = []
    status = read_json(DASHBOARD / "status.json")
    read_json(DASHBOARD / "sweep.json")
    gate_rows = read_tsv(GATE_REGISTRY)
    capability_rows = read_tsv(CAPABILITY_REGISTRY)
    hundred_slice_rows = read_tsv(HUNDRED_SLICE_LEDGER)
    q4_target_rows = read_tsv(Q4_TARGET_INVENTORY)
    phylo_balance_rows = read_tsv(PHYLO_BALANCE_INVENTORY)
    scale_phylo_diagnostic_rows = read_tsv(SCALE_PHYLO_DIAGNOSTICS)
    phylo_profile_loglik_rows = read_tsv(PHYLO_PROFILE_LOGLIK_STATUS)
    bootstrap_refit_accounting_rows = read_tsv(BOOTSTRAP_REFIT_ACCOUNTING)
    phylo_q2_q4_target_map_rows = read_tsv(PHYLO_Q2_Q4_TARGET_MAP)
    phylo_extractor_status_rows = read_tsv(PHYLO_EXTRACTOR_STATUS)
    bridge_payload_schema_rows = read_tsv(BRIDGE_PAYLOAD_SCHEMA)
    bridge_provenance_fields_rows = read_tsv(BRIDGE_PROVENANCE_FIELDS)
    loconly_bridge_draft_rows = read_tsv(LOCONLY_BRIDGE_DRAFT)
    bridge_serialization_status_rows = read_tsv(BRIDGE_SERIALIZATION_STATUS)
    bridge_reconstruction_status_rows = read_tsv(BRIDGE_RECONSTRUCTION_STATUS)
    julia_home_smoke_rows = read_tsv(JULIA_HOME_SMOKE)
    bridge_rejection_message_rows = read_tsv(BRIDGE_REJECTION_MESSAGES)
    capability_regeneration_status_rows = read_tsv(CAPABILITY_REGENERATION_STATUS)
    bridge_parity_smoke_status_rows = read_tsv(BRIDGE_PARITY_SMOKE_STATUS)
    binomial_bridge_map_rows = read_tsv(BINOMIAL_BRIDGE_MAP)
    binomial_profile_status_rows = read_tsv(BINOMIAL_PROFILE_STATUS)
    ayumi_balance_slice_rows = read_tsv(AYUMI_BALANCE_SLICE_LEDGER)
    ayumi_balance_vocabulary_rows = read_tsv(AYUMI_BALANCE_VOCABULARY)
    ayumi_balance_tracker_rows = read_tsv(AYUMI_BALANCE_TRACKERS)
    ayumi_inference_coverage_rows = read_tsv(AYUMI_INFERENCE_COVERAGE)
    ayumi_boundary_status_rows = read_tsv(AYUMI_BOUNDARY_STATUS)
    documenter_paths = local_documenter_claim_paths()

    version = (DASHBOARD / "version.txt").read_text(encoding="utf-8").strip()
    index = (DASHBOARD / "index.html").read_text(encoding="utf-8")
    build = re.search(r'const BUILD = "([^"]+)"', index)
    if not build:
        errors.append("index.html has no BUILD constant")
    elif build.group(1) != version:
        errors.append(f"version.txt is {version!r}, but index.html BUILD is {build.group(1)!r}")

    slice_counts = {key: 0 for key in ("verified", "active", "blocked", "deferred")}
    total_slices = 0
    for phase in status.get("phases", []):
        phase_status = phase.get("status")
        if phase_status not in PHASE_STATUSES:
            errors.append(f"{phase.get('id', '<phase>')} has invalid status {phase_status!r}")
        for owner in owner_names(phase.get("owner")):
            if owner not in STANDING_REVIEW_NAMES:
                errors.append(f"{phase.get('id', '<phase>')} has non-standing owner {owner!r}")
        slices = phase.get("slices", [])
        total_slices += len(slices)
        done = 0
        for item in slices:
            item_status = item.get("status")
            if item_status not in SLICE_STATUSES:
                errors.append(f"{phase.get('id', '<phase>')} slice {item.get('name')!r} has invalid status {item_status!r}")
            if item_status in {"verified", "banked"}:
                done += 1
                slice_counts["verified"] += 1
                if not any(item.get(key) for key in ("evidence", "issue", "url")):
                    errors.append(f"verified/banked slice lacks evidence: {item.get('name')!r}")
            elif item_status in slice_counts:
                slice_counts[item_status] += 1
        expected_counts = f"{done}/{len(slices)}"
        if phase.get("counts") != expected_counts:
            errors.append(
                f"{phase.get('id', '<phase>')} counts are {phase.get('counts')!r}; expected {expected_counts!r}"
            )

    metrics = status.get("metrics", {})
    expected_metrics = {
        "verified": slice_counts["verified"],
        "active": slice_counts["active"],
        "blocked": slice_counts["blocked"],
        "deferred": slice_counts["deferred"],
        "total": total_slices,
    }
    for key, expected in expected_metrics.items():
        if metrics.get(key) != expected:
            errors.append(f"metrics.{key} is {metrics.get(key)!r}; expected {expected!r}")

    for agent in status.get("agents", []):
        name = agent.get("name")
        if name not in STANDING_REVIEW_NAMES:
            errors.append(f"non-standing review name in team list: {name!r}")
    agent_names = {agent.get("name") for agent in status.get("agents", [])}
    missing_standing = sorted(STANDING_REVIEW_NAMES - agent_names)
    if missing_standing:
        errors.append(f"team list missing standing review names: {', '.join(missing_standing)}")
    extra_team = sorted(agent_names - STANDING_REVIEW_NAMES)
    if extra_team:
        errors.append(f"team list has non-standing names: {', '.join(extra_team)}")

    for section in ("active_work", "activity", "blockers", "evidence"):
        for item in status.get(section, []):
            who = item.get("who") or item.get("kind")
            if who and who not in CANONICAL_ACTORS and section != "blockers":
                errors.append(f"non-canonical name in {section}: {who!r}")

    matrix = status.get("matrix", [])
    design_count = matrix_row_count_from_design(DESIGN_MATRIX)
    if design_count >= 0 and len(matrix) != design_count:
        errors.append(f"dashboard matrix has {len(matrix)} rows; design matrix has {design_count}")
    matrix_fields = (
        "engine",
        "bridge",
        "point",
        "wald",
        "profile",
        "bootstrap",
        "docs",
        "visual",
        "simulation",
        "release",
    )
    for row in matrix:
        row_name = row.get("area", "<matrix row>")
        row_text = " ".join(
            str(row.get(key, ""))
            for key in ("area", "next", "evidence", "evidence_url")
        )
        has_covered = False
        for field in matrix_fields:
            value = row.get(field)
            if value not in MATRIX_STATUSES:
                errors.append(f"{row_name}: {field} has invalid status {value!r}")
            has_covered = has_covered or value == "covered"
        if has_covered and not (row.get("evidence") or row.get("evidence_url")):
            errors.append(f"{row_name}: covered row lacks evidence")
        if row.get("simulation") == "covered" and COVERAGE_NOT_EVALUATED_PATTERN.search(row_text):
            errors.append(f"{row_name}: simulation is covered while coverage is not evaluated")
        if (
            AI_REML_READY_TRUE_PATTERN.search(row_text)
            and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text)
        ):
            errors.append(f"{row_name}: ai_reml_ready=true without a promoted optimizer gate")

    finish_board = status.get("finish_board", [])
    lanes_seen: set[str] = set()
    row_ids: set[str] = set()
    for row in finish_board:
        row_id = row.get("id", "<finish row>")
        if not row.get("id"):
            errors.append("finish_board row lacks id")
        elif row_id in row_ids:
            errors.append(f"duplicate finish_board id: {row_id}")
        row_ids.add(row_id)
        lane = row.get("lane")
        if lane not in FINISH_LANES:
            errors.append(f"{row_id}: invalid finish-board lane {lane!r}")
        else:
            lanes_seen.add(lane)
        issue = row.get("issue")
        if issue and not re.match(r"^https://github\.com/[^/]+/[^/]+/(issues|pull)/[0-9]+", issue):
            errors.append(f"{row_id}: issue is not a GitHub issue/PR URL: {issue!r}")
        owners = row.get("owners", [])
        if not owners:
            errors.append(f"{row_id}: finish-board row has no owners")
        for owner in owners:
            if owner not in STANDING_REVIEW_NAMES:
                errors.append(f"{row_id}: non-standing owner {owner!r}")
        has_evidence_status = False
        for field in FINISH_STATUS_FIELDS:
            value = row.get(field)
            if value not in FINISH_STATUSES:
                errors.append(f"{row_id}: {field} has invalid status {value!r}")
            has_evidence_status = has_evidence_status or value in EVIDENCE_STATUSES
        if has_evidence_status and not (row.get("evidence_url") or row.get("evidence")):
            errors.append(f"{row_id}: verified/banked/covered finish row lacks evidence")
        if not row.get("last_verified"):
            errors.append(f"{row_id}: finish-board row lacks last_verified")
    missing_lanes = sorted(FINISH_LANES - lanes_seen)
    if missing_lanes:
        errors.append(f"finish_board missing lanes: {', '.join(missing_lanes)}")

    gate_ids: set[str] = set()
    if not gate_rows:
        errors.append("julia-gates.tsv has no gate rows")
    for row in gate_rows:
        row_id = row.get("gate_id", "<gate row>")
        if set(row.keys()) != set(GATE_FIELDS):
            errors.append(f"{row_id}: julia-gates.tsv fields do not match the registry contract")
        if not row.get("gate_id"):
            errors.append("julia-gates.tsv row lacks gate_id")
        elif row_id in gate_ids:
            errors.append(f"duplicate Julia gate id: {row_id}")
        gate_ids.add(row_id)
        for field in GATE_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("r_bridge_status") != "intentional_error":
            errors.append(f"{row_id}: r_bridge_status is not intentional_error")
        if row.get("action") != "error":
            errors.append(f"{row_id}: action is not error")
        if row.get("issue") != "drmTMB#544":
            errors.append(f"{row_id}: issue is not drmTMB#544")
        if not re.match(r"^https://github\.com/[^/]+/[^/]+/issues/[0-9]+", row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url is not a GitHub issue URL")

    capability_ids: set[str] = set()
    if not capability_rows:
        errors.append("julia-capabilities.tsv has no capability rows")
    for row in capability_rows:
        row_id = row.get("capability_id", "<capability row>")
        if set(row.keys()) != set(CAPABILITY_FIELDS):
            errors.append(f"{row_id}: julia-capabilities.tsv fields do not match the comparison contract")
        if not row.get("capability_id"):
            errors.append("julia-capabilities.tsv row lacks capability_id")
        elif row_id in capability_ids:
            errors.append(f"duplicate Julia capability id: {row_id}")
        capability_ids.add(row_id)
        for field in CAPABILITY_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("r_bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid r_bridge_status {row.get('r_bridge_status')!r}")
        if row.get("claim_status") not in CAPABILITY_CLAIM_STATUSES:
            errors.append(f"{row_id}: invalid claim_status {row.get('claim_status')!r}")
        if not re.match(r"^https://github\.com/[^/]+/[^/]+/issues/[0-9]+", row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url is not a GitHub issue URL")
        if not re.match(r"^[A-Za-z0-9]+#[0-9]+$", row.get("issue", "")):
            errors.append(f"{row_id}: issue is not a compact issue label")

    q4_target_ids: set[str] = set()
    if not q4_target_rows:
        errors.append("q4-target-inventory.tsv has no target rows")
    for row in q4_target_rows:
        row_id = row.get("target_id", "<q4 target row>")
        if set(row.keys()) != set(Q4_TARGET_FIELDS):
            errors.append(f"{row_id}: q4-target-inventory.tsv fields do not match the inventory contract")
        if not row.get("target_id"):
            errors.append("q4-target-inventory.tsv row lacks target_id")
        elif row_id in q4_target_ids:
            errors.append(f"duplicate q4 target id: {row_id}")
        q4_target_ids.add(row_id)
        for field in Q4_TARGET_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("engine") not in Q4_ENGINES:
            errors.append(f"{row_id}: invalid engine {row.get('engine')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        for field in ("point_status", "wald_status", "profile_status", "bootstrap_status"):
            if row.get(field) not in Q4_TARGET_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in Q4_TARGET_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    phylo_balance_ids: set[str] = set()
    if not phylo_balance_rows:
        errors.append("phylo-balance-inventory.tsv has no balance rows")
    for row in phylo_balance_rows:
        row_id = row.get("balance_id", "<phylo balance row>")
        if set(row.keys()) != set(PHYLO_BALANCE_FIELDS):
            errors.append(f"{row_id}: phylo-balance-inventory.tsv fields do not match the balance contract")
        if not row.get("balance_id"):
            errors.append("phylo-balance-inventory.tsv row lacks balance_id")
        elif row_id in phylo_balance_ids:
            errors.append(f"duplicate phylo balance id: {row_id}")
        phylo_balance_ids.add(row_id)
        for field in PHYLO_BALANCE_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("model_scope") not in PHYLO_BALANCE_SCOPES:
            errors.append(f"{row_id}: invalid model_scope {row.get('model_scope')!r}")
        if row.get("route") not in PHYLO_BALANCE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        if row.get("engine") not in Q4_ENGINES:
            errors.append(f"{row_id}: invalid engine {row.get('engine')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        for field in ("fit_status", "test_status", "inference_status"):
            if row.get(field) not in PHYLO_BALANCE_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("balance_class") not in PHYLO_BALANCE_CLASSES:
            errors.append(f"{row_id}: invalid balance_class {row.get('balance_class')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in PHYLO_BALANCE_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    scale_phylo_diagnostic_ids: set[str] = set()
    if not scale_phylo_diagnostic_rows:
        errors.append("scale-phylo-diagnostics.tsv has no diagnostic rows")
    for row in scale_phylo_diagnostic_rows:
        row_id = row.get("diagnostic_id", "<scale phylo diagnostic row>")
        if set(row.keys()) != set(SCALE_PHYLO_DIAGNOSTIC_FIELDS):
            errors.append(f"{row_id}: scale-phylo-diagnostics.tsv fields do not match the diagnostic contract")
        if not row.get("diagnostic_id"):
            errors.append("scale-phylo-diagnostics.tsv row lacks diagnostic_id")
        elif row_id in scale_phylo_diagnostic_ids:
            errors.append(f"duplicate scale phylo diagnostic id: {row_id}")
        scale_phylo_diagnostic_ids.add(row_id)
        for field in SCALE_PHYLO_DIAGNOSTIC_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("model_scope") not in PHYLO_BALANCE_SCOPES:
            errors.append(f"{row_id}: invalid model_scope {row.get('model_scope')!r}")
        if row.get("route") not in PHYLO_BALANCE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        statuses = row.get("expected_status", "").split(";")
        invalid_statuses = [
            status for status in statuses
            if status not in SCALE_PHYLO_EXPECTED_STATUSES
        ]
        if invalid_statuses:
            errors.append(f"{row_id}: invalid expected_status values {invalid_statuses!r}")
        row_text = " ".join(str(row.get(field, "")) for field in SCALE_PHYLO_DIAGNOSTIC_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    phylo_profile_loglik_ids: set[str] = set()
    if not phylo_profile_loglik_rows:
        errors.append("phylo-profile-loglik-status.tsv has no status rows")
    for row in phylo_profile_loglik_rows:
        row_id = row.get("status_id", "<phylo profile/logLik row>")
        if set(row.keys()) != set(PHYLO_PROFILE_LOGLIK_FIELDS):
            errors.append(f"{row_id}: phylo-profile-loglik-status.tsv fields do not match the status contract")
        if not row.get("status_id"):
            errors.append("phylo-profile-loglik-status.tsv row lacks status_id")
        elif row_id in phylo_profile_loglik_ids:
            errors.append(f"duplicate phylo profile/logLik id: {row_id}")
        phylo_profile_loglik_ids.add(row_id)
        for field in PHYLO_PROFILE_LOGLIK_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("model_scope") not in PHYLO_BALANCE_SCOPES:
            errors.append(f"{row_id}: invalid model_scope {row.get('model_scope')!r}")
        if row.get("route") not in PHYLO_BALANCE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        if row.get("engine") not in Q4_ENGINES:
            errors.append(f"{row_id}: invalid engine {row.get('engine')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("loglik_status") not in PHYLO_LOGLIK_STATUSES:
            errors.append(f"{row_id}: invalid loglik_status {row.get('loglik_status')!r}")
        if row.get("profile_status") not in PHYLO_PROFILE_STATUSES:
            errors.append(f"{row_id}: invalid profile_status {row.get('profile_status')!r}")
        if row.get("interval_status") not in PHYLO_INTERVAL_STATUSES:
            errors.append(f"{row_id}: invalid interval_status {row.get('interval_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in PHYLO_PROFILE_LOGLIK_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    bootstrap_refit_accounting_ids: set[str] = set()
    if not bootstrap_refit_accounting_rows:
        errors.append("bootstrap-refit-accounting.tsv has no accounting rows")
    for row in bootstrap_refit_accounting_rows:
        row_id = row.get("accounting_id", "<bootstrap refit accounting row>")
        if set(row.keys()) != set(BOOTSTRAP_REFIT_ACCOUNTING_FIELDS):
            errors.append(f"{row_id}: bootstrap-refit-accounting.tsv fields do not match the accounting contract")
        if not row.get("accounting_id"):
            errors.append("bootstrap-refit-accounting.tsv row lacks accounting_id")
        elif row_id in bootstrap_refit_accounting_ids:
            errors.append(f"duplicate bootstrap refit accounting id: {row_id}")
        bootstrap_refit_accounting_ids.add(row_id)
        for field in BOOTSTRAP_REFIT_ACCOUNTING_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("route") not in PHYLO_BALANCE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        if row.get("engine") not in Q4_ENGINES:
            errors.append(f"{row_id}: invalid engine {row.get('engine')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        for field in ("requested_refits", "successful_refits", "failed_refits"):
            value = row.get(field, "")
            if value not in {"varies"}:
                try:
                    if int(value) < 0:
                        errors.append(f"{row_id}: {field} is negative")
                except ValueError:
                    errors.append(f"{row_id}: {field} must be non-negative integer or varies")
        if row.get("failure_reason_status") not in BOOTSTRAP_REFIT_FAILURE_STATUSES:
            errors.append(f"{row_id}: invalid failure_reason_status {row.get('failure_reason_status')!r}")
        if row.get("diagnostics_status") not in BOOTSTRAP_REFIT_DIAGNOSTIC_STATUSES:
            errors.append(f"{row_id}: invalid diagnostics_status {row.get('diagnostics_status')!r}")
        if row.get("interval_claim_status") not in BOOTSTRAP_INTERVAL_CLAIM_STATUSES:
            errors.append(f"{row_id}: invalid interval_claim_status {row.get('interval_claim_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in BOOTSTRAP_REFIT_ACCOUNTING_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    phylo_q2_q4_target_map_ids: set[str] = set()
    if not phylo_q2_q4_target_map_rows:
        errors.append("phylo-q2-q4-target-map.tsv has no map rows")
    for row in phylo_q2_q4_target_map_rows:
        row_id = row.get("map_id", "<phylo q2/q4 map row>")
        if set(row.keys()) != set(PHYLO_Q2_Q4_TARGET_MAP_FIELDS):
            errors.append(f"{row_id}: phylo-q2-q4-target-map.tsv fields do not match the map contract")
        if not row.get("map_id"):
            errors.append("phylo-q2-q4-target-map.tsv row lacks map_id")
        elif row_id in phylo_q2_q4_target_map_ids:
            errors.append(f"duplicate phylo q2/q4 target-map id: {row_id}")
        phylo_q2_q4_target_map_ids.add(row_id)
        for field in PHYLO_Q2_Q4_TARGET_MAP_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("model_scope") not in PHYLO_BALANCE_SCOPES:
            errors.append(f"{row_id}: invalid model_scope {row.get('model_scope')!r}")
        if row.get("route") not in PHYLO_BALANCE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        if row.get("engine") not in Q4_ENGINES:
            errors.append(f"{row_id}: invalid engine {row.get('engine')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("dimension") not in PHYLO_Q2_Q4_DIMENSIONS:
            errors.append(f"{row_id}: invalid dimension {row.get('dimension')!r}")
        try:
            if int(row.get("correlation_targets", "")) < 0:
                errors.append(f"{row_id}: correlation_targets is negative")
        except ValueError:
            errors.append(f"{row_id}: correlation_targets must be a non-negative integer")
        if row.get("profile_target_status") not in PHYLO_PROFILE_STATUSES:
            errors.append(f"{row_id}: invalid profile_target_status {row.get('profile_target_status')!r}")
        if row.get("diagnostic_status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid diagnostic_status {row.get('diagnostic_status')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("relation") not in PHYLO_Q2_Q4_RELATIONS:
            errors.append(f"{row_id}: invalid relation {row.get('relation')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in PHYLO_Q2_Q4_TARGET_MAP_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")
    if "q2" not in {row.get("dimension") for row in phylo_q2_q4_target_map_rows}:
        errors.append("phylo-q2-q4-target-map.tsv lacks q2 rows")
    if "q4" not in {row.get("dimension") for row in phylo_q2_q4_target_map_rows}:
        errors.append("phylo-q2-q4-target-map.tsv lacks q4 rows")
    if "q2_plus_q2" not in {row.get("dimension") for row in phylo_q2_q4_target_map_rows}:
        errors.append("phylo-q2-q4-target-map.tsv lacks q2_plus_q2 rows")

    phylo_extractor_status_ids: set[str] = set()
    if not phylo_extractor_status_rows:
        errors.append("phylo-extractor-status.tsv has no extractor rows")
    for row in phylo_extractor_status_rows:
        row_id = row.get("extractor_id", "<phylo extractor-status row>")
        if set(row.keys()) != set(PHYLO_EXTRACTOR_STATUS_FIELDS):
            errors.append(f"{row_id}: phylo-extractor-status.tsv fields do not match the extractor contract")
        if not row.get("extractor_id"):
            errors.append("phylo-extractor-status.tsv row lacks extractor_id")
        elif row_id in phylo_extractor_status_ids:
            errors.append(f"duplicate phylo extractor-status id: {row_id}")
        phylo_extractor_status_ids.add(row_id)
        for field in PHYLO_EXTRACTOR_STATUS_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("model_scope") not in PHYLO_BALANCE_SCOPES:
            errors.append(f"{row_id}: invalid model_scope {row.get('model_scope')!r}")
        if row.get("route") not in PHYLO_BALANCE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        if row.get("engine") not in Q4_ENGINES:
            errors.append(f"{row_id}: invalid engine {row.get('engine')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("dimension") not in PHYLO_Q2_Q4_DIMENSIONS:
            errors.append(f"{row_id}: invalid dimension {row.get('dimension')!r}")
        if row.get("expected_status") not in PHYLO_EXTRACTOR_EXPECTED_STATUSES:
            errors.append(f"{row_id}: invalid expected_status {row.get('expected_status')!r}")
        if row.get("interval_source_status") not in PHYLO_EXTRACTOR_INTERVAL_SOURCE_STATUSES:
            errors.append(f"{row_id}: invalid interval_source_status {row.get('interval_source_status')!r}")
        if row.get("wald_status") not in PHYLO_EXTRACTOR_WALD_STATUSES:
            errors.append(f"{row_id}: invalid wald_status {row.get('wald_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in PHYLO_EXTRACTOR_STATUS_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    bridge_payload_schema_ids: set[str] = set()
    if not bridge_payload_schema_rows:
        errors.append("bridge-payload-schema.tsv has no schema rows")
    for row in bridge_payload_schema_rows:
        row_id = row.get("schema_id", "<bridge payload schema row>")
        if set(row.keys()) != set(BRIDGE_PAYLOAD_SCHEMA_FIELDS):
            errors.append(f"{row_id}: bridge-payload-schema.tsv fields do not match the schema contract")
        if not row.get("schema_id"):
            errors.append("bridge-payload-schema.tsv row lacks schema_id")
        elif row_id in bridge_payload_schema_ids:
            errors.append(f"duplicate bridge payload-schema id: {row_id}")
        bridge_payload_schema_ids.add(row_id)
        for field in BRIDGE_PAYLOAD_SCHEMA_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("route") not in BRIDGE_SCHEMA_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        if row.get("source_repo") not in BRIDGE_SCHEMA_SOURCE_REPOS:
            errors.append(f"{row_id}: invalid source_repo {row.get('source_repo')!r}")
        if row.get("estimator") not in BRIDGE_SCHEMA_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("r_bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid r_bridge_status {row.get('r_bridge_status')!r}")
        if ";" not in row.get("payload_fields", ""):
            errors.append(f"{row_id}: payload_fields should list multiple semicolon-separated fields")
        row_text = " ".join(str(row.get(field, "")) for field in BRIDGE_PAYLOAD_SCHEMA_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    bridge_provenance_fields_ids: set[str] = set()
    if not bridge_provenance_fields_rows:
        errors.append("bridge-provenance-fields.tsv has no provenance rows")
    for row in bridge_provenance_fields_rows:
        row_id = row.get("provenance_id", "<bridge provenance row>")
        if set(row.keys()) != set(BRIDGE_PROVENANCE_FIELDS_FIELDS):
            errors.append(f"{row_id}: bridge-provenance-fields.tsv fields do not match the provenance contract")
        if not row.get("provenance_id"):
            errors.append("bridge-provenance-fields.tsv row lacks provenance_id")
        elif row_id in bridge_provenance_fields_ids:
            errors.append(f"duplicate bridge provenance id: {row_id}")
        bridge_provenance_fields_ids.add(row_id)
        for field in BRIDGE_PROVENANCE_FIELDS_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("route") not in BRIDGE_PROVENANCE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        if row.get("source_system") not in BRIDGE_PROVENANCE_SOURCE_SYSTEMS:
            errors.append(f"{row_id}: invalid source_system {row.get('source_system')!r}")
        if row.get("verification_status") not in BRIDGE_PROVENANCE_STATUSES:
            errors.append(f"{row_id}: invalid verification_status {row.get('verification_status')!r}")
        if row.get("r_bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid r_bridge_status {row.get('r_bridge_status')!r}")
        if ";" not in row.get("required_fields", ""):
            errors.append(f"{row_id}: required_fields should list multiple semicolon-separated fields")
        row_text = " ".join(str(row.get(field, "")) for field in BRIDGE_PROVENANCE_FIELDS_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    loconly_bridge_draft_ids: set[str] = set()
    if not loconly_bridge_draft_rows:
        errors.append("loconly-bridge-draft.tsv has no draft rows")
    for row in loconly_bridge_draft_rows:
        row_id = row.get("draft_id", "<loconly bridge draft row>")
        if set(row.keys()) != set(LOCONLY_BRIDGE_DRAFT_FIELDS):
            errors.append(f"{row_id}: loconly-bridge-draft.tsv fields do not match the draft contract")
        if not row.get("draft_id"):
            errors.append("loconly-bridge-draft.tsv row lacks draft_id")
        elif row_id in loconly_bridge_draft_ids:
            errors.append(f"duplicate loconly bridge draft id: {row_id}")
        loconly_bridge_draft_ids.add(row_id)
        for field in LOCONLY_BRIDGE_DRAFT_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("estimator") not in BRIDGE_SCHEMA_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        for field in (
            "native_r_status",
            "direct_drmjl_status",
            "r_via_julia_status",
            "payload_schema_status",
            "provenance_status",
            "parity_status",
        ):
            if row.get(field) not in LOCONLY_BRIDGE_DRAFT_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in LOCONLY_BRIDGE_DRAFT_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    bridge_serialization_status_ids: set[str] = set()
    if not bridge_serialization_status_rows:
        errors.append("bridge-serialization-status.tsv has no serialization rows")
    for row in bridge_serialization_status_rows:
        row_id = row.get("serialization_id", "<bridge serialization row>")
        if set(row.keys()) != set(BRIDGE_SERIALIZATION_STATUS_FIELDS):
            errors.append(f"{row_id}: bridge-serialization-status.tsv fields do not match the serialization contract")
        if not row.get("serialization_id"):
            errors.append("bridge-serialization-status.tsv row lacks serialization_id")
        elif row_id in bridge_serialization_status_ids:
            errors.append(f"duplicate bridge serialization id: {row_id}")
        bridge_serialization_status_ids.add(row_id)
        for field in BRIDGE_SERIALIZATION_STATUS_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("format") not in BRIDGE_SERIALIZATION_FORMATS:
            errors.append(f"{row_id}: invalid format {row.get('format')!r}")
        for field in ("roundtrip_status", "missing_field_status", "test_status"):
            if row.get(field) not in BRIDGE_SERIALIZATION_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if ";" not in row.get("schema_fields", ""):
            errors.append(f"{row_id}: schema_fields should list multiple semicolon-separated fields")
        row_text = " ".join(str(row.get(field, "")) for field in BRIDGE_SERIALIZATION_STATUS_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    bridge_reconstruction_status_ids: set[str] = set()
    if not bridge_reconstruction_status_rows:
        errors.append("bridge-reconstruction-status.tsv has no reconstruction rows")
    for row in bridge_reconstruction_status_rows:
        row_id = row.get("reconstruction_id", "<bridge reconstruction row>")
        if set(row.keys()) != set(BRIDGE_RECONSTRUCTION_STATUS_FIELDS):
            errors.append(f"{row_id}: bridge-reconstruction-status.tsv fields do not match the reconstruction contract")
        if not row.get("reconstruction_id"):
            errors.append("bridge-reconstruction-status.tsv row lacks reconstruction_id")
        elif row_id in bridge_reconstruction_status_ids:
            errors.append(f"duplicate bridge reconstruction id: {row_id}")
        bridge_reconstruction_status_ids.add(row_id)
        for field in BRIDGE_RECONSTRUCTION_STATUS_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        for field in (
            "object_status",
            "payload_status",
            "coefficient_status",
            "vcov_status",
            "profile_target_status",
            "corpairs_status",
            "test_status",
        ):
            if row.get(field) not in BRIDGE_RECONSTRUCTION_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES | {"diagnostic_only"}:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in BRIDGE_RECONSTRUCTION_STATUS_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    julia_home_smoke_ids: set[str] = set()
    if not julia_home_smoke_rows:
        errors.append("julia-home-smoke.tsv has no smoke rows")
    for row in julia_home_smoke_rows:
        row_id = row.get("smoke_id", "<Julia home smoke row>")
        if set(row.keys()) != set(JULIA_HOME_SMOKE_FIELDS):
            errors.append(f"{row_id}: julia-home-smoke.tsv fields do not match the smoke contract")
        if not row.get("smoke_id"):
            errors.append("julia-home-smoke.tsv row lacks smoke_id")
        elif row_id in julia_home_smoke_ids:
            errors.append(f"duplicate Julia home smoke id: {row_id}")
        julia_home_smoke_ids.add(row_id)
        for field in JULIA_HOME_SMOKE_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("helper") not in JULIA_HOME_SMOKE_HELPERS:
            errors.append(f"{row_id}: invalid helper {row.get('helper')!r}")
        for field in ("observed_status", "test_status"):
            if row.get(field) not in JULIA_HOME_SMOKE_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in JULIA_HOME_SMOKE_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    bridge_rejection_message_ids: set[str] = set()
    bridge_rejection_gate_ids: set[str] = set()
    if not bridge_rejection_message_rows:
        errors.append("bridge-rejection-messages.tsv has no message rows")
    for row in bridge_rejection_message_rows:
        row_id = row.get("message_id", "<bridge rejection message row>")
        if set(row.keys()) != set(BRIDGE_REJECTION_MESSAGE_FIELDS):
            errors.append(f"{row_id}: bridge-rejection-messages.tsv fields do not match the message contract")
        if not row.get("message_id"):
            errors.append("bridge-rejection-messages.tsv row lacks message_id")
        elif row_id in bridge_rejection_message_ids:
            errors.append(f"duplicate bridge rejection message id: {row_id}")
        bridge_rejection_message_ids.add(row_id)
        for field in BRIDGE_REJECTION_MESSAGE_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        gate_id = row.get("gate_id", "")
        if gate_id:
            bridge_rejection_gate_ids.add(gate_id)
        if gate_id not in gate_ids:
            errors.append(f"{row_id}: gate_id {gate_id!r} is not in the gate registry")
        for field in ("guidance_status", "pre_juliacall_status", "test_status"):
            if row.get(field) not in BRIDGE_REJECTION_MESSAGE_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") != "intentional_error":
            errors.append(f"{row_id}: bridge_status is not intentional_error")
        row_text = " ".join(str(row.get(field, "")) for field in BRIDGE_REJECTION_MESSAGE_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")
    if bridge_rejection_gate_ids != gate_ids:
        missing = sorted(gate_ids - bridge_rejection_gate_ids)
        extra = sorted(bridge_rejection_gate_ids - gate_ids)
        if missing:
            errors.append(
                "bridge-rejection-messages.tsv lacks gate ids: " + ", ".join(missing)
            )
        if extra:
            errors.append(
                "bridge-rejection-messages.tsv has unknown gate ids: " + ", ".join(extra)
            )

    capability_regeneration_ids: set[str] = set()
    expected_regeneration_counts = {
        "julia_capability_comparison": len(capability_rows),
        "julia_gate_registry": len(gate_rows),
    }
    expected_source_functions = {
        "julia_capability_comparison": "drm_julia_capability_comparison",
        "julia_gate_registry": "drm_julia_intentional_gates",
    }
    if not capability_regeneration_status_rows:
        errors.append("capability-regeneration-status.tsv has no regeneration rows")
    for row in capability_regeneration_status_rows:
        row_id = row.get("artifact_id", "<capability regeneration row>")
        if set(row.keys()) != set(CAPABILITY_REGENERATION_STATUS_FIELDS):
            errors.append(f"{row_id}: capability-regeneration-status.tsv fields do not match the regeneration contract")
        if row_id in capability_regeneration_ids:
            errors.append(f"duplicate capability regeneration id: {row_id}")
        capability_regeneration_ids.add(row_id)
        for field in CAPABILITY_REGENERATION_STATUS_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row_id not in expected_regeneration_counts:
            errors.append(f"{row_id}: unknown regeneration artifact")
        elif row.get("source_function") != expected_source_functions[row_id]:
            errors.append(f"{row_id}: source_function does not match expected source")
        try:
            registry_rows = int(row.get("registry_rows", ""))
            artifact_rows = int(row.get("artifact_rows", ""))
        except ValueError:
            errors.append(f"{row_id}: registry_rows and artifact_rows must be integers")
            registry_rows = artifact_rows = -1
        expected_rows = expected_regeneration_counts.get(row_id)
        if expected_rows is not None and registry_rows != expected_rows:
            errors.append(f"{row_id}: registry_rows is {registry_rows}; expected {expected_rows}")
        if expected_rows is not None and artifact_rows != expected_rows:
            errors.append(f"{row_id}: artifact_rows is {artifact_rows}; expected {expected_rows}")
        for path_field in ("writer_script", "dashboard_output", "extdata_output"):
            if not evidence_reference_exists(row.get(path_field, "")):
                errors.append(f"{row_id}: {path_field} does not resolve to local evidence")
        for field in ("test_status", "regeneration_status"):
            if row.get(field) not in CAPABILITY_REGENERATION_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in CAPABILITY_REGENERATION_STATUS_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")
    if capability_regeneration_ids != set(expected_regeneration_counts):
        errors.append("capability-regeneration-status.tsv does not cover exactly the generated bridge artifacts")

    bridge_parity_smoke_ids: set[str] = set()
    if not bridge_parity_smoke_status_rows:
        errors.append("bridge-parity-smoke-status.tsv has no parity smoke rows")
    for row in bridge_parity_smoke_status_rows:
        row_id = row.get("smoke_id", "<bridge parity smoke row>")
        if set(row.keys()) != set(BRIDGE_PARITY_SMOKE_STATUS_FIELDS):
            errors.append(f"{row_id}: bridge-parity-smoke-status.tsv fields do not match the parity smoke contract")
        if not row.get("smoke_id"):
            errors.append("bridge-parity-smoke-status.tsv row lacks smoke_id")
        elif row_id in bridge_parity_smoke_ids:
            errors.append(f"duplicate bridge parity smoke id: {row_id}")
        bridge_parity_smoke_ids.add(row_id)
        for field in BRIDGE_PARITY_SMOKE_STATUS_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        for field in (
            "native_tmb_status",
            "r_via_julia_status",
            "direct_drmjl_status",
            "parity_status",
            "test_status",
        ):
            if row.get(field) not in BRIDGE_PARITY_SMOKE_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in BRIDGE_PARITY_SMOKE_STATUS_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    binomial_bridge_map_ids: set[str] = set()
    if not binomial_bridge_map_rows:
        errors.append("binomial-bridge-map.tsv has no map rows")
    for row in binomial_bridge_map_rows:
        row_id = row.get("map_id", "<binomial bridge map row>")
        if set(row.keys()) != set(BINOMIAL_BRIDGE_MAP_FIELDS):
            errors.append(f"{row_id}: binomial-bridge-map.tsv fields do not match the map contract")
        if not row.get("map_id"):
            errors.append("binomial-bridge-map.tsv row lacks map_id")
        elif row_id in binomial_bridge_map_ids:
            errors.append(f"duplicate binomial bridge map id: {row_id}")
        binomial_bridge_map_ids.add(row_id)
        for field in BINOMIAL_BRIDGE_MAP_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("route") not in BINOMIAL_BRIDGE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        for field in ("native_tmb_status", "drmjl_status"):
            if row.get(field) not in BINOMIAL_BRIDGE_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("r_bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid r_bridge_status {row.get('r_bridge_status')!r}")
        if row.get("parity_status") not in BINOMIAL_PARITY_STATUSES:
            errors.append(f"{row_id}: invalid parity_status {row.get('parity_status')!r}")
        if row.get("inference_status") not in BINOMIAL_INFERENCE_STATUSES:
            errors.append(f"{row_id}: invalid inference_status {row.get('inference_status')!r}")
        row_text = " ".join(str(row.get(field, "")) for field in BINOMIAL_BRIDGE_MAP_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    binomial_profile_status_ids: set[str] = set()
    if not binomial_profile_status_rows:
        errors.append("binomial-profile-status.tsv has no status rows")
    for row in binomial_profile_status_rows:
        row_id = row.get("status_id", "<binomial profile status row>")
        if set(row.keys()) != set(BINOMIAL_PROFILE_STATUS_FIELDS):
            errors.append(
                f"{row_id}: binomial-profile-status.tsv fields do not match the profile contract"
            )
        if not row.get("status_id"):
            errors.append("binomial-profile-status.tsv row lacks status_id")
        elif row_id in binomial_profile_status_ids:
            errors.append(f"duplicate binomial profile status id: {row_id}")
        binomial_profile_status_ids.add(row_id)
        for field in BINOMIAL_PROFILE_STATUS_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("profile_target_status") not in BINOMIAL_PROFILE_TARGET_STATUSES:
            errors.append(
                f"{row_id}: invalid profile_target_status {row.get('profile_target_status')!r}"
            )
        if row.get("default_profile_status") not in BINOMIAL_DEFAULT_PROFILE_STATUSES:
            errors.append(
                f"{row_id}: invalid default_profile_status {row.get('default_profile_status')!r}"
            )
        if row.get("explicit_profile_status") not in BINOMIAL_EXPLICIT_PROFILE_STATUSES:
            errors.append(
                f"{row_id}: invalid explicit_profile_status {row.get('explicit_profile_status')!r}"
            )
        if row.get("interval_claim_status") not in BINOMIAL_INTERVAL_CLAIM_STATUSES:
            errors.append(
                f"{row_id}: invalid interval_claim_status {row.get('interval_claim_status')!r}"
            )
        if row.get("test_status") not in MATRIX_STATUSES | {"covered"}:
            errors.append(f"{row_id}: invalid test_status {row.get('test_status')!r}")
        row_text = " ".join(
            str(row.get(field, "")) for field in BINOMIAL_PROFILE_STATUS_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    if len(ayumi_balance_slice_rows) != 100:
        errors.append(
            "ayumi-phylo-balance-100-slices.tsv has "
            f"{len(ayumi_balance_slice_rows)} rows; expected 100"
        )
    ayumi_slice_ids: set[str] = set()
    ayumi_slice_orders: set[int] = set()
    ayumi_wave_counts = {wave: 0 for wave in AYUMI_BALANCE_WAVES}
    for index, row in enumerate(ayumi_balance_slice_rows, start=1):
        row_id = row.get("slice_id", f"<Ayumi slice {index}>")
        if set(row.keys()) != set(AYUMI_BALANCE_SLICE_FIELDS):
            errors.append(
                f"{row_id}: ayumi-phylo-balance-100-slices.tsv fields "
                "do not match the ledger contract"
            )
        if not re.match(r"^A[0-9]{3}$", row_id):
            errors.append(f"{row_id}: slice_id must look like A001")
        elif row_id in ayumi_slice_ids:
            errors.append(f"duplicate Ayumi balance slice id: {row_id}")
        ayumi_slice_ids.add(row_id)
        try:
            order = int(row.get("order", ""))
        except ValueError:
            errors.append(f"{row_id}: order is not an integer")
            order = -1
        if order != index:
            errors.append(f"{row_id}: order is {order}; expected {index}")
        if 1 <= order <= 100:
            ayumi_slice_orders.add(order)
        expected_id = f"A{index:03d}"
        if row_id != expected_id:
            errors.append(f"{row_id}: expected slice_id {expected_id}")
        wave = row.get("wave")
        expected_wave = AYUMI_BALANCE_WAVES[(index - 1) // 10]
        if wave != expected_wave:
            errors.append(f"{row_id}: wave is {wave!r}; expected {expected_wave!r}")
        if wave in ayumi_wave_counts:
            ayumi_wave_counts[wave] += 1
        for field in (
            "area",
            "repo",
            "route",
            "primary_gate",
            "claim_boundary",
            "next_action",
        ):
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        status = row.get("status")
        if status not in SLICE_STATUSES:
            errors.append(f"{row_id}: invalid status {status!r}")
        bridge_status = row.get("bridge_status")
        if bridge_status not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {bridge_status!r}")
        row_text = " ".join(
            str(row.get(field, "")) for field in AYUMI_BALANCE_SLICE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if status in {"banked", "verified"} and not evidence_reference_exists(
            row.get("evidence_url", "")
        ):
            errors.append(f"{row_id}: banked/verified Ayumi slice row lacks evidence")
        dependencies = row.get("depends_on", "")
        if dependencies != "none":
            for dependency in dependencies.split(";"):
                if not re.match(r"^A[0-9]{3}$", dependency):
                    errors.append(f"{row_id}: dependency {dependency!r} must look like A001")
                elif dependency not in ayumi_slice_ids:
                    errors.append(
                        f"{row_id}: dependency {dependency!r} must refer to an earlier row"
                    )
    if ayumi_slice_orders != set(range(1, 101)):
        errors.append("ayumi-phylo-balance-100-slices.tsv orders are not exactly 1:100")
    for wave, count in ayumi_wave_counts.items():
        if count != 10:
            errors.append(
                f"ayumi-phylo-balance-100-slices.tsv wave {wave!r} has "
                f"{count} rows; expected 10"
            )

    ayumi_term_ids: set[str] = set()
    required_terms = {
        "balanced_univariate_phylo",
        "balanced_bivariate_q4",
        "partial_native_reml",
        "experimental_bridge",
        "diagnostic_point_fit",
        "map_not_ml_reml",
        "ayumi_reply_gate",
        "issue_access_boundary",
    }
    if not ayumi_balance_vocabulary_rows:
        errors.append("ayumi-phylo-balance-vocabulary.tsv has no term rows")
    for row in ayumi_balance_vocabulary_rows:
        row_id = row.get("term_id", "<Ayumi vocabulary row>")
        if set(row.keys()) != set(AYUMI_BALANCE_VOCABULARY_FIELDS):
            errors.append(
                f"{row_id}: ayumi-phylo-balance-vocabulary.tsv fields "
                "do not match the vocabulary contract"
            )
        if not row.get("term_id"):
            errors.append("ayumi-phylo-balance-vocabulary.tsv row lacks term_id")
        elif row_id in ayumi_term_ids:
            errors.append(f"duplicate Ayumi vocabulary term id: {row_id}")
        ayumi_term_ids.add(row_id)
        for field in AYUMI_BALANCE_VOCABULARY_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        invalid_statuses = [
            status.strip()
            for status in row.get("allowed_status", "").split(";")
            if status.strip() not in AYUMI_BALANCE_ALLOWED_TERM_STATUSES
        ]
        if invalid_statuses:
            errors.append(f"{row_id}: invalid allowed_status values {invalid_statuses!r}")
        row_text = " ".join(
            str(row.get(field, "")) for field in AYUMI_BALANCE_VOCABULARY_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")
    missing_terms = sorted(required_terms - ayumi_term_ids)
    if missing_terms:
        errors.append(
            "ayumi-phylo-balance-vocabulary.tsv lacks required terms: "
            + ", ".join(missing_terms)
        )

    ayumi_tracker_ids: set[str] = set()
    required_trackers = {
        "ayumi_issue_2",
        "drmtmb_555",
        "drmtmb_570",
        "drmjl_291",
        "drmjl_293",
    }
    if not ayumi_balance_tracker_rows:
        errors.append("ayumi-phylo-balance-trackers.tsv has no tracker rows")
    for row in ayumi_balance_tracker_rows:
        row_id = row.get("tracker_id", "<Ayumi tracker row>")
        if set(row.keys()) != set(AYUMI_BALANCE_TRACKER_FIELDS):
            errors.append(
                f"{row_id}: ayumi-phylo-balance-trackers.tsv fields "
                "do not match the tracker contract"
            )
        if not row.get("tracker_id"):
            errors.append("ayumi-phylo-balance-trackers.tsv row lacks tracker_id")
        elif row_id in ayumi_tracker_ids:
            errors.append(f"duplicate Ayumi tracker id: {row_id}")
        ayumi_tracker_ids.add(row_id)
        for field in AYUMI_BALANCE_TRACKER_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("source") not in AYUMI_TRACKER_SOURCES:
            errors.append(f"{row_id}: invalid source {row.get('source')!r}")
        if row.get("issue_status") not in AYUMI_TRACKER_ISSUE_STATUSES:
            errors.append(f"{row_id}: invalid issue_status {row.get('issue_status')!r}")
        if row.get("blocker_status") not in AYUMI_TRACKER_BLOCKER_STATUSES:
            errors.append(
                f"{row_id}: invalid blocker_status {row.get('blocker_status')!r}"
            )
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if not row.get("issue_url", "").startswith("https://github.com/"):
            errors.append(f"{row_id}: issue_url is not a GitHub URL")
        row_text = " ".join(
            str(row.get(field, "")) for field in AYUMI_BALANCE_TRACKER_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_trackers = sorted(required_trackers - ayumi_tracker_ids)
    if missing_trackers:
        errors.append(
            "ayumi-phylo-balance-trackers.tsv lacks required trackers: "
            + ", ".join(missing_trackers)
        )

    ayumi_coverage_ids: set[str] = set()
    required_coverage_rows = {
        "native_univariate_mu_phylo_ml",
        "native_univariate_sigma_phylo_ml",
        "native_univariate_mu_sigma_phylo_ml",
        "native_bivariate_q4_ml_sd",
        "native_bivariate_q4_ml_cor",
        "native_bivariate_q4_reml",
        "bridge_bivariate_q4_reml",
        "direct_drmjl_bivariate_q4_profile_bootstrap",
    }
    if not ayumi_inference_coverage_rows:
        errors.append("ayumi-inference-coverage-ledger.tsv has no coverage rows")
    for row in ayumi_inference_coverage_rows:
        row_id = row.get("coverage_id", "<Ayumi coverage row>")
        if set(row.keys()) != set(AYUMI_INFERENCE_COVERAGE_FIELDS):
            errors.append(
                f"{row_id}: ayumi-inference-coverage-ledger.tsv fields "
                "do not match the coverage contract"
            )
        if not row.get("coverage_id"):
            errors.append("ayumi-inference-coverage-ledger.tsv row lacks coverage_id")
        elif row_id in ayumi_coverage_ids:
            errors.append(f"duplicate Ayumi coverage id: {row_id}")
        ayumi_coverage_ids.add(row_id)
        for field in AYUMI_INFERENCE_COVERAGE_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("route") not in AYUMI_INFERENCE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        if row.get("engine") not in Q4_ENGINES:
            errors.append(f"{row_id}: invalid engine {row.get('engine')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("wald_status") not in AYUMI_WALD_STATUSES:
            errors.append(f"{row_id}: invalid wald_status {row.get('wald_status')!r}")
        if row.get("profile_status") not in AYUMI_PROFILE_STATUSES:
            errors.append(f"{row_id}: invalid profile_status {row.get('profile_status')!r}")
        if row.get("bootstrap_status") not in AYUMI_BOOTSTRAP_STATUSES:
            errors.append(
                f"{row_id}: invalid bootstrap_status {row.get('bootstrap_status')!r}"
            )
        if row.get("coverage_status") not in AYUMI_COVERAGE_STATUSES:
            errors.append(
                f"{row_id}: invalid coverage_status {row.get('coverage_status')!r}"
            )
        row_text = " ".join(
            str(row.get(field, "")) for field in AYUMI_INFERENCE_COVERAGE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")
    missing_coverage = sorted(required_coverage_rows - ayumi_coverage_ids)
    if missing_coverage:
        errors.append(
            "ayumi-inference-coverage-ledger.tsv lacks required rows: "
            + ", ".join(missing_coverage)
        )

    ayumi_boundary_ids: set[str] = set()
    required_boundary_rows = {
        "native_scale_phylo_pdhess_false",
        "native_scale_phylo_clamp_active",
        "native_q4_30tip_pdhess_false",
        "native_q4_100tip_nonconverged",
        "native_q4_250tip_profile_failed",
        "ayumi_pv2_locphylo_current",
        "ayumi_pv2_q4_main_boundary",
        "direct_drmjl_q4_collapsed_axis",
    }
    if not ayumi_boundary_status_rows:
        errors.append("ayumi-boundary-status-ledger.tsv has no boundary rows")
    for row in ayumi_boundary_status_rows:
        row_id = row.get("boundary_id", "<Ayumi boundary row>")
        if set(row.keys()) != set(AYUMI_BOUNDARY_STATUS_FIELDS):
            errors.append(
                f"{row_id}: ayumi-boundary-status-ledger.tsv fields "
                "do not match the boundary contract"
            )
        if not row.get("boundary_id"):
            errors.append("ayumi-boundary-status-ledger.tsv row lacks boundary_id")
        elif row_id in ayumi_boundary_ids:
            errors.append(f"duplicate Ayumi boundary id: {row_id}")
        ayumi_boundary_ids.add(row_id)
        for field in AYUMI_BOUNDARY_STATUS_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("route") not in AYUMI_INFERENCE_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        if row.get("engine") not in Q4_ENGINES:
            errors.append(f"{row_id}: invalid engine {row.get('engine')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("boundary_signal") not in AYUMI_BOUNDARY_SIGNALS:
            errors.append(
                f"{row_id}: invalid boundary_signal {row.get('boundary_signal')!r}"
            )
        if row.get("fit_status") not in AYUMI_BOUNDARY_FIT_STATUSES:
            errors.append(f"{row_id}: invalid fit_status {row.get('fit_status')!r}")
        if row.get("interval_status") not in AYUMI_BOUNDARY_INTERVAL_STATUSES:
            errors.append(
                f"{row_id}: invalid interval_status {row.get('interval_status')!r}"
            )
        row_text = " ".join(
            str(row.get(field, "")) for field in AYUMI_BOUNDARY_STATUS_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")
    missing_boundary = sorted(required_boundary_rows - ayumi_boundary_ids)
    if missing_boundary:
        errors.append(
            "ayumi-boundary-status-ledger.tsv lacks required rows: "
            + ", ".join(missing_boundary)
        )

    if len(hundred_slice_rows) != 100:
        errors.append(f"finish-100-slices.tsv has {len(hundred_slice_rows)} rows; expected 100")
    slice_ids: set[str] = set()
    slice_orders: set[int] = set()
    wave_counts = {wave: 0 for wave in HUNDRED_SLICE_WAVES}
    for index, row in enumerate(hundred_slice_rows, start=1):
        row_id = row.get("slice_id", f"<slice {index}>")
        if set(row.keys()) != set(HUNDRED_SLICE_FIELDS):
            errors.append(f"{row_id}: finish-100-slices.tsv fields do not match the ledger contract")
        if not re.match(r"^S[0-9]{3}$", row_id):
            errors.append(f"{row_id}: slice_id must look like S001")
        elif row_id in slice_ids:
            errors.append(f"duplicate 100-slice id: {row_id}")
        slice_ids.add(row_id)
        try:
            order = int(row.get("order", ""))
        except ValueError:
            errors.append(f"{row_id}: order is not an integer")
            order = -1
        if order != index:
            errors.append(f"{row_id}: order is {order}; expected {index}")
        if 1 <= order <= 100:
            slice_orders.add(order)
        expected_id = f"S{index:03d}"
        if row_id != expected_id:
            errors.append(f"{row_id}: expected slice_id {expected_id}")
        wave = row.get("wave")
        expected_wave = HUNDRED_SLICE_WAVES[(index - 1) // 10]
        if wave != expected_wave:
            errors.append(f"{row_id}: wave is {wave!r}; expected {expected_wave!r}")
        if wave in wave_counts:
            wave_counts[wave] += 1
        for field in ("area", "repo", "route", "primary_gate", "claim_boundary", "next_action"):
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        status = row.get("status")
        if status not in SLICE_STATUSES:
            errors.append(f"{row_id}: invalid status {status!r}")
        bridge_status = row.get("bridge_status")
        if bridge_status not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {bridge_status!r}")
        row_text = " ".join(str(row.get(field, "")) for field in HUNDRED_SLICE_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if status in {"banked", "verified"} and not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: banked/verified 100-slice row lacks existing evidence")
        dependencies = row.get("depends_on", "")
        if dependencies != "none":
            for dependency in dependencies.split(";"):
                if not re.match(r"^S[0-9]{3}$", dependency):
                    errors.append(f"{row_id}: dependency {dependency!r} must look like S001")
                elif dependency not in slice_ids:
                    errors.append(f"{row_id}: dependency {dependency!r} must refer to an earlier row")
    if slice_orders != set(range(1, 101)):
        errors.append("finish-100-slices.tsv orders are not exactly 1:100")
    for wave, count in wave_counts.items():
        if count != 10:
            errors.append(f"finish-100-slices.tsv wave {wave!r} has {count} rows; expected 10")

    for path in PUBLIC_CLAIM_REFERENCE_FILES:
        if not path.exists():
            errors.append(f"public claim reference file is missing: {rel_path(path)}")
            continue
        text = path.read_text(encoding="utf-8")
        if CLAIM_MATRIX_REF not in text:
            errors.append(f"{rel_path(path)} does not link the finish capability matrix")
    for path in documenter_paths:
        text = path.read_text(encoding="utf-8", errors="ignore")
        if CLAIM_MATRIX_REF not in text:
            errors.append(f"{rel_path(path)} local Documenter claim file does not link the finish capability matrix")

    for path in public_claim_scan_paths():
        if path == DESIGN_MATRIX:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in RELEASE_READY_PATTERN.finditer(text):
            line = text_line_number(text, match.start())
            errors.append(
                f"{rel_path(path)}:{line} uses release-ready language outside the release gate"
            )
        for match in RESERVED_PUBLIC_CONTROL_PATTERN.finditer(text):
            line = text_line_number(text, match.start())
            errors.append(f"{rel_path(path)}:{line} exposes reserved engine_control language")
        for match in AI_REML_READY_TRUE_PATTERN.finditer(text):
            if not PROMOTED_AI_REML_GATE_PATTERN.search(text):
                line = text_line_number(text, match.start())
                errors.append(
                    f"{rel_path(path)}:{line} claims ai_reml_ready=true without a promoted optimizer gate"
                )

    if errors:
        for error in errors:
            print(f"mission-control validation error: {error}", file=sys.stderr)
        return 1

    print(
        "mission_control_ok: "
        f"{expected_metrics['verified']}/{expected_metrics['total']} banked_or_verified, "
        f"{expected_metrics['active']} active, "
        f"{len(matrix)} matrix rows, "
        f"{len(finish_board)} finish rows, "
        f"{len(gate_rows)} Julia gate rows, "
        f"{len(capability_rows)} Julia capability rows, "
        f"{len(hundred_slice_rows)} 100-slice rows, "
        f"{len(q4_target_rows)} q4 target rows, "
        f"{len(phylo_balance_rows)} phylo balance rows, "
        f"{len(scale_phylo_diagnostic_rows)} scale phylo diagnostic rows, "
        f"{len(phylo_profile_loglik_rows)} phylo profile/logLik rows, "
        f"{len(bootstrap_refit_accounting_rows)} bootstrap accounting rows"
        f", {len(phylo_q2_q4_target_map_rows)} phylo q2/q4 target-map rows"
        f", {len(phylo_extractor_status_rows)} phylo extractor-status rows"
        f", {len(bridge_payload_schema_rows)} bridge payload-schema rows"
        f", {len(bridge_provenance_fields_rows)} bridge provenance rows"
        f", {len(loconly_bridge_draft_rows)} loconly bridge draft rows"
        f", {len(bridge_serialization_status_rows)} bridge serialization rows"
        f", {len(bridge_reconstruction_status_rows)} bridge reconstruction rows"
        f", {len(julia_home_smoke_rows)} Julia home smoke rows"
        f", {len(bridge_rejection_message_rows)} bridge rejection-message rows"
        f", {len(capability_regeneration_status_rows)} capability regeneration rows"
        f", {len(bridge_parity_smoke_status_rows)} bridge parity smoke rows"
        f", {len(binomial_bridge_map_rows)} binomial bridge-map rows"
        f", {len(binomial_profile_status_rows)} binomial profile-status rows"
        f", {len(ayumi_balance_slice_rows)} Ayumi balance-slice rows"
        f", {len(ayumi_balance_vocabulary_rows)} Ayumi balance vocabulary rows"
        f", {len(ayumi_balance_tracker_rows)} Ayumi balance tracker rows"
        f", {len(ayumi_inference_coverage_rows)} Ayumi inference coverage rows"
        f", {len(ayumi_boundary_status_rows)} Ayumi boundary-status rows"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
