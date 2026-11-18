# Bernoulli probit and cloglog correlated q2 SD bridge receipt

Date: 2026-10-26 local time.

The opt-in live test passed one R-to-Julia block containing same-data TMB and Julia fits for both probit and complementary log-log responses. Each model had one ordinary correlated intercept-and-slope block and two coefficient-specific SD regressions. Across both links, the test checked SD-trend direction and distance from the generating slopes, correlation recovery, convergence, coefficient and correlation comparisons with TMB, and group-SD prediction agreement. Thirty live expectations passed with no warnings, failures, or skips. The run completed in about 70 seconds, within the announced 20-minute cap.

This is one synthetic fixture per link. It does not establish calibrated intervals, coverage, structured-effect support, or broad recovery across group and sample-size conditions.

Runtime: R 4.6.0, Julia 1.10.0, one Julia thread, one BLAS/OMP thread. The raw console transcript was observed in the task session and was not saved separately.

Exact command:

```sh
JULIA_BIN='/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin'
PATH="$JULIA_BIN:$PATH" JULIA_HOME="$JULIA_BIN" JULIA_NUM_THREADS=1 \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
DRM_JL_JULIA_HOME="$JULIA_BIN" \
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
DRMTMB_JULIA_TESTS=true \
Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-julia-binomial-nonlogit-correlated-sd-bridge.R", reporter="summary", stop_on_failure=TRUE)'
```

Candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`. Relevant closeout hashes:

```text
e1fd288e399583807cec2b1641b4d40192194e4156b27610420c47898db03cf0  drmTMB/tests/testthat/test-julia-binomial-nonlogit-correlated-sd-bridge.R
56b88276994bc09decfd56162360234e915c858ee1ca27d3a6b73bb4352d64d6  drmTMB/R/julia-bridge.R
5dce57b711cabd3b21b836f74d1affa247f2ed8d40b4320b5966491051a9ef60  DRM.jl/src/bridge.jl
e06cf2a73c431b8db905dac51f89223a43da6f08d3e78ac34e651c22084ba5fd  DRM.jl/src/gaussian_core.jl
d5cfff92f46610a539d89fc9cc932c3788098895aba3553c42f34d666821d500  DRM.jl/src/binomial_sd_regression.jl
```
