# Julia Binomial animal Ainv plus IID bridge receipt

Date: 2026-10-29.

The opt-in live R-to-Julia parity test passed for a logit Binomial model with a pedigree-related animal intercept supplied through its precision matrix Ainv and a separate ordinary IID site intercept. Both effects have predictor-dependent SDs. The test checks TMB and Julia convergence, coefficient-specific SD outputs, likelihood parity, equality of A and equivalent Ainv fits, an independent dense joint-Laplace oracle for the covariance form, SD predictions, simulation component structure, and deterministic marginal binary simulation. The saved run reports one live Julia bridge test, no failures or skips, and shell exit code 0.

This is one synthetic dataset. It is focused candidate evidence, not interval calibration or broad provider-pair coverage.

Runtime: Julia 1.10.0, one Julia thread, and one BLAS/OMP thread. Exact source hashes and console are saved beside this receipt.

Command:

```sh
PATH=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin:$PATH JULIA_HOME=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 NOT_CRAN=true DRM_JL_JULIA_HOME=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMTMB_JULIA_TESTS=true Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-julia-binomial-animal-iid-sd-parity.R", reporter="summary", stop_on_failure=TRUE)'
```

Review status remains unreviewed.
