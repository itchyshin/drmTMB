# Bivariate Scale Clamp-Sensitivity Diagnostic

This artifact is a narrow diagnostic for the `drmTMB#59` numerical-guard
sensitivity row. It asks whether the configurable `log(sigma)` clamp behaves
visibly for fixed-effect bivariate Gaussian `sigma1` and `sigma2` formulas.
It is not a recovery, coverage, power, or release-readiness grid.

The fitted model is
`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ z1, sigma2 = ~ z2, rho12 = ~ 1)`
with `family = biv_gaussian()`. Location parameters `mu1` and `mu2` are the two
conditional means. Scale parameters `sigma1` and `sigma2` are the residual
standard deviations on the two response axes, modelled through
`log(sigma1)` and `log(sigma2)`. Coscale is represented by residual
correlation `rho12`, kept constant here so this artifact isolates the scale
guard.

The runner compares three public control settings:

- `logsigma_clamp = NULL`;
- the default identity-in-band clamp;
- a wide `logsigma_clamp = c(-25, 25)` band.

The runner deliberately does not retry fits, force convergence, change starts,
use fallback optimizers, profile intervals, or bootstrap intervals. It records
warnings, optimizer status, Hessian status, fixed gradients, fitted
`log(sigma1)`/`log(sigma2)` ranges, default-vs-off differences, `check_drm()`
rows, and session details.

## Outputs

- `biv-scale-clamp-conditions.csv`: four bivariate scale cells and their true
  formula-scale coefficients.
- `biv-scale-clamp-configs.csv`: off/default/wide clamp settings.
- `biv-scale-clamp-fit-diagnostics.csv`: per-fit coefficients, standard
  errors, fit status, fitted log-scale ranges, clamp deltas, and
  `check_drm()` summaries.
- `biv-scale-clamp-comparisons.csv`: per-fit differences against the
  replicate-matched unclamped reference.
- `biv-scale-clamp-aggregate-summary.csv`: per-condition and per-config rates
  plus maximum absolute default-vs-off differences.
- `biv-scale-clamp-condition-summary.csv`: condition-level denominators.
- `biv-scale-clamp-check-drm.csv`: full `check_drm()` rows for each fit.
- `biv-scale-clamp-failures.csv`: unexpected fit errors, if any.
- `biv-scale-clamp-run-summary.csv`: compact run-level counts.
- `session-info.txt`: software and platform details.

The runner resolves the repository root from its own file path, so it can be
launched from outside the package working directory. The run summary and
session info record UTC timestamp, git SHA, branch, dirty state, and command.

## Results

The diagnostic ran 120 requested fits: four bivariate scale cells, ten
replicates per cell, and three clamp configurations per replicate. There were
no fit errors. All 120 fits converged with `pdHess = TRUE`.

The ordinary bivariate scale cell had no clamp-active fits. Default, wide, and
unclamped controls matched to numerical tolerance in that cell.

The three high-scale cells made the default guard visible. The default
configuration produced 30 `logsigma_clamp_active` warnings, all in cells where
`sigma1`, `sigma2`, or both axes lived above the default identity band. The
reported upper fitted log-scale was `15` for the default clamp, while the
unclamped and wide-band fits reached approximately `15.86` to `16.50` on the
high-scale axis. The wide-band fits matched the unclamped reference in the
audited cells, while the default clamp materially changed log likelihood and
scale coefficients when it bound.

This is the same honest pattern as the first fixed-effect univariate clamp
pilot, now checked on the bivariate `sigma1`/`sigma2` route: the default guard
is negligible when inactive, and it leaves a visible diagnostic trace when it
binds.

## Boundaries

This artifact can show fixed-effect bivariate Gaussian scale-guard visibility
for `sigma1` and `sigma2` under ordinary and deliberately huge
unstandardized-scale cells.

It does not show bivariate scale-route recovery accuracy, interval coverage,
power, q2/q4/q8 covariance readiness, random effects in `rho12`, structured
correlation readiness, Julia bridge parity, release readiness, CRAN readiness,
missing-data behavior, or non-Gaussian REML/AI-REML claims.
