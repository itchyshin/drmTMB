# Julia Binomial phylogenetic plus IID SD bridge receipt

Date: 2026-10-29.

## Source pins

- drmTMB HEAD: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl HEAD: `70dbf564eb670144c63c08f61ea099084d95add2`
- Source manifest: `source-manifest.json`

## Command and result

Ran `testthat::test_file("tests/testthat/test-julia-binomial-phylo-iid-sd-bridge.R", reporter = "summary")` from drmTMB with Julia 1.10.0, `JULIA_NUM_THREADS=4`, `OPENBLAS_NUM_THREADS=1`, `DRMTMB_JULIA_TESTS=true`, and `DRM_JL_PATH` set to the paired `general-sd-julia` checkout. The retained `console.log` (SHA-256 `10127466df446cf7e64bcaeaa9f726d9f5f018f290dbf67e53278acf3331a740`) reports one live bridge test passed.

The synthetic fixture uses independent phylogenetic and IID random intercepts with predictor-dependent scales and a unit-height tree. Under both probit and cloglog, the test fits the same data through native TMB and Julia; checks convergence, positive SD slopes, cross-engine slope difference below 0.45, predicted group SD difference below 0.45, log-likelihood difference below 0.08, and one Julia marginal draw with binary outcomes.

## Interpretation boundary

This is focused candidate evidence for Julia Binomial `mu`, `iid:group_factor+phylo:tree`, q1 additive independent fields, probit and cloglog. It is not repeated-sample recovery, calibrated uncertainty, interval coverage, or broad parity evidence. The tolerance checks are fixture-specific and not a general accuracy guarantee.
