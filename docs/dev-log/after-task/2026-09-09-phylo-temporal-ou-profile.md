# After-task — phylogenetic-stable plus independent OU profile gate

## 1. Goal

Prove the G8 fixed-mean profile endpoint contract for the approved paired phylogenetic stable-intercept plus independent OU Gaussian ML model.

## 2. Implemented

Added an independent dense-Cholesky profile reference and a focused G8 suite. It re-optimizes all nuisance parameters at fixed `beta_mu:x`, finds likelihood-ratio crossings, compares public endpoints, tests deferred-target errors and checks the irregular-Hessian warning.

## 3a. Decisions and Rejected Alternatives

The dense reference uses `nlminb()` only on the direct covariance likelihood and does not call `TMB::tmbprofile()` or drmTMB profile helpers. The check uses a 90% interval to keep the deterministic bracket compact. It does not qualify coverage; calibration remains a later G10–G13 concern.

## 4. Files Touched

- `tests/testthat/helper-phylo-temporal-ou-reference.R`
- `tests/testthat/test-phylo-temporal-ou-profile.R`
- `tests/testthat/test-phylo-temporal-ou-gate-runner.R`
- `tools/phylo-temporal-ou-gates.R`
- G8 ledger, check log, this report and matching plan-versus-actual record

## 5. Checks Run

The exact G8 command returned `PHYLO_TEMPORAL_OU_G8_PASS`. The paired parser, dense oracle, methods, profile, temporal parser, temporal OU and runner regression files passed. `git diff --check` passed.

## 6. Tests of the Tests

A measured profile pilot took about one second. The direct dense prototype gave 90% endpoints 0.17577 and 0.59428 versus public 0.17544 and 0.59399, establishing the 0.005 tolerance before the final test was written.

## 7a. Issue Ledger

No G8 defect remains. Wald covariance, variance/decay intervals, bootstrap, forecasts and `newdata` profile intervals remain intentionally unavailable.

## 8. Consistency Audit

The reference covariance is the same independent stable-phylogenetic plus same-species OU covariance verified in G3–G6. At every constrained coefficient it re-estimates residual scale, both variance components and decay, so the comparison includes nuisance-parameter uncertainty without transferring the unqualified Wald covariance.

## 9. What Did Not Go Smoothly

The first combined fixture scan showed several legitimate phylogenetic-SD boundary fits. G8 uses the preselected finite, positive-SD fixture from G7 so the profile comparison has an interior optimum.

## 10. Known Residuals

This gate does NOT establish 95% coverage or any campaign result. It does NOT make variance, decay, bootstrap, forecast, Wald or `newdata` intervals available.

## 11. Team Learning

A public profile engine can be checked without duplicating its implementation: independently profile the dense marginal likelihood under the same constrained coefficient and compare likelihood-ratio crossings.

## 12. Cross-Product Coverage

This gate does NOT cover the separable phylogeny-by-OU field, heterogeneous structures, Toeplitz, ARMA, seasonal, random-walk or temporal Matérn models.
