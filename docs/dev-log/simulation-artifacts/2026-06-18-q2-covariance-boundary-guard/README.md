# Q2 Covariance Boundary Guard Diagnostic

This artifact is a diagnostic contract for the `drmTMB#59` q2
random-effect covariance guard lane. It covers one fitted surface only:
univariate Gaussian `mu`/`sigma` group-level covariance through matching
`(1 | p | id)` terms in the location and scale formulas.

The guard candidate is the q2 covariance transform
`rho = 0.999999 * tanh(eta_cor_mu_sigma)` in `src/drmTMB.cpp`, with matching
response-scale extraction through `corpars`, `summary()`, and `check_drm()`.
The transform keeps the latent covariance matrix inside the open interval
`(-1, 1)`. It is a domain transform plus near-singularity guard, not evidence
that a near-boundary covariance is inferentially reliable.

The runner deliberately does not retry fits, force convergence, use fallback
optimizers, use profile or bootstrap intervals, or change optimizer controls.
It records failures, warnings, optimizer status, Hessian status, fixed
gradients, fitted covariance diagnostics, and full `check_drm()` rows.

## Outputs

- `q2-covariance-boundary-source-grid.csv`: deterministic transform grid for
  target correlations 0, 0.4, 0.9, and 0.98.
- `q2-covariance-boundary-conditions.csv`: fitted diagnostic cells.
- `q2-covariance-boundary-fit-diagnostics.csv`: fitted estimates, gradients,
  Hessian status, log likelihood, AIC/BIC, boundary distances, and warning
  counts.
- `q2-covariance-boundary-exposure.csv`: per-cell true and fitted correlation
  exposure, guard multiplier, `1 - rho^2`, threshold counts, and covariance
  diagnostic messages.
- `q2-covariance-boundary-condition-summary.csv`: per-cell denominators for
  requested, attempted, error, warning, convergence, Hessian, gradient, and
  `check_drm()` warning/error status.
- `q2-covariance-boundary-check-drm.csv`: full `check_drm()` rows beside each
  fit, including `mu_sigma_random_effect_covariance`.
- `q2-covariance-boundary-failures.csv`: unexpected fit errors, if any.
- `q2-covariance-boundary-run-summary.csv`: compact run-level counts.
- `session-info.txt`: software and platform details.

The runner resolves the repository root from its own file path, so it can be
launched from outside the package working directory. The run summary and
session info record UTC timestamp, git SHA, branch, dirty state, and command.

## Results

The source grid has 4 rows for target correlations 0, 0.4, 0.9, and 0.98. The
six-nines guard leaves those targets unchanged on the guarded scale when using
the matching inverse link, while the unguarded `tanh(eta)` value is larger by
about `rho * 1e-6`.

The fitted diagnostic has 4 requested cells and 4 attempted fits. All 4 fits
converged with `pdHess = TRUE`, and there were no fit errors or R warnings.
That clean status is not the claim. The boundary cell estimated
`rho = 0.999999` for true `rho = 0.98`, which is exactly why the diagnostic row
needs to be visible: `check_drm()` reported a
`mu_sigma_random_effect_covariance` warning at the configured
`rho_boundary = 0.98`.

The ordinary, moderate, and high cells reported `ok` covariance diagnostics.
The boundary cell had boundary distance `1e-06`, `1 - rho^2 = 1.999999e-06`,
and a `check_drm()` warning telling users to profile, simulate, or simplify
before interpreting the covariance.

## Boundaries

This artifact can show whether a small fitted univariate Gaussian q2
location-scale covariance stress set surfaces near-boundary random-effect
correlation behaviour through fitted values, gradients, Hessian status, and
`check_drm()` rows.

It does not promote calibrated intervals, coverage, power, release readiness,
CRAN readiness, Julia bridge parity, random effects in `rho12`, structured
correlations, q4/q8 covariance intervals, bivariate covariance breadth,
missing-data behavior, or non-Gaussian REML/AI-REML claims.
