# Phase 18 Interval Producer Contract

Phase 18 coverage tables should consume interval rows from fitting-specific
producers rather than guessing how an interval was made. The common consumer is
`phase18_summarise_interval_coverage()`: it needs `truth`, `conf.low`, and
`conf.high`, and it uses `interval_status = "ok"` when that status column is
present. Failed, planned, or unavailable rows therefore stay in the evidence
table and still count in `n_replicate`, but they do not count in `n_interval`.

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

Diagnostics should also separate three different causes of a low coverage
entry. `phase18_summarise_interval_evidence()` reports how many requested
replicates produced usable intervals, how many usable intervals covered truth,
how many usable intervals missed truth, and how many rows were unusable because
they failed or were not requested. This is the default interpretation layer for
formal Student-t shape and `rho12` interval pilots; a failed profile is a
method-status result, not a coverage miss.

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
producers should do that surface by surface. `interval_scale` may be one value
for the whole table or one value per row.

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

Slice 278 confirms that this helper is a simulation-table producer, not the
public fitted-model correlation interval route. The fitted-model route remains
`profile_targets()` plus `confint(..., method = "profile")` for direct
correlation targets. Simulation producers may use Fisher-z back-transformed
Wald intervals with either raw-correlation standard errors or Fisher-z-scale
standard errors, and the returned table must record
`interval_scale = "fisher_z_backtransformed"` and `std.error.scale`.

`phase18_profile_interval_columns()` is the shared profile-smoke adapter. It
keeps profile endpoints beside the replicate summary as `profile.conf.low`,
`profile.conf.high`, `profile.status`, and `profile.message` so a later
artifact writer can choose the requested parameters without dropping the rest
of the replicate table.

`phase18_bootstrap_interval_columns()` is the matching private parametric-
bootstrap adapter. It uses `phase18_parametric_bootstrap()` and percentile
intervals from `R/sim_bootstrap.R`, writes `bootstrap.*` columns back onto the
replicate summary, and leaves unrequested rows as `not_requested`. If bootstrap
is requested but no finite estimates are available for a parameter, the row is
marked as `failed`.

`phase18_intervals_from_columns()` converts profile or bootstrap column sets
into the standard interval-row contract. `phase18_interval_evidence_table()`
then binds Wald, profile, and bootstrap rows into one artifact with
`artifact_grain = "interval_evidence"`. `phase18_interval_failures()` should be
run on that combined artifact so planned, failed, and unavailable intervals are
visible before coverage summaries are interpreted.

`phase18_summarise_interval_evidence()` is the method-level diagnostics
consumer for the same combined artifact. It returns
`artifact_grain = "interval_diagnostics"` and keeps `n_interval`,
`n_covered`, `n_interval_missed`, `n_interval_unusable`, success/failure
rates, and MCSEs together so reports can distinguish method instability from
statistical under-coverage.
