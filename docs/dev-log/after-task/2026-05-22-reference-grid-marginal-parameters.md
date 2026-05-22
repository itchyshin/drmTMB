# After Task: Reference Grid And Marginal Examples

## Goal

Continue the comprehensive function/reference audit by improving the
`prediction_grid()` and `marginal_parameters()` reference pages.

## Implemented

- Added direct guidance on when to use `margin = "mean_reference"` versus
  `margin = "empirical"` in `prediction_grid()`.
- Replaced the tiny `prediction_grid()` example with a stable location-scale
  fixture whose downstream `predict_parameters(..., conf.int = TRUE)` call
  produces finite Wald rows.
- Added an empirical-grid example that feeds directly into
  `marginal_parameters()`.
- Reworded `marginal_parameters()` as the average-over-rows helper rather than
  a future plotting or emmeans-style placeholder.
- Replaced the `marginal_parameters()` example with the same stable fixture and
  empirical-grid averaging by habitat.

## Mathematical Contract

No prediction, averaging, or interval calculation changed. `prediction_grid()`
still builds `newdata`; `predict_parameters()` still performs row-level
prediction and optional fixed-effect Wald intervals; `marginal_parameters()`
still averages already-predicted parameter values and reports point-only
interval provenance.

## Files Changed

- `R/prediction-grid.R`
- `R/marginal-parameters.R`
- `man/prediction_grid.Rd`
- `man/marginal_parameters.Rd`
- `docs/dev-log/audits/2026-05-21-function-reference-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-22-reference-grid-marginal-parameters.md`

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e 'devtools::load_all(quiet = TRUE); set.seed(20260523); n <- 48; x <- seq(-1.5, 1.5, length.out = n); habitat <- factor(rep(c("reef", "sand"), length.out = n)); eta <- 0.4 + 0.7 * x + ifelse(habitat == "reef", 0.25, -0.15); sigma <- exp(-0.35 + 0.15 * x); dat <- data.frame(y = eta + rnorm(n, sd = sigma), x = x, habitat = habitat); fit <- drmTMB(bf(y ~ x + habitat, sigma ~ x), data = dat); grid <- prediction_grid(fit, focal = "x", at = list(x = c(-1, 0, 1)), condition = list(habitat = "reef")); print(predict_parameters(fit, newdata = grid, dpar = c("mu", "sigma"), conf.int = TRUE)); empirical_grid <- prediction_grid(fit, focal = "habitat", at = list(habitat = levels(dat$habitat)), margin = "empirical"); print(marginal_parameters(fit, newdata = empirical_grid, dpar = "mu", by = "habitat")); print(marginal_parameters(fit, newdata = empirical_grid, dpar = c("mu", "sigma"), by = "habitat"))'
air format R/prediction-grid.R R/marginal-parameters.R
Rscript -e "devtools::test(filter = 'prediction-grid|marginal-parameters|predict-parameters|plot-parameter-surface', reporter = 'summary')"
Rscript -e "pkgdown::build_reference()"
rg -n 'mean_reference|empirical|averages rather than row-level predictions|finite|wald|marginal_parameters\\(|prediction_grid\\(' R/prediction-grid.R R/marginal-parameters.R man/prediction_grid.Rd man/marginal_parameters.Rd pkgdown-site/reference/prediction_grid.html pkgdown-site/reference/marginal_parameters.html -S
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "prediction_grid marginal_parameters reference OR prediction marginal examples" --limit 20
```

## Tests Of The Tests

The revised examples were executed before focused tests. The old examples
created nearly zero `sigma` values from a six-row fit; the replacement produces
finite Wald prediction intervals and non-degenerate marginal summaries.

## Consistency Audit

The pages now teach the same table sequence used elsewhere in the package:
build an explicit grid with `prediction_grid()`, predict row-level
distributional parameters with `predict_parameters()`, and average those rows
with `marginal_parameters()` when the estimand is a group mean.

## GitHub Issue Maintenance

Issue search found #58, the broad visualization-layer issue. This reference
slice contributes to that public-surface cleanup, but it does not close #58.

## What Did Not Go Smoothly

Executing the old examples exposed the same problem as the previous reference
slice: tiny fitted examples can be technically runnable while producing
scientifically unhelpful outputs.

## Known Limitations

This slice does not add uncertainty propagation to marginal summaries, weighted
averages, contrasts, or new plotting functions.

## Next Actions

1. Continue rendered reference inspection with grouped model-fit extractor
   prose and examples.
2. Keep executing reference examples before treating them as teaching fixtures.
