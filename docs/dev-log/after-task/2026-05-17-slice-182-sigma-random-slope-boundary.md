# After Task: Slice 182 Sigma Random-Slope Boundary

## Goal

Pin the Gaussian residual-scale random-slope boundary before returning to
location-scale covariance and bivariate or structured random-slope slices.

## Implemented

`sigma` formulas already fitted random intercepts and independent numeric
random slopes on `log(sigma)`. This slice makes the boundary explicit:
multiple independent residual-scale terms such as
`sigma ~ z + (1 | id) + (0 + w1 | id) + (0 + w2 | id)` fit separate
`sdpars$sigma` rows, and their latent correlations remain fixed at zero.
Correlated residual-scale intercept-slope blocks and labelled residual-scale
slope covariance blocks remain planned.

## Mathematical Contract

For group `j`,

```text
log(sigma_ij) = X_sigma[ij, ] beta_sigma + a_0j + w1_ij a_1j + w2_ij a_2j
a_kj = sd_k v_kj
v_0j, v_1j, v_2j ~ Normal(0, 1)
cor(v_kj, v_lj) = 0 for k != l in this phase
```

The scale model remains a residual `sigma` model. It is not an `sd(group)`
model for the location random-effect SD.

## Files Changed

- `tests/testthat/test-gaussian-random-intercepts.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/04-random-effects.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-182-sigma-random-slope-boundary.md`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/04-random-effects.md docs/design/33-phase-6c-core-random-effects.md tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e 'devtools::test(filter = "gaussian-random-intercepts", reporter = "summary")'`: passed.
- `Rscript -e 'devtools::test(filter = "profile-targets|gaussian-random-intercepts", reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The new test fits a model with three independent residual-scale random-effect
terms, checks the fitted log-`sigma` contribution against
`predict(dpar = "sigma", type = "link")`, verifies three direct
`log_sd_sigma` profile targets, and confirms that no `cor:sigma` target is
created.

## Consistency Audit

The roadmap, formula grammar, random-effects design note, and Phase 6c status
note now use the same boundary: multiple independent Gaussian `sigma` random
effects are implemented; residual-scale random-effect correlations are fixed
at zero unless a labelled intercept-only covariance block is explicitly
implemented elsewhere.

## What Did Not Go Smoothly

The feature itself was already in the engine. The important work was avoiding
overclaiming: the test and docs had to say "multiple independent terms" rather
than imply correlated scale random-slope blocks. The first test draft also used
an over-tight lower bound on every fitted scale SD; the final test checks the
model contract instead, because a weak residual-scale component can legitimately
estimate near the boundary.

## Team Learning

Ada kept this as a closure slice instead of opening a new covariance surface.
Fisher and Curie wanted a test that inspects profile-target status, not only
optimizer convergence. Pat and Darwin pushed the docs to distinguish residual
`sigma` random effects from `sd(group)` scale models. Grace kept the validation
to targeted tests and pkgdown because no likelihood algebra changed. Rose
recorded the zero-correlation boundary as a named limitation before the next
location-scale covariance slice.

## Known Limitations

Correlated residual-scale intercept-slope blocks such as
`sigma ~ z + (1 + w | id)`, labelled residual-scale slope covariance, bivariate
scale slopes, non-Gaussian scale random effects, and profile intervals for
derived multi-parameter correlations remain future work.

## Next Actions

Slice 183 can return to the two matched `mu`/`sigma` random-intercept covariance
blocks. Slice 185 should then define the first bivariate random-slope policy
without opening large endpoint covariance blocks prematurely.
