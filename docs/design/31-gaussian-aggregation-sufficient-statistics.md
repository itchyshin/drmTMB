# Gaussian Aggregation and Sufficient Statistics

## Purpose

This note defines the Phase 5b aggregation path for large Gaussian data.
It is for package contributors deciding when repeated observation rows can be
collapsed before TMB optimization without changing the fitted likelihood.

Sparse fixed-effect matrices and aggregation solve different memory problems.
`sparse_fixed = TRUE` helps when the design matrix has many mostly-zero
columns. Aggregation helps when the data have many rows but far fewer unique
predictor states. A large ecological survey can need both, but they should be
implemented and tested separately.

## First Supported Target

The first aggregation target should be opt-in and narrow:

```r
drmTMB(
  bf(y ~ habitat + season, sigma ~ effort_class),
  family = gaussian(),
  data = dat,
  control = drm_control(aggregate_gaussian = TRUE)
)
```

`aggregate_gaussian` is a reserved design name, not an implemented control.
Slice 48 should either adopt that name or choose a different explicit
Gaussian-only control before writing code.

The first coded path should allow only univariate Gaussian fixed-effect
models. It should reject:

- ordinary random effects;
- direct random-effect SD formulas such as `sd(id) ~ z`;
- phylogenetic or spatial structured effects;
- known sampling covariance through `meta_known_V(V = V)`;
- bivariate Gaussian models;
- non-Gaussian families;
- row-level features that cannot be represented by the aggregation key.

This scope keeps the first likelihood comparison exact and keeps the user
message honest: aggregation is a Gaussian row-compression tool, not a general
large-data engine.

## Likelihood Contract

For a Gaussian cell `g`, assume every row in the cell has the same location and
scale linear predictors after missing-row filtering:

```text
eta_mu_i = eta_mu_g
eta_sigma_i = eta_sigma_g
mu_g = eta_mu_g
sigma_g = exp(eta_sigma_g)
```

For unweighted rows,

```text
y_i | mu_g, sigma_g ~ Normal(mu_g, sigma_g^2),  i in g
```

the log-likelihood contribution is:

```text
sum_i log p(y_i | mu_g, sigma_g)
  = -0.5 n_g log(2 pi)
    - n_g log(sigma_g)
    - 0.5 (sum_y2_g - 2 mu_g sum_y_g + n_g mu_g^2) / sigma_g^2
```

where:

```text
n_g      = number of rows in cell g
sum_y_g  = sum_i y_i
sum_y2_g = sum_i y_i^2
```

The optimizer sees the same likelihood it would see from the full rows. Only
the internal data representation changes.

If ordinary likelihood weights are supported in a later aggregation slice, the
same algebra uses weighted sufficient statistics:

```text
sum_w_g   = sum_i w_i
sum_wy_g  = sum_i w_i y_i
sum_wy2_g = sum_i w_i y_i^2
```

The first implementation can reject non-unit weights if that keeps the
comparison and diagnostics simpler.

## Aggregation Key

Rows are eligible for the same Gaussian aggregation cell only after ordinary
model-row filtering and only when these stored inputs are identical:

- the fixed-effect design row for `mu`;
- the fixed-effect design row for `sigma`;
- any offsets that enter `mu` or `sigma`;
- the processed likelihood-weight rule chosen for the first implementation;
- the family and link route.

The grouping key should be built from model matrices and offsets, not directly
from raw data-frame columns. This avoids false splits from equivalent factor
contrasts and catches the model that TMB will actually fit.

## TMB Data Contract

The first implementation should keep the dense row path intact and add a
parallel aggregated Gaussian path. The TMB data should include enough fields to
make the route explicit:

```text
use_gaussian_aggregation
n_agg
agg_n
agg_sum_y
agg_sum_y2
X_mu_agg
X_sigma_agg
offset_mu_agg
offset_sigma_agg
```

The C++ Gaussian likelihood can then branch:

```text
if (!use_gaussian_aggregation) {
  loop over observation rows
} else {
  loop over aggregation cells
}
```

The branch should report the same fixed-effect coefficients, scale estimates,
log-likelihood, `AIC`, and fitted parameter values at the cell level. Any
method that returns one value per original row needs a clear policy before
aggregation is advertised for saved fitted objects.

## Post-Fit Method Policy

Aggregation compresses the likelihood rows. That creates an output question:
should fitted-row methods return aggregation-cell rows or original rows?

The first implementation should use one of two conservative policies:

1. Keep an original-row expansion map when `keep_data = TRUE`, so
   `predict(fit)`, `fitted(fit)`, and `residuals(fit)` can still return
   original-row outputs.
2. When the expansion map is not retained, require `newdata` for full-row
   predictions and make fitted-row residuals error with a clear message.

Do not silently return cell-level residuals as if they were row-level
residuals. Cell-level fitted summaries can be useful, but they need an explicit
method or column that says they are aggregation-cell summaries.

## Diagnostics

Before fitting, an internal helper should be able to report:

- original row count;
- aggregation-cell count;
- compression ratio;
- largest cell size;
- whether `mu` and `sigma` designs are both part of the key;
- the reason aggregation was rejected, when it is rejected.

`check_drm()` can later expose the fitted aggregation state:

```text
gaussian_aggregation: ok/note/warning
original_rows
aggregation_cells
compression_ratio
largest_cell_n
```

Pat's reader-facing version is: "This fit used 5 million rows in the data, but
only 80,000 Gaussian likelihood cells after aggregation."

## Required Tests

The first implementation should add tests before any benchmark claim:

- an independent likelihood-comparison test showing full rows and aggregated
  cells have the same log-likelihood at fixed coefficients;
- a fitted dense-versus-aggregated parity test for coefficients,
  `sigma`, `logLik()`, `AIC`, and `vcov()` on a small dataset;
- a test with a non-intercept `sigma` formula where rows aggregate only when
  the `sigma` design row also matches;
- rejection tests for random effects, direct-SD formulas, structured effects,
  known covariance, bivariate Gaussian, and non-Gaussian families;
- a post-fit output test for the selected fitted-row prediction and residual
  policy;
- a memory-light compatibility test when `keep_model_frame = FALSE`.

The benchmark script should be extended only after the parity tests pass.

## Roadmap

Slice 47 records this design. Slice 48 should implement an internal
aggregation-key builder and likelihood-comparison helper. Slice 49 should fit
the first opt-in univariate Gaussian aggregation path. Slice 50 should add
benchmarks, docs, and a release-readiness audit for the aggregation lane.

Later phases can consider:

- weighted Gaussian aggregation;
- bivariate Gaussian sufficient statistics, adding `sum_y1`, `sum_y2`,
  `sum_y1y1`, `sum_y2y2`, and `sum_y1y2`;
- random-effect or structured-effect aggregation when the random-effect index
  is part of the key;
- aggregation combined with sparse fixed-effect matrices.
