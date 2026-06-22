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
START_MISSION_CONTROL = ROOT / "tools" / "start-mission-control.sh"
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
STRUCTURED_RE_BALANCE_MATRIX = DASHBOARD / "structured-re-balance-matrix.tsv"
STRUCTURED_RE_BALANCE_SLICE_LEDGER = DASHBOARD / "structured-re-balance-100-slices.tsv"
STRUCTURED_RE_FINISH_SLICE_LEDGER = DASHBOARD / "structured-re-finish-100-slices.tsv"
MEMBER_ROSTER = DASHBOARD / "member-roster.tsv"
MEMBER_DISCUSSIONS = DASHBOARD / "member-discussions.tsv"
MEMBER_WAVE_ASSIGNMENTS = DASHBOARD / "member-wave-assignments.tsv"
STRUCTURED_RE_CONVERSION_SLICE_LEDGER = DASHBOARD / "structured-re-conversion-200-slices.tsv"
STRUCTURED_RE_STATUS_VOCABULARY = DASHBOARD / "structured-re-status-vocabulary.tsv"
STRUCTURED_RE_Q1_BRIDGE_PAYLOAD_CONTRACT = DASHBOARD / "structured-re-q1-bridge-payload-contract.tsv"
STRUCTURED_RE_Q1_RECONSTRUCTION_MAP = DASHBOARD / "structured-re-q1-reconstruction-map.tsv"
STRUCTURED_RE_Q1_PARITY_FIXTURE_CONTRACT = DASHBOARD / "structured-re-q1-parity-fixture-contract.tsv"
STRUCTURED_RE_Q2_TARGET_CONTRACT = DASHBOARD / "structured-re-q2-target-contract.tsv"
STRUCTURED_RE_Q2_NATIVE_EVIDENCE = DASHBOARD / "structured-re-q2-native-evidence.tsv"
STRUCTURED_RE_Q2_BRIDGE_BOUNDARY = DASHBOARD / "structured-re-q2-bridge-boundary.tsv"
STRUCTURED_RE_Q4_TARGET_CONTRACT = DASHBOARD / "structured-re-q4-target-contract.tsv"
STRUCTURED_RE_Q4_EXTRACTOR_PARITY = DASHBOARD / "structured-re-q4-extractor-parity.tsv"
STRUCTURED_RE_Q4_BRIDGE_BOUNDARY = DASHBOARD / "structured-re-q4-bridge-boundary.tsv"
STRUCTURED_RE_REML_SCOPE_GATE = DASHBOARD / "structured-re-reml-scope-gate.tsv"
STRUCTURED_RE_ADEMP_DESIGN = DASHBOARD / "structured-re-ademp-design.tsv"
STRUCTURED_RE_TYPE_GAPS = DASHBOARD / "structured-re-type-gaps.tsv"
STRUCTURED_RE_R_DOCS_API_SYNC = DASHBOARD / "structured-re-r-docs-api-sync.tsv"
STRUCTURED_RE_JULIA_TWIN_SYNC = DASHBOARD / "structured-re-julia-twin-sync.tsv"
STRUCTURED_RE_CLOSEOUT_PACKAGE = DASHBOARD / "structured-re-closeout-package.tsv"
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
STRUCTURED_RE_BALANCE_MATRIX_FIELDS = (
    "cell_id",
    "structured_type",
    "input_scope",
    "dimension",
    "endpoints",
    "estimator",
    "fit_status",
    "inference_status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_BALANCE_SLICE_FIELDS = HUNDRED_SLICE_FIELDS
MEMBER_ROSTER_FIELDS = (
    "member_id",
    "canonical_name",
    "role_slug",
    "launchable_agent",
    "authority",
    "can_do",
    "current_waves",
    "improvement_target",
    "required_signoff_for",
    "status",
    "last_verified",
    "source_ref",
)
MEMBER_DISCUSSION_FIELDS = (
    "meeting_id",
    "slice_id",
    "member_id",
    "stance",
    "exact_claim",
    "evidence_class",
    "evidence_path",
    "negative_evidence",
    "sibling_impact",
    "decision_status",
    "next_gate",
    "timestamp",
)
MEMBER_WAVE_ASSIGNMENT_FIELDS = (
    "wave_id",
    "slice_range",
    "lead_member",
    "required_members",
    "optional_members",
    "bank_condition",
    "blocked_condition",
)
STRUCTURED_RE_CONVERSION_SLICE_FIELDS = (
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
    "lead_member",
    "required_members",
    "bank_condition",
)
STRUCTURED_RE_STATUS_VOCABULARY_FIELDS = (
    "term",
    "applies_to",
    "allowed_scope",
    "not_claimed",
    "evidence_rule",
    "owner_member",
    "status",
    "evidence_url",
    "next_gate",
)
STRUCTURED_RE_Q1_BRIDGE_PAYLOAD_CONTRACT_FIELDS = (
    "contract_id",
    "target",
    "route",
    "estimator",
    "required_payload_fields",
    "required_provenance",
    "unsupported_fields",
    "status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q1_RECONSTRUCTION_MAP_FIELDS = (
    "map_id",
    "target",
    "extractor",
    "required_payload",
    "reconstruction_output",
    "unavailable_status",
    "bridge_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q1_PARITY_FIXTURE_CONTRACT_FIELDS = (
    "fixture_id",
    "target",
    "native_r_path",
    "direct_drmjl_path",
    "r_via_julia_path",
    "parity_quantity",
    "tolerance",
    "status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q2_TARGET_CONTRACT_FIELDS = (
    "target_id",
    "dimension",
    "axes",
    "estimator",
    "route",
    "separated_from",
    "direct_targets",
    "derived_targets",
    "profile_status",
    "inference_status",
    "bridge_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q2_NATIVE_EVIDENCE_FIELDS = (
    "evidence_id",
    "structured_type",
    "dimension",
    "estimator",
    "native_route",
    "likelihood_evidence",
    "extractor_evidence",
    "inference_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q2_BRIDGE_BOUNDARY_FIELDS = (
    "boundary_id",
    "target",
    "bridge_status",
    "allowed_behavior",
    "error_reason",
    "negative_evidence",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_TARGET_CONTRACT_FIELDS = (
    "target_id",
    "axes",
    "estimator",
    "direct_sd_targets",
    "derived_correlation_targets",
    "profile_status",
    "interval_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_EXTRACTOR_PARITY_FIELDS = (
    "extractor_id",
    "target",
    "source",
    "point_status",
    "vcov_status",
    "profile_status",
    "interval_status",
    "bridge_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_BRIDGE_BOUNDARY_FIELDS = (
    "boundary_id",
    "target",
    "smoke_status",
    "parity_required",
    "bridge_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_REML_SCOPE_GATE_FIELDS = (
    "gate_id",
    "target",
    "route",
    "allowed_wording",
    "forbidden_wording",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_ADEMP_DESIGN_FIELDS = (
    "design_id",
    "dimension",
    "aim",
    "dgp",
    "estimand",
    "methods",
    "performance",
    "mcse_target",
    "failed_fit_policy",
    "interval_policy",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_TYPE_GAP_FIELDS = (
    "gap_id",
    "structured_type",
    "dimension",
    "supported_now",
    "missing_cell",
    "user_message",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_R_DOCS_API_SYNC_FIELDS = (
    "sync_id",
    "surface",
    "synced_terms",
    "missing_or_deferred",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_JULIA_TWIN_SYNC_FIELDS = (
    "sync_id",
    "repo",
    "branch",
    "head",
    "evidence_class",
    "bridge_impact",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_CLOSEOUT_PACKAGE_FIELDS = (
    "closeout_id",
    "item",
    "status",
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
STRUCTURED_RE_BALANCE_WAVES = (
    "Rehydrate",
    "Native ML q1",
    "Native ML q2",
    "Native ML q4",
    "Structured slopes",
    "Native REML",
    "Inference",
    "Bridge parity",
    "Docs",
    "Closeout Reply",
)
STRUCTURED_RE_FINISH_WAVES = (
    "Finish Rehydrate",
    "Bridge q1 parity",
    "Bridge q2 parity",
    "Bridge q4 parity",
    "Coverage calibration",
    "Native REML scope",
    "Structured type gaps",
    "R API docs",
    "Julia twin sync",
    "Ayumi closeout",
)
STRUCTURED_RE_CONVERSION_WAVES = (
    "Mission-control restore",
    "Member board v1",
    "Status vocabulary cleanup",
    "q1 bridge payload contract",
    "q1 bridge reconstruction",
    "q1 parity fixture",
    "q2 target contract",
    "q2 native evidence",
    "q2 bridge boundary",
    "q4 target contract",
    "q4 extractor parity",
    "q4 bridge boundary",
    "REML scope gate",
    "ADEMP q1 design",
    "ADEMP q2 design",
    "ADEMP q4 design",
    "Structured type gaps",
    "R docs/API sync",
    "Julia twin sync",
    "Closeout package",
)
MEMBER_STATUSES = {"active", "queued", "blocked", "deferred"}
MEMBER_DISCUSSION_STANCES = {
    "approve",
    "block_until_done",
    "needs_evidence",
    "question",
}
MEMBER_DISCUSSION_DECISIONS = {"accepted", "open", "blocked", "superseded"}
MEMBER_ROLE_TO_AGENT = {
    "integration_reviewer": "integration-reviewer",
    "systems_auditor": "systems-auditor",
    "reproducibility_engineer": "reproducibility-engineer",
    "formula_reviewer": "formula-reviewer",
    "architecture_reviewer": "architecture-reviewer",
    "inference_reviewer": "inference-reviewer",
    "tmb_engineer": "tmb-engineer",
    "math_consistency_reviewer": "math-consistency-reviewer",
    "simulation_tester": "simulation-tester",
    "user_tester": "user-tester",
    "audience_reviewer": "audience-reviewer",
    "figure_reviewer": "figure-reviewer",
    "landscape_scout": "landscape-scout",
}
R_BRIDGE_STATUSES = {"supported", "experimental", "intentional_error", "planned", "unsupported"}
STRUCTURED_RE_VOCABULARY_TERMS = {
    "covered",
    "partial",
    "planned",
    "banked",
    "blocked",
    "experimental",
    "unsupported",
}
STRUCTURED_RE_Q1_TARGETS = {
    "gaussian_q1_mu_structured",
    "gaussian_q1_sigma_structured",
    "gaussian_q1_mu_sigma_structured",
    "gaussian_q1_mu_phylo_loconly",
    "count_q1_mu_structured",
}
STRUCTURED_RE_Q1_EXTRACTORS = {"coef", "vcov", "profile_targets", "summary", "corpairs"}
STRUCTURED_RE_Q2_TARGET_DIMENSIONS = {"q2", "q2_plus_q2"}
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
STRUCTURED_RE_TYPES = {"phylo", "spatial", "animal", "relmat", "phylo_interaction"}
STRUCTURED_RE_INPUT_SCOPES = {
    "tree",
    "coords",
    "pedigree_or_A",
    "A_or_Ainv",
    "K_or_Q",
    "tree_pair",
}
STRUCTURED_RE_DIMENSIONS = {"q1", "q2", "q2_plus_q2", "q4"}
STRUCTURED_RE_REQUIRED_MATRIX_CELLS = {
    "sr_phylo_q1_gaussian_mu",
    "sr_phylo_q1_gaussian_sigma",
    "sr_phylo_q1_gaussian_mu_sigma",
    "sr_phylo_q2_biv_mu",
    "sr_phylo_q2_plus_q2_biv_mu_sigma",
    "sr_phylo_q4_biv_all_four",
    "sr_phylo_q1_count_mu",
    "sr_spatial_q1_gaussian_mu",
    "sr_spatial_q1_gaussian_sigma",
    "sr_spatial_q1_gaussian_mu_sigma",
    "sr_spatial_q2_biv_mu",
    "sr_spatial_q4_biv_all_four",
    "sr_spatial_q1_count_mu",
    "sr_animal_q1_gaussian_mu",
    "sr_animal_q1_gaussian_sigma",
    "sr_animal_q1_gaussian_mu_sigma",
    "sr_animal_q2_biv_mu",
    "sr_animal_q4_biv_all_four",
    "sr_animal_q1_count_mu",
    "sr_relmat_q1_gaussian_mu",
    "sr_relmat_q1_gaussian_sigma",
    "sr_relmat_q1_gaussian_mu_sigma",
    "sr_relmat_q2_biv_mu",
    "sr_relmat_q4_biv_all_four",
    "sr_relmat_q1_count_mu",
    "sr_phylo_interaction_q1_gaussian_mu",
    "sr_phylo_interaction_q1_count_mu",
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


def member_list(value: str) -> list[str]:
    if value in {"", "none"}:
        return []
    return [part.strip() for part in value.split(";") if part.strip()]


def slug(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


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
    structured_re_balance_matrix_rows = read_tsv(STRUCTURED_RE_BALANCE_MATRIX)
    structured_re_balance_slice_rows = read_tsv(STRUCTURED_RE_BALANCE_SLICE_LEDGER)
    structured_re_finish_slice_rows = read_tsv(STRUCTURED_RE_FINISH_SLICE_LEDGER)
    member_roster_rows = read_tsv(MEMBER_ROSTER)
    member_discussion_rows = read_tsv(MEMBER_DISCUSSIONS)
    member_wave_assignment_rows = read_tsv(MEMBER_WAVE_ASSIGNMENTS)
    structured_re_conversion_slice_rows = read_tsv(STRUCTURED_RE_CONVERSION_SLICE_LEDGER)
    structured_re_status_vocabulary_rows = read_tsv(STRUCTURED_RE_STATUS_VOCABULARY)
    structured_re_q1_bridge_payload_contract_rows = read_tsv(
        STRUCTURED_RE_Q1_BRIDGE_PAYLOAD_CONTRACT
    )
    structured_re_q1_reconstruction_map_rows = read_tsv(STRUCTURED_RE_Q1_RECONSTRUCTION_MAP)
    structured_re_q1_parity_fixture_contract_rows = read_tsv(
        STRUCTURED_RE_Q1_PARITY_FIXTURE_CONTRACT
    )
    structured_re_q2_target_contract_rows = read_tsv(STRUCTURED_RE_Q2_TARGET_CONTRACT)
    structured_re_q2_native_evidence_rows = read_tsv(STRUCTURED_RE_Q2_NATIVE_EVIDENCE)
    structured_re_q2_bridge_boundary_rows = read_tsv(STRUCTURED_RE_Q2_BRIDGE_BOUNDARY)
    structured_re_q4_target_contract_rows = read_tsv(STRUCTURED_RE_Q4_TARGET_CONTRACT)
    structured_re_q4_extractor_parity_rows = read_tsv(STRUCTURED_RE_Q4_EXTRACTOR_PARITY)
    structured_re_q4_bridge_boundary_rows = read_tsv(STRUCTURED_RE_Q4_BRIDGE_BOUNDARY)
    structured_re_reml_scope_gate_rows = read_tsv(STRUCTURED_RE_REML_SCOPE_GATE)
    structured_re_ademp_design_rows = read_tsv(STRUCTURED_RE_ADEMP_DESIGN)
    structured_re_type_gap_rows = read_tsv(STRUCTURED_RE_TYPE_GAPS)
    structured_re_r_docs_api_sync_rows = read_tsv(STRUCTURED_RE_R_DOCS_API_SYNC)
    structured_re_julia_twin_sync_rows = read_tsv(STRUCTURED_RE_JULIA_TWIN_SYNC)
    structured_re_closeout_package_rows = read_tsv(STRUCTURED_RE_CLOSEOUT_PACKAGE)
    documenter_paths = local_documenter_claim_paths()

    version = (DASHBOARD / "version.txt").read_text(encoding="utf-8").strip()
    index = (DASHBOARD / "index.html").read_text(encoding="utf-8")
    build = re.search(r'const BUILD = "([^"]+)"', index)
    if not build:
        errors.append("index.html has no BUILD constant")
    elif build.group(1) != version:
        errors.append(f"version.txt is {version!r}, but index.html BUILD is {build.group(1)!r}")

    start_script = START_MISSION_CONTROL.read_text(encoding="utf-8")
    dashboard_tsvs = sorted(path.name for path in DASHBOARD.glob("*.tsv"))
    if '"$SRC"/*.tsv' not in start_script and "'$SRC'/*.tsv" not in start_script:
        missing_copies = [name for name in dashboard_tsvs if name not in start_script]
        if missing_copies:
            errors.append(
                "tools/start-mission-control.sh does not copy dashboard TSVs: "
                + ", ".join(missing_copies)
            )

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

    structured_re_cell_ids: set[str] = set()
    if not structured_re_balance_matrix_rows:
        errors.append("structured-re-balance-matrix.tsv has no matrix rows")
    for row in structured_re_balance_matrix_rows:
        row_id = row.get("cell_id", "<structured RE matrix row>")
        if set(row.keys()) != set(STRUCTURED_RE_BALANCE_MATRIX_FIELDS):
            errors.append(
                f"{row_id}: structured-re-balance-matrix.tsv fields "
                "do not match the matrix contract"
            )
        if not row.get("cell_id"):
            errors.append("structured-re-balance-matrix.tsv row lacks cell_id")
        elif row_id in structured_re_cell_ids:
            errors.append(f"duplicate structured RE matrix cell id: {row_id}")
        structured_re_cell_ids.add(row_id)
        for field in STRUCTURED_RE_BALANCE_MATRIX_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("structured_type") not in STRUCTURED_RE_TYPES:
            errors.append(
                f"{row_id}: invalid structured_type {row.get('structured_type')!r}"
            )
        if row.get("input_scope") not in STRUCTURED_RE_INPUT_SCOPES:
            errors.append(f"{row_id}: invalid input_scope {row.get('input_scope')!r}")
        if row.get("dimension") not in STRUCTURED_RE_DIMENSIONS:
            errors.append(f"{row_id}: invalid dimension {row.get('dimension')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        for field in ("fit_status", "inference_status"):
            if row.get(field) not in MATRIX_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_BALANCE_MATRIX_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")
    missing_structured_re_cells = sorted(
        STRUCTURED_RE_REQUIRED_MATRIX_CELLS - structured_re_cell_ids
    )
    extra_structured_re_cells = sorted(
        structured_re_cell_ids - STRUCTURED_RE_REQUIRED_MATRIX_CELLS
    )
    if missing_structured_re_cells:
        errors.append(
            "structured-re-balance-matrix.tsv lacks required cells: "
            + ", ".join(missing_structured_re_cells)
        )
    if extra_structured_re_cells:
        errors.append(
            "structured-re-balance-matrix.tsv has unexpected cells: "
            + ", ".join(extra_structured_re_cells)
        )
    present_structured_re_types = {
        row.get("structured_type") for row in structured_re_balance_matrix_rows
    }
    missing_structured_re_types = sorted(
        STRUCTURED_RE_TYPES - present_structured_re_types
    )
    if missing_structured_re_types:
        errors.append(
            "structured-re-balance-matrix.tsv lacks structured types: "
            + ", ".join(missing_structured_re_types)
        )
    present_structured_re_dimensions = {
        row.get("dimension") for row in structured_re_balance_matrix_rows
    }
    missing_structured_re_dimensions = sorted(
        STRUCTURED_RE_DIMENSIONS - present_structured_re_dimensions
    )
    if missing_structured_re_dimensions:
        errors.append(
            "structured-re-balance-matrix.tsv lacks dimensions: "
            + ", ".join(missing_structured_re_dimensions)
        )

    if len(structured_re_balance_slice_rows) != 100:
        errors.append(
            "structured-re-balance-100-slices.tsv has "
            f"{len(structured_re_balance_slice_rows)} rows; expected 100"
        )
    structured_re_slice_ids: set[str] = set()
    structured_re_slice_orders: set[int] = set()
    structured_re_wave_counts = {wave: 0 for wave in STRUCTURED_RE_BALANCE_WAVES}
    for index, row in enumerate(structured_re_balance_slice_rows, start=1):
        row_id = row.get("slice_id", f"<structured RE slice {index}>")
        if set(row.keys()) != set(STRUCTURED_RE_BALANCE_SLICE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-balance-100-slices.tsv fields "
                "do not match the ledger contract"
            )
        if not re.match(r"^SR[0-9]{3}$", row_id):
            errors.append(f"{row_id}: slice_id must look like SR001")
        elif row_id in structured_re_slice_ids:
            errors.append(f"duplicate structured RE balance slice id: {row_id}")
        structured_re_slice_ids.add(row_id)
        try:
            order = int(row.get("order", ""))
        except ValueError:
            errors.append(f"{row_id}: order is not an integer")
            order = -1
        if order != index:
            errors.append(f"{row_id}: order is {order}; expected {index}")
        if 1 <= order <= 100:
            structured_re_slice_orders.add(order)
        expected_id = f"SR{index:03d}"
        if row_id != expected_id:
            errors.append(f"{row_id}: expected slice_id {expected_id}")
        wave = row.get("wave")
        expected_wave = STRUCTURED_RE_BALANCE_WAVES[(index - 1) // 10]
        if wave != expected_wave:
            errors.append(f"{row_id}: wave is {wave!r}; expected {expected_wave!r}")
        if wave in structured_re_wave_counts:
            structured_re_wave_counts[wave] += 1
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
            str(row.get(field, "")) for field in STRUCTURED_RE_BALANCE_SLICE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if status in {"banked", "verified"} and not evidence_reference_exists(
            row.get("evidence_url", "")
        ):
            errors.append(f"{row_id}: banked/verified structured RE slice row lacks evidence")
        dependencies = row.get("depends_on", "")
        if dependencies != "none":
            for dependency in dependencies.split(";"):
                if not re.match(r"^SR[0-9]{3}$", dependency):
                    errors.append(
                        f"{row_id}: dependency {dependency!r} must look like SR001"
                    )
                elif dependency not in structured_re_slice_ids:
                    errors.append(
                        f"{row_id}: dependency {dependency!r} must refer to an earlier row"
                    )
    if structured_re_slice_orders != set(range(1, 101)):
        errors.append("structured-re-balance-100-slices.tsv orders are not exactly 1:100")
    for wave, count in structured_re_wave_counts.items():
        if count != 10:
            errors.append(
                f"structured-re-balance-100-slices.tsv wave {wave!r} has "
                f"{count} rows; expected 10"
            )

    if len(structured_re_finish_slice_rows) != 100:
        errors.append(
            "structured-re-finish-100-slices.tsv has "
            f"{len(structured_re_finish_slice_rows)} rows; expected 100"
        )
    structured_re_finish_ids: set[str] = set()
    structured_re_finish_orders: set[int] = set()
    structured_re_finish_wave_counts = {wave: 0 for wave in STRUCTURED_RE_FINISH_WAVES}
    for index, row in enumerate(structured_re_finish_slice_rows, start=1):
        row_id = row.get("slice_id", f"<structured RE finish slice {index}>")
        if set(row.keys()) != set(STRUCTURED_RE_BALANCE_SLICE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-finish-100-slices.tsv fields "
                "do not match the ledger contract"
            )
        if not re.match(r"^SR[0-9]{3}$", row_id):
            errors.append(f"{row_id}: finish slice_id must look like SR101")
        elif row_id in structured_re_finish_ids:
            errors.append(f"duplicate structured RE finish slice id: {row_id}")
        structured_re_finish_ids.add(row_id)
        try:
            order = int(row.get("order", ""))
        except ValueError:
            errors.append(f"{row_id}: order is not an integer")
            order = -1
        expected_order = index + 100
        if order != expected_order:
            errors.append(f"{row_id}: order is {order}; expected {expected_order}")
        if 101 <= order <= 200:
            structured_re_finish_orders.add(order)
        expected_id = f"SR{index + 100:03d}"
        if row_id != expected_id:
            errors.append(f"{row_id}: expected finish slice_id {expected_id}")
        wave = row.get("wave")
        expected_wave = STRUCTURED_RE_FINISH_WAVES[(index - 1) // 10]
        if wave != expected_wave:
            errors.append(f"{row_id}: wave is {wave!r}; expected {expected_wave!r}")
        if wave in structured_re_finish_wave_counts:
            structured_re_finish_wave_counts[wave] += 1
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
            str(row.get(field, "")) for field in STRUCTURED_RE_BALANCE_SLICE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if status in {"banked", "verified"} and not evidence_reference_exists(
            row.get("evidence_url", "")
        ):
            errors.append(f"{row_id}: banked/verified structured RE finish row lacks evidence")
        dependencies = row.get("depends_on", "")
        if dependencies != "none":
            for dependency in dependencies.split(";"):
                if not re.match(r"^SR[0-9]{3}$", dependency):
                    errors.append(
                        f"{row_id}: dependency {dependency!r} must look like SR101"
                    )
                elif dependency not in structured_re_finish_ids:
                    errors.append(
                        f"{row_id}: dependency {dependency!r} must refer to an earlier finish row"
                    )
    if structured_re_finish_orders != set(range(101, 201)):
        errors.append("structured-re-finish-100-slices.tsv orders are not exactly 101:200")
    for wave, count in structured_re_finish_wave_counts.items():
        if count != 10:
            errors.append(
                f"structured-re-finish-100-slices.tsv wave {wave!r} has "
                f"{count} rows; expected 10"
            )

    member_ids: set[str] = set()
    roster_names: set[str] = set()
    if len(member_roster_rows) != len(STANDING_REVIEW_NAMES):
        errors.append(
            f"member-roster.tsv has {len(member_roster_rows)} rows; "
            f"expected {len(STANDING_REVIEW_NAMES)}"
        )
    for row in member_roster_rows:
        row_id = row.get("member_id", "<member>")
        if set(row.keys()) != set(MEMBER_ROSTER_FIELDS):
            errors.append(f"{row_id}: member-roster.tsv fields do not match the roster contract")
        if not re.match(r"^[a-z][a-z0-9_]*$", row_id):
            errors.append(f"{row_id}: member_id must be a lowercase slug")
        elif row_id in member_ids:
            errors.append(f"duplicate member_id: {row_id}")
        member_ids.add(row_id)
        name = row.get("canonical_name")
        if name not in STANDING_REVIEW_NAMES:
            errors.append(f"{row_id}: canonical_name is not a standing reviewer: {name!r}")
        roster_names.add(name)
        role_slug = row.get("role_slug")
        expected_agent = MEMBER_ROLE_TO_AGENT.get(role_slug)
        if expected_agent is None:
            errors.append(f"{row_id}: role_slug is not recognized: {role_slug!r}")
        elif row.get("launchable_agent") != expected_agent:
            errors.append(
                f"{row_id}: launchable_agent is {row.get('launchable_agent')!r}; "
                f"expected {expected_agent!r}"
            )
        launchable_agent = row.get("launchable_agent", "")
        if launchable_agent:
            codex_agent = ROOT / ".codex" / "agents" / f"{launchable_agent}.toml"
            claude_agent = ROOT / ".claude" / "agents" / f"{launchable_agent}.md"
            if not codex_agent.exists():
                errors.append(f"{row_id}: missing Codex launchable agent {rel_path(codex_agent)}")
            if not claude_agent.exists():
                errors.append(f"{row_id}: missing Claude launchable agent {rel_path(claude_agent)}")
        if row.get("status") not in MEMBER_STATUSES:
            errors.append(f"{row_id}: invalid member status {row.get('status')!r}")
        for field in MEMBER_ROSTER_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        for wave_range in member_list(row.get("current_waves", "")):
            if not re.match(r"^SC[0-9]{3}-SC[0-9]{3}$", wave_range):
                errors.append(f"{row_id}: current wave {wave_range!r} must look like SC201-SC210")
        if not evidence_reference_exists(row.get("source_ref", "")):
            errors.append(f"{row_id}: source_ref does not resolve to local evidence")
    missing_roster_names = sorted(STANDING_REVIEW_NAMES - roster_names)
    if missing_roster_names:
        errors.append("member-roster.tsv lacks standing reviewers: " + ", ".join(missing_roster_names))

    structured_re_conversion_ids: set[str] = set()
    structured_re_conversion_orders: set[int] = set()
    structured_re_conversion_wave_counts = {wave: 0 for wave in STRUCTURED_RE_CONVERSION_WAVES}
    if len(structured_re_conversion_slice_rows) != 200:
        errors.append(
            "structured-re-conversion-200-slices.tsv has "
            f"{len(structured_re_conversion_slice_rows)} rows; expected 200"
        )
    for index, row in enumerate(structured_re_conversion_slice_rows, start=1):
        row_id = row.get("slice_id", f"<structured RE conversion slice {index}>")
        if set(row.keys()) != set(STRUCTURED_RE_CONVERSION_SLICE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-conversion-200-slices.tsv fields "
                "do not match the ledger contract"
            )
        if not re.match(r"^SC[0-9]{3}$", row_id):
            errors.append(f"{row_id}: conversion slice_id must look like SC201")
        elif row_id in structured_re_conversion_ids:
            errors.append(f"duplicate structured RE conversion slice id: {row_id}")
        structured_re_conversion_ids.add(row_id)
        try:
            order = int(row.get("order", ""))
        except ValueError:
            errors.append(f"{row_id}: order is not an integer")
            order = -1
        expected_order = index + 200
        if order != expected_order:
            errors.append(f"{row_id}: order is {order}; expected {expected_order}")
        if 201 <= order <= 400:
            structured_re_conversion_orders.add(order)
        expected_id = f"SC{index + 200:03d}"
        if row_id != expected_id:
            errors.append(f"{row_id}: expected conversion slice_id {expected_id}")
        wave = row.get("wave")
        expected_wave = STRUCTURED_RE_CONVERSION_WAVES[(index - 1) // 10]
        if wave != expected_wave:
            errors.append(f"{row_id}: wave is {wave!r}; expected {expected_wave!r}")
        if wave in structured_re_conversion_wave_counts:
            structured_re_conversion_wave_counts[wave] += 1
        for field in (
            "area",
            "repo",
            "route",
            "primary_gate",
            "claim_boundary",
            "next_action",
            "lead_member",
            "required_members",
            "bank_condition",
        ):
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("status") not in SLICE_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("lead_member") not in member_ids:
            errors.append(f"{row_id}: lead_member {row.get('lead_member')!r} is not in member roster")
        for member_id in member_list(row.get("required_members", "")):
            if member_id not in member_ids:
                errors.append(f"{row_id}: required member {member_id!r} is not in member roster")
        dependencies = row.get("depends_on", "")
        if dependencies == "none":
            if row_id != "SC201":
                errors.append(f"{row_id}: only SC201 may have no dependency")
        elif not re.match(r"^SC[0-9]{3}$", dependencies):
            errors.append(f"{row_id}: dependency {dependencies!r} must look like SC201")
        elif dependencies not in structured_re_conversion_ids:
            errors.append(f"{row_id}: dependency {dependencies!r} must refer to an earlier conversion row")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_CONVERSION_SLICE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if row.get("status") in {"banked", "verified"} and not evidence_reference_exists(
            row.get("evidence_url", "")
        ):
            errors.append(f"{row_id}: banked/verified conversion row lacks evidence")
    if structured_re_conversion_orders != set(range(201, 401)):
        errors.append("structured-re-conversion-200-slices.tsv orders are not exactly 201:400")
    for wave, count in structured_re_conversion_wave_counts.items():
        if count != 10:
            errors.append(
                f"structured-re-conversion-200-slices.tsv wave {wave!r} has "
                f"{count} rows; expected 10"
            )

    vocabulary_terms: set[str] = set()
    for row in structured_re_status_vocabulary_rows:
        row_id = row.get("term", "<structured vocabulary term>")
        if set(row.keys()) != set(STRUCTURED_RE_STATUS_VOCABULARY_FIELDS):
            errors.append(
                f"{row_id}: structured-re-status-vocabulary.tsv fields do not match the contract"
            )
        vocabulary_terms.add(row_id)
        if row_id not in STRUCTURED_RE_VOCABULARY_TERMS:
            errors.append(f"{row_id}: unexpected structured RE vocabulary term")
        if row.get("owner_member") not in member_ids:
            errors.append(f"{row_id}: owner_member {row.get('owner_member')!r} is not in member roster")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid vocabulary status {row.get('status')!r}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: vocabulary evidence_url does not resolve")
        for field in STRUCTURED_RE_STATUS_VOCABULARY_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        row_text = " ".join(str(row.get(field, "")) for field in STRUCTURED_RE_STATUS_VOCABULARY_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if vocabulary_terms != STRUCTURED_RE_VOCABULARY_TERMS:
        errors.append(
            "structured-re-status-vocabulary.tsv terms are not exactly: "
            + ", ".join(sorted(STRUCTURED_RE_VOCABULARY_TERMS))
        )

    if len(structured_re_q1_bridge_payload_contract_rows) < len(STRUCTURED_RE_Q1_TARGETS):
        errors.append(
            "structured-re-q1-bridge-payload-contract.tsv lacks required q1 target rows"
        )
    q1_payload_targets: set[str] = set()
    for row in structured_re_q1_bridge_payload_contract_rows:
        row_id = row.get("contract_id", "<q1 bridge payload contract>")
        if set(row.keys()) != set(STRUCTURED_RE_Q1_BRIDGE_PAYLOAD_CONTRACT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q1-bridge-payload-contract.tsv fields do not match the contract"
            )
        target = row.get("target", "")
        q1_payload_targets.add(target)
        if target not in STRUCTURED_RE_Q1_TARGETS:
            errors.append(f"{row_id}: target {target!r} is not a registered q1 target")
        if row.get("estimator") not in BRIDGE_SCHEMA_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if "matrix_digest" not in row.get("required_payload_fields", ""):
            errors.append(f"{row_id}: required_payload_fields must include matrix_digest")
        if "coverage_payload" not in row.get("unsupported_fields", ""):
            errors.append(f"{row_id}: unsupported_fields must keep coverage_payload explicit")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q1_BRIDGE_PAYLOAD_CONTRACT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q1_targets = sorted(STRUCTURED_RE_Q1_TARGETS - q1_payload_targets)
    if missing_q1_targets:
        errors.append(
            "structured-re-q1-bridge-payload-contract.tsv missing q1 targets: "
            + ", ".join(missing_q1_targets)
        )

    for row in structured_re_q1_reconstruction_map_rows:
        row_id = row.get("map_id", "<q1 reconstruction map>")
        if set(row.keys()) != set(STRUCTURED_RE_Q1_RECONSTRUCTION_MAP_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q1-reconstruction-map.tsv fields do not match the contract"
            )
        if "q1" not in row.get("target", ""):
            errors.append(f"{row_id}: target must be scoped to q1")
        if row.get("extractor") not in STRUCTURED_RE_Q1_EXTRACTORS:
            errors.append(f"{row_id}: unknown extractor {row.get('extractor')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not row.get("unavailable_status"):
            errors.append(f"{row_id}: unavailable_status is empty")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q1_RECONSTRUCTION_MAP_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_q1_parity_fixture_contract_rows:
        row_id = row.get("fixture_id", "<q1 parity fixture contract>")
        if set(row.keys()) != set(STRUCTURED_RE_Q1_PARITY_FIXTURE_CONTRACT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q1-parity-fixture-contract.tsv fields do not match the contract"
            )
        if "q1" not in row.get("target", ""):
            errors.append(f"{row_id}: target must be scoped to q1")
        if not evidence_reference_exists(row.get("native_r_path", "")):
            errors.append(f"{row_id}: native_r_path does not resolve")
        if not evidence_reference_exists(row.get("direct_drmjl_path", "")):
            errors.append(f"{row_id}: direct_drmjl_path does not resolve")
        if row.get("r_via_julia_path") != "planned" and not evidence_reference_exists(
            row.get("r_via_julia_path", "")
        ):
            errors.append(f"{row_id}: r_via_julia_path must be planned or resolve")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q1_PARITY_FIXTURE_CONTRACT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_q2_target_contract_rows:
        row_id = row.get("target_id", "<q2 target contract>")
        if set(row.keys()) != set(STRUCTURED_RE_Q2_TARGET_CONTRACT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q2-target-contract.tsv fields do not match the contract"
            )
        if row.get("dimension") not in STRUCTURED_RE_Q2_TARGET_DIMENSIONS:
            errors.append(f"{row_id}: invalid dimension {row.get('dimension')!r}")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if not row.get("separated_from"):
            errors.append(f"{row_id}: separated_from is empty")
        if row.get("dimension") == "q2" and "q4" not in row.get("separated_from", ""):
            errors.append(f"{row_id}: q2 rows must explicitly separate from q4")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q2_TARGET_CONTRACT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_q2_native_evidence_rows:
        row_id = row.get("evidence_id", "<q2 native evidence>")
        if set(row.keys()) != set(STRUCTURED_RE_Q2_NATIVE_EVIDENCE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q2-native-evidence.tsv fields do not match the contract"
            )
        if row.get("structured_type") not in STRUCTURED_RE_TYPES - {"phylo_interaction"}:
            errors.append(f"{row_id}: invalid structured_type {row.get('structured_type')!r}")
        if row.get("dimension") != "q2":
            errors.append(f"{row_id}: dimension must be q2")
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("inference_status") not in {"point_only", "unsupported"}:
            errors.append(f"{row_id}: inference_status must stay point_only or unsupported")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q2_NATIVE_EVIDENCE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_q2_bridge_boundary_rows:
        row_id = row.get("boundary_id", "<q2 bridge boundary>")
        if set(row.keys()) != set(STRUCTURED_RE_Q2_BRIDGE_BOUNDARY_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q2-bridge-boundary.tsv fields do not match the contract"
            )
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not row.get("negative_evidence"):
            errors.append(f"{row_id}: negative_evidence is empty")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q2_BRIDGE_BOUNDARY_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_q4_target_contract_rows:
        row_id = row.get("target_id", "<q4 target contract>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_TARGET_CONTRACT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-target-contract.tsv fields do not match the contract"
            )
        if row.get("estimator") not in Q4_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("interval_status") not in {"not_evaluated", "unsupported"}:
            errors.append(f"{row_id}: interval_status must stay not_evaluated or unsupported")
        if "q4" not in row_id:
            errors.append(f"{row_id}: q4 target id must include q4")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_TARGET_CONTRACT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_q4_extractor_parity_rows:
        row_id = row.get("extractor_id", "<q4 extractor parity>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_EXTRACTOR_PARITY_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-extractor-parity.tsv fields do not match the contract"
            )
        if "q4" not in row.get("target", ""):
            errors.append(f"{row_id}: target must be scoped to q4")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("interval_status") not in {"not_available", "not_evaluated"}:
            errors.append(f"{row_id}: interval_status must remain unavailable or not evaluated")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_EXTRACTOR_PARITY_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_q4_bridge_boundary_rows:
        row_id = row.get("boundary_id", "<q4 bridge boundary>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_BRIDGE_BOUNDARY_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-bridge-boundary.tsv fields do not match the contract"
            )
        if "q4" not in row.get("target", ""):
            errors.append(f"{row_id}: target must be scoped to q4")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not row.get("parity_required"):
            errors.append(f"{row_id}: parity_required is empty")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_BRIDGE_BOUNDARY_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_reml_scope_gate_rows:
        row_id = row.get("gate_id", "<REML scope gate>")
        if set(row.keys()) != set(STRUCTURED_RE_REML_SCOPE_GATE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-reml-scope-gate.tsv fields do not match the contract"
            )
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not row.get("allowed_wording") or not row.get("forbidden_wording"):
            errors.append(f"{row_id}: allowed_wording and forbidden_wording must be explicit")
        if row.get("target", "").startswith("count") and "non-Gaussian REML" not in row.get(
            "forbidden_wording", ""
        ):
            errors.append(f"{row_id}: count routes must forbid non-Gaussian REML")
        if "q4" in row.get("target", "") and "HSquared" not in row.get("forbidden_wording", ""):
            errors.append(f"{row_id}: q4 rows must forbid HSquared AI-REML relabeling")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_REML_SCOPE_GATE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    ademp_dimensions: set[str] = set()
    for row in structured_re_ademp_design_rows:
        row_id = row.get("design_id", "<ADEMP design>")
        if set(row.keys()) != set(STRUCTURED_RE_ADEMP_DESIGN_FIELDS):
            errors.append(
                f"{row_id}: structured-re-ademp-design.tsv fields do not match the contract"
            )
        dimension = row.get("dimension", "")
        ademp_dimensions.add(dimension)
        if dimension not in {"q1", "q2", "q4"}:
            errors.append(f"{row_id}: dimension must be q1, q2, or q4")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if "MCSE" not in row.get("mcse_target", "") and "mcse" not in row.get("mcse_target", ""):
            errors.append(f"{row_id}: mcse_target must name MCSE")
        if "denominator" not in row.get("failed_fit_policy", ""):
            errors.append(f"{row_id}: failed_fit_policy must keep failures in denominators")
        if row.get("dimension") == "q4" and "No q4 interval coverage" not in row.get(
            "interval_policy", ""
        ):
            errors.append(f"{row_id}: q4 interval_policy must block coverage claims")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_ADEMP_DESIGN_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if ademp_dimensions != {"q1", "q2", "q4"}:
        errors.append("structured-re-ademp-design.tsv must include q1, q2, and q4 designs")

    type_gap_seen: set[str] = set()
    for row in structured_re_type_gap_rows:
        row_id = row.get("gap_id", "<structured type gap>")
        if set(row.keys()) != set(STRUCTURED_RE_TYPE_GAP_FIELDS):
            errors.append(
                f"{row_id}: structured-re-type-gaps.tsv fields do not match the contract"
            )
        structured_type = row.get("structured_type", "")
        type_gap_seen.add(structured_type)
        if structured_type not in STRUCTURED_RE_TYPES:
            errors.append(f"{row_id}: invalid structured_type {structured_type!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not row.get("missing_cell"):
            errors.append(f"{row_id}: missing_cell is empty")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(str(row.get(field, "")) for field in STRUCTURED_RE_TYPE_GAP_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if type_gap_seen != STRUCTURED_RE_TYPES:
        errors.append("structured-re-type-gaps.tsv must include every structured RE type")

    for row in structured_re_r_docs_api_sync_rows:
        row_id = row.get("sync_id", "<R docs/API sync>")
        if set(row.keys()) != set(STRUCTURED_RE_R_DOCS_API_SYNC_FIELDS):
            errors.append(
                f"{row_id}: structured-re-r-docs-api-sync.tsv fields do not match the contract"
            )
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not row.get("missing_or_deferred"):
            errors.append(f"{row_id}: missing_or_deferred is empty")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_R_DOCS_API_SYNC_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_julia_twin_sync_rows:
        row_id = row.get("sync_id", "<Julia twin sync>")
        if set(row.keys()) != set(STRUCTURED_RE_JULIA_TWIN_SYNC_FIELDS):
            errors.append(
                f"{row_id}: structured-re-julia-twin-sync.tsv fields do not match the contract"
            )
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("repo") not in {"DRM.jl", "drmTMB", "drmTMB+DRM.jl"}:
            errors.append(f"{row_id}: invalid repo {row.get('repo')!r}")
        if row.get("head") == "unknown" and "parked" not in row_id:
            errors.append(f"{row_id}: active twin rows must name a head")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_JULIA_TWIN_SYNC_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_closeout_package_rows:
        row_id = row.get("closeout_id", "<structured closeout package>")
        if set(row.keys()) != set(STRUCTURED_RE_CLOSEOUT_PACKAGE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-closeout-package.tsv fields do not match the contract"
            )
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_CLOSEOUT_PACKAGE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    if len(member_wave_assignment_rows) != len(STRUCTURED_RE_CONVERSION_WAVES):
        errors.append(
            f"member-wave-assignments.tsv has {len(member_wave_assignment_rows)} rows; "
            f"expected {len(STRUCTURED_RE_CONVERSION_WAVES)}"
        )
    for index, row in enumerate(member_wave_assignment_rows):
        row_id = row.get("wave_id", f"<member wave {index + 1}>")
        if set(row.keys()) != set(MEMBER_WAVE_ASSIGNMENT_FIELDS):
            errors.append(f"{row_id}: member-wave-assignments.tsv fields do not match the assignment contract")
        expected_wave = STRUCTURED_RE_CONVERSION_WAVES[index]
        expected_id = slug(expected_wave)
        expected_range = f"SC{201 + index * 10:03d}-SC{210 + index * 10:03d}"
        if row_id != expected_id:
            errors.append(f"{row_id}: expected wave_id {expected_id!r}")
        if row.get("slice_range") != expected_range:
            errors.append(
                f"{row_id}: slice_range is {row.get('slice_range')!r}; expected {expected_range!r}"
            )
        if row.get("lead_member") not in member_ids:
            errors.append(f"{row_id}: lead_member {row.get('lead_member')!r} is not in member roster")
        for field in ("required_members", "optional_members"):
            for member_id in member_list(row.get(field, "")):
                if member_id not in member_ids:
                    errors.append(f"{row_id}: {field} member {member_id!r} is not in member roster")
        for field in ("bank_condition", "blocked_condition"):
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")

    discussion_member_ids: set[str] = set()
    discussion_keys: set[tuple[str, str, str]] = set()
    for row in member_discussion_rows:
        row_id = (
            row.get("meeting_id", "<meeting>"),
            row.get("slice_id", "<slice>"),
            row.get("member_id", "<member>"),
        )
        if set(row.keys()) != set(MEMBER_DISCUSSION_FIELDS):
            errors.append(f"{row_id}: member-discussions.tsv fields do not match the discussion contract")
        if row_id in discussion_keys:
            errors.append(f"duplicate member discussion row: {row_id}")
        discussion_keys.add(row_id)
        member_id = row.get("member_id")
        discussion_member_ids.add(member_id)
        if member_id not in member_ids:
            errors.append(f"{row_id}: member_id {member_id!r} is not in member roster")
        slice_id = row.get("slice_id", "")
        if slice_id not in structured_re_conversion_ids:
            errors.append(f"{row_id}: slice_id {slice_id!r} is not in SC201-SC400")
        if row.get("stance") not in MEMBER_DISCUSSION_STANCES:
            errors.append(f"{row_id}: invalid stance {row.get('stance')!r}")
        if row.get("decision_status") not in MEMBER_DISCUSSION_DECISIONS:
            errors.append(f"{row_id}: invalid decision_status {row.get('decision_status')!r}")
        for field in MEMBER_DISCUSSION_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if not evidence_reference_exists(row.get("evidence_path", "")):
            errors.append(f"{row_id}: evidence_path does not resolve to local evidence")
        row_text = " ".join(str(row.get(field, "")) for field in MEMBER_DISCUSSION_FIELDS)
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_discussion_members = sorted(member_ids - discussion_member_ids)
    if missing_discussion_members:
        errors.append(
            "member-discussions.tsv lacks member discussion rows for: "
            + ", ".join(missing_discussion_members)
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
        f", {len(structured_re_balance_matrix_rows)} structured RE matrix rows"
        f", {len(structured_re_balance_slice_rows)} structured RE balance-slice rows"
        f", {len(structured_re_finish_slice_rows)} structured RE finish-slice rows"
        f", {len(member_roster_rows)} member roster rows"
        f", {len(member_discussion_rows)} member discussion rows"
        f", {len(member_wave_assignment_rows)} member wave-assignment rows"
        f", {len(structured_re_conversion_slice_rows)} structured RE conversion rows"
        f", {len(structured_re_status_vocabulary_rows)} structured RE vocabulary rows"
        f", {len(structured_re_q1_bridge_payload_contract_rows)} q1 payload-contract rows"
        f", {len(structured_re_q1_reconstruction_map_rows)} q1 reconstruction-map rows"
        f", {len(structured_re_q1_parity_fixture_contract_rows)} q1 parity-fixture rows"
        f", {len(structured_re_q2_target_contract_rows)} q2 target-contract rows"
        f", {len(structured_re_q2_native_evidence_rows)} q2 native-evidence rows"
        f", {len(structured_re_q2_bridge_boundary_rows)} q2 bridge-boundary rows"
        f", {len(structured_re_q4_target_contract_rows)} q4 target-contract rows"
        f", {len(structured_re_q4_extractor_parity_rows)} q4 extractor-parity rows"
        f", {len(structured_re_q4_bridge_boundary_rows)} q4 bridge-boundary rows"
        f", {len(structured_re_reml_scope_gate_rows)} REML scope-gate rows"
        f", {len(structured_re_ademp_design_rows)} ADEMP design rows"
        f", {len(structured_re_type_gap_rows)} structured type-gap rows"
        f", {len(structured_re_r_docs_api_sync_rows)} R docs/API sync rows"
        f", {len(structured_re_julia_twin_sync_rows)} Julia twin-sync rows"
        f", {len(structured_re_closeout_package_rows)} closeout-package rows"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
