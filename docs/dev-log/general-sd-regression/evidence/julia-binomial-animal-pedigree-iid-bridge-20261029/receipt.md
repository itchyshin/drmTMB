# Julia Binomial animal pedigree plus IID SD bridge receipt

Date: 2026-10-29.

The opt-in live R-to-Julia bridge test passed a synthetic logit model with one animal intercept built from a pedigree and one independent IID site intercept. Both effects have separate fixed-predictor SD regressions. The test confirms route admission, pedigree-to-A marshalling and label order, convergence in TMB and Julia, coefficient target names, likelihood agreement, group-specific SD prediction agreement, and marginal binary simulation. The test file reports two live Julia bridge tests, no failures or skips, and exited 0.

This is one fixed-seed design. It is focused bridge evidence, not broad recovery, interval calibration, or evidence for all structured-effect pairs.

Runtime: Julia 1.10.0, one Julia thread, one BLAS/OMP thread. The exact console and hashes are saved beside this receipt.

Command:

```sh
PATH=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin:$PATH JULIA_HOME=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 DRM_JL_JULIA_HOME=/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRMTMB_JULIA_TESTS=true Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-julia-binomial-animal-iid-nonlogit-sd-bridge.R", reporter="summary", stop_on_failure=TRUE)'
```

No model implementation changed in this slice. The test adds exact candidate evidence for one Julia Binomial animal-pedigree plus IID provider-pair row under logit. Review status remains unreviewed.
