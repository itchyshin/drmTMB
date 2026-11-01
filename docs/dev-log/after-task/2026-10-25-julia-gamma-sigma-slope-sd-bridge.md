# After Task: Gamma sigma random-slope SD through the Julia bridge

## 1. Goal

Verify one Gamma `sigma` independent random slope with a predictor-dependent coefficient SD through the R-to-Julia bridge. Keep the selected target identity in public outputs and state the limits of the evidence.

## 2. Implemented

The bridge now serializes a selected Gamma `sigma` slope as `sd(group, sigma, coef(x))`. It preserves the existing `sd(group, sigma)` spelling for an intercept. The family-specific route guard requires one ordinary numeric `sigma` slope and an SD target that names the same group and coefficient. The paired Julia fitter uses the row-specific slope loading in the integrated likelihood and conditional `sigma` output.

The Student SD label path was also reviewed at the user's request. Its canonical `sd` label mapping and focused test were already present in the dirty candidate; the test passed, so this slice made no duplicate edit to that code.

## 3a. Decisions and Rejected Alternatives

The bridge helper now preserves a selected `sigma` coefficient in the Julia formula. Family-specific admission still controls which targets can fit; this serializer change does not make the BetaBinomial `sigma` slope route available. The existing intercept serialization stays unchanged.

Assumptions made without asking: the selected R coefficient name is represented in Julia with the existing `coef(x)` marker syntax. If the paired Julia parser does not preserve that descriptor on another supported family, that family remains outside this route until its own bridge fixture passes.

## 4. Files Touched

- `R/julia-bridge.R`
- `tests/testthat/test-julia-gamma-sigma-sd-bridge.R`
- `NEWS.md`, `README.md`, `docs/design/01-formula-grammar.md`, `docs/design/02-family-registry.md`, `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/general-sd-regression/inventory.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/after-task/2026-10-25-julia-gamma-sigma-slope-sd-bridge.md`
- Paired Julia files: `src/gamma.jl`, `test/test_gamma_sigma_sd_regression.jl`, `docs/src/capabilities.md`, `docs/src/developer-notes/formula-grammar.md`, `NEWS.md`, and `docs/dev-log/after-task/2026-10-25-julia-gamma-sigma-slope-sd.md`

R candidate base: `425bee81572c625a634b2b083050c5c57c1dc1f1`. Julia candidate base: `70dbf564eb670144c63c08f61ea099084d95add2`. Both worktrees contain substantial pre-existing dirty work; these hashes identify the checked-out commits, not clean source snapshots.

Source hashes at verification: R bridge `R/julia-bridge.R` SHA-256 `1690a1aaca85cae1d68c9ecc51068d8f5d1a55b1f57cf9980ca8d133a7bae200`; Gamma bridge test `tests/testthat/test-julia-gamma-sigma-sd-bridge.R` `0555c6ce448b97d5c23f4d02803e8d53f0643802dd0e263b8c9427c4ba78e0ee`; Student bridge test `tests/testthat/test-julia-student-sd.R` `89e54d045de8d50963abf4dc403f1e50206383ac86f6984c624ecee4cf507104`; Julia `src/gamma.jl` `589b9c83edf798bd92381002ca53c337984b543317f783d4a55ab2e78d5e6f84`; Julia slope test `test/test_gamma_sigma_sd_regression.jl` `790e40c009fbb60aa0c2ddd6ff450ffde23a8244e001504ef7d6c331c14b6ab4`.

## 5. Checks Run

- The first live `julia-gamma-sigma-sd-bridge` run reached the Julia intercept fixture but failed on the slope at `drm_julia_formula_lhs()`: the R serializer still rejected a non-intercept `sigma` selector.
- After the serializer fix, `TMPDIR=/private/tmp DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRM_JL_JULIA_HOME='/Users/z3437171/.juliaup/bin' JULIA_DEPOT_PATH='/private/tmp/julia-depot:/Users/z3437171/.julia' OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-gamma-sigma-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'` passed with two live bridge tests. They cover the intercept and independent slope, same-data coefficient and SD-prediction comparisons, public target labels, conditional `sigma`, and slope save/reload.
- `JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia +1.10.12 --project=. -e 'include("test/test_gamma_sigma_sd_regression.jl")'` passed 23 assertions: 13 intercept, 1 ignored-covariance refusal, and 9 slope assertions. The tests use fixed seeds `20261025`, `20261026`, and `20261027`; the slope test includes an independent `QuadGK` groupwise likelihood oracle.
- A follow-up `julia-student-sd` run with `DRM_JL_PATH` set to the paired candidate passed 34 expectations, including two live Student TMB/Julia bridge fits (intercept and slope). JuliaCall used Julia 1.10.0. The fixtures check coefficient recovery, target labels, group-SD prediction, and save/reload for the slope route.
- `Rscript -e 'pkgdown::check_pkgdown()'` reported no problems. Existing Pandoc `--mathml` deprecation warnings appeared. A full site render was not run.
- `git diff --check` passed for the touched R implementation, test, and documentation paths and for the paired Julia worktree. The full R worktree check found one unrelated trailing blank line at `tests/testthat/test-binomial-sd-integration.R:225`; that file was not changed in this slice.

