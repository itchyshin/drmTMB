# Phase 18 Interval Producer Contract

Phase 18 coverage tables should consume interval columns from fitting-specific
producers rather than guessing how an interval was made. The common consumer is
`phase18_summarise_interval_coverage()`: it only needs `truth`, `conf.low`, and
`conf.high`, but the rows that feed it should carry enough metadata for a reader
to understand the interval.

## Required Columns

A real interval producer should return the ordinary parameter-summary columns
plus:

- `conf.low` and `conf.high`: lower and upper endpoints on the reported scale.
- `conf.level`: nominal confidence level, usually `0.95`.
- `interval_method`: one of `wald`, `profile`, `parametric_bootstrap`, or
  `bootstrap`.
- `interval_scale`: the scale on which endpoints are reported, such as
  `public`, `formula_coefficient`, `log_sigma`, `rho`, or
  `fisher_z_backtransformed`.
- `interval_status`: `ok`, `not_estimated`, `failed`, or `not_requested`.
- `interval_message`: short reason when `interval_status` is not `ok`.

Known inputs such as `meta_V(V = V)` must not receive interval rows. They can
appear in design metadata, but they are not estimated targets.

## Parameter Scales

The default reader-facing scale should be the public drmTMB scale:

- `mu` parameters on the linear predictor scale used by the location formula.
- `sigma` on the positive standard-deviation scale, even when TMB fits
  `log(sigma)` internally.
- `nu` on the documented shape scale for the family.
- `rho12` and random-effect correlations on the raw correlation scale
  `[-1, 1]`.

For Wald intervals on correlations, the producer may calculate endpoints on
the raw correlation scale or on Fisher's z scale and back-transform. The output
must record this in `interval_scale`. The preferred default for correlation
Wald intervals is `fisher_z_backtransformed` when the required standard error is
available, because it respects the correlation boundary better than a raw-rho
normal interval.

For profile intervals, `conf.low` and `conf.high` should be reported on the
public target scale. The profiler may move on an internal transformed scale,
but the table should not make readers translate endpoints by hand.

## Failure Accounting

Interval failures should remain rows, not disappear from coverage summaries.
If an interval is requested but cannot be computed, the producer should set
`conf.low = NA_real_`, `conf.high = NA_real_`, `interval_status = "failed"`,
and explain the failure in `interval_message`. This lets
`phase18_summarise_interval_coverage()` count `n_replicate` and `n_interval`
separately.

The first real producers should target:

1. Gaussian location-scale fixed effects on `mu` and `sigma`.
2. `meta_V(V = V)` fixed effects and fitted residual `sigma`, excluding known
   sampling covariance `V`.
3. `rho12` and random-effect correlations with explicit raw-rho versus Fisher-z
   Wald labels.
4. Profile intervals for variance, correlation, shape, and scale targets after
   the narrower Wald path is tested.

## Current Helper

`phase18_add_wald_intervals()` is the first generic helper for this contract.
It takes a parameter-summary table that already contains `estimate` and
`std.error`, adds normal Wald endpoints, and records `interval_method`,
`interval_scale`, `interval_status`, and `interval_message`. It deliberately
does not extract standard errors from fitted model objects; model-specific
producers should do that surface by surface.

The Gaussian location-scale summary smoke uses this helper with
`interval_scale = "formula_coefficient"`, because the current pilot summaries
target fixed-effect coefficients such as `mu:x` and `sigma:z`, not response-
scale fitted values.

`phase18_add_correlation_fisher_z_intervals()` is the matching correlation
helper. It reports endpoints on the raw correlation scale after calculating the
interval on Fisher's z scale. When `std.error.scale = "rho"`, it uses the delta
method to move the raw-correlation standard error to z scale. When
`std.error.scale = "fisher_z"`, it uses the supplied standard error directly.
Rows at or beyond the correlation boundary are marked as failed rather than
silently clipped.
