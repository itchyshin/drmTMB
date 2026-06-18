# Residual rho12 Open-Interval Guard Diagnostic

This artifact is a diagnostic contract for the `drmTMB#59` residual
correlation guard lane. It covers fixed bivariate Gaussian residual
`rho12 ~ 1` only. Random effects or structured terms in `rho12` remain out of
scope.

The guard candidate is the correlation transform
`rho12 = 0.999999 * tanh(eta_rho12)` in `src/drmTMB.cpp`, with matching
response-scale extraction through `rho12()` and `predict(..., dpar = "rho12")`.
The transform keeps the residual covariance matrix inside the open interval
`(-1, 1)`. It is a domain transform plus near-singularity guard, not evidence
that a near-boundary fit is inferentially reliable.

The runner deliberately does not retry fits, force convergence, use profile or
bootstrap intervals, or change optimizer controls. It records the default
Fisher-z start and whether the residual-correlation start was clamped at the
R-side `[-0.8, 0.8]` starting-value boundary.

## Outputs

- `rho12-open-interval-source-grid.csv`: deterministic transform grid for
  target correlations 0, 0.4, 0.9, and 0.98.
- `rho12-open-interval-conditions.csv`: fitted diagnostic cells.
- `rho12-open-interval-fit-diagnostics.csv`: fitted estimates, starts,
  gradients, Hessian status, log likelihood, AIC/BIC, boundary distances, and
  warning counts.
- `rho12-open-interval-exposure.csv`: per-cell true and fitted `rho12`
  exposure, guard multiplier, `1 - rho12^2`, threshold counts, and boundary
  messages.
- `rho12-open-interval-condition-summary.csv`: per-cell denominators for
  requested, attempted, error, warning, convergence, Hessian, gradient, and
  `check_drm()` warning/error status.
- `rho12-open-interval-check-drm.csv`: full `check_drm()` rows beside each fit,
  including `rho12_boundary` and `fixed_gradient`.
- `rho12-open-interval-failures.csv`: unexpected fit errors, if any.
- `rho12-open-interval-run-summary.csv`: compact run-level counts.
- `session-info.txt`: software and platform details.

The runner resolves the repository root from its own file path, so it can be
launched from outside the package working directory. The run summary and
session info record UTC timestamp, git SHA, branch, dirty state, and command.

## Results

The source grid has 4 rows for target correlations 0, 0.4, 0.9, and 0.98.
The six-nines guard leaves those targets unchanged on the guarded scale when
using the matching inverse link, while the unguarded `tanh(eta)` value is
larger by about `rho * 1e-6`.

The fitted diagnostic has 4 requested cells and 4 attempted fits. All 4 fits
converged with `pdHess = TRUE`, and there were no fit errors or R warnings.
That clean status is not the claim. The high-correlation cells also exposed
the numerical path and inspection signals: 2/4 cells used the default R-side
starting-value clamp from the raw residual correlation to `0.8`; 2/4 cells had
`fixed_gradient` warnings; and the `rho_true = 0.98` cell had a
`rho12_boundary` warning with fitted `rho12 = 0.9813`.

The largest absolute response-scale `rho12` error in this one-replicate
diagnostic was `0.05096506`, from the `rho_true = 0.4` cell. The high cell
estimated `rho12 = 0.9269` for `rho_true = 0.9`. The default-boundary cell
estimated `rho12 = 0.9813` for `rho_true = 0.98`; its minimum fitted
`1 - rho12^2` was `0.03700307`, and its boundary distance was `0.01867593`.

## Boundaries

This artifact can show whether a small fixed-effect residual-correlation stress
set surfaces near-boundary `rho12` behaviour through fitted values, gradients,
Hessian status, and `check_drm()` rows.

It does not promote calibrated intervals, coverage, power, release readiness,
CRAN readiness, Julia bridge parity, random effects in `rho12`, structured
correlations, mixed responses, or non-Gaussian REML/AI-REML claims.
