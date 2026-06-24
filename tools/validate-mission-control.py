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
STRUCTURED_RE_Q_SERIES_SUPPORT_CELLS = (
    DASHBOARD / "structured-re-q-series-support-cells.tsv"
)
STRUCTURED_RE_MU_SLOPE_FIXTURE_AUDIT = (
    DASHBOARD / "structured-re-mu-slope-fixture-audit.tsv"
)
STRUCTURED_RE_MU_SLOPE_PARITY_FIXTURE = (
    DASHBOARD / "structured-re-mu-slope-parity-fixture.tsv"
)
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
STRUCTURED_RE_Q2_PAYLOAD_CONTRACT = DASHBOARD / "structured-re-q2-payload-contract.tsv"
STRUCTURED_RE_Q2_PAYLOAD_PROVENANCE = DASHBOARD / "structured-re-q2-payload-provenance.tsv"
STRUCTURED_RE_Q2_COEFFICIENT_ORDER_MAP = DASHBOARD / "structured-re-q2-coefficient-order-map.tsv"
STRUCTURED_RE_Q2_DIRECT_DRMJL_EXPORT = DASHBOARD / "structured-re-q2-direct-drmjl-export.tsv"
STRUCTURED_RE_Q2_ACCEPTANCE_GATE = DASHBOARD / "structured-re-q2-acceptance-gate.tsv"
STRUCTURED_RE_Q4_TARGET_CONTRACT = DASHBOARD / "structured-re-q4-target-contract.tsv"
STRUCTURED_RE_Q4_PHYLOCOV_TARGET_MAP = DASHBOARD / "structured-re-q4-phylocov-target-map.tsv"
STRUCTURED_RE_Q4_PROFILE_TARGET_BRIDGE_MAP = (
    DASHBOARD / "structured-re-q4-profile-target-bridge-map.tsv"
)
STRUCTURED_RE_Q4_SCALE_AXIS_INTERVAL_FAILURES = (
    DASHBOARD / "structured-re-q4-scale-axis-interval-failures.tsv"
)
STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_PLAN = (
    DASHBOARD / "structured-re-q4-interval-diagnostic-plan.tsv"
)
STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_STATUS = (
    DASHBOARD / "structured-re-q4-interval-diagnostic-status.tsv"
)
STRUCTURED_RE_Q4_CONVERGENCE_PROBE = DASHBOARD / "structured-re-q4-convergence-probe.tsv"
STRUCTURED_RE_Q4_BOUNDARY_SEPARATED_PROBE = (
    DASHBOARD / "structured-re-q4-boundary-separated-probe.tsv"
)
STRUCTURED_RE_Q4_HESSIAN_DIAGNOSTIC_STATUS = (
    DASHBOARD / "structured-re-q4-hessian-diagnostic-status.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_FIXTURE_DESIGN = (
    DASHBOARD / "structured-re-q4-stabilized-fixture-design.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_PREFLIGHT = (
    DASHBOARD / "structured-re-q4-stabilized-preflight.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_DENOMINATOR_EXTENSION = (
    DASHBOARD / "structured-re-q4-stabilized-denominator-extension.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_PROFILE_SMOKE = (
    DASHBOARD / "structured-re-q4-stabilized-profile-smoke.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_ALL_DIRECT_PROFILE = (
    DASHBOARD / "structured-re-q4-stabilized-all-direct-profile.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_PROFILE_DENOMINATOR_STATUS = (
    DASHBOARD / "structured-re-q4-stabilized-profile-denominator-status.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_ELIGIBLE_PROFILE = (
    DASHBOARD / "structured-re-q4-stabilized-eligible-profile.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_COVERAGE_DESIGN = (
    DASHBOARD / "structured-re-q4-stabilized-coverage-design.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_GRID_RUNNER_CONTRACT = (
    DASHBOARD / "structured-re-q4-stabilized-grid-runner-contract.tsv"
)
STRUCTURED_RE_Q4_STABILIZED_GRID_SMOKE_STATUS = (
    DASHBOARD / "structured-re-q4-stabilized-grid-smoke-status.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_INTERVAL_CONTRACT = (
    DASHBOARD / "structured-re-q4-derived-correlation-interval-contract.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_INTERVAL_SMOKE = (
    DASHBOARD / "structured-re-q4-derived-correlation-interval-smoke.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_DIAGNOSTIC = (
    DASHBOARD / "structured-re-q4-derived-correlation-delta-diagnostic.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_CONTRACT = (
    DASHBOARD / "structured-re-q4-derived-correlation-delta-grid-contract.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_STATUS = (
    DASHBOARD / "structured-re-q4-derived-correlation-delta-grid-smoke-status.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_MINI_STATUS = (
    DASHBOARD / "structured-re-q4-derived-correlation-delta-grid-mini-status.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_ADEMP_CONTRACT = (
    DASHBOARD / "structured-re-q4-derived-correlation-delta-grid-ademp-contract.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_SMOKE = (
    DASHBOARD
    / "structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_SHARD_PLAN = (
    DASHBOARD
    / "structured-re-q4-derived-correlation-delta-grid-drac-shard-plan.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_PACK = (
    DASHBOARD
    / "structured-re-q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_REHEARSAL = (
    DASHBOARD
    / "structured-re-q4-derived-correlation-delta-grid-two-shard-rehearsal.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_REHEARSAL = (
    DASHBOARD
    / "structured-re-q4-derived-correlation-delta-grid-local-four-shard-rehearsal.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_EIGHT_SHARD_MEDIUM_REHEARSAL = (
    DASHBOARD
    / "structured-re-q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal.tsv"
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_SIXTEEN_SHARD_MCSE_PREGRID = (
    DASHBOARD
    / "structured-re-q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid.tsv"
)
Q4_STABILIZED_GRID_DRY_RUN = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-stabilized-calibrated-grid-dry-run.tsv"
)
Q4_STABILIZED_GRID_SMOKE_RESULTS = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-stabilized-calibrated-grid-smoke-results.tsv"
)
Q4_DERIVED_CORRELATION_INTERVAL_SMOKE_RESULTS = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-interval-smoke-results.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_DIAGNOSTIC_RESULTS = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-diagnostic-results.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_RESULTS = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-smoke-results.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_MINI_RESULTS = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-mini-results.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_ADEMP_DRY_RUN = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-ademp-dry-run.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_MANIFEST = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_RUN_LOG = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_SHARD_PLAN = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-drac-shard-plan.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_PACK = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-drac-dispatch-pack"
    / "q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_ARRAY_SCRIPT = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-drac-dispatch-pack"
    / "slurm"
    / "q4-derived-correlation-delta-grid-array.sbatch"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_WORKER_SCRIPT = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-drac-dispatch-pack"
    / "slurm"
    / "q4-derived-correlation-delta-grid-array-worker.sh"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_TOTORO_SCRIPT = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-drac-dispatch-pack"
    / "slurm"
    / "q4-derived-correlation-delta-grid-totoro-worker.sh"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_AGGREGATE_SCRIPT = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-drac-dispatch-pack"
    / "slurm"
    / "q4-derived-correlation-delta-grid-aggregate.sh"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_MANIFEST = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-two-shard-rehearsal"
    / "aggregate"
    / "q4-derived-correlation-delta-grid-two_shard_rehearsal-aggregate-manifest.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_SUMMARY = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-two-shard-rehearsal"
    / "aggregate"
    / "q4-derived-correlation-delta-grid-two_shard_rehearsal-aggregate-summary.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_AGGREGATE_MANIFEST = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-local-four-shard-rehearsal"
    / "aggregate"
    / "q4-derived-correlation-delta-grid-local_four_shard_rehearsal-aggregate-manifest.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_AGGREGATE_SUMMARY = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-local-four-shard-rehearsal"
    / "aggregate"
    / "q4-derived-correlation-delta-grid-local_four_shard_rehearsal-aggregate-summary.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_EIGHT_SHARD_MEDIUM_AGGREGATE_MANIFEST = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal"
    / "aggregate"
    / "q4-derived-correlation-delta-grid-local_eight_shard_medium_rehearsal-aggregate-manifest.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_EIGHT_SHARD_MEDIUM_AGGREGATE_SUMMARY = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal"
    / "aggregate"
    / "q4-derived-correlation-delta-grid-local_eight_shard_medium_rehearsal-aggregate-summary.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_SIXTEEN_SHARD_MCSE_PREGRID_AGGREGATE_MANIFEST = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid"
    / "aggregate"
    / "q4-derived-correlation-delta-grid-local_sixteen_shard_mcse_pregrid-aggregate-manifest.tsv"
)
Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_SIXTEEN_SHARD_MCSE_PREGRID_AGGREGATE_SUMMARY = (
    ROOT
    / "docs"
    / "dev-log"
    / "simulation-artifacts"
    / "2026-06-23-q4-stabilized-preflight"
    / "q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid"
    / "aggregate"
    / "q4-derived-correlation-delta-grid-local_sixteen_shard_mcse_pregrid-aggregate-summary.tsv"
)
STRUCTURED_RE_Q4_DIRECT_DRMJL_EXPORT = DASHBOARD / "structured-re-q4-direct-drmjl-export.tsv"
STRUCTURED_RE_Q4_DETERMINISTIC_FIXTURE = DASHBOARD / "structured-re-q4-deterministic-fixture.tsv"
STRUCTURED_RE_Q4_TOLERANCE_POLICY = DASHBOARD / "structured-re-q4-tolerance-policy.tsv"
STRUCTURED_RE_Q4_SAME_FIXTURE_PARITY_PROBE = (
    DASHBOARD / "structured-re-q4-same-fixture-parity-probe.tsv"
)
STRUCTURED_RE_Q4_CALIBRATED_PARITY_PROBE = (
    DASHBOARD / "structured-re-q4-calibrated-parity-probe.tsv"
)
STRUCTURED_RE_Q4_PARITY_ACCEPTANCE_GATE = DASHBOARD / "structured-re-q4-parity-acceptance-gate.tsv"
STRUCTURED_RE_Q4_EXTRACTOR_PARITY = DASHBOARD / "structured-re-q4-extractor-parity.tsv"
STRUCTURED_RE_Q4_CORPAIRS_PARITY_GATE = DASHBOARD / "structured-re-q4-corpairs-parity-gate.tsv"
STRUCTURED_RE_Q4_BRIDGE_BOUNDARY = DASHBOARD / "structured-re-q4-bridge-boundary.tsv"
STRUCTURED_RE_Q4_REML_REQUESTED_EFFECTIVE_AUDIT = (
    DASHBOARD / "structured-re-q4-reml-requested-effective-audit.tsv"
)
STRUCTURED_RE_REML_SCOPE_GATE = DASHBOARD / "structured-re-reml-scope-gate.tsv"
STRUCTURED_RE_ADEMP_DESIGN = DASHBOARD / "structured-re-ademp-design.tsv"
STRUCTURED_RE_COVERAGE_CALIBRATION_STATUS = (
    DASHBOARD / "structured-re-coverage-calibration-status.tsv"
)
STRUCTURED_RE_COVERAGE_ACCEPTANCE_GATE = (
    DASHBOARD / "structured-re-coverage-acceptance-gate.tsv"
)
STRUCTURED_RE_NATIVE_REML_SCOPE_STATUS = (
    DASHBOARD / "structured-re-native-reml-scope-status.tsv"
)
STRUCTURED_RE_SCOPE_GATE_STATUS = DASHBOARD / "structured-re-scope-gate-status.tsv"
STRUCTURED_RE_TYPE_GAPS = DASHBOARD / "structured-re-type-gaps.tsv"
STRUCTURED_RE_R_DOCS_API_SYNC = DASHBOARD / "structured-re-r-docs-api-sync.tsv"
STRUCTURED_RE_R_DOCS_SYNC_STATUS = DASHBOARD / "structured-re-r-docs-sync-status.tsv"
STRUCTURED_RE_JULIA_TWIN_SYNC = DASHBOARD / "structured-re-julia-twin-sync.tsv"
STRUCTURED_RE_JULIA_TWIN_STATUS = DASHBOARD / "structured-re-julia-twin-status.tsv"
STRUCTURED_RE_AYUMI_CLOSEOUT_STATUS = DASHBOARD / "structured-re-ayumi-closeout-status.tsv"
STRUCTURED_RE_CLOSEOUT_PACKAGE = DASHBOARD / "structured-re-closeout-package.tsv"
STRUCTURED_RE_EXECUTABLE_EVIDENCE = DASHBOARD / "structured-re-executable-evidence.tsv"
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
STRUCTURED_RE_Q_SERIES_SUPPORT_CELL_FIELDS = (
    "cell_id",
    "formula_cell",
    "family_class",
    "family",
    "structure_provider",
    "dimension_pattern",
    "endpoint_set",
    "slope_class",
    "covariance_layout",
    "route",
    "estimator_requested",
    "estimator_effective",
    "fit_status",
    "extractor_status",
    "bridge_status",
    "interval_status",
    "coverage_status",
    "authority_status",
    "evidence_url",
    "claim_boundary",
    "denominator_policy",
    "next_gate",
)
STRUCTURED_RE_MU_SLOPE_FIXTURE_AUDIT_FIELDS = (
    "audit_id",
    "formula_cell",
    "structure_provider",
    "family",
    "route",
    "estimator",
    "artifact_writer_status",
    "focused_test_status",
    "extractor_identity_status",
    "bridge_fixture_status",
    "interval_status",
    "coverage_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_MU_SLOPE_PARITY_FIXTURE_FIELDS = (
    "fixture_id",
    "formula_cell",
    "structured_type",
    "dimension",
    "endpoint",
    "slope_class",
    "estimator",
    "native_status",
    "direct_drmjl_status",
    "r_via_julia_status",
    "coefficient_order",
    "matrix_slot",
    "input_scale",
    "parity_status",
    "bridge_status",
    "interval_status",
    "coverage_status",
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
STRUCTURED_RE_Q2_PAYLOAD_CONTRACT_FIELDS = STRUCTURED_RE_Q1_BRIDGE_PAYLOAD_CONTRACT_FIELDS
STRUCTURED_RE_Q2_PAYLOAD_PROVENANCE_FIELDS = (
    "provenance_id",
    "target",
    "structured_type",
    "dimension",
    "route",
    "estimator",
    "payload_version",
    "source_repo",
    "source_branch",
    "source_head",
    "matrix_id",
    "matrix_digest",
    "matrix_slot",
    "input_scale",
    "missing_level_policy",
    "bridge_marshalling",
    "endpoint",
    "required_levels",
    "version_fields",
    "dirty_state_policy",
    "status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q2_COEFFICIENT_ORDER_MAP_FIELDS = (
    "map_id",
    "structured_type",
    "target",
    "route",
    "estimator",
    "coefficient_order",
    "fixed_effect_terms",
    "structured_terms",
    "correlation_terms",
    "extractor",
    "tolerance_quantity",
    "status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q2_DIRECT_DRMJL_EXPORT_FIELDS = (
    "export_id",
    "target",
    "structured_type",
    "dimension",
    "route",
    "estimator",
    "coefficient_order",
    "direct_status",
    "bridge_status",
    "unavailable_reason",
    "claim_boundary",
    "evidence_url",
    "next_gate",
)
STRUCTURED_RE_Q2_ACCEPTANCE_GATE_FIELDS = (
    "gate_id",
    "target",
    "structured_type",
    "dimension",
    "estimator",
    "native_status",
    "direct_drmjl_status",
    "r_via_julia_status",
    "tolerance_policy",
    "acceptance_status",
    "missing_evidence",
    "required_before_acceptance",
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
STRUCTURED_RE_Q4_PHYLOCOV_TARGET_MAP_FIELDS = (
    "map_id",
    "target",
    "target_kind",
    "axis",
    "axis_pair",
    "direct_sd_target",
    "log_cholesky_target",
    "correlation_target",
    "extractor",
    "estimator",
    "point_status",
    "interval_status",
    "bridge_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_PROFILE_TARGET_BRIDGE_MAP_FIELDS = (
    "map_id",
    "target",
    "axis",
    "native_profile_target",
    "bridge_profile_target",
    "direct_sd_target",
    "native_tmb_parameter",
    "native_profile_ready",
    "bridge_profile_ready",
    "interval_status",
    "negative_evidence",
    "status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_SCALE_AXIS_INTERVAL_FAILURES_FIELDS = (
    "failure_id",
    "target",
    "axis",
    "direct_sd_target",
    "native_tmb_status",
    "direct_drmjl_status",
    "r_via_julia_status",
    "failure_class",
    "interval_claim_status",
    "status",
    "bridge_status",
    "evidence_url",
    "source_evidence",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_PLAN_FIELDS = (
    "diagnostic_id",
    "slice_id",
    "target",
    "target_kind",
    "axis_pair",
    "direct_sd_target",
    "derived_correlation_target",
    "interval_methods",
    "required_fit_evidence",
    "required_interval_evidence",
    "denominator_fields",
    "current_blocker",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_STATUS_FIELDS = (
    "diagnostic_id",
    "slice_id",
    "target",
    "target_kind",
    "axis_pair",
    "direct_sd_target",
    "derived_correlation_target",
    "source_artifact",
    "observed_target_rows",
    "n_fit_ok",
    "n_converged",
    "n_pdhess",
    "n_finite_intervals",
    "interval_status",
    "failure_class",
    "interval_claim_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_CONVERGENCE_PROBE_FIELDS = (
    "probe_id",
    "slice_id",
    "target",
    "n_tip",
    "m",
    "replicate",
    "optimizer_preset",
    "fit_ok",
    "convergence",
    "converged",
    "pdHess",
    "elapsed_sec",
    "message",
    "diagnostic_class",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_BOUNDARY_SEPARATED_PROBE_FIELDS = (
    "probe_id",
    "slice_id",
    "target",
    "fixture",
    "n_tip",
    "m",
    "seed",
    "optimizer_preset",
    "fit_ok",
    "convergence",
    "converged",
    "pdHess",
    "elapsed_sec",
    "message",
    "min_direct_sd_estimate",
    "max_abs_derived_correlation",
    "diagnostic_class",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_HESSIAN_DIAGNOSTIC_STATUS_FIELDS = (
    "diagnostic_id",
    "slice_id",
    "target",
    "fixture",
    "optimizer_preset",
    "converged",
    "pdHess",
    "metric",
    "value",
    "diagnostic_class",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_FIXTURE_DESIGN_FIELDS = (
    "design_id",
    "slice_id",
    "target",
    "blocker",
    "evidence_input",
    "required_design_change",
    "acceptance_metric",
    "acceptance_threshold",
    "owner_members",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_PREFLIGHT_FIELDS = (
    "preflight_id",
    "slice_id",
    "target",
    "fixture",
    "seed",
    "n_tip",
    "n_each",
    "sd_scale",
    "corr_offdiag",
    "fit_ok",
    "convergence",
    "converged",
    "pdHess",
    "max_gradient",
    "min_direct_sd_estimate",
    "max_abs_derived_correlation",
    "finite_wald_direct_sd_intervals",
    "direct_sd_interval_status",
    "diagnostic_class",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_DENOMINATOR_EXTENSION_FIELDS = (
    "summary_id",
    "slice_id",
    "target",
    "fixture",
    "sd_scale",
    "n_total",
    "n_fit_ok",
    "n_converged",
    "n_pdhess",
    "n_finite_wald_direct_sd_intervals",
    "n_pdhess_false",
    "gradient_warning_rows",
    "min_direct_sd_pdhess_true",
    "max_abs_cor_pdhess_true",
    "denominator_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_PROFILE_SMOKE_FIELDS = (
    "smoke_id",
    "slice_id",
    "target",
    "fixture",
    "seed",
    "sd_scale",
    "parm",
    "fit_convergence",
    "pdHess",
    "max_gradient",
    "profile_precision",
    "profile_elapsed_sec",
    "lower",
    "upper",
    "profile_engine",
    "conf_status",
    "profile_boundary",
    "profile_message",
    "diagnostic_class",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_ALL_DIRECT_PROFILE_FIELDS = (
    "profile_id",
    "slice_id",
    "target",
    "fixture",
    "seed",
    "sd_scale",
    "axis",
    "parm",
    "fit_convergence",
    "pdHess",
    "max_gradient",
    "profile_precision",
    "profile_elapsed_sec",
    "lower",
    "upper",
    "profile_engine",
    "conf_status",
    "profile_boundary",
    "profile_message",
    "diagnostic_class",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_PROFILE_DENOMINATOR_STATUS_FIELDS = (
    "denominator_id",
    "slice_id",
    "target",
    "fixture",
    "seed",
    "sd_scale",
    "fit_ok",
    "converged",
    "pdHess",
    "max_gradient",
    "finite_wald_direct_sd_intervals",
    "profile_eligible",
    "profile_attempted",
    "direct_profile_rows",
    "profile_finite_rows",
    "profile_status",
    "blocker",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_ELIGIBLE_PROFILE_FIELDS = (
    "profile_id",
    "slice_id",
    "target",
    "fixture",
    "seed",
    "sd_scale",
    "axis",
    "parm",
    "fit_convergence",
    "pdHess",
    "max_gradient",
    "profile_precision",
    "fit_elapsed_sec",
    "profile_elapsed_sec",
    "lower",
    "upper",
    "profile_engine",
    "conf_status",
    "profile_boundary",
    "profile_message",
    "warning_context",
    "diagnostic_class",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_COVERAGE_DESIGN_FIELDS = (
    "design_id",
    "slice_id",
    "target",
    "design_component",
    "current_evidence",
    "required_next_artifact",
    "planned_n_rep",
    "denominator_policy",
    "warning_policy",
    "acceptance_metric",
    "blocked_until",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_GRID_RUNNER_CONTRACT_FIELDS = (
    "contract_id",
    "slice_id",
    "target",
    "executable",
    "mode",
    "output_artifact",
    "required_columns",
    "denominator_policy",
    "warning_policy",
    "validation_gate",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
Q4_STABILIZED_GRID_DRY_RUN_FIELDS = (
    "dry_run_id",
    "slice_id",
    "target",
    "requested_n_rep",
    "seed_start",
    "sd_scale_levels",
    "direct_sd_targets",
    "derived_correlation_targets",
    "denominator_fields",
    "warning_fields",
    "output_schema",
    "status",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_STABILIZED_GRID_SMOKE_STATUS_FIELDS = (
    "smoke_id",
    "slice_id",
    "target",
    "source_script",
    "output_artifact",
    "observed_replicates",
    "observed_target_rows",
    "direct_sd_rows",
    "derived_correlation_rows",
    "fit_status",
    "interval_status",
    "mcse_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
Q4_STABILIZED_GRID_SMOKE_RESULT_FIELDS = (
    "replicate_id",
    "seed",
    "sd_scale",
    "axis",
    "target_name",
    "target_kind",
    "true_value",
    "fit_status",
    "convergence",
    "converged",
    "pdHess",
    "max_gradient",
    "fit_elapsed_sec",
    "interval_method",
    "interval_status",
    "lower",
    "upper",
    "warning_context",
    "failure_reason",
    "coverage_indicator",
    "coverage_mcse",
    "failure_rate_mcse",
    "mcse_status",
    "claim_boundary",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_INTERVAL_CONTRACT_FIELDS = (
    "contract_id",
    "slice_id",
    "target",
    "axis_pair",
    "derived_correlation_target",
    "point_source",
    "interval_source",
    "current_interval_status",
    "reconstruction_route",
    "required_payload_fields",
    "required_methods",
    "denominator_policy",
    "mcse_policy",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_INTERVAL_SMOKE_FIELDS = (
    "smoke_id",
    "slice_id",
    "target",
    "axis_pair",
    "derived_correlation_target",
    "source_script",
    "output_artifact",
    "point_status",
    "profile_target_status",
    "interval_status",
    "interval_source",
    "denominator_policy",
    "mcse_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
Q4_DERIVED_CORRELATION_INTERVAL_SMOKE_RESULT_FIELDS = (
    "replicate_id",
    "seed",
    "sd_scale",
    "axis_pair",
    "target_name",
    "target_kind",
    "true_value",
    "estimate",
    "fit_status",
    "convergence",
    "converged",
    "pdHess",
    "max_gradient",
    "fit_elapsed_sec",
    "parameter",
    "from_dpar",
    "to_dpar",
    "class",
    "profile_target",
    "interval_method",
    "interval_status",
    "interval_source",
    "lower",
    "upper",
    "warning_context",
    "failure_reason",
    "coverage_indicator",
    "coverage_mcse",
    "failure_rate_mcse",
    "mcse_status",
    "claim_boundary",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_DIAGNOSTIC_FIELDS = (
    "diagnostic_id",
    "slice_id",
    "target",
    "axis_pair",
    "derived_correlation_target",
    "source_script",
    "output_artifact",
    "reconstruction_status",
    "report_match_status",
    "interval_method",
    "interval_status",
    "interval_source",
    "denominator_policy",
    "mcse_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
Q4_DERIVED_CORRELATION_DELTA_DIAGNOSTIC_RESULT_FIELDS = (
    "replicate_id",
    "seed",
    "sd_scale",
    "axis_pair",
    "target_name",
    "target_kind",
    "true_value",
    "corpairs_estimate",
    "report_estimate",
    "max_abs_report_corpairs_delta",
    "delta_se",
    "lower",
    "upper",
    "interval_method",
    "interval_status",
    "interval_source",
    "boundary_clamped",
    "gradient_l2",
    "finite_difference_step_min",
    "finite_difference_step_max",
    "theta_parameter_count",
    "theta_covariance_status",
    "fit_status",
    "convergence",
    "converged",
    "pdHess",
    "max_gradient",
    "fit_elapsed_sec",
    "warning_context",
    "coverage_indicator",
    "coverage_mcse",
    "failure_rate_mcse",
    "mcse_status",
    "claim_boundary",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_CONTRACT_FIELDS = (
    "contract_id",
    "slice_id",
    "target",
    "contract_component",
    "source_artifact",
    "required_input",
    "required_output_fields",
    "denominator_policy",
    "mcse_policy",
    "failure_policy",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_STATUS_FIELDS = (
    "smoke_id",
    "slice_id",
    "target",
    "smoke_component",
    "source_script",
    "output_artifact",
    "observed_replicates",
    "observed_target_rows",
    "finite_delta_rows",
    "retained_denominator_rows",
    "theta_report_status",
    "interval_status",
    "mcse_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_MINI_STATUS_FIELDS = (
    "mini_id",
    "slice_id",
    "target",
    "mini_component",
    "source_script",
    "output_artifact",
    "scale_levels",
    "observed_replicates",
    "observed_seed_scale_cells",
    "observed_target_rows",
    "finite_delta_rows",
    "retained_denominator_rows",
    "boundary_clamped_rows",
    "theta_report_status",
    "interval_status",
    "coverage_accounting_status",
    "mcse_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_ADEMP_CONTRACT_FIELDS = (
    "contract_id",
    "slice_id",
    "target",
    "contract_component",
    "source_script",
    "output_artifact",
    "planned_n_rep",
    "scale_levels",
    "planned_seed_scale_cells",
    "planned_target_rows",
    "coverage_mcse_threshold",
    "coverage_mcse_at_nominal",
    "failure_rate_reference",
    "failure_rate_mcse_at_reference",
    "denominator_policy",
    "boundary_clamp_policy",
    "mcse_policy",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_RESULT_FIELDS = (
    "replicate_id",
    "seed",
    "sd_scale",
    "axis_pair",
    "target_name",
    "target_kind",
    "true_value",
    "fit_status",
    "convergence",
    "converged",
    "pdHess",
    "max_gradient",
    "fit_elapsed_sec",
    "warning_context",
    "failure_reason",
    "theta_parameter_count",
    "theta_covariance_status",
    "corpairs_estimate",
    "report_estimate",
    "max_abs_report_corpairs_delta",
    "gradient_l2",
    "finite_difference_step_min",
    "finite_difference_step_max",
    "delta_se",
    "lower",
    "upper",
    "interval_method",
    "interval_status",
    "interval_source",
    "boundary_clamped",
    "coverage_indicator",
    "coverage_mcse",
    "failure_rate_mcse",
    "mcse_status",
    "claim_boundary",
)
Q4_DERIVED_CORRELATION_DELTA_GRID_MINI_RESULT_FIELDS = (
    Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_RESULT_FIELDS
)
Q4_DERIVED_CORRELATION_DELTA_GRID_ADEMP_DRY_RUN_FIELDS = (
    "dry_run_id",
    "slice_id",
    "target",
    "sd_scale",
    "axis_pair",
    "target_name",
    "target_kind",
    "true_value",
    "planned_n_rep",
    "seed_start",
    "seed_end",
    "planned_seed_scale_cells",
    "planned_target_rows",
    "nominal_coverage",
    "coverage_mcse_threshold",
    "coverage_mcse_at_nominal",
    "failure_rate_reference",
    "failure_rate_mcse_at_reference",
    "interval_method",
    "denominator_policy",
    "boundary_clamp_policy",
    "warning_policy",
    "failure_policy",
    "mcse_policy",
    "output_schema",
    "status",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_SMOKE_FIELDS = (
    "smoke_id",
    "slice_id",
    "target",
    "smoke_component",
    "source_script",
    "delegated_smoke_script",
    "contract_source",
    "manifest_artifact",
    "run_log_artifact",
    "cell_output_root",
    "observed_cells",
    "computed_actions",
    "skipped_actions",
    "observed_target_rows",
    "finite_delta_rows",
    "retained_denominator_rows",
    "boundary_clamped_rows",
    "denominator_policy",
    "resumability_status",
    "mcse_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_MANIFEST_FIELDS = (
    "manifest_id",
    "slice_id",
    "target",
    "source_script",
    "delegated_smoke_script",
    "contract_source",
    "output_root",
    "manifest_artifact",
    "run_log_artifact",
    "cell_outputs",
    "planned_n_rep",
    "scale_levels",
    "cell_limit",
    "observed_cells",
    "computed_actions",
    "skipped_actions",
    "observed_target_rows",
    "finite_delta_rows",
    "retained_denominator_rows",
    "warning_rows",
    "failure_rows",
    "boundary_clamped_rows",
    "coverage_evaluable_rows",
    "coverage_mcse",
    "failure_rate_mcse",
    "mcse_status",
    "resumability_status",
    "denominator_policy",
    "status",
    "claim_boundary",
    "next_gate",
)
Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_RUN_LOG_FIELDS = (
    "run_label",
    "cell_id",
    "slice_id",
    "target",
    "seed",
    "sd_scale",
    "cell_index",
    "cell_output",
    "action",
    "previous_output_detected",
    "child_status",
    "observed_target_rows",
    "finite_delta_rows",
    "retained_denominator_rows",
    "warning_rows",
    "failure_rows",
    "boundary_clamped_rows",
    "coverage_evaluable_rows",
    "coverage_mcse",
    "failure_rate_mcse",
    "mcse_status",
    "resumability_status",
    "denominator_policy",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_SHARD_PLAN_FIELDS = (
    "plan_id",
    "slice_id",
    "target",
    "plan_component",
    "source_script",
    "plan_artifact",
    "planned_n_rep",
    "scale_levels",
    "planned_workers",
    "planned_shards",
    "planned_seed_scale_cells",
    "planned_target_rows",
    "cells_per_shard",
    "write_isolation",
    "aggregate_gate",
    "mcse_policy",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_PACK_FIELDS = (
    "pack_id",
    "slice_id",
    "target",
    "pack_component",
    "source_script",
    "pack_manifest",
    "slurm_array_script",
    "worker_script",
    "totoro_worker_script",
    "aggregate_script",
    "planned_n_rep",
    "scale_levels",
    "planned_shards",
    "planned_drac_array_tasks",
    "planned_totoro_shards",
    "planned_seed_scale_cells",
    "planned_target_rows",
    "cells_per_shard",
    "scheduler_status",
    "compute_status",
    "storage_policy",
    "aggregate_gate",
    "mcse_policy",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_PACK_FIELDS = (
    "pack_id",
    "slice_id",
    "target",
    "pack_component",
    "artifact_path",
    "planned_n_rep",
    "scale_levels",
    "planned_shards",
    "planned_drac_array_tasks",
    "planned_totoro_shards",
    "planned_seed_scale_cells",
    "planned_target_rows",
    "scheduler",
    "scheduler_status",
    "compute_status",
    "account_placeholder",
    "time_limit",
    "mem",
    "cpus_per_task",
    "output_root",
    "aggregate_label",
    "aggregate_gate",
    "mcse_policy",
    "storage_policy",
    "status",
    "claim_boundary",
    "next_gate",
)
Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_SHARD_PLAN_FIELDS = (
    "shard_id",
    "slice_id",
    "target",
    "worker_label",
    "worker_role",
    "n_shards",
    "shard_index",
    "planned_n_rep",
    "seed_start",
    "seed_end",
    "scale_levels",
    "planned_total_cells",
    "planned_total_target_rows",
    "planned_shard_cells",
    "planned_shard_target_rows",
    "cell_index_min",
    "cell_index_max",
    "shard_output_root",
    "shard_manifest",
    "shard_run_log",
    "aggregate_manifest",
    "aggregate_summary",
    "runner_command",
    "resume_command",
    "write_isolation",
    "assignment_policy",
    "aggregate_gate",
    "denominator_policy",
    "coverage_mcse_at_nominal",
    "failure_rate_mcse_at_reference",
    "mcse_status",
    "status",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_REHEARSAL_FIELDS = (
    "rehearsal_id",
    "slice_id",
    "target",
    "rehearsal_component",
    "source_script",
    "aggregate_script",
    "aggregate_manifest",
    "aggregate_summary",
    "n_shards",
    "expected_cells",
    "unique_cells",
    "computed_actions",
    "skipped_actions",
    "observed_target_rows",
    "finite_delta_rows",
    "retained_denominator_rows",
    "boundary_clamped_rows",
    "coverage_evaluable_rows",
    "write_isolation",
    "aggregate_status",
    "mcse_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_REHEARSAL_FIELDS = (
    "rehearsal_id",
    "slice_id",
    "target",
    "rehearsal_component",
    "source_script",
    "aggregate_script",
    "aggregate_manifest",
    "aggregate_summary",
    "n_shards",
    "expected_cells",
    "unique_cells",
    "computed_actions",
    "skipped_actions",
    "observed_target_rows",
    "finite_delta_rows",
    "retained_denominator_rows",
    "warning_rows",
    "failure_rows",
    "boundary_clamped_rows",
    "coverage_evaluable_rows",
    "write_isolation",
    "aggregate_status",
    "mcse_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_MANIFEST_FIELDS = (
    "aggregate_id",
    "slice_id",
    "target",
    "n_shards",
    "shard_manifests",
    "shard_run_logs",
    "unique_cells",
    "computed_actions",
    "skipped_actions",
    "expected_cells",
    "expected_target_rows",
    "observed_target_rows",
    "finite_delta_rows",
    "retained_denominator_rows",
    "warning_rows",
    "failure_rows",
    "boundary_clamped_rows",
    "coverage_evaluable_rows",
    "coverage_mcse",
    "failure_rate_mcse",
    "mcse_status",
    "denominator_policy",
    "aggregate_status",
    "claim_boundary",
    "next_gate",
)
Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_SUMMARY_FIELDS = (
    "target_name",
    "observed_rows",
    "finite_delta_rows",
    "warning_rows",
    "failure_rows",
    "boundary_clamped_rows",
    "coverage_evaluable_rows",
    "retained_denominator_rows",
    "coverage_rate",
    "failure_rate",
    "warning_rate",
    "boundary_clamp_rate",
    "coverage_mcse",
    "failure_rate_mcse",
    "warning_rate_mcse",
    "boundary_clamp_rate_mcse",
    "aggregate_label",
    "mcse_status",
    "claim_boundary",
)
STRUCTURED_RE_Q4_DIRECT_DRMJL_EXPORT_FIELDS = (
    "export_id",
    "target",
    "axis",
    "dimension",
    "route",
    "estimator",
    "direct_sd_target",
    "sigma_a_source",
    "direct_status",
    "bridge_status",
    "inference_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_DETERMINISTIC_FIXTURE_FIELDS = (
    "fixture_id",
    "target",
    "n_species",
    "n_obs",
    "tree_id",
    "axes",
    "direct_sd_targets",
    "truth_status",
    "data_status",
    "fit_status",
    "bridge_status",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_TOLERANCE_POLICY_FIELDS = (
    "policy_id",
    "target",
    "quantity",
    "comparator_routes",
    "tolerance",
    "tolerance_scale",
    "required_fixture",
    "acceptance_use",
    "status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_SAME_FIXTURE_PARITY_PROBE_FIELDS = (
    "probe_id",
    "target",
    "fixture_id",
    "comparator_routes",
    "native_tmb_status",
    "direct_drmjl_status",
    "r_via_julia_status",
    "loglik_delta",
    "max_abs_cor_delta",
    "tolerance_result",
    "acceptance_status",
    "status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_CALIBRATED_PARITY_PROBE_FIELDS = (
    "probe_id",
    "target",
    "fixture_id",
    "seed",
    "n_tip",
    "n_each",
    "comparator_routes",
    "native_tmb_status",
    "direct_drmjl_status",
    "r_via_julia_status",
    "loglik_delta_native_bridge",
    "loglik_delta_direct_bridge",
    "max_abs_fixef_native_bridge",
    "max_abs_sd_native_bridge",
    "max_abs_sd_direct_bridge",
    "max_abs_cor_native_bridge",
    "max_abs_cor_direct_bridge",
    "tolerance_result",
    "acceptance_status",
    "reconstruction_status",
    "status",
    "bridge_status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_Q4_PARITY_ACCEPTANCE_GATE_FIELDS = (
    "gate_id",
    "target",
    "required_fixture",
    "required_quantities",
    "native_status",
    "direct_drmjl_status",
    "r_via_julia_status",
    "tolerance_policy",
    "acceptance_status",
    "missing_evidence",
    "status",
    "bridge_status",
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
STRUCTURED_RE_Q4_CORPAIRS_PARITY_GATE_FIELDS = (
    "gate_id",
    "target",
    "extractor",
    "native_status",
    "direct_drmjl_status",
    "r_via_julia_status",
    "parity_status",
    "missing_evidence",
    "required_before_acceptance",
    "status",
    "bridge_status",
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
STRUCTURED_RE_Q4_REML_REQUESTED_EFFECTIVE_AUDIT_FIELDS = (
    "audit_id",
    "target",
    "route",
    "requested_estimator",
    "effective_estimator",
    "effective_family",
    "fit_status",
    "point_status",
    "interval_status",
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
STRUCTURED_RE_COVERAGE_CALIBRATION_STATUS_FIELDS = (
    "calibration_id",
    "slice_id",
    "dimension",
    "calibration_surface",
    "artifact",
    "evidence_class",
    "grid_status",
    "interval_methods",
    "bootstrap_accounting",
    "mcse_policy",
    "failure_policy",
    "report_section",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_COVERAGE_ACCEPTANCE_GATE_FIELDS = (
    "gate_id",
    "slice_id",
    "dimension",
    "calibration_surface",
    "source_artifact",
    "gate_status",
    "planned_n_rep",
    "observed_target_rows",
    "finite_interval_rows",
    "mcse_status",
    "missing_evidence",
    "failure_policy",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_NATIVE_REML_SCOPE_STATUS_FIELDS = (
    "scope_id",
    "slice_id",
    "target",
    "route",
    "requested_estimator",
    "effective_estimator",
    "support_status",
    "diagnostic_fields",
    "negative_evidence",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_SCOPE_GATE_STATUS_FIELDS = (
    "gate_id",
    "slice_id",
    "wave",
    "target",
    "route_or_surface",
    "support_status",
    "evidence_class",
    "required_before_support",
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
STRUCTURED_RE_R_DOCS_SYNC_STATUS_FIELDS = (
    "sync_id",
    "slice_id",
    "surface",
    "source_file",
    "sync_status",
    "evidence_class",
    "required_terms",
    "deferred_terms",
    "scan_command",
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
STRUCTURED_RE_JULIA_TWIN_STATUS_FIELDS = (
    "sync_id",
    "slice_id",
    "repo",
    "branch",
    "head",
    "dirty_state",
    "surface",
    "evidence_class",
    "test_command",
    "test_result",
    "status",
    "evidence_url",
    "claim_boundary",
    "next_gate",
)
STRUCTURED_RE_AYUMI_CLOSEOUT_STATUS_FIELDS = (
    "gate_id",
    "slice_id",
    "gate",
    "requirement",
    "current_status",
    "evidence_class",
    "evidence_url",
    "status",
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
STRUCTURED_RE_EXECUTABLE_EVIDENCE_FIELDS = (
    "evidence_id",
    "scope",
    "artifact",
    "claim_status",
    "evidence_class",
    "evidence_path",
    "test_command",
    "status",
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
STRUCTURED_RE_Q2_PAYLOAD_TARGETS = {
    "gaussian_q2_mu1_mu2_phylo",
    "gaussian_q2_mu1_mu2_spatial",
    "gaussian_q2_mu1_mu2_animal",
    "gaussian_q2_mu1_mu2_relmat",
    "gaussian_q2_mu1_mu2_reml",
}
STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS = {
    "gaussian_q2_mu1_mu2_phylo",
    "gaussian_q2_mu1_mu2_spatial",
    "gaussian_q2_mu1_mu2_animal",
    "gaussian_q2_mu1_mu2_relmat",
}
STRUCTURED_RE_Q2_COEFFICIENT_ORDER = (
    "mu1:(Intercept);mu1:x;mu2:(Intercept);mu2:x;"
    "sd_mu1:structured(group);sd_mu2:structured(group);"
    "cor_mu1_mu2:structured(group)"
)
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
STRUCTURED_RE_Q_SERIES_PROVIDERS = STRUCTURED_RE_TYPES | {
    "ordinary",
    "all_structured",
}
STRUCTURED_RE_Q_SERIES_FAMILY_CLASSES = {
    "gaussian",
    "non_gaussian",
}
STRUCTURED_RE_Q_SERIES_DIMENSION_PATTERNS = {
    "q1",
    "q1_plus_q1",
    "q2",
    "q2_plus_q2",
    "q4",
    "q6",
    "q8",
}
STRUCTURED_RE_Q_SERIES_SLOPE_CLASSES = {
    "intercept_only",
    "independent_one_slope",
    "labelled_slope_covariance",
    "multiple_slope",
    "not_applicable",
}
STRUCTURED_RE_Q_SERIES_ROUTES = {
    "native_tmb",
    "native_direct_bridge_fixture",
    "planned",
    "unsupported",
}
STRUCTURED_RE_Q_SERIES_ESTIMATORS = {
    "ML",
    "ML_Laplace",
    "ML_or_REML",
    "REML",
    "not_applicable",
}
STRUCTURED_RE_Q_SERIES_STATUSES = {
    "planned",
    "unsupported",
    "parser_ready",
    "point_fit",
    "extractor_ready",
    "fixture_parity",
    "interval_feasible",
    "inference_ready",
    "supported",
    "diagnostic_only",
    "blocked",
}
STRUCTURED_RE_Q_SERIES_AUTHORITY_STATUSES = {
    "source",
    "derived",
    "stale",
    "superseded",
}
STRUCTURED_RE_REQUIRED_Q_SERIES_CELLS = {
    "qseries_ordinary_q1_intercept",
    "qseries_ordinary_q1_independent_slope",
    "qseries_ordinary_q2_mu1_mu2_intercept",
    "qseries_ordinary_q4_location_one_slope",
    "qseries_ordinary_q6_location_two_slopes",
    "qseries_ordinary_q8_all_endpoint_one_slope",
    "qseries_phylo_q1_mu_intercept",
    "qseries_phylo_q1_sigma_intercept",
    "qseries_phylo_q1_mu_sigma_intercept",
    "qseries_phylo_q1_mu_one_slope",
    "qseries_spatial_q1_mu_one_slope",
    "qseries_animal_q1_mu_one_slope",
    "qseries_relmat_q1_mu_one_slope",
    "qseries_phylo_q1_sigma_one_slope_planned",
    "qseries_spatial_q1_sigma_one_slope_planned",
    "qseries_animal_q1_sigma_one_slope_planned",
    "qseries_relmat_q1_sigma_one_slope_planned",
    "qseries_phylo_q2_mu1_mu2_intercept",
    "qseries_spatial_q2_mu1_mu2_intercept",
    "qseries_animal_q2_mu1_mu2_intercept",
    "qseries_relmat_q2_mu1_mu2_intercept",
    "qseries_phylo_q2_plus_q2_intercept",
    "qseries_spatial_q2_plus_q2_sigma_rejected",
    "qseries_animal_q2_plus_q2_sigma_rejected",
    "qseries_relmat_q2_plus_q2_sigma_rejected",
    "qseries_phylo_q4_all_four_intercept",
    "qseries_spatial_q4_all_four_intercept",
    "qseries_animal_q4_all_four_intercept",
    "qseries_relmat_q4_all_four_intercept",
    "qseries_phylo_q6_planned",
    "qseries_spatial_q6_planned",
    "qseries_animal_q6_planned",
    "qseries_relmat_q6_planned",
    "qseries_phylo_q8_planned",
    "qseries_spatial_q8_planned",
    "qseries_animal_q8_planned",
    "qseries_relmat_q8_planned",
    "qseries_phylo_interaction_q1_mu",
    "qseries_phylo_poisson_q1_mu_intercept",
    "qseries_phylo_nbinom2_q1_mu_intercept",
    "qseries_nongaussian_structured_slopes_planned",
    "qseries_phylo_direct_sd_univariate",
    "qseries_phylo_direct_sd_bivariate",
}
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


def expect_float_close(
    errors: list[str],
    row_id: str,
    field: str,
    actual: str | None,
    expected: float,
    tolerance: float = 1e-12,
) -> None:
    try:
        value = float(actual or "")
    except ValueError:
        errors.append(f"{row_id}: {field} must be numeric close to {expected!r}")
        return
    if abs(value - expected) > tolerance:
        errors.append(f"{row_id}: {field} must be close to {expected!r}")


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
    structured_re_q_series_support_cell_rows = read_tsv(
        STRUCTURED_RE_Q_SERIES_SUPPORT_CELLS
    )
    structured_re_mu_slope_fixture_audit_rows = read_tsv(
        STRUCTURED_RE_MU_SLOPE_FIXTURE_AUDIT
    )
    structured_re_mu_slope_parity_fixture_rows = read_tsv(
        STRUCTURED_RE_MU_SLOPE_PARITY_FIXTURE
    )
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
    structured_re_q2_payload_contract_rows = read_tsv(STRUCTURED_RE_Q2_PAYLOAD_CONTRACT)
    structured_re_q2_payload_provenance_rows = read_tsv(
        STRUCTURED_RE_Q2_PAYLOAD_PROVENANCE
    )
    structured_re_q2_coefficient_order_map_rows = read_tsv(
        STRUCTURED_RE_Q2_COEFFICIENT_ORDER_MAP
    )
    structured_re_q2_direct_drmjl_export_rows = read_tsv(
        STRUCTURED_RE_Q2_DIRECT_DRMJL_EXPORT
    )
    structured_re_q2_acceptance_gate_rows = read_tsv(
        STRUCTURED_RE_Q2_ACCEPTANCE_GATE
    )
    structured_re_q4_target_contract_rows = read_tsv(STRUCTURED_RE_Q4_TARGET_CONTRACT)
    structured_re_q4_phylocov_target_map_rows = read_tsv(
        STRUCTURED_RE_Q4_PHYLOCOV_TARGET_MAP
    )
    structured_re_q4_profile_target_bridge_map_rows = read_tsv(
        STRUCTURED_RE_Q4_PROFILE_TARGET_BRIDGE_MAP
    )
    structured_re_q4_scale_axis_interval_failure_rows = read_tsv(
        STRUCTURED_RE_Q4_SCALE_AXIS_INTERVAL_FAILURES
    )
    structured_re_q4_interval_diagnostic_plan_rows = read_tsv(
        STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_PLAN
    )
    structured_re_q4_interval_diagnostic_status_rows = read_tsv(
        STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_STATUS
    )
    structured_re_q4_convergence_probe_rows = read_tsv(STRUCTURED_RE_Q4_CONVERGENCE_PROBE)
    structured_re_q4_boundary_separated_probe_rows = read_tsv(
        STRUCTURED_RE_Q4_BOUNDARY_SEPARATED_PROBE
    )
    structured_re_q4_hessian_diagnostic_status_rows = read_tsv(
        STRUCTURED_RE_Q4_HESSIAN_DIAGNOSTIC_STATUS
    )
    structured_re_q4_stabilized_fixture_design_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_FIXTURE_DESIGN
    )
    structured_re_q4_stabilized_preflight_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_PREFLIGHT
    )
    structured_re_q4_stabilized_denominator_extension_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_DENOMINATOR_EXTENSION
    )
    structured_re_q4_stabilized_profile_smoke_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_PROFILE_SMOKE
    )
    structured_re_q4_stabilized_all_direct_profile_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_ALL_DIRECT_PROFILE
    )
    structured_re_q4_stabilized_profile_denominator_status_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_PROFILE_DENOMINATOR_STATUS
    )
    structured_re_q4_stabilized_eligible_profile_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_ELIGIBLE_PROFILE
    )
    structured_re_q4_stabilized_coverage_design_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_COVERAGE_DESIGN
    )
    structured_re_q4_stabilized_grid_runner_contract_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_GRID_RUNNER_CONTRACT
    )
    structured_re_q4_stabilized_grid_smoke_status_rows = read_tsv(
        STRUCTURED_RE_Q4_STABILIZED_GRID_SMOKE_STATUS
    )
    structured_re_q4_derived_correlation_interval_contract_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_INTERVAL_CONTRACT
    )
    structured_re_q4_derived_correlation_interval_smoke_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_INTERVAL_SMOKE
    )
    structured_re_q4_derived_correlation_delta_diagnostic_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_DIAGNOSTIC
    )
    structured_re_q4_derived_correlation_delta_grid_contract_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_CONTRACT
    )
    structured_re_q4_derived_correlation_delta_grid_smoke_status_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_STATUS
    )
    structured_re_q4_derived_correlation_delta_grid_mini_status_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_MINI_STATUS
    )
    structured_re_q4_derived_correlation_delta_grid_ademp_contract_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_ADEMP_CONTRACT
    )
    structured_re_q4_derived_correlation_delta_grid_resumable_smoke_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_SMOKE
    )
    structured_re_q4_derived_correlation_delta_grid_drac_shard_plan_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_SHARD_PLAN
    )
    structured_re_q4_derived_correlation_delta_grid_drac_dispatch_pack_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_PACK
    )
    structured_re_q4_derived_correlation_delta_grid_two_shard_rehearsal_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_REHEARSAL
    )
    structured_re_q4_derived_correlation_delta_grid_local_four_shard_rehearsal_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_REHEARSAL
    )
    structured_re_q4_derived_correlation_delta_grid_local_eight_shard_medium_rehearsal_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_EIGHT_SHARD_MEDIUM_REHEARSAL
    )
    structured_re_q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_rows = read_tsv(
        STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_SIXTEEN_SHARD_MCSE_PREGRID
    )
    q4_stabilized_grid_dry_run_rows = read_tsv(Q4_STABILIZED_GRID_DRY_RUN)
    q4_stabilized_grid_smoke_result_rows = read_tsv(Q4_STABILIZED_GRID_SMOKE_RESULTS)
    q4_derived_correlation_interval_smoke_result_rows = read_tsv(
        Q4_DERIVED_CORRELATION_INTERVAL_SMOKE_RESULTS
    )
    q4_derived_correlation_delta_diagnostic_result_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_DIAGNOSTIC_RESULTS
    )
    q4_derived_correlation_delta_grid_smoke_result_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_RESULTS
    )
    q4_derived_correlation_delta_grid_mini_result_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_MINI_RESULTS
    )
    q4_derived_correlation_delta_grid_ademp_dry_run_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_ADEMP_DRY_RUN
    )
    q4_derived_correlation_delta_grid_resumable_manifest_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_MANIFEST
    )
    q4_derived_correlation_delta_grid_resumable_run_log_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_RUN_LOG
    )
    q4_derived_correlation_delta_grid_drac_shard_plan_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_SHARD_PLAN
    )
    q4_derived_correlation_delta_grid_drac_dispatch_pack_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_PACK
    )
    q4_derived_correlation_delta_grid_drac_dispatch_array_script = (
        Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_ARRAY_SCRIPT.read_text(
            encoding="utf-8"
        )
    )
    q4_derived_correlation_delta_grid_drac_dispatch_worker_script = (
        Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_WORKER_SCRIPT.read_text(
            encoding="utf-8"
        )
    )
    q4_derived_correlation_delta_grid_drac_dispatch_totoro_script = (
        Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_TOTORO_SCRIPT.read_text(
            encoding="utf-8"
        )
    )
    q4_derived_correlation_delta_grid_drac_dispatch_aggregate_script = (
        Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_AGGREGATE_SCRIPT.read_text(
            encoding="utf-8"
        )
    )
    q4_derived_correlation_delta_grid_two_shard_aggregate_manifest_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_MANIFEST
    )
    q4_derived_correlation_delta_grid_two_shard_aggregate_summary_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_SUMMARY
    )
    q4_derived_correlation_delta_grid_local_four_shard_aggregate_manifest_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_AGGREGATE_MANIFEST
    )
    q4_derived_correlation_delta_grid_local_four_shard_aggregate_summary_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_AGGREGATE_SUMMARY
    )
    q4_derived_correlation_delta_grid_local_eight_shard_medium_aggregate_manifest_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_EIGHT_SHARD_MEDIUM_AGGREGATE_MANIFEST
    )
    q4_derived_correlation_delta_grid_local_eight_shard_medium_aggregate_summary_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_EIGHT_SHARD_MEDIUM_AGGREGATE_SUMMARY
    )
    q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate_manifest_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_SIXTEEN_SHARD_MCSE_PREGRID_AGGREGATE_MANIFEST
    )
    q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate_summary_rows = read_tsv(
        Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_SIXTEEN_SHARD_MCSE_PREGRID_AGGREGATE_SUMMARY
    )
    structured_re_q4_direct_drmjl_export_rows = read_tsv(
        STRUCTURED_RE_Q4_DIRECT_DRMJL_EXPORT
    )
    structured_re_q4_deterministic_fixture_rows = read_tsv(
        STRUCTURED_RE_Q4_DETERMINISTIC_FIXTURE
    )
    structured_re_q4_tolerance_policy_rows = read_tsv(
        STRUCTURED_RE_Q4_TOLERANCE_POLICY
    )
    structured_re_q4_same_fixture_parity_probe_rows = read_tsv(
        STRUCTURED_RE_Q4_SAME_FIXTURE_PARITY_PROBE
    )
    structured_re_q4_calibrated_parity_probe_rows = read_tsv(
        STRUCTURED_RE_Q4_CALIBRATED_PARITY_PROBE
    )
    structured_re_q4_parity_acceptance_gate_rows = read_tsv(
        STRUCTURED_RE_Q4_PARITY_ACCEPTANCE_GATE
    )
    structured_re_q4_extractor_parity_rows = read_tsv(STRUCTURED_RE_Q4_EXTRACTOR_PARITY)
    structured_re_q4_corpairs_parity_gate_rows = read_tsv(
        STRUCTURED_RE_Q4_CORPAIRS_PARITY_GATE
    )
    structured_re_q4_bridge_boundary_rows = read_tsv(STRUCTURED_RE_Q4_BRIDGE_BOUNDARY)
    structured_re_q4_reml_requested_effective_audit_rows = read_tsv(
        STRUCTURED_RE_Q4_REML_REQUESTED_EFFECTIVE_AUDIT
    )
    structured_re_reml_scope_gate_rows = read_tsv(STRUCTURED_RE_REML_SCOPE_GATE)
    structured_re_ademp_design_rows = read_tsv(STRUCTURED_RE_ADEMP_DESIGN)
    structured_re_coverage_calibration_status_rows = read_tsv(
        STRUCTURED_RE_COVERAGE_CALIBRATION_STATUS
    )
    structured_re_coverage_acceptance_gate_rows = read_tsv(
        STRUCTURED_RE_COVERAGE_ACCEPTANCE_GATE
    )
    structured_re_native_reml_scope_status_rows = read_tsv(
        STRUCTURED_RE_NATIVE_REML_SCOPE_STATUS
    )
    structured_re_scope_gate_status_rows = read_tsv(STRUCTURED_RE_SCOPE_GATE_STATUS)
    structured_re_type_gap_rows = read_tsv(STRUCTURED_RE_TYPE_GAPS)
    structured_re_r_docs_api_sync_rows = read_tsv(STRUCTURED_RE_R_DOCS_API_SYNC)
    structured_re_r_docs_sync_status_rows = read_tsv(STRUCTURED_RE_R_DOCS_SYNC_STATUS)
    structured_re_julia_twin_sync_rows = read_tsv(STRUCTURED_RE_JULIA_TWIN_SYNC)
    structured_re_julia_twin_status_rows = read_tsv(STRUCTURED_RE_JULIA_TWIN_STATUS)
    structured_re_ayumi_closeout_status_rows = read_tsv(
        STRUCTURED_RE_AYUMI_CLOSEOUT_STATUS
    )
    structured_re_closeout_package_rows = read_tsv(STRUCTURED_RE_CLOSEOUT_PACKAGE)
    structured_re_executable_evidence_rows = read_tsv(STRUCTURED_RE_EXECUTABLE_EVIDENCE)
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

    q_series_cell_ids: set[str] = set()
    if not structured_re_q_series_support_cell_rows:
        errors.append("structured-re-q-series-support-cells.tsv has no rows")
    for row in structured_re_q_series_support_cell_rows:
        row_id = row.get("cell_id", "<structured RE q-series cell>")
        if set(row.keys()) != set(STRUCTURED_RE_Q_SERIES_SUPPORT_CELL_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q-series-support-cells.tsv fields "
                "do not match the support-cell contract"
            )
        if not row.get("cell_id"):
            errors.append("structured-re-q-series-support-cells.tsv row lacks cell_id")
        elif row_id in q_series_cell_ids:
            errors.append(f"duplicate structured RE q-series cell id: {row_id}")
        q_series_cell_ids.add(row_id)
        for field in STRUCTURED_RE_Q_SERIES_SUPPORT_CELL_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        if row.get("family_class") not in STRUCTURED_RE_Q_SERIES_FAMILY_CLASSES:
            errors.append(
                f"{row_id}: invalid family_class {row.get('family_class')!r}"
            )
        if row.get("structure_provider") not in STRUCTURED_RE_Q_SERIES_PROVIDERS:
            errors.append(
                f"{row_id}: invalid structure_provider "
                f"{row.get('structure_provider')!r}"
            )
        if row.get("dimension_pattern") not in STRUCTURED_RE_Q_SERIES_DIMENSION_PATTERNS:
            errors.append(
                f"{row_id}: invalid dimension_pattern "
                f"{row.get('dimension_pattern')!r}"
            )
        if row.get("slope_class") not in STRUCTURED_RE_Q_SERIES_SLOPE_CLASSES:
            errors.append(f"{row_id}: invalid slope_class {row.get('slope_class')!r}")
        if row.get("route") not in STRUCTURED_RE_Q_SERIES_ROUTES:
            errors.append(f"{row_id}: invalid route {row.get('route')!r}")
        for field in ("estimator_requested", "estimator_effective"):
            if row.get(field) not in STRUCTURED_RE_Q_SERIES_ESTIMATORS:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        for field in (
            "fit_status",
            "extractor_status",
            "bridge_status",
            "interval_status",
            "coverage_status",
        ):
            if row.get(field) not in STRUCTURED_RE_Q_SERIES_STATUSES:
                errors.append(f"{row_id}: invalid {field} {row.get(field)!r}")
        if row.get("authority_status") not in STRUCTURED_RE_Q_SERIES_AUTHORITY_STATUSES:
            errors.append(
                f"{row_id}: invalid authority_status "
                f"{row.get('authority_status')!r}"
            )
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q_SERIES_SUPPORT_CELL_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")
        if (
            row.get("dimension_pattern") == "q4"
            and row.get("coverage_status") in {"inference_ready", "supported"}
        ):
            errors.append(f"{row_id}: q4 coverage is not accepted in this map")
        if (
            row.get("dimension_pattern") in {"q6", "q8"}
            and row.get("structure_provider") != "ordinary"
            and row.get("fit_status") not in {"planned", "unsupported", "blocked"}
        ):
            errors.append(
                f"{row_id}: structured {row.get('dimension_pattern')} must remain "
                "planned, unsupported, or blocked until runtime evidence exists"
            )
    missing_q_series_cells = sorted(
        STRUCTURED_RE_REQUIRED_Q_SERIES_CELLS - q_series_cell_ids
    )
    if missing_q_series_cells:
        errors.append(
            "structured-re-q-series-support-cells.tsv lacks required cells: "
            + ", ".join(missing_q_series_cells)
        )

    expected_mu_slope_audits = {
        "phylo": "mu_slope_phylo_artifact_audit",
        "spatial": "mu_slope_spatial_artifact_audit",
        "animal": "mu_slope_animal_artifact_audit",
        "relmat": "mu_slope_relmat_artifact_audit",
    }
    seen_mu_slope_audits: set[str] = set()
    if len(structured_re_mu_slope_fixture_audit_rows) != len(expected_mu_slope_audits):
        errors.append(
            "structured-re-mu-slope-fixture-audit.tsv has "
            f"{len(structured_re_mu_slope_fixture_audit_rows)} rows; expected "
            f"{len(expected_mu_slope_audits)}"
        )
    for row in structured_re_mu_slope_fixture_audit_rows:
        row_id = row.get("audit_id", "<structured RE mu slope audit>")
        if set(row.keys()) != set(STRUCTURED_RE_MU_SLOPE_FIXTURE_AUDIT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-mu-slope-fixture-audit.tsv fields "
                "do not match the audit contract"
            )
        for field in STRUCTURED_RE_MU_SLOPE_FIXTURE_AUDIT_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        provider = row.get("structure_provider")
        if provider not in expected_mu_slope_audits:
            errors.append(f"{row_id}: invalid structure_provider {provider!r}")
        elif row_id != expected_mu_slope_audits[provider]:
            errors.append(f"{row_id}: audit_id does not match provider {provider!r}")
        if row_id in seen_mu_slope_audits:
            errors.append(f"duplicate structured RE mu slope audit id: {row_id}")
        seen_mu_slope_audits.add(row_id)
        for field in ("artifact_writer_status", "focused_test_status"):
            if row.get(field) != "source_tested":
                errors.append(f"{row_id}: {field} must remain source_tested")
        if row.get("extractor_identity_status") != "banked":
            errors.append(f"{row_id}: extractor_identity_status must be banked")
        for field in ("bridge_fixture_status", "interval_status", "coverage_status"):
            if row.get(field) != "planned":
                errors.append(f"{row_id}: {field} must remain planned")
        if "coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must mention coverage boundary")
        if "bridge" not in row.get("next_gate", ""):
            errors.append(f"{row_id}: next_gate must keep bridge promotion separate")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

    expected_mu_slope_parity_fixtures = {
        "phylo": "mu_slope_phylo_same_target_ml",
        "spatial": "mu_slope_spatial_same_target_ml",
        "animal": "mu_slope_animal_same_target_ml",
        "relmat": "mu_slope_relmat_same_target_ml",
    }
    seen_mu_slope_parity_fixtures: set[str] = set()
    if len(structured_re_mu_slope_parity_fixture_rows) != len(
        expected_mu_slope_parity_fixtures
    ):
        errors.append(
            "structured-re-mu-slope-parity-fixture.tsv has "
            f"{len(structured_re_mu_slope_parity_fixture_rows)} rows; expected "
            f"{len(expected_mu_slope_parity_fixtures)}"
        )
    for row in structured_re_mu_slope_parity_fixture_rows:
        row_id = row.get("fixture_id", "<structured RE mu slope parity fixture>")
        if set(row.keys()) != set(STRUCTURED_RE_MU_SLOPE_PARITY_FIXTURE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-mu-slope-parity-fixture.tsv fields "
                "do not match the fixture contract"
            )
        for field in STRUCTURED_RE_MU_SLOPE_PARITY_FIXTURE_FIELDS:
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        provider = row.get("structured_type")
        if provider not in expected_mu_slope_parity_fixtures:
            errors.append(f"{row_id}: invalid structured_type {provider!r}")
        elif row_id != expected_mu_slope_parity_fixtures[provider]:
            errors.append(f"{row_id}: fixture_id does not match provider {provider!r}")
        if row_id in seen_mu_slope_parity_fixtures:
            errors.append(f"duplicate structured RE mu slope parity fixture id: {row_id}")
        seen_mu_slope_parity_fixtures.add(row_id)
        if row.get("dimension") != "q1":
            errors.append(f"{row_id}: dimension must remain q1")
        if row.get("endpoint") != "mu":
            errors.append(f"{row_id}: endpoint must remain mu")
        if row.get("slope_class") != "independent_one_slope":
            errors.append(f"{row_id}: slope_class must remain independent_one_slope")
        if row.get("estimator") != "ML":
            errors.append(f"{row_id}: estimator must remain ML")
        for field in ("interval_status", "coverage_status"):
            if row.get(field) != "planned":
                errors.append(f"{row_id}: {field} must remain planned")
        implemented_mu_slope_parity = {"phylo", "spatial", "animal"}
        if provider in implemented_mu_slope_parity:
            for field in ("native_status", "direct_drmjl_status", "r_via_julia_status"):
                if row.get(field) != "fixture_available":
                    errors.append(f"{row_id}: {field} must be fixture_available")
            if row.get("parity_status") != "covered_same_target_fixture":
                errors.append(
                    f"{row_id}: parity_status must be covered_same_target_fixture"
                )
            if row.get("bridge_status") != "fixture_parity":
                errors.append(f"{row_id}: bridge_status must be fixture_parity")
            if row.get("coefficient_order") != (
                "mu:(Intercept);mu:x;sd_mu:structured(Intercept);"
                "sd_mu:structured(x)"
            ):
                errors.append(f"{row_id}: coefficient_order changed")
            if "broad bridge support" not in row.get("claim_boundary", ""):
                errors.append(
                    f"{row_id}: claim_boundary must keep broad bridge unsupported"
                )
            if provider == "phylo" and "template" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: next_gate must name the template role")
            if provider == "spatial" and "fixed-covariance" not in row.get(
                "claim_boundary", ""
            ):
                errors.append(f"{row_id}: spatial claim_boundary must be fixed-covariance")
            if provider == "animal" and "A-matrix" not in row.get(
                "claim_boundary", ""
            ):
                errors.append(f"{row_id}: animal claim_boundary must name A-matrix")
        else:
            for field in ("native_status", "direct_drmjl_status", "r_via_julia_status"):
                if row.get(field) != "planned":
                    errors.append(f"{row_id}: {field} must remain planned")
            for field in ("parity_status", "bridge_status"):
                if row.get(field) != "planned":
                    errors.append(f"{row_id}: {field} must remain planned")
            if row.get("coefficient_order") != "planned":
                errors.append(f"{row_id}: coefficient_order must remain planned")
            if "Implement" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: next_gate must state the implementation gate")
            if provider == "relmat" and "K-versus-Q" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: relmat next_gate must keep K/Q boundary")
        if "coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must mention coverage boundary")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve to local evidence")

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
        if row.get("status") not in MATRIX_STATUSES | {"blocked"}:
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

    if len(structured_re_q2_payload_contract_rows) < len(STRUCTURED_RE_Q2_PAYLOAD_TARGETS):
        errors.append(
            "structured-re-q2-payload-contract.tsv lacks required q2 payload rows"
        )
    q2_payload_targets: set[str] = set()
    for row in structured_re_q2_payload_contract_rows:
        row_id = row.get("contract_id", "<q2 payload contract>")
        if set(row.keys()) != set(STRUCTURED_RE_Q2_PAYLOAD_CONTRACT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q2-payload-contract.tsv fields do not match the contract"
            )
        target = row.get("target", "")
        q2_payload_targets.add(target)
        if target not in STRUCTURED_RE_Q2_PAYLOAD_TARGETS:
            errors.append(f"{row_id}: target {target!r} is not a registered q2 payload target")
        if row.get("estimator") not in BRIDGE_SCHEMA_ESTIMATORS:
            errors.append(f"{row_id}: invalid estimator {row.get('estimator')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if "matrix_digest" not in row.get("required_payload_fields", ""):
            errors.append(f"{row_id}: required_payload_fields must include matrix_digest")
        if "q4_payload" not in row.get("unsupported_fields", ""):
            errors.append(f"{row_id}: unsupported_fields must keep q4_payload explicit")
        if row.get("estimator") == "REML" and "not HSquared AI-REML" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: q2 REML payload boundary must reject HSquared AI-REML wording")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q2_PAYLOAD_CONTRACT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q2_payload_targets = sorted(STRUCTURED_RE_Q2_PAYLOAD_TARGETS - q2_payload_targets)
    if missing_q2_payload_targets:
        errors.append(
            "structured-re-q2-payload-contract.tsv missing q2 payload targets: "
            + ", ".join(missing_q2_payload_targets)
        )

    if len(structured_re_q2_payload_provenance_rows) < len(
        STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS
    ):
        errors.append(
            "structured-re-q2-payload-provenance.tsv lacks required q2 provenance rows"
        )
    q2_payload_provenance_targets: set[str] = set()
    for row in structured_re_q2_payload_provenance_rows:
        row_id = row.get("provenance_id", "<q2 payload provenance>")
        if set(row.keys()) != set(STRUCTURED_RE_Q2_PAYLOAD_PROVENANCE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q2-payload-provenance.tsv fields do not match the contract"
            )
        target = row.get("target", "")
        q2_payload_provenance_targets.add(target)
        if target not in STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS:
            errors.append(f"{row_id}: target {target!r} is not a registered q2 provenance target")
        if row.get("structured_type") not in STRUCTURED_RE_TYPES - {"phylo_interaction"}:
            errors.append(f"{row_id}: invalid structured_type {row.get('structured_type')!r}")
        if row.get("dimension") != "q2":
            errors.append(f"{row_id}: dimension must be q2")
        if row.get("route") != "q2_bridge":
            errors.append(f"{row_id}: route must be q2_bridge")
        if row.get("estimator") != "ML":
            errors.append(f"{row_id}: estimator must be ML")
        if row.get("payload_version") != "structured_re_bridge_payload_v1":
            errors.append(f"{row_id}: payload_version must be structured_re_bridge_payload_v1")
        if "drmTMB" not in row.get("source_repo", "") or "DRM.jl" not in row.get("source_repo", ""):
            errors.append(f"{row_id}: source_repo must name both drmTMB and DRM.jl")
        if "codex/ai-reml-transfer-slices" not in row.get("source_branch", ""):
            errors.append(f"{row_id}: source_branch must name the drmTMB branch")
        if "codex/ai-reml-gaussian-mme-pilot" not in row.get("source_branch", ""):
            errors.append(f"{row_id}: source_branch must name the DRM.jl pilot branch")
        if "b56aabd947b5" not in row.get("source_head", ""):
            errors.append(f"{row_id}: source_head must name the drmTMB head")
        if "e016fc15b4fb" not in row.get("source_head", ""):
            errors.append(f"{row_id}: source_head must name the DRM.jl head")
        if not row.get("matrix_id", "").startswith("fixture_q2_"):
            errors.append(f"{row_id}: matrix_id must be a q2 fixture matrix")
        if not row.get("matrix_digest", "").startswith("4x4:"):
            errors.append(f"{row_id}: matrix_digest must name the 4x4 fixture matrix")
        expected_matrix_slot = {
            "phylo": "tree",
            "spatial": "coords",
            "animal": "A",
            "relmat": "K",
        }.get(row.get("structured_type"))
        if expected_matrix_slot and row.get("matrix_slot") != expected_matrix_slot:
            errors.append(
                f"{row_id}: matrix_slot must be {expected_matrix_slot!r} for "
                f"{row.get('structured_type')} q2 provenance"
            )
        if not row.get("input_scale"):
            errors.append(f"{row_id}: input_scale must name the provider input scale")
        if not row.get("missing_level_policy"):
            errors.append(f"{row_id}: missing_level_policy must name level alignment policy")
        if not row.get("bridge_marshalling"):
            errors.append(f"{row_id}: bridge_marshalling must name bridge payload boundary")
        if "matrix_row_names" not in row.get("required_levels", ""):
            errors.append(f"{row_id}: required_levels must include matrix_row_names")
        if "payload_version" not in row.get("version_fields", ""):
            errors.append(f"{row_id}: version_fields must include payload_version")
        if "not_public_support" not in row.get("dirty_state_policy", ""):
            errors.append(f"{row_id}: dirty_state_policy must reject public support")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        structured_type = row.get("structured_type")
        bridge_status = row.get("bridge_status")
        if structured_type in {"phylo", "spatial", "animal", "relmat"} and bridge_status != "experimental":
            errors.append(
                f"{row_id}: {structured_type} q2 bridge status must record the experimental fixture"
            )
        if structured_type == "phylo":
            if "tree" not in row.get("matrix_slot", ""):
                errors.append(f"{row_id}: phylo matrix_slot must name the tree")
            if "extra_tree_tips_allowed" not in row.get("missing_level_policy", ""):
                errors.append(f"{row_id}: phylo missing_level_policy must allow extra tree tips")
            if "tree_serialized" not in row.get("bridge_marshalling", ""):
                errors.append(f"{row_id}: phylo bridge_marshalling must name tree serialization")
            if "no broad q2 bridge support" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: phylo claim_boundary must reject broad q2 bridge support")
        elif structured_type == "spatial":
            if "fixed_covariance_K" not in row.get("input_scale", ""):
                errors.append(f"{row_id}: spatial input_scale must name fixed covariance K")
            if "extra_coordinate_rows_not_supported" not in row.get("missing_level_policy", ""):
                errors.append(f"{row_id}: spatial missing_level_policy must reject extra coordinate rows")
            if "range_estimating_spatial_not_promoted" not in row.get("bridge_marshalling", ""):
                errors.append(f"{row_id}: spatial bridge_marshalling must reject range-estimating promotion")
            if "fixed-covariance" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must name fixed-covariance fixture evidence")
            if "no range-estimating spatial route" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must reject range-estimating support")
            if "no" not in row.get("claim_boundary", "") or "broad" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must reject broad bridge support")
        elif structured_type in {"animal", "relmat"}:
            if "extra_matrix_levels_allowed" not in row.get("missing_level_policy", ""):
                errors.append(f"{row_id}: {structured_type} missing_level_policy must allow extra matrix levels")
            if structured_type == "animal" and "pedigree_Ainv_not_marshaled" not in row.get("bridge_marshalling", ""):
                errors.append(f"{row_id}: animal bridge_marshalling must reject pedigree/Ainv marshalling")
            if structured_type == "relmat" and "Q_precision_not_marshaled" not in row.get("bridge_marshalling", ""):
                errors.append(f"{row_id}: relmat bridge_marshalling must reject Q precision marshalling")
            if "fixture-level audit evidence" not in row.get("claim_boundary", ""):
                errors.append(
                    f"{row_id}: {structured_type} claim_boundary must name fixture-level audit evidence"
                )
            if structured_type == "animal" and "pedigree/Ainv" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: animal claim_boundary must reject pedigree/Ainv marshalling")
            if structured_type == "relmat" and "Q precision" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: relmat claim_boundary must reject Q precision marshalling")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q2_PAYLOAD_PROVENANCE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q2_payload_provenance_targets = sorted(
        STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS - q2_payload_provenance_targets
    )
    if missing_q2_payload_provenance_targets:
        errors.append(
            "structured-re-q2-payload-provenance.tsv missing targets: "
            + ", ".join(missing_q2_payload_provenance_targets)
        )

    if len(structured_re_q2_coefficient_order_map_rows) < len(
        STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS
    ):
        errors.append(
            "structured-re-q2-coefficient-order-map.tsv lacks required q2 coefficient-order rows"
        )
    q2_coefficient_order_targets: set[str] = set()
    for row in structured_re_q2_coefficient_order_map_rows:
        row_id = row.get("map_id", "<q2 coefficient order map>")
        if set(row.keys()) != set(STRUCTURED_RE_Q2_COEFFICIENT_ORDER_MAP_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q2-coefficient-order-map.tsv fields do not match the contract"
            )
        target = row.get("target", "")
        q2_coefficient_order_targets.add(target)
        if target not in STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS:
            errors.append(
                f"{row_id}: target {target!r} is not a registered q2 coefficient-order target"
            )
        if row.get("structured_type") not in STRUCTURED_RE_TYPES - {"phylo_interaction"}:
            errors.append(f"{row_id}: invalid structured_type {row.get('structured_type')!r}")
        if row.get("route") != "q2_bridge":
            errors.append(f"{row_id}: route must be q2_bridge")
        if row.get("estimator") != "ML":
            errors.append(f"{row_id}: estimator must be ML")
        if row.get("coefficient_order") != STRUCTURED_RE_Q2_COEFFICIENT_ORDER:
            errors.append(f"{row_id}: coefficient_order does not match the q2 payload fixture")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        structured_type = row.get("structured_type")
        bridge_status = row.get("bridge_status")
        if structured_type in {"phylo", "spatial", "animal", "relmat"} and bridge_status != "experimental":
            errors.append(
                f"{row_id}: {structured_type} q2 bridge status must record the experimental fixture"
            )
        if "structured_correlation" not in row.get("tolerance_quantity", ""):
            errors.append(f"{row_id}: tolerance_quantity must include structured_correlation")
        if structured_type == "phylo":
            if "no broad q2 bridge support" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: phylo claim_boundary must reject broad q2 bridge support")
        elif structured_type == "spatial":
            if "fixed-covariance" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must name fixed-covariance fixture evidence")
            if "no range-estimating spatial route" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must reject range-estimating support")
            if "no" not in row.get("claim_boundary", "") or "broad" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must reject broad bridge support")
        elif structured_type in {"animal", "relmat"}:
            if "fixture-level contract evidence" not in row.get("claim_boundary", ""):
                errors.append(
                    f"{row_id}: {structured_type} claim_boundary must name fixture-level contract evidence"
                )
            if structured_type == "animal" and "pedigree/Ainv" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: animal claim_boundary must reject pedigree/Ainv marshalling")
            if structured_type == "relmat" and "Q precision" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: relmat claim_boundary must reject Q precision marshalling")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q2_COEFFICIENT_ORDER_MAP_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q2_coefficient_order_targets = sorted(
        STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS - q2_coefficient_order_targets
    )
    if missing_q2_coefficient_order_targets:
        errors.append(
            "structured-re-q2-coefficient-order-map.tsv missing targets: "
            + ", ".join(missing_q2_coefficient_order_targets)
        )

    if len(structured_re_q2_direct_drmjl_export_rows) < len(
        STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS
    ):
        errors.append(
            "structured-re-q2-direct-drmjl-export.tsv lacks required q2 direct export rows"
        )
    q2_direct_export_targets: set[str] = set()
    for row in structured_re_q2_direct_drmjl_export_rows:
        row_id = row.get("export_id", "<q2 direct drmjl export>")
        if set(row.keys()) != set(STRUCTURED_RE_Q2_DIRECT_DRMJL_EXPORT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q2-direct-drmjl-export.tsv fields do not match the contract"
            )
        target = row.get("target", "")
        q2_direct_export_targets.add(target)
        if target not in STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS:
            errors.append(f"{row_id}: target {target!r} is not a registered q2 direct target")
        if row.get("structured_type") not in STRUCTURED_RE_TYPES - {"phylo_interaction"}:
            errors.append(f"{row_id}: invalid structured_type {row.get('structured_type')!r}")
        if row.get("dimension") != "q2":
            errors.append(f"{row_id}: dimension must be q2")
        if row.get("route") != "direct_drmjl":
            errors.append(f"{row_id}: route must be direct_drmjl")
        if row.get("estimator") != "ML":
            errors.append(f"{row_id}: estimator must be ML")
        if row.get("coefficient_order") != STRUCTURED_RE_Q2_COEFFICIENT_ORDER:
            errors.append(f"{row_id}: coefficient_order does not match the q2 direct contract")
        if row.get("structured_type") == "phylo":
            if row.get("direct_status") != "available_residual_correlation_point_export":
                errors.append(
                    f"{row_id}: phylo direct_status must record the residual-correlation point export"
                )
        elif row.get("structured_type") == "spatial":
            if row.get("direct_status") != "available_fixed_covariance_residual_correlation_fixture":
                errors.append(
                    f"{row_id}: spatial direct_status must record the fixed-covariance fixture boundary"
                )
        elif row.get("direct_status") != "available_known_covariance_residual_correlation_point_export":
            errors.append(
                f"{row_id}: animal/relmat direct_status must record known-covariance q2 export"
            )
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        structured_type = row.get("structured_type")
        bridge_status = row.get("bridge_status")
        if structured_type in {"phylo", "spatial", "animal", "relmat"} and bridge_status != "experimental":
            errors.append(
                f"{row_id}: {structured_type} q2 bridge status must record the experimental fixture"
            )
        if structured_type == "phylo":
            if "residual-correlation" not in row.get("unavailable_reason", ""):
                errors.append(f"{row_id}: phylo unavailable_reason must name the residual-correlation fixture")
            if "q2 phylo residual-correlation" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: phylo claim_boundary must name the q2 phylo residual-correlation fixture")
        else:
            if structured_type == "spatial":
                if "fixed-covariance" not in row.get("unavailable_reason", ""):
                    errors.append(f"{row_id}: spatial unavailable_reason must name fixed-covariance fixture status")
                if "not a range-estimating spatial route" not in row.get("claim_boundary", ""):
                    errors.append(f"{row_id}: spatial claim_boundary must reject range-estimating spatial support")
            else:
                if "known covariance/precision" not in row.get("unavailable_reason", ""):
                    errors.append(f"{row_id}: unavailable_reason must name known covariance/precision fixture status")
                if "known-covariance" not in row.get("claim_boundary", ""):
                    errors.append(f"{row_id}: claim_boundary must name known-covariance fixture evidence")
        if structured_type == "phylo":
            if "no broad q2 bridge support" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: phylo claim_boundary must reject broad q2 bridge support")
        elif structured_type == "spatial":
            if "no broad q2 bridge support" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must reject broad q2 bridge support")
            if "not a range-estimating spatial route" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must reject range-estimating spatial support")
        elif structured_type in {"animal", "relmat"}:
            if "bridge parity fixture" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: {structured_type} claim_boundary must name bridge parity fixture evidence")
            if structured_type == "animal" and "pedigree/Ainv" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: animal claim_boundary must reject pedigree/Ainv marshalling")
            if structured_type == "relmat" and "Q precision" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: relmat claim_boundary must reject Q precision marshalling")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q2_DIRECT_DRMJL_EXPORT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q2_direct_export_targets = sorted(
        STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS - q2_direct_export_targets
    )
    if missing_q2_direct_export_targets:
        errors.append(
            "structured-re-q2-direct-drmjl-export.tsv missing targets: "
            + ", ".join(missing_q2_direct_export_targets)
        )

    if len(structured_re_q2_acceptance_gate_rows) < len(
        STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS
    ):
        errors.append("structured-re-q2-acceptance-gate.tsv lacks required q2 gate rows")
    q2_acceptance_targets: set[str] = set()
    for row in structured_re_q2_acceptance_gate_rows:
        row_id = row.get("gate_id", "<q2 acceptance gate>")
        if set(row.keys()) != set(STRUCTURED_RE_Q2_ACCEPTANCE_GATE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q2-acceptance-gate.tsv fields do not match the contract"
            )
        target = row.get("target", "")
        q2_acceptance_targets.add(target)
        if target not in STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS:
            errors.append(f"{row_id}: target {target!r} is not a registered q2 acceptance target")
        if row.get("structured_type") not in STRUCTURED_RE_TYPES - {"phylo_interaction"}:
            errors.append(f"{row_id}: invalid structured_type {row.get('structured_type')!r}")
        if row.get("dimension") != "q2":
            errors.append(f"{row_id}: dimension must be q2")
        if row.get("estimator") != "ML":
            errors.append(f"{row_id}: estimator must be ML")
        if row.get("native_status") != "available_point_fixture":
            errors.append(f"{row_id}: native_status must be available_point_fixture")
        structured_type = row.get("structured_type")
        if structured_type == "phylo":
            if row.get("direct_drmjl_status") != "available_residual_correlation_point_export":
                errors.append(f"{row_id}: phylo direct_drmjl_status must record q2 residual-correlation export")
            if row.get("r_via_julia_status") != "available_q2_phylo_formula_bridge_fixture":
                errors.append(f"{row_id}: phylo r_via_julia_status must record q2 bridge fixture availability")
            if row.get("acceptance_status") != "banked_phylo_fixture":
                errors.append(f"{row_id}: phylo acceptance_status must be banked_phylo_fixture")
            if row.get("status") != "covered":
                errors.append(f"{row_id}: phylo status must be covered")
        elif structured_type == "spatial":
            if row.get("direct_drmjl_status") != "available_fixed_covariance_residual_correlation_fixture":
                errors.append(
                    f"{row_id}: spatial direct_drmjl_status must record fixed-covariance q2 evidence"
                )
            if row.get("r_via_julia_status") != "available_q2_fixed_covariance_spatial_formula_bridge_fixture":
                errors.append(
                    f"{row_id}: spatial r_via_julia_status must record fixed-covariance bridge evidence"
                )
            if row.get("acceptance_status") != "banked_fixed_covariance_spatial_fixture":
                errors.append(f"{row_id}: spatial acceptance_status must record the fixed-covariance fixture")
            if row.get("status") != "covered":
                errors.append(f"{row_id}: spatial status must be covered")
        else:
            if row.get("direct_drmjl_status") != "available_known_covariance_residual_correlation_point_export":
                errors.append(
                    f"{row_id}: animal/relmat direct_drmjl_status must record known-covariance q2 evidence"
                )
            if row.get("r_via_julia_status") != "available_q2_known_covariance_formula_bridge_fixture":
                errors.append(
                    f"{row_id}: animal/relmat r_via_julia_status must record known-covariance bridge evidence"
                )
            if row.get("acceptance_status") != "banked_known_covariance_fixture":
                errors.append(f"{row_id}: animal/relmat acceptance_status must be banked_known_covariance_fixture")
            if row.get("status") != "covered":
                errors.append(f"{row_id}: animal/relmat status must be covered")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if structured_type in {"phylo", "spatial", "animal", "relmat"} and row.get("bridge_status") != "experimental":
            errors.append(
                f"{row_id}: {structured_type} q2 bridge status must record the experimental fixture"
            )
        if structured_type == "phylo":
            if row.get("missing_evidence") != "none_for_phylo_fixture":
                errors.append(f"{row_id}: phylo missing_evidence must be none_for_phylo_fixture")
            if row.get("required_before_acceptance") != "none_for_phylo_fixture":
                errors.append(f"{row_id}: phylo required_before_acceptance must be none_for_phylo_fixture")
            if "same_target_fixture" not in row.get("tolerance_policy", ""):
                errors.append(f"{row_id}: phylo tolerance_policy must record same-target fixture tolerance")
            if "no broad q2 bridge support" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: phylo claim_boundary must reject broad q2 bridge support")
        elif structured_type == "spatial":
            if row.get("missing_evidence") != "none_for_fixed_covariance_spatial_fixture":
                errors.append(f"{row_id}: spatial missing_evidence must be none_for_fixed_covariance_spatial_fixture")
            if row.get("required_before_acceptance") != "none_for_fixed_covariance_spatial_fixture":
                errors.append(
                    f"{row_id}: spatial required_before_acceptance must be none_for_fixed_covariance_spatial_fixture"
                )
            if "same_target_fixture" not in row.get("tolerance_policy", ""):
                errors.append(f"{row_id}: spatial tolerance_policy must record same-target fixture tolerance")
            if "fixed-covariance" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must name the fixed-covariance fixture")
            if "not a range-estimating spatial route" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: spatial claim_boundary must reject range-estimating spatial support")
        else:
            if row.get("missing_evidence") != "none_for_known_covariance_fixture":
                errors.append(f"{row_id}: animal/relmat missing_evidence must be none_for_known_covariance_fixture")
            if row.get("required_before_acceptance") != "none_for_known_covariance_fixture":
                errors.append(
                    f"{row_id}: animal/relmat required_before_acceptance must be none_for_known_covariance_fixture"
                )
            if "same_target_fixture" not in row.get("tolerance_policy", ""):
                errors.append(
                    f"{row_id}: animal/relmat tolerance_policy must record same-target fixture tolerance"
                )
            if "complete-response exact-Gaussian ML" not in row.get("claim_boundary", ""):
                errors.append(
                    f"{row_id}: animal/relmat claim_boundary must name the exact-Gaussian ML fixture"
                )
            if structured_type == "animal" and "pedigree/Ainv" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: animal claim_boundary must reject pedigree/Ainv marshalling")
            if structured_type == "relmat" and "Q precision" not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: relmat claim_boundary must reject Q precision marshalling")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q2_ACCEPTANCE_GATE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q2_acceptance_targets = sorted(
        STRUCTURED_RE_Q2_COEFFICIENT_ORDER_TARGETS - q2_acceptance_targets
    )
    if missing_q2_acceptance_targets:
        errors.append(
            "structured-re-q2-acceptance-gate.tsv missing targets: "
            + ", ".join(missing_q2_acceptance_targets)
        )

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

    expected_q4_sd_targets = {"sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2"}
    expected_q4_cor_targets = {
        "cor_mu1_mu2",
        "cor_mu1_sigma1",
        "cor_mu1_sigma2",
        "cor_mu2_sigma1",
        "cor_mu2_sigma2",
        "cor_sigma1_sigma2",
    }
    if len(structured_re_q4_phylocov_target_map_rows) != 10:
        errors.append("structured-re-q4-phylocov-target-map.tsv must have 10 q4 target rows")
    q4_sd_targets: set[str] = set()
    q4_cor_targets: set[str] = set()
    for row in structured_re_q4_phylocov_target_map_rows:
        row_id = row.get("map_id", "<q4 phylocov target map>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_PHYLOCOV_TARGET_MAP_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-phylocov-target-map.tsv fields do not match the contract"
            )
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("estimator") != "ML":
            errors.append(f"{row_id}: estimator must be ML")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("bridge_status") != "experimental":
            errors.append(f"{row_id}: bridge_status must remain experimental")
        if row.get("target_kind") == "direct_sd":
            q4_sd_targets.add(row.get("direct_sd_target", ""))
            if row.get("correlation_target") != "not_applicable":
                errors.append(f"{row_id}: direct SD rows must not name a correlation target")
            if row.get("interval_status") != "not_evaluated":
                errors.append(f"{row_id}: direct SD interval_status must be not_evaluated")
            if not row.get("log_cholesky_target", "").startswith("log_cholesky_diag_"):
                errors.append(f"{row_id}: direct SD rows must map to log_cholesky_diag_*")
        elif row.get("target_kind") == "derived_correlation":
            q4_cor_targets.add(row.get("correlation_target", ""))
            if row.get("direct_sd_target") != "not_direct":
                errors.append(f"{row_id}: derived correlations are not direct SD targets")
            if row.get("extractor") != "corpairs":
                errors.append(f"{row_id}: derived correlations must use corpairs")
            if row.get("interval_status") != "not_available":
                errors.append(f"{row_id}: derived correlation intervals must be not_available")
            if not row.get("log_cholesky_target", "").startswith("log_cholesky_offdiag_"):
                errors.append(f"{row_id}: derived correlation rows must map to log_cholesky_offdiag_*")
        else:
            errors.append(f"{row_id}: invalid target_kind {row.get('target_kind')!r}")
        if "no q4" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject q4 promotion")
        if "interval coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject interval coverage")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_PHYLOCOV_TARGET_MAP_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q4_sd_targets = sorted(expected_q4_sd_targets - q4_sd_targets)
    if missing_q4_sd_targets:
        errors.append(
            "structured-re-q4-phylocov-target-map.tsv missing SD targets: "
            + ", ".join(missing_q4_sd_targets)
        )
    missing_q4_cor_targets = sorted(expected_q4_cor_targets - q4_cor_targets)
    if missing_q4_cor_targets:
        errors.append(
            "structured-re-q4-phylocov-target-map.tsv missing correlation targets: "
            + ", ".join(missing_q4_cor_targets)
        )

    expected_q4_profile_targets = {
        "mu1": (
            "sd:mu:mu1:phylo(1 | p | species)",
            "sd:mu1:phylo(1 | species)",
            "sd_mu1",
        ),
        "mu2": (
            "sd:mu:mu2:phylo(1 | p | species)",
            "sd:mu2:phylo(1 | species)",
            "sd_mu2",
        ),
        "sigma1": (
            "sd:mu:sigma1:phylo(1 | p | species)",
            "sd:sigma1:phylo(1 | species)",
            "sd_sigma1",
        ),
        "sigma2": (
            "sd:mu:sigma2:phylo(1 | p | species)",
            "sd:sigma2:phylo(1 | species)",
            "sd_sigma2",
        ),
    }
    if len(structured_re_q4_profile_target_bridge_map_rows) != 4:
        errors.append("structured-re-q4-profile-target-bridge-map.tsv must have four rows")
    q4_profile_axes: set[str] = set()
    for row in structured_re_q4_profile_target_bridge_map_rows:
        row_id = row.get("map_id", "<q4 profile target bridge map>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_PROFILE_TARGET_BRIDGE_MAP_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-profile-target-bridge-map.tsv fields do not match the contract"
            )
        axis = row.get("axis", "")
        q4_profile_axes.add(axis)
        expected = expected_q4_profile_targets.get(axis)
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if expected is None:
            errors.append(f"{row_id}: invalid axis {axis!r}")
        else:
            native_target, bridge_target, sd_target = expected
            if row.get("native_profile_target") != native_target:
                errors.append(f"{row_id}: native_profile_target does not match {axis}")
            if row.get("bridge_profile_target") != bridge_target:
                errors.append(f"{row_id}: bridge_profile_target does not match {axis}")
            if row.get("direct_sd_target") != sd_target:
                errors.append(f"{row_id}: direct_sd_target does not match {axis}")
        if row.get("native_tmb_parameter") != "log_sd_phylo":
            errors.append(f"{row_id}: native_tmb_parameter must be log_sd_phylo")
        if row.get("native_profile_ready") != "true":
            errors.append(f"{row_id}: native_profile_ready must remain true")
        if row.get("bridge_profile_ready") != "target_inventory_only":
            errors.append(f"{row_id}: bridge_profile_ready must remain target_inventory_only")
        if row.get("interval_status") != "not_evaluated":
            errors.append(f"{row_id}: interval_status must remain not_evaluated")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") != "experimental":
            errors.append(f"{row_id}: bridge_status must remain experimental")
        if "no_same_fixture_native_direct_bridge_profile_comparison" not in row.get(
            "negative_evidence", ""
        ):
            errors.append(f"{row_id}: negative_evidence must name same-fixture gap")
        if "no q4 parity" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject q4 parity")
        if "interval coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject interval coverage")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_PROFILE_TARGET_BRIDGE_MAP_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q4_profile_axes = sorted(set(expected_q4_profile_targets) - q4_profile_axes)
    if missing_q4_profile_axes:
        errors.append(
            "structured-re-q4-profile-target-bridge-map.tsv missing axes: "
            + ", ".join(missing_q4_profile_axes)
        )

    expected_q4_scale_failure_targets = {
        "sigma1": "sd_sigma1",
        "sigma2": "sd_sigma2",
    }
    if len(structured_re_q4_scale_axis_interval_failure_rows) != 2:
        errors.append("structured-re-q4-scale-axis-interval-failures.tsv must have two rows")
    q4_scale_failure_axes: set[str] = set()
    for row in structured_re_q4_scale_axis_interval_failure_rows:
        row_id = row.get("failure_id", "<q4 scale-axis interval failure>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_SCALE_AXIS_INTERVAL_FAILURES_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-scale-axis-interval-failures.tsv fields do not match the contract"
            )
        axis = row.get("axis", "")
        q4_scale_failure_axes.add(axis)
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        expected_target = expected_q4_scale_failure_targets.get(axis)
        if expected_target is None:
            errors.append(f"{row_id}: invalid axis {axis!r}")
        elif row.get("direct_sd_target") != expected_target:
            errors.append(f"{row_id}: direct_sd_target must be {expected_target}")
        if "100tip_refit_failures" not in row.get("native_tmb_status", ""):
            errors.append(f"{row_id}: native_tmb_status must retain 100-tip refit failures")
        if row.get("direct_drmjl_status") != "known_scale_axis_undercoverage":
            errors.append(f"{row_id}: direct_drmjl_status must record known undercoverage")
        if row.get("r_via_julia_status") != "target_inventory_only":
            errors.append(f"{row_id}: r_via_julia_status must remain target_inventory_only")
        if "scale_axis_undercoverage_known" not in row.get("failure_class", ""):
            errors.append(f"{row_id}: failure_class must record scale-axis undercoverage")
        if "native_refit_failures_visible" not in row.get("failure_class", ""):
            errors.append(f"{row_id}: failure_class must record native refit failures")
        if row.get("interval_claim_status") != "blocked":
            errors.append(f"{row_id}: interval_claim_status must remain blocked")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") != "experimental":
            errors.append(f"{row_id}: bridge_status must remain experimental")
        if "bootstrap-refit-accounting.tsv" not in row.get("source_evidence", ""):
            errors.append(f"{row_id}: source_evidence must include bootstrap refit accounting")
        if "bivariate-bootstrap-sigma-a.md" not in row.get("source_evidence", ""):
            errors.append(f"{row_id}: source_evidence must include direct DRM.jl bootstrap evidence")
        if "no q4 interval reliability" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject q4 interval reliability")
        if "interval coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject interval coverage")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_SCALE_AXIS_INTERVAL_FAILURES_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q4_scale_failure_axes = sorted(
        set(expected_q4_scale_failure_targets) - q4_scale_failure_axes
    )
    if missing_q4_scale_failure_axes:
        errors.append(
            "structured-re-q4-scale-axis-interval-failures.tsv missing axes: "
            + ", ".join(missing_q4_scale_failure_axes)
        )

    expected_q4_interval_direct_targets = {
        "mu1": "sd_mu1",
        "mu2": "sd_mu2",
        "sigma1": "sd_sigma1",
        "sigma2": "sd_sigma2",
    }
    expected_q4_interval_cor_targets = {
        "mu1_mu2",
        "mu1_sigma1",
        "mu1_sigma2",
        "mu2_sigma1",
        "mu2_sigma2",
        "sigma1_sigma2",
    }
    if len(structured_re_q4_interval_diagnostic_plan_rows) != 10:
        errors.append("structured-re-q4-interval-diagnostic-plan.tsv must have ten rows")
    q4_interval_direct_axes: set[str] = set()
    q4_interval_cor_axes: set[str] = set()
    for row in structured_re_q4_interval_diagnostic_plan_rows:
        row_id = row.get("diagnostic_id", "<q4 interval diagnostic plan>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_PLAN_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-interval-diagnostic-plan.tsv fields do not match the contract"
            )
        if row.get("slice_id") != "SR150":
            errors.append(f"{row_id}: slice_id must be SR150")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("target_kind") not in {"direct_sd", "derived_correlation"}:
            errors.append(f"{row_id}: invalid target_kind {row.get('target_kind')!r}")
        axis_pair = row.get("axis_pair", "")
        if row.get("target_kind") == "direct_sd":
            q4_interval_direct_axes.add(axis_pair)
            expected_sd_target = expected_q4_interval_direct_targets.get(axis_pair)
            if expected_sd_target is None:
                errors.append(f"{row_id}: invalid direct axis {axis_pair!r}")
            elif row.get("direct_sd_target") != expected_sd_target:
                errors.append(f"{row_id}: direct_sd_target must be {expected_sd_target}")
            if row.get("derived_correlation_target") != "not_applicable":
                errors.append(f"{row_id}: direct rows must use not_applicable derived target")
        else:
            q4_interval_cor_axes.add(axis_pair)
            if axis_pair not in expected_q4_interval_cor_targets:
                errors.append(f"{row_id}: invalid derived-correlation axis pair {axis_pair!r}")
            if row.get("direct_sd_target") != "not_direct":
                errors.append(f"{row_id}: derived-correlation rows must use not_direct")
            if row.get("derived_correlation_target") != f"cor_{axis_pair}":
                errors.append(f"{row_id}: derived_correlation_target must match axis_pair")
            if "corpairs" not in row.get("required_fit_evidence", ""):
                errors.append(f"{row_id}: derived rows must require corpairs reconstruction")
        for method in ("wald", "profile", "bootstrap"):
            if method not in row.get("interval_methods", ""):
                errors.append(f"{row_id}: interval_methods must include {method}")
        if ">=500" not in row.get("required_fit_evidence", ""):
            errors.append(f"{row_id}: required_fit_evidence must retain planned replicate count")
        if "finite" not in row.get("required_interval_evidence", ""):
            errors.append(f"{row_id}: required_interval_evidence must require finite intervals")
        if "coverage_mcse<=0.01" not in row.get("required_interval_evidence", ""):
            errors.append(f"{row_id}: required_interval_evidence must require MCSE target")
        for field in (
            "coverage_denominator",
            "n_fit_ok",
            "n_failed_fit",
            "n_interval_finite",
            "coverage_mcse",
        ):
            if field not in row.get("denominator_fields", ""):
                errors.append(f"{row_id}: denominator_fields must include {field}")
        if row.get("status") != "planned":
            errors.append(f"{row_id}: q4 interval diagnostics must remain planned")
        claim_boundary = row.get("claim_boundary", "")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in claim_boundary:
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_PLAN_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q4_interval_direct_axes = sorted(
        set(expected_q4_interval_direct_targets) - q4_interval_direct_axes
    )
    if missing_q4_interval_direct_axes:
        errors.append(
            "structured-re-q4-interval-diagnostic-plan.tsv missing direct axes: "
            + ", ".join(missing_q4_interval_direct_axes)
        )
    missing_q4_interval_cor_axes = sorted(
        expected_q4_interval_cor_targets - q4_interval_cor_axes
    )
    if missing_q4_interval_cor_axes:
        errors.append(
            "structured-re-q4-interval-diagnostic-plan.tsv missing correlation axes: "
            + ", ".join(missing_q4_interval_cor_axes)
        )

    if len(structured_re_q4_interval_diagnostic_status_rows) != 10:
        errors.append("structured-re-q4-interval-diagnostic-status.tsv must have ten rows")
    q4_interval_status_direct_axes: set[str] = set()
    q4_interval_status_cor_axes: set[str] = set()
    for row in structured_re_q4_interval_diagnostic_status_rows:
        row_id = row.get("diagnostic_id", "<q4 interval diagnostic status>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-interval-diagnostic-status.tsv fields do not match the contract"
            )
        if row.get("slice_id") != "SR150":
            errors.append(f"{row_id}: slice_id must be SR150")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("source_artifact") != (
            "docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/"
            "tables/structured-coverage-pilot-rows.csv"
        ):
            errors.append(f"{row_id}: source_artifact must point to the q4 pilot rows")
        if not evidence_reference_exists(row.get("source_artifact", "")):
            errors.append(f"{row_id}: source_artifact does not resolve")
        if row.get("target_kind") not in {"direct_sd", "derived_correlation"}:
            errors.append(f"{row_id}: invalid target_kind {row.get('target_kind')!r}")
        axis_pair = row.get("axis_pair", "")
        numeric_values = {}
        for numeric_field in (
            "observed_target_rows",
            "n_fit_ok",
            "n_converged",
            "n_pdhess",
            "n_finite_intervals",
        ):
            try:
                value = int(row.get(numeric_field, ""))
            except ValueError:
                value = -1
            numeric_values[numeric_field] = value
            if value < 0:
                errors.append(f"{row_id}: {numeric_field} must be a non-negative integer")
        if row.get("target_kind") == "direct_sd":
            q4_interval_status_direct_axes.add(axis_pair)
            expected_sd_target = expected_q4_interval_direct_targets.get(axis_pair)
            if expected_sd_target is None:
                errors.append(f"{row_id}: invalid direct axis {axis_pair!r}")
            elif row.get("direct_sd_target") != expected_sd_target:
                errors.append(f"{row_id}: direct_sd_target must be {expected_sd_target}")
            if numeric_values.get("observed_target_rows") != 2:
                errors.append(f"{row_id}: direct rows must retain two q4 pilot rows")
            if numeric_values.get("n_fit_ok") != 2:
                errors.append(f"{row_id}: direct rows must retain two fit_ok rows")
            if numeric_values.get("n_converged") != 0:
                errors.append(f"{row_id}: direct rows must retain zero converged rows")
            if numeric_values.get("n_pdhess") != 0:
                errors.append(f"{row_id}: direct rows must retain zero pdHess rows")
            if row.get("interval_status") != "wald_unavailable":
                errors.append(f"{row_id}: direct rows must retain wald_unavailable status")
            if "no_finite_wald_intervals" not in row.get("failure_class", ""):
                errors.append(f"{row_id}: direct rows must name missing finite Wald intervals")
        else:
            q4_interval_status_cor_axes.add(axis_pair)
            if axis_pair not in expected_q4_interval_cor_targets:
                errors.append(f"{row_id}: invalid derived-correlation axis pair {axis_pair!r}")
            if row.get("direct_sd_target") != "not_direct":
                errors.append(f"{row_id}: derived-correlation rows must use not_direct")
            if row.get("derived_correlation_target") != f"cor_{axis_pair}":
                errors.append(f"{row_id}: derived_correlation_target must match axis_pair")
            if any(value != 0 for value in numeric_values.values()):
                errors.append(f"{row_id}: derived rows must retain zero observed interval rows")
            if row.get("interval_status") != "derived_interval_not_reconstructed":
                errors.append(f"{row_id}: derived rows must retain reconstruction gap")
            if "derived_correlation_interval_reconstruction_not_available" not in row.get(
                "failure_class", ""
            ):
                errors.append(f"{row_id}: derived rows must name reconstruction gap")
        if numeric_values.get("n_finite_intervals") != 0:
            errors.append(f"{row_id}: q4 diagnostic status must retain zero finite intervals")
        if row.get("interval_claim_status") != "blocked":
            errors.append(f"{row_id}: interval_claim_status must remain blocked")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: diagnostic ledger rows must be covered")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_INTERVAL_DIAGNOSTIC_STATUS_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q4_interval_status_direct_axes = sorted(
        set(expected_q4_interval_direct_targets) - q4_interval_status_direct_axes
    )
    if missing_q4_interval_status_direct_axes:
        errors.append(
            "structured-re-q4-interval-diagnostic-status.tsv missing direct axes: "
            + ", ".join(missing_q4_interval_status_direct_axes)
        )
    missing_q4_interval_status_cor_axes = sorted(
        expected_q4_interval_cor_targets - q4_interval_status_cor_axes
    )
    if missing_q4_interval_status_cor_axes:
        errors.append(
            "structured-re-q4-interval-diagnostic-status.tsv missing correlation axes: "
            + ", ".join(missing_q4_interval_status_cor_axes)
        )

    if len(structured_re_q4_convergence_probe_rows) != 15:
        errors.append("structured-re-q4-convergence-probe.tsv must have fifteen rows")
    q4_probe_presets: set[str] = set()
    q4_probe_dense_converged = 0
    for row in structured_re_q4_convergence_probe_rows:
        row_id = row.get("probe_id", "<q4 convergence probe>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_CONVERGENCE_PROBE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-convergence-probe.tsv fields do not match the contract"
            )
        if row.get("slice_id") != "SR150":
            errors.append(f"{row_id}: slice_id must be SR150")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        preset = row.get("optimizer_preset", "")
        q4_probe_presets.add(preset)
        if preset not in {"default", "careful", "robust"}:
            errors.append(f"{row_id}: invalid optimizer_preset {preset!r}")
        for field in ("n_tip", "m", "replicate", "convergence"):
            try:
                value = int(row.get(field, ""))
            except ValueError:
                value = -1
            if value < 0:
                errors.append(f"{row_id}: {field} must be a non-negative integer")
        try:
            elapsed = float(row.get("elapsed_sec", ""))
        except ValueError:
            elapsed = -1.0
        if elapsed <= 0:
            errors.append(f"{row_id}: elapsed_sec must be positive")
        if row.get("fit_ok") != "true":
            errors.append(f"{row_id}: probe rows must retain fit_ok=true")
        if row.get("pdHess") != "false":
            errors.append(f"{row_id}: q4 convergence probe must retain pdHess=false")
        if row.get("converged") == "true" and row.get("diagnostic_class") == "optimizer_converged_pdhess_false":
            q4_probe_dense_converged += 1
        if row.get("converged") == "true" and row.get("pdHess") != "false":
            errors.append(f"{row_id}: converged q4 probes still must not have pdHess")
        if row.get("converged") == "false" and "nonconverged" not in row.get(
            "diagnostic_class", ""
        ):
            errors.append(f"{row_id}: nonconverged rows must be classified")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: convergence probe rows must be covered")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_CONVERGENCE_PROBE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if q4_probe_presets != {"default", "careful", "robust"}:
        errors.append("structured-re-q4-convergence-probe.tsv must cover all optimizer presets")
    if q4_probe_dense_converged != 3:
        errors.append(
            "structured-re-q4-convergence-probe.tsv must retain three converged-but-pdHess-false dense rows"
        )

    if len(structured_re_q4_boundary_separated_probe_rows) != 12:
        errors.append("structured-re-q4-boundary-separated-probe.tsv must have twelve rows")
    boundary_probe_presets: set[str] = set()
    boundary_probe_seeds: set[str] = set()
    boundary_probe_converged = 0
    for row in structured_re_q4_boundary_separated_probe_rows:
        row_id = row.get("probe_id", "<q4 boundary-separated probe>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_BOUNDARY_SEPARATED_PROBE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-boundary-separated-probe.tsv fields do not match the contract"
            )
        if row.get("slice_id") != "SR150":
            errors.append(f"{row_id}: slice_id must be SR150")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        preset = row.get("optimizer_preset", "")
        boundary_probe_presets.add(preset)
        if preset not in {"default", "careful", "robust"}:
            errors.append(f"{row_id}: invalid optimizer_preset {preset!r}")
        seed = row.get("seed", "")
        boundary_probe_seeds.add(seed)
        for field in ("n_tip", "m", "seed", "convergence"):
            try:
                value = int(row.get(field, ""))
            except ValueError:
                value = -1
            if value < 0:
                errors.append(f"{row_id}: {field} must be a non-negative integer")
        for field in ("elapsed_sec", "min_direct_sd_estimate", "max_abs_derived_correlation"):
            try:
                value = float(row.get(field, ""))
            except ValueError:
                value = -1.0
            if value < 0:
                errors.append(f"{row_id}: {field} must be non-negative")
            if field == "max_abs_derived_correlation" and value < 0.9:
                errors.append(f"{row_id}: boundary probe should retain near-boundary correlations")
        if row.get("fit_ok") != "true":
            errors.append(f"{row_id}: probe rows must retain fit_ok=true")
        if row.get("pdHess") != "false":
            errors.append(f"{row_id}: boundary-separated probe must retain pdHess=false")
        if row.get("converged") == "true":
            boundary_probe_converged += 1
            if row.get("diagnostic_class") != "optimizer_converged_pdhess_false_boundary_correlation":
                errors.append(f"{row_id}: converged probe rows must name pdHess and boundary-correlation blocker")
        if row.get("converged") == "false" and "nonconverged" not in row.get(
            "diagnostic_class", ""
        ):
            errors.append(f"{row_id}: nonconverged probe rows must be classified")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: boundary-separated probe rows must be covered")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_BOUNDARY_SEPARATED_PROBE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if boundary_probe_presets != {"default", "careful", "robust"}:
        errors.append("structured-re-q4-boundary-separated-probe.tsv must cover all optimizer presets")
    if boundary_probe_seeds != {"202606777", "202606778"}:
        errors.append("structured-re-q4-boundary-separated-probe.tsv must retain both seeds")
    if boundary_probe_converged != 2:
        errors.append(
            "structured-re-q4-boundary-separated-probe.tsv must retain two converged-but-pdHess-false rows"
        )

    expected_hessian_metrics = {
        "max_abs_gradient_fixed",
        "min_cov_fixed_eigenvalue",
        "max_cov_fixed_eigenvalue",
        "min_direct_sd_estimate",
        "max_direct_sd_estimate",
        "min_abs_derived_correlation",
        "max_abs_derived_correlation",
        "finite_wald_direct_sd_intervals",
    }
    hessian_metrics: set[str] = set()
    if len(structured_re_q4_hessian_diagnostic_status_rows) != 8:
        errors.append("structured-re-q4-hessian-diagnostic-status.tsv must have eight rows")
    for row in structured_re_q4_hessian_diagnostic_status_rows:
        row_id = row.get("diagnostic_id", "<q4 hessian diagnostic>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_HESSIAN_DIAGNOSTIC_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-hessian-diagnostic-status.tsv fields do not match the contract"
            )
        if row.get("slice_id") != "SR150":
            errors.append(f"{row_id}: slice_id must be SR150")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("fixture") != "q4_10tip_m4_seed202606421":
            errors.append(f"{row_id}: fixture must identify the dense q4 toy fit")
        if row.get("optimizer_preset") != "default":
            errors.append(f"{row_id}: optimizer_preset must be default for this diagnostic")
        if row.get("converged") != "true":
            errors.append(f"{row_id}: hessian diagnostic fixture must be optimizer-converged")
        if row.get("pdHess") != "false":
            errors.append(f"{row_id}: hessian diagnostic must retain pdHess=false")
        metric = row.get("metric", "")
        hessian_metrics.add(metric)
        if metric not in expected_hessian_metrics:
            errors.append(f"{row_id}: unexpected metric {metric!r}")
        value_text = row.get("value", "")
        if metric != "finite_wald_direct_sd_intervals":
            try:
                value = float(value_text)
            except ValueError:
                value = float("nan")
            if value != value:
                errors.append(f"{row_id}: numeric hessian diagnostic value required")
            if metric == "min_cov_fixed_eigenvalue" and value >= 0:
                errors.append(f"{row_id}: min covariance eigenvalue must be negative")
            if metric == "max_abs_gradient_fixed" and value >= 1e-5:
                errors.append(f"{row_id}: max gradient should remain small")
            if metric == "min_direct_sd_estimate" and value >= 1e-4:
                errors.append(f"{row_id}: min direct SD estimate must retain near-zero boundary")
            if metric == "min_abs_derived_correlation" and value <= 0.9:
                errors.append(f"{row_id}: derived correlations must retain near-boundary evidence")
        else:
            if value_text != "0_of_4":
                errors.append(f"{row_id}: finite Wald interval count must remain 0_of_4")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: hessian diagnostic rows must be covered")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_HESSIAN_DIAGNOSTIC_STATUS_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_hessian_metrics = sorted(expected_hessian_metrics - hessian_metrics)
    if missing_hessian_metrics:
        errors.append(
            "structured-re-q4-hessian-diagnostic-status.tsv missing metrics: "
            + ", ".join(missing_hessian_metrics)
        )

    expected_stabilized_design = {
        "q4_stabilized_direct_sd_signal": (
            "near_zero_direct_sd_estimates",
            "min_direct_sd_estimate",
            ">=0.20",
        ),
        "q4_stabilized_correlation_interior": (
            "derived_correlations_near_boundary",
            "max_abs_derived_correlation",
            "<=0.80",
        ),
        "q4_stabilized_positive_hessian": (
            "optimizer_converged_pdhess_false",
            "pdHess_and_cov_fixed_eigenspectrum",
            "pdHess=true",
        ),
        "q4_stabilized_finite_direct_intervals": (
            "zero_finite_direct_sd_intervals",
            "finite_direct_sd_intervals_by_method",
            "wald=4_of_4",
        ),
        "q4_stabilized_denominator_accounting": (
            "no_calibrated_denominator_accounting",
            "denominator_fields",
            "coverage_mcse",
        ),
        "q4_stabilized_route_specific_parity": (
            "bridge_and_native_routes_not_equivalent_for_intervals",
            "parity_routes",
            "r_via_julia",
        ),
    }
    stabilized_design_ids: set[str] = set()
    if len(structured_re_q4_stabilized_fixture_design_rows) != 6:
        errors.append("structured-re-q4-stabilized-fixture-design.tsv must have six rows")
    for row in structured_re_q4_stabilized_fixture_design_rows:
        row_id = row.get("design_id", "<q4 stabilized fixture design>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_FIXTURE_DESIGN_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-fixture-design.tsv fields do not match the contract"
            )
        if row_id not in expected_stabilized_design:
            errors.append(f"{row_id}: unexpected q4 stabilized fixture design row")
            expected = ("", "", "")
        else:
            expected = expected_stabilized_design[row_id]
        stabilized_design_ids.add(row_id)
        if row.get("slice_id") != "SR150":
            errors.append(f"{row_id}: slice_id must be SR150")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("blocker") != expected[0]:
            errors.append(f"{row_id}: blocker must be {expected[0]!r}")
        if row.get("acceptance_metric") != expected[1]:
            errors.append(f"{row_id}: acceptance_metric must be {expected[1]!r}")
        if expected[2] and expected[2] not in row.get("acceptance_threshold", ""):
            errors.append(f"{row_id}: acceptance_threshold must include {expected[2]!r}")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: stabilized fixture design rows must be covered")
        if not row.get("required_design_change", "").strip():
            errors.append(f"{row_id}: required_design_change must be populated")
        if not row.get("next_gate", "").strip():
            errors.append(f"{row_id}: next_gate must be populated")
        owners = member_list(row.get("owner_members", ""))
        if not owners:
            errors.append(f"{row_id}: owner_members must name at least one member")
        for owner in owners:
            if owner not in CANONICAL_ACTORS:
                errors.append(f"{row_id}: owner_members includes unknown member {owner!r}")
        for input_ref in member_list(row.get("evidence_input", "")):
            if not evidence_reference_exists(f"docs/dev-log/dashboard/{input_ref}"):
                errors.append(f"{row_id}: evidence_input {input_ref!r} does not resolve")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_STABILIZED_FIXTURE_DESIGN_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_stabilized_design_ids = sorted(
        set(expected_stabilized_design) - stabilized_design_ids
    )
    if missing_stabilized_design_ids:
        errors.append(
            "structured-re-q4-stabilized-fixture-design.tsv missing rows: "
            + ", ".join(missing_stabilized_design_ids)
        )

    if len(structured_re_q4_stabilized_preflight_rows) != 4:
        errors.append("structured-re-q4-stabilized-preflight.tsv must have four rows")
    preflight_seeds: set[str] = set()
    preflight_scales: set[str] = set()
    preflight_pdhess_true = 0
    preflight_finite_wald = 0
    for row in structured_re_q4_stabilized_preflight_rows:
        row_id = row.get("preflight_id", "<q4 stabilized preflight>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_PREFLIGHT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-preflight.tsv fields do not match the contract"
            )
        if row.get("slice_id") != "SR150":
            errors.append(f"{row_id}: slice_id must be SR150")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("fixture") != "q4_stabilized_balanced32_n8_corr005":
            errors.append(f"{row_id}: fixture must name the stabilized balanced32 preflight")
        seed = row.get("seed", "")
        scale = row.get("sd_scale", "")
        preflight_seeds.add(seed)
        preflight_scales.add(scale)
        for field in ("seed", "n_tip", "n_each", "convergence"):
            try:
                value = int(row.get(field, ""))
            except ValueError:
                value = -1
            if value < 0:
                errors.append(f"{row_id}: {field} must be a non-negative integer")
        if row.get("n_tip") != "32":
            errors.append(f"{row_id}: n_tip must be 32 for this preflight")
        if row.get("n_each") != "8":
            errors.append(f"{row_id}: n_each must be 8 for this preflight")
        for field in (
            "sd_scale",
            "corr_offdiag",
            "max_gradient",
            "min_direct_sd_estimate",
            "max_abs_derived_correlation",
        ):
            try:
                value = float(row.get(field, ""))
            except ValueError:
                value = -1.0
            if value < 0:
                errors.append(f"{row_id}: {field} must be non-negative")
            if field == "max_gradient" and value >= 1e-3:
                errors.append(f"{row_id}: stabilized preflight gradient must remain below 1e-3")
            if field == "max_abs_derived_correlation" and value >= 0.9:
                errors.append(f"{row_id}: stabilized preflight must keep correlations away from +/-1")
        if row.get("fit_ok") != "true":
            errors.append(f"{row_id}: stabilized preflight rows must retain fit_ok=true")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: stabilized preflight rows must be covered")
        pdhess = row.get("pdHess")
        if pdhess == "true":
            preflight_pdhess_true += 1
            if row.get("converged") != "true" or row.get("convergence") != "0":
                errors.append(f"{row_id}: pdHess=true rows must also be converged")
            if row.get("finite_wald_direct_sd_intervals") != "4_of_4":
                errors.append(f"{row_id}: pdHess=true rows must retain 4_of_4 finite Wald direct-SD intervals")
            if row.get("direct_sd_interval_status") != "wald_finite":
                errors.append(f"{row_id}: pdHess=true rows must have wald_finite status")
            if row.get("diagnostic_class") != "converged_pdhess_true_finite_wald_direct_sd_intervals":
                errors.append(f"{row_id}: pdHess=true rows must be classified as finite-Wald preflight evidence")
            preflight_finite_wald += 1
        elif pdhess == "false":
            if row.get("finite_wald_direct_sd_intervals") != "not_evaluated":
                errors.append(f"{row_id}: pdHess=false rows must not report finite interval counts")
            if row.get("direct_sd_interval_status") != "pdhess_false":
                errors.append(f"{row_id}: pdHess=false rows must retain pdhess_false interval status")
            if "nonconverged_pdhess_false" not in row.get("diagnostic_class", ""):
                errors.append(f"{row_id}: pdHess=false rows must retain nonconverged classification")
        else:
            errors.append(f"{row_id}: pdHess must be true or false")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_STABILIZED_PREFLIGHT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if preflight_seeds != {"202606901", "202606902"}:
        errors.append("structured-re-q4-stabilized-preflight.tsv must retain both seeds")
    if preflight_scales != {"0.35", "0.50"}:
        errors.append("structured-re-q4-stabilized-preflight.tsv must retain both scale levels")
    if preflight_pdhess_true != 2:
        errors.append("structured-re-q4-stabilized-preflight.tsv must retain two pdHess=true rows")
    if preflight_finite_wald != 2:
        errors.append("structured-re-q4-stabilized-preflight.tsv must retain two finite-Wald rows")

    expected_denominator_extension = {
        "0.35": {
            "n_total": "4",
            "n_fit_ok": "4",
            "n_converged": "2",
            "n_pdhess": "2",
            "n_finite_wald_direct_sd_intervals": "2",
            "n_pdhess_false": "2",
            "gradient_warning_rows": "0",
            "denominator_status": "denominator_preflight_only",
        },
        "0.50": {
            "n_total": "4",
            "n_fit_ok": "4",
            "n_converged": "3",
            "n_pdhess": "3",
            "n_finite_wald_direct_sd_intervals": "3",
            "n_pdhess_false": "1",
            "gradient_warning_rows": "1",
            "denominator_status": "denominator_preflight_with_gradient_warning",
        },
    }
    denominator_scales: set[str] = set()
    if len(structured_re_q4_stabilized_denominator_extension_rows) != 2:
        errors.append(
            "structured-re-q4-stabilized-denominator-extension.tsv must have two rows"
        )
    for row in structured_re_q4_stabilized_denominator_extension_rows:
        row_id = row.get("summary_id", "<q4 stabilized denominator extension>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_DENOMINATOR_EXTENSION_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-denominator-extension.tsv fields do not match the contract"
            )
        if row.get("slice_id") != "SR150":
            errors.append(f"{row_id}: slice_id must be SR150")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("fixture") != "q4_stabilized_balanced32_n8_corr005":
            errors.append(f"{row_id}: fixture must name the stabilized balanced32 preflight")
        scale = row.get("sd_scale", "")
        denominator_scales.add(scale)
        expected = expected_denominator_extension.get(scale)
        if expected is None:
            errors.append(f"{row_id}: unexpected sd_scale {scale!r}")
            expected = {}
        for field, expected_value in expected.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in (
            "n_total",
            "n_fit_ok",
            "n_converged",
            "n_pdhess",
            "n_finite_wald_direct_sd_intervals",
            "n_pdhess_false",
            "gradient_warning_rows",
        ):
            try:
                value = int(row.get(field, ""))
            except ValueError:
                value = -1
            if value < 0:
                errors.append(f"{row_id}: {field} must be a non-negative integer")
        for field in ("min_direct_sd_pdhess_true", "max_abs_cor_pdhess_true"):
            try:
                value = float(row.get(field, ""))
            except ValueError:
                value = -1.0
            if value < 0:
                errors.append(f"{row_id}: {field} must be non-negative")
            if field == "max_abs_cor_pdhess_true" and value >= 0.7:
                errors.append(f"{row_id}: denominator extension should keep positive rows interior")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: denominator extension rows must be covered")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_STABILIZED_DENOMINATOR_EXTENSION_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if denominator_scales != {"0.35", "0.50"}:
        errors.append(
            "structured-re-q4-stabilized-denominator-extension.tsv must retain both scale rows"
        )

    if len(structured_re_q4_stabilized_profile_smoke_rows) != 1:
        errors.append("structured-re-q4-stabilized-profile-smoke.tsv must have one row")
    for row in structured_re_q4_stabilized_profile_smoke_rows:
        row_id = row.get("smoke_id", "<q4 stabilized profile smoke>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_PROFILE_SMOKE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-profile-smoke.tsv fields do not match the contract"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "fixture": "q4_stabilized_balanced32_n8_corr005",
            "seed": "202606902",
            "sd_scale": "0.50",
            "parm": "sd:mu:sigma1:phylo(1 | p | species)",
            "fit_convergence": "0",
            "pdHess": "true",
            "profile_precision": "fast",
            "profile_engine": "tmbprofile",
            "conf_status": "profile",
            "profile_boundary": "false",
            "profile_message": "ok",
            "diagnostic_class": "profile_smoke_finite_direct_sd_interval",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in ("max_gradient", "profile_elapsed_sec", "lower", "upper"):
            try:
                value = float(row.get(field, ""))
            except ValueError:
                value = -1.0
            if value < 0:
                errors.append(f"{row_id}: {field} must be non-negative")
            if field == "max_gradient" and value >= 1e-3:
                errors.append(f"{row_id}: profile smoke fit gradient must stay below 1e-3")
        try:
            lower = float(row.get("lower", ""))
            upper = float(row.get("upper", ""))
        except ValueError:
            lower = upper = float("nan")
        if not lower < upper:
            errors.append(f"{row_id}: profile endpoints must be ordered")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_STABILIZED_PROFILE_SMOKE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    expected_q4_all_direct_profile_targets = {
        "mu1": "sd:mu:mu1:phylo(1 | p | species)",
        "mu2": "sd:mu:mu2:phylo(1 | p | species)",
        "sigma1": "sd:mu:sigma1:phylo(1 | p | species)",
        "sigma2": "sd:mu:sigma2:phylo(1 | p | species)",
    }
    if len(structured_re_q4_stabilized_all_direct_profile_rows) != 4:
        errors.append("structured-re-q4-stabilized-all-direct-profile.tsv must have four rows")
    q4_all_direct_profile_axes: set[str] = set()
    for row in structured_re_q4_stabilized_all_direct_profile_rows:
        row_id = row.get("profile_id", "<q4 stabilized all-direct profile>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_ALL_DIRECT_PROFILE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-all-direct-profile.tsv fields do not match the contract"
            )
        axis = row.get("axis", "")
        q4_all_direct_profile_axes.add(axis)
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "fixture": "q4_stabilized_balanced32_n8_corr005",
            "seed": "202606902",
            "sd_scale": "0.50",
            "fit_convergence": "0",
            "pdHess": "true",
            "profile_precision": "fast",
            "profile_engine": "tmbprofile",
            "conf_status": "profile",
            "profile_boundary": "false",
            "profile_message": "ok",
            "diagnostic_class": "all_direct_profile_finite_direct_sd_interval",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        expected_parm = expected_q4_all_direct_profile_targets.get(axis)
        if expected_parm is None:
            errors.append(f"{row_id}: axis must be one of the four direct q4 SD axes")
        elif row.get("parm") != expected_parm:
            errors.append(f"{row_id}: parm must match axis {axis!r}")
        for field in ("max_gradient", "profile_elapsed_sec", "lower", "upper"):
            try:
                value = float(row.get(field, ""))
            except ValueError:
                value = -1.0
            if value < 0:
                errors.append(f"{row_id}: {field} must be non-negative")
            if field == "max_gradient" and value >= 1e-3:
                errors.append(f"{row_id}: all-direct profile fit gradient must stay below 1e-3")
            if field == "profile_elapsed_sec" and value <= 0:
                errors.append(f"{row_id}: profile_elapsed_sec must be positive")
        try:
            lower = float(row.get("lower", ""))
            upper = float(row.get("upper", ""))
        except ValueError:
            lower = upper = float("nan")
        if not lower < upper:
            errors.append(f"{row_id}: profile endpoints must be ordered")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_STABILIZED_ALL_DIRECT_PROFILE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if q4_all_direct_profile_axes != set(expected_q4_all_direct_profile_targets):
        errors.append(
            "structured-re-q4-stabilized-all-direct-profile.tsv must retain all four direct axes"
        )

    if len(structured_re_q4_stabilized_profile_denominator_status_rows) != 8:
        errors.append(
            "structured-re-q4-stabilized-profile-denominator-status.tsv must have eight rows"
        )
    q4_profile_denominator_seed_scale: set[tuple[str, str]] = set()
    q4_profile_denominator_counts = {
        "eligible": 0,
        "attempted": 0,
        "finite_rows": 0,
        "pdhess_false": 0,
        "gradient_warning": 0,
        "eligible_unprofiled": 0,
    }
    expected_q4_profile_denominator_statuses = {
        "all_direct_profiles_finite",
        "blocked_pdhess_false",
        "eligible_not_profiled",
        "held_for_gradient_warning",
    }
    for row in structured_re_q4_stabilized_profile_denominator_status_rows:
        row_id = row.get("denominator_id", "<q4 stabilized profile denominator>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_PROFILE_DENOMINATOR_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-profile-denominator-status.tsv fields do not match the contract"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "fixture": "q4_stabilized_balanced32_n8_corr005",
            "fit_ok": "true",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        seed_scale = (row.get("seed", ""), row.get("sd_scale", ""))
        q4_profile_denominator_seed_scale.add(seed_scale)
        if row.get("sd_scale") not in {"0.35", "0.50"}:
            errors.append(f"{row_id}: sd_scale must be 0.35 or 0.50")
        if row.get("profile_status") not in expected_q4_profile_denominator_statuses:
            errors.append(f"{row_id}: profile_status is not recognized")
        try:
            max_gradient = float(row.get("max_gradient", ""))
        except ValueError:
            max_gradient = -1.0
        if max_gradient < 0:
            errors.append(f"{row_id}: max_gradient must be non-negative")
        if row.get("pdHess") == "false":
            q4_profile_denominator_counts["pdhess_false"] += 1
            if row.get("profile_eligible") != "false" or row.get("profile_status") != "blocked_pdhess_false":
                errors.append(f"{row_id}: pdHess=false rows must be profile-blocked")
        if row.get("blocker") == "gradient_warning":
            q4_profile_denominator_counts["gradient_warning"] += 1
            if max_gradient <= 1e-3:
                errors.append(f"{row_id}: gradient-warning rows must retain max_gradient above 1e-3")
            if row.get("profile_eligible") != "false":
                errors.append(f"{row_id}: gradient-warning row must not be profile eligible")
        if row.get("profile_eligible") == "true":
            q4_profile_denominator_counts["eligible"] += 1
        if row.get("profile_attempted") == "true":
            q4_profile_denominator_counts["attempted"] += 1
        if row.get("profile_status") == "eligible_not_profiled":
            q4_profile_denominator_counts["eligible_unprofiled"] += 1
            if row.get("profile_eligible") != "true" or row.get("profile_attempted") != "false":
                errors.append(f"{row_id}: eligible_not_profiled rows must be eligible and unattempted")
        for field in ("direct_profile_rows", "profile_finite_rows"):
            try:
                value = int(row.get(field, ""))
            except ValueError:
                value = -1
            if value < 0 or value > 4:
                errors.append(f"{row_id}: {field} must be an integer from 0 to 4")
            if field == "profile_finite_rows":
                q4_profile_denominator_counts["finite_rows"] += value
        if row.get("profile_status") == "all_direct_profiles_finite":
            if row.get("profile_attempted") != "true":
                errors.append(f"{row_id}: finite profile rows must mark profile_attempted=true")
            if row.get("direct_profile_rows") != "4" or row.get("profile_finite_rows") != "4":
                errors.append(f"{row_id}: finite profile rows must retain 4 direct and finite rows")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_STABILIZED_PROFILE_DENOMINATOR_STATUS_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    expected_q4_profile_denominator_seed_scale = {
        ("202606901", "0.35"),
        ("202606902", "0.35"),
        ("202606903", "0.35"),
        ("202606904", "0.35"),
        ("202606901", "0.50"),
        ("202606902", "0.50"),
        ("202606903", "0.50"),
        ("202606904", "0.50"),
    }
    if q4_profile_denominator_seed_scale != expected_q4_profile_denominator_seed_scale:
        errors.append(
            "structured-re-q4-stabilized-profile-denominator-status.tsv must retain all seed-scale rows"
        )
    if q4_profile_denominator_counts != {
        "eligible": 4,
        "attempted": 4,
        "finite_rows": 16,
        "pdhess_false": 3,
        "gradient_warning": 1,
        "eligible_unprofiled": 0,
    }:
        errors.append(
            "structured-re-q4-stabilized-profile-denominator-status.tsv counts changed"
        )

    expected_q4_eligible_profile_seed_scale = {
        ("202606902", "0.35"),
        ("202606903", "0.35"),
        ("202606904", "0.50"),
    }
    expected_q4_eligible_profile_axes = {
        "mu1": "sd:mu:mu1:phylo(1 | p | species)",
        "mu2": "sd:mu:mu2:phylo(1 | p | species)",
        "sigma1": "sd:mu:sigma1:phylo(1 | p | species)",
        "sigma2": "sd:mu:sigma2:phylo(1 | p | species)",
    }
    if len(structured_re_q4_stabilized_eligible_profile_rows) != 12:
        errors.append("structured-re-q4-stabilized-eligible-profile.tsv must have twelve rows")
    q4_eligible_profile_seed_scale: set[tuple[str, str]] = set()
    q4_eligible_profile_axis_by_seed_scale: dict[tuple[str, str], set[str]] = {}
    for row in structured_re_q4_stabilized_eligible_profile_rows:
        row_id = row.get("profile_id", "<q4 stabilized eligible profile>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_ELIGIBLE_PROFILE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-eligible-profile.tsv fields do not match the contract"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "fixture": "q4_stabilized_balanced32_n8_corr005",
            "fit_convergence": "0",
            "pdHess": "true",
            "profile_precision": "fast",
            "profile_engine": "tmbprofile",
            "conf_status": "profile",
            "profile_boundary": "false",
            "profile_message": "ok",
            "diagnostic_class": "eligible_profile_finite_direct_sd_interval",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        seed_scale = (row.get("seed", ""), row.get("sd_scale", ""))
        q4_eligible_profile_seed_scale.add(seed_scale)
        q4_eligible_profile_axis_by_seed_scale.setdefault(seed_scale, set()).add(row.get("axis", ""))
        expected_parm = expected_q4_eligible_profile_axes.get(row.get("axis", ""))
        if expected_parm is None:
            errors.append(f"{row_id}: axis must be one of the four direct q4 SD axes")
        elif row.get("parm") != expected_parm:
            errors.append(f"{row_id}: parm must match axis {row.get('axis', '')!r}")
        for field in ("max_gradient", "fit_elapsed_sec", "profile_elapsed_sec", "lower", "upper"):
            try:
                value = float(row.get(field, ""))
            except ValueError:
                value = -1.0
            if value < 0:
                errors.append(f"{row_id}: {field} must be non-negative")
            if field == "max_gradient" and value >= 1e-3:
                errors.append(f"{row_id}: eligible profile fit gradient must stay below 1e-3")
            if field in {"fit_elapsed_sec", "profile_elapsed_sec"} and value <= 0:
                errors.append(f"{row_id}: {field} must be positive")
        try:
            lower = float(row.get("lower", ""))
            upper = float(row.get("upper", ""))
        except ValueError:
            lower = upper = float("nan")
        if not lower < upper:
            errors.append(f"{row_id}: profile endpoints must be ordered")
        if "regularize_values_duplicate_x" not in row.get("warning_context", ""):
            errors.append(f"{row_id}: warning_context must retain the duplicate-x warning")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_STABILIZED_ELIGIBLE_PROFILE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if q4_eligible_profile_seed_scale != expected_q4_eligible_profile_seed_scale:
        errors.append("structured-re-q4-stabilized-eligible-profile.tsv must retain all eligible rows")
    for seed_scale, axes in q4_eligible_profile_axis_by_seed_scale.items():
        if axes != set(expected_q4_eligible_profile_axes):
            errors.append(f"structured-re-q4-stabilized-eligible-profile.tsv missing axes for {seed_scale}")

    expected_q4_stabilized_coverage_components = {
        "direct_sd_profile_grid",
        "pdhess_failure_denominator",
        "gradient_warning_policy",
        "profile_warning_policy",
        "derived_correlation_interval_gap",
        "bootstrap_refit_accounting",
        "route_specific_boundary",
        "MCSE_report_policy",
    }
    if len(structured_re_q4_stabilized_coverage_design_rows) != 8:
        errors.append("structured-re-q4-stabilized-coverage-design.tsv must have eight rows")
    q4_stabilized_coverage_components: set[str] = set()
    for row in structured_re_q4_stabilized_coverage_design_rows:
        row_id = row.get("design_id", "<q4 stabilized coverage design>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_COVERAGE_DESIGN_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-coverage-design.tsv fields do not match the contract"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "planned_n_rep": "500",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        component = row.get("design_component", "")
        q4_stabilized_coverage_components.add(component)
        if component not in expected_q4_stabilized_coverage_components:
            errors.append(f"{row_id}: design_component is not recognized")
        for required_fragment in ("denominator",):
            if required_fragment not in row.get("denominator_policy", ""):
                errors.append(f"{row_id}: denominator_policy must name {required_fragment}")
        if row.get("warning_policy", "") == "":
            errors.append(f"{row_id}: warning_policy must not be empty")
        if row.get("blocked_until", "") == "":
            errors.append(f"{row_id}: blocked_until must not be empty")
        if "MCSE" not in row.get("acceptance_metric", "") and component != "route_specific_boundary":
            errors.append(f"{row_id}: acceptance_metric must retain MCSE/accounting language")
        if component == "direct_sd_profile_grid" and "16 finite direct q4 SD profile rows" not in row.get("current_evidence", ""):
            errors.append(f"{row_id}: direct profile design must cite the 16 finite direct profile rows")
        if component == "pdhess_failure_denominator" and "3 of 8" not in row.get("current_evidence", ""):
            errors.append(f"{row_id}: pdHess denominator row must retain the 3 of 8 blocker")
        if component == "gradient_warning_policy" and "0.0048295879" not in row.get("current_evidence", ""):
            errors.append(f"{row_id}: gradient warning row must retain the observed gradient")
        if component == "profile_warning_policy" and "duplicate-x" not in row.get("current_evidence", ""):
            errors.append(f"{row_id}: profile warning row must retain duplicate-x evidence")
        if component == "derived_correlation_interval_gap" and "not available" not in row.get("current_evidence", ""):
            errors.append(f"{row_id}: derived-correlation row must retain interval unavailability")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_STABILIZED_COVERAGE_DESIGN_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if q4_stabilized_coverage_components != expected_q4_stabilized_coverage_components:
        errors.append(
            "structured-re-q4-stabilized-coverage-design.tsv must retain all design components"
        )

    expected_q4_grid_runner_contracts = {
        "q4_stabilized_grid_entrypoint",
        "q4_stabilized_grid_seed_contract",
        "q4_stabilized_grid_direct_target_contract",
        "q4_stabilized_grid_derived_target_contract",
        "q4_stabilized_grid_denominator_contract",
        "q4_stabilized_grid_warning_contract",
        "q4_stabilized_grid_mcse_contract",
        "q4_stabilized_grid_boundary_contract",
    }
    if len(structured_re_q4_stabilized_grid_runner_contract_rows) != 8:
        errors.append(
            "structured-re-q4-stabilized-grid-runner-contract.tsv must have eight rows"
        )
    q4_grid_runner_contract_ids: set[str] = set()
    for row in structured_re_q4_stabilized_grid_runner_contract_rows:
        row_id = row.get("contract_id", "<q4 stabilized grid runner contract>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_GRID_RUNNER_CONTRACT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-grid-runner-contract.tsv fields do not match the contract"
            )
        q4_grid_runner_contract_ids.add(row_id)
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "mode": "dry_run",
            "output_artifact": "q4-stabilized-calibrated-grid-dry-run.tsv",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if row_id not in expected_q4_grid_runner_contracts:
            errors.append(f"{row_id}: contract_id is not recognized")
        if "run-calibrated-grid-dry-run.R" not in row.get("executable", ""):
            errors.append(f"{row_id}: executable must point to the dry-run script")
        if "denominator" not in row.get("denominator_policy", ""):
            errors.append(f"{row_id}: denominator_policy must name denominator")
        if row.get("warning_policy", "") == "":
            errors.append(f"{row_id}: warning_policy must not be empty")
        if row_id == "q4_stabilized_grid_entrypoint" and "--n-rep=0" not in row.get("validation_gate", ""):
            errors.append(f"{row_id}: validation_gate must use --n-rep=0")
        if row_id == "q4_stabilized_grid_mcse_contract" and "MCSE" not in row.get("validation_gate", ""):
            errors.append(f"{row_id}: MCSE contract must require MCSE columns")
        for required_column in ("denominator", "warning"):
            row_text_for_schema = " ".join(
                row.get(field, "")
                for field in ("required_columns", "denominator_policy", "warning_policy")
            )
            if required_column not in row_text_for_schema:
                errors.append(f"{row_id}: contract must retain {required_column} schema language")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_STABILIZED_GRID_RUNNER_CONTRACT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if q4_grid_runner_contract_ids != expected_q4_grid_runner_contracts:
        errors.append(
            "structured-re-q4-stabilized-grid-runner-contract.tsv must retain all contract rows"
        )

    if len(q4_stabilized_grid_dry_run_rows) != 1:
        errors.append("q4-stabilized-calibrated-grid-dry-run.tsv must have one row")
    for row in q4_stabilized_grid_dry_run_rows:
        row_id = row.get("dry_run_id", "<q4 grid dry run>")
        if set(row.keys()) != set(Q4_STABILIZED_GRID_DRY_RUN_FIELDS):
            errors.append(
                f"{row_id}: q4-stabilized-calibrated-grid-dry-run.tsv fields do not match the contract"
            )
        expected_values = {
            "dry_run_id": "q4_stabilized_calibrated_grid_dry_run",
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "requested_n_rep": "0",
            "seed_start": "202607001",
            "sd_scale_levels": "0.35;0.50",
            "status": "dry_run_only",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for required_target in ("sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2"):
            if required_target not in row.get("direct_sd_targets", ""):
                errors.append(f"{row_id}: missing direct target {required_target}")
        for required_target in (
            "cor_mu1_mu2",
            "cor_mu1_sigma1",
            "cor_mu1_sigma2",
            "cor_mu2_sigma1",
            "cor_mu2_sigma2",
            "cor_sigma1_sigma2",
        ):
            if required_target not in row.get("derived_correlation_targets", ""):
                errors.append(f"{row_id}: missing derived target {required_target}")
        for required_field in (
            "n_total",
            "n_fit_ok",
            "n_pdhess",
            "n_profile_warning",
            "n_gradient_warning",
            "n_failed_fit",
        ):
            if required_field not in row.get("denominator_fields", ""):
                errors.append(f"{row_id}: missing denominator field {required_field}")
        for required_field in (
            "profile_warning_context",
            "gradient_warning_context",
            "regularize_values_duplicate_x_count",
        ):
            if required_field not in row.get("warning_fields", ""):
                errors.append(f"{row_id}: missing warning field {required_field}")
        for required_field in ("coverage_mcse", "failure_rate_mcse"):
            if required_field not in row.get("output_schema", ""):
                errors.append(f"{row_id}: output_schema must include {required_field}")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")

    expected_q4_grid_smoke_ids = {
        "q4_stabilized_grid_smoke_entrypoint",
        "q4_stabilized_grid_smoke_direct_sd_rows",
        "q4_stabilized_grid_smoke_derived_correlation_rows",
        "q4_stabilized_grid_smoke_denominator_fields",
        "q4_stabilized_grid_smoke_warning_fields",
        "q4_stabilized_grid_smoke_mcse_fields",
        "q4_stabilized_grid_smoke_claim_boundary",
        "q4_stabilized_grid_smoke_next_gate",
    }
    if len(structured_re_q4_stabilized_grid_smoke_status_rows) != 8:
        errors.append("structured-re-q4-stabilized-grid-smoke-status.tsv must have eight rows")
    q4_grid_smoke_ids: set[str] = set()
    for row in structured_re_q4_stabilized_grid_smoke_status_rows:
        row_id = row.get("smoke_id", "<q4 grid smoke status>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_STABILIZED_GRID_SMOKE_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-stabilized-grid-smoke-status.tsv fields do not match the contract"
            )
        q4_grid_smoke_ids.add(row_id)
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "output_artifact": "q4-stabilized-calibrated-grid-smoke-results.tsv",
            "observed_replicates": "1",
            "fit_status": "fit_ok",
            "mcse_status": "insufficient_replicates",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if row_id not in expected_q4_grid_smoke_ids:
            errors.append(f"{row_id}: smoke_id is not recognized")
        if "run-calibrated-grid-smoke.R" not in row.get("source_script", ""):
            errors.append(f"{row_id}: source_script must point to the smoke script")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        for numeric_field in (
            "observed_target_rows",
            "direct_sd_rows",
            "derived_correlation_rows",
        ):
            try:
                int(row.get(numeric_field, ""))
            except ValueError:
                errors.append(f"{row_id}: {numeric_field} must be an integer")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_grid_smoke_ids != expected_q4_grid_smoke_ids:
        errors.append("structured-re-q4-stabilized-grid-smoke-status.tsv must retain all smoke rows")

    if len(q4_stabilized_grid_smoke_result_rows) != 10:
        errors.append("q4-stabilized-calibrated-grid-smoke-results.tsv must have ten target rows")
    direct_smoke_rows = [
        row
        for row in q4_stabilized_grid_smoke_result_rows
        if row.get("target_kind") == "direct_sd"
    ]
    derived_smoke_rows = [
        row
        for row in q4_stabilized_grid_smoke_result_rows
        if row.get("target_kind") == "derived_correlation"
    ]
    if len(direct_smoke_rows) != 4:
        errors.append("q4 smoke result must retain four direct-SD rows")
    if len(derived_smoke_rows) != 6:
        errors.append("q4 smoke result must retain six derived-correlation rows")
    if {row.get("replicate_id") for row in q4_stabilized_grid_smoke_result_rows} != {"smoke_001"}:
        errors.append("q4 smoke result must contain only replicate smoke_001")
    for row in q4_stabilized_grid_smoke_result_rows:
        row_id = row.get("target_name", "<q4 grid smoke result>")
        if set(row.keys()) != set(Q4_STABILIZED_GRID_SMOKE_RESULT_FIELDS):
            errors.append(
                f"{row_id}: q4-stabilized-calibrated-grid-smoke-results.tsv fields do not match the contract"
            )
        expected_values = {
            "seed": "202606902",
            "fit_status": "fit_ok",
            "convergence": "0",
            "converged": "TRUE",
            "pdHess": "TRUE",
            "mcse_status": "insufficient_replicates",
            "coverage_mcse": "not_computed_single_replicate",
            "failure_rate_mcse": "not_computed_single_replicate",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in ("max_gradient", "fit_elapsed_sec", "true_value"):
            try:
                float(row.get(field, ""))
            except ValueError:
                errors.append(f"{row_id}: {field} must be numeric")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    expected_direct_smoke_targets = {"sd_mu1", "sd_mu2", "sd_sigma1", "sd_sigma2"}
    if {row.get("target_name") for row in direct_smoke_rows} != expected_direct_smoke_targets:
        errors.append("q4 smoke result direct-SD targets changed")
    for row in direct_smoke_rows:
        row_id = row.get("target_name", "<q4 direct smoke>")
        if row.get("interval_method") != "wald":
            errors.append(f"{row_id}: direct smoke rows must use wald intervals")
        if row.get("interval_status") != "finite":
            errors.append(f"{row_id}: direct smoke rows must have finite interval status")
        if row.get("coverage_indicator") != "covered_by_interval":
            errors.append(f"{row_id}: direct smoke rows must retain single-replicate coverage indicator")
        for field in ("lower", "upper"):
            try:
                float(row.get(field, ""))
            except ValueError:
                errors.append(f"{row_id}: {field} must be numeric")
    expected_derived_smoke_targets = {
        "cor_mu1_mu2",
        "cor_mu1_sigma1",
        "cor_mu1_sigma2",
        "cor_mu2_sigma1",
        "cor_mu2_sigma2",
        "cor_sigma1_sigma2",
    }
    if {row.get("target_name") for row in derived_smoke_rows} != expected_derived_smoke_targets:
        errors.append("q4 smoke result derived-correlation targets changed")
    for row in derived_smoke_rows:
        row_id = row.get("target_name", "<q4 derived smoke>")
        if row.get("interval_method") != "not_available":
            errors.append(f"{row_id}: derived rows must keep interval_method not_available")
        if row.get("interval_status") != "derived_correlation_interval_not_reconstructed":
            errors.append(f"{row_id}: derived rows must keep reconstruction blocker")
        if row.get("failure_reason") != "derived_correlation_interval_reconstruction_not_available":
            errors.append(f"{row_id}: derived rows must keep unavailable reason")
        if row.get("coverage_indicator") != "not_evaluated":
            errors.append(f"{row_id}: derived rows must not evaluate coverage")
        if row.get("lower") or row.get("upper"):
            errors.append(f"{row_id}: derived rows must not contain interval endpoints")

    expected_q4_derived_interval_contract_targets = {
        "cor_mu1_mu2": "mu1_mu2",
        "cor_mu1_sigma1": "mu1_sigma1",
        "cor_mu1_sigma2": "mu1_sigma2",
        "cor_mu2_sigma1": "mu2_sigma1",
        "cor_mu2_sigma2": "mu2_sigma2",
        "cor_sigma1_sigma2": "sigma1_sigma2",
    }
    if len(structured_re_q4_derived_correlation_interval_contract_rows) != 6:
        errors.append(
            "structured-re-q4-derived-correlation-interval-contract.tsv must have six rows"
        )
    q4_derived_interval_targets: set[str] = set()
    for row in structured_re_q4_derived_correlation_interval_contract_rows:
        row_id = row.get("contract_id", "<q4 derived interval contract>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_DERIVED_CORRELATION_INTERVAL_CONTRACT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-interval-contract.tsv fields do not match the contract"
            )
        target = row.get("derived_correlation_target", "")
        q4_derived_interval_targets.add(target)
        expected_axis_pair = expected_q4_derived_interval_contract_targets.get(target)
        if expected_axis_pair is None:
            errors.append(f"{row_id}: derived_correlation_target is not recognized")
        elif row.get("axis_pair") != expected_axis_pair:
            errors.append(f"{row_id}: axis_pair must be {expected_axis_pair!r}")
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "current_interval_status": "not_available",
            "reconstruction_route": "planned_delta_or_profile_reconstruction",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for required_text, field in (
            ("corpairs", "point_source"),
            ("q4-stabilized-calibrated-grid-smoke-results.tsv", "interval_source"),
            ("Sigma_a", "required_payload_fields"),
            ("axis_pair", "required_payload_fields"),
            ("warning_context", "required_payload_fields"),
            ("failure_reason", "required_payload_fields"),
            ("delta", "required_methods"),
            ("profile", "required_methods"),
            ("bootstrap", "required_methods"),
            ("unavailable", "denominator_policy"),
            ("coverage_mcse", "mcse_policy"),
            ("failure_rate_mcse", "mcse_policy"),
        ):
            if required_text not in row.get(field, ""):
                errors.append(f"{row_id}: {field} must include {required_text!r}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_derived_interval_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append(
            "structured-re-q4-derived-correlation-interval-contract.tsv targets changed"
        )

    if len(structured_re_q4_derived_correlation_interval_smoke_rows) != 6:
        errors.append("structured-re-q4-derived-correlation-interval-smoke.tsv must have six rows")
    q4_derived_interval_smoke_targets: set[str] = set()
    for row in structured_re_q4_derived_correlation_interval_smoke_rows:
        row_id = row.get("smoke_id", "<q4 derived interval smoke>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_DERIVED_CORRELATION_INTERVAL_SMOKE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-interval-smoke.tsv fields do not match the contract"
            )
        target = row.get("derived_correlation_target", "")
        q4_derived_interval_smoke_targets.add(target)
        expected_axis_pair = expected_q4_derived_interval_contract_targets.get(target)
        if expected_axis_pair is None:
            errors.append(f"{row_id}: derived_correlation_target is not recognized")
        elif row.get("axis_pair") != expected_axis_pair:
            errors.append(f"{row_id}: axis_pair must be {expected_axis_pair!r}")
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "output_artifact": "q4-derived-correlation-interval-smoke-results.tsv",
            "point_status": "corpairs_point_reconstructed",
            "profile_target_status": "profile_target_mapped",
            "interval_status": "derived_interval_unavailable",
            "interval_source": "not_available",
            "mcse_status": "insufficient_replicates",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if "run-derived-correlation-interval-smoke.R" not in row.get("source_script", ""):
            errors.append(f"{row_id}: source_script must point to the r48 smoke script")
        if "unavailable" not in row.get("denominator_policy", ""):
            errors.append(f"{row_id}: denominator_policy must retain unavailable rows")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_derived_interval_smoke_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("structured-re-q4-derived-correlation-interval-smoke.tsv targets changed")

    if len(q4_derived_correlation_interval_smoke_result_rows) != 6:
        errors.append("q4-derived-correlation-interval-smoke-results.tsv must have six rows")
    q4_derived_interval_result_targets: set[str] = set()
    for row in q4_derived_correlation_interval_smoke_result_rows:
        row_id = row.get("target_name", "<q4 derived interval smoke result>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_INTERVAL_SMOKE_RESULT_FIELDS):
            errors.append(
                f"{row_id}: q4-derived-correlation-interval-smoke-results.tsv fields do not match the contract"
            )
        target = row.get("target_name", "")
        q4_derived_interval_result_targets.add(target)
        expected_axis_pair = expected_q4_derived_interval_contract_targets.get(target)
        if expected_axis_pair is None:
            errors.append(f"{row_id}: target_name is not recognized")
        elif row.get("axis_pair") != expected_axis_pair:
            errors.append(f"{row_id}: axis_pair must be {expected_axis_pair!r}")
        expected_values = {
            "replicate_id": "derived_smoke_001",
            "seed": "202606902",
            "target_kind": "derived_correlation",
            "fit_status": "fit_ok",
            "convergence": "0",
            "converged": "TRUE",
            "pdHess": "TRUE",
            "interval_status": "derived_interval_unavailable",
            "interval_source": "not_available",
            "failure_reason": "derived_interval_unavailable_by_profile_targets",
            "coverage_indicator": "not_evaluated",
            "coverage_mcse": "not_computed_single_replicate",
            "failure_rate_mcse": "not_computed_single_replicate",
            "mcse_status": "insufficient_replicates",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in ("true_value", "estimate", "max_gradient", "fit_elapsed_sec"):
            try:
                float(row.get(field, ""))
            except ValueError:
                errors.append(f"{row_id}: {field} must be numeric")
        if not row.get("profile_target", "").startswith("cor:phylo:"):
            errors.append(f"{row_id}: profile_target must be a q4 phylo correlation target")
        if row.get("lower") or row.get("upper"):
            errors.append(f"{row_id}: derived interval smoke rows must not contain endpoints")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_derived_interval_result_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("q4-derived-correlation-interval-smoke-results.tsv targets changed")

    if len(structured_re_q4_derived_correlation_delta_diagnostic_rows) != 6:
        errors.append(
            "structured-re-q4-derived-correlation-delta-diagnostic.tsv must have six rows"
        )
    q4_derived_delta_targets: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_diagnostic_rows:
        row_id = row.get("diagnostic_id", "<q4 derived delta diagnostic>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_DIAGNOSTIC_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-diagnostic.tsv fields do not match the contract"
            )
        target = row.get("derived_correlation_target", "")
        q4_derived_delta_targets.add(target)
        expected_axis_pair = expected_q4_derived_interval_contract_targets.get(target)
        if expected_axis_pair is None:
            errors.append(f"{row_id}: derived_correlation_target is not recognized")
        elif row.get("axis_pair") != expected_axis_pair:
            errors.append(f"{row_id}: axis_pair must be {expected_axis_pair!r}")
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "output_artifact": "q4-derived-correlation-delta-diagnostic-results.tsv",
            "reconstruction_status": "finite_difference_delta_available",
            "report_match_status": "corpairs_matches_report",
            "interval_method": "wald_delta_finite_difference",
            "interval_status": "finite_delta_diagnostic",
            "interval_source": "finite_difference_delta",
            "mcse_status": "insufficient_replicates",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if "run-derived-correlation-delta-diagnostic.R" not in row.get(
            "source_script", ""
        ):
            errors.append(f"{row_id}: source_script must point to the r49 delta script")
        if "denominator" not in row.get("denominator_policy", ""):
            errors.append(f"{row_id}: denominator_policy must retain denominator rows")
        if "MCSE" not in row.get("next_gate", "") and "MCSE" not in row.get(
            "claim_boundary", ""
        ):
            errors.append(f"{row_id}: next_gate must require MCSE before coverage wording")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_derived_delta_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append(
            "structured-re-q4-derived-correlation-delta-diagnostic.tsv targets changed"
        )

    if len(q4_derived_correlation_delta_diagnostic_result_rows) != 6:
        errors.append("q4-derived-correlation-delta-diagnostic-results.tsv must have six rows")
    q4_derived_delta_result_targets: set[str] = set()
    for row in q4_derived_correlation_delta_diagnostic_result_rows:
        row_id = row.get("target_name", "<q4 derived delta diagnostic result>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_DIAGNOSTIC_RESULT_FIELDS):
            errors.append(
                f"{row_id}: q4-derived-correlation-delta-diagnostic-results.tsv fields do not match the contract"
            )
        target = row.get("target_name", "")
        q4_derived_delta_result_targets.add(target)
        expected_axis_pair = expected_q4_derived_interval_contract_targets.get(target)
        if expected_axis_pair is None:
            errors.append(f"{row_id}: target_name is not recognized")
        elif row.get("axis_pair") != expected_axis_pair:
            errors.append(f"{row_id}: axis_pair must be {expected_axis_pair!r}")
        expected_values = {
            "replicate_id": "derived_delta_001",
            "seed": "202606902",
            "target_kind": "derived_correlation",
            "interval_method": "wald_delta_finite_difference",
            "interval_status": "finite_delta_diagnostic",
            "interval_source": "finite_difference_delta",
            "boundary_clamped": "FALSE",
            "theta_parameter_count": "6",
            "theta_covariance_status": "finite",
            "fit_status": "fit_ok",
            "convergence": "0",
            "converged": "TRUE",
            "pdHess": "TRUE",
            "warning_context": "none",
            "coverage_indicator": "not_evaluated",
            "coverage_mcse": "not_computed_single_replicate",
            "failure_rate_mcse": "not_computed_single_replicate",
            "mcse_status": "insufficient_replicates",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        numeric_fields = (
            "true_value",
            "corpairs_estimate",
            "report_estimate",
            "max_abs_report_corpairs_delta",
            "delta_se",
            "lower",
            "upper",
            "gradient_l2",
            "finite_difference_step_min",
            "finite_difference_step_max",
            "max_gradient",
            "fit_elapsed_sec",
        )
        numeric_values: dict[str, float] = {}
        for field in numeric_fields:
            try:
                numeric_values[field] = float(row.get(field, ""))
            except ValueError:
                errors.append(f"{row_id}: {field} must be numeric")
        if numeric_values.get("max_abs_report_corpairs_delta", 1.0) > 1e-8:
            errors.append(f"{row_id}: report and corpairs estimates must match")
        if numeric_values.get("delta_se", 0.0) <= 0:
            errors.append(f"{row_id}: delta_se must be positive")
        if numeric_values.get("gradient_l2", 0.0) <= 0:
            errors.append(f"{row_id}: gradient_l2 must be positive")
        lower = numeric_values.get("lower")
        upper = numeric_values.get("upper")
        if lower is not None and upper is not None:
            if not lower < upper:
                errors.append(f"{row_id}: lower must be less than upper")
            if lower < -1 or upper > 1:
                errors.append(f"{row_id}: finite diagnostic interval must stay in [-1, 1]")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_derived_delta_result_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("q4-derived-correlation-delta-diagnostic-results.tsv targets changed")

    expected_q4_delta_grid_contracts = {
        "q4_derived_delta_grid_entrypoint": (
            "grid_entrypoint",
            ("replicate_id", "target_name", "coverage_mcse", "failure_rate_mcse"),
        ),
        "q4_derived_delta_grid_seed_scale": (
            "seed_scale_contract",
            ("seed", "sd_scale", "warning_context", "pdHess"),
        ),
        "q4_derived_delta_grid_theta_report": (
            "theta_report_contract",
            ("theta_parameter_count", "theta_covariance_status", "gradient_l2"),
        ),
        "q4_derived_delta_grid_interval_fields": (
            "interval_field_contract",
            ("delta_se", "lower", "upper", "boundary_clamped"),
        ),
        "q4_derived_delta_grid_target_set": (
            "target_set_contract",
            ("axis_pair", "target_name", "corpairs_estimate", "report_estimate"),
        ),
        "q4_derived_delta_grid_denominator": (
            "denominator_contract",
            ("fit_status", "failure_reason", "coverage_indicator", "mcse_status"),
        ),
        "q4_derived_delta_grid_mcse": (
            "mcse_contract",
            ("coverage_mcse", "failure_rate_mcse", "mcse_status"),
        ),
        "q4_derived_delta_grid_claim_boundary": (
            "claim_boundary_contract",
            ("claim_boundary", "status", "evidence_url", "next_gate"),
        ),
    }
    if len(structured_re_q4_derived_correlation_delta_grid_contract_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-contract.tsv must have eight rows"
        )
    q4_delta_grid_contract_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_contract_rows:
        row_id = row.get("contract_id", "<q4 delta grid contract>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_CONTRACT_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-contract.tsv fields do not match the contract"
            )
        q4_delta_grid_contract_ids.add(row_id)
        expected = expected_q4_delta_grid_contracts.get(row_id)
        if expected is None:
            errors.append(f"{row_id}: unexpected q4 delta grid contract row")
            expected_component = None
            expected_fields: tuple[str, ...] = ()
        else:
            expected_component, expected_fields = expected
        if expected_component and row.get("contract_component") != expected_component:
            errors.append(f"{row_id}: contract_component must be {expected_component!r}")
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "denominator_policy": "all_fit_success_warning_failure_rows_retained",
            "mcse_policy": "coverage_mcse_and_failure_rate_mcse_required",
            "failure_policy": "per_target_failure_reason_required",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for required_field in expected_fields:
            if required_field not in row.get("required_output_fields", ""):
                errors.append(
                    f"{row_id}: required_output_fields must include {required_field!r}"
                )
        if "coverage_mcse" not in row.get("mcse_policy", ""):
            errors.append(f"{row_id}: mcse_policy must require coverage_mcse")
        if "failure_rate_mcse" not in row.get("mcse_policy", ""):
            errors.append(f"{row_id}: mcse_policy must require failure_rate_mcse")
        if "failure_reason" not in row.get("failure_policy", ""):
            errors.append(f"{row_id}: failure_policy must require failure_reason")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_delta_grid_contract_ids != set(expected_q4_delta_grid_contracts):
        missing = sorted(set(expected_q4_delta_grid_contracts) - q4_delta_grid_contract_ids)
        extra = sorted(q4_delta_grid_contract_ids - set(expected_q4_delta_grid_contracts))
        errors.append(f"q4 delta grid contract ids changed: missing={missing}, extra={extra}")

    expected_q4_delta_grid_smoke_ids = {
        "q4_derived_delta_grid_smoke_entrypoint": "grid_entrypoint",
        "q4_derived_delta_grid_smoke_seed_scale": "seed_scale_contract",
        "q4_derived_delta_grid_smoke_theta_report": "theta_report_contract",
        "q4_derived_delta_grid_smoke_interval_fields": "interval_field_contract",
        "q4_derived_delta_grid_smoke_target_set": "target_set_contract",
        "q4_derived_delta_grid_smoke_denominator": "denominator_contract",
        "q4_derived_delta_grid_smoke_mcse": "mcse_contract",
        "q4_derived_delta_grid_smoke_claim_boundary": "claim_boundary_contract",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_smoke_status_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-smoke-status.tsv must have eight rows"
        )
    q4_delta_grid_smoke_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_smoke_status_rows:
        row_id = row.get("smoke_id", "<q4 delta grid smoke>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_STATUS_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-smoke-status.tsv fields do not match the contract"
            )
        q4_delta_grid_smoke_ids.add(row_id)
        expected_component = expected_q4_delta_grid_smoke_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid smoke status row")
        elif row.get("smoke_component") != expected_component:
            errors.append(f"{row_id}: smoke_component must be {expected_component!r}")
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "output_artifact": "q4-derived-correlation-delta-grid-smoke-results.tsv",
            "observed_replicates": "1",
            "observed_target_rows": "6",
            "finite_delta_rows": "6",
            "retained_denominator_rows": "6",
            "theta_report_status": "full_vector_theta_phylo_report_reconstruction",
            "interval_status": "finite_delta_diagnostic",
            "mcse_status": "insufficient_replicates",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if "run-calibrated-grid-delta-smoke.R" not in row.get("source_script", ""):
            errors.append(f"{row_id}: source_script must point to the r51 smoke script")
        if "MCSE" not in row.get("next_gate", ""):
            errors.append(f"{row_id}: next_gate must require MCSE before coverage wording")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_delta_grid_smoke_ids != set(expected_q4_delta_grid_smoke_ids):
        missing = sorted(set(expected_q4_delta_grid_smoke_ids) - q4_delta_grid_smoke_ids)
        extra = sorted(q4_delta_grid_smoke_ids - set(expected_q4_delta_grid_smoke_ids))
        errors.append(f"q4 delta grid smoke ids changed: missing={missing}, extra={extra}")

    if len(q4_derived_correlation_delta_grid_smoke_result_rows) != 6:
        errors.append("q4-derived-correlation-delta-grid-smoke-results.tsv must have six rows")
    q4_delta_grid_smoke_targets: set[str] = set()
    for row in q4_derived_correlation_delta_grid_smoke_result_rows:
        row_id = row.get("target_name", "<q4 delta grid smoke result>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_RESULT_FIELDS):
            errors.append(
                f"{row_id}: q4-derived-correlation-delta-grid-smoke-results.tsv fields do not match the contract"
            )
        target = row.get("target_name", "")
        q4_delta_grid_smoke_targets.add(target)
        expected_axis_pair = expected_q4_derived_interval_contract_targets.get(target)
        if expected_axis_pair is None:
            errors.append(f"{row_id}: target_name is not recognized")
        elif row.get("axis_pair") != expected_axis_pair:
            errors.append(f"{row_id}: axis_pair must be {expected_axis_pair!r}")
        expected_values = {
            "replicate_id": "delta_grid_smoke_001",
            "seed": "202606902",
            "target_kind": "derived_correlation",
            "fit_status": "fit_ok",
            "convergence": "0",
            "converged": "TRUE",
            "pdHess": "TRUE",
            "warning_context": "none",
            "failure_reason": "none",
            "theta_parameter_count": "6",
            "theta_covariance_status": "finite",
            "interval_method": "wald_delta_finite_difference",
            "interval_status": "finite_delta_diagnostic",
            "interval_source": "finite_difference_delta",
            "boundary_clamped": "FALSE",
            "coverage_indicator": "not_evaluated",
            "coverage_mcse": "not_computed_single_replicate",
            "failure_rate_mcse": "not_computed_single_replicate",
            "mcse_status": "insufficient_replicates",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        numeric_fields = (
            "true_value",
            "max_gradient",
            "fit_elapsed_sec",
            "corpairs_estimate",
            "report_estimate",
            "max_abs_report_corpairs_delta",
            "gradient_l2",
            "finite_difference_step_min",
            "finite_difference_step_max",
            "delta_se",
            "lower",
            "upper",
        )
        numeric_values: dict[str, float] = {}
        for field in numeric_fields:
            try:
                numeric_values[field] = float(row.get(field, ""))
            except ValueError:
                errors.append(f"{row_id}: {field} must be numeric")
        if numeric_values.get("max_abs_report_corpairs_delta", 1.0) > 1e-8:
            errors.append(f"{row_id}: report and corpairs estimates must match")
        if numeric_values.get("delta_se", 0.0) <= 0:
            errors.append(f"{row_id}: delta_se must be positive")
        if numeric_values.get("gradient_l2", 0.0) <= 0:
            errors.append(f"{row_id}: gradient_l2 must be positive")
        lower = numeric_values.get("lower")
        upper = numeric_values.get("upper")
        if lower is not None and upper is not None:
            if not lower < upper:
                errors.append(f"{row_id}: lower must be less than upper")
            if lower < -1 or upper > 1:
                errors.append(f"{row_id}: finite diagnostic interval must stay in [-1, 1]")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_delta_grid_smoke_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("q4-derived-correlation-delta-grid-smoke-results.tsv targets changed")

    expected_q4_delta_grid_mini_ids = {
        "q4_derived_delta_grid_mini_entrypoint": "grid_entrypoint",
        "q4_derived_delta_grid_mini_seed_scale": "seed_scale_contract",
        "q4_derived_delta_grid_mini_theta_report": "theta_report_contract",
        "q4_derived_delta_grid_mini_interval_fields": "interval_field_contract",
        "q4_derived_delta_grid_mini_target_set": "target_set_contract",
        "q4_derived_delta_grid_mini_denominator": "denominator_contract",
        "q4_derived_delta_grid_mini_mcse": "mcse_contract",
        "q4_derived_delta_grid_mini_claim_boundary": "claim_boundary_contract",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_mini_status_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-mini-status.tsv must have eight rows"
        )
    raw_mini_row_count = len(q4_derived_correlation_delta_grid_mini_result_rows)
    raw_mini_finite_count = sum(
        row.get("interval_status") == "finite_delta_diagnostic"
        for row in q4_derived_correlation_delta_grid_mini_result_rows
    )
    raw_mini_boundary_count = sum(
        row.get("boundary_clamped") == "TRUE"
        for row in q4_derived_correlation_delta_grid_mini_result_rows
    )
    q4_delta_grid_mini_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_mini_status_rows:
        row_id = row.get("mini_id", "<q4 delta grid mini>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_MINI_STATUS_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-mini-status.tsv fields do not match the contract"
            )
        q4_delta_grid_mini_ids.add(row_id)
        expected_component = expected_q4_delta_grid_mini_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid mini status row")
        elif row.get("mini_component") != expected_component:
            errors.append(f"{row_id}: mini_component must be {expected_component!r}")
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "output_artifact": "q4-derived-correlation-delta-grid-mini-results.tsv",
            "scale_levels": "0.35;0.50",
            "observed_replicates": "2",
            "observed_seed_scale_cells": "4",
            "observed_target_rows": str(raw_mini_row_count),
            "finite_delta_rows": str(raw_mini_finite_count),
            "retained_denominator_rows": str(raw_mini_row_count),
            "boundary_clamped_rows": str(raw_mini_boundary_count),
            "theta_report_status": "full_vector_theta_phylo_report_reconstruction",
            "interval_status": "finite_delta_diagnostic",
            "coverage_accounting_status": "diagnostic_true-value_accounting_retains_all_rows",
            "mcse_status": "computed_mini_grid_diagnostic_not_calibrated",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if "run-calibrated-grid-delta-mini.R" not in row.get("source_script", ""):
            errors.append(f"{row_id}: source_script must point to the r52 mini-grid script")
        if "ADEMP-sized" not in row.get("next_gate", ""):
            errors.append(f"{row_id}: next_gate must require an ADEMP-sized grid")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_delta_grid_mini_ids != set(expected_q4_delta_grid_mini_ids):
        missing = sorted(set(expected_q4_delta_grid_mini_ids) - q4_delta_grid_mini_ids)
        extra = sorted(q4_delta_grid_mini_ids - set(expected_q4_delta_grid_mini_ids))
        errors.append(f"q4 delta grid mini ids changed: missing={missing}, extra={extra}")

    if len(q4_derived_correlation_delta_grid_mini_result_rows) != 24:
        errors.append("q4-derived-correlation-delta-grid-mini-results.tsv must have 24 rows")
    q4_delta_grid_mini_targets: set[str] = set()
    q4_delta_grid_mini_replicates: set[str] = set()
    for row in q4_derived_correlation_delta_grid_mini_result_rows:
        row_id = row.get("target_name", "<q4 delta grid mini result>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_MINI_RESULT_FIELDS):
            errors.append(
                f"{row_id}: q4-derived-correlation-delta-grid-mini-results.tsv fields do not match the contract"
            )
        target = row.get("target_name", "")
        q4_delta_grid_mini_targets.add(target)
        q4_delta_grid_mini_replicates.add(row.get("replicate_id", ""))
        expected_axis_pair = expected_q4_derived_interval_contract_targets.get(target)
        if expected_axis_pair is None:
            errors.append(f"{row_id}: target_name is not recognized")
        elif row.get("axis_pair") != expected_axis_pair:
            errors.append(f"{row_id}: axis_pair must be {expected_axis_pair!r}")
        expected_values = {
            "target_kind": "derived_correlation",
            "fit_status": "fit_ok",
            "convergence": "0",
            "converged": "TRUE",
            "pdHess": "TRUE",
            "warning_context": "none",
            "failure_reason": "none",
            "theta_parameter_count": "6",
            "theta_covariance_status": "finite",
            "interval_method": "wald_delta_finite_difference",
            "interval_status": "finite_delta_diagnostic",
            "interval_source": "finite_difference_delta",
            "coverage_indicator": "delta_diagnostic_covers_true",
            "mcse_status": "computed_mini_grid_diagnostic_not_calibrated",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if row.get("seed") not in {"202606902", "202606903"}:
            errors.append(f"{row_id}: seed must be one of the r52 mini-grid seeds")
        if row.get("sd_scale") not in {"0.35", "0.5"}:
            errors.append(f"{row_id}: sd_scale must be one of the r52 mini-grid scales")
        numeric_fields = (
            "true_value",
            "max_gradient",
            "fit_elapsed_sec",
            "corpairs_estimate",
            "report_estimate",
            "max_abs_report_corpairs_delta",
            "gradient_l2",
            "finite_difference_step_min",
            "finite_difference_step_max",
            "delta_se",
            "lower",
            "upper",
            "coverage_mcse",
            "failure_rate_mcse",
        )
        numeric_values: dict[str, float] = {}
        for field in numeric_fields:
            try:
                numeric_values[field] = float(row.get(field, ""))
            except ValueError:
                errors.append(f"{row_id}: {field} must be numeric")
        if numeric_values.get("max_abs_report_corpairs_delta", 1.0) > 1e-8:
            errors.append(f"{row_id}: report and corpairs estimates must match")
        if numeric_values.get("delta_se", 0.0) <= 0:
            errors.append(f"{row_id}: delta_se must be positive")
        if numeric_values.get("gradient_l2", 0.0) <= 0:
            errors.append(f"{row_id}: gradient_l2 must be positive")
        lower = numeric_values.get("lower")
        upper = numeric_values.get("upper")
        if lower is not None and upper is not None:
            if not lower < upper:
                errors.append(f"{row_id}: lower must be less than upper")
            if lower < -1 or upper > 1:
                errors.append(f"{row_id}: finite diagnostic interval must stay in [-1, 1]")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_delta_grid_mini_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("q4-derived-correlation-delta-grid-mini-results.tsv targets changed")
    if q4_delta_grid_mini_replicates != {
        "delta_grid_mini_sd035_001",
        "delta_grid_mini_sd035_002",
        "delta_grid_mini_sd050_001",
        "delta_grid_mini_sd050_002",
    }:
        errors.append("q4-derived-correlation-delta-grid-mini-results.tsv replicate ids changed")

    expected_q4_delta_grid_ademp_contract_ids = {
        "q4_derived_delta_grid_ademp_entrypoint": "grid_entrypoint",
        "q4_derived_delta_grid_ademp_aims": "A_aims",
        "q4_derived_delta_grid_ademp_dgp": "D_dgp",
        "q4_derived_delta_grid_ademp_estimands": "E_estimands",
        "q4_derived_delta_grid_ademp_methods": "M_methods",
        "q4_derived_delta_grid_ademp_performance": "P_performance",
        "q4_derived_delta_grid_ademp_denominator": "denominator_contract",
        "q4_derived_delta_grid_ademp_claim_boundary": "claim_boundary_contract",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_ademp_contract_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-ademp-contract.tsv must have eight rows"
        )
    q4_delta_grid_ademp_contract_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_ademp_contract_rows:
        row_id = row.get("contract_id", "<q4 delta grid ADEMP contract>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_ADEMP_CONTRACT_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-ademp-contract.tsv fields do not match the contract"
            )
        q4_delta_grid_ademp_contract_ids.add(row_id)
        expected_component = expected_q4_delta_grid_ademp_contract_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid ADEMP contract row")
        elif row.get("contract_component") != expected_component:
            errors.append(
                f"{row_id}: contract_component must be {expected_component!r}"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "output_artifact": "q4-derived-correlation-delta-grid-ademp-dry-run.tsv",
            "planned_n_rep": "500",
            "scale_levels": "0.35;0.50",
            "planned_seed_scale_cells": "1000",
            "planned_target_rows": "6000",
            "coverage_mcse_threshold": "0.010",
            "coverage_mcse_at_nominal": "0.009747",
            "failure_rate_reference": "0.05",
            "failure_rate_mcse_at_reference": "0.009747",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if "run-calibrated-grid-delta-ademp-dry-run.R" not in row.get(
            "source_script", ""
        ):
            errors.append(f"{row_id}: source_script must point to the r53 dry-run script")
        if "retain_fit_errors" not in row.get("denominator_policy", ""):
            errors.append(f"{row_id}: denominator_policy must retain failed fits")
        if "boundary_clamped" not in row.get("denominator_policy", ""):
            errors.append(f"{row_id}: denominator_policy must retain clamped rows")
        if "count_clamped_rows" not in row.get("boundary_clamp_policy", ""):
            errors.append(f"{row_id}: boundary_clamp_policy must count clamped rows")
        if "coverage_mcse_threshold_0.01" not in row.get("mcse_policy", ""):
            errors.append(f"{row_id}: mcse_policy must require the coverage MCSE gate")
        if "failure_rate_mcse" not in row.get("mcse_policy", ""):
            errors.append(f"{row_id}: mcse_policy must require failure-rate MCSE")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_delta_grid_ademp_contract_ids != set(expected_q4_delta_grid_ademp_contract_ids):
        missing = sorted(
            set(expected_q4_delta_grid_ademp_contract_ids)
            - q4_delta_grid_ademp_contract_ids
        )
        extra = sorted(
            q4_delta_grid_ademp_contract_ids
            - set(expected_q4_delta_grid_ademp_contract_ids)
        )
        errors.append(
            f"q4 delta grid ADEMP contract ids changed: missing={missing}, extra={extra}"
        )

    if len(q4_derived_correlation_delta_grid_ademp_dry_run_rows) != 12:
        errors.append("q4-derived-correlation-delta-grid-ademp-dry-run.tsv must have 12 rows")
    q4_delta_grid_ademp_targets: set[str] = set()
    q4_delta_grid_ademp_ids: set[str] = set()
    for row in q4_derived_correlation_delta_grid_ademp_dry_run_rows:
        row_id = row.get("dry_run_id", "<q4 delta grid ADEMP dry-run>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_ADEMP_DRY_RUN_FIELDS):
            errors.append(
                f"{row_id}: q4-derived-correlation-delta-grid-ademp-dry-run.tsv fields do not match the contract"
            )
        q4_delta_grid_ademp_ids.add(row_id)
        target = row.get("target_name", "")
        q4_delta_grid_ademp_targets.add(target)
        expected_axis_pair = expected_q4_derived_interval_contract_targets.get(target)
        if expected_axis_pair is None:
            errors.append(f"{row_id}: target_name is not recognized")
        elif row.get("axis_pair") != expected_axis_pair:
            errors.append(f"{row_id}: axis_pair must be {expected_axis_pair!r}")
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "target_kind": "derived_correlation",
            "true_value": "0.05",
            "planned_n_rep": "500",
            "seed_start": "202607500",
            "seed_end": "202607999",
            "planned_seed_scale_cells": "1000",
            "planned_target_rows": "6000",
            "nominal_coverage": "0.95",
            "coverage_mcse_threshold": "0.010",
            "coverage_mcse_at_nominal": "0.009747",
            "failure_rate_reference": "0.05",
            "failure_rate_mcse_at_reference": "0.009747",
            "interval_method": "wald_delta_finite_difference",
            "status": "dry_run_contract",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if row.get("sd_scale") not in {"0.35", "0.5"}:
            errors.append(f"{row_id}: sd_scale must be one of the r53 dry-run scales")
        for required in (
            "retain_fit_errors",
            "pdHess_false",
            "boundary_clamped",
            "finite_rows",
        ):
            if required not in row.get("denominator_policy", ""):
                errors.append(
                    f"{row_id}: denominator_policy must include {required!r}"
                )
        if "count_clamped_rows" not in row.get("boundary_clamp_policy", ""):
            errors.append(f"{row_id}: boundary_clamp_policy must count clamped rows")
        if "failure_rate_mcse" not in row.get("mcse_policy", ""):
            errors.append(f"{row_id}: mcse_policy must require failure-rate MCSE")
        for required_field in (
            "coverage_mcse",
            "failure_rate_mcse",
            "boundary_clamped",
            "failure_reason",
            "warning_context",
        ):
            if required_field not in row.get("output_schema", ""):
                errors.append(f"{row_id}: output_schema must include {required_field!r}")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_delta_grid_ademp_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("q4-derived-correlation-delta-grid-ademp-dry-run.tsv targets changed")
    expected_q4_delta_grid_ademp_ids = {
        f"q4_delta_ademp_sd{scale}_{axis_pair}"
        for scale in ("035", "050")
        for axis_pair in expected_q4_derived_interval_contract_targets.values()
    }
    if q4_delta_grid_ademp_ids != expected_q4_delta_grid_ademp_ids:
        missing = sorted(expected_q4_delta_grid_ademp_ids - q4_delta_grid_ademp_ids)
        extra = sorted(q4_delta_grid_ademp_ids - expected_q4_delta_grid_ademp_ids)
        errors.append(f"q4 delta grid ADEMP dry-run ids changed: missing={missing}, extra={extra}")

    expected_q4_delta_grid_resumable_ids = {
        "q4_derived_delta_grid_resumable_entrypoint": "grid_entrypoint",
        "q4_derived_delta_grid_resumable_output_root": "output_root_contract",
        "q4_derived_delta_grid_resumable_compute": "forced_compute_contract",
        "q4_derived_delta_grid_resumable_resume_skip": "resume_skip_contract",
        "q4_derived_delta_grid_resumable_target_rows": "target_row_contract",
        "q4_derived_delta_grid_resumable_denominator": "denominator_contract",
        "q4_derived_delta_grid_resumable_mcse": "mcse_boundary_contract",
        "q4_derived_delta_grid_resumable_claim_boundary": "claim_boundary_contract",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_resumable_smoke_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv must have eight rows"
        )
    q4_delta_grid_resumable_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_resumable_smoke_rows:
        row_id = row.get("smoke_id", "<q4 delta grid resumable smoke>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_SMOKE_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv fields do not match the contract"
            )
        q4_delta_grid_resumable_ids.add(row_id)
        expected_component = expected_q4_delta_grid_resumable_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid resumable smoke row")
        elif row.get("smoke_component") != expected_component:
            errors.append(
                f"{row_id}: smoke_component must be {expected_component!r}"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "contract_source": "q4-derived-correlation-delta-grid-ademp-dry-run.tsv",
            "observed_cells": "24",
            "computed_actions": "24",
            "skipped_actions": "24",
            "observed_target_rows": "144",
            "finite_delta_rows": "142",
            "retained_denominator_rows": "144",
            "boundary_clamped_rows": "27",
            "resumability_status": "resume_skip_verified",
            "mcse_status": "insufficient_replicates_resumability_smoke",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if "run-calibrated-grid-delta-resumable-smoke.R" not in row.get(
            "source_script", ""
        ):
            errors.append(f"{row_id}: source_script must point to the resumable runner")
        if "run-calibrated-grid-delta-smoke.R" not in row.get(
            "delegated_smoke_script", ""
        ):
            errors.append(f"{row_id}: delegated_smoke_script must point to r51 smoke")
        for field in ("manifest_artifact", "run_log_artifact", "cell_output_root"):
            if not evidence_reference_exists(row.get(field, "")):
                errors.append(f"{row_id}: {field} does not resolve")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        for required in (
            "retain_fit_errors",
            "pdHess_false",
            "boundary_clamped",
            "finite_rows",
        ):
            if required not in row.get("denominator_policy", ""):
                errors.append(
                    f"{row_id}: denominator_policy must include {required!r}"
                )
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_delta_grid_resumable_ids != set(expected_q4_delta_grid_resumable_ids):
        missing = sorted(
            set(expected_q4_delta_grid_resumable_ids)
            - q4_delta_grid_resumable_ids
        )
        extra = sorted(
            q4_delta_grid_resumable_ids
            - set(expected_q4_delta_grid_resumable_ids)
        )
        errors.append(
            f"q4 delta grid resumable smoke ids changed: missing={missing}, extra={extra}"
        )

    if len(q4_derived_correlation_delta_grid_resumable_manifest_rows) != 1:
        errors.append("q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv must have one row")
    else:
        manifest = q4_derived_correlation_delta_grid_resumable_manifest_rows[0]
        if set(manifest.keys()) != set(
            Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_MANIFEST_FIELDS
        ):
            errors.append("q4 delta grid resumable manifest fields do not match the contract")
        expected_manifest_values = {
            "manifest_id": "q4_derived_delta_grid_resumable_smoke_manifest",
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "contract_source": "q4-derived-correlation-delta-grid-ademp-dry-run.tsv",
            "planned_n_rep": "8",
            "scale_levels": "0.35;0.5;0.65",
            "cell_limit": "24",
            "observed_cells": "24",
            "computed_actions": "24",
            "skipped_actions": "24",
            "observed_target_rows": "144",
            "finite_delta_rows": "142",
            "retained_denominator_rows": "144",
            "warning_rows": "48",
            "failure_rows": "30",
            "boundary_clamped_rows": "27",
            "coverage_evaluable_rows": "0",
            "coverage_mcse": "not_computed_resumability_smoke",
            "failure_rate_mcse": "not_computed_resumability_smoke",
            "mcse_status": "insufficient_replicates_resumability_smoke",
            "resumability_status": "resume_skip_verified",
            "status": "resumability_smoke_verified",
        }
        for field, expected_value in expected_manifest_values.items():
            if manifest.get(field) != expected_value:
                errors.append(f"q4 delta grid resumable manifest: {field} must be {expected_value!r}")
        for field in ("source_script", "delegated_smoke_script", "output_root", "manifest_artifact", "run_log_artifact"):
            if not evidence_reference_exists(manifest.get(field, "")):
                errors.append(f"q4 delta grid resumable manifest: {field} does not resolve")
        cell_outputs = [part for part in manifest.get("cell_outputs", "").split(";") if part]
        expected_cell_outputs = [
            f"q4_delta_resumable_sd{scale}_seed{seed}"
            for seed in range(202607500, 202607508)
            for scale in ("035", "050", "065")
        ]
        if len(cell_outputs) != 24:
            errors.append("q4 delta grid resumable manifest must name 24 cell outputs")
        for cell_output in cell_outputs:
            if not evidence_reference_exists(cell_output):
                errors.append(f"q4 delta grid resumable manifest cell output does not resolve: {cell_output}")
        cell_output_ids = {pathlib.Path(cell_output).stem for cell_output in cell_outputs}
        if cell_output_ids != set(expected_cell_outputs):
            missing = sorted(set(expected_cell_outputs) - cell_output_ids)
            extra = sorted(cell_output_ids - set(expected_cell_outputs))
            errors.append(f"q4 delta grid resumable manifest cell outputs changed: missing={missing}, extra={extra}")
        for required in (
            "retain_fit_errors",
            "pdHess_false",
            "boundary_clamped",
            "finite_rows",
        ):
            if required not in manifest.get("denominator_policy", ""):
                errors.append(
                    f"q4 delta grid resumable manifest denominator_policy must include {required!r}"
                )
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in manifest.get("claim_boundary", ""):
                errors.append(
                    f"q4 delta grid resumable manifest claim_boundary must reject {forbidden_claim}"
                )
        if cell_outputs:
            cell_rows = []
            for cell_output in cell_outputs:
                cell_rows.extend(read_tsv(ROOT / cell_output))
            if len(cell_rows) != 144:
                errors.append("q4 delta grid resumable cell outputs must have 144 rows")
            cell_targets = {row.get("target_name", "") for row in cell_rows}
            if cell_targets != set(expected_q4_derived_interval_contract_targets):
                errors.append("q4 delta grid resumable cell output targets changed")
            target_counts: dict[str, int] = {}
            for row in cell_rows:
                target_counts[row.get("target_name", "")] = target_counts.get(row.get("target_name", ""), 0) + 1
            for target_name in expected_q4_derived_interval_contract_targets:
                if target_counts.get(target_name) != 24:
                    errors.append(f"{target_name}: q4 delta grid resumable cell output must appear 24 times")
            cell_summary = {
                "converged_true": 0,
                "pdHess_true": 0,
                "finite_delta_diagnostic": 0,
                "delta_unavailable": 0,
                "failure_none": 0,
                "failure_delta_unavailable": 0,
                "warning_rows": 0,
                "boundary_clamped": 0,
            }
            for row in cell_rows:
                row_id = row.get("target_name", "<q4 delta grid resumable cell>")
                if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_SMOKE_RESULT_FIELDS):
                    errors.append(
                        f"{row_id}: q4 delta grid resumable cell output fields do not match the delegated smoke contract"
                    )
                expected_axis_pair = expected_q4_derived_interval_contract_targets.get(row_id)
                if expected_axis_pair is None:
                    errors.append(f"{row_id}: target_name is not recognized")
                elif row.get("axis_pair") != expected_axis_pair:
                    errors.append(f"{row_id}: axis_pair must be {expected_axis_pair!r}")
                expected_cell_values = {
                    "replicate_id": "delta_grid_smoke_001",
                    "target_kind": "derived_correlation",
                    "fit_status": "fit_ok",
                    "theta_parameter_count": "6",
                    "theta_covariance_status": "finite",
                    "interval_method": "wald_delta_finite_difference",
                    "interval_source": "finite_difference_delta",
                    "coverage_indicator": "not_evaluated",
                    "coverage_mcse": "not_computed_single_replicate",
                    "failure_rate_mcse": "not_computed_single_replicate",
                    "mcse_status": "insufficient_replicates",
                }
                for field, expected_value in expected_cell_values.items():
                    if row.get(field) != expected_value:
                        errors.append(f"{row_id}: {field} must be {expected_value!r}")
                if row.get("seed") not in {str(seed) for seed in range(202607500, 202607508)}:
                    errors.append(f"{row_id}: seed must be one of the r56 pilot seeds")
                if row.get("sd_scale") not in {"0.35", "0.5", "0.65"}:
                    errors.append(f"{row_id}: sd_scale must be one of the r56 pilot scales")
                if row.get("converged") == "TRUE":
                    cell_summary["converged_true"] += 1
                if row.get("pdHess") == "TRUE":
                    cell_summary["pdHess_true"] += 1
                if row.get("interval_status") == "finite_delta_diagnostic":
                    cell_summary["finite_delta_diagnostic"] += 1
                elif row.get("interval_status") == "delta_unavailable":
                    cell_summary["delta_unavailable"] += 1
                else:
                    errors.append(f"{row_id}: interval_status is not recognized")
                if row.get("failure_reason") == "none":
                    cell_summary["failure_none"] += 1
                elif row.get("failure_reason") == "delta_interval_unavailable":
                    cell_summary["failure_delta_unavailable"] += 1
                else:
                    errors.append(f"{row_id}: failure_reason is not recognized")
                if row.get("warning_context") != "none":
                    cell_summary["warning_rows"] += 1
                if row.get("boundary_clamped") == "TRUE":
                    cell_summary["boundary_clamped"] += 1
                for forbidden_claim in (
                    "no q4 interval reliability",
                    "interval coverage",
                    "q4 REML",
                    "AI-REML",
                    "broad bridge support",
                ):
                    if forbidden_claim not in row.get("claim_boundary", ""):
                        errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
            expected_cell_summary = {
                "converged_true": 102,
                "pdHess_true": 114,
                "finite_delta_diagnostic": 142,
                "delta_unavailable": 2,
                "failure_none": 142,
                "failure_delta_unavailable": 2,
                "warning_rows": 48,
                "boundary_clamped": 27,
            }
            for field, expected_value in expected_cell_summary.items():
                if cell_summary[field] != expected_value:
                    errors.append(
                        f"q4 delta grid resumable cell outputs: {field} must be {expected_value}, got {cell_summary[field]}"
                    )

    if len(q4_derived_correlation_delta_grid_resumable_run_log_rows) != 48:
        errors.append("q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv must have 48 rows")
    q4_resumable_actions = []
    expected_r56_cells = {
        "q4_delta_resumable_sd035_seed202607500": ("202607500", "0.35", "1", "6", "0", "0", "2"),
        "q4_delta_resumable_sd050_seed202607500": ("202607500", "0.5", "2", "6", "0", "0", "0"),
        "q4_delta_resumable_sd065_seed202607500": ("202607500", "0.65", "3", "6", "0", "0", "0"),
        "q4_delta_resumable_sd035_seed202607501": ("202607501", "0.35", "4", "6", "0", "0", "3"),
        "q4_delta_resumable_sd050_seed202607501": ("202607501", "0.5", "5", "6", "0", "0", "1"),
        "q4_delta_resumable_sd065_seed202607501": ("202607501", "0.65", "6", "6", "0", "0", "0"),
        "q4_delta_resumable_sd035_seed202607502": ("202607502", "0.35", "7", "6", "0", "0", "1"),
        "q4_delta_resumable_sd050_seed202607502": ("202607502", "0.5", "8", "6", "0", "0", "0"),
        "q4_delta_resumable_sd065_seed202607502": ("202607502", "0.65", "9", "6", "0", "0", "0"),
        "q4_delta_resumable_sd035_seed202607503": ("202607503", "0.35", "10", "6", "6", "0", "3"),
        "q4_delta_resumable_sd050_seed202607503": ("202607503", "0.5", "11", "6", "0", "0", "1"),
        "q4_delta_resumable_sd065_seed202607503": ("202607503", "0.65", "12", "6", "0", "0", "0"),
        "q4_delta_resumable_sd035_seed202607504": ("202607504", "0.35", "13", "6", "6", "6", "3"),
        "q4_delta_resumable_sd050_seed202607504": ("202607504", "0.5", "14", "5", "6", "6", "1"),
        "q4_delta_resumable_sd065_seed202607504": ("202607504", "0.65", "15", "6", "6", "6", "3"),
        "q4_delta_resumable_sd035_seed202607505": ("202607505", "0.35", "16", "6", "6", "6", "1"),
        "q4_delta_resumable_sd050_seed202607505": ("202607505", "0.5", "17", "6", "0", "0", "1"),
        "q4_delta_resumable_sd065_seed202607505": ("202607505", "0.65", "18", "6", "0", "0", "0"),
        "q4_delta_resumable_sd035_seed202607506": ("202607506", "0.35", "19", "6", "6", "0", "2"),
        "q4_delta_resumable_sd050_seed202607506": ("202607506", "0.5", "20", "6", "0", "0", "1"),
        "q4_delta_resumable_sd065_seed202607506": ("202607506", "0.65", "21", "6", "0", "0", "0"),
        "q4_delta_resumable_sd035_seed202607507": ("202607507", "0.35", "22", "6", "6", "0", "2"),
        "q4_delta_resumable_sd050_seed202607507": ("202607507", "0.5", "23", "5", "6", "6", "1"),
        "q4_delta_resumable_sd065_seed202607507": ("202607507", "0.65", "24", "6", "0", "0", "1"),
    }
    for row in q4_derived_correlation_delta_grid_resumable_run_log_rows:
        row_id = row.get("run_label", "<q4 delta grid resumable run log>")
        if set(row.keys()) != set(
            Q4_DERIVED_CORRELATION_DELTA_GRID_RESUMABLE_RUN_LOG_FIELDS
        ):
            errors.append(f"{row_id}: q4 delta grid resumable run-log fields do not match the contract")
        q4_resumable_actions.append((row.get("run_label"), row.get("action")))
        expected_cell = expected_r56_cells.get(row.get("cell_id", ""))
        if expected_cell is None:
            errors.append(f"{row_id}: unexpected q4 delta grid resumable cell_id")
            expected_cell = ("<seed>", "<sd_scale>", "<cell_index>", "<finite_delta_rows>", "<warning_rows>", "<failure_rows>", "<boundary_count>")
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "seed": expected_cell[0],
            "sd_scale": expected_cell[1],
            "cell_index": expected_cell[2],
            "child_status": "0",
            "observed_target_rows": "6",
            "finite_delta_rows": expected_cell[3],
            "retained_denominator_rows": "6",
            "warning_rows": expected_cell[4],
            "failure_rows": expected_cell[5],
            "boundary_clamped_rows": expected_cell[6],
            "coverage_evaluable_rows": "0",
            "coverage_mcse": "not_computed_resumability_smoke",
            "failure_rate_mcse": "not_computed_resumability_smoke",
            "mcse_status": "insufficient_replicates_resumability_smoke",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if not evidence_reference_exists(row.get("cell_output", "")):
            errors.append(f"{row_id}: cell_output does not resolve")
        for required in (
            "retain_fit_errors",
            "pdHess_false",
            "boundary_clamped",
            "finite_rows",
        ):
            if required not in row.get("denominator_policy", ""):
                errors.append(f"{row_id}: denominator_policy must include {required!r}")
        for forbidden_claim in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "broad bridge support",
        ):
            if forbidden_claim not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {forbidden_claim}")
    if q4_resumable_actions != [("r56_totoro_compute", "computed")] * 24 + [
        ("r56_totoro_resume", "skipped_existing")
    ] * 24:
        errors.append("q4 delta grid resumable run log must record 24 r56 totoro computes then 24 skipped_existing actions")
    previous_flags = [
        row.get("previous_output_detected")
        for row in q4_derived_correlation_delta_grid_resumable_run_log_rows
    ]
    if previous_flags != ["FALSE"] * 24 + ["TRUE"] * 24:
        errors.append("q4 delta grid resumable run log must record 24 FALSE then 24 TRUE previous_output_detected flags")

    expected_q4_delta_grid_drac_plan_ids = {
        "q4_derived_delta_grid_drac_shard_plan_entrypoint": "grid_entrypoint",
        "q4_derived_delta_grid_drac_shard_plan_workers": "worker_allocation",
        "q4_derived_delta_grid_drac_shard_plan_assignment": "cell_assignment",
        "q4_derived_delta_grid_drac_shard_plan_write_isolation": "write_isolation",
        "q4_derived_delta_grid_drac_shard_plan_aggregate": "aggregate_gate",
        "q4_derived_delta_grid_drac_shard_plan_mcse": "mcse_gate",
        "q4_derived_delta_grid_drac_shard_plan_hsquared_boundary": "hsquared_boundary",
        "q4_derived_delta_grid_drac_shard_plan_sr150_gate": "sr150_gate",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_drac_shard_plan_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-drac-shard-plan.tsv must have eight rows"
        )
    q4_delta_grid_drac_plan_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_drac_shard_plan_rows:
        row_id = row.get("plan_id", "<q4 delta grid DRAC shard plan>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_SHARD_PLAN_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-drac-shard-plan.tsv fields do not match the contract"
            )
        q4_delta_grid_drac_plan_ids.add(row_id)
        expected_component = expected_q4_delta_grid_drac_plan_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid DRAC shard plan row")
        elif row.get("plan_component") != expected_component:
            errors.append(
                f"{row_id}: plan_component must be {expected_component!r}"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "planned_n_rep": "500",
            "scale_levels": "0.35;0.5",
            "planned_workers": "9",
            "planned_shards": "9",
            "planned_seed_scale_cells": "1000",
            "planned_target_rows": "6000",
            "cells_per_shard": "112;111;111;111;111;111;111;111;111",
            "write_isolation": "private_shard_root_no_shared_append",
            "aggregate_gate": "aggregate_after_every_shard_manifest_exists_and_unique_cell_ids_equal_1000",
            "mcse_policy": "coverage_mcse_at_0.95_equals_0.009747;failure_rate_mcse_at_0.05_equals_0.009747",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in ("source_script", "plan_artifact", "evidence_url"):
            if not evidence_reference_exists(row.get(field, "")):
                errors.append(f"{row_id}: {field} does not resolve")
        if "run-calibrated-grid-delta-drac-shard-plan.R" not in row.get(
            "source_script", ""
        ):
            errors.append(f"{row_id}: source_script must point to the shard plan script")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
        if row_id == "q4_derived_delta_grid_drac_shard_plan_hsquared_boundary":
            if "Study HSquared AI-REML source" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: next_gate must keep HSquared AI-REML as study-first")
        if row_id == "q4_derived_delta_grid_drac_shard_plan_sr150_gate":
            if "two-shard rehearsal" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: next_gate must require a two-shard rehearsal")
    if q4_delta_grid_drac_plan_ids != set(expected_q4_delta_grid_drac_plan_ids):
        missing = sorted(
            set(expected_q4_delta_grid_drac_plan_ids)
            - q4_delta_grid_drac_plan_ids
        )
        extra = sorted(
            q4_delta_grid_drac_plan_ids
            - set(expected_q4_delta_grid_drac_plan_ids)
        )
        errors.append(
            f"q4 delta grid DRAC shard plan ids changed: missing={missing}, extra={extra}"
        )

    if len(q4_derived_correlation_delta_grid_drac_shard_plan_rows) != 9:
        errors.append("q4-derived-correlation-delta-grid-drac-shard-plan.tsv must have nine shard rows")
    expected_worker_labels = [
        "drac01",
        "drac02",
        "drac03",
        "drac04",
        "drac05",
        "drac06",
        "drac07",
        "drac08",
        "totoro",
    ]
    expected_shard_cells = [112, 111, 111, 111, 111, 111, 111, 111, 111]
    observed_shard_cells = 0
    observed_target_rows = 0
    observed_workers: list[str] = []
    observed_shard_ids: set[str] = set()
    for index, row in enumerate(q4_derived_correlation_delta_grid_drac_shard_plan_rows, start=1):
        row_id = row.get("shard_id", "<q4 delta grid DRAC shard>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_SHARD_PLAN_FIELDS):
            errors.append(f"{row_id}: q4 delta grid DRAC shard plan fields do not match the contract")
        observed_shard_ids.add(row_id)
        observed_workers.append(row.get("worker_label", ""))
        expected_values = {
            "shard_id": f"q4_delta_drac_shard_{index:02d}",
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "worker_label": expected_worker_labels[index - 1],
            "n_shards": "9",
            "shard_index": str(index),
            "planned_n_rep": "500",
            "scale_levels": "0.35;0.5",
            "planned_total_cells": "1000",
            "planned_total_target_rows": "6000",
            "planned_shard_cells": str(expected_shard_cells[index - 1]),
            "planned_shard_target_rows": str(expected_shard_cells[index - 1] * 6),
            "write_isolation": "private_shard_root_no_shared_append",
            "assignment_policy": "round_robin_by_seed_scale_cell_index",
            "coverage_mcse_at_nominal": "0.009747",
            "failure_rate_mcse_at_reference": "0.009747",
            "mcse_status": "planned_mcse_gate_not_run",
            "status": "planned_not_run",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if index <= 8 and row.get("worker_role") != "drac_cpu_worker":
            errors.append(f"{row_id}: first eight workers must be DRAC CPU workers")
        if index == 9 and row.get("worker_role") != "totoro_cpu_worker":
            errors.append(f"{row_id}: ninth worker must be the totoro CPU worker")
        for field in (
            "shard_output_root",
            "shard_manifest",
            "shard_run_log",
            "aggregate_manifest",
            "aggregate_summary",
        ):
            if "q4-derived-correlation-delta-grid-drac-shards" not in row.get(field, ""):
                errors.append(f"{row_id}: {field} must stay under the DRAC shard output root")
        if f"--shard-index={index}" not in row.get("runner_command", ""):
            errors.append(f"{row_id}: runner_command must include the shard index")
        for required in (
            "--n-shards=9",
            "--cell-limit=1000",
            "--force=false",
            "--allow-large=true",
            "--manifest-dir=",
            "--run-log-dir=",
        ):
            if required not in row.get("runner_command", ""):
                errors.append(f"{row_id}: runner_command must include {required}")
        if "unique cell_id values, 1000 seed-scale cells, 6000 target rows" not in row.get("aggregate_gate", ""):
            errors.append(f"{row_id}: aggregate_gate must enforce unique cells and target-row counts")
        for required in (
            "retain_fit_errors",
            "pdHess_false",
            "boundary_clamped",
            "finite_rows",
        ):
            if required not in row.get("denominator_policy", ""):
                errors.append(f"{row_id}: denominator_policy must include {required!r}")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
        observed_shard_cells += int(row.get("planned_shard_cells", "0"))
        observed_target_rows += int(row.get("planned_shard_target_rows", "0"))
    if observed_shard_cells != 1000:
        errors.append(f"q4 delta grid DRAC shard plan must sum to 1000 cells, got {observed_shard_cells}")
    if observed_target_rows != 6000:
        errors.append(f"q4 delta grid DRAC shard plan must sum to 6000 target rows, got {observed_target_rows}")
    if observed_workers != expected_worker_labels:
        errors.append("q4 delta grid DRAC shard plan worker labels changed")
    expected_shard_ids = {
        f"q4_delta_drac_shard_{index:02d}" for index in range(1, 10)
    }
    if observed_shard_ids != expected_shard_ids:
        errors.append("q4 delta grid DRAC shard ids changed")

    expected_q4_delta_grid_drac_dispatch_ids = {
        "q4_derived_delta_grid_drac_dispatch_pack_entrypoint": "entrypoint",
        "q4_derived_delta_grid_drac_dispatch_pack_slurm_array": "slurm_array",
        "q4_derived_delta_grid_drac_dispatch_pack_worker": "drac_array_worker",
        "q4_derived_delta_grid_drac_dispatch_pack_totoro": "totoro_worker",
        "q4_derived_delta_grid_drac_dispatch_pack_aggregate": "aggregate_gate",
        "q4_derived_delta_grid_drac_dispatch_pack_storage": "storage_policy",
        "q4_derived_delta_grid_drac_dispatch_pack_mcse": "mcse_gate",
        "q4_derived_delta_grid_drac_dispatch_pack_sr150_gate": "sr150_gate",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_drac_dispatch_pack_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv must have eight rows"
        )
    q4_delta_grid_drac_dispatch_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_drac_dispatch_pack_rows:
        row_id = row.get("pack_id", "<q4 delta grid DRAC dispatch pack>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_PACK_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv fields do not match the contract"
            )
        q4_delta_grid_drac_dispatch_ids.add(row_id)
        expected_component = expected_q4_delta_grid_drac_dispatch_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid DRAC dispatch row")
        elif row.get("pack_component") != expected_component:
            errors.append(
                f"{row_id}: pack_component must be {expected_component!r}"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "planned_n_rep": "500",
            "scale_levels": "0.35;0.5",
            "planned_shards": "9",
            "planned_drac_array_tasks": "8",
            "planned_totoro_shards": "1",
            "planned_seed_scale_cells": "1000",
            "planned_target_rows": "6000",
            "cells_per_shard": "112;111;111;111;111;111;111;111;111",
            "scheduler_status": "slurm_array_dry_run_not_submitted",
            "compute_status": "not_submitted",
            "storage_policy": "project_backed_private_shards_no_login_node_compute",
            "aggregate_gate": "after_all_9_shard_manifests_expect_1000_cells_6000_rows_compute_rate_mcse_true",
            "mcse_policy": "coverage_mcse_at_0.95_equals_0.009747;failure_rate_mcse_at_0.05_equals_0.009747;diagnostic_rate_mcse_requires_compute_rate_mcse_true",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in (
            "source_script",
            "pack_manifest",
            "slurm_array_script",
            "worker_script",
            "totoro_worker_script",
            "aggregate_script",
            "evidence_url",
        ):
            if not evidence_reference_exists(row.get(field, "")):
                errors.append(f"{row_id}: {field} does not resolve")
        if "write-calibrated-grid-delta-drac-dispatch-pack.R" not in row.get(
            "source_script", ""
        ):
            errors.append(f"{row_id}: source_script must point to the dispatch-pack writer")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
            "DRAC readiness",
            "SR150 acceptance",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
        if "no compute on login nodes" not in row.get("next_gate", ""):
            errors.append(f"{row_id}: next_gate must keep login nodes compute-free")
    if q4_delta_grid_drac_dispatch_ids != set(expected_q4_delta_grid_drac_dispatch_ids):
        missing = sorted(
            set(expected_q4_delta_grid_drac_dispatch_ids)
            - q4_delta_grid_drac_dispatch_ids
        )
        extra = sorted(
            q4_delta_grid_drac_dispatch_ids
            - set(expected_q4_delta_grid_drac_dispatch_ids)
        )
        errors.append(
            f"q4 delta grid DRAC dispatch ids changed: missing={missing}, extra={extra}"
        )

    expected_dispatch_components = {
        "manifest",
        "drac_slurm_array",
        "drac_array_worker",
        "totoro_worker",
        "aggregate_afterok",
        "readme",
    }
    if len(q4_derived_correlation_delta_grid_drac_dispatch_pack_rows) != 6:
        errors.append("q4-derived-correlation-delta-grid-drac-dispatch-pack.tsv must have six rows")
    observed_dispatch_components: set[str] = set()
    for row in q4_derived_correlation_delta_grid_drac_dispatch_pack_rows:
        row_id = row.get("pack_component", "<q4 delta grid DRAC dispatch component>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_DRAC_DISPATCH_PACK_FIELDS):
            errors.append(f"{row_id}: q4 delta grid DRAC dispatch pack fields do not match the contract")
        observed_dispatch_components.add(row_id)
        expected_values = {
            "pack_id": "q4_derived_delta_grid_drac_dispatch_pack",
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "planned_n_rep": "500",
            "scale_levels": "0.35;0.5",
            "planned_shards": "9",
            "planned_drac_array_tasks": "8",
            "planned_totoro_shards": "1",
            "planned_seed_scale_cells": "1000",
            "planned_target_rows": "6000",
            "scheduler": "slurm_template_for_drac_plus_separate_totoro_worker",
            "scheduler_status": "dry_run_not_submitted",
            "compute_status": "not_submitted",
            "account_placeholder": "def-pi-placeholder",
            "time_limit": "06:00:00",
            "mem": "16G",
            "cpus_per_task": "4",
            "aggregate_label": "drac_hybrid_full_calibrated_grid",
            "aggregate_gate": "after_all_9_shard_manifests_expect_1000_cells_6000_rows_compute_rate_mcse_true",
            "mcse_policy": "coverage_mcse_at_0.95_equals_0.009747;failure_rate_mcse_at_0.05_equals_0.009747;diagnostic_rate_mcse_requires_compute_rate_mcse_true",
            "storage_policy": "project_backed_private_shards_no_login_node_compute",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        if not evidence_reference_exists(row.get("artifact_path", "")):
            errors.append(f"{row_id}: artifact_path does not resolve")
        if "q4-derived-correlation-delta-grid-drac-shards" not in row.get("output_root", ""):
            errors.append(f"{row_id}: output_root must stay under the DRAC shard root")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
            "DRAC readiness",
            "SR150 acceptance",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
        if "all nine shard manifests exist" not in row.get("next_gate", ""):
            errors.append(f"{row_id}: next_gate must require all nine shard manifests")
    if observed_dispatch_components != expected_dispatch_components:
        missing = sorted(expected_dispatch_components - observed_dispatch_components)
        extra = sorted(observed_dispatch_components - expected_dispatch_components)
        errors.append(
            f"q4 delta grid DRAC dispatch components changed: missing={missing}, extra={extra}"
        )

    dispatch_script_checks = [
        (
            "q4 delta grid DRAC array script",
            q4_derived_correlation_delta_grid_drac_dispatch_array_script,
            (
                "#SBATCH --array=1-8",
                "#SBATCH --cpus-per-task=4",
                "#SBATCH --mem=16G",
                "#SBATCH --account=def-pi-placeholder",
                "q4-derived-correlation-delta-grid-array-worker.sh",
            ),
        ),
        (
            "q4 delta grid DRAC worker script",
            q4_derived_correlation_delta_grid_drac_dispatch_worker_script,
            (
                "SLURM_ARRAY_TASK_ID",
                "--n-shards=9",
                "--cell-limit=1000",
                "--shard-index=\"${SHARD_INDEX}\"",
                "r63_drac_compute",
                "r63_drac_resume",
                "--force=true",
                "--reset-output=true",
                "--reset-log=true",
                "--force=false",
            ),
        ),
        (
            "q4 delta grid totoro worker script",
            q4_derived_correlation_delta_grid_drac_dispatch_totoro_script,
            (
                "SHARD_INDEX=9",
                "--n-shards=9",
                "r63_totoro_compute",
                "r63_totoro_resume",
                "--force=true",
                "--force=false",
            ),
        ),
        (
            "q4 delta grid aggregate script",
            q4_derived_correlation_delta_grid_drac_dispatch_aggregate_script,
            (
                "--n-shards=9",
                "--expected-cells=1000",
                "--expected-target-rows=6000",
                "--aggregate-label=drac_hybrid_full_calibrated_grid",
                "--compute-rate-mcse=true",
            ),
        ),
    ]
    for script_name, script_text, required_tokens in dispatch_script_checks:
        lower_script_text = script_text.lower()
        if "gpu" in lower_script_text:
            errors.append(f"{script_name}: dispatch pack must remain CPU-only")
        for required in required_tokens:
            if required not in script_text:
                errors.append(f"{script_name}: missing {required!r}")

    expected_q4_delta_grid_two_shard_ids = {
        "q4_derived_delta_grid_two_shard_entrypoint": "local_two_shard_entrypoint",
        "q4_derived_delta_grid_two_shard_private_outputs": "private_output_contract",
        "q4_derived_delta_grid_two_shard_resume": "compute_resume_contract",
        "q4_derived_delta_grid_two_shard_aggregate": "aggregate_contract",
        "q4_derived_delta_grid_two_shard_denominator": "denominator_contract",
        "q4_derived_delta_grid_two_shard_mcse": "mcse_boundary_contract",
        "q4_derived_delta_grid_two_shard_no_drac_gate": "local_first_compute_gate",
        "q4_derived_delta_grid_two_shard_claim_boundary": "claim_boundary_contract",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_two_shard_rehearsal_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-two-shard-rehearsal.tsv must have eight rows"
        )
    q4_delta_grid_two_shard_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_two_shard_rehearsal_rows:
        row_id = row.get("rehearsal_id", "<q4 delta grid two-shard rehearsal>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_REHEARSAL_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-two-shard-rehearsal.tsv fields do not match the contract"
            )
        q4_delta_grid_two_shard_ids.add(row_id)
        expected_component = expected_q4_delta_grid_two_shard_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid two-shard rehearsal row")
        elif row.get("rehearsal_component") != expected_component:
            errors.append(
                f"{row_id}: rehearsal_component must be {expected_component!r}"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "n_shards": "2",
            "expected_cells": "4",
            "unique_cells": "4",
            "computed_actions": "4",
            "skipped_actions": "4",
            "observed_target_rows": "24",
            "finite_delta_rows": "24",
            "retained_denominator_rows": "24",
            "boundary_clamped_rows": "6",
            "coverage_evaluable_rows": "0",
            "write_isolation": "private_shard_root_no_shared_append",
            "aggregate_status": "aggregate_verified",
            "mcse_status": "insufficient_replicates_two_shard_rehearsal",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in (
            "source_script",
            "aggregate_script",
            "aggregate_manifest",
            "aggregate_summary",
            "evidence_url",
        ):
            if not evidence_reference_exists(row.get(field, "")):
                errors.append(f"{row_id}: {field} does not resolve")
        if "run-calibrated-grid-delta-resumable-smoke.R" not in row.get("source_script", ""):
            errors.append(f"{row_id}: source_script must point to the resumable runner")
        if "aggregate-calibrated-grid-delta-shards.R" not in row.get("aggregate_script", ""):
            errors.append(f"{row_id}: aggregate_script must point to the shard aggregator")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
        if row_id == "q4_derived_delta_grid_two_shard_no_drac_gate":
            if "Do not use DRAC unless local or totoro evidence is insufficient" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: next_gate must keep DRAC gated behind local/totoro evidence")
    if q4_delta_grid_two_shard_ids != set(expected_q4_delta_grid_two_shard_ids):
        missing = sorted(
            set(expected_q4_delta_grid_two_shard_ids)
            - q4_delta_grid_two_shard_ids
        )
        extra = sorted(
            q4_delta_grid_two_shard_ids
            - set(expected_q4_delta_grid_two_shard_ids)
        )
        errors.append(
            f"q4 delta grid two-shard rehearsal ids changed: missing={missing}, extra={extra}"
        )

    if len(q4_derived_correlation_delta_grid_two_shard_aggregate_manifest_rows) != 1:
        errors.append("q4 two-shard aggregate manifest must have one row")
    else:
        manifest = q4_derived_correlation_delta_grid_two_shard_aggregate_manifest_rows[0]
        if set(manifest.keys()) != set(
            Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_MANIFEST_FIELDS
        ):
            errors.append("q4 two-shard aggregate manifest fields do not match the contract")
        expected_values = {
            "aggregate_id": "q4_delta_grid_two_shard_rehearsal_aggregate",
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "n_shards": "2",
            "unique_cells": "4",
            "computed_actions": "4",
            "skipped_actions": "4",
            "expected_cells": "4",
            "expected_target_rows": "24",
            "observed_target_rows": "24",
            "finite_delta_rows": "24",
            "retained_denominator_rows": "24",
            "warning_rows": "0",
            "failure_rows": "0",
            "boundary_clamped_rows": "6",
            "coverage_evaluable_rows": "0",
            "coverage_mcse": "not_computed_two_shard_rehearsal",
            "failure_rate_mcse": "not_computed_two_shard_rehearsal",
            "mcse_status": "insufficient_replicates_two_shard_rehearsal",
            "aggregate_status": "aggregate_verified",
        }
        for field, expected_value in expected_values.items():
            if manifest.get(field) != expected_value:
                errors.append(f"q4 two-shard aggregate manifest: {field} must be {expected_value!r}")
        for field in ("shard_manifests", "shard_run_logs"):
            for evidence_path in [part for part in manifest.get(field, "").split(";") if part]:
                if not evidence_reference_exists(evidence_path):
                    errors.append(f"q4 two-shard aggregate manifest {field} path does not resolve: {evidence_path}")
        for required in (
            "retain_fit_errors",
            "pdHess_false",
            "boundary_clamped",
            "finite_rows",
        ):
            if required not in manifest.get("denominator_policy", ""):
                errors.append(f"q4 two-shard aggregate manifest denominator_policy must include {required!r}")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in manifest.get("claim_boundary", ""):
                errors.append(f"q4 two-shard aggregate manifest claim_boundary must reject {required}")

    if len(q4_derived_correlation_delta_grid_two_shard_aggregate_summary_rows) != 6:
        errors.append("q4 two-shard aggregate summary must have six target rows")
    two_shard_summary_targets = set()
    expected_two_shard_boundary_rows = {
        "cor_mu1_mu2": ("0", "0"),
        "cor_mu1_sigma1": ("3", "0.75"),
        "cor_mu1_sigma2": ("0", "0"),
        "cor_mu2_sigma1": ("1", "0.25"),
        "cor_mu2_sigma2": ("1", "0.25"),
        "cor_sigma1_sigma2": ("1", "0.25"),
    }
    for row in q4_derived_correlation_delta_grid_two_shard_aggregate_summary_rows:
        row_id = row.get("target_name", "<q4 two-shard aggregate summary>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_SUMMARY_FIELDS):
            errors.append(f"{row_id}: q4 two-shard aggregate summary fields do not match the contract")
        two_shard_summary_targets.add(row_id)
        expected_values = {
            "observed_rows": "4",
            "finite_delta_rows": "4",
            "warning_rows": "0",
            "failure_rows": "0",
            "coverage_evaluable_rows": "0",
            "retained_denominator_rows": "4",
            "coverage_rate": "not_evaluable_two_shard_rehearsal",
            "failure_rate": "0",
            "warning_rate": "0",
            "coverage_mcse": "not_computed_two_shard_rehearsal",
            "failure_rate_mcse": "not_computed_two_shard_rehearsal",
            "warning_rate_mcse": "not_computed_two_shard_rehearsal",
            "boundary_clamp_rate_mcse": "not_computed_two_shard_rehearsal",
            "aggregate_label": "two_shard_rehearsal",
            "mcse_status": "insufficient_replicates_two_shard_rehearsal",
        }
        boundary_expected = expected_two_shard_boundary_rows.get(row_id)
        if boundary_expected is None:
            errors.append(f"{row_id}: unexpected q4 two-shard aggregate summary target")
        else:
            expected_values["boundary_clamped_rows"] = boundary_expected[0]
            expected_values["boundary_clamp_rate"] = boundary_expected[1]
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
    if two_shard_summary_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("q4 two-shard aggregate summary targets changed")

    expected_q4_delta_grid_local_four_shard_ids = {
        "q4_derived_delta_grid_local_four_shard_entrypoint": "local_four_shard_entrypoint",
        "q4_derived_delta_grid_local_four_shard_private_outputs": "private_output_contract",
        "q4_derived_delta_grid_local_four_shard_resume": "compute_resume_contract",
        "q4_derived_delta_grid_local_four_shard_aggregate": "aggregate_contract",
        "q4_derived_delta_grid_local_four_shard_denominator": "denominator_contract",
        "q4_derived_delta_grid_local_four_shard_warning_failure_boundary": "warning_failure_boundary_contract",
        "q4_derived_delta_grid_local_four_shard_no_drac_gate": "local_first_compute_gate",
        "q4_derived_delta_grid_local_four_shard_claim_boundary": "claim_boundary_contract",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_local_four_shard_rehearsal_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-local-four-shard-rehearsal.tsv must have eight rows"
        )
    q4_delta_grid_local_four_shard_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_local_four_shard_rehearsal_rows:
        row_id = row.get("rehearsal_id", "<q4 delta grid local four-shard rehearsal>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_REHEARSAL_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-local-four-shard-rehearsal.tsv fields do not match the contract"
            )
        q4_delta_grid_local_four_shard_ids.add(row_id)
        expected_component = expected_q4_delta_grid_local_four_shard_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid local four-shard rehearsal row")
        elif row.get("rehearsal_component") != expected_component:
            errors.append(
                f"{row_id}: rehearsal_component must be {expected_component!r}"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "n_shards": "4",
            "expected_cells": "12",
            "unique_cells": "12",
            "computed_actions": "12",
            "skipped_actions": "12",
            "observed_target_rows": "72",
            "finite_delta_rows": "71",
            "retained_denominator_rows": "72",
            "warning_rows": "24",
            "failure_rows": "18",
            "boundary_clamped_rows": "17",
            "coverage_evaluable_rows": "0",
            "write_isolation": "private_shard_root_no_shared_append",
            "aggregate_status": "aggregate_verified",
            "mcse_status": "insufficient_replicates_local_four_shard_rehearsal",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in (
            "source_script",
            "aggregate_script",
            "aggregate_manifest",
            "aggregate_summary",
            "evidence_url",
        ):
            if not evidence_reference_exists(row.get(field, "")):
                errors.append(f"{row_id}: {field} does not resolve")
        if "run-calibrated-grid-delta-resumable-smoke.R" not in row.get("source_script", ""):
            errors.append(f"{row_id}: source_script must point to the resumable runner")
        if "aggregate-calibrated-grid-delta-shards.R" not in row.get("aggregate_script", ""):
            errors.append(f"{row_id}: aggregate_script must point to the shard aggregator")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
        if row_id == "q4_derived_delta_grid_local_four_shard_no_drac_gate":
            if "Do not use DRAC unless local or totoro evidence is insufficient" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: next_gate must keep DRAC gated behind local/totoro evidence")
    if q4_delta_grid_local_four_shard_ids != set(expected_q4_delta_grid_local_four_shard_ids):
        missing = sorted(
            set(expected_q4_delta_grid_local_four_shard_ids)
            - q4_delta_grid_local_four_shard_ids
        )
        extra = sorted(
            q4_delta_grid_local_four_shard_ids
            - set(expected_q4_delta_grid_local_four_shard_ids)
        )
        errors.append(
            f"q4 delta grid local four-shard rehearsal ids changed: missing={missing}, extra={extra}"
        )

    if len(q4_derived_correlation_delta_grid_local_four_shard_aggregate_manifest_rows) != 1:
        errors.append("q4 local four-shard aggregate manifest must have one row")
    else:
        manifest = q4_derived_correlation_delta_grid_local_four_shard_aggregate_manifest_rows[0]
        if set(manifest.keys()) != set(
            Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_MANIFEST_FIELDS
        ):
            errors.append("q4 local four-shard aggregate manifest fields do not match the contract")
        expected_values = {
            "aggregate_id": "q4_delta_grid_local_four_shard_rehearsal_aggregate",
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "n_shards": "4",
            "unique_cells": "12",
            "computed_actions": "12",
            "skipped_actions": "12",
            "expected_cells": "12",
            "expected_target_rows": "72",
            "observed_target_rows": "72",
            "finite_delta_rows": "71",
            "retained_denominator_rows": "72",
            "warning_rows": "24",
            "failure_rows": "18",
            "boundary_clamped_rows": "17",
            "coverage_evaluable_rows": "0",
            "coverage_mcse": "not_computed_local_four_shard_rehearsal",
            "failure_rate_mcse": "not_computed_local_four_shard_rehearsal",
            "mcse_status": "insufficient_replicates_local_four_shard_rehearsal",
            "aggregate_status": "aggregate_verified",
        }
        for field, expected_value in expected_values.items():
            if manifest.get(field) != expected_value:
                errors.append(f"q4 local four-shard aggregate manifest: {field} must be {expected_value!r}")
        for field in ("shard_manifests", "shard_run_logs"):
            for evidence_path in [part for part in manifest.get(field, "").split(";") if part]:
                if not evidence_reference_exists(evidence_path):
                    errors.append(f"q4 local four-shard aggregate manifest {field} path does not resolve: {evidence_path}")
        for required in (
            "retain_fit_errors",
            "pdHess_false",
            "boundary_clamped",
            "finite_rows",
        ):
            if required not in manifest.get("denominator_policy", ""):
                errors.append(f"q4 local four-shard aggregate manifest denominator_policy must include {required!r}")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in manifest.get("claim_boundary", ""):
                errors.append(f"q4 local four-shard aggregate manifest claim_boundary must reject {required}")

    if len(q4_derived_correlation_delta_grid_local_four_shard_aggregate_summary_rows) != 6:
        errors.append("q4 local four-shard aggregate summary must have six target rows")
    local_four_shard_summary_targets = set()
    expected_local_four_shard_summary_counts = {
        "cor_mu1_mu2": ("12", "0", "0"),
        "cor_mu1_sigma1": ("12", "4", "0.333333333333333"),
        "cor_mu1_sigma2": ("11", "1", "0.0833333333333333"),
        "cor_mu2_sigma1": ("12", "2", "0.166666666666667"),
        "cor_mu2_sigma2": ("12", "2", "0.166666666666667"),
        "cor_sigma1_sigma2": ("12", "8", "0.666666666666667"),
    }
    for row in q4_derived_correlation_delta_grid_local_four_shard_aggregate_summary_rows:
        row_id = row.get("target_name", "<q4 local four-shard aggregate summary>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_SUMMARY_FIELDS):
            errors.append(f"{row_id}: q4 local four-shard aggregate summary fields do not match the contract")
        local_four_shard_summary_targets.add(row_id)
        expected_values = {
            "observed_rows": "12",
            "warning_rows": "4",
            "failure_rows": "3",
            "coverage_evaluable_rows": "0",
            "retained_denominator_rows": "12",
            "coverage_rate": "not_evaluable_local_four_shard_rehearsal",
            "failure_rate": "0.25",
            "warning_rate": "0.333333333333333",
            "coverage_mcse": "not_computed_local_four_shard_rehearsal",
            "failure_rate_mcse": "not_computed_local_four_shard_rehearsal",
            "warning_rate_mcse": "not_computed_local_four_shard_rehearsal",
            "boundary_clamp_rate_mcse": "not_computed_local_four_shard_rehearsal",
            "aggregate_label": "local_four_shard_rehearsal",
            "mcse_status": "insufficient_replicates_local_four_shard_rehearsal",
        }
        target_expected = expected_local_four_shard_summary_counts.get(row_id)
        if target_expected is None:
            errors.append(f"{row_id}: unexpected q4 local four-shard aggregate summary target")
        else:
            expected_values["finite_delta_rows"] = target_expected[0]
            expected_values["boundary_clamped_rows"] = target_expected[1]
            expected_values["boundary_clamp_rate"] = target_expected[2]
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
    if local_four_shard_summary_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("q4 local four-shard aggregate summary targets changed")

    expected_q4_delta_grid_local_eight_shard_medium_ids = {
        "q4_derived_delta_grid_local_eight_shard_medium_entrypoint": "local_eight_shard_medium_entrypoint",
        "q4_derived_delta_grid_local_eight_shard_medium_private_outputs": "private_output_contract",
        "q4_derived_delta_grid_local_eight_shard_medium_resume": "compute_resume_contract",
        "q4_derived_delta_grid_local_eight_shard_medium_aggregate": "aggregate_contract",
        "q4_derived_delta_grid_local_eight_shard_medium_denominator": "denominator_contract",
        "q4_derived_delta_grid_local_eight_shard_medium_warning_failure_boundary": "warning_failure_boundary_contract",
        "q4_derived_delta_grid_local_eight_shard_medium_no_drac_gate": "local_first_compute_gate",
        "q4_derived_delta_grid_local_eight_shard_medium_claim_boundary": "claim_boundary_contract",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_local_eight_shard_medium_rehearsal_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal.tsv must have eight rows"
        )
    q4_delta_grid_local_eight_shard_medium_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_local_eight_shard_medium_rehearsal_rows:
        row_id = row.get("rehearsal_id", "<q4 delta grid local eight-shard medium rehearsal>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_REHEARSAL_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal.tsv fields do not match the contract"
            )
        q4_delta_grid_local_eight_shard_medium_ids.add(row_id)
        expected_component = expected_q4_delta_grid_local_eight_shard_medium_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid local eight-shard medium rehearsal row")
        elif row.get("rehearsal_component") != expected_component:
            errors.append(
                f"{row_id}: rehearsal_component must be {expected_component!r}"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "n_shards": "8",
            "expected_cells": "48",
            "unique_cells": "48",
            "computed_actions": "48",
            "skipped_actions": "48",
            "observed_target_rows": "288",
            "finite_delta_rows": "276",
            "retained_denominator_rows": "288",
            "warning_rows": "156",
            "failure_rows": "108",
            "boundary_clamped_rows": "61",
            "coverage_evaluable_rows": "0",
            "write_isolation": "private_shard_root_no_shared_append",
            "aggregate_status": "aggregate_verified",
            "mcse_status": "insufficient_replicates_local_eight_shard_medium_rehearsal",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in (
            "source_script",
            "aggregate_script",
            "aggregate_manifest",
            "aggregate_summary",
            "evidence_url",
        ):
            if not evidence_reference_exists(row.get(field, "")):
                errors.append(f"{row_id}: {field} does not resolve")
        if "run-calibrated-grid-delta-resumable-smoke.R" not in row.get("source_script", ""):
            errors.append(f"{row_id}: source_script must point to the resumable runner")
        if "aggregate-calibrated-grid-delta-shards.R" not in row.get("aggregate_script", ""):
            errors.append(f"{row_id}: aggregate_script must point to the shard aggregator")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
        if row_id == "q4_derived_delta_grid_local_eight_shard_medium_no_drac_gate":
            if "Do not use DRAC unless local or totoro evidence is insufficient" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: next_gate must keep DRAC gated behind local/totoro evidence")
    if q4_delta_grid_local_eight_shard_medium_ids != set(expected_q4_delta_grid_local_eight_shard_medium_ids):
        missing = sorted(
            set(expected_q4_delta_grid_local_eight_shard_medium_ids)
            - q4_delta_grid_local_eight_shard_medium_ids
        )
        extra = sorted(
            q4_delta_grid_local_eight_shard_medium_ids
            - set(expected_q4_delta_grid_local_eight_shard_medium_ids)
        )
        errors.append(
            f"q4 delta grid local eight-shard medium rehearsal ids changed: missing={missing}, extra={extra}"
        )

    if len(q4_derived_correlation_delta_grid_local_eight_shard_medium_aggregate_manifest_rows) != 1:
        errors.append("q4 local eight-shard medium aggregate manifest must have one row")
    else:
        manifest = q4_derived_correlation_delta_grid_local_eight_shard_medium_aggregate_manifest_rows[0]
        if set(manifest.keys()) != set(
            Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_MANIFEST_FIELDS
        ):
            errors.append("q4 local eight-shard medium aggregate manifest fields do not match the contract")
        expected_values = {
            "aggregate_id": "q4_delta_grid_local_eight_shard_medium_rehearsal_aggregate",
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "n_shards": "8",
            "unique_cells": "48",
            "computed_actions": "48",
            "skipped_actions": "48",
            "expected_cells": "48",
            "expected_target_rows": "288",
            "observed_target_rows": "288",
            "finite_delta_rows": "276",
            "retained_denominator_rows": "288",
            "warning_rows": "156",
            "failure_rows": "108",
            "boundary_clamped_rows": "61",
            "coverage_evaluable_rows": "0",
            "coverage_mcse": "not_computed_local_eight_shard_medium_rehearsal",
            "failure_rate_mcse": "not_computed_local_eight_shard_medium_rehearsal",
            "mcse_status": "insufficient_replicates_local_eight_shard_medium_rehearsal",
            "aggregate_status": "aggregate_verified",
        }
        for field, expected_value in expected_values.items():
            if manifest.get(field) != expected_value:
                errors.append(f"q4 local eight-shard medium aggregate manifest: {field} must be {expected_value!r}")
        for field in ("shard_manifests", "shard_run_logs"):
            for evidence_path in [part for part in manifest.get(field, "").split(";") if part]:
                if not evidence_reference_exists(evidence_path):
                    errors.append(f"q4 local eight-shard medium aggregate manifest {field} path does not resolve: {evidence_path}")
        for required in (
            "retain_fit_errors",
            "pdHess_false",
            "boundary_clamped",
            "finite_rows",
        ):
            if required not in manifest.get("denominator_policy", ""):
                errors.append(f"q4 local eight-shard medium aggregate manifest denominator_policy must include {required!r}")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in manifest.get("claim_boundary", ""):
                errors.append(f"q4 local eight-shard medium aggregate manifest claim_boundary must reject {required}")

    if len(q4_derived_correlation_delta_grid_local_eight_shard_medium_aggregate_summary_rows) != 6:
        errors.append("q4 local eight-shard medium aggregate summary must have six target rows")
    local_eight_shard_medium_summary_targets = set()
    expected_local_eight_shard_medium_summary_counts = {
        "cor_mu1_mu2": ("46", "0", "0"),
        "cor_mu1_sigma1": ("47", "8", "0.166666666666667"),
        "cor_mu1_sigma2": ("43", "12", "0.25"),
        "cor_mu2_sigma1": ("47", "8", "0.166666666666667"),
        "cor_mu2_sigma2": ("47", "8", "0.166666666666667"),
        "cor_sigma1_sigma2": ("46", "25", "0.520833333333333"),
    }
    for row in q4_derived_correlation_delta_grid_local_eight_shard_medium_aggregate_summary_rows:
        row_id = row.get("target_name", "<q4 local eight-shard medium aggregate summary>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_SUMMARY_FIELDS):
            errors.append(f"{row_id}: q4 local eight-shard medium aggregate summary fields do not match the contract")
        local_eight_shard_medium_summary_targets.add(row_id)
        expected_values = {
            "observed_rows": "48",
            "warning_rows": "26",
            "failure_rows": "18",
            "coverage_evaluable_rows": "0",
            "retained_denominator_rows": "48",
            "coverage_rate": "not_evaluable_local_eight_shard_medium_rehearsal",
            "failure_rate": "0.375",
            "warning_rate": "0.541666666666667",
            "coverage_mcse": "not_computed_local_eight_shard_medium_rehearsal",
            "failure_rate_mcse": "not_computed_local_eight_shard_medium_rehearsal",
            "warning_rate_mcse": "not_computed_local_eight_shard_medium_rehearsal",
            "boundary_clamp_rate_mcse": "not_computed_local_eight_shard_medium_rehearsal",
            "aggregate_label": "local_eight_shard_medium_rehearsal",
            "mcse_status": "insufficient_replicates_local_eight_shard_medium_rehearsal",
        }
        target_expected = expected_local_eight_shard_medium_summary_counts.get(row_id)
        if target_expected is None:
            errors.append(f"{row_id}: unexpected q4 local eight-shard medium aggregate summary target")
        else:
            expected_values["finite_delta_rows"] = target_expected[0]
            expected_values["boundary_clamped_rows"] = target_expected[1]
            expected_values["boundary_clamp_rate"] = target_expected[2]
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
    if local_eight_shard_medium_summary_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("q4 local eight-shard medium aggregate summary targets changed")

    expected_q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids = {
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_entrypoint": "local_sixteen_shard_mcse_pregrid_entrypoint",
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_private_outputs": "private_output_contract",
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_resume": "compute_resume_contract",
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate": "aggregate_contract",
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_denominator": "denominator_contract",
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_diagnostic_mcse": "diagnostic_mcse_contract",
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_no_drac_gate": "local_first_compute_gate",
        "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_claim_boundary": "claim_boundary_contract",
    }
    if len(structured_re_q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_rows) != 8:
        errors.append(
            "structured-re-q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid.tsv must have eight rows"
        )
    q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids: set[str] = set()
    for row in structured_re_q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_rows:
        row_id = row.get("rehearsal_id", "<q4 delta grid local sixteen-shard MCSE pre-grid>")
        if set(row.keys()) != set(
            STRUCTURED_RE_Q4_DERIVED_CORRELATION_DELTA_GRID_LOCAL_FOUR_SHARD_REHEARSAL_FIELDS
        ):
            errors.append(
                f"{row_id}: structured-re-q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid.tsv fields do not match the contract"
            )
        q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids.add(row_id)
        expected_component = expected_q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids.get(row_id)
        if expected_component is None:
            errors.append(f"{row_id}: unexpected q4 delta grid local sixteen-shard MCSE pre-grid row")
        elif row.get("rehearsal_component") != expected_component:
            errors.append(
                f"{row_id}: rehearsal_component must be {expected_component!r}"
            )
        expected_values = {
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "n_shards": "16",
            "expected_cells": "96",
            "unique_cells": "96",
            "computed_actions": "96",
            "skipped_actions": "96",
            "observed_target_rows": "576",
            "finite_delta_rows": "555",
            "retained_denominator_rows": "576",
            "warning_rows": "306",
            "failure_rows": "192",
            "boundary_clamped_rows": "126",
            "coverage_evaluable_rows": "0",
            "write_isolation": "private_shard_root_no_shared_append",
            "aggregate_status": "aggregate_verified",
            "mcse_status": "diagnostic_rate_mcse_computed_coverage_not_evaluable_local_sixteen_shard_mcse_pregrid",
            "status": "covered",
        }
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        for field in (
            "source_script",
            "aggregate_script",
            "aggregate_manifest",
            "aggregate_summary",
            "evidence_url",
        ):
            if not evidence_reference_exists(row.get(field, "")):
                errors.append(f"{row_id}: {field} does not resolve")
        if "run-calibrated-grid-delta-resumable-smoke.R" not in row.get("source_script", ""):
            errors.append(f"{row_id}: source_script must point to the resumable runner")
        if "aggregate-calibrated-grid-delta-shards.R" not in row.get("aggregate_script", ""):
            errors.append(f"{row_id}: aggregate_script must point to the shard aggregator")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
        if row_id == "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_diagnostic_mcse":
            if "coverage remains not_evaluable" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: next_gate must keep coverage not_evaluable")
        if row_id == "q4_derived_delta_grid_local_sixteen_shard_mcse_pregrid_no_drac_gate":
            if "Do not use DRAC unless local or totoro runtime is insufficient" not in row.get("next_gate", ""):
                errors.append(f"{row_id}: next_gate must keep DRAC gated behind local/totoro throughput evidence")
    if q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids != set(expected_q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids):
        missing = sorted(
            set(expected_q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids)
            - q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids
        )
        extra = sorted(
            q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids
            - set(expected_q4_delta_grid_local_sixteen_shard_mcse_pregrid_ids)
        )
        errors.append(
            f"q4 delta grid local sixteen-shard MCSE pre-grid ids changed: missing={missing}, extra={extra}"
        )

    if len(q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate_manifest_rows) != 1:
        errors.append("q4 local sixteen-shard MCSE pre-grid aggregate manifest must have one row")
    else:
        manifest = q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate_manifest_rows[0]
        if set(manifest.keys()) != set(
            Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_MANIFEST_FIELDS
        ):
            errors.append("q4 local sixteen-shard MCSE pre-grid aggregate manifest fields do not match the contract")
        expected_values = {
            "aggregate_id": "q4_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate",
            "slice_id": "SR150",
            "target": "gaussian_q4_phylo",
            "n_shards": "16",
            "unique_cells": "96",
            "computed_actions": "96",
            "skipped_actions": "96",
            "expected_cells": "96",
            "expected_target_rows": "576",
            "observed_target_rows": "576",
            "finite_delta_rows": "555",
            "retained_denominator_rows": "576",
            "warning_rows": "306",
            "failure_rows": "192",
            "boundary_clamped_rows": "126",
            "coverage_evaluable_rows": "0",
            "coverage_mcse": "not_evaluable_local_sixteen_shard_mcse_pregrid",
            "mcse_status": "diagnostic_rate_mcse_computed_coverage_not_evaluable_local_sixteen_shard_mcse_pregrid",
            "aggregate_status": "aggregate_verified",
        }
        for field, expected_value in expected_values.items():
            if manifest.get(field) != expected_value:
                errors.append(f"q4 local sixteen-shard MCSE pre-grid aggregate manifest: {field} must be {expected_value!r}")
        expect_float_close(
            errors,
            "q4 local sixteen-shard MCSE pre-grid aggregate manifest",
            "failure_rate_mcse",
            manifest.get("failure_rate_mcse"),
            0.0483650833406674,
        )
        for field in ("shard_manifests", "shard_run_logs"):
            for evidence_path in [part for part in manifest.get(field, "").split(";") if part]:
                if not evidence_reference_exists(evidence_path):
                    errors.append(f"q4 local sixteen-shard MCSE pre-grid aggregate manifest {field} path does not resolve: {evidence_path}")
        for required in (
            "retain_fit_errors",
            "pdHess_false",
            "boundary_clamped",
            "finite_rows",
        ):
            if required not in manifest.get("denominator_policy", ""):
                errors.append(f"q4 local sixteen-shard MCSE pre-grid aggregate manifest denominator_policy must include {required!r}")
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in manifest.get("claim_boundary", ""):
                errors.append(f"q4 local sixteen-shard MCSE pre-grid aggregate manifest claim_boundary must reject {required}")

    if len(q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate_summary_rows) != 6:
        errors.append("q4 local sixteen-shard MCSE pre-grid aggregate summary must have six target rows")
    local_sixteen_shard_mcse_pregrid_summary_targets = set()
    expected_local_sixteen_shard_mcse_pregrid_summary_counts = {
        "cor_mu1_mu2": ("94", "0", "0", 0.0),
        "cor_mu1_sigma1": ("94", "17", "0.177083333333333", 0.0389610952303824),
        "cor_mu1_sigma2": ("89", "22", "0.229166666666667", 0.0428963510437703),
        "cor_mu2_sigma1": ("94", "17", "0.177083333333333", 0.0389610952303824),
        "cor_mu2_sigma2": ("91", "19", "0.197916666666667", 0.0406644884648323),
        "cor_sigma1_sigma2": ("93", "51", "0.53125", 0.0509312687906457),
    }
    for row in q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_aggregate_summary_rows:
        row_id = row.get("target_name", "<q4 local sixteen-shard MCSE pre-grid aggregate summary>")
        if set(row.keys()) != set(Q4_DERIVED_CORRELATION_DELTA_GRID_TWO_SHARD_AGGREGATE_SUMMARY_FIELDS):
            errors.append(f"{row_id}: q4 local sixteen-shard MCSE pre-grid aggregate summary fields do not match the contract")
        local_sixteen_shard_mcse_pregrid_summary_targets.add(row_id)
        expected_values = {
            "observed_rows": "96",
            "warning_rows": "51",
            "failure_rows": "32",
            "coverage_evaluable_rows": "0",
            "retained_denominator_rows": "96",
            "coverage_rate": "not_evaluable_local_sixteen_shard_mcse_pregrid",
            "failure_rate": "0.333333333333333",
            "warning_rate": "0.53125",
            "coverage_mcse": "not_evaluable_local_sixteen_shard_mcse_pregrid",
            "aggregate_label": "local_sixteen_shard_mcse_pregrid",
            "mcse_status": "diagnostic_rate_mcse_computed_coverage_not_evaluable_local_sixteen_shard_mcse_pregrid",
        }
        target_expected = expected_local_sixteen_shard_mcse_pregrid_summary_counts.get(row_id)
        if target_expected is None:
            errors.append(f"{row_id}: unexpected q4 local sixteen-shard MCSE pre-grid aggregate summary target")
        else:
            expected_values["finite_delta_rows"] = target_expected[0]
            expected_values["boundary_clamped_rows"] = target_expected[1]
            expected_values["boundary_clamp_rate"] = target_expected[2]
        for field, expected_value in expected_values.items():
            if row.get(field) != expected_value:
                errors.append(f"{row_id}: {field} must be {expected_value!r}")
        expect_float_close(
            errors,
            row_id,
            "failure_rate_mcse",
            row.get("failure_rate_mcse"),
            0.0481125224324688,
        )
        expect_float_close(
            errors,
            row_id,
            "warning_rate_mcse",
            row.get("warning_rate_mcse"),
            0.0509312687906457,
        )
        if target_expected is not None:
            expect_float_close(
                errors,
                row_id,
                "boundary_clamp_rate_mcse",
                row.get("boundary_clamp_rate_mcse"),
                target_expected[3],
            )
        for required in (
            "no q4 interval reliability",
            "interval coverage",
            "q4 REML",
            "AI-REML",
            "HSquared transfer",
            "broad bridge support",
        ):
            if required not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must reject {required}")
    if local_sixteen_shard_mcse_pregrid_summary_targets != set(expected_q4_derived_interval_contract_targets):
        errors.append("q4 local sixteen-shard MCSE pre-grid aggregate summary targets changed")

    expected_q4_direct_exports = {
        "mu1": ("gaussian_q4_phylo_sd_mu1", "sd_mu1"),
        "mu2": ("gaussian_q4_phylo_sd_mu2", "sd_mu2"),
        "sigma1": ("gaussian_q4_phylo_sd_sigma1", "sd_sigma1"),
        "sigma2": ("gaussian_q4_phylo_sd_sigma2", "sd_sigma2"),
    }
    if len(structured_re_q4_direct_drmjl_export_rows) != 4:
        errors.append("structured-re-q4-direct-drmjl-export.tsv must have four rows")
    q4_direct_export_axes: set[str] = set()
    for row in structured_re_q4_direct_drmjl_export_rows:
        row_id = row.get("export_id", "<q4 direct DRM.jl export>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_DIRECT_DRMJL_EXPORT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-direct-drmjl-export.tsv fields do not match the contract"
            )
        axis = row.get("axis", "")
        q4_direct_export_axes.add(axis)
        expected = expected_q4_direct_exports.get(axis)
        if expected is None:
            errors.append(f"{row_id}: invalid axis {axis!r}")
        else:
            target, direct_sd_target = expected
            if row.get("target") != target:
                errors.append(f"{row_id}: target does not match {axis}")
            if row.get("direct_sd_target") != direct_sd_target:
                errors.append(f"{row_id}: direct_sd_target does not match {axis}")
        if row.get("dimension") != "q4":
            errors.append(f"{row_id}: dimension must be q4")
        if row.get("route") != "direct_drmjl":
            errors.append(f"{row_id}: route must be direct_drmjl")
        if row.get("estimator") != "ML":
            errors.append(f"{row_id}: estimator must be ML")
        if row.get("sigma_a_source") != "fit.ranef.Sigma_a":
            errors.append(f"{row_id}: sigma_a_source must be fit.ranef.Sigma_a")
        if row.get("direct_status") != "available_point_target":
            errors.append(f"{row_id}: direct_status must be available_point_target")
        if row.get("bridge_status") != "experimental":
            errors.append(f"{row_id}: bridge_status must remain experimental")
        if row.get("inference_status") != "point_target_only":
            errors.append(f"{row_id}: inference_status must remain point_target_only")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if "no R-via-Julia q4 bridge parity" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject q4 bridge parity")
        if "interval coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject interval coverage")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_DIRECT_DRMJL_EXPORT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q4_direct_export_axes = sorted(set(expected_q4_direct_exports) - q4_direct_export_axes)
    if missing_q4_direct_export_axes:
        errors.append(
            "structured-re-q4-direct-drmjl-export.tsv missing axes: "
            + ", ".join(missing_q4_direct_export_axes)
        )

    if len(structured_re_q4_deterministic_fixture_rows) != 1:
        errors.append("structured-re-q4-deterministic-fixture.tsv must have one row")
    for row in structured_re_q4_deterministic_fixture_rows:
        row_id = row.get("fixture_id", "<q4 deterministic fixture>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_DETERMINISTIC_FIXTURE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-deterministic-fixture.tsv fields do not match the contract"
            )
        if row.get("fixture_id") != "q4_deterministic_balanced8":
            errors.append(f"{row_id}: fixture_id must be q4_deterministic_balanced8")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("n_species") != "8":
            errors.append(f"{row_id}: n_species must be 8")
        if row.get("n_obs") != "16":
            errors.append(f"{row_id}: n_obs must be 16")
        if row.get("axes") != "mu1;mu2;sigma1;sigma2":
            errors.append(f"{row_id}: axes must be mu1;mu2;sigma1;sigma2")
        if row.get("direct_sd_targets") != "sd_mu1;sd_mu2;sd_sigma1;sd_sigma2":
            errors.append(f"{row_id}: direct_sd_targets must name all four SD axes")
        if row.get("truth_status") != "known_truth_sigma_a":
            errors.append(f"{row_id}: truth_status must be known_truth_sigma_a")
        if row.get("data_status") != "deterministic_fixture":
            errors.append(f"{row_id}: data_status must be deterministic_fixture")
        if row.get("fit_status") != "not_fit_in_fixture_contract":
            errors.append(f"{row_id}: fit_status must remain not_fit_in_fixture_contract")
        if row.get("bridge_status") != "planned":
            errors.append(f"{row_id}: bridge_status must remain planned")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if "no q4 parity" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject q4 parity")
        if "interval coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject interval coverage")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_DETERMINISTIC_FIXTURE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    expected_q4_tolerance_quantities = {
        "logLik",
        "fixed_coefficients",
        "direct_sd_targets",
        "derived_correlations",
    }
    if len(structured_re_q4_tolerance_policy_rows) != 4:
        errors.append("structured-re-q4-tolerance-policy.tsv must have four rows")
    q4_tolerance_quantities: set[str] = set()
    for row in structured_re_q4_tolerance_policy_rows:
        row_id = row.get("policy_id", "<q4 tolerance policy>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_TOLERANCE_POLICY_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-tolerance-policy.tsv fields do not match the contract"
            )
        quantity = row.get("quantity", "")
        q4_tolerance_quantities.add(quantity)
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if quantity not in expected_q4_tolerance_quantities:
            errors.append(f"{row_id}: invalid quantity {quantity!r}")
        if row.get("comparator_routes") != "native_tmb;direct_drmjl;r_via_julia":
            errors.append(f"{row_id}: comparator_routes must name all three routes")
        if not row.get("tolerance", ""):
            errors.append(f"{row_id}: tolerance must be non-empty")
        if row.get("required_fixture") != "q4_deterministic_balanced8":
            errors.append(f"{row_id}: required_fixture must be q4_deterministic_balanced8")
        if row.get("acceptance_use") != "predeclared_policy_only":
            errors.append(f"{row_id}: acceptance_use must remain predeclared_policy_only")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("bridge_status") != "planned":
            errors.append(f"{row_id}: bridge_status must remain planned")
        if "no q4 parity" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject q4 parity")
        if "interval coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject interval coverage")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_TOLERANCE_POLICY_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    missing_q4_tolerance_quantities = sorted(
        expected_q4_tolerance_quantities - q4_tolerance_quantities
    )
    if missing_q4_tolerance_quantities:
        errors.append(
            "structured-re-q4-tolerance-policy.tsv missing quantities: "
            + ", ".join(missing_q4_tolerance_quantities)
        )

    if len(structured_re_q4_same_fixture_parity_probe_rows) != 1:
        errors.append("structured-re-q4-same-fixture-parity-probe.tsv must have one probe row")
    for row in structured_re_q4_same_fixture_parity_probe_rows:
        row_id = row.get("probe_id", "<q4 same-fixture parity probe>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_SAME_FIXTURE_PARITY_PROBE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-same-fixture-parity-probe.tsv fields do not match the contract"
            )
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("fixture_id") != "q4_30tip_m3_seed42_live_probe":
            errors.append(f"{row_id}: fixture_id must name the live q4 probe")
        for route in ("native_tmb", "r_via_julia", "direct_drmjl_not_compared"):
            if route not in row.get("comparator_routes", ""):
                errors.append(f"{row_id}: comparator_routes must include {route}")
        if not row.get("native_tmb_status", "").startswith("nonconverged"):
            errors.append(f"{row_id}: native_tmb_status must record non-convergence")
        if row.get("direct_drmjl_status") != "point_matrix_export_available_not_compared":
            errors.append(f"{row_id}: direct_drmjl_status must record unavailable same-fixture comparison")
        if row.get("r_via_julia_status") != "converged_point_extractor":
            errors.append(f"{row_id}: r_via_julia_status must record the converged point extractor")
        try:
            loglik_delta = float(row.get("loglik_delta", "nan"))
        except ValueError:
            loglik_delta = float("nan")
        try:
            max_abs_cor_delta = float(row.get("max_abs_cor_delta", "nan"))
        except ValueError:
            max_abs_cor_delta = float("nan")
        if not (0 <= loglik_delta < 1e-3):
            errors.append(f"{row_id}: loglik_delta must remain below 1e-3 for the recorded probe")
        if not (max_abs_cor_delta > 0.05):
            errors.append(f"{row_id}: max_abs_cor_delta must stay above the q4 correlation tolerance")
        for marker in ("negative_probe_superseded", "gt_0.05", "native_nonconverged"):
            if marker not in row.get("tolerance_result", ""):
                errors.append(f"{row_id}: tolerance_result must include {marker}")
        if row.get("acceptance_status") != "negative_probe_superseded_by_calibrated_probe":
            errors.append(f"{row_id}: acceptance_status must record superseded negative evidence")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: status must be covered")
        if row.get("bridge_status") != "experimental":
            errors.append(f"{row_id}: bridge_status must remain experimental")
        for boundary in ("retained negative evidence", "q4 REML", "AI-REML", "interval coverage"):
            if boundary not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must include {boundary}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_SAME_FIXTURE_PARITY_PROBE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    if len(structured_re_q4_calibrated_parity_probe_rows) != 2:
        errors.append("structured-re-q4-calibrated-parity-probe.tsv must have two probe rows")
    calibrated_fixtures = {
        row.get("fixture_id") for row in structured_re_q4_calibrated_parity_probe_rows
    }
    expected_calibrated_fixtures = {
        "q4_balanced32_seed20260802_n4",
        "q4_balanced32_seed31_n8",
    }
    if calibrated_fixtures != expected_calibrated_fixtures:
        errors.append(
            "structured-re-q4-calibrated-parity-probe.tsv fixture_id values must be "
            + ", ".join(sorted(expected_calibrated_fixtures))
        )
    for row in structured_re_q4_calibrated_parity_probe_rows:
        row_id = row.get("probe_id", "<q4 calibrated parity probe>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_CALIBRATED_PARITY_PROBE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-calibrated-parity-probe.tsv fields do not match the contract"
            )
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("n_tip") != "32":
            errors.append(f"{row_id}: n_tip must be 32")
        for route in ("native_tmb", "direct_drmjl", "r_via_julia"):
            if route not in row.get("comparator_routes", ""):
                errors.append(f"{row_id}: comparator_routes must include {route}")
        if row.get("native_tmb_status") != "converged_relative_convergence_code0":
            errors.append(f"{row_id}: native_tmb_status must record converged native fit")
        if row.get("direct_drmjl_status") != "converged_point_matrix_export_matches_wrapper":
            errors.append(f"{row_id}: direct_drmjl_status must record direct-wrapper match")
        if row.get("r_via_julia_status") != "converged_point_reconstruction":
            errors.append(f"{row_id}: r_via_julia_status must record converged wrapper reconstruction")
        numeric_fields = {
            field: row.get(field, "nan")
            for field in (
                "loglik_delta_native_bridge",
                "loglik_delta_direct_bridge",
                "max_abs_fixef_native_bridge",
                "max_abs_sd_native_bridge",
                "max_abs_sd_direct_bridge",
                "max_abs_cor_native_bridge",
                "max_abs_cor_direct_bridge",
            )
        }
        numeric_values = {}
        for field, value in numeric_fields.items():
            try:
                numeric_values[field] = float(value)
            except ValueError:
                numeric_values[field] = float("nan")
                errors.append(f"{row_id}: {field} must be numeric")
        if not (0 <= numeric_values["loglik_delta_native_bridge"] < 1e-3):
            errors.append(f"{row_id}: native-bridge logLik delta must be within the q4 tolerance")
        if not (0 <= numeric_values["max_abs_fixef_native_bridge"] < 5e-3):
            errors.append(f"{row_id}: native-bridge fixed-effect delta must be within q4 tolerance")
        if not (0 <= numeric_values["max_abs_sd_native_bridge"] < 0.02):
            errors.append(f"{row_id}: native-bridge SD delta must be within q4 tolerance")
        if not (0 <= numeric_values["max_abs_cor_native_bridge"] < 0.05):
            errors.append(f"{row_id}: native-bridge correlation delta must be within q4 tolerance")
        if not (0 <= numeric_values["loglik_delta_direct_bridge"] < 1e-12):
            errors.append(f"{row_id}: direct-wrapper logLik delta must be near zero")
        if not (0 <= numeric_values["max_abs_sd_direct_bridge"] < 1e-12):
            errors.append(f"{row_id}: direct-wrapper SD delta must be near zero")
        if not (0 <= numeric_values["max_abs_cor_direct_bridge"] < 1e-12):
            errors.append(f"{row_id}: direct-wrapper correlation delta must be near zero")
        for marker in ("covered_point_parity", "direct_wrapper_match", "within_1e-3"):
            if marker not in row.get("tolerance_result", ""):
                errors.append(f"{row_id}: tolerance_result must include {marker}")
        if row.get("reconstruction_status") != "covered":
            errors.append(f"{row_id}: reconstruction_status must be covered")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: status must be covered")
        if row.get("bridge_status") != "experimental":
            errors.append(f"{row_id}: bridge_status must remain experimental")
        for boundary in ("no broad q4 bridge support", "q4 REML", "AI-REML", "interval coverage"):
            if boundary not in row.get("claim_boundary", ""):
                errors.append(f"{row_id}: claim_boundary must include {boundary}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_Q4_CALIBRATED_PARITY_PROBE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    if len(structured_re_q4_parity_acceptance_gate_rows) != 1:
        errors.append("structured-re-q4-parity-acceptance-gate.tsv must have one row")
    for row in structured_re_q4_parity_acceptance_gate_rows:
        row_id = row.get("gate_id", "<q4 parity acceptance gate>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_PARITY_ACCEPTANCE_GATE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-parity-acceptance-gate.tsv fields do not match the contract"
            )
        if row.get("gate_id") != "q4_parity_acceptance_gate":
            errors.append(f"{row_id}: gate_id must be q4_parity_acceptance_gate")
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("required_fixture") != "q4_calibrated_balanced32_pair":
            errors.append(f"{row_id}: required_fixture must be q4_calibrated_balanced32_pair")
        for required in ("logLik", "fixed_coefficients", "direct_sd_targets", "derived_correlations"):
            if required not in row.get("required_quantities", ""):
                errors.append(f"{row_id}: required_quantities must include {required}")
        if row.get("native_status") != "covered_calibrated_native_tmb_converged":
            errors.append(f"{row_id}: native_status must record calibrated native convergence")
        if row.get("direct_drmjl_status") != "covered_point_export_matches_wrapper":
            errors.append(f"{row_id}: direct_drmjl_status must record point export wrapper parity")
        if row.get("r_via_julia_status") != "covered_calibrated_point_parity":
            errors.append(f"{row_id}: r_via_julia_status must record calibrated point parity")
        if row.get("tolerance_policy") != "predeclared":
            errors.append(f"{row_id}: tolerance_policy must be predeclared")
        if row.get("acceptance_status") != "covered_point_parity_no_interval_claim":
            errors.append(f"{row_id}: acceptance_status must record point-only coverage")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: status must be covered")
        if row.get("bridge_status") != "experimental":
            errors.append(f"{row_id}: bridge_status must remain experimental")
        for missing in ("interval_reliability", "interval_coverage"):
            if missing not in row.get("missing_evidence", ""):
                errors.append(f"{row_id}: missing_evidence must include {missing}")
        if "no broad q4 bridge support" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject broad q4 bridge support")
        if "interval coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject interval coverage")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_PARITY_ACCEPTANCE_GATE_FIELDS
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

    if len(structured_re_q4_corpairs_parity_gate_rows) != 1:
        errors.append("structured-re-q4-corpairs-parity-gate.tsv must have one gate row")
    for row in structured_re_q4_corpairs_parity_gate_rows:
        row_id = row.get("gate_id", "<q4 corpairs parity gate>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_CORPAIRS_PARITY_GATE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-corpairs-parity-gate.tsv fields do not match the contract"
            )
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("extractor") != "corpairs":
            errors.append(f"{row_id}: extractor must be corpairs")
        if row.get("native_status") != "covered_calibrated_native_corpairs":
            errors.append(f"{row_id}: native_status must record calibrated native corpairs")
        if row.get("direct_drmjl_status") != "covered_point_export_matches_wrapper_corpairs":
            errors.append(f"{row_id}: direct_drmjl_status must record direct-wrapper corpairs parity")
        if row.get("r_via_julia_status") != "covered_calibrated_corpairs":
            errors.append(f"{row_id}: r_via_julia_status must record calibrated corpairs parity")
        if row.get("parity_status") != "covered_point_corpairs":
            errors.append(f"{row_id}: parity_status must record point-corpairs coverage")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: status must be covered")
        if row.get("bridge_status") != "experimental":
            errors.append(f"{row_id}: bridge_status must remain experimental")
        for missing in ("interval_reliability", "interval_coverage"):
            if missing not in row.get("missing_evidence", ""):
                errors.append(f"{row_id}: missing_evidence must include {missing}")
        if "interval reliability" not in row.get("required_before_acceptance", ""):
            errors.append(f"{row_id}: required_before_acceptance must keep interval reliability separate")
        if "no broad q4 bridge support" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject broad q4 bridge support")
        if "interval coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject interval coverage")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_CORPAIRS_PARITY_GATE_FIELDS
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

    expected_q4_reml_audit_ids = {
        "native_tmb_q4_ml_effective",
        "native_tmb_q4_reml_rejection",
        "direct_drmjl_q4_patterson_thompson",
        "r_via_julia_q4_patterson_thompson",
        "hsquared_ai_reml_boundary",
    }
    observed_q4_reml_audit_ids: set[str] = set()
    for row in structured_re_q4_reml_requested_effective_audit_rows:
        row_id = row.get("audit_id", "<q4 REML requested/effective audit>")
        if set(row.keys()) != set(STRUCTURED_RE_Q4_REML_REQUESTED_EFFECTIVE_AUDIT_FIELDS):
            errors.append(
                f"{row_id}: structured-re-q4-reml-requested-effective-audit.tsv fields do not match the contract"
            )
        observed_q4_reml_audit_ids.add(row_id)
        if row.get("target") != "gaussian_q4_phylo":
            errors.append(f"{row_id}: target must be gaussian_q4_phylo")
        if row.get("requested_estimator") not in {"ML", "REML", "HSquared_AI_REML"}:
            errors.append(f"{row_id}: invalid requested_estimator {row.get('requested_estimator')!r}")
        if row.get("bridge_status") not in R_BRIDGE_STATUSES:
            errors.append(f"{row_id}: invalid bridge_status {row.get('bridge_status')!r}")
        if row.get("status") != "covered":
            errors.append(f"{row_id}: status must be covered")
        if "not HSquared AI-REML" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject HSquared AI-REML relabeling")
        if "interval coverage" not in row.get("claim_boundary", ""):
            errors.append(f"{row_id}: claim_boundary must reject interval coverage")
        if row_id == "native_tmb_q4_reml_rejection" and row.get("effective_estimator") != "unsupported_no_native_q4_reml":
            errors.append(f"{row_id}: native q4 REML must remain unsupported")
        if row_id == "r_via_julia_q4_patterson_thompson" and row.get("bridge_status") != "experimental":
            errors.append(f"{row_id}: R-via-Julia q4 Patterson-Thompson row must remain experimental")
        if row_id == "hsquared_ai_reml_boundary" and row.get("effective_estimator") != "unsupported_not_run":
            errors.append(f"{row_id}: HSquared AI-REML boundary must remain unsupported_not_run")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_Q4_REML_REQUESTED_EFFECTIVE_AUDIT_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if observed_q4_reml_audit_ids != expected_q4_reml_audit_ids:
        missing = sorted(expected_q4_reml_audit_ids - observed_q4_reml_audit_ids)
        extra = sorted(observed_q4_reml_audit_ids - expected_q4_reml_audit_ids)
        if missing:
            errors.append(
                "structured-re-q4-reml-requested-effective-audit.tsv missing rows: "
                + ", ".join(missing)
            )
        if extra:
            errors.append(
                "structured-re-q4-reml-requested-effective-audit.tsv has extra rows: "
                + ", ".join(extra)
            )

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

    expected_calibration_slices = {f"SR{index}" for index in range(142, 150)}
    calibration_slices: set[str] = set()
    for row in structured_re_coverage_calibration_status_rows:
        row_id = row.get("calibration_id", "<coverage calibration>")
        if set(row.keys()) != set(STRUCTURED_RE_COVERAGE_CALIBRATION_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-coverage-calibration-status.tsv fields do not match the contract"
            )
        slice_id = row.get("slice_id", "")
        calibration_slices.add(slice_id)
        if slice_id not in expected_calibration_slices:
            errors.append(f"{row_id}: unexpected slice_id {slice_id!r}")
        if row.get("dimension") not in {"q1", "q2", "q4", "q1_q2_q4"}:
            errors.append(f"{row_id}: invalid dimension {row.get('dimension')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if "MCSE" not in row.get("mcse_policy", "") and "mcse" not in row.get(
            "mcse_policy", ""
        ):
            errors.append(f"{row_id}: mcse_policy must name MCSE")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_COVERAGE_CALIBRATION_STATUS_FIELDS
        )
        if "denominator" not in row_text:
            errors.append(f"{row_id}: denominator policy must be explicit")
        if "coverage" not in row_text.lower():
            errors.append(f"{row_id}: coverage boundary must be explicit")
        if row.get("slice_id") == "SR144" and "no q4" not in row_text.lower():
            errors.append(f"{row_id}: q4 row must reject q4 promotion")
        if row.get("slice_id") == "SR146" and "not coverage by itself" not in row_text:
            errors.append(f"{row_id}: bootstrap row must reject bootstrap-only coverage")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if calibration_slices != expected_calibration_slices:
        missing = sorted(expected_calibration_slices - calibration_slices)
        extra = sorted(calibration_slices - expected_calibration_slices)
        if missing:
            errors.append(
                "structured-re-coverage-calibration-status.tsv missing slices: "
                + ", ".join(missing)
            )
        if extra:
            errors.append(
                "structured-re-coverage-calibration-status.tsv has extra slices: "
                + ", ".join(extra)
            )

    expected_coverage_acceptance = {
        "q1_coverage_acceptance_gate": "q1",
        "q2_coverage_acceptance_gate": "q2",
        "q4_coverage_acceptance_gate": "q4",
        "integrated_coverage_acceptance_gate": "q1_q2_q4",
    }
    coverage_acceptance_seen: dict[str, str] = {}
    for row in structured_re_coverage_acceptance_gate_rows:
        row_id = row.get("gate_id", "<coverage acceptance gate>")
        if set(row.keys()) != set(STRUCTURED_RE_COVERAGE_ACCEPTANCE_GATE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-coverage-acceptance-gate.tsv fields do not match the contract"
            )
        gate_id = row.get("gate_id", "")
        coverage_acceptance_seen[gate_id] = row.get("dimension", "")
        if row.get("slice_id") != "SR150":
            errors.append(f"{row_id}: slice_id must be SR150")
        if row.get("dimension") not in {"q1", "q2", "q4", "q1_q2_q4"}:
            errors.append(f"{row_id}: invalid dimension {row.get('dimension')!r}")
        if row.get("gate_status") not in {"blocked", "eligible_for_review"}:
            errors.append(f"{row_id}: invalid gate_status {row.get('gate_status')!r}")
        if row.get("status") not in MATRIX_STATUSES | {"blocked"}:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("status") != "blocked":
            errors.append(f"{row_id}: SR150 gate rows must remain blocked until calibrated grids pass")
        try:
            planned_n_rep = int(row.get("planned_n_rep", ""))
        except ValueError:
            planned_n_rep = -1
        if planned_n_rep < 475:
            errors.append(f"{row_id}: planned_n_rep must meet the MCSE-derived minimum")
        for numeric_field in ("observed_target_rows", "finite_interval_rows"):
            try:
                value = int(row.get(numeric_field, ""))
            except ValueError:
                value = -1
            if value < 0:
                errors.append(f"{row_id}: {numeric_field} must be a non-negative integer")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_COVERAGE_ACCEPTANCE_GATE_FIELDS
        )
        if "denominator" not in row_text:
            errors.append(f"{row_id}: failure_policy must keep denominators explicit")
        if "coverage" not in row_text.lower():
            errors.append(f"{row_id}: coverage boundary must be explicit")
        if "no " not in row.get("claim_boundary", "").lower():
            errors.append(f"{row_id}: claim_boundary must be a negative coverage claim")
        if row.get("dimension") in {"q2", "q4", "q1_q2_q4"} and "finite" not in row.get(
            "missing_evidence", ""
        ):
            errors.append(f"{row_id}: q2/q4 acceptance gates must require finite intervals")
        if row.get("dimension") == "q4":
            for forbidden in ("q4 REML", "AI-REML"):
                if forbidden not in row.get("claim_boundary", ""):
                    errors.append(f"{row_id}: q4 claim boundary must reject {forbidden}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if coverage_acceptance_seen != expected_coverage_acceptance:
        missing = sorted(set(expected_coverage_acceptance) - set(coverage_acceptance_seen))
        extra = sorted(set(coverage_acceptance_seen) - set(expected_coverage_acceptance))
        if missing:
            errors.append(
                "structured-re-coverage-acceptance-gate.tsv missing rows: "
                + ", ".join(missing)
            )
        if extra:
            errors.append(
                "structured-re-coverage-acceptance-gate.tsv has extra rows: "
                + ", ".join(extra)
            )

    expected_reml_slices = {f"SR{index}" for index in range(151, 160)}
    reml_slices: set[str] = set()
    for row in structured_re_native_reml_scope_status_rows:
        row_id = row.get("scope_id", "<native REML scope>")
        if set(row.keys()) != set(STRUCTURED_RE_NATIVE_REML_SCOPE_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-native-reml-scope-status.tsv fields do not match the contract"
            )
        slice_id = row.get("slice_id", "")
        reml_slices.add(slice_id)
        if slice_id not in expected_reml_slices:
            errors.append(f"{row_id}: unexpected slice_id {slice_id!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not row.get("requested_estimator") or not row.get("effective_estimator"):
            errors.append(f"{row_id}: requested and effective estimators must be explicit")
        diagnostic_fields = row.get("diagnostic_fields", "")
        if "requested_estimator" not in diagnostic_fields or "effective_estimator" not in diagnostic_fields:
            errors.append(
                f"{row_id}: diagnostic_fields must include requested/effective estimator fields"
            )
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_NATIVE_REML_SCOPE_STATUS_FIELDS
        )
        if row.get("slice_id") == "SR155" and "HSquared AI-REML" not in row_text:
            errors.append(f"{row_id}: q4 row must forbid HSquared AI-REML")
        if row.get("slice_id") == "SR158" and "unsupported" not in row_text.lower():
            errors.append(f"{row_id}: public optimizer row must remain unsupported")
        if row.get("slice_id") == "SR159" and "non-Gaussian REML" not in row_text:
            errors.append(f"{row_id}: non-Gaussian row must name forbidden REML wording")
        if "coverage" in row.get("claim_boundary", "") and "no" not in row.get(
            "claim_boundary", ""
        ).lower():
            errors.append(f"{row_id}: coverage mention must be a rejection")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if reml_slices != expected_reml_slices:
        missing = sorted(expected_reml_slices - reml_slices)
        extra = sorted(reml_slices - expected_reml_slices)
        if missing:
            errors.append(
                "structured-re-native-reml-scope-status.tsv missing slices: "
                + ", ".join(missing)
            )
        if extra:
            errors.append(
                "structured-re-native-reml-scope-status.tsv has extra slices: "
                + ", ".join(extra)
            )

    expected_scope_slices = {f"SR{index}" for index in range(160, 171)}
    scope_slices: set[str] = set()
    for row in structured_re_scope_gate_status_rows:
        row_id = row.get("gate_id", "<scope gate>")
        if set(row.keys()) != set(STRUCTURED_RE_SCOPE_GATE_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-scope-gate-status.tsv fields do not match the contract"
            )
        slice_id = row.get("slice_id", "")
        scope_slices.add(slice_id)
        if slice_id not in expected_scope_slices:
            errors.append(f"{row_id}: unexpected slice_id {slice_id!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        support_status = row.get("support_status", "")
        if not support_status:
            errors.append(f"{row_id}: support_status is empty")
        row_text = " ".join(
            str(row.get(field, ""))
            for field in STRUCTURED_RE_SCOPE_GATE_STATUS_FIELDS
        )
        if slice_id == "SR160" and "blocked" not in row_text.lower():
            errors.append(f"{row_id}: SR160 must remain a blocked acceptance gate")
        if slice_id in {"SR162", "SR164", "SR166", "SR168", "SR169"} and (
            "unsupported" not in row_text.lower()
        ):
            errors.append(f"{row_id}: unsupported scope row must say unsupported")
        if slice_id == "SR165" and "q1" not in row_text.lower():
            errors.append(f"{row_id}: phylo_interaction row must remain q1-scoped")
        if "promote" in row_text.lower() and "does not promote" not in row_text.lower():
            errors.append(f"{row_id}: promotion wording must be a rejection")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
    if scope_slices != expected_scope_slices:
        missing = sorted(expected_scope_slices - scope_slices)
        extra = sorted(scope_slices - expected_scope_slices)
        if missing:
            errors.append(
                "structured-re-scope-gate-status.tsv missing slices: "
                + ", ".join(missing)
            )
        if extra:
            errors.append(
                "structured-re-scope-gate-status.tsv has extra slices: "
                + ", ".join(extra)
            )

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

    r_docs_status_slices: set[str] = set()
    for row in structured_re_r_docs_sync_status_rows:
        row_id = row.get("sync_id", "<R docs sync status>")
        if set(row.keys()) != set(STRUCTURED_RE_R_DOCS_SYNC_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-r-docs-sync-status.tsv fields do not match the contract"
            )
        slice_id = row.get("slice_id", "")
        r_docs_status_slices.add(slice_id)
        if slice_id not in {f"SR{i}" for i in range(171, 181)}:
            errors.append(f"{row_id}: invalid slice_id {slice_id!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not row.get("source_file"):
            errors.append(f"{row_id}: source_file is empty")
        if not row.get("scan_command"):
            errors.append(f"{row_id}: scan_command is empty")
        if not row.get("deferred_terms"):
            errors.append(f"{row_id}: deferred_terms is empty")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_R_DOCS_SYNC_STATUS_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if "coverage claim" in row_text and "no broad support claim" not in row_text and "does not promote" not in row_text:
            errors.append(f"{row_id}: coverage-claim wording must be explicitly negative")
    expected_r_docs_slices = {f"SR{i}" for i in range(171, 181)}
    if r_docs_status_slices != expected_r_docs_slices:
        missing = sorted(expected_r_docs_slices - r_docs_status_slices)
        extra = sorted(r_docs_status_slices - expected_r_docs_slices)
        if missing:
            errors.append(
                "structured-re-r-docs-sync-status.tsv missing slices: "
                + ", ".join(missing)
            )
        if extra:
            errors.append(
                "structured-re-r-docs-sync-status.tsv has extra slices: "
                + ", ".join(extra)
            )

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

    julia_twin_status_slices: set[str] = set()
    for row in structured_re_julia_twin_status_rows:
        row_id = row.get("sync_id", "<Julia twin status>")
        if set(row.keys()) != set(STRUCTURED_RE_JULIA_TWIN_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-julia-twin-status.tsv fields do not match the contract"
            )
        slice_id = row.get("slice_id", "")
        julia_twin_status_slices.add(slice_id)
        if slice_id not in {f"SR{i}" for i in range(181, 191)}:
            errors.append(f"{row_id}: invalid slice_id {slice_id!r}")
        if row.get("repo") not in {"DRM.jl", "drmTMB", "drmTMB+DRM.jl"}:
            errors.append(f"{row_id}: invalid repo {row.get('repo')!r}")
        if row.get("status") not in MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        head = row.get("head", "")
        if not head or head == "unknown":
            errors.append(f"{row_id}: head must name a concrete commit")
        if not row.get("dirty_state"):
            errors.append(f"{row_id}: dirty_state is empty")
        if not row.get("test_command"):
            errors.append(f"{row_id}: test_command is empty")
        if not row.get("test_result"):
            errors.append(f"{row_id}: test_result is empty")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_JULIA_TWIN_STATUS_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if (
            "bridge support" in row_text
            and "not public R bridge support" not in row_text
            and "not broad public R bridge support" not in row_text
            and "does not promote" not in row_text
            and "unpromoted" not in row_text
        ):
            errors.append(f"{row_id}: bridge-support wording must be explicitly negative")
    expected_julia_twin_slices = {f"SR{i}" for i in range(181, 191)}
    if julia_twin_status_slices != expected_julia_twin_slices:
        missing = sorted(expected_julia_twin_slices - julia_twin_status_slices)
        extra = sorted(julia_twin_status_slices - expected_julia_twin_slices)
        if missing:
            errors.append(
                "structured-re-julia-twin-status.tsv missing slices: "
                + ", ".join(missing)
            )
        if extra:
            errors.append(
                "structured-re-julia-twin-status.tsv has extra slices: "
                + ", ".join(extra)
            )

    ayumi_closeout_slices: set[str] = set()
    for row in structured_re_ayumi_closeout_status_rows:
        row_id = row.get("gate_id", "<Ayumi closeout status>")
        if set(row.keys()) != set(STRUCTURED_RE_AYUMI_CLOSEOUT_STATUS_FIELDS):
            errors.append(
                f"{row_id}: structured-re-ayumi-closeout-status.tsv fields do not match the contract"
            )
        slice_id = row.get("slice_id", "")
        ayumi_closeout_slices.add(slice_id)
        if slice_id not in {f"SR{i}" for i in range(191, 201)}:
            errors.append(f"{row_id}: invalid slice_id {slice_id!r}")
        status = row.get("status")
        if status not in MATRIX_STATUSES | {"blocked"}:
            errors.append(f"{row_id}: invalid status {status!r}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        if slice_id in {f"SR{i}" for i in range(191, 199)} and status != "blocked":
            errors.append(f"{row_id}: SR191-SR198 must remain blocked until approval gates pass")
        if slice_id in {"SR199", "SR200"} and status != "covered":
            errors.append(f"{row_id}: SR199-SR200 should be covered by checkpoint/handoff evidence")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_AYUMI_CLOSEOUT_STATUS_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")
        if "posted" in row_text and "No posted URL exists" not in row_text and "No Ayumi reply was posted" not in row_text:
            errors.append(f"{row_id}: posted wording must be explicitly negative")
    expected_ayumi_closeout_slices = {f"SR{i}" for i in range(191, 201)}
    if ayumi_closeout_slices != expected_ayumi_closeout_slices:
        missing = sorted(expected_ayumi_closeout_slices - ayumi_closeout_slices)
        extra = sorted(ayumi_closeout_slices - expected_ayumi_closeout_slices)
        if missing:
            errors.append(
                "structured-re-ayumi-closeout-status.tsv missing slices: "
                + ", ".join(missing)
            )
        if extra:
            errors.append(
                "structured-re-ayumi-closeout-status.tsv has extra slices: "
                + ", ".join(extra)
            )

    for row in structured_re_closeout_package_rows:
        row_id = row.get("closeout_id", "<structured closeout package>")
        if set(row.keys()) != set(STRUCTURED_RE_CLOSEOUT_PACKAGE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-closeout-package.tsv fields do not match the contract"
            )
        if row.get("status") not in MATRIX_STATUSES | {"blocked"}:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if not evidence_reference_exists(row.get("evidence_url", "")):
            errors.append(f"{row_id}: evidence_url does not resolve")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_CLOSEOUT_PACKAGE_FIELDS
        )
        if AI_REML_READY_TRUE_PATTERN.search(row_text) and not PROMOTED_AI_REML_GATE_PATTERN.search(row_text):
            errors.append(f"{row_id}: ai_reml_ready=true without a promoted optimizer gate")

    for row in structured_re_executable_evidence_rows:
        row_id = row.get("evidence_id", "<structured executable evidence>")
        if set(row.keys()) != set(STRUCTURED_RE_EXECUTABLE_EVIDENCE_FIELDS):
            errors.append(
                f"{row_id}: structured-re-executable-evidence.tsv fields do not match the contract"
            )
        if row.get("status") not in SLICE_STATUSES | MATRIX_STATUSES:
            errors.append(f"{row_id}: invalid status {row.get('status')!r}")
        if row.get("claim_status") not in {"executable_guard", "executable_scaffold"}:
            errors.append(f"{row_id}: invalid claim_status {row.get('claim_status')!r}")
        if not evidence_reference_exists(row.get("evidence_path", "")):
            errors.append(f"{row_id}: evidence_path does not resolve")
        for field in ("scope", "artifact", "evidence_class", "test_command", "claim_boundary", "next_gate"):
            if not row.get(field):
                errors.append(f"{row_id}: {field} is empty")
        row_text = " ".join(
            str(row.get(field, "")) for field in STRUCTURED_RE_EXECUTABLE_EVIDENCE_FIELDS
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
        f", {len(structured_re_q_series_support_cell_rows)} structured RE q-series cells"
        f", {len(structured_re_mu_slope_fixture_audit_rows)} structured RE mu-slope audit rows"
        f", {len(structured_re_mu_slope_parity_fixture_rows)} structured RE mu-slope parity-fixture rows"
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
        f", {len(structured_re_q2_payload_contract_rows)} q2 payload-contract rows"
        f", {len(structured_re_q2_payload_provenance_rows)} q2 payload-provenance rows"
        f", {len(structured_re_q2_coefficient_order_map_rows)} q2 coefficient-order rows"
        f", {len(structured_re_q2_direct_drmjl_export_rows)} q2 direct-DRM.jl export rows"
        f", {len(structured_re_q2_acceptance_gate_rows)} q2 acceptance-gate rows"
        f", {len(structured_re_q4_target_contract_rows)} q4 target-contract rows"
        f", {len(structured_re_q4_phylocov_target_map_rows)} q4 phylocov target-map rows"
        f", {len(structured_re_q4_profile_target_bridge_map_rows)} q4 profile-target bridge-map rows"
        f", {len(structured_re_q4_scale_axis_interval_failure_rows)} q4 scale-axis interval-failure rows"
        f", {len(structured_re_q4_interval_diagnostic_plan_rows)} q4 interval-diagnostic plan rows"
        f", {len(structured_re_q4_interval_diagnostic_status_rows)} q4 interval-diagnostic status rows"
        f", {len(structured_re_q4_convergence_probe_rows)} q4 convergence-probe rows"
        f", {len(structured_re_q4_boundary_separated_probe_rows)} q4 boundary-separated probe rows"
        f", {len(structured_re_q4_hessian_diagnostic_status_rows)} q4 hessian-diagnostic status rows"
        f", {len(structured_re_q4_stabilized_fixture_design_rows)} q4 stabilized fixture-design rows"
        f", {len(structured_re_q4_stabilized_preflight_rows)} q4 stabilized preflight rows"
        f", {len(structured_re_q4_stabilized_denominator_extension_rows)} q4 stabilized denominator-extension rows"
        f", {len(structured_re_q4_stabilized_profile_smoke_rows)} q4 stabilized profile-smoke rows"
        f", {len(structured_re_q4_stabilized_all_direct_profile_rows)} q4 stabilized all-direct profile rows"
        f", {len(structured_re_q4_stabilized_profile_denominator_status_rows)} q4 stabilized profile-denominator rows"
        f", {len(structured_re_q4_stabilized_eligible_profile_rows)} q4 stabilized eligible-profile rows"
        f", {len(structured_re_q4_stabilized_coverage_design_rows)} q4 stabilized coverage-design rows"
        f", {len(structured_re_q4_stabilized_grid_runner_contract_rows)} q4 stabilized grid-runner contract rows"
        f", {len(structured_re_q4_stabilized_grid_smoke_status_rows)} q4 stabilized grid-smoke rows"
        f", {len(structured_re_q4_derived_correlation_interval_contract_rows)} q4 derived-correlation interval-contract rows"
        f", {len(structured_re_q4_derived_correlation_interval_smoke_rows)} q4 derived-correlation interval-smoke rows"
        f", {len(structured_re_q4_derived_correlation_delta_diagnostic_rows)} q4 derived-correlation delta-diagnostic rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_contract_rows)} q4 derived-correlation delta-grid contract rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_smoke_status_rows)} q4 derived-correlation delta-grid smoke rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_mini_status_rows)} q4 derived-correlation delta-grid mini rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_ademp_contract_rows)} q4 derived-correlation delta-grid ADEMP contract rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_resumable_smoke_rows)} q4 derived-correlation delta-grid resumable-smoke rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_drac_shard_plan_rows)} q4 derived-correlation delta-grid DRAC shard-plan rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_drac_dispatch_pack_rows)} q4 derived-correlation delta-grid DRAC dispatch-pack rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_two_shard_rehearsal_rows)} q4 derived-correlation delta-grid two-shard rehearsal rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_local_four_shard_rehearsal_rows)} q4 derived-correlation delta-grid local four-shard rehearsal rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_local_eight_shard_medium_rehearsal_rows)} q4 derived-correlation delta-grid local eight-shard medium rehearsal rows"
        f", {len(structured_re_q4_derived_correlation_delta_grid_local_sixteen_shard_mcse_pregrid_rows)} q4 derived-correlation delta-grid local sixteen-shard MCSE pre-grid rows"
        f", {len(structured_re_q4_direct_drmjl_export_rows)} q4 direct-DRM.jl export rows"
        f", {len(structured_re_q4_deterministic_fixture_rows)} q4 deterministic fixture rows"
        f", {len(structured_re_q4_tolerance_policy_rows)} q4 tolerance-policy rows"
        f", {len(structured_re_q4_same_fixture_parity_probe_rows)} q4 same-fixture parity-probe rows"
        f", {len(structured_re_q4_calibrated_parity_probe_rows)} q4 calibrated parity-probe rows"
        f", {len(structured_re_q4_parity_acceptance_gate_rows)} q4 parity-acceptance gate rows"
        f", {len(structured_re_q4_extractor_parity_rows)} q4 extractor-parity rows"
        f", {len(structured_re_q4_corpairs_parity_gate_rows)} q4 corpairs-parity gate rows"
        f", {len(structured_re_q4_bridge_boundary_rows)} q4 bridge-boundary rows"
        f", {len(structured_re_q4_reml_requested_effective_audit_rows)} q4 REML requested/effective audit rows"
        f", {len(structured_re_reml_scope_gate_rows)} REML scope-gate rows"
        f", {len(structured_re_ademp_design_rows)} ADEMP design rows"
        f", {len(structured_re_coverage_calibration_status_rows)} coverage-calibration rows"
        f", {len(structured_re_coverage_acceptance_gate_rows)} coverage-acceptance gate rows"
        f", {len(structured_re_native_reml_scope_status_rows)} native-REML scope rows"
        f", {len(structured_re_scope_gate_status_rows)} scope-gate rows"
        f", {len(structured_re_type_gap_rows)} structured type-gap rows"
        f", {len(structured_re_r_docs_api_sync_rows)} R docs/API sync rows"
        f", {len(structured_re_r_docs_sync_status_rows)} R docs sync-status rows"
        f", {len(structured_re_julia_twin_sync_rows)} Julia twin-sync rows"
        f", {len(structured_re_julia_twin_status_rows)} Julia twin-status rows"
        f", {len(structured_re_ayumi_closeout_status_rows)} Ayumi closeout-status rows"
        f", {len(structured_re_closeout_package_rows)} closeout-package rows"
        f", {len(structured_re_executable_evidence_rows)} executable-evidence rows"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
