# After Task: Implemented Source Map

## Goal

Create a developer-facing map from implemented model paths to their R builders,
TMB branches, tests, and documentation.

## Implemented

- Added `vignettes/source-map.Rmd`.
- Added the source-map article to the pkgdown Developer Notes menu and article
  index.
- Documented the current `model_type` routing:
  - `1`: univariate Gaussian location-scale;
  - `2`: bivariate Gaussian location-scale-coscale;
  - `3`: univariate Student-t location-scale-shape;
  - `99`: internal phylogenetic prior helper used by tests.
- Mapped implemented paths for Gaussian, Student-t, bivariate Gaussian,
  `meta_known_V(V = V)`, `meta_vcov_bivariate()`, random-effect scale models,
  and phylogenetic Gaussian location effects.
- Fixed stale location-scale wording so `sd(id) ~ x_group` is described as
  implemented, not future work.

## Mathematical Contract

The article does not introduce a new likelihood. Its contract is a consistency
map:

```text
implemented path = user syntax + R builder + TMB model_type + tests + docs
```

For example, bivariate Gaussian `rho12` is mapped to:

```text
rho12 = tanh(eta_rho12)
model_type = 2
R builder = drm_build_biv_gaussian_spec()
TMB branch = src/drmTMB.cpp model_type == 2
tests = tests/testthat/test-biv-gaussian.R
```

## Files Changed

- `_pkgdown.yml`
- `vignettes/source-map.Rmd`
- `vignettes/location-scale.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-implemented-source-map.md`

## Checks Run

- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n 'Later double-hierarchical|This developer article will|current planning reference|model_type = 99|meta_gaussian|tau ~|rho ~|c\\(gaussian\\(\\), poisson\\(\\)\\)|skew_normal\\(\\)' vignettes/source-map.Rmd vignettes/location-scale.Rmd _pkgdown.yml docs/design/08-meta-analysis.md`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct source-map render: passed;
- direct source-map and location-scale render after stale-wording fix: passed;
- `git diff --check`: clean;
- stale/unsupported-syntax scan: no old placeholder text and no stale "Later
  double-hierarchical" wording remained. Remaining hits were intentional:
  `model_type = 99` is documented as internal, `c(gaussian(), poisson())` is in
  an unsupported-feature list, and `meta_gaussian()` / `tau ~` are in the
  meta-analysis guardrail design note;
- `pkgdown::check_pkgdown()`: no problems found;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

No fitted-model code changed. This task checked that the new article points to
the existing test files for each implemented path. The source-only Jason review
served as an independent map of files, branches, and gaps before the after-task
audit.

## Consistency Audit

- The source map names `model_type = 99` as an internal test helper, not a public
  fitted model.
- The source map does not teach mixed composed families, bivariate Student-t,
  bivariate skew-normal, spatial random fields, profile-likelihood confidence
  intervals, or bivariate random effects as implemented syntax.
- The location-scale vignette now agrees with the implemented `sd(id) ~
  x_group` path.
- `_pkgdown.yml` exposes the new article in both the Developer Notes menu and
  the article index.

## What Did Not Go Smoothly

The first source-map draft missed one stale sentence in `location-scale.Rmd`.
Jason caught it in a source-only pass before commit. This was a good example of
why the staggered review pattern is useful.

## Team Learning

The project now has a contributor-facing source map as well as skills. Future
agents should consult it before editing a likelihood, family, or extractor.

## Known Limitations

- The map is manually maintained and must be updated when a model path changes.
- Gaussian known-covariance meta-analysis with `sd(group) ~ predictors` still
  needs a targeted validation test before examples recommend it as routine
  syntax.

## Next Actions

- Add a targeted test for `meta_known_V(V = V)` combined with
  `sd(group) ~ predictors`, or explicitly reject that combination if the
  interpretation is not yet stable.
- Consider adding the same model-type table to `docs/design/03-likelihoods.md`
  if the source map proves useful.
