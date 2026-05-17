# After Task: Slice 193 Non-Gaussian Scale Boundary

## Goal

Revisit non-Gaussian `sigma` random effects before Phase 18 and make the
current boundary explicit rather than leaving scale bar terms to generic
unsupported-formula errors.

## Implemented

Student-t, lognormal, Gamma, beta, beta-binomial, NB2, truncated NB2, and
hurdle NB2 `sigma` formulas remain fixed-effect only in this slice. Random
effects in those scale formulas now error with a scale-specific message:

```r
bf(y ~ x, sigma ~ z + (1 | id))
```

is blocked before optimization unless the family is Gaussian. The message
points users back to fixed-effect scale formulas such as `sigma ~ z` and names
the evidence needed before non-Gaussian scale random effects can be fitted.

## Mathematical Contract

The currently fitted non-Gaussian scale model is:

```text
eta_sigma_i = X_sigma[i, ] beta_sigma
sigma_i = link_sigma^{-1}(eta_sigma_i)
```

Slice 193 deliberately does not fit:

```text
eta_sigma_i = X_sigma[i, ] beta_sigma + sd_sigma u_sigma[g[i]]
u_sigma[g] ~ Normal(0, 1)
```

outside Gaussian models. Each non-Gaussian family needs separate likelihood
code, recovery evidence, extractors, profile-target rows, and reader-facing
scale interpretation before that second equation is advertised.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-nongaussian-scale-boundary.R`
- `tests/testthat/test-nbinom2-location-scale.R`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/34-validation-debt-register.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/model-map.Rmd`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-nongaussian-scale-boundary.R tests/testthat/test-nbinom2-location-scale.R`
- `air format R/drmTMB.R NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/33-phase-6c-core-random-effects.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md vignettes/model-map.Rmd tests/testthat/test-nongaussian-scale-boundary.R tests/testthat/test-nbinom2-location-scale.R`
- `Rscript -e "devtools::test(filter = 'nongaussian-scale-boundary', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'nongaussian-scale-boundary|nbinom2-location-scale|student-location-scale|lognormal-location-scale|gamma-location-scale|beta-location-scale|beta-binomial|truncated-nbinom2|hurdle-nbinom2|zi-nbinom2', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `rg -n 'Slice 193|non-Gaussian `sigma` random effects|Non-Gaussian sigma random effects|Random-effect scale formulae are not implemented|Slice 190 first candidates|non-Gaussian scale random effects|sigma random effects.*not implemented' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests`:
  returned current Slice 193 rows, the intended `sd(group)` unsupported
  messages, and no stale Slice 190 wording.
- `git diff --check`: passed.

## Tests Of The Tests

The new boundary test exercises random intercept and independent-slope bar
terms in `sigma` formulas for Student-t, lognormal, Gamma, beta,
beta-binomial, NB2, truncated NB2, and hurdle NB2 families. These calls stop
before optimization, so the test is cheap but covers the public parser surface.
The neighbouring family test run checks that existing fixed-effect family
behaviour and malformed-input tests still pass.

## Consistency Audit

NEWS, README, ROADMAP, the formula grammar, family registry, Phase 6c
random-effect note, validation-debt register, known limitations, and model-map
article now say the same thing: non-Gaussian `sigma` formulas are fixed-effect
only until family-specific scale random-effect likelihoods and recovery tests
exist.

## What Did Not Go Smoothly

The main risk was over-claiming a scale random-effect implementation because
the Gaussian `sigma` machinery already exists. Reading the non-Gaussian C++
branches confirmed they compute `log_sigma = X_sigma * beta_sigma` directly,
so the honest Slice 193 result is a boundary and test gate.

## Team Learning

Ada kept the slice in boundary mode. Gauss and Noether checked the likelihood
contract and confirmed that the non-Gaussian scale branches need real C++
changes before fitting random effects. Fisher and Curie added broad cheap
failure tests across scale families. Pat and Darwin kept the user-facing text
on the family-specific `sigma` scale. Grace checked pkgdown. Rose checked that
the old Slice 190 wording no longer leaks into scale random-effect errors.

## Known Limitations

No non-Gaussian `sigma` random-effect likelihood is fitted in this slice.
NB2 `mu` random effects, correlated Poisson slopes, shape/skew random effects,
zero-inflation and one-inflation random effects, ordinal random effects,
structured non-Gaussian random effects, and cross-parameter non-Gaussian
covariance remain planned.

## Next Actions

Slice 194 should pin the shape/skew policy: `nu` random effects, future
skew-normal/skew-t parameters, and whether skewness belongs at the residual
distribution level, the latent ID-effect level, or both.
