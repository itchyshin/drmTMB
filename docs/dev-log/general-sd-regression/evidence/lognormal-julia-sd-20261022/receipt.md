# Julia LogNormal ordinary direct-SD bridge receipt

The paired development candidates fit two complete-data LogNormal location models: one ordinary random intercept and one independent numeric random slope. Each uses a matching predictor-dependent `sd()` formula and fixed `sigma ~ 1`. The live R bridge test compares SD coefficients, group SD predictions, and row predictions against native TMB; the intercept fixture also checks save/reload.

The source-hash-bound focused run passed 16 structural admission expectations and two live Julia bridge tests, with no failures or skips. Julia group prediction names include the target prefix, so the fixture aligns group values by target and group identity before comparing values. The run includes the current qualified `nlme::fixef` method registration and NAMESPACE.

- drmTMB candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`
- R: 4.6.0; TMB: 1.9.21; Julia: 1.10.0
- Test command: `DRM_JL_PATH=<paired DRM.jl candidate> DRMTMB_JULIA_TESTS=true JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-lognormal-sd-(parity|gate)", reporter = "summary", stop_on_failure = TRUE)'`
- Console log: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/docs/dev-log/general-sd-regression/evidence/lognormal-julia-sd-20261022/test-console.log` (SHA-256 `3ee3cd85874cc6709183c437f42c9cf3e8c06e6a1b268f769cee6fade99ea47c`)
- Source manifest: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/docs/dev-log/general-sd-regression/evidence/lognormal-julia-sd-20261022/sources-before.sha256` (SHA-256 `fa9a82df2fc83b57dc35ee3891274a0d8354c79f8f1437c34a873e852d463248`)
- Parity test: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/tests/testthat/test-julia-lognormal-sd-parity.R` (SHA-256 `26b21486f3bb5129c90fbe9ff7e5e480f33c6c9735f8c8ed6d6eec811a04b37d`)

This receipt covers only the two tested ordinary `mu` forms under fixed `sigma` in the paired development candidates. It does not establish interval calibration, support in the current shared/released DRM.jl package, structured or correlated effects, other LogNormal endpoints, missing-data parity, or broad family parity.
