# Bernoulli probit correlated q3 SD bridge receipt

Date: 2026-10-26 local time.

The opt-in R-to-Julia test fitted the same synthetic Bernoulli probit model with native TMB and the paired DRM.jl development candidate. The model has one ordinary correlated block with an intercept and two numeric slopes, and one fixed-predictor SD formula for each coefficient. The test passed its coefficient, correlation, group-specific SD prediction, and marginal simulation checks. It emitted one Julia warning: the Hessian was numerically singular at coordinate 12, with reciprocal condition estimate `4.1128792556230674e-11`. The affected Wald standard error is not trustworthy.

This is a one-fixture cross-engine point and output check. It does not establish recovery against truth, reliable Wald uncertainty, profile or bootstrap intervals, interval coverage, or support for other links, block sizes, families, or structured effects.

The run used R 4.6.0, Julia 1.10.0, one Julia thread, and one BLAS/OMP thread. It completed below the announced 10-minute limit. The test transcript was observed in the task session but was not saved as a raw log.

Exact command:

```sh
JULIA_BIN='/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin'
PATH="$JULIA_BIN:$PATH" JULIA_HOME="$JULIA_BIN" JULIA_NUM_THREADS=1 \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
DRM_JL_JULIA_HOME="$JULIA_BIN" \
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
DRMTMB_JULIA_TESTS=true \
Rscript -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-julia-binomial-correlated-q3-sd-bridge.R", reporter="summary", stop_on_failure=TRUE)'
```

Candidate pins at the run: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; paired DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`. Both worktrees contained other in-flight changes. The following hashes identify the relevant source and test files at closeout:

```text
56b88276994bc09decfd56162360234e915c858ee1ca27d3a6b73bb4352d64d6  drmTMB/R/julia-bridge.R
62f799c965194260c1672940e7ba7ea847e424d526161edb87ea5b59d276adc9  drmTMB/R/julia-simulate.R
8daf84e2f6d1c650500a4c31e36f12d5f5045d9db405bfe4b3d8b9c28c4b2853  drmTMB/tests/testthat/test-julia-binomial-correlated-q3-sd-bridge.R
5dce57b711cabd3b21b836f74d1affa247f2ed8d40b4320b5966491051a9ef60  DRM.jl/src/bridge.jl
e06cf2a73c431b8db905dac51f89223a43da6f08d3e78ac34e651c22084ba5fd  DRM.jl/src/gaussian_core.jl
d5cfff92f46610a539d89fc9cc932c3788098895aba3553c42f34d666821d500  DRM.jl/src/binomial_sd_regression.jl
41bf229ad8ae1e56477b589e104ea60fc7cc861942bd30c5a9f5cb5bdd312a9d  DRM.jl/src/binomial.jl
```
