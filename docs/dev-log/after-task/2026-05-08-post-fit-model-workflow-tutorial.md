# After Task: Post-Fit Model Workflow Tutorial

## Goal

Add a user-facing tutorial that shows how to move from a fitted
location-scale model to diagnostics, coefficient interpretation, prediction,
residual checks, and simulation.

## Implemented

- Added `vignettes/model-workflow.Rmd`.
- Added the tutorial to the pkgdown Tutorials menu and article index.
- Used a compact growth example with a Gaussian location-scale model.
- Paired symbolic equations with matching `drmTMB()` syntax and short
  interpretation.
- Connected the same workflow to `meta_known_V(V = V)` and bivariate Pearson
  residuals with `sigma1`, `sigma2`, and `rho12`.

## Mathematical Contract

The tutorial documents the model:

```text
growth_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = beta_0 + beta_1 temperature_i + beta_2 habitat_i
log(sigma_i) = gamma_0 + gamma_1 temperature_i
```

The matching R syntax is:

```r
fit <- drmTMB(
  bf(growth ~ temperature + habitat, sigma ~ temperature),
  family = gaussian(),
  data = fish
)
```

The `sigma` formula is described as a residual standard deviation model on the
log scale. The tutorial does not introduce new likelihood behaviour.

## Files Changed

- `_pkgdown.yml`
- `vignettes/model-workflow.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-post-fit-model-workflow-tutorial.md`

## Checks Run

- `Rscript -e "rmarkdown::render('vignettes/model-workflow.Rmd', quiet = TRUE)"`
- `Rscript -e "pkgdown::build_article('model-workflow')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `air format .`
- `rg -n "Checking and using fitted models|post-fit loop|meta_known_V\\(V = V\\)|simulate\\(fit|residuals\\(fit|check_drm\\(fit\\)" pkgdown-site/articles/model-workflow.html pkgdown-site/articles/index.html pkgdown-site/index.html`
- `rg -n "meta_gaussian|tau ~|rho ~|biv_gaussian|biological data|O.Dea-style|O'Dea-style" vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html docs README.md vignettes _pkgdown.yml`

Results:

- `devtools::test()` passed: 572 tests, 0 failures.
- `pkgdown::check_pkgdown()` found no problems.
- `pkgdown::build_site()` completed and built `articles/model-workflow.html`.
- `devtools::check()` completed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check` was clean.
- Generated-site search confirmed the tutorial title, navigation entry,
  `check_drm(fit)`, `residuals(fit, type = "pearson")`, `simulate(fit)`, and
  `meta_known_V(V = V)` note.

## Tests Of The Tests

This task added no unit tests because it was a tutorial-only change. The
important checks were:

- full vignette execution during R CMD check;
- full pkgdown site build rather than only source-file inspection;
- generated-site search to confirm the article and navbar entries were
  visible after rendering.

## Consistency Audit

- The R syntax uses only currently supported behaviour.
- The equations, syntax, and interpretation all use `sigma` as the residual
  standard deviation.
- The bivariate note uses the canonical residual correlation name `rho12`.
- The meta-analysis note uses `meta_known_V(V = V)` and does not introduce
  `meta_gaussian()` or `tau ~`.
- No roadmap, NEWS, or likelihood design update was needed because this task
  added tutorial coverage rather than new model behaviour.

## What Did Not Go Smoothly

- Direct `rmarkdown::render()` and `pkgdown::build_article()` failed in a
  plain session because `drmTMB` was not installed there.
- The full pkgdown site build and R CMD check both install the package before
  building vignettes, and both passed.
- `air format .` is still unavailable on this machine.

## Team Learning

- Pat's view: post-fit documentation should show the ordinary loop a user
  repeats after every fit, not only isolated extractor functions.
- Rose's view: generated HTML should be searched after docs changes, because
  source files and pkgdown navigation can drift apart.
- Noether's view: equations and syntax should appear together for model
  tutorials so implementation targets remain checkable.

## Known Limitations

- The growth example is synthetic and deliberately small.
- The tutorial does not yet cover profile-likelihood intervals, spatial or
  phylogenetic post-fit summaries, or conditional prediction for new
  random-effect levels.
- Richer ecology/evolution examples should be added after the relevant fitted
  features stabilize.

## Next Actions

- Add profile-likelihood interval documentation when that feature is designed.
- Add structured-effect post-fit examples after phylogenetic slopes, scale
  effects, and spatial SPDE paths are implemented.
- Consider a later tutorial that compares simulation diagnostics with
  comparator packages where equivalent models exist.
