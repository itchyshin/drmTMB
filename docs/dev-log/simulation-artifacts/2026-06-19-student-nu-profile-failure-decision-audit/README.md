# Student-t `nu` Profile Failure Decision Audit

## Scope

This artifact is a readback audit of the 100-fit Student-t profile/bootstrap
calibration diagnostic. It does not rerun fits and does not change interval
methods. Its purpose is to decide whether the next Student-t interval slice
should run a larger grid or repair/profile-audit the method first.

## Source Artifact

- `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-profile-bootstrap-calibration-diagnostic`

## Decision Summary

| cell | parameter | profile ok | profile failed | profile decision | bootstrap coverage | bootstrap MCSE | bootstrap decision |
| --- | --- | --- | --- | --- | --- | --- | --- |
| low_nu_boundary | nu:(Intercept) | 0.540 | 23 | blocked_by_method | 0.520 | 0.071 | needs_larger_grid |
| low_nu_boundary | nu:w | 0.520 | 24 | blocked_by_method | 0.600 | 0.069 | needs_larger_grid |
| ordinary_nu | nu:(Intercept) | 0.420 | 29 | blocked_by_method | 0.500 | 0.071 | diagnostic_hold |
| ordinary_nu | nu:w | 0.380 | 31 | blocked_by_method | 0.680 | 0.066 | needs_larger_grid |

## Profile Failure Diagnostics

The 100-fit calibration artifact retained 107 focused `nu` profile failures.
Most failed rows reported `nonfinite_interval`; profile failure also occurred
in many fits that had `converged = TRUE` and `pdHess = TRUE`, so larger
replicate counts alone would not resolve the profile interval method.

| converged | pdHess | profile failures |
| --- | --- | --- |
| FALSE | FALSE | 13 |
| TRUE | FALSE | 8 |
| TRUE | TRUE | 86 |

## Degenerate Profile Rows

Two low-boundary `nu:(Intercept)` profile rows were formally `ok` but had
degenerate intervals. They are retained as target-construction evidence, not
as calibrated interval support.

| cell_id | replicate | parameter | truth | estimate | conf.low | conf.high | converged | pdHess | student_nu_status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| student_shape_001 | 8 | nu:(Intercept) | -0.223 | -34.251 | -34.251 | -34.251 | FALSE | FALSE | error |
| student_shape_001 | 9 | nu:(Intercept) | -0.223 | 8.146 | 8.146 | 8.146 | FALSE | FALSE | warning |

## Boundary

Student-t profile intervals remain `blocked_by_method` for the current fixed-effect
finite-variance shape route. Bootstrap intervals remain diagnostic or larger-grid
candidates depending on the target. This artifact does not promote profile or
bootstrap coverage, random effects, bivariate routes, structured routes, true
`nu <= 2`, Julia bridge parity, release readiness, CRAN readiness, or
non-Gaussian REML/AI-REML.
