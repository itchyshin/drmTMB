# Julia Binomial phylogenetic SD bridge receipt

## Scope

Current candidate test evidence for a univariate Bernoulli phylogenetic random-intercept SD formula using `logit`, `probit`, and `cloglog`. This evidence links only the three Julia `tree` provider rows in the frozen capability table. It does not promote capability status.

## Source pins

- drmTMB: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl: `70dbf564eb670144c63c08f61ea099084d95add2`
- Source files and SHA-256 digests: `source-manifest.sha256`

## Command and result

```sh
JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-phylo-sd", reporter = "summary", stop_on_failure = TRUE)'
```

Observed result: exit 0. All tests in the filtered file passed, and three live Julia bridge tests ran for the logit, probit, and cloglog routes. The run reported the raw-tree-scale message and the standard notice that refits run serially by default.

The file checks cross-engine coefficient and likelihood agreement, group-level SD predictions, and save/reload prediction behavior. It also checks target-qualified stored `sdpars` names separately from tip names returned by `predict()`. The original current-source run exposed two name-only assertion failures; correcting those expectations led to the passing rerun. The fitted and predicted values agreed in the failing run.

## Limits

This is one synthetic dataset per link and a focused candidate-source bridge check. It does not establish repeated-sample recovery, calibrated uncertainty, interval coverage, other phylogenetic effect shapes, other providers, other families, or release readiness. One probit fit has a near-singular Hessian warning recorded in the earlier source-bound report; no Wald calibration claim is made.
