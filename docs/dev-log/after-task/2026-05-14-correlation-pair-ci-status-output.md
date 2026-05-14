# After-Task Report: Correlation-Pair CI Status Output

Date: 2026-05-14

## Task

Clarify random-effect correlation output so users can see whether a reported
correlation has a 95% profile-likelihood interval, needs row-specific input, or
is a derived target whose interval is not implemented yet.

## Result

`corpairs()` now accepts `conf.int = TRUE`. Profile-ready direct correlation
rows can receive profile-likelihood bounds. Predictor-dependent residual
`rho12` summaries report `conf.status = "newdata_required"` because their
intervals depend on the row to profile. Derived q=4 ordinary or phylogenetic
correlation rows report `conf.status = "derived_interval_unavailable"` so
point estimates are not mistaken for complete inference.

The phylogenetic-spatial article now shows a model ladder from residual
correlation to phylogenetic mean-mean correlation, direct-SD phylogenetic SD
surfaces, q=4 phylogenetic location-scale blocks, and planned
predictor-dependent latent `corpair()` formulas. It also adds math separating
residual `rho12` from latent phylogenetic correlations.

## Checks

- `air format R/methods.R tests/testthat/test-corpairs.R tests/testthat/test-phylo-gaussian.R vignettes/phylogenetic-spatial.Rmd`
- `Rscript -e 'devtools::document()'`
- `Rscript -e 'devtools::test(filter = "corpairs|phylo-gaussian|summary|profile-targets", reporter = "summary")'`
- `Rscript -e 'devtools::test(reporter = "summary")'`
- `Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE)'`
- `git diff --check`

All passed.

## Role Notes

- Ada: Keep the route anchored in user-visible output, not only internal target
  inventories.
- Boole: `corpairs(conf.int = TRUE)` should stay extractor-like; avoid making
  users learn a separate interval helper for correlation rows.
- Gauss: q=4 derived correlation intervals remain a numerical design task, not
  a Wald shortcut.
- Noether: The article now matches the likelihood layers: residual
  observation covariance, latent phylogenetic covariance, and direct-SD
  covariance surfaces.
- Fisher: Profile likelihood is the default goal for covariance parameters;
  conditional random-effect mode intervals are separate and lower priority.
- Pat: Output should say what is missing. A blank CI column without status is
  not good enough for applied users.
- Grace: Focused tests and article rendering are green; full suite and Actions
  should run after the next implementation slice.
- Rose: Watch for stale prose that says q=4 intervals are unavailable without
  mentioning the new `conf.status` column.
