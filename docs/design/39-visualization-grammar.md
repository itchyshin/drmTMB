# Visualization Grammar and Marginal-Effects Research

Slice 100 records what `drmTMB` should learn from the R visualization and
model-interpretation ecosystem before adding a plotting layer. The reader is an
applied ecology, evolution, or environmental-science user who wants to explain a
fitted distributional model without rebuilding prediction grids by hand.

This is a design note, not a blanket implementation claim. `drmTMB` is not
becoming a Bayesian package, and the plotting layer should stay optional and
small. Slice 104 adds `ggplot2` to `Suggests` for one helper, but does not add
`tidybayes`, `ggdist`, `emmeans`, `ggeffects`, `marginaleffects`,
`performance`, `see`, or `DHARMa` as dependencies. The useful lesson is
structural: good model graphics start from clear tabular quantities, explicit
grids, and honest uncertainty labels.

## Sources Read

| Source | Pattern worth learning | `drmTMB` consequence |
| --- | --- | --- |
| [`ggplot2`](https://ggplot2.tidyverse.org/) | A plot is data plus aesthetic mappings plus layers. | Return ordinary data frames first; let users build custom plots with the grammar they already know. |
| [`tidybayes`](https://mjskay.github.io/tidybayes/) | Draws, fitted values, predictions, and intervals become tidy long data before they become graphics. | Future simulation, bootstrap, or profile-draw surfaces should be long tables with parameter, row, draw or replicate, and source columns. |
| [`ggdist`](https://mjskay.github.io/ggdist/) | Interval, slab, dot, and ribbon geoms can display both frequentist and Bayesian uncertainty when the uncertainty object is explicit. | Do not use Bayesian vocabulary for frequentist fits; instead label Wald, profile, bootstrap, or simulation uncertainty and make `ggdist` a possible optional consumer later. |
| [`emmeans`](https://rvlenth.github.io/emmeans/reference/emmeans.html) | Estimated marginal means are predictions over a reference grid, with averaging and contrast choices kept explicit. | Any future EMM support needs a reference-grid contract for each `dpar`, scale, weighting rule, and transformed response before plotting or contrasts are advertised. |
| [`ggeffects`](https://strengejacke.github.io/ggeffects/reference/predict_response.html) | Adjusted predictions are returned as structured data frames on interpretable scales, with focal terms and marginalization rules visible. | A `drmTMB` grid helper should name focal terms, fixed covariate values, and marginalization over nuisance predictors rather than hiding them inside a plot. |
| [`marginaleffects`](https://marginaleffects.com/) | Predictions, comparisons, slopes, marginal means, grids, and plots share a unified interpretation vocabulary. | Phase 17 should separate predictions, contrasts, slopes, and marginal means as different estimands, not as one generic "effect plot." |
| [`performance::check_model()`](https://easystats.github.io/performance/reference/check_model.html) and [`DHARMa`](https://cran-e.com/package/DHARMa) | Diagnostics are visual workflows, but the useful contract is the diagnostic quantity and model class support. | `check_drm()` should remain the first interpretation gate; visual diagnostics can come later only when their residual or simulation contract is tested. |
| [`patchwork`](https://patchwork.data-imaginist.com/) and [`viridis`](https://sjmgarnier.github.io/viridis/) | Publication figures need composable panels and accessible colours. | Figure helpers should return composable `ggplot` objects only if `ggplot2` is optional and available; examples should use colour-blind-friendly palettes where colour carries meaning. |

## Design Principles

### Data First, Plot Second

The first stable contract should be the table, not the figure. Current
`predict_parameters()` already returns one row per prediction, distributional
parameter, component, scale, and grid row. Current `marginal_parameters()`
already reduces that table to unweighted group summaries. Future plotting
helpers should consume those tables instead of calling internals again.

A plotting helper can be convenient later, but the main exported object should
remain usable with base R, `ggplot2`, `patchwork`, Quarto, tables, or a package
the user already knows.

### Name The Estimand

The user should be able to tell whether a row is a prediction, an adjusted
prediction, an estimated marginal mean, a contrast, a slope, or a diagnostic.
Those quantities answer different questions:

| Quantity | Reader question | Future data columns needed |
| --- | --- | --- |
| Prediction | What value does the fitted model expect at this covariate row? | `row`, `dpar`, `type`, `estimate`, supplied `newdata` columns |
| Adjusted prediction | What value is expected across focal covariate values after fixing or averaging over other predictors? | focal-term columns, `condition`, `margin`, `weights` |
| Estimated marginal mean | What model-based mean is obtained over a reference grid? | reference-grid columns, averaging weights, `dpar`, scale |
| Contrast | How do two predictions or marginal means differ or ratio? | `contrast`, `estimate`, `comparison_scale`, interval source |
| Slope | How does a prediction change with a focal predictor? | `term`, `derivative_scale`, step size or analytic derivative source |
| Diagnostic | Does the fitted model violate a check before interpretation? | `check`, `status`, diagnostic value, threshold, action |

The phrase "EMMs" should mean estimated marginal means. Avoid "EM means" in
documentation.

### Keep Scales Visible

Every row that can be plotted needs the fitted scale and the reporting scale.
For `sigma`, the public response-scale quantity is residual SD or a
family-specific scale; the internal fitted coefficient is on `log(sigma)`.
If the scientific question is residual variance, predictability, or
overdispersion, examples can add a derived `sigma^2` column, but they should not
rename the fitted parameter to `tau` or silently square log-SD coefficients.

For bivariate models, `rho12` remains the residual correlation parameter.
Ordinary group-level, phylogenetic, spatial, and mean-scale correlations should
flow through `corpairs()` rows so plots can keep correlation layers separate.

### Make Uncertainty Provenance Mandatory

A point estimate can be useful without an interval, but every interval must
name what it represents. Reusing the column names `conf.low` and `conf.high` is
fine only if companion columns explain the source:

```text
interval_source = "wald" | "profile" | "derived_profile" |
                  "parametric_bootstrap" | "simulation" |
                  "posterior" | "not_available"
conf.status = "wald" | "profile" | "profile_ready" |
              "newdata_required" | "derived_interval_unavailable" |
              "wald_unavailable" | "not_requested"
```

Bayesian-looking geoms such as half-eye plots or lineribbons can be useful for
frequentist uncertainty if the data object contains a confidence distribution,
bootstrap distribution, profile sample, or simulation replicate. The plot title
and axis labels should not call those rows posterior draws unless a Bayesian
model actually produced posterior draws.

### Separate Raw Data, Fitted Parameters, And Diagnostics

Tutorial figures should usually follow this order:

1. raw response data on the biological scale;
2. fitted distributional parameter surfaces, such as `mu`, `sigma`, `nu`, or
   `rho12`;
3. uncertainty or interval status, when available;
4. diagnostics or simulation summaries that explain whether interpretation is
   trustworthy.

This order keeps a beginner from reading a polished curve before seeing the
data and model checks.

### Raw-Data-Plus-Model Example Rules

Slice 109 turns the landscape note into concrete example rules. A reader-facing
figure should make four objects visible in the prose or code before it becomes
publication styling:

| Object | Example rule | Why it matters |
| --- | --- | --- |
| Scientific question | Name the focal predictor, response, and distributional parameter before drawing. | A `mu` plot, a `sigma` plot, and a `rho12` plot answer different questions. |
| Raw data | Show observed responses on the observed response scale before or beside fitted `mu` curves. | Readers can see the data support before seeing the model surface. |
| Prediction table | Build the grid with `prediction_grid()` and the surface with `predict_parameters()` before calling a plot helper. | Conditioning, marginalization, fitted scale, and interval status stay inspectable. |
| Interpretation status | Report `conf.status`, `interval_source`, and `check_drm()` status in the surrounding workflow. | The plot cannot silently imply intervals or diagnostics that were not computed. |

For now, examples should keep raw observations and fitted distributional
parameters in separate panels or separate sequential figures. Raw response
points belong on the observed-response axis; they should not be overplotted on a
`sigma`, `sigma^2`, `rho12`, random-effect SD, or correlation axis. If an
example derives residual variance, it should create an explicit `sigma^2`
column from response-scale `sigma` predictions rather than renaming the fitted
parameter. If a plot draws a ribbon, interval bar, or shaded region, the source
table must contain a real interval source instead of
`interval_source = "not_available"`.

## Proposed Phase 17 Data Contracts

### Prediction Grid Builder

Slice 101 adds the first `prediction_grid()` implementation. It builds explicit
grids without fitting or plotting. The output is an ordinary data frame plus
metadata that can be printed:

```text
focal_terms
conditioned_terms
margin
weights
grid_source
```

The first helper supports simple focal terms, supplied `at` values,
conditioned nuisance predictors, mean-reference grids, and empirical
counterfactual grids. It does not promise full `emmeans` compatibility; that
requires a tested reference-grid contract for transformed, bounded, count,
ordinal, bivariate, and structured-effect fits.

Slice 117 adds the first preflight test for that contract. The current test
fits small fixed-effect models for the implemented univariate, count,
proportion, ordinal, and bivariate Gaussian families, builds explicit
`prediction_grid()` objects, and checks that `predict_parameters(type = "link")`
and `predict_parameters(type = "response")` preserve the documented inverse
link for each fitted `dpar`. This is evidence that the existing data helpers
respect link-versus-response scale on explicit grids; it is not an exported
`emmeans` method, a contrast API, or a weighting contract.

Slice 102 adds the first article-level empirical-grid example. The
model-workflow article now shows a conditioned grid for direct
`predict_parameters()` rows and a separate empirical grid for
`marginal_parameters(..., by = "temperature")`.

### Prediction Surface

`predict_parameters()` is the current base. Later versions can add optional
uncertainty columns without changing the long-table idea:

```text
row
row_label
dpar
component
type
estimate
std.error
conf.low
conf.high
conf.status
interval_source
newdata columns
```

Slice 103 adds the first provenance-only version of `conf.status` and
`interval_source` to `predict_parameters()` and `marginal_parameters()`. The
tables still contain point estimates only, so they report
`conf.status = "not_requested"` and
`interval_source = "not_available"` instead of empty confidence limits.

When uncertainty is unavailable, the row should still print with a status that
tells the user what to try next, such as profiling a direct target or supplying
`newdata`.

### Marginal And Contrast Surface

`marginal_parameters()` is currently a plug-in unweighted average. A later
`contrasts_parameters()` or `compare_parameters()` should be a separate
estimand, not an argument hidden inside the plotter. It should declare:

```text
estimand = "marginal_mean" | "contrast" | "ratio" | "slope"
dpar
type
by
weights
comparison_scale
estimate
uncertainty columns
```

This keeps pairwise differences, ratios such as `sigma_forest / sigma_grass`,
and slopes of `mu`, `sigma`, or `rho12` from being confused with raw fitted
coefficients.

### Distribution Or Draw Surface

If Phase 17 or Phase 18 later adds profile samples, parametric bootstrap draws,
or simulation replicates, they should live in a separate long table:

```text
row
dpar
component
type
source = "profile" | "parametric_bootstrap" | "simulation"
replicate
value
```

That table would be the natural bridge to `ggdist` geoms such as intervals,
half-eyes, dot intervals, and lineribbons. It would also be useful for simulation
reports without requiring any plotting package.

## Candidate Plot Families

The first plotting layer should be small and optional:

- raw response plus fitted `mu` curves or ribbons;
- fitted `sigma` curves, with optional derived residual-variance panels;
- fitted residual `rho12` curves for bivariate Gaussian coscale models;
- `corpairs()` dot-and-interval summaries for residual, group-level,
  phylogenetic, spatial, and mean-scale correlation rows;
- `check_drm()` visual summaries after diagnostic data contracts are stable;
- Phase 18 simulation plots for bias, root-mean-square error, empirical
  coverage, convergence, interval width, and power curves.

Do not start with a broad `autoplot.drmTMB()` that guesses the reader's
question. A small set of named helpers is safer:

```text
plot_parameter_surface()  # implemented in Slice 104
plot_corpairs()           # implemented in Slice 113
plot_diagnostics()        # planned
plot_simulation_summary() # planned
```

### `corpairs()` Plotting Preflight

Slice 112 records the minimum contract that `plot_corpairs()` follows as an
exported helper. Correlation displays are scientifically dense because residual
`rho12`, ordinary group-level correlations, phylogenetic correlations, spatial
correlations, and q=4 mean-scale correlations are different layers. A plot
helper should therefore consume an explicit `corpairs()` table rather than call
fitting internals or guess which layer the reader wants.

The helper should satisfy these rules:

- accept a `corpairs()` data frame as the primary input;
- require visible columns for `level`, `class`, `parameter`, `estimate`,
  `modelled`, and, when intervals are requested, `conf.status`;
- add a display status such as `not_requested` when a plain `corpairs(fit)`
  table lacks interval columns, instead of implying that intervals were checked;
- draw point estimates for all rows but draw interval segments only when
  `conf.low` and `conf.high` are finite;
- label or facet by `level` so residual, ordinary group-level, phylogenetic,
  spatial, and future study-level correlations are not visually collapsed;
- keep derived q=4 or covariance-product rows visibly separate from direct
  profile-ready correlation targets;
- cover empty tables, residual `rho12`, ordinary group-level rows,
  phylogenetic rows, derived-unavailable statuses, and missing `ggplot2` in
  tests while keeping the helper in `_pkgdown.yml`.

Only `plot_parameter_surface()` and `plot_corpairs()` are currently
implemented. The remaining names are design placeholders and should not be
exported until their data contracts and optional dependency policy are settled.

Slice 104 implements the first narrow helper, `plot_parameter_surface()`. It
consumes a `predict_parameters()` table, maps one explicit x-axis column to
`estimate`, returns a composable `ggplot` object, and keeps `ggplot2` in
`Suggests`. It does not compute intervals, estimated marginal means, contrasts,
or slopes.

Slice 113 implements `plot_corpairs()` after the Slice 112 preflight. It
consumes a `corpairs()` table, draws one point per correlation row, adds
interval segments only for rows with finite `conf.low` and `conf.high` bounds,
and keeps correlation `level`, `class`, and display interval status attached to
the plotted data. It does not compute correlation pairs, run profile intervals,
or collapse residual, ordinary group-level, phylogenetic, spatial, and future
study-level correlations into one unnamed layer.

Slice 114 adds optional faceting to `plot_corpairs()`. The default remains a
single panel with row labels that include `level`, `class`, and `parameter`;
readers can set `facet = "level"` or another explicit table column when they
need to visually separate correlation layers.

Slice 115 adds the first faceted Reference example for `plot_corpairs()`. This
is still an explicit-table example rather than a fitted biological workflow; the
workflow article should wait until the correlation example can show the fitted
model, table, plot, and interpretation together.

Slice 116 adds that first fitted workflow in the bivariate-coscale tutorial. The
example fits a repeated-individual model, stores `corpairs(fit_group)` as an
explicit table, and calls `plot_corpairs(pair_table, facet = "level")` so
residual `rho12` and group-level random-intercept correlation rows stay
separate.

Slice 108 confirms the pkgdown reference-page contract. Exported plotting
functions belong in the `Visualization` reference section, and only exported,
documented, tested helpers should appear there. At that slice boundary,
`plot_parameter_surface()` was the exported plotting helper with a stable data
contract. Core post-fit tables and extractors, including `summary()`,
`confint()`, `profile_targets()`, `prediction_grid()`, `predict_parameters()`,
`marginal_parameters()`, `corpairs()`, `fixef()`, `ranef()`, `sigma()`, and
`rho12()`, stay in the `Model fitting and post-fit tools` reference section
because they are data and extraction surfaces rather than plotting helpers.

## Dependency Policy

Core fitting, prediction, and summary helpers should remain free of plotting
dependencies. If a future plot helper returns a `ggplot` object, `ggplot2`
belongs in `Suggests`, the helper should fail with an informative message when
`ggplot2` is missing, and tests should cover the missing-package path. `ggdist`,
`patchwork`, and `viridis` should remain optional example or vignette tools
unless a later design decision shows that they are essential.

`tidybayes` is a design inspiration, not a dependency target. The relevant
idea is tidy long data for uncertainty, not Bayesian model support.

## Near-Term Slice Order

1. Decide whether the next `emmeans` step should be a design-only S3 contract,
   an internal reference-grid adapter, or another validation slice for
   structured-effect and random-effect predictions. Do not add an exported
   `emmeans` method until weights, contrasts, intervals, and unsupported-model
   errors are explicit.
