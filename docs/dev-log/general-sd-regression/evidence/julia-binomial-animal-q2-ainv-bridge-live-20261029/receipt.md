# Evidence receipt: Julia Binomial animal q2 with supplied Ainv

Date: 2026-10-29

## Question

Does the existing R-to-Julia bridge correctly pass and fit a supplied animal precision matrix for a Bernoulli logit intercept-plus-slope block with separate predictor-dependent SD formulas?

## Result

Yes, for this synthetic candidate fixture. The bridge payload identifies the matrix keyword as `Ainv` and passes the exact supplied matrix. Native TMB and Julia fits converge; their log likelihoods, coefficient-specific SD coefficients, and predicted group SDs agree within the focused test tolerances. The Julia marginal simulator returns binary responses and matches a seeded independent draw built from the equivalent covariance matrix `A`.

The change in this slice is a regression test. No model or bridge source changed because the current implementation already handled this route.

## Reproduction

```sh
JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-animal-q2-sd", reporter = "summary", stop_on_failure = TRUE)'
```

The saved `test-console.log` reports exit 0 and three live Julia bridge tests. The Ainv fixture uses 80 groups, 24 observations per group, a fixed seed, and one supplied inverse covariance matrix.

## Source pins

- drmTMB candidate: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl candidate: `70dbf564eb670144c63c08f61ea099084d95add2`
- Exact source, test, and log hashes: `source-manifest.sha256`

## Limits

This receipt covers Julia `binomial` logit, one supplied-`Ainv` animal q2 block, one intercept and one numeric slope, complete synthetic data, one seed, fit/output agreement and marginal simulation. It does not establish probit/cloglog Ainv parity, pedigree bridge parity, coverage calibration, broader recovery, other providers, or general family support. Capability status remains unchanged.
