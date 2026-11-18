# After Task: Native probit phylogenetic Bernoulli SD check

## 1. Goal

Add direct synthetic evidence that the native TMB Binomial path fits a predictor-dependent phylogenetic random-effect SD with a probit link.

## 2. Implemented

Added a deterministic 80-tip probit recovery case to the existing Binomial phylogenetic SD test. It checks convergence, recovery of the positive SD slope within 0.25 of truth, agreement between link-scale and response-scale SD predictions, and agreement of tip-level predictions with the fitted SD formula. A constant-SD probit fit also matches the scalar phylogenetic model in likelihood and SD intercept. The model is
`P(y_i = 1) = Phi(x_i beta + b_s)` with `b ~ N(0, D A D)` and `D_ss = exp(z_s alpha)`.

The Student Julia bridge label mapping was also reviewed in the active candidate. Its existing Student-specific route maps intercept and selected-slope SD labels to Julia's `sd` block. The focused bridge test passed with two live Julia fits after setting `DRM_JL_JULIA_HOME` and `DRM_JL_PATH`; no source edit was needed for that slice.

## 3a. Decisions and Rejected Alternatives

The test keeps the supplied phylogenetic kernel scaling and uses the probit response link. It adds no Bernoulli residual scale. The initial 24-tip fixture was rejected after its deterministic draw yielded a highly unstable SD slope; increasing the number of tips provided a higher-information check without loosening the recovery tolerance.

## 4. Files Touched

- `tests/testthat/test-binomial-phylo-sd-regression.R`
- `docs/dev-log/check-log.d/2026-10-25-native-binomial-probit-phylo-sd-check.md`
- This after-task report

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "julia-student-sd", reporter = "summary")'`: bridge label assertions passed; two live tests were skipped because the Julia path was unset.
- `DRM_JL_JULIA_HOME='/Users/z3437171/.juliaup/bin' DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' Rscript -e 'devtools::test(filter = "julia-student-sd", reporter = "summary")'`: passed; two live Student SD fits ran through Julia.
- `Rscript -e 'devtools::test(filter = "binomial-phylo-sd-regression", reporter = "summary")'`: passed with probit recovery, formula-aligned tip-SD predictions, and constant-SD equivalence.
- No full package, pkgdown, profile, bootstrap, or interval coverage campaign was run.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <report>`: structure check passed. The validator also reported the repository-wide acceptance ledger as not runnable; its gate state remains unknown and is not treated as satisfied by this focused slice.

## 6. Tests of the Tests

The initial 24-tip probit fixture failed its recovery check, with fitted SD slope 4.79 for truth 0.5. A diagnostic 80-tip draw recovered 0.515 with convergence code 0. The final deterministic 80-tip test passed with an absolute recovery tolerance of 0.25, formula-aligned tip-SD predictions, and constant-SD equivalence. The smaller fixture's failure was treated as inadequate information, not repaired by widening the tolerance.

## 7a. Issue Ledger

No issue was opened or changed. This slice adds direct evidence for an existing feature; the broad cross-engine implementation goal remains active.

## 8. Consistency Audit

The change adds test evidence for an already admitted native route. It does not alter formula grammar or public behavior. The test uses `stats::binomial(link = "probit")`, the existing `sd(species, level = "phylogenetic")` syntax, and the existing prediction methods. No user guide or pkgdown page needed an update for this test-only slice.

## 9. What Did Not Go Smoothly

The first synthetic design used too few tips for a stable one-draw recovery assertion. The larger deterministic design fixed the test design without changing model tolerances.

## 10. Known Residuals

This is one point-recovery draw, not interval calibration. The Julia probit phylogenetic Laplace fitter still needs a link-aware implementation and an independent dense oracle. Its shared source file remains under the covariance-parity lane's active ownership.

Next action: after the covariance lane releases `src/sparse_laplace_glmm.jl`, complete Julia probit phylogenetic SD fitting, run the focused dense-oracle and recovery tests, then document the verified cross-engine boundary.

## 11. Team Learning

For phylogenetic SD recovery checks, group count and the realized kernel-correlated latent field affect information more than the number of repeated observations alone. Keep weak-draw failures as evidence and improve the DGP before adjusting thresholds.

## 12. Cross-Product Coverage

Native R/TMB covers one direct probit phylogenetic random-intercept SD-regression cell through fitting, one fixed-seed recovery draw, and SD prediction checks. The Julia engine covers Student ordinary-intercept and selected independent-slope SD fits through the `drmTMB` bridge, including target labels and public SD predictions. This work does NOT cover Julia probit phylogenetic SD fitting, direct DRM.jl Julia API parity for that cell, interval coverage, cloglog phylogenetic SDs, correlated or crossed blocks, animal/relmat/spatial probit effects, REML, missing responses, or additional providers. These remain open cells in the broader goal.
