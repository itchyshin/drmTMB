# Live evidence receipt: Julia Binomial phylogenetic plus IID SD bridge

Date: 2026-10-29

## Result

The existing mixed bridge test passed live on Julia 1.10.0 for probit and cloglog. It checks the exact route's admission and target labels, convergence for native TMB and Julia, positive SD-slope estimates, cross-engine coefficient and predicted-group-SD agreement, log-likelihood agreement, and Julia marginal simulation.

This run supplies the live integration evidence that the earlier report lacked because Julia was not configured for that run. The test's slope checks are directional and broad-bound checks; they do not establish close recovery of the generating slope values. The evidence grade remains `focused_test`.

## Reproduction

```sh
PATH="/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin:$PATH" JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 NOT_CRAN=true DRMTMB_JULIA_TESTS=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-binomial-phylo-iid-sd-bridge.R", reporter = "summary")'
```

The saved console log reports one live JuliaCall test passed for both links.

## Source pins

- drmTMB candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`
- Exact current source, test, and console hashes: `source-manifest.sha256`

## Limits

This receipt covers one synthetic complete-data mixed phylogenetic-intercept plus IID-intercept route for Binomial probit and cloglog. It does not cover logit for this exact pair, random slopes, other provider pairs, additional families, interval calibration, coverage, or broad Julia parity. It does not promote capability status.
