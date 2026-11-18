# Check log: Binomial non-logit animal-intercept SD bridge

Focused live command on 2026-10-26:

```sh
DRMTMB_JULIA_TESTS=true DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_HOME='/Users/z3437171/.juliaup/bin' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=4 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R", reporter = "summary")'
```

Result: exit 0, three live test blocks ran through the R-to-Julia bridge on Julia 1.10.0. They cover probit/cloglog animal slopes, animal intercepts, and relmat intercepts, with same-data TMB fits. The new animal-intercept cases test convergence, finite/named SD coefficients, point recovery, fitted group-SD predictions, and native/Julia log-likelihood agreement.

The fit-free rerun of the same file passed, with all three live blocks skipped as expected. `git diff --check` passed. This evidence does not establish interval coverage or broad family/effect parity.
