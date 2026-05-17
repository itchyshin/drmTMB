# After-Task Report: Slices 178-181 Gaussian q > 2 Location Blocks

## Scope

This task moved ordinary univariate Gaussian `mu` random slopes from the
one-slope boundary to the first public q > 2 unstructured grouped block. The
implemented syntax is:

```r
bf(y ~ x1 + x2 + (1 + x1 + x2 | id), sigma ~ z)
bf(y ~ x1 + x2 + (1 + x1 + x2 | p | id), sigma ~ z)
```

The q=3 path is tested. Larger numeric blocks are accepted by the parser but
remain advanced fits until Phase 18 simulation measures the group count,
within-group spread, slope-SD, convergence, boundary, and interval cost.

## What Changed

- `parse_random_mu_lhs()` now accepts ordinary Gaussian `mu` blocks with an
  intercept and multiple simple numeric slope symbols.
- The univariate Gaussian spec splits q > 2 `mu` blocks out of the legacy
  `u_mu` path and sends them through the labelled covariance registry.
- The TMB Gaussian likelihood now applies `u_re_cov`, `log_sd_re_cov`, and
  `theta_re_cov` contributions for q > 2 ordinary blocks.
- `predict(dpar = "mu")` includes the fitted q > 2 covariance-block
  contribution for fitted rows.
- `profile_targets()` maps q > 2 block SDs to direct `log_sd_re_cov` targets
  and keeps unstructured correlations as derived, unavailable-for-direct
  profiling targets.
- `NEWS.md`, `ROADMAP.md`, `docs/design/04-random-effects.md`, and
  `docs/design/33-phase-6c-core-random-effects.md` now state the q=3 evidence
  boundary and output names.

## Validation

- `air format R/drmTMB.R tests/testthat/test-gaussian-random-intercepts.R src/drmTMB.cpp`
- `Rscript -e 'devtools::test(filter = "gaussian-random-intercepts")'`
- `Rscript -e 'devtools::test(filter = "gaussian-random-intercepts|profile-targets")'`
- `Rscript -e 'devtools::test(filter = "corpairs|gaussian-random-intercepts|profile-targets|summary")'`
- `Rscript -e 'devtools::test(filter = "gaussian-location-scale|gaussian-random-intercepts|profile-targets", reporter = "summary")'`
- `Rscript -e 'devtools::test(reporter = "summary")'`
- `Rscript -e 'devtools::document()'`
- `git diff --check`
- `Rscript -e 'pkgdown::check_pkgdown()'`

The broad focused run passed with `FAIL 0 | WARN 0 | SKIP 0 | PASS 1090`.
The full package test run and `pkgdown::check_pkgdown()` also passed.

## Boundaries

The implementation fits and reports q > 2 ordinary Gaussian `mu` SDs and
correlations. Direct profile intervals are ready for the SDs, not for the
unstructured correlations. Residual-scale correlated slope blocks, multiple
residual-scale slopes, slope-specific `sd(group)` formulae, bivariate random
slopes, phylogenetic slopes, and non-Gaussian random-effect slopes remain
planned.

## Standing Roles

Ada coordinated the slice boundary and kept the work small enough for one PR.
Boole checked the syntax boundary: ordinary Gaussian `mu` accepts
`(1 + x1 + x2 | id)`, while residual-scale correlated slope blocks still error.
Gauss and Noether kept the q > 2 path on the positive-definite registry/TMB
parameterization rather than the legacy pairwise correlation loop. Fisher and
Curie required q=3 recovery, prediction, `corpairs()`, summary, and
`profile_targets()` coverage. Pat and Darwin pushed the docs to say what an
applied user can fit now and where sample-size caution starts. Emmy checked
the extractor paths. Grace required roxygen regeneration and CI-ready focused
tests. Rose closed the loop by removing stale "planned but not implemented"
wording for ordinary Gaussian `mu` q > 2 blocks while preserving the remaining
unsupported boundaries.

## Next Actions

Slice 182 should pin the residual-scale random-slope boundary: independent
`sigma` slopes are implemented, but correlated residual-scale intercept-slope
and multi-slope blocks still need a separate likelihood, extractor, and
simulation lane. Slice 183 can then return to the two matched `mu`/`sigma`
random-intercept covariance blocks.
