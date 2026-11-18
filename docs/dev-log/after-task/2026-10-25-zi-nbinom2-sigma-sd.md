# After Task: Native ZI-NB2 sigma SD intercept

## 1. Goal

Add and document a narrow native complete-data zero-inflated NB2 route for a predictor-dependent SD on one ordinary `sigma` random intercept, keeping `mu` and `zi` fixed.

## 2. Implemented

The native model-type 9 likelihood now maps the `sigma` random-intercept term to its group-specific SD from `X_sd_sigma %*% beta_sd_sigma`, using the existing clamp and overflow guards. It reports the SD coefficients and group log-SDs/SDs for extraction and prediction. The existing R builder and output machinery were already present in this candidate; this change connected the native likelihood to that design.

The ZI-NB2 sigma-intercept route is described in NEWS, the design and family maps, the limitations and roadmap pages, and three user-facing articles. The focused test checks formula assembly, point recovery, Hessian/covariance availability, group-SD prediction, conditional sigma output, save/reload, simulation, constant-SD likelihood equivalence, and rejection of within-group-varying SD predictors.

## 3a. Decisions and Rejected Alternatives

- Kept admission at the existing exact q1 sigma-intercept gate. A synthetic sigma-slope test was tried, then removed after the builder correctly rejected it; admitting slopes requires a separate reviewed expansion.
- Used the existing kernel-free ordinary intercept route; no new formula syntax or SD parameterization was introduced.
- Assumed complete data, fixed-effect `mu` and `zi`, and no other random-effect target, matching the current gate. If those assumptions change, the builder and likelihood need a separate extension.
- Coverage calibration and Julia parity remain deferred; this slice makes point-fit and output claims only.

## 4. Files Touched

- `src/drmTMB.cpp`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/internal-roadmap.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/general-sd-regression/native-family-sd-adapter-map.md`
- `tests/testthat/test-zi-nbinom2-sigma-sd-regression.R` (existing focused test file; the experimental slope block was removed)
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/predictor-dependent-random-sd.Rmd`
- `docs/dev-log/after-task/2026-10-25-zi-nbinom2-sigma-sd.md`

## 5. Checks Run

- Before the likelihood patch, the focused test failed: the fitted Hessian was not positive definite, covariance extraction was unavailable, and the constant-SD likelihood differed by about 0.96.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zi-nbinom2-sigma-sd-regression", reporter = "summary", stop_on_failure = TRUE)'`: passed after the likelihood patch and again after removing the unsupported slope test.
- `pkgdown::check_pkgdown()`: passed with no pkgdown problems; Pandoc emitted existing `--mathml` deprecation warnings.
- `pkgdown::build_site()`: interrupted at the final “Building docs for llms” stage after the process remained idle for over five minutes. The edited `formula-grammar`, `model-map`, and `predictor-dependent-random-sd` articles rendered successfully. This is not a full-site build pass.
- Scoped `git diff --check` on implementation and documentation paths: passed. A broader working-tree check reported a trailing blank line in the unrelated `tests/testthat/test-binomial-sd-integration.R` file; that foreign path was not changed here.
- Exact current hashes: `src/drmTMB.cpp` `71ed10ab4f632d5e03afee3226fc2a322c7965c204023fdc0f381de29cea9ed3`; `R/drmTMB.R` `86c7742867a13f05a63495f681bdaa7102f61adf53512bbc0830f9aa4141a72b`.
- No full package check, Julia fit, or coverage campaign was run.

## 6. Tests of the Tests

The focused file failed before the likelihood patch with a non-positive-definite Hessian, unavailable covariance, and a constant-SD likelihood mismatch. The tests therefore detected the missing SD-design connection. The malformed within-group predictor test remains a negative control. A newly attempted sigma-slope test also confirmed the current builder boundary by receiving the intended admission error; it was removed because slopes are outside this slice.

## 7a. Issue Ledger

- Fixed: model type 9 ignored the sigma SD design and used only the constant `log_sd_sigma` parameter.
- Deferred: sigma random slopes in ZI-NB2, structured and correlated terms, other random-effect targets, Julia parity, and interval calibration.
- GitHub issue search for this specific route returned no matching open issue.

## 8. Consistency Audit

The symbolic model is `b_g ~ Normal(0, tau_g^2)`, `log(tau_g) = W_g alpha`, and `log(sigma_i) = X_sigma beta_sigma + b_g`, with fixed `mu` and `zi`. This matches the TMB group-SD calculation and the R prediction interface. Status wording now distinguishes this narrow route from ordinary NB2 sigma slopes and from other zero-inflated targets. The relevant formula grammar, family registry, limitations, roadmap, NEWS, and vignettes were checked. `README.md` and `_pkgdown.yml` required no change for this non-exported route.

## 9. What Did Not Go Smoothly

The first new synthetic slope test exceeded the existing gate. I removed that test instead of broadening the feature without reviewing the associated builder and likelihood scope. The full pkgdown build took far longer than estimated and stalled at the final LLM-docs stage; I stopped it after confirming the edited articles had rendered. One exploratory `graft` command was unavailable in this worktree, so I used the repository’s existing source and test evidence instead.

## 10. Known Residuals

This is one native point-fit capability cell. It does not establish uncertainty calibration, broad family parity, Julia parity, or support for sigma slopes or structured effects. Full pkgdown build remains incomplete. The worktree contains unrelated concurrent changes; no commit, merge, or push was made. Overall programme gates remain open.

## 11. Team Learning

Memory receipt: `route.py` returned “NO manifest for repo”; the drmTMB dossier was retrieved from the brain and applied for focused tests, source-hash checks, and honest scope boundaries. No local `LOAD-FIRST` manifest was available. Golden Set: NOT RUN because no known repeated-error pattern was identified as in scope. No durable memory note was added.

## 12. Cross-Product Coverage

Covers: native R/TMB fitting, point recovery, group SD prediction, conditional sigma output, save/reload, simulation, constant-SD equivalence, and a group-constant predictor rejection check for one complete-data ZI-NB2 sigma random intercept with fixed `mu` and `zi`.

Does NOT cover: Julia; sigma slopes; other random-effect families or providers; correlated, structured, or cross-parameter blocks; other ZI-NB2 dpars; missing-data routes; interval coverage or calibrated uncertainty; broad package validation; full pkgdown completion; or programme completion.
