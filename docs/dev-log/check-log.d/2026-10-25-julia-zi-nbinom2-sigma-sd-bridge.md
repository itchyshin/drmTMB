# Julia ZI-NB2 sigma-SD bridge admission

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-zi-nbinom2-sigma-sd-bridge", reporter = "summary", stop_on_failure = FALSE)'` — PASS after fix; three formula-admission assertions pass. The live fixture skipped because no Julia path was set.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "nbinom2-(zi-)?sigma-sd-bridge", reporter = "summary", stop_on_failure = FALSE)'` — PASS; ordinary NB2 admission/labels and ZI boundary tests pass. Two live tests skipped in this configuration.
- `DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRM_JL_JULIA_HOME='/Users/z3437171/.juliaup/bin' JULIA_DEPOT_PATH='/private/tmp/julia-depot:/Users/z3437171/.julia' OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-nbinom2-zi-sigma-sd-bridge", reporter = "summary", stop_on_failure = FALSE)'` — PASS; one live R-to-Julia test ran.
- `DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH=... JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "julia-nbinom2-sigma-sd-bridge", reporter = "summary", stop_on_failure = FALSE)'` — PASS; one live test ran, covering ordinary NB2 sigma intercept and slope.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zi-nbinom2-sigma-sd-workflows", reporter = "summary", stop_on_failure = FALSE)'` — PASS; 12 expectations cover profile-target registration and two bootstrap refits retaining the SD coefficient target.
- Full ZI-NB2 sigma SD profile confidence interval attempt — INTERRUPTED after exceeding four minutes without output; do not count as a pass.
- `git diff --check -- R/julia-bridge.R tests/testthat/test-julia-zi-nbinom2-sigma-sd-bridge.R` — PASS.
- Coverage calibration and full package checks — NOT RUN; outside this focused slice.
