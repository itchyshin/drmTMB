# Evidence receipt: non-logit Binomial animal-intercept SD with covariance A

Date: 2026-10-29

## Question

Do the R-to-Julia and native R/TMB engines fit the Binomial animal-intercept SD regression with supplied covariance `A` under probit and complementary log-log links?

## Result

Yes, for the fixed synthetic fixture. The focused test ran one live bridge test and passed for both links. For each link, both engines converged, estimated the SD-regression slope within 0.55 of the generating value, agreed on that slope within 0.35, agreed on log likelihood within 0.02, and returned matching fitted group SDs within 0.03.

The test used 80 groups, 32 observations per group, a covariance matrix with unequal diagonal entries, and generating log-SD coefficients `(-0.6, 0.5)`. Separate fixed seeds generated the latent field and each link's responses.

## Reproduction

```sh
NOT_CRAN=true JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-animal-A-nonlogit-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'
```

The saved `test-console.log` reports exit 0 and one live Julia bridge test. Exact file hashes are recorded in `source-manifest.sha256`.

## Source pins

- drmTMB candidate: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl candidate: `70dbf564eb670144c63c08f61ea099084d95add2`

## Limits

This is focused fit, coefficient-recovery, likelihood, and fitted-SD agreement evidence for one q1 animal intercept with covariance input `A` under probit and cloglog. It does not establish interval coverage, other animal inputs, other random-effect types, or broad Julia parity. The evidence rows remain unreviewed; no capability status was promoted.
