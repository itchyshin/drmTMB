# After Task: Reference Correlation And Prediction Examples

## Goal

Continue the comprehensive function/reference audit by improving the
`corpairs()` and `predict_parameters()` reference pages without changing their
behavior.

## Implemented

- Clarified that `rho12()` is the extractor for the residual-correlation curve,
  while `corpairs()` is the table for fitted residual, group-level,
  phylogenetic, coordinate-spatial, animal-model, and `relmat()` correlation
  rows.
- Added explicit `corpairs()` guidance that profile intervals are opt-in,
  should be filtered before long runs, and are not a bootstrap route.
- Clarified that `predict_parameters()` is for row-level values on a covariate
  grid, while `marginal_parameters()` is for averages over rows.
- Added link-scale versus response-scale Wald interval wording for
  `predict_parameters()`.
- Replaced the tiny `predict_parameters()` example with a reproducible toy fit
  that produces finite Wald intervals.

## Mathematical Contract

No model calculation changed. `corpairs()` still reports fitted correlation
rows and interval provenance already available from the model/profile-target
contract. `predict_parameters()` still delegates row-level predictions to
`predict.drmTMB()` and uses fixed-effect covariance for available Wald
intervals.

## Files Changed

- `R/methods.R`
- `R/predict-parameters.R`
- `man/corpairs.Rd`
- `man/predict_parameters.Rd`
- `docs/dev-log/audits/2026-05-21-function-reference-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-22-reference-corpairs-predict-parameters.md`

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e 'devtools::load_all(quiet = TRUE); set.seed(1); n <- 40; x <- rnorm(n); z1 <- rnorm(n); z2 <- rnorm(n); mu1 <- 0.2 + 0.5 * x; mu2 <- -0.1 + 0.4 * x; sigma1 <- exp(-0.2 + 0.15 * z1); sigma2 <- exp(0.1 - 0.1 * z2); rho <- 0.35; e1 <- rnorm(n); e2 <- rho * e1 + sqrt(1 - rho^2) * rnorm(n); dat <- data.frame(y1 = mu1 + sigma1 * e1, y2 = mu2 + sigma2 * e2, x = x, z1 = z1, z2 = z2); fit <- drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ z1, sigma2 = ~ z2, rho12 = ~ 1), family = c(gaussian(), gaussian()), data = dat); pairs <- corpairs(fit); print(pairs); print(corpairs(fit, level = "residual")); set.seed(20260522); n <- 36; x <- seq(-1.5, 1.5, length.out = n); sigma <- exp(-0.35 + 0.2 * x); dat <- data.frame(y = 0.4 + 0.7 * x + rnorm(n, sd = sigma), x = x); fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat); grid <- data.frame(x = c(-1, 0, 1)); pred <- predict_parameters(fit, newdata = grid, dpar = c("mu", "sigma"), conf.int = TRUE); print(pred); print(predict_parameters(fit, newdata = grid, dpar = "sigma", type = "link", include_newdata = FALSE, conf.int = TRUE))'
air format R/methods.R R/predict-parameters.R
Rscript -e "devtools::test(filter = 'corpairs|predict-parameters|plot-parameter-surface|plot-corpairs', reporter = 'summary')"
Rscript -e "pkgdown::build_reference()"
rg -n 'Bootstrap intervals are not a `corpairs\\(\\)` route|Use `rho12\\(\\)`|Use `marginal_parameters\\(\\)`|Profile intervals are opt-in|delta method|wald' R/methods.R R/predict-parameters.R man/corpairs.Rd man/predict_parameters.Rd pkgdown-site/reference/corpairs.html pkgdown-site/reference/predict_parameters.html -S
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "corpairs predict_parameters reference OR correlation prediction examples" --limit 20
```

## Tests Of The Tests

The revised examples were executed through `devtools::load_all()` before the
focused tests. The original tiny `predict_parameters()` example produced
`wald_unavailable`; the replacement now demonstrates finite Wald rows on both
response and link scales.

## Consistency Audit

The reference pages now match the interval map: fast Wald rows belong to
`predict_parameters()` when fixed-effect covariance is available on a supplied
grid; `corpairs()` remains a correlation-row table with profile-only interval
support for ready targets and explicit unavailable statuses for derived rows.

## GitHub Issue Maintenance

Issue search found #58, the broad visualization-layer issue. This reference
slice contributes to that public-surface cleanup, but it does not close #58.

## What Did Not Go Smoothly

The first pass kept the existing six-row prediction example. Running it showed
that the toy fit could not provide finite Wald intervals, so it was not a good
public example for a page meant to teach fast intervals.

## Known Limitations

This slice does not add bootstrap support to `corpairs()` or new interval
methods to `predict_parameters()`. It only clarifies the current extractor
surface.

## Next Actions

1. Continue rendered reference inspection with `prediction_grid()`,
   `marginal_parameters()`, and grouped model-fit extractors.
2. Keep checking examples by executing them, not just by reading generated Rd.
