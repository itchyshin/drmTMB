# After Task: Gamma Animal Raw-Kernel Parity

## 1. Goal

Apply the user's selected covariance rule to Julia Gamma animal models: use supplied `A` without normalization, matching native TMB, and verify one non-unit-diagonal cross-engine case. This supersedes the 2026-10-24 report that recommended keeping normalized Julia `A`.

## 2. Implemented

Julia Gamma animal intercept, slope-only, and independent intercept-plus-slope fitting now retain raw `A`. Gamma animal marginal simulation in Julia and the R bridge uses that same covariance. The fitted SD is a multiplier; group `g` has marginal SD equal to the multiplier times `sqrt(A[g,g])`. Julia Gamma related-matrix `K` retains its existing normalization. The change affects Julia Gamma animal fits when supplied `A` has a non-unit diagonal.

## 3a. Decisions and Rejected Alternatives

The user explicitly selected raw supplied `A` for Julia Gamma animal models after the normalized-versus-raw conflict was presented. Preserve this convention across fitting and marginal simulation. This changes earlier Julia fits for non-unit-diagonal `A`; retaining normalization would keep the engines on different scales.

## 3. Mathematical Contract

For one animal coefficient, `b ~ N(0, D A D)`, with `D = diag(exp(W alpha))`. For an independent intercept and slope, the fields have covariances `D0 A D0` and `D1 A D1`; row `i` receives `b0[g_i] + x_i b1[g_i]`. The marginal coefficient SD at group `g` is `exp(W_g alpha) sqrt(A[g,g])`. This is the raw-kernel rule selected by the user and already used by native TMB.

## 4. Files Touched

- Julia: `src/sparse_laplace_glmm.jl`, `src/gamma.jl`, `src/inference.jl`, and three Gamma animal SD regression tests.
- Julia docs: family guide, animal tutorial, capability table, formula-grammar developer note, and NEWS.
- drmTMB bridge: `R/julia-simulate.R` and the non-unit-kernel simulation and parity tests.
- Programme inventory, check log, and source-hash evidence are in the paired drmTMB worktree.

## 5. Checks Run

- Julia focused command, with `JULIA_DEPOT_PATH=/private/tmp/codex-general-sd-julia-depot:/Users/z3437171/.julia`, `JULIA_NUM_THREADS=1`, and `OPENBLAS_NUM_THREADS=1`, included `test/test_gamma_animal_sd_regression.jl`, `test/test_gamma_animal_slope_sd_regression.jl`, and `test/test_gamma_animal_intercept_slope_sd.jl`: 66 assertions passed.
- R bridge filter `gamma-animal-q2-nonunit-kernel-(simulation|parity)`, against the paired live Julia worktree: both tests passed.
- Scoped `git diff --check` passed in both worktrees.
- `julia --project=docs --startup-file=no docs/make.jl` did not start because Documenter is absent from the configured docs environment. No dependency installation or environment change was made.

## 6. Tests of the Tests

The R simulation test failed before the bridge simulator was changed: its seeded draw disagreed with the raw-`A` oracle because the wrapper normalized `A`. It passed after normalization was removed. The same-data parity test compares independently fitted engines on non-unit-diagonal `A` and checks fitted SD coefficients, log likelihood, and named group SDs. The direct Julia tests also use non-unit `A` and independent dense Laplace or covariance calculations.

## 8. Consistency Audit

The Julia fit, Julia marginal simulator, R bridge simulator, and user-facing Gamma animal documentation now use the same raw-`A` interpretation. The capability table and programme inventory describe one non-unit-diagonal same-data parity fixture. The exact current-facing stale-claim scan was `rg -n 'normalizes.*A|normaliz.*Gamma animal|direct same-data parity|cross-engine.*not established' docs/src news/gamma-sd-regression.md` and returned no matches. No claim of broad engine parity or interval calibration is made. Earlier reports remain unchanged and are superseded by this record.

## 7a. Issue Ledger

A read-only search for open issues matching `Gamma animal non-unit A covariance Julia` returned no matches. No issue was changed.

## 9. What Did Not Go Smoothly

An earlier passing simulation oracle used the same raw covariance as its simulator and therefore failed to test the covariance used by the fitted Julia model. The later independent fit/simulation comparison exposed the inconsistency. The docs build was blocked by the missing Documenter dependency.

## 11. Team Learning

A seeded simulator oracle must use the covariance implied by the fitted likelihood and public scale parameter, not merely repeat the simulator's covariance choice. For structured effects, state both the multiplier and the kernel-adjusted marginal SD.

## 10. Known Residuals

This evidence covers Gamma animal intercept, slope-only, and independent intercept-plus-slope routes in focused tests, plus one same-data TMB/Julia point-parity fixture. It does not establish broad parity across animal inputs or other structured providers, calibrated uncertainty, full documentation rendering, or completion of the general SD programme. Existing Julia Gamma animal fits with non-unit-diagonal `A` change under the selected convention.

## 12. Cross-Product Coverage

This slice covers the Julia Gamma animal fit and marginal-simulation covariance convention, the R bridge simulator, and one same-data non-unit-diagonal TMB/Julia comparison. It does not cover other Gamma providers, other response families, broad backend parity, calibrated intervals, or programme completion.

## Prose Assessment

Automated prose check: 0 findings. Formal naturalness assessment: NOTASSESSED.

## Next Actions

Continue the general family/effect/backend inventory. Keep interval coverage calibration deferred as previously agreed. Re-run the Julia documentation build after Documenter becomes available in its project environment.
