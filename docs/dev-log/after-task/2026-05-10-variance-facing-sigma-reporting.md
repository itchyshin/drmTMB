# After Task: Variance-Facing Sigma Reporting

## Goal

Make the `sigma` to `sigma^2` conversion explicit for users who need
variance-facing summaries, while preserving `sigma` as the public model
grammar and extractor.

## Implemented

- Added SD-ratio and variance-ratio output to the Gaussian location-scale
  interpretation example.
- Added fitted residual variance to the Gaussian location-scale reporting
  table.
- Expanded the scale-choice meta-analysis example to report extra
  heterogeneity SD, extra heterogeneity variance, and total observation
  variance after adding known sampling variance.
- Added a "Reporting variation" table to the family guide so readers do not
  generalize Gaussian `sigma^2` to every family.
- Added a workflow warning that residual variance is obtained from fitted
  response-scale `sigma`, not by squaring a log-SD coefficient.

## Mathematical Contract

The public formula and extractor vocabulary remains `sigma`. In Gaussian
location-scale models, `sigma` is residual SD and residual variance is
`sigma^2`. A `sigma` coefficient is on the log-SD scale, so a coefficient
implies an SD ratio of `exp(coef)` and a variance ratio of `exp(2 * coef)`.
For Gaussian meta-analysis with `meta_known_V(V = V)`, fitted `sigma^2` is
extra heterogeneity variance; total observation variance is `vi + sigma^2`.
For non-Gaussian families, variation summaries follow the family-specific
mean-variance relationship rather than the Gaussian shortcut.

## Files Changed

- `vignettes/location-scale.Rmd`
- `vignettes/which-scale.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/model-workflow.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-variance-facing-sigma-reporting.md`

## Checks Run

- `air format vignettes/location-scale.Rmd vignettes/which-scale.Rmd vignettes/distribution-families.Rmd vignettes/model-workflow.Rmd`
- `Rscript -e "pkgdown::build_articles()"` failed first because direct article
  rendering could not `library(drmTMB)` from the active R library.
- `Rscript -e "devtools::install(upgrade = 'never', quick = TRUE)"`
- `Rscript -e "pkgdown::build_articles()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `rg -n "residual_variance_ratio|fitted_residual_variance|extra_heterogeneity_variance|total_observation_variance|Reporting variation|do not square the|rho12 \\* sigma1" vignettes pkgdown-site/articles --glob '!pkgdown-site/search.json'`
- `rg -n "O'Dea/Nakagawa|O'Dea-style|O\\.Dea/Nakagawa|O\\.Dea-style" README.md ROADMAP.md NEWS.md docs/design vignettes R tests _pkgdown.yml pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n "tau ~|meta_gaussian\\(|rho ~" README.md ROADMAP.md NEWS.md docs/design vignettes R tests _pkgdown.yml pkgdown-site --glob '!pkgdown-site/search.json'`
- `git diff --check`

## Tests Of The Tests

This was a documentation-only change, so no new unit test was added. The
executable vignette chunks were tested by rendering articles after installing
the current checkout locally. The full test suite still passed with 1400
tests, 0 failures, 0 warnings, and 0 skips.

## Consistency Audit

The source vignettes and rendered pkgdown articles now contain the new
variance-facing terms. The active source docs do not use the avoided shorthand
for the individual-difference paper. The `tau ~`, `meta_gaussian()`, and
`rho ~` scan found only intended guardrail prose and the explicit
meta-analysis reporting conversion.

## What Did Not Go Smoothly

Direct `pkgdown::build_articles()` failed before the package was installed in
the active R library. The fix was to install the current checkout with
`devtools::install(upgrade = 'never', quick = TRUE)` before rerendering.

## Team Learning

Pat's user-tester review was right: the older tutorial said "twice as
variable" where a user could reasonably ask whether that meant SD or variance.
Rose and Fisher were also right that a new residual-variance helper would be
premature because `sigma()` is family-specific. The safer improvement is to
teach the reporting conversion clearly and keep the public API stable.

## Known Limitations

There is still no exported `residual_variance()` helper. That remains a design
choice, not an accidental omission. If a helper is added later, it should be
explicitly scoped by family and tested against Gaussian, meta-analysis, and
bivariate Gaussian cases.

## Next Actions

- Add uncertainty guidance for bivariate residual covariance reporting when
  the coscale inference tools are designed.
- Keep the full individual-difference roadmap focused on variance-facing
  reporting without changing the public `sigma` formula grammar.
