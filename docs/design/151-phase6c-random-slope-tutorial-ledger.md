# Phase 6c Random-Slope Tutorial Ledger

This ledger closes the reader-facing part of issue #444. It does not add a new
model surface. It records where an applied ecology, evolution, or
environmental-science reader should learn the current random-slope syntax, how
to interpret fitted output, and where planned neighbours remain outside the
course path.

## Reader Path

The course path is:

1. `vignettes/model-map.Rmd` to separate fitted, first-slice, planned, and
   unsupported routes before choosing syntax.
2. `vignettes/location-scale.Rmd` for the worked Gaussian reaction-norm path:
   symbolic equations, R syntax, `summary()`, `check_drm()`,
   `profile_targets()`, `corpairs()`, and response-scale interpretation.
3. `vignettes/which-scale.Rmd` to distinguish residual `sigma`,
   random-effect SDs, `sd(group)`, residual-scale random effects, and residual
   `rho12`.
4. `vignettes/bivariate-coscale.Rmd` for residual `rho12` and ordinary
   group-level covariance rows reported by `corpairs()`.
5. The focused structural-dependence articles for `phylo()`, `spatial()`,
   `animal()`, and `relmat()` examples, with `vignettes/implementation-map.Rmd`
   as the finer status ledger.

## Finished Versus Planned

| Capability | Reader-facing status | Remaining boundary |
| --- | --- | --- |
| Ordinary Gaussian `mu` random intercepts and slopes | The location-scale tutorial pairs the equations and syntax for `(0 + x | id)` and `(1 + x | id)` with output interpretation, `check_drm()`, `profile_targets()`, and `corpairs(fit, class = "mean-slope")`. | Larger q > 2 blocks are advanced, sample-size hungry fits; their SDs are direct targets, but q > 2 correlations remain derived rows without direct profile intervals. |
| Gaussian residual-scale random effects | The location-scale and scale articles now name residual-scale random intercepts and independent `sigma ~ z + (0 + w | id)` slopes on `log(sigma)`. | Correlated or labelled residual-scale slope covariance remains planned. |
| Random-effect scale formulas | The scale article and model map teach `sd(group) ~ x_group` as a model for among-group `mu` SD, separate from residual `sigma`. | Coefficient-specific random-slope SD formulas such as `sd(group, coef = "x") ~ z` remain reserved. |
| Ordinary bivariate slope rows | The bivariate coscale article now includes the first location slope-slope covariance slice, the first same-response q2 `mu`/`sigma` slope slice, and the first q2 `sigma1`/`sigma2` scale-slope slice with purpose, equations, syntax, output interpretation, diagnostics, and direct-target guidance. The matching q4 and q6 location blocks now have smoke artifact lanes, and q8 now has a source-tested all-endpoint route with diagnostic smoke/recovery artifacts. | A fuller simulated plasticity-syndrome worked example remains future work; formal recovery, coverage, and power at broad grid scale plus q8 coverage/power evidence remain planned. |
| Selected non-Gaussian ordinary `mu` slopes | The model map and implementation map point readers to selected ordinary non-Gaussian `mu` random intercept and independent numeric slope first slices. | Correlated non-Gaussian slopes, labelled covariance, structured non-Gaussian slopes, and most non-Gaussian `sigma`, shape, inflation, hurdle, or ordinal random effects remain planned or blocked. |
| Structured Gaussian one-slope routes | The model map now states that `phylo()`, coordinate `spatial()`, `animal()`, and `relmat()` each have a first Gaussian one-slope `mu` route, with focused structural articles carrying examples and diagnostics. | Multiple structured slopes, structured residual-scale slopes, slope correlations, structured `rho12`, sparse large-pedigree speed claims, mesh/SPDE slopes, and non-Gaussian structured slopes remain planned. |
| Residual coscale and latent correlation rows | The bivariate coscale tutorial and model map keep residual `rho12`, singular `corpair()` formula markers, and plural `corpairs()` extractor rows separate. | Random effects in `rho12`, predictor-dependent q4 latent correlations, and residual-scale or slope-specific `corpair()` regressions remain planned. |

## Reference Discoverability

The pkgdown reference index already exposes the surfaces needed for this
reader path: `random_effect_scale_formulas` for `sd(group)`, `rho12`,
`corpair`, `corpairs`, `phylo`, `spatial`, `animal`, `relmat`, `check_drm`, and
`profile_targets`. The articles menu also exposes `model-map`,
`location-scale`, `which-scale`, `bivariate-coscale`, the focused structural
articles, and `implementation-map`.

Issue #444 can close when the source scans and `pkgdown::check_pkgdown()` show
those reference and article routes are still present, and the after-task report
records that unsupported cells were left as explicit planned neighbours rather
than tutorial syntax.
