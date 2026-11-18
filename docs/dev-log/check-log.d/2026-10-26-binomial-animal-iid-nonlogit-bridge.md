# Check log: Binomial animal-plus-IID probit/cloglog bridge

The live opt-in R bridge test passed for probit and cloglog with TMB and the paired Julia candidate. It checks convergence, point recovery of both SD slopes, predictor-aligned group SDs, and likelihood agreement. The existing logit animal-plus-IID live parity test also passed. The fit-free focused run passed with the live test skipped as expected. These are bounded point and output checks, not interval-calibration evidence.

Exact focused commands and environment from the live runs:

```sh
DRMTMB_JULIA_TESTS=true DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_HOME='/Users/z3437171/.juliaup/bin' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=4 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-binomial-animal-iid-nonlogit-sd-bridge.R", reporter = "summary")'

NOT_CRAN=true DRMTMB_JULIA_TESTS=true DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_HOME='/Users/z3437171/.juliaup/bin' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=4 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-binomial-animal-iid-sd-parity.R", reporter = "summary")'
```

Julia source SHA-256: `7b77883ee26ae873dfde2963dc9f13710f02f8b02690e05e4f7c3a0b85f16945`.

## Fresh source-bound live run

Command: `DRMTMB_JULIA_TESTS=true DRMODELS_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/../general-sd-julia" JULIA_HOME="/Users/z3437171/.juliaup/bin" JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=4 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-binomial-animal-iid-nonlogit-sd-bridge.R", reporter = "summary")'`

ℹ Loading drmTMB
julia-binomial-animal-iid-nonlogit-sd-bridge: ..i Starting Julia (first call in a session takes ~30-60 s; later calls are fast)...
Julia version 1.10.0 at location /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin will be used.
Loading setup script for JuliaCall...
Finish loading setup script for JuliaCall.
  Activating project at `~/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia`
.......................

══ DONE ════════════════════════════════════════════════════════════════════════
Julia bridge: 1 live test ran; bridge glue was exercised in this configuration.
Julia exit.
