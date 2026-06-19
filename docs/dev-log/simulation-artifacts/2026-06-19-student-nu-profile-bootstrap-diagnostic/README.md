# Student-t `nu` Profile/Bootstrap Diagnostic

## Scope

This artifact is a small feasibility diagnostic for the fixed-effect
Student-t shape route. It follows the 100-replicate Wald calibration
artifact by asking whether the existing profile-likelihood and
parametric-bootstrap machinery can produce visible status rows for the two
`nu` coefficients in ordinary and low-boundary cells.

It is not a coverage or promotion grid. With five replicates per cell and
ten bootstrap refits per fit, the only defensible conclusion is whether the
interval machinery runs, which statuses it reports, and whether degenerate
or failed interval rows remain visible.

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

Each cell has 5 replicates. Profile intervals are requested
at level 0.7 for `nu:(Intercept)` and `nu:w`.
Parametric-bootstrap intervals are requested at level 0.7 with 10 refits per fit.

## Run Summary

| fits | min convergence | min pdHess | min profile ok | max degenerate profile | min bootstrap ok | min bootstrap refits |
| --- | --- | --- | --- | --- | --- | --- |
| 10 | 0.600 | 0.800 | 0.000 | 0.000 | 1.000 | 10 |

## Fit Status

| cell | nu at w=0 | fits | convergence | pdHess | warning rate |
| --- | --- | --- | --- | --- | --- |
| low_nu_boundary | 2.800 | 5 | 0.600 | 0.800 | 0.200 |
| ordinary_nu | 8.000 | 5 | 0.800 | 0.800 | 0.200 |

## `nu` Profile Status

| cell | parameter | profiles | ok | failed | ok rate | degenerate | degenerate rate |
| --- | --- | --- | --- | --- | --- | --- | --- |
| low_nu_boundary | nu:(Intercept) | 5 | 0 | 5 | 0.000 | 0 | 0.000 |
| low_nu_boundary | nu:w | 5 | 0 | 5 | 0.000 | 0 | 0.000 |
| ordinary_nu | nu:(Intercept) | 5 | 3 | 2 | 0.600 | 0 | 0.000 |
| ordinary_nu | nu:w | 5 | 1 | 4 | 0.200 | 0 | 0.000 |

## `nu` Bootstrap Status

| cell | parameter | intervals | ok | failed | ok rate | min refits | mean refits |
| --- | --- | --- | --- | --- | --- | --- | --- |
| low_nu_boundary | nu:(Intercept) | 5 | 5 | 0 | 1.000 | 10 | 10.000 |
| low_nu_boundary | nu:w | 5 | 5 | 0 | 1.000 | 10 | 10.000 |
| ordinary_nu | nu:(Intercept) | 5 | 5 | 0 | 1.000 | 10 | 10.000 |
| ordinary_nu | nu:w | 5 | 5 | 0 | 1.000 | 10 | 10.000 |

## Interpretation

This diagnostic records interval feasibility and status visibility only.
The bootstrap count is too small for interval calibration, and the profile
level is chosen to keep the run bounded. Degenerate profile rows, failed
Wald rows, `student_nu` warnings, and bootstrap refit counts should travel
with any later Student-t interval evidence rather than being summarized
away.

## Files

- `run-pilot.R`: reproducible runner.
- `student-nu-profile-bootstrap-run-summary.csv`: top-line run summary.
- `tables/student-nu-profile-bootstrap-fit-summary.csv`: fit status by cell.
- `tables/student-nu-profile-summary.csv`: profile status by `nu` parameter.
- `tables/student-nu-bootstrap-summary.csv`: bootstrap status by parameter.
- `tables/student-nu-profile-bootstrap-diagnostics.csv`: interval
  diagnostics for the two `nu` coefficients.
- `tables/student-nu-profile-bootstrap-failures.csv`: interval failure rows.

## Boundary

This artifact does not promote Student-t profile or bootstrap coverage,
release readiness, CRAN readiness, Julia bridge parity, random effects,
bivariate routes, true `nu <= 2`, or non-Gaussian REML/AI-REML.
