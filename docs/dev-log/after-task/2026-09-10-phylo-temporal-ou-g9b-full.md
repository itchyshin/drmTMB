# After-task — G9b full phylogenetic-stable plus independent OU recovery

## 1. Goal

Run the separately approved G9b point-recovery study for the already implemented temporal OU term composed with an existing phylogenetic stable intercept.

## 2. Implemented

The retained runner freezes 24 contrast fixtures and 300 independently generated tree-and-response replicates. It uses the established temporal OU formula and existing `phylo()` infrastructure; it does not add or alter a phylogenetic covariance model.

## 3a. Decisions and Rejected Alternatives

G9 remains a failed historical gate. G9b evaluates reportable between- and within-species contrasts separately, then uses a 300-tree ensemble to evaluate population-intercept bias. It does not promote interval inference, forecasting, `newdata`, a separable phylogeny-by-time field, or the next temporal structure.

## 4. Files Touched

- `tools/run-phylo-temporal-ou-g9b-full.R`
- `tools/phylo-temporal-ou-gates.R`
- `tests/testthat/test-phylo-temporal-ou-gate-runner.R`
- `docs/dev-log/plans/2026-09-09-phylo-temporal-ou/unlazy/GATES.md`
- retained v1--v5 artifacts under `docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g9b-full*`
- this report, its plan-versus-actual record, check log entry, and the cross-project handoff note

## 5. Checks Run

The focused gate-runner test passed before each frozen runner checkpoint. The direct immutable-artifact verifier returned `PHYLO_TEMPORAL_OU_G9B_FULL_PASS`. It verified 24 contrast fixtures, 48 contrast attempts, 300 ensemble fits, 600 ensemble attempts, complete manifests, all 12 criteria, and runner provenance.

## 6. Tests of the Tests

The gate-runner test asserts that G9b-full fails closed before artifacts exist. The first four retained study directories demonstrate independent negative controls: v1 used the wrong residual-SD key, v2/v3 exposed empty-summary handling, and v4 showed that the parser rejects `tree = generated$tree` because it requires a named tree object. The successful v5 binds that same existing tree to the local name `tree`; no model code changed.

## 7a. Issue Ledger

No matching gllvmTMB GitHub issue was found locally. GitHub's API was unreachable when this report was written, so no external issue was created. The requested ready-to-post handoff is retained at `docs/dev-log/handover/2026-09-10-gllvmtmb-phylo-temporal-ou.md`.

## 8. Consistency Audit

The G9b success is labelled only as replacement point-recovery evidence. The public article, grammar, likelihood documentation, and limitation register remain development-marked because G10--G13 interval-calibration and campaign gates are still pending. The historical G9 failure remains visible.

## 9. What Did Not Go Smoothly

The first full-run harness versions had four runner-level defects. All partial outputs are retained rather than overwritten. The eventual fit-bearing v5 had 46 optimizer or covariance warnings across difficult simulated cases; its denominators and all predeclared criteria nevertheless passed, and warnings remain in the run output.

## 10. Known Residuals

This result is not coverage calibration. It does not support confidence intervals, variance or decay intervals, profiles as evidence, forecasting, `newdata`, the separable phylogeny-by-OU field, Toeplitz, heterogeneous temporal structures, ARMA, seasonal, random-walk, or temporal Matérn models.

## 11. Team Learning

A formula parser may correctly require `tree = tree` even when a nested expression evaluates to a phylogeny. Simulation harnesses should bind structured objects to the user-facing symbol before constructing formulas, then retain parser failures as evidence of that contract.

## 12. Cross-Product Coverage

This validates only additive composition of a stable phylogenetic intercept with independent within-species temporal OU deviations. It does NOT cover phylogenetic propagation through time, a separable phylogeny-by-OU field, REML, penalties, missing-response handling, a Julia engine, aggregation, spatial effects, or any new phylogenetic implementation.
