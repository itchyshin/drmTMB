# Support-Floor Diagnostic

This artifact is a diagnostic contract for the `drmTMB#59` support-floor
lane. It covers beta, zero-one beta, and missing-predictor beta-style guards.

The source-level guard candidates are:

- `beta_mu_eps = 1e-12`, which keeps fitted beta means inside the open
  interval before density evaluation;
- `beta_shape_floor = 1e-8`, which keeps beta shape parameters positive in
  beta and zero-one beta response likelihoods;
- the matching `1e-12` mean clamp and `1e-8` shape floor in beta and
  zero-one beta missing-predictor quadrature.

The runner deliberately does not add optimizer tricks or force difficult fits
to converge. It records fitted status and validation failures as data.

## Outputs

- `support-floor-source-grid.csv`: deterministic source-level guard grid for
  beta-response, zero-one-beta-response, missing-predictor-beta, and
  missing-predictor-zero-one-beta routes.
- `support-floor-source-summary.csv`: source-grid floor activation counts by
  route and `log_sigma`.
- `support-floor-fit-diagnostics.csv`: small fitted-model diagnostics for
  ordinary and boundary-near beta/zero-one-beta routes plus valid
  missing-predictor routes.
- `support-floor-check-drm.csv`: `check_drm()` rows retained beside each fit.
- `support-floor-validation.csv`: malformed or boundary-heavy response and
  missing-predictor inputs that should fail before density floors can hide the
  boundary problem.
- `support-floor-failures.csv`: unexpected fit errors, if any.
- `support-floor-run-summary.csv`: compact run-level counts.
- `session-info.txt`: software and platform details.

The runner resolves the repository root from its own file path, so it can be
launched from outside the package working directory. The run summary and
session info record UTC timestamp, git SHA, branch, dirty state, and command.

## Results

The deterministic source grid has 60 rows. Shape-floor activation is absent at
`log_sigma = log(0.5)` and `log_sigma = log(2)`. It appears in the high-scale
source cells: 4/12 alpha and 4/12 beta-shape floor activations at
`log_sigma = 8`, then 12/12 and 12/12 at `log_sigma = 12` and
`log_sigma = 16`.

The fitted cells are deliberately small. All 6 fitted cells converged with
`pdHess = TRUE` and no fit errors. Four fitted response-route cells exposed
`alpha` and `beta_shape`; none of those reported either vector at the `1e-8`
floor. The two fitted missing-predictor cells did not expose `alpha` or
`beta_shape` in the TMB report, so their fitted shape-floor counts are recorded
as `NA`, not zero. The largest fixed-gradient diagnostic was `0.002022189` in
the valid missing-predictor zero-one beta cell, where `check_drm()` marked the
fixed-gradient and standard-error rows as warnings.

All 6 validation cells errored with the expected boundary messages. The beta
response route rejected exact 0 and 1 values; zero-one beta rejected
out-of-range responses and all-boundary responses with no interior beta data;
the beta missing-predictor route rejected an observed boundary predictor; and
the zero-one beta missing-predictor route rejected observed rows with no
interior predictor values.

## Boundaries

This artifact can show where the source-level support floors would activate
and whether small fitted response-route examples expose floor-active reported
shape vectors.
It can also show whether illegal response or missing-predictor boundaries are
rejected visibly.

It does not promote beta or zero-one beta interval coverage, power, release
readiness, CRAN readiness, Julia bridge parity, random effects, structured
effects, bivariate responses, or non-Gaussian REML/AI-REML claims.
