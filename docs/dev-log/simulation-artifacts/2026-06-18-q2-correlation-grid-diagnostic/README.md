# Q2 Correlation Grid Diagnostic

This artifact widens the q2 random-effect correlation boundary visibility
check without changing package code. It is diagnostic evidence for fitted
ordinary q2 covariance routes only, not recovery, coverage, power, release
readiness, CRAN readiness, Julia bridge parity, structured covariance support,
random effects in `rho12`, or non-Gaussian REML/AI-REML evidence.

## Aim

Check whether three already fitted ordinary q2 random-effect covariance routes
make near-boundary fitted correlations visible through `check_drm()`:

- univariate Gaussian `mu`/`sigma` random-intercept covariance;
- bivariate Gaussian `mu1`/`mu2` random-intercept covariance;
- bivariate Gaussian `sigma1`/`sigma2` random-intercept covariance.

The diagnostic records fitted correlation magnitude, boundary distance,
Hessian status, fixed-gradient status, and the route-specific `check_drm()`
row. It asks whether fitted boundary status is visible, not whether every true
boundary cell is accurately recovered.

## Data-Generating Mechanisms

Each route uses four complete-data Gaussian cells with true latent
random-effect correlations `0`, `0.4`, `0.9`, and `0.98`. The grid uses
deterministic seeds and one replicate per route-cell pair, so it is a
diagnostic pilot rather than a calibration grid.

The runner uses the default optimizer path with no retries, multistart,
fallback optimizer, profile interval, bootstrap interval, or manual convergence
rescue. Warnings and failures are recorded as data.

## Tables

- `q2-correlation-grid-source-grid.csv`: link-scale source values and
  six-nines guard distances for the four target correlations.
- `q2-correlation-grid-conditions.csv`: route, seed, group count, replicate
  count, and true correlation for each requested fit.
- `q2-correlation-grid-fit-diagnostics.csv`: per-fit convergence, Hessian,
  gradient, covariance, likelihood, warning, and fitted-correlation fields.
- `q2-correlation-grid-exposure.csv`: per-fit boundary-distance and
  threshold-exposure flags.
- `q2-correlation-grid-condition-summary.csv`: one-row denominators for each
  route-cell pair.
- `q2-correlation-grid-route-summary.csv`: compact route-level counts.
- `q2-correlation-grid-check-drm.csv`: full `check_drm()` rows beside each
  fit.
- `q2-correlation-grid-failures.csv`: fit errors if any occurred.
- `q2-correlation-grid-run-summary.csv`: compact run metadata and headline
  counts.
- `session-info.txt`: command, git state, and R session metadata.

## Result

Run the artifact with:

```sh
Rscript docs/dev-log/simulation-artifacts/2026-06-18-q2-correlation-grid-diagnostic/run-pilot.R
```

The committed run requested 12 fits across three routes and four true
correlation targets. All 12 fits converged with `pdHess = TRUE`; there were no
fit errors and no R warnings. Eight of 12 fits had fixed gradients below the
default threshold. Eight route-cell pairs produced `check_drm()` warning or
error rows, and four route-cell pairs produced a route-specific covariance
boundary warning.

The smallest fitted boundary distance was `1.003682e-06`. The largest fixed
gradient was `0.003596244`. The largest absolute fitted-minus-true correlation
difference was `0.4083517`; this is retained as evidence that one-replicate
boundary visibility is not recovery evidence.

The bivariate scale route illustrates the key limitation. Its true
`rho = 0.98` cell fit back to `rho = 0.9031` and therefore did not trigger the
route-specific covariance boundary warning. That is a diagnostic result, not a
failure to be hidden: `check_drm()` reports fitted boundary status, so broader
random-effect correlation recovery and interval studies still need deliberately
sized simulation grids.

## Boundary

This artifact does not change the TMB likelihood, formula grammar, optimizer,
controls, public API, examples, pkgdown navigation, or mission-control counts.
It does not promote q2 recovery accuracy, interval coverage, power,
structured correlations, q4/q8 covariance intervals, random effects in
`rho12`, Julia bridge parity, release readiness, CRAN readiness, or
non-Gaussian REML/AI-REML language.
