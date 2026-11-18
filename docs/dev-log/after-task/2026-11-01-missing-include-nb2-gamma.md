# After-task note: NB2 and Gamma ordinary SD regression with missing responses kept

Date: 2026-11-01. Branch: codex/general-sd-regression (private copy, no lane commit).

## What changed

NB2 (`nbinom2()`) and Gamma(link = "log") ordinary SD regression now accepts `miss_control(response = "include")` for one ordinary `mu` random intercept `(1 | id)` or one independent random slope `(0 + x | id)`, with `sd(id) ~ w` and a fixed-effect `sigma ~ 1`. Rows with a missing response stay in the data, contribute no likelihood, and receive predictions.

Admission test: the C++ branches for both families (model_type 7 for NB2, model_type 5 for Gamma) already guard each density with `observed_y(i) == 1`, so nothing in `src/` changed. The R builders only refused the combination.

Source edits, all in `R/drmTMB.R`:

1. `drm_build_gamma_ls_spec()`: the include refusal now fires only for a sigma-target SD formula, a structured SD formula, or a structured `mu` term. Ordinary `mu` SD formulas pass.
2. `drm_build_nbinom2_spec()`: the include refusal now fires only for a sigma-target SD formula, a structured SD formula, or an ordinary `mu` SD formula beside a zero-inflation formula. The old message is kept, so the existing zero-inflated pin in `test-zi-nbinom2-sd-regression.R` still passes unchanged.
3. `drm_build_nbinom2_spec()`, a real defect found by this slice: the include branch built start values with `nbinom2_start()` but did not pass `sd_mu`, `sd_sigma` or `sd_phylo`. The SD regression was then started from a one-element `beta_sd_mu` while the design had two columns, so the fit silently used a wrong start and then failed in `split_tmb_sdpars()` with an NA subscript error. The three arguments are now passed, as on the complete-data branch. Without this edit the new NB2 cases error (measured: 2 errors in 21 expectations).

Gamma needed no start-value change: `gamma_ls_start()` already takes `observed_y` and the SD structures.

## Evidence (tests/testthat/test-nb2-gamma-sd-missing-include.R, new file)

Four cases: NB2 and Gamma, each with a random intercept and with a random slope. Each fixture has 36 groups of 14 rows, shuffled row order, shuffled factor levels, a group-level `w` with a true SD slope of 0.9, 40 random missing responses, and one group with no observed response at all.

Tolerances were fixed before the first run (listed in the file header). Results from the final run: 114 expectations passed, 0 failed, 0 errors, 0 skipped.

- The include fit equals the complete-case fit: log-likelihood within 1e-8, all coefficients within 1e-6, observed-row training predictions within 1e-6.
- The log-likelihood equals a dense, drmTMB-independent per-group scalar Laplace oracle at the fitted parameters within 1e-4.
- Emulated-bug sensitivity: scoring the masked rows as placeholder responses (0 for NB2, 1 for Gamma), or dropping the SD slope on `w`, moves the oracle by more than 0.05. The first run showed the 0.45 SD slope was too weak for the second check on one fixture, so the true slope was raised to 0.9. No agreement tolerance was changed.
- Constant SD (`sd(id) ~ 1`) under include equals the plain random-effect fit within 1e-6, equals the complete-case fit within 1e-8, and its predicted group SD equals the plain fit's SD.
- Predictions: `predict()` returns one finite value per input row, masked rows included; masked rows in the empty group sit on the fixed-effect line (conditional mode zero); `newdata` rows with an NA response get population-level predictions equal to X beta within 1e-8; `predict(fit, dpar = "sd(id)")` is name-aligned and equals exp(X alpha) for every group, including the empty one.
- Refusals still pinned under include, for both families: sigma-target ordinary SD, joint mu and sigma ordinary SD, and relmat SD with a non-unit-diagonal K (1.7 scale Toeplitz, reversed level order).

Neighbouring tests re-run with no change in outcome (all pass): zero-inflated NB2 SD, NB2 batch5 and joint SD, Gamma iid-structured, ordinary-beside-structured, joint SD, structured-slope and SD integration, count structured q2, structured-sd-nonunit-k-and-missing, structured-sd-q-ainv-quickwins, truncated NB2 SD, NB2 ordinary correlated q2, missing-response count mixtures, and the two missing-data control files. No existing test file was edited.

## Not covered

No calibration, coverage, recovery or Julia parity claim. One fixture seed per case. Sigma-target, joint, structured (relmat, animal, phylo, spatial), zero-inflated and correlated-block SD routes stay refused under include. Missing predictors (`mi()`) were not examined. Prose in `vignettes/predictor-dependent-random-sd.Rmd` and the capability registry still describe these routes as needing complete data and were not edited here; the evidence TSV has no row for the new test file yet, and the capability reader for the registry was not touched.
