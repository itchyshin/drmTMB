# After Task: Testing Likelihoods Developer Guide

## Goal

Replace the placeholder `testing-likelihoods` article with a practical
developer guide for validating `drmTMB` likelihoods.

## Implemented

- Expanded `vignettes/testing-likelihoods.Rmd` from a two-sentence placeholder
  into a full developer article.
- Added paired symbolic equations and `drmTMB` syntax for:
  - fixed-effect Gaussian location-scale models;
  - Gaussian random-intercept comparator models;
  - dense known-`V` Gaussian meta-analysis;
  - Student-t location-scale-shape models;
  - bivariate Gaussian `rho12` location-coscale models.
- Explained comparator checks, simulation recovery, independent likelihood
  checks, boundary/rejection tests, and fast versus long-test separation.
- Clarified that `glmmTMB::equalto()` is a planned comparator rather than a
  current package test.
- Marked skew-normal examples in the GAMLSS naming note as planned-only.
- Updated the collaboration/team design note to match the current standing
  review roles in `AGENTS.md`.

## Mathematical Contract

The article teaches the same contract used for implementation tasks:

```text
symbolic model = R syntax = TMB likelihood = tests
```

For example, the dense known-`V` meta-analysis overlap is:

```text
y ~ Normal(X beta, V + sigma^2 I)
```

with:

```r
drm_formula(yi ~ x + meta_known_V(V = V))
```

and the comparable `metafor` model:

```r
metafor::rma.mv(
  yi = yi,
  V = V,
  mods = ~ x,
  random = ~ 1 | obs,
  data = dat,
  method = "ML"
)
```

## Files Changed

- `vignettes/testing-likelihoods.Rmd`
- `docs/design/05-testing-strategy.md`
- `docs/design/07-collaboration-and-site.md`
- `docs/design/08-meta-analysis.md`
- `docs/design/11-reference-programme.md`
- `docs/design/14-gamlss-parameter-names.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-testing-likelihoods-developer-guide.md`

## Checks Run

- `Rscript -e "rmarkdown::render('vignettes/testing-likelihoods.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n "This developer article will|will document simulation recovery|current planning reference|skew_normal\\(\\)|glmmTMB::equalto\\(\\)|Current Agent Team|Testing likelihoods" vignettes docs/design README.md ROADMAP.md NEWS.md`
- `rg -n 'location means|complete-row `2n`|per-study list|This developer article will|will document simulation recovery|glmmTMB::equalto\\(\\)|skew_normal\\(\\)' vignettes/testing-likelihoods.Rmd docs/design/05-testing-strategy.md docs/design/08-meta-analysis.md docs/design/11-reference-programme.md docs/design/14-gamlss-parameter-names.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-08-testing-likelihoods-developer-guide.md`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

## Tests Of The Tests

No package code changed. The validation was therefore:

- direct rendering of the new vignette;
- pkgdown index and site rebuild checks;
- full package tests to ensure no documentation examples or package state were
  disturbed;
- full `R CMD check` with vignette rebuilding.

The article itself now documents the test patterns contributors should use for
future code changes: independent likelihood checks, comparator checks,
simulation recovery, rejection tests, and bivariate known-covariance separation.

## Consistency Audit

- The public pkgdown menu already included `testing-likelihoods`; the article now
  matches that visible navigation.
- `glmmTMB::equalto()` references now distinguish planned comparator work from
  implemented `metafor` comparator tests.
- Skew-normal examples in the GAMLSS parameter note are labelled as planned-only.
- The collaboration/team design note now matches the richer standing-role table
  in `AGENTS.md`.
- Rose's audit caught two P2 wording issues, now fixed: the article defines
  location, scale, shape, and coscale at first use, and bivariate known-`V`
  wording now states that the implemented input is a complete-row `2n` by `2n`
  row-paired covariance matrix rather than a per-study list of `S_i` blocks.
- No `NEWS.md` update was needed because this was a developer-documentation
  improvement, not a user-facing API or fitted-model behaviour change.

## What Did Not Go Smoothly

The first draft of the rejection-test examples used valid but awkward
`expect_snapshot()` argument ordering. I rewrote them into the normal block form
before rendering the vignette. A later audit also found that the article used
`location-scale-shape` and `location-coscale` before defining those terms.
Finally, one post-audit `rg` scan failed because shell backticks in the pattern
were not quoted safely; the successful scan used single quotes and is recorded
above.

## Team Learning

Pat's review caught the important gap: a pkgdown article title creates an
expectation. If a developer page is visible in navigation, it needs to contain a
usable workflow, not a promise to write one later.

## Known Limitations

- `vignettes/adding-families.Rmd` is still a placeholder-style developer
  article and should be expanded next.
- The new likelihood-testing article is documentation only; it does not add new
  long simulation infrastructure or scheduled CI.
- `glmmTMB::equalto()` remains planned as a comparator and is not yet in the
  routine test suite.

## Next Actions

- Expand `vignettes/adding-families.Rmd` into the same equation-syntax-tests-docs
  style.
- Add the bivariate known-`V` comparator or document the closest available
  `metafor` parameterization.
- Add optional long-test scripts for larger simulation grids once the CRAN-safe
  test suite remains stable.
