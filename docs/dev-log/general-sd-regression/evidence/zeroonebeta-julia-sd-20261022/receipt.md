# Julia ZeroOneBeta ordinary direct-SD bridge receipt

The paired development candidates fit complete-response ZeroOneBeta location models with predictor-dependent SDs for one ordinary random intercept and one selected independent numeric random slope. Both keep `sigma`, `zoi`, and `coi` fixed at intercepts. The synthetic same-data fixtures compare native TMB and Julia SD coefficients, target-specific group SD predictions, and Julia prediction outputs; the intercept fixture also checks save/reload.

The hash-bound focused test passed 35 assertions with two live Julia fits, no failures, warnings, or skips.

- drmTMB candidate HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl candidate HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`
- R: 4.6.0; TMB: 1.9.21; Julia: 1.10.0
- Command: `DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH=<paired DRM.jl candidate> DRM_JL_JULIA_HOME=/Users/z3437171/.juliaup/bin JULIA_DEPOT_PATH=/private/tmp/julia-depot:/Users/z3437171/.julia OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=4 Rscript -e 'devtools::test(filter = "^julia-zero-one-beta-sd$", reporter = "summary", stop_on_failure = TRUE)'`
- Console log: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/docs/dev-log/general-sd-regression/evidence/zeroonebeta-julia-sd-20261022/test-console.log` (SHA-256 `a3e6d2b10e0c539622ac50149187168a8d6fe4be17452c7bf68234b2fce8e7ba`)
- Source manifest: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/docs/dev-log/general-sd-regression/evidence/zeroonebeta-julia-sd-20261022/sources-before.sha256` (SHA-256 `2a476d27a8315b8e8bff674437b4a23b3183c6420d02435948908f92a7af2d34`)
- Test source: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression/tests/testthat/test-julia-zero-one-beta-sd.R` (SHA-256 `9ba8fc2e93ba130a595d5e938c22b75f8f94899d4deba58fb300918b71e76814`)

This is candidate-checkout point-recovery and output evidence for these two ordinary `mu` targets only. It does not establish exact likelihood equality, interval calibration, profile/bootstrap behavior for these routes, structured or correlated effects, missing-response support, or shared/released DRM.jl support.
