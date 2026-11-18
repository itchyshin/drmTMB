# Check Log: Cloglog phylogenetic Bernoulli SD bridge

Date: 2026-10-26

Candidate pins: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.

Direct Julia test: `test/test_binomial_cloglog_phylo_sd_regression.jl`, Julia 1.10.0, passed 29/29.

Live bridge command:

```sh
JULIA_HOME='/Users/z3437171/.juliaup/bin' \
DRMTMB_JULIA_TESTS=true \
DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' \
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null \
/usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd")'
```

Result: PASS, 71 expectations, 0 failures, 0 testthat warnings, 0 skips. Three live Julia tests ran in 119.0 seconds. The probit route emitted a near-singular Hessian warning for two coordinates (`rcond = 4.6681524208092426e-11`); those Wald standard errors are not trustworthy. Console log: `docs/dev-log/general-sd-regression/evidence/julia-binomial-cloglog-phylo-bridge-20261026/live-bridge-test.log`, SHA-256 `18e85e9980e24230f6561c954b63c64b3989470b4766093cefcac4b38124027d`.

Source SHA-256: `R/julia-bridge.R` `5966d1170c12e73bed99baba5fa4153ede4a98a29d1fbde4aafca032c552b145`; `tests/testthat/test-julia-binomial-phylo-sd.R` `bb6c0be230a2f64489f1d5227c07d7cb25b8e549ccfeaa19978448d7a2acf6e4`.

Scope: one synthetic Bernoulli/cloglog phylogenetic random-intercept SD-regression bridge. No interval calibration, broad cross-engine parity, full-suite, or release claim.
