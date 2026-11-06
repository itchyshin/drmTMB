# After task: Julia hard errors from the Totoro check (batch 10)

Reader: the maintainer closing out PR #1663. Purpose: classify nine hard errors seen in the Totoro R CMD check of 7309d3cd8 and say what was changed for each.

Base: bee7f6c4f. Reproduced and re-verified on Totoro with no Julia installed.

## Root cause shared by four of the failures

`R/julia-simulate.R` (the Julia `simulate()` methods and the Binomial and Gamma SD simulation helpers) exists only as an untracked file in the lane working tree. It is not in any commit, and `NAMESPACE` already registers `S3method(simulate, drmTMB_julia)`. A clean checkout, which is what the Totoro check built, therefore lacks `drm_julia_binomial_correlated_sd_component`, `drm_julia_draw_correlated_random_effects`, `drm_julia_align_group_sd` and the real `simulate.drmTMB_julia`. The patch adds the file unchanged (copied byte for byte from the lane tree, 39333 bytes).

## Per-failure table

| test:line | cause class | evidence | fix |
|---|---|---|---|
| test-julia-binomial-correlated-q3-sd-bridge.R:75 | (b) real defect, file never committed | `git log --all -- R/julia-simulate.R` is empty; the function is defined only in the untracked file; error was "could not find function" | add `R/julia-simulate.R`; file now 20 pass, 0 fail |
| test-julia-binomial-correlated-q4-sd-bridge.R:112 | same | same | same; 21 pass, 0 fail |
| test-julia-bridge.R:63 | (a) stale test | `drm_julia_formula_spec()` deliberately returns an unnamed positional vector for selector-bearing ordinary SD targets (comment in the function; the q3 test asserts `names()` is NULL). The test indexed it by dpar name | assert type character, no names, length 3, and check elements 2 and 3 by position |
| test-julia-bridge.R:1006 and :1014 | (a) stale test, plus a dead fence | `predict_parameters.drmTMB_julia` in `R/predict-parameters.R` (added in b87566680) collates after the refusal stub in `R/julia-bridge.R` and wins, so the `drmTMB_predict_parameters_julia_unsupported` error is never raised. With `R/julia-simulate.R` present `simulate()` is admitted too. The stub then failed in `drm_julia_predict_model_object` | replaced by a test of refusals that remain: Poisson random-effect Julia `simulate()` ("Marginal simulation is not implemented for this Julia random-effect model"), unknown `dpar` in `predict_parameters()`, and reserved `...`. Test renamed accordingly |
| test-julia-structured-dimnames.R:38 | (a) stale test | `drm_julia_align_labelled_matrix` (message "missing rows or columns") is unused; the live helper `drm_julia_align_structured_matrix` (also on main) aborts with class `drmTMB_julia_structured_labels` and "has no row for". Behaviour (error on a missing level) is unchanged | expect the classed error and the new message; also wrap the unlabelled case in `expect_warning(class = "drmTMB_julia_unlabelled_structured_matrix")`, which the live helper emits |
| test-profile-targets-julia.R:355 and :388 | (a) stale fixture | `drm_julia_predict_sd` (added in b87566680, absent on main) correctly requires SD predictors to be constant within each group. The mock fixture used `sd(species) ~ z` with `z` varying within `sp_1` and `sp_3` | make `z` constant within species in the fixture (`0.1, 0.1, -0.2, 0.3, 0.3, -0.4`); coefficient names and the pinned listing are unchanged |

## Not changed, for the maintainer

- `R/julia-bridge.R` still holds dead duplicates: `simulate.drmTMB_julia`, `predict_parameters.drmTMB_julia`, `drm_julia_method_fence`, and `drm_julia_align_labelled_matrix`. The first two are overridden by later-collated files. Removing them is a separate cleanup, and the `@rdname` roxygen entries would need a check.
- `_problems/` and `testthat-problems.rds` are untracked in the lane tree and were not copied.
- Julia-live tests were not run; none of the nine failures needs Julia.

## Verification (Totoro, 1 process, OPENBLAS and OMP threads 1)

| file | passed | failed | error | skipped |
|---|---|---|---|---|
| test-julia-binomial-correlated-q3-sd-bridge.R | 20 | 0 | 0 | 1 |
| test-julia-binomial-correlated-q4-sd-bridge.R | 21 | 0 | 0 | 1 |
| test-julia-bridge.R | 153 | 0 | 0 | 2 |
| test-julia-structured-dimnames.R | 6 | 0 | 0 | 0 |
| test-profile-targets-julia.R | 48 | 0 | 0 | 2 |

The skips are the opt-in live-Julia tests.
