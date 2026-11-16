# Check log: Julia Gamma animal SD prediction names (#1745)

**Date:** 2026-11-16
**Branch:** `cursor/julia-gamma-animal-sd-names-4454`

## Change

- `drm_julia_predict_keeps_sd_dpar_prefix()` in `R/julia-bridge.R`.
  `predict.drmTMB_julia()` keeps `dpar:group` names for Gamma animal SD
  predictions. Other single-target group-level SD predictions stay named by
  the group level.
- `drm_julia_simulate_gamma_animal_sd()` in `R/julia-simulate.R` still requires
  those prefixed names. When `target_coef` is missing, the alignment error
  names the public SD parameter.
- Fit-free regression: `tests/testthat/test-fix-1745-julia-gamma-animal-sd-names.R`.

## Verification

```sh
export R_LIBS_USER=/home/ubuntu/R-library
cd /agent/repos/drmTMB
Rscript -e '.libPaths(c("/home/ubuntu/R-library", .libPaths())); pkgload::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-fix-1745-julia-gamma-animal-sd-names.R", reporter = "summary")'
```

| Tree | Result |
| --- | --- |
| `main` (pre-fix) | 4 tests. Intercept names fail (`animal_01` vs `sd_animal(id):animal_01`). `simulate()` aborts with `for NA`. Coefficient-specific `predict()` aborts on a fixture that the corrected test no longer uses. Alignment message contains `for NA`. |
| branch | **4 tests, 17 expectations, 0 failures, 0 skips** |

Julia is not installed on this VM (`julia` not on `PATH`, `JuliaCall` not installed, `DRM_JL_PATH` empty). Live files skip with `DRModels.jl / DRM.jl engine not available (set DRMODELS_JL_PATH or DRM_JL_PATH)`:

| File | pass | fail | skip |
| --- | --- | --- | --- |
| `test-julia-gamma-animal-intercept-simulation.R` | 0 | 0 | 1 |
| `test-gamma-animal-q2-nonunit-kernel-simulation.R` | 0 | 0 | 1 |
| `test-julia-gamma-sd.R` | 1 | 0 | 5 |
| `test-julia-lognormal-sd-parity.R` | 0 | 0 | 2 |
| `test-julia-tweedie-relmat-sd.R` | 1 | 0 | 1 |
| `test-julia-binomial-animal-sd-regression.R` | 4 | 0 | 2 |
| `test-julia-binomial-sd.R` | 4 | 0 | 5 |
| `test-julia-predict-newdata.R` | 6 | 0 | 1 |
| `test-julia-predict-quantile.R` | 5 | 0 | 1 |
| `test-julia-negbinomial-sd.R` | 1 | 0 | 2 |
| `test-julia-poisson-animal-sd-parity.R` | 0 | 0 | 1 |
| `test-julia-cumlogit-predict.R` | 3 | 0 | 1 |
| `test-julia-binomial-phylo-sd.R` | 4 | 0 | 3 |
| `test-julia-binomial-relmat-sd-parity.R` | 1 | 0 | 1 |

No failures in the files that ran. The live Gamma animal simulation oracles did not execute.

## Wording search

```sh
rg "named by group level" R man tests docs
rg "dpar:group" R man NEWS.md
```

Native `predict.drmTMB()` still documents group-level SD names as the group level (`R/methods.R`, `man/predict.drmTMB.Rd`). The Julia method now states the Gamma animal `dpar:group` names (`man/predict.drmTMB_julia.Rd`).
