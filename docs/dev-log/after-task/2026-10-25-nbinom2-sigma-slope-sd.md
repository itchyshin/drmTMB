## 1. Goal

Add one predictor-dependent SD route for an ordinary NB2 dispersion random slope, using independent synthetic data and light correctness checks. Interval calibration remains deferred.

## 2. Implemented

Native, complete-data, non-inflated NB2 now admits one unlabelled numeric random slope on `sigma`, with fixed-effect-only `mu` and a group-constant SD predictor:

```r
bf(
  count ~ x,
  sigma ~ 1 + (0 + z | id),
  sd(id, dpar = "sigma", coef = "z") ~ w
)
```

The latent model is `log(sigma_ig) = X_sigma,ig beta_sigma + z_ig u_g`, `u_g ~ N(0, tau_g^2)`, and `log(tau_g) = W_g alpha`. A single unlabelled sigma slope is now also accepted without a varying-SD formula so that the existing constant-SD model supplies a valid equivalence reference. The existing TMB term loop applies the group SD by random-effect index; this slice changed no C++ source.

The focused test checks signed point recovery, target and group-SD prediction mapping, constant-SD log-likelihood and scale equivalence to the baseline sigma-slope model, and refusal when the SD predictor varies within group. An unreviewed recovery receipt links the native NB2 sigma-slope row. The receipt does not promote the candidate capability row.

## 3a. Decisions and Rejected Alternatives

The admission stays restricted to one independent numeric slope, complete non-inflated NB2 data, fixed `mu`, no other random or structured effects, and no within-group variation in the SD predictors. Correlated sigma blocks, multiple sigma coefficients, zero-inflated NB2, and cross-parameter covariance remain outside this slice.

## 4. Files Touched

- `R/drmTMB.R`
- `R/random-effect-scale-formulas.R`
- `man/random_effect_scale_formulas.Rd`
- `tests/testthat/test-nbinom2-sigma-slope-sd-regression.R`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/evidence/nbinom2-sigma-slope-20261025/`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `LOOP/lanes/general-sd-regression/arcs.md`

The worktree also contains unrelated in-flight edits in shared files. This report covers the NB2 sigma-slope hunks only and does not claim all dirty changes belong to this slice.

## 5. Checks Run

- Focused R tests: `devtools::test(filter = "nbinom2-sigma-(sd-regression|slope-sd-regression)", reporter = "summary", stop_on_failure = TRUE)`; exit code 0. The existing intercept test and new slope test passed. Exact output and stable before/after hashes for six relevant source and test files are in `docs/dev-log/general-sd-regression/evidence/nbinom2-sigma-slope-20261025/`.
- `devtools::document()` regenerated the public syntax reference.
- The predictor-dependent SD vignette rendered to `/private/tmp/drmtmb-predictor-dependent-random-sd-nbinom2-sigma-slope.html`; Pandoc reported its existing `--mathjax` deprecation warning.
- `pkgdown::check_pkgdown()` passed with existing Pandoc `--mathml` deprecation warnings.
- No C++ likelihood change, Julia fit, profile/bootstrap refit, or interval-calibration campaign was run.

## 6. Tests of the Tests

The first test run failed at the explicit NB2 sigma intercept-only guard. A subsequent combined command accidentally selected only the existing intercept file; I found and corrected the filter before treating it as verification. The correctly filtered run first passed point recovery, then exposed that the baseline constant-SD sigma-slope model was still refused. I narrowed the base admission to one independent slope in the fixed-mean, non-inflated, complete-data route. A later run exposed an early reference to the missing-predictor flag; I removed that premature reference and retained the later existing guard. The final exact filter passed with exit code 0.

## 7a. Issue Ledger

- Resolved in this slice: NB2 sigma random-effect SD regression admitted only an intercept despite a generic TMB per-term SD-row path.
- Resolved prerequisite: the non-inflated NB2 baseline sigma random-slope model now fits for constant-SD comparison, restricted to one independent slope and fixed `mu`.
- Open: Julia parity, zero-inflated NB2 sigma slopes, correlated and structured sigma effects, and broader output workflows.
- Open: interval calibration and full package checks.
- Open: programme-level review and the complete required family/provider/backend universe.

## 8. Consistency Audit

The formula targets the `z` coefficient in a random slope on NB2 `sigma`. NB2 `sigma` is the overdispersion predictor; the SD formula models the scale of the latent random slope on `log(sigma)`. The simulated `tau_g`, target extraction, group prediction, and constant-SD comparison use this same definition. The fixed `mu` condition and complete-data/non-inflated boundaries agree across builder guards and documentation.

## 9. What Did Not Go Smoothly

The first supposed green filter omitted the newly added slope test. The corrected filter made the baseline-model prerequisite visible. The first implementation attempt also referenced a missing-predictor flag before that flag was initialized. Each issue was corrected, and the final source-bound filter passed.

## 10. Known Residuals

This receipt covers one native NB2 sigma random-slope fixture. It does not establish interval coverage, Julia parity, broad NB2 support, zero-inflated sigma effects, correlated blocks, profile/bootstrap behavior, or calibrated Wald intervals. The evidence row remains unreviewed, and the after-task acceptance-ledger check reports `UNKNOWN` because the ledger has no runnable gate-check.

## 11. Team Learning

For a scale-dependent random-slope extension, test both the predictor-dependent fit and the corresponding constant-SD model. The constant model can reveal a missing base random-slope admission that a positive recovery fit alone would miss. Keep the test filter exact and record the files it actually selected.

## 12. Cross-Product Coverage

This native NB2 sigma-slope slice does NOT cover Julia, zero-inflated NB2, other response families, structured or correlated sigma blocks, interval calibration, or all fit/predict/profile/bootstrap/save-reload workflows.
