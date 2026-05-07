# After Task: Bivariate Gaussian rho12

Date: 2026-05-06

## Task

Implement and harden the first bivariate Gaussian location-scale-coscale path:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + x2,
    mu2 = y2 ~ x1,
    sigma1 = ~ z1,
    sigma2 = ~ z2,
    rho12 = ~ w
  ),
  family = biv_gaussian(),
  data = dat
)
```

## Created Or Changed

- Added exported `biv_gaussian()` family object in `R/family.R`.
- Extended `drmTMB()` dispatch for `family = biv_gaussian()`.
- Added fixed-effect bivariate model construction in `R/drmTMB.R`.
- Extended `src/drmTMB.cpp` with the bivariate Gaussian likelihood.
- Added response-scale `rho12` prediction through a bounded tanh transform.
- Added bivariate simulation, prediction, sigma, residual, summary, and
  covariance support in `R/methods.R`.
- Added `tests/testthat/test-biv-gaussian.R`.
- Updated README, NEWS, ROADMAP, vignettes, pkgdown configuration, design docs,
  and known limitations.
- Updated the pkgdown workflow to configure GitHub Pages and cancel stale
  pkgdown builds.
- Added a gllvmTMB source map for later phylogenetic A-inverse and SPDE work.

## Checks Performed

- Targeted bivariate tests:
  `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- Full test suite:
  `Rscript -e "devtools::test()"`
- Documentation:
  `Rscript -e "devtools::document()"`
- pkgdown:
  `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- Package check:
  `Rscript -e "devtools::check(error_on = 'never')"`
- Stale-text scans for planned bivariate status and forbidden meta-analysis
  syntax.

## Outcomes

- Targeted bivariate tests: 40 passed, 0 failed.
- Full test suite: 113 passed, 0 failed.
- pkgdown check: no problems found.
- pkgdown site: built successfully.
- R CMD check: 0 errors, 0 warnings, 0 notes.
- `air format .` was attempted but `air` is not installed locally.

## Consistency Review

- README now says fixed-effect bivariate Gaussian `rho12 ~ predictors` is
  implemented.
- ROADMAP Phase 3 status now says fixed-effect bivariate Gaussian is
  implemented.
- `docs/design/02-family-registry.md` lists `biv_gaussian()` as implemented.
- `docs/design/03-likelihoods.md` documents the implemented bivariate
  likelihood and bounded `rho12` transform.
- `vignettes/bivariate-coscale.Rmd` now contains runnable fixed-effect syntax.
- `docs/dev-log/known-limitations.md` no longer says bivariate models are
  generally unimplemented.
- Remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails.

## Remaining Limitations

- Bivariate random effects are not implemented.
- `mvbind(y1, y2) ~ ...` shorthand is not implemented.
- Bivariate known sampling covariance and bivariate meta-analysis are not
  implemented.
- Phylogenetic A-inverse and spatial SPDE support are design-stage only.
- Non-Gaussian families remain roadmap items.

## Next Best Task

The next modelling task should be random intercepts in univariate Gaussian
location models, because this unlocks mixed models, double-hierarchical models,
and the later A-inverse/SPDE routes without overloading the bivariate likelihood
too early.
