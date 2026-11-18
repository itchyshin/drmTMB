# Evidence receipt: Julia Binomial animal-intercept logit with A and Ainv

Date: 2026-10-29

## Question

Do the current native and Julia bridges fit the Bernoulli logit animal-intercept SD regression consistently when the relationship input is supplied as covariance `A` or precision `Ainv`?

## Result

Yes, for the fixed synthetic fixture. The focused test passed with two live Julia bridge tests. For both matrix inputs, native and Julia fits recover the generated log-SD slope within the predeclared test tolerance, agree on the slope and likelihood, and return matching group SDs. The test also checks agreement between the covariance and precision representations within each engine.

## Reproduction

```sh
NOT_CRAN=true JULIA_HOME='/Users/z3437171/.juliaup/bin' DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 R_PROFILE_USER=/dev/null /usr/local/bin/Rscript -e 'devtools::test(filter = "julia-binomial-animal-sd-regression", reporter = "summary", stop_on_failure = TRUE)'
```

The saved `test-console.log` reports exit 0 and two live Julia bridge tests. It includes the animal-intercept `A`/`Ainv` comparison and the existing ordinary animal-slope bridge fixture.

## Source pins

- drmTMB candidate: `425bee81572c625a634b2b083050c5c57c1dc1f1`
- DRM.jl candidate: `70dbf564eb670144c63c08f61ea099084d95add2`
- Exact source, test, and log hashes: `source-manifest.sha256`

## Limits

This receipt links the Julia logit animal-intercept q1 rows for supplied `A` and `Ainv`. The same focused test includes native comparison, but native rows were already linked by an earlier receipt. It does not establish other links, pedigree, q2, interval calibration, or coverage. Both Julia rows remain unresolved and unreviewed.
