# Evidence receipt: non-logit Binomial animal-slope SD with covariance A

Date: 2026-10-29

## Question

Do the native TMB and Julia engines fit a predictor-dependent SD for a structured animal slope using supplied covariance `A` under probit and complementary log-log links?

## Result

Yes, for the fixed synthetic fixture. One live bridge test passed for both links. For each link, both engines converged, estimated the log-SD slope within 0.65 of its generating value, agreed on that slope within 0.4, agreed on log likelihood within 0.05, and returned matching fitted animal SDs within 0.04.

The test used 80 groups with 32 observations per group. The slope covariate varied within each group, and the SD predictor was constant within group. The supplied covariance had unequal diagonal entries. Generating log-SD coefficients were `(-0.45, 0.55)`.

## Reproduction

```sh
NOT_CRAN=true JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-animal-slope-A-nonlogit-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'
```

The saved `test-console.log` reports exit 0 and one live bridge test. Exact file hashes are recorded in `source-manifest.sha256`.

## Source pins

- drmTMB candidate: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl candidate: `70dbf564eb670144c63c08f61ea099084d95add2`

## Limits

This is focused fit and point-recovery evidence for a q1 animal slope with covariance input `A` under probit and cloglog. It does not establish interval coverage, other animal inputs, other random-effect types, or broad Julia parity. The four evidence rows remain unreviewed; no capability status was promoted.
