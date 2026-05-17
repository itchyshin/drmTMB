# After Task: Slice 190 Non-Gaussian Mu Random-Effect Gate

## Goal

Decide which fixed-effect non-Gaussian families get an ordinary `mu`
random-intercept path first, and which retain clear unsupported messages.

## Implemented

The roadmap and family-registry design note now prioritize ordinary `mu`
random intercepts for Poisson first, then NB2 and zero-truncated NB2. Lognormal,
Gamma, Student-t, beta, beta-binomial, ordinal, zero-inflation, hurdle, shape,
and structured non-Gaussian random-effect paths remain planned. Unsupported
bar syntax in non-Gaussian formulas now tells users that random effects are
planned and names the Slice 190 first candidates.

## Mathematical Contract

The first target is a standard conditional-mean random intercept:

```text
eta_mu_i = X_i beta + b_group[i]
b_g = sd_group u_g
u_g ~ Normal(0, 1)
```

For Poisson and NB2-style count likelihoods, this enters the log-mean
predictor. It does not add random effects to dispersion `sigma`,
zero-inflation `zi`, hurdle `hu`, ordinal thresholds, shape parameters,
phylogenetic/spatial structures, or bivariate response correlation.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-poisson-mean.R`
- `tests/testthat/test-nbinom2-location-scale.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/02-family-registry.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-190-nongaussian-mu-re-gate.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-poisson-mean.R tests/testthat/test-nbinom2-location-scale.R NEWS.md ROADMAP.md docs/design/02-family-registry.md`
- `Rscript -e "devtools::test(filter = 'poisson-mean|nbinom2-location-scale|zi-poisson|zi-nbinom2|truncated-nbinom2|hurdle-nbinom2|student-location-scale|gamma-location-scale|lognormal-location-scale|beta-location-scale|beta-binomial', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Tests Of The Tests

The updated Poisson and NB2 unsupported-random-effect tests now require the
Slice 190 first-candidate guidance in the error message.

## Consistency Audit

The roadmap, family registry, NEWS, and unsupported formula message all point
to the same first target: ordinary count `mu` random intercepts. Later
non-Gaussian scale, shape, zero-inflation, hurdle, ordinal, bounded-response,
and structured paths remain explicitly out of scope.

## What Did Not Go Smoothly

The generic unsupported-term message was too uninformative for this gate. It
now remains an error, but it tells users which non-Gaussian random-effect
surface is being considered first.

## Team Learning

Ada kept Slice 190 as a decision gate. Boole improved the unsupported syntax
message. Fisher and Curie pushed the first implementation toward count
likelihoods because recovery evidence should be clearest there. Pat wanted the
error to explain what is planned. Grace kept the code change to the error
surface and targeted tests. Rose recorded the family priority before Slice
191 implementation begins.

## Known Limitations

No non-Gaussian random-effect likelihood was added in this slice.

## Next Actions

Slice 191 should implement or harden the first ordinary non-Gaussian `mu`
random-intercept path, starting with Poisson unless a focused pre-check shows
NB2 should go first.
