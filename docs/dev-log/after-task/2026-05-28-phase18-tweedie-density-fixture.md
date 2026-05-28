# After Task: Phase 18 Tweedie Density Fixture

Date: 2026-05-28

## Goal

Add a small direct density fixture for the fitted fixed-effect Tweedie lane
before opening the larger `tweedie_fixed_effect` artifact implementation.

## Implemented

`tests/testthat/helper-tweedie-density.R` now provides a test-only compound
Poisson-Gamma reference for the Tweedie density with `1 < nu < 2`. The helper
uses the fitted `drmTMB` public scale through `phi = sigma^2`, computes the
Poisson rate, Gamma shape, and Gamma scale, returns the exact-zero log mass,
and evaluates positive observations by summing the compound Poisson-Gamma
series on the log scale.

`tests/testthat/test-tweedie-location-scale.R` now fits a tiny intercept-only
Tweedie model with both exact zeros and positive observations, then compares
`logLik(fit)` with the independent reference-density sum at the fitted `mu`,
`sigma^2`, and `nu`.

## Mathematical Contract

For `1 < nu < 2`, the direct fixture uses

```text
lambda = mu^(2 - nu) / (phi * (2 - nu))
alpha = (2 - nu) / (nu - 1)
gamma = phi * (nu - 1) * mu^(nu - 1)
```

with `N ~ Poisson(lambda)` and positive increments
`X_j ~ Gamma(shape = alpha, scale = gamma)`. The zero mass is
`Pr(y = 0) = exp(-lambda)`. For `y > 0`, the fixture evaluates the
compound-density series

```text
sum_j Pr(N = j) * dgamma(y; shape = j * alpha, scale = gamma)
```

on the log scale. This independently checks the TMB `dtweedie()` likelihood
constants for a small fitted example.

## Files Changed

- `tests/testthat/helper-tweedie-density.R`
- `tests/testthat/test-tweedie-location-scale.R`
- `docs/design/03-likelihoods.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/helper-tweedie-density.R tests/testthat/test-tweedie-location-scale.R docs/design/03-likelihoods.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-28-phase18-tweedie-density-fixture.md
Rscript --vanilla -e "devtools::test(filter = '^tweedie-location-scale$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(tweedie-location-scale|family-link-contract)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'tweedie_fixed_effect.*(implemented|exists|ready|runnable)|Tweedie.*now has.*(DGP|runner|writer|grid)|Tweedie.*ready for.*coverage|manual `tweedie_fixed_effect`|phase18_(dgp|run|write)_tweedie|nu ~ x|Tweedie random|bivariate Tweedie|zero-inflation aliases|hurdle aliases' README.md NEWS.md ROADMAP.md docs/design inst/sim R src NAMESPACE man tests/testthat --glob '!docs/dev-log/**' --glob '!docs/reference/**' --glob '!docs/articles/**'
git diff --check
```

Results: formatting completed; focused `test-tweedie-location-scale` passed;
the combined focused Tweedie and family-link gate passed;
`pkgdown::check_pkgdown()` reported no problems; the stale-support scan
returned only expected current-support or planned-boundary references; and
`git diff --check` was clean.

## Tests Of The Tests

The new test compares the fitted TMB likelihood to an independent compound
Poisson-Gamma density calculation rather than to another fitted package. It
covers both exact-zero mass and positive observations.

## Consistency Audit

This slice does not widen the Tweedie surface. It adds no DGP, runner, grid
writer, manual Actions task, coverage table, predictor-dependent `nu`, random
effects, structured effects, bivariate Tweedie route, zero-inflation alias, or
hurdle alias.

## Known Limitations

The reference-density helper is deliberately test-only and uses a finite
log-scale series with a generous term limit for a small fixture. It is not a
public density API and is not a replacement for TMB's automatic-differentiable
`dtweedie()` branch.

## Next Actions

After this PR is published, the next Team A slice can start the first
`tweedie_fixed_effect` artifact implementation: DGP, summariser, smoke runner,
tests, docs, check-log, and after-task report.
