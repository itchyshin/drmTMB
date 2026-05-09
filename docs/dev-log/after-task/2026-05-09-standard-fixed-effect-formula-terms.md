# After Task: Standard Fixed-Effect Formula Terms

## Goal

Answer whether `drmTMB` supports ordinary R fixed-effect formula terms such as
`poly(x, 2)`, `I(x^2)`, `x1:x2`, and `(x1 + x2 + x3)^2`, and make that answer
testable in the package rather than leaving it only in chat.

## Implemented

Implemented fixed-effect distributional-parameter formulas now have an explicit
test and documentation statement saying they use base R formula semantics via
`model.matrix()`. This covers transformed basis columns and interaction
expansions in fixed-effect formulas for implemented parameters such as `mu`,
`sigma`, and `rho12`.

No new parser feature was needed: the implementation already used base R model
frame and model matrix machinery. The new work verifies that behaviour and
records the intended contract.

## Mathematical Contract

For a Gaussian location-scale model with a quadratic effect of `x`, pairwise
interactions among `x1`, `x2`, and `x3`, and a quadratic scale model in `z`,
the user can write:

```r
fit <- drmTMB(
  drm_formula(
    y ~ poly(x, 2) + I(x^2) + (x1 + x2 + x3)^2,
    sigma ~ poly(z, 2) + x1:x2
  ),
  family = gaussian(),
  data = dat
)
```

The implemented linear predictors are:

```text
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
y_i ~ Normal(mu_i, sigma_i^2)
```

Here `poly(x, 2)`, `I(x^2)`, `(x1 + x2 + x3)^2`, and `x1:x2` are expanded by
base R before fitting. They are nonlinear functions of the original covariates
but remain linear in their coefficients. That is the standard ecological
quadratic and interaction workflow, not a general nonlinear model.

## Files Changed

- `tests/testthat/test-gaussian-location-scale.R`
- `docs/design/01-formula-grammar.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-09-standard-fixed-effect-formula-terms.md`

## Checks Run

- Ad hoc formula fit with `poly(x, 2)`, `I(x^2)`, `(x1 + x2 + x3)^2`,
  `x1:x2`, and `predict(newdata = ...)`: convergence code 0.
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`:
  74 passed, 0 failed after strengthening the `poly()` newdata-basis checks.
- `Rscript -e "rmarkdown::render('vignettes/formula-grammar.Rmd', output_dir = tempdir(), quiet = TRUE)"`:
  passed.
- `Rscript -e "devtools::test()"`: 1253 passed, 0 failed after the final
  test update.
- `Rscript -e "pkgdown::build_site()"`: passed after rerunning with cache and
  network permission.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.

## Tests Of The Tests

The new test checks the exact `model.matrix()` column names for transformed and
interaction fixed-effect terms. It also manually constructs the expected
`newdata` design matrices using the training-data `poly()` basis, then checks
`predict(newdata = ...)` against matrix multiplication with those matrices.
That means the subtle `poly()` prediction contract is tested as well as model
fitting.

The initial ad hoc verification failed once because the R expression was passed
through a shell double-quoted string and `$x`, `$y`, and related data-frame
columns were expanded by the shell. Rerunning with single quotes confirmed the
package behaviour; the failure was a command quoting problem, not a package
problem.

## Consistency Audit

The formula grammar design document and formula-grammar vignette now give the
same fixed-effect rule. The status inventory was checked with:

```sh
rg "poly\\(|I\\(x|\\(x1 \\+ x2 \\+ x3\\)\\^2|ordinary formula|standard R" README.md ROADMAP.md NEWS.md docs vignettes tests R
rg "formula grammar|fixed-effect formula|fixed effects" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd
```

No README, ROADMAP, NEWS, or known-limitations change was needed because this
task clarifies already-supported fixed-effect formula behaviour rather than
adding a new family, model class, or unsupported syntax.

## What Did Not Go Smoothly

The shell quoting failure was a small but useful reminder: any ad hoc R command
that uses `$` inside a data frame should be single-quoted at the shell level or
moved into a test file. The first pkgdown build also failed under sandboxed
cache/network access; rebuilding with the proper permission passed.

## Team Learning

Boole's rule for the formula parser is now clearer: lean on base R formula
semantics for fixed effects, and document restrictions only where `drmTMB`
intentionally narrows the grammar. Rose's audit should keep distinguishing
fixed-effect transformations from random-effect or structured-effect slopes,
because users naturally ask about all of them in the same sentence.

## Known Limitations

This task does not broaden random-effect slope support. Ordinary fixed-effect
interactions such as `(x1 + x2 + x3)^2` are supported, but interaction random
slopes should be treated cautiously until the random-effect grammar documents
and tests the intended behaviour. For now, an interaction random slope should
be materialized as a data column before use.

This task also does not implement general nonlinear models. Polynomial and
interaction formula terms are basis expansions inside linear predictors.

## Next Actions

Add a small tutorial paragraph in a biological example showing a quadratic
environmental response, such as activity changing with temperature and
`sigma` changing with habitat quality. Later, revisit whether random-effect
slopes should accept transformed terms directly or require users to create
explicit columns for interpretability and numerical stability.
