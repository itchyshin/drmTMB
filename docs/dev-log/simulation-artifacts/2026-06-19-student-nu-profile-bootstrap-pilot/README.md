# Student-t `nu` Profile/Bootstrap Pilot

## Scope

This artifact is a bounded diagnostic pilot for the fixed-effect Student-t
shape route. It follows the smaller profile/bootstrap feasibility artifact
by increasing the run to 25 replicates per cell and 25 bootstrap refits per
fit, so the interval status rows and rough pilot coverage summaries can be
audited without presenting a promotion grid.

It is not a calibrated coverage or release-readiness study. The profile
level remains 0.70, bootstrap refit counts are intentionally small, and
failed or non-positive-Hessian fits remain part of the evidence.

## Model

The fitted model is `bf(y ~ x, sigma ~ z, nu ~ w)` with
`family = student()`. The shape parameter uses
`nu = 2 + exp(eta_nu)`, so the fitted model is deliberately finite-variance
and excludes `nu <= 2`.

## Design

Both cells use `n = 180`, `beta_mu = (0.25, 0.55)`,
`beta_sigma = (log(0.65), 0.20)`, `nu_slope = 0`, and
`rho(x, w) = 0.20`. The low-boundary cell has `nu(w = 0) = 2.8`; the
ordinary cell has `nu(w = 0) = 8.0`.

Each cell has 25 replicates. Profile intervals are requested
at level 0.7 for `nu:(Intercept)` and `nu:w`.
Parametric-bootstrap intervals are requested at level 0.7 with 25 refits per fit.

## Run Summary

| fits | min convergence | min pdHess | min profile ok | max profile coverage MCSE | min bootstrap ok | min bootstrap refits | max bootstrap coverage MCSE |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 50 | 0.920 | 0.880 | 0.400 | 0.155 | 1.000 | 25 | 0.099 |

## Fit Status

| cell | nu at w=0 | fits | convergence | pdHess | warning rate |
| --- | --- | --- | --- | --- | --- |
| low_nu_boundary | 2.800 | 25 | 0.960 | 0.960 | 0.000 |
| ordinary_nu | 8.000 | 25 | 0.920 | 0.880 | 0.120 |

## `nu` Profile Status

| cell | parameter | profiles | ok | failed | ok rate | pilot coverage | coverage MCSE |
| --- | --- | --- | --- | --- | --- | --- | --- |
| low_nu_boundary | nu:(Intercept) | 25 | 10 | 15 | 0.400 | 0.400 | 0.155 |
| low_nu_boundary | nu:w | 25 | 13 | 12 | 0.520 | 0.615 | 0.135 |
| ordinary_nu | nu:(Intercept) | 25 | 15 | 10 | 0.600 | 0.733 | 0.114 |
| ordinary_nu | nu:w | 25 | 17 | 8 | 0.680 | 0.765 | 0.103 |

## `nu` Bootstrap Status

| cell | parameter | intervals | ok | failed | ok rate | pilot coverage | coverage MCSE | min refits |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| low_nu_boundary | nu:(Intercept) | 25 | 25 | 0 | 1.000 | 0.600 | 0.098 | 25 |
| low_nu_boundary | nu:w | 25 | 25 | 0 | 1.000 | 0.600 | 0.098 | 25 |
| ordinary_nu | nu:(Intercept) | 25 | 25 | 0 | 1.000 | 0.560 | 0.099 | 25 |
| ordinary_nu | nu:w | 25 | 25 | 0 | 1.000 | 0.720 | 0.090 | 25 |

## Interpretation

This pilot records interval-method status and rough finite-sample behavior.
The profile rows are target-specific and can fail even when the model returns
finite point estimates. The bootstrap rows show whether the bounded refit
budget returns intervals, but 25 refits per fit is not enough to support
headline calibration.

Any later Student-t interval claim should carry the fit status, profile
status, bootstrap refit count, `student_nu` diagnostics, and MCSE columns
forward instead of summarizing away failed or weak rows.

## Files

- `run-pilot.R`: reproducible runner.
- `student-nu-profile-bootstrap-pilot-run-summary.csv`: top-line run summary.
- `tables/student-nu-profile-bootstrap-pilot-fit-summary.csv`: fit status by cell.
- `tables/student-nu-profile-pilot-summary.csv`: profile status and rough coverage by `nu` parameter.
- `tables/student-nu-bootstrap-pilot-summary.csv`: bootstrap status and rough coverage by `nu` parameter.
- `tables/student-nu-profile-bootstrap-pilot-diagnostics.csv`: interval diagnostics for the two `nu` coefficients.
- `tables/student-nu-profile-bootstrap-pilot-failures.csv`: interval failure rows.

## Boundary

This artifact does not promote Student-t profile or bootstrap coverage,
release readiness, CRAN readiness, Julia bridge parity, random effects,
bivariate routes, true `nu <= 2`, or non-Gaussian REML/AI-REML.
