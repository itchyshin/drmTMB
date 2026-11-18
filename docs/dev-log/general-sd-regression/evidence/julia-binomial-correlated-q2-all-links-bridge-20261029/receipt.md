# Julia Binomial correlated q2 all-link bridge test

Date: 2026-10-29.

The opt-in R-to-Julia bridge test passed for logit, probit, and complementary log-log links on one synthetic correlated intercept-and-slope block. It checks route admission for probit/cloglog, fitting and convergence in TMB and Julia, target coefficient labels, SD trend direction and broad point-recovery bounds, correlation agreement/recovery, and target-specific group SD prediction agreement. The live Julia bridge ran once; 50 expectations passed with no failures or skips. This is one fixed-seed design per link and focused bridge evidence, not interval calibration or broad recovery.

Runtime: R package test harness with JuliaCall, Julia 1.10.0, one Julia and BLAS/OMP thread. The logged rerun exited 0.

Command:

```sh
PATH=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin:$PATH JULIA_HOME=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 DRM_JL_JULIA_HOME=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMTMB_JULIA_TESTS=true Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-julia-binomial-nonlogit-correlated-sd-bridge.R", reporter="summary", stop_on_failure=TRUE)'
```

The exact test snapshot, console, and source hashes are retained beside this receipt. This result does not establish coverage calibration, all correlated-block dimensions, all SD targets, or all-family Julia parity.