## 6. Tests of the Tests

The first live bridge run failed at the exact missing serialization behavior before the fix. The new positive marshalling assertion expects `sd(id, sigma, coef(x))`; negative route checks reject a mismatched coefficient and group. The direct Julia slope test also compares the fitted objective with a separately coded scalar integral, so a fit-only assertion is not the sole numerical check.

## 7a. Issue Ledger

The open-issue search found no issue for this Gamma `sigma` SD slope bridge. Issue [drmTMB #1551](https://github.com/itchyshin/drmTMB/issues/1551) concerns ordinary Gamma and Poisson mean random-intercept `resd` labels and marginal-likelihood routing; that is adjacent but not the `sigma` slope route changed here. No issue was modified.

## 8. Consistency Audit

The formula, serializer, Julia descriptor, integrated row loading, conditional `sigma` output, and docs all describe the same target: for row `i` in group `g`, `eta_sigma,i = X_sigma,i gamma + x_i b_g`, `b_g ~ Normal(0, tau_g^2)`, and `log(tau_g) = W_g alpha`. Gamma `sigma` is the coefficient of variation; this random effect acts on `log(sigma)`. The R docs and capability inventory distinguish one same-data point-estimate check per coefficient type from broad parity or calibrated uncertainty.

The targeted inventory search was `rg -n -C 2 'Gamma.*sigma|sigma.*Gamma|Gamma.*bridge|sigma-intercept' README.md docs/design/02-family-registry.md docs/dev-log/general-sd-regression/inventory.md docs/dev-log/known-limitations.md NEWS.md docs/dev-log/check-log.md`. The formula and roadmap check was `rg -n -C 2 'Gamma.*sigma|sigma.*Gamma' docs/design/01-formula-grammar.md docs/design/18-random-effect-scale-models.md docs/dev-log/internal-roadmap.md vignettes/formula-grammar.Rmd`.

## 9. What Did Not Go Smoothly

The bridge admission predicate accepted the selected slope before its formula serializer could encode it. The live test exposed this mismatch. The lane-preflight script identified the candidate branch but could not identify the runtime and stalled after printing the file header; the full target diff was reviewed before the scoped edit, under the user's authorization. A later Student live-test attempt hit `ENOSPC` while Julia wrote a depot lock; a fresh R process using the existing home depot passed both Student bridge fits. `route.py` found no repository LOAD-FIRST manifest. No other lane's edits were reverted.

## 10. Known Residuals

The R/TMB-versus-Julia comparison is one synthetic fixture per coefficient type, with smoke tolerances because the engines use different integration approximations. It does not establish broad numerical parity, interval coverage, random slopes on other Gamma parameters, structured or correlated `sigma` effects, joint `mu`/`sigma` random effects, or missing-response support. The full package suite and full site render were not run. The overall predictor-dependent random-effect SD goal remains active; interval-coverage calibration is deferred by the current user-approved scope.

## 11. Team Learning

When a family gate admits a selected random coefficient, test the final serialized Julia formula as well as the admission predicate. A live bridge fixture caught an intercept-only serializer left behind by a wider route change.

Memory receipt: `route.py` reported no LOAD-FIRST manifest. The brain's reusable-wins note supports positive capability checks by fitting the route; the live TMB/Julia test and the independent Julia integral were used. The exact project cross-repo-guards note was not found through the brain connector. Golden Set: not run; no memory-rule change or cross-repo guard was introduced.

## 12. Cross-Product Coverage

Covers: one ordinary Gamma `sigma` intercept and one independent numeric `sigma` slope in the paired Julia candidate; one R-to-Julia same-data fixture per coefficient type; selected target naming, group-SD prediction, conditional `sigma`, and slope save/reload.

Does NOT cover: other Gamma random-effect types or providers, other family/backend combinations, broad engine parity, interval calibration, or the full predictor-dependent SD capability universe. This report does not close the overall goal.
