# Structured Q2 Boundary Diagnostic

This artifact extends `check_drm()` fitted-boundary visibility to structured
q2 location covariance. It is diagnostic evidence for fitted coordinate-spatial,
animal-model, and `relmat()` q2 location covariance rows only, not recovery,
coverage, power, release readiness, CRAN readiness, Julia bridge parity, q4/q8
covariance intervals, random effects in `rho12`, or non-Gaussian REML/AI-REML
evidence.

## Aim

Check whether fitted near-boundary structured q2 location correlations are
visible through `check_drm()` for:

- bivariate Gaussian coordinate-spatial `mu1`/`mu2` q2 covariance;
- bivariate Gaussian `animal()` `mu1`/`mu2` q2 covariance;
- bivariate Gaussian `relmat()` `mu1`/`mu2` q2 covariance.

The diagnostic records fitted correlation magnitude, boundary distance,
Hessian status, fixed-gradient status, optimizer status, and the route-specific
`check_drm()` row. It asks whether fitted boundary status is visible, not
whether every true boundary cell is accurately recovered.

## Data-Generating Mechanisms

Each structured surface uses four complete-data bivariate Gaussian cells with
true latent structured correlations `0`, `0.4`, `0.9`, and `0.98`. The spatial
surface uses a ring coordinate layout. The animal and `relmat()` surfaces use
the existing known-matrix precision route. The grid uses deterministic seeds and
one replicate per surface-cell pair, so it is a diagnostic pilot rather than a
calibration grid.

The runner uses the default Phase 18 q2 fitting helpers with no manual retries,
multistart, fallback optimizer, profile intervals, bootstrap intervals, or
manual convergence rescue. Warnings and failures are recorded as data.

## Tables

- `structured-q2-boundary-source-grid.csv`: link-scale source values and
  six-nines guard distances for the four target correlations.
- `structured-q2-boundary-conditions.csv`: surface, seed, level count,
  replicate count, and true correlation for each requested fit.
- `structured-q2-boundary-fit-diagnostics.csv`: per-fit convergence, Hessian,
  gradient, covariance, likelihood, warning, and fitted-correlation fields.
- `structured-q2-boundary-exposure.csv`: per-fit boundary-distance and
  threshold-exposure flags.
- `structured-q2-boundary-condition-summary.csv`: one-row denominators for each
  surface-cell pair.
- `structured-q2-boundary-surface-summary.csv`: compact surface-level counts.
- `structured-q2-boundary-check-drm.csv`: full `check_drm()` rows beside each
  fit.
- `structured-q2-boundary-failures.csv`: fit errors if any occurred.
- `structured-q2-boundary-run-summary.csv`: compact run metadata and headline
  counts.
- `session-info.txt`: command, git state, and R session metadata.

## Result

Run the artifact with:

```sh
Rscript docs/dev-log/simulation-artifacts/2026-06-18-structured-q2-boundary-diagnostic/run-pilot.R
```

The committed run requested 12 fits across three structured q2 surfaces and four
true correlation targets. There were no fit errors. Eleven fits reported
optimizer convergence, all 12 reported `pdHess = TRUE`, and all 12 had fixed
gradients below the default threshold. The animal-model true `rho = 0.9` cell
reported optimizer non-convergence (`false convergence (8)`) while also showing
`pdHess = TRUE` and a fitted structured correlation at the numerical guard;
that warning is retained as part of the diagnostic evidence.

Five surface-cell pairs produced route-specific structured q2 covariance
warnings:

- spatial at true `rho = 0.98`, fitted `rho = 0.9837`;
- animal at true `rho = 0.9`, fitted `rho = 0.999999`;
- animal at true `rho = 0.98`, fitted `rho = 0.999999`;
- `relmat()` at true `rho = 0.9`, fitted `rho = 0.999999`;
- `relmat()` at true `rho = 0.98`, fitted `rho = 0.999999`.

The smallest fitted boundary distance was `1.000015e-06`. The largest fixed
gradient was `7.440224e-05`. The largest absolute fitted-minus-true correlation
difference was `0.6262573`; this is retained as evidence that one-replicate
boundary visibility is not recovery evidence.

## Boundary

This artifact changes `check_drm()` diagnostic reporting and adds tests. It does
not change the TMB likelihood, formula grammar, optimizer, controls, examples,
pkgdown navigation, or mission-control counts. It does not promote structured q2
recovery accuracy, interval coverage, power, q4/q8 covariance intervals, random
effects in `rho12`, Julia bridge parity, release readiness, CRAN readiness, or
non-Gaussian REML/AI-REML language.
