# After-task — phylogenetic-stable plus independent OU methods gate

## 1. Goal

Prove the G7 public-method contract for the approved paired phylogenetic stable-intercept plus independent OU Gaussian ML fit.

## 2. Implemented

Added a focused paired-model methods suite and G7 runner worker. It reconstructs conditional fitted values, response residuals, conditional simulation and fresh simulation from the fixed, phylogenetic and temporal components.

## 3a. Decisions and Rejected Alternatives

The suite uses a deterministic non-boundary fixture so omitting either component is detectable. It records the actual nested `terms` metadata rather than assuming terms are plain character labels. It does not test dense profile endpoints; that is G8.

## 4. Files Touched

- `tests/testthat/test-phylo-temporal-ou-methods.R`
- `tests/testthat/test-phylo-temporal-ou-gate-runner.R`
- `tools/phylo-temporal-ou-gates.R`
- `docs/dev-log/plans/2026-09-09-phylo-temporal-ou/unlazy/GATES.md`
- this report and the matching plan-versus-actual record
- `docs/dev-log/check-log.md`

## 5. Checks Run

The G7 runner returned `PHYLO_TEMPORAL_OU_G7_PASS`. Focused paired parser, dense oracle, methods, temporal parser, temporal OU and runner tests passed. `git diff --check` passed.

## 6. Tests of the Tests

The initial G7 runner invocation failed because G7 did not exist. The first focused suite then exposed incorrect assumptions about nested labels, a phylogenetic boundary fixture and premature profile readiness; the repaired suite verifies the real object contract and passes 25 assertions.

## 7a. Issue Ledger

No new model defect remains in the G7 scope. Fixed-mean profiles require the separate G8 dense-profile check and later calibration; Wald covariance remains deliberately unqualified for OU.

## 8. Consistency Audit

The test mirrors `drm_ordinary_random_effect_draws()`: it draws structured phylogenetic effects before independent temporal OU paths, then Gaussian residual noise. The public fitted value is the matching sum of fixed, phylogenetic and temporal contributions. This matches the P1 covariance contract without implying a separable field.

## 9. What Did Not Go Smoothly

A first fixture placed the phylogenetic SD at its numerical boundary, masking the stable component. The deterministic scan selected a finite non-boundary fixture instead.

## 10. Known Residuals

This gate does NOT cover profile-likelihood endpoints, recovery, calibration, article rendering, package checks, campaigns or later temporal structures. It does NOT make Wald, variance, decay, bootstrap, forecast or newdata intervals available.

## 11. Team Learning

For additive latent components, simulation tests must reproduce the exact random-number draw order and use a fixture where each component materially contributes. Otherwise a passing test can hide a dropped term.

## 12. Cross-Product Coverage

This gate does NOT cover the future separable phylogeny-by-OU field, heterogeneous structures, ARMA, seasonal, random-walk or temporal Matérn models.
