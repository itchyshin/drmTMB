# Comment intended for https://github.com/itchyshin/drmTMB/pull/1565

GitHub write from this cloud task may return 403. Paste this if posting by hand. Refs #1565. Do not close.

t7 follow-up on head `b0cf1d8a7bdc365d17c4c626e71c970543efa77a` (this PR), DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`.

**Host contract:** `DRMODELS_JL_PATH=/home/ubuntu/DRModels.jl` only. `JULIA_PROJECT` unset. `DRM_JL_PATH` unset. Official Julia 1.12.6 tarball + CRAN JuliaCall 0.17.6 + apt R 4.6.1 on Ubuntu 24.04.5. drmTMB installed from this PR tree (`R CMD INSTALL`).

**Segfault is gone.** `timeout --signal=KILL 2400 Rscript sweep-oct16/t7/harness_julia_engine.R 1565` finished **R exit 0** in 62.4 s. First cell 58 s (JuliaCall setup + `Pkg.activate` at the DRModels checkout). Later cells 0.01–1.0 s. Original ca3ddef t7 run died 139 on the first `engine="julia"` fit after a successful `drm_julia_setup()`.

Smoke: `drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d, engine = "julia")` **FIT OK**, logLik −57.026.

t7 offset/contrasts cells no longer crash. They now **refuse** for independent reasons (formula `offset()` → DRModels `_BRIDGE_REJECT_CALLS[:offset]`; ordered-factor contrasts → #1495). Receipt: `sweep-oct16/t7/RECEIPT_t7.md` follow-up on branch `sweep-oct16/t7`. CSVs: `results_offset_julia_1565.csv`, `results_contrasts_julia_1565.csv`.

The 139 draft (`issues/NEW_drmTMB_julia_segfault.md`) should not be filed.
