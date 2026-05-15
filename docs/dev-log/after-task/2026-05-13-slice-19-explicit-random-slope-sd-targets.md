# After Task: Slice 19 Explicit Random-Slope SD Target Reservation

## Goal

Reserve a clear syntax for future coefficient-specific random-effect SD models
without fitting multi-random-slope scale regression before the covariance model
is designed.

## Implemented

- `drm_formula()` now parses explicit random-effect scale targets such as
  `sd(id, dpar = "mu", coef = "x", block = "p") ~ z`.
- `drmTMB()` rejects those explicit targets before fitting with a reserved-but
  not-implemented message.
- The parser validates that explicit `sd()` targets are currently
  location-only through `dpar = "mu"`.
- `sd1()` and `sd2()` continue to use their short bivariate location-only
  grammar and reject explicit target options.
- Formula grammar, random-effect scale design notes, known limitations, NEWS,
  and tests were updated.

## Mathematical Contract

The current fitted Family B scale model is:

```text
b_j = sd_j u_j
u_j ~ Normal(0, 1)
log(sd_j) = W_j alpha
```

That model is unambiguous only when a group contributes one location random
intercept. A future random-slope version must decide how to parameterize:

```text
[b0_j, b1_j]' ~ MVN(0, Sigma_j)
```

when `sd0_j` and `sd1_j` may both depend on predictors. The first reserved
syntax names the coefficient explicitly, but fitting remains planned until
the package defines whether the intercept-slope correlation is constant,
predictor-dependent, or otherwise constrained.

## Files Changed

- `R/parse-formula.R`
- `R/drmTMB.R`
- `tests/testthat/test-package-skeleton.R`
- `tests/testthat/test-gaussian-random-effect-scale.R`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/parse-formula.R R/drmTMB.R tests/testthat/test-package-skeleton.R tests/testthat/test-gaussian-random-effect-scale.R`
- `Rscript -e 'devtools::test(filter = "package-skeleton|gaussian-random-effect-scale", reporter = "summary")'`
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`
- `Rscript -e 'devtools::test(filter = "package-skeleton|gaussian-random-effect-scale|biv-gaussian", reporter = "summary")'`
- `git diff --check`
- `rg -n 'Future explicit syntax should be considered|sd\\(id, dpar = "mu"\\).*support only|Explicit coefficient-specific .* implemented|sd\\(id, dpar = "sigma"\\).*Reserved' R tests docs NEWS.md`

## Tests Of The Tests

The parser test checks the stored target fields for `dpar`, `coef`, and
`block`, plus malformed explicit targets. The fit-time test checks that an
otherwise valid Gaussian random-intercept model still rejects explicit `sd()`
targets before optimization.

## Consistency Audit

The documentation now says explicit coefficient-specific `sd()` syntax is
reserved, not implemented. The implemented shorthand remains `sd(group)` for a
single unlabelled Gaussian `mu` random intercept and `sd1(group)` /
`sd2(group)` for bivariate location random intercepts.

## What Did Not Go Smoothly

`air format` reformatted a few long expectations in the existing
random-effect-scale test file. The formatting changes are mechanical and kept
inside the touched test file.

## Team Learning

Boole gets a stable spelling for future random-slope scale targets. Gauss and
Noether still need the covariance model before this can become a likelihood
slice.

## Known Limitations

- Explicit `sd()` target formulas are rejected by `drmTMB()`.
- Random-slope SD regression and predictor-dependent random-effect
  correlations remain planned.
- Bivariate explicit `sd(id, dpar = "mu1")` syntax is not reserved; the
  current bivariate direct-SD names remain `sd1(group)` and `sd2(group)`.

## Next Actions

Either design the random-slope covariance parameterization in more detail, or
continue with q4/phylogenetic hardening where the fitted likelihood already
exists.
