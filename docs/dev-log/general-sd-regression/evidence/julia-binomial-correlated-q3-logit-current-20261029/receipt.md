# Current-source Julia Binomial correlated q3 logit bridge receipt

Date: 2026-10-29.

The opt-in live R-to-Julia test passed for an independent synthetic logit Binomial model with 160 groups, 32 observations per group, and one correlated intercept plus two numeric slopes. Each of the three random coefficients has a fixed-predictor SD regression. TMB and Julia converged; the test checks all three SD slopes against the generating values, cross-engine coefficient and correlation agreement, group-specific SD predictions, and marginal binary simulation. The test reports one live Julia bridge test, no failures or skips, and shell exit code 0.

This is one high-information fixed-seed design. It does not establish low-information stability, interval calibration, or broad programme completion.

Runtime: Julia 1.10.0, one Julia thread, one BLAS/OMP thread. Wall time was 7 minutes 56 seconds. The exact console, test snapshot, and source hashes are saved beside this receipt.

Command:

```sh
PATH=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin:$PATH JULIA_HOME=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 NOT_CRAN=true DRM_JL_JULIA_HOME=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin DRM_JL_PATH=<paired candidate> DRMTMB_JULIA_TESTS=true Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-julia-binomial-correlated-q3-logit-sd-bridge.R", reporter="summary", stop_on_failure=TRUE)'
```

Review status remains unreviewed. This evidence applies to the current candidate source pins only.
