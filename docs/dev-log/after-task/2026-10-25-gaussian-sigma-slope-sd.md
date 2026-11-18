## 1. Goal

Implement one bounded non-location slice of predictor-dependent random-effect SD regression: an independent numeric random slope on Gaussian residual `sigma`, with a fixed-predictor SD formula. Interval coverage remains deferred.

## 2. Implemented

The Gaussian builder now admits one independent `sigma` random intercept or numeric random slope with a matching `sd(group, dpar = "sigma", coef = "z") ~ w` target. For the slope route, the model is `log(sigma_ig) = X_sigma,ig beta_sigma + z_ig u_g`, with `u_g ~ N(0, tau_g^2)` and `log(tau_g) = W_g alpha`. The route requires fixed-effect-only `mu`, complete unaggregated observations, one sigma random-effect term and a group-constant SD design. Existing C++ parameter and prediction assembly already supported this representation, so this slice changed no C++ source.

The tests exercise seeded point recovery, SD target identity, group and row-level scale predictions, constant-SD equivalence, mismatched targets, within-group SD predictor variation, and refusal of multiple random-slope terms. The direct-SD evidence ledger links one unreviewed native Gaussian sigma slope receipt. That receipt records a focused test result; it does not promote the candidate capability row.

## 3a. Decisions and Rejected Alternatives

The implementation uses the existing formula grammar and SD target resolver. It does not add a new modeling interface or silently broaden sigma SD regression beyond the single independent intercept-or-slope route. Julia parity and interval coverage are deferred; neither is implied by the native test.

## 4. Files Touched

- `R/drmTMB.R`
- `R/random-effect-scale-formulas.R`
- `man/random_effect_scale_formulas.Rd`
- `tests/testthat/test-gaussian-sigma-sd-slope-regression.R`
- `docs/design/01-formula-grammar.md`
- `docs/design/18-random-effect-scale-models.md`
- `NEWS.md`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `docs/dev-log/general-sd-regression/gaussian-sigma-slope-contract.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/evidence/gaussian-sigma-slope-20261025/`
- `docs/dev-log/check-log.md`
- `LOOP/lanes/general-sd-regression/arcs.md`

The worktree contains extensive other in-flight changes. This report names the files relevant to this slice and does not claim that every dirty hunk in those files belongs to it.

## 5. Checks Run

- Focused R tests: `devtools::test(filter = "gaussian-sigma-sd-(regression|slope-regression)", reporter = "summary", stop_on_failure = TRUE)`; exit code 0. Both the existing intercept test and the new slope test passed. The exact output is in `docs/dev-log/general-sd-regression/evidence/gaussian-sigma-slope-20261025/test-console-final.log`.
- Source manifest: six relevant R, C++, and test files had identical before/after SHA-256 entries; `source-stability-final.diff` is empty.
- Predictor-dependent SD vignette rendered successfully to `/private/tmp/drmtmb-predictor-dependent-random-sd-gaussian-sigma-slope.html`; Pandoc emitted its existing MathJax deprecation warning.
- `pkgdown::check_pkgdown()` passed with existing Pandoc MathML deprecation warnings.
- The independent math reviewer approved the equation, formula, data-generating process, and extraction alignment. The review covered this mathematical slice; programme acceptance remains open.

## 6. Tests of the Tests

The new focused test was first run against the intercept-only builder and failed at its explicit sigma-slope refusal. After the narrowly scoped admission change, the recovery and constant-SD checks passed. One negative test initially expected stale error wording; its expectation was corrected to the current explicit boundary and the focused filter then passed.

## 7a. Issue Ledger

- Resolved in this slice: Gaussian sigma SD builder rejected the independent numeric random-slope target despite existing downstream parameter and prediction assembly.
- Open: broader Gaussian sigma random-effect structures, Julia parity, and general random-effect SD support across all required family/provider/backend rows.
- Open: interval calibration, profile/bootstrap uncertainty, and full prediction/refit/save-reload workflow checks for this route.
- Open: programme-level reconciliation and review of the full dirty worktree.

## 8. Consistency Audit

The equation, R formula, existing TMB parameter mapping, synthetic generator, and extraction labels describe the same log-SD predictor and group-level random slope. Constant `W_g alpha` is compared with the corresponding constant-SD model. Bernoulli residual scale is unaffected. The inventory now separates this native sigma result from Gaussian `mu` parity evidence.

## 9. What Did Not Go Smoothly

The initial negative-test expectation used the previous error phrase. It was corrected and the complete focused filter passed. The required lane-preflight and graft executables could not be found through this worktree's shell, and the route helper returned no LOAD-FIRST manifest for the worktree path. The extensive pre-existing dirty tree makes broad staging or cleanup unsafe; this slice remained scoped and no unrelated changes were reverted.

## 10. Known Residuals

This is one native Gaussian sigma endpoint route. It does not establish Julia parity, broad distributional parity, interval coverage, calibrated uncertainty, or completion of any programme gate. `sd()` predictors remain fixed-effect-only and must be constant within the latent group. No C++ likelihood change was made. No full package check was run.

The after-task structure check passed. Its acceptance-ledger check returned `UNKNOWN` because no runnable node or gate-check was configured; the ledger is not considered satisfied.

## 11. Team Learning

When an existing downstream TMB payload already supports a scale endpoint, test whether the builder's admission fence is the only missing layer before changing compiled likelihood code. Keep the admission test narrow and pair it with a constant-SD equivalence check. Record the source-stable focused result as a receipt without treating it as capability promotion.

## 12. Cross-Product Coverage

This native-only Gaussian sigma slope slice does NOT cover Julia, Bernoulli or any other response family, structured covariance, correlated blocks, bivariate endpoints, interval calibration, or complete save/reload/profile/bootstrap workflows.
