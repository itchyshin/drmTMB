# Student-t `nu` Profile/Bootstrap Calibration Diagnostic

## Scope

This artifact is a bounded calibration diagnostic for the fixed-effect
Student-t shape route. It follows the smaller profile/bootstrap pilot by
increasing the run to 50 replicates per cell and 50 bootstrap refits per
fit, so profile failures, bootstrap status, MCSE, and rough 70% interval
coverage can be audited with more depth without presenting a promotion grid.

It is not release-readiness evidence and does not settle profile/bootstrap
coverage for users. The profile level remains 0.70, bootstrap refit counts
are still modest, and failed or non-positive-Hessian fits remain part of the
evidence.

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

Each cell has 50 replicates. Profile intervals are requested
at level 0.7 for `nu:(Intercept)` and `nu:w`.
Parametric-bootstrap intervals are requested at level 0.7 with 50 refits per fit.

## Run Summary

| fits | min convergence | min pdHess | min profile ok | max profile coverage MCSE | min bootstrap ok | min bootstrap refits | max bootstrap coverage MCSE |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 100 | 0.880 | 0.860 | 0.380 | 0.101 | 1.000 | 50 | 0.071 |

## Fit Status

| cell | nu at w=0 | fits | convergence | pdHess | warning rate |
| --- | --- | --- | --- | --- | --- |
| low_nu_boundary | 2.800 | 50 | 0.880 | 0.860 | 0.100 |
| ordinary_nu | 8.000 | 50 | 0.920 | 0.860 | 0.100 |

## `nu` Profile Status

| cell | parameter | profiles | ok | failed | ok rate | rough coverage | coverage MCSE |
| --- | --- | --- | --- | --- | --- | --- | --- |
| low_nu_boundary | nu:(Intercept) | 50 | 27 | 23 | 0.540 | 0.519 | 0.096 |
| low_nu_boundary | nu:w | 50 | 26 | 24 | 0.520 | 0.692 | 0.091 |
| ordinary_nu | nu:(Intercept) | 50 | 21 | 29 | 0.420 | 0.810 | 0.086 |
| ordinary_nu | nu:w | 50 | 19 | 31 | 0.380 | 0.737 | 0.101 |

## `nu` Bootstrap Status

| cell | parameter | intervals | ok | failed | ok rate | rough coverage | coverage MCSE | min refits |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| low_nu_boundary | nu:(Intercept) | 50 | 50 | 0 | 1.000 | 0.520 | 0.071 | 50 |
| low_nu_boundary | nu:w | 50 | 50 | 0 | 1.000 | 0.600 | 0.069 | 50 |
| ordinary_nu | nu:(Intercept) | 50 | 50 | 0 | 1.000 | 0.500 | 0.071 | 50 |
| ordinary_nu | nu:w | 50 | 50 | 0 | 1.000 | 0.680 | 0.066 | 50 |

## Interpretation

This diagnostic records interval-method status and rough finite-sample behavior.
The profile rows are target-specific and can fail even when the model returns
finite point estimates. The bootstrap rows show whether the bounded refit
budget returns intervals, but 50 refits per fit is not enough to support
headline calibration.

Any later Student-t interval claim should carry the fit status, profile
status, bootstrap refit count, `student_nu` diagnostics, and MCSE columns
forward instead of summarizing away failed or weak rows.

## Files

- `run-pilot.R`: reproducible runner.
- `student-nu-profile-bootstrap-calibration-run-summary.csv`: top-line run summary.
- `tables/student-nu-profile-bootstrap-calibration-fit-summary.csv`: fit status by cell.
- `tables/student-nu-profile-calibration-summary.csv`: profile status and rough coverage by `nu` parameter.
- `tables/student-nu-bootstrap-calibration-summary.csv`: bootstrap status and rough coverage by `nu` parameter.
- `tables/student-nu-profile-bootstrap-calibration-diagnostics.csv`: interval diagnostics for the two `nu` coefficients.
- `tables/student-nu-profile-bootstrap-calibration-failures.csv`: interval failure rows.

## Boundary

This artifact does not promote Student-t profile or bootstrap coverage,
release readiness, CRAN readiness, Julia bridge parity, random effects,
bivariate routes, true `nu <= 2`, or non-Gaussian REML/AI-REML.
