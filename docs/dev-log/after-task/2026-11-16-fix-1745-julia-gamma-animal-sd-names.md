# After-task: Julia Gamma animal SD prediction names (#1745)

Reader: an R package contributor checking the Julia Gamma animal simulation contract.

## Goal

`predict()` on a Julia Gamma animal SD fit should return the `dpar:group` names that `simulate()` matches to the fitted animal groups. An alignment failure should name the SD parameter when the formula omits `coef`.

## Implemented

`drm_julia_predict_sd()` already names group-level values `dpar:group`. `predict.drmTMB_julia()` was removing that prefix for every single SD target. Gamma animal targets now keep it. Ordinary and non-animal single-target predictions still use the bare group level, which is what native `predict.drmTMB()` documents and what the lognormal and Tweedie relmat tests require.

`drm_julia_simulate_gamma_animal_sd()` still requires the prefixed names. `sd(id, level = "animal")` stores `target_coef` as `NA`. The alignment error now uses the public SD parameter, such as `sd_animal(id)`, in that case.

## Files changed

- `R/julia-bridge.R` — `drm_julia_predict_keeps_sd_dpar_prefix()` and the `predict.drmTMB_julia()` name rule.
- `R/julia-simulate.R` — alignment error label.
- `man/predict.drmTMB_julia.Rd`, `man/simulate.drmTMB.Rd`, `NEWS.md`.
- `tests/testthat/test-fix-1745-julia-gamma-animal-sd-names.R`.
- `docs/dev-log/check-log.d/2026-11-16-fix-1745-julia-gamma-animal-sd-names.md`.

## Checks run

Before the code change, the new intercept test failed with `animal_01` versus `sd_animal(id):animal_01`, and `simulate()` aborted with `Julia Gamma SD predictions do not align with animal groups for NA`.

After the change: `test-fix-1745-julia-gamma-animal-sd-names.R` — 4 tests, 17 expectations, 0 failures.

Julia is not on this VM (`julia` absent, `JuliaCall` not installed, `DRM_JL_PATH` empty). These live files skipped on `DRModels.jl / DRM.jl engine not available` and did not execute their oracles:

- `test-julia-gamma-animal-intercept-simulation.R` (1 skip)
- `test-gamma-animal-q2-nonunit-kernel-simulation.R` (1 skip)
- `test-julia-lognormal-sd-parity.R` (2 skips)
- `test-julia-poisson-animal-sd-parity.R` (1 skip)

Fit-free portions of the other Julia predict files listed in the check log passed. None failed.

## Consistency

The name change is limited to Gamma `sd_animal` targets. `test-sd-predict-semantics.R` documents bare group names for native `predict.drmTMB()` and says it makes no Julia claim. That file was not edited.

Wording search: `rg "named by group level" R man tests docs` and `rg "dpar:group" R man NEWS.md`.

## Tests of the tests

The new file failed on current `main` before the edit, including the `for NA` message. It also checks a mismatched group label, which is the error path, and an ordinary `sd(id)` prediction, which must stay bare.

## What did not go smoothly

The coefficient-specific fixture first used `~ z0` and `~ z1` with a single intercept coefficient block, so `predict()` aborted on the design before it could check names. The regression uses `~ 1` for both selectors. The live q2 oracle in `test-gamma-animal-q2-nonunit-kernel-simulation.R` is unchanged and still needs Julia.

## Known limitations

Live Julia Gamma animal simulation was not re-run here. Native `predict.drmTMB()` still names `sd_animal(id)` by the group level. This slice does not change that method.

## Issue tracker

Issue #1745 stays open. The draft pull request references it. No closing keyword, and no comment on #1746 or pull request #1691.

## Next actions

Run `test-julia-gamma-animal-intercept-simulation.R` and `test-gamma-animal-q2-nonunit-kernel-simulation.R` where `DRM_JL_PATH` points at the CI-pinned DRModels.jl checkout.
