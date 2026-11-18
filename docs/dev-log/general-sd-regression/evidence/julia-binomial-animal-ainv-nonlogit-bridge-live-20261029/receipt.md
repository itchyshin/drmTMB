# Evidence receipt: Julia Binomial animal-intercept Ainv under probit and cloglog

Date: 2026-10-29

## Question

Does the current R-to-Julia bridge fit a Bernoulli animal random intercept with a predictor-dependent SD and supplied `Ainv` under probit and complementary log-log links?

## Result

Yes, for the fixed synthetic fixture. The opt-in live bridge test passed for both links. Native TMB and Julia converged; the test checks log-SD slope recovery against the generating value, cross-engine slope agreement, likelihood agreement, and predicted animal SD agreement. No model source changed. I added a fixed seed before assigning the group-level SD predictor so the fixture is reproducible.

## Reproduction

```sh
NOT_CRAN=true JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-animal-ainv-nonlogit-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'
```

The saved `test-console.log` reports exit 0 and one live Julia bridge test, covering both links. The fixture uses 80 groups, 32 rows per group, a non-unit-diagonal covariance, and deterministic group-predictor and latent-effect seeds.

## Source pins

- drmTMB candidate: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl candidate: `70dbf564eb670144c63c08f61ea099084d95add2`
- Exact source, test, and log hashes: `source-manifest.sha256`

## Limits

This is one complete-data synthetic q1 animal-intercept fixture using supplied `Ainv`, for probit and cloglog. It does not establish logit in this exact fixture, animal q2, pedigree, other providers, interval calibration, or coverage. The four evidence rows remain unreviewed and capability status is unchanged.
