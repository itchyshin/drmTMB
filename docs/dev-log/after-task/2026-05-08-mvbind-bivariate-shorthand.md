# After Task: `mvbind()` Bivariate Location Shorthand

## Goal

Implement `mvbind(y1, y2) ~ rhs` as a narrow shorthand for bivariate Gaussian
models where both responses share the same location predictors, while keeping
explicit `mu1` and `mu2` formulas as the main syntax for different predictors.

## Implemented

- Added parser expansion for one unnamed `mvbind(y1, y2) ~ rhs` location
  formula in two-response Gaussian models.
- Expanded the shorthand internally to `mu1 = y1 ~ rhs` and
  `mu2 = y2 ~ rhs` before the bivariate likelihood specification is built.
- Rejected malformed or ambiguous shorthand:
  - `mvbind()` in one-response Gaussian models;
  - more than two responses;
  - named `mvbind()` formulas;
  - repeated `mvbind()` formulas;
  - `mvbind()` combined with explicit `mu1` or `mu2`.
- Updated tests, README, ROADMAP, formula grammar docs, likelihood/family
  design notes, vignettes, NEWS, and roxygen documentation.

## Mathematical Contract

The shorthand is an interface expansion only. It does not define a new
likelihood.

The user syntax

```r
drm_formula(
  mvbind(y1, y2) ~ x1 + x2,
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

is equivalent to

```r
drm_formula(
  mu1 = y1 ~ x1 + x2,
  mu2 = y2 ~ x1 + x2,
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

The fitted model remains

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
mu1_i = X_mu[i, ] beta_mu1
mu2_i = X_mu[i, ] beta_mu2
log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
rho12_i = tanh(X_rho12[i, ] beta_rho12)
Omega_i[1, 2] = rho12_i sigma1_i sigma2_i
```

where the shorthand makes `mu1` and `mu2` share the same fixed-effect design
matrix, but still estimates separate coefficient vectors for the two response
locations.

## Files Changed

- `R/drmTMB.R`
- `R/bf.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-package-skeleton.R`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/formula-grammar.Rmd`
- `man/drmTMB.Rd`
- `man/drm_formula.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'biv-gaussian|package-skeleton')"`:
  110 passed, 0 failed.
- `Rscript -e "devtools::document()"`: completed successfully.
- Stale-wording `rg` scan for planned/reserved/not-implemented `mvbind()`
  wording in current docs, tests, R files, and Rd files, excluding historical
  dev-log records: no matches.
- `Rscript -e "devtools::test()"`: 572 passed, 0 failed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `git diff --check`: clean.
- `Rscript -e "pkgdown::build_site()"`: completed successfully.
- Generated-site search found `mvbind()` shorthand text on the home page,
  roadmap, `drmTMB()` reference, `drm_formula()` reference, bivariate coscale
  article, formula grammar article, and changelog.
- `air format .`: not run because `air` is not installed locally.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

- The main equivalence test fits the explicit and shorthand formulas to the
  same simulated bivariate Gaussian data and checks equal log-likelihood and
  equal `mu1`/`mu2` coefficients.
- Failure-path tests cover malformed and ambiguous inputs, including
  univariate use, three responses, named `mvbind()`, and mixing shorthand with
  explicit `mu1` or `mu2`.
- The parser-level test checks that `drm_formula()` stores `mvbind()` as the
  unnamed location formula before model building expands it.

## Consistency Audit

- The formula grammar status table now says `mvbind(y1, y2) ~ x` is
  implemented shorthand, not planned syntax.
- README, ROADMAP, design docs, vignettes, NEWS, roxygen-generated Rd files,
  and rendered pkgdown pages all use the same wording: `mvbind()` is only for
  identical bivariate location predictors.
- Current docs still recommend explicit `mu1` and `mu2` formulas when the two
  responses need different fixed effects, which matches the project design.
- Generated pkgdown pages were rebuilt and searched directly, so the public
  preview should not show stale `mvbind()` status.

## What Did Not Go Smoothly

- The shorthand had to be kept narrower than general multivariate syntax. That
  is the right package boundary, but it means the validation errors matter.
- The stale wording was spread across README, roadmap, design docs, vignettes,
  and generated site pages. This reinforced that user-facing status changes
  need a full Rose pass.
- `air` is not installed in this environment, so formatting still relies on
  existing style and `git diff --check` until that tool is available.

## Team Learning

- Shorthand should be introduced only when it improves memory and typing
  without weakening the scientific grammar. `mvbind()` passes that test only
  for identical location predictors.
- Parser tests should check the pre-expansion object, while model tests should
  check the post-expansion likelihood equivalence.
- Pkgdown freshness needs direct generated-page searches after every public
  syntax-status change.

## Known Limitations

- `mvbind()` shorthand is implemented only for two Gaussian responses.
- Mixed composed families remain planned.
- Bivariate random effects remain planned, so this shorthand currently covers
  fixed-effect location formulas only.

## Next Actions

- Keep bivariate examples explicit by default when predictors differ across
  responses.
- Revisit `mvbind()` only after bivariate random effects and mixed composed
  families have their own equations, implementation, and simulation tests.
- Add `air` or document an alternative formatter in the development setup if
  the project wants formatting checks to be reproducible locally and in CI.
