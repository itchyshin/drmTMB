# Student-t Nu Boundary Diagnostic Pilot

This artifact banks a small diagnostic pilot for the Student-t finite-variance
restriction `nu = 2 + exp(eta_nu)`. It uses the existing Phase 18 Student-t
shape runner plus the new `student_nu` summary columns from `check_drm()`.

Interpretation label: `diagnostic_pilot`. The evidence shows whether the
artifact tables can expose boundary warnings, errors, notes, convergence,
`pdHess`, and rough parameter recovery for ordinary and low-`nu` cells. It does
not calibrate coverage or promote any release claim.

## ADEMP Summary

**Aim.** Check whether the existing Student-t shape simulation artifacts expose
finite-variance-boundary diagnostic rates for an ordinary Student-t cell and a
low-`nu` boundary cell.

**Data-generating mechanism.** Each replicate uses
`bf(y ~ x, sigma ~ z, nu ~ w)` with `n = 180`,
`beta_mu = (0.25, 0.55)`, `beta_sigma = (log(0.65), 0.20)`,
`rho(x, w) = 0.20`, and `nu_slope = 0`. The two cells differ only in the
`nu` intercept: the low-boundary cell has `nu(w = 0) = 2.8`, and the ordinary
cell has `nu(w = 0) = 8`.

**Estimands.** Formula-scale fixed effects for `mu`, `sigma`, and `nu`; the
diagnostic target is the fitted `student_nu` status, value, and message
reported by `check_drm()`.

**Methods.** Each replicate fits `drmTMB(..., family = student())` through the
existing Phase 18 Student-t shape runner. No external comparator is fitted
because this pilot asks whether drmTMB's own finite-variance diagnostic is
visible in the simulation artifacts.

**Performance measures.** The committed summaries report convergence rate,
`pdHess` rate, warning rate, `student_nu` warning/error/note/ok rates, bias,
RMSE, and MCSE columns produced by the existing Phase 18 summariser.

## Files

- `run-pilot.R`: reproducible runner.
- `student-nu-boundary-run-summary.csv`: one-row headline summary.
- `session-info.txt`: R session information.
- `tables/student-nu-conditions.csv`: simulation cells.
- `tables/student-nu-fit-status.csv`: one row per fitted replicate.
- `tables/student-nu-status-summary.csv`: cell-level diagnostic rates.
- `tables/student-nu-parameter-aggregate.csv`: parameter-level bias/RMSE.
- `tables/student-shape-*.csv`: standard tables from the Phase 18 Student-t
  shape writer, including manifest, failures, replicate estimates, Wald
  intervals, interval evidence, interval diagnostics, and interval failures.

The raw per-replicate RDS files are generated transiently by the runner and
deleted before the artifact is committed.

## Conditions

| Cell | Label | n | `nu(w = 0)` | `nu` slope | `sigma` slope | `rho(x, w)` |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| student_shape_001 | low_nu_boundary | 180 | 2.8 | 0.00 | 0.20 | 0.20 |
| student_shape_002 | ordinary_nu | 180 | 8.0 | 0.00 | 0.20 | 0.20 |

Each cell uses 25 replicates, for 50 fitted models.

## Results

The run attempted 50 fits. The minimum convergence rate was 0.92, the minimum
`pdHess` rate was 0.88, and the maximum warning rate was 0.08.

| Cell | `student_nu` ok | warning | error | note | warning rate | error rate | note rate |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| low_nu_boundary | 17 | 5 | 3 | 0 | 0.20 | 0.12 | 0.00 |
| ordinary_nu | 15 | 0 | 0 | 10 | 0.00 | 0.00 | 0.40 |

The low-boundary cell produced finite-variance-boundary warnings and non-finite
or invalid `nu` errors, which is the expected stress signal for a model that
deliberately fits only `nu > 2`. The ordinary cell produced no warnings or
errors, but some fits received Gaussian-tail notes when the fitted `nu` moved
toward a high-degree-of-freedom limit.

Interpretation: the Student-t shape simulation artifacts now carry the
diagnostic surface needed for a future larger guard-sensitivity study. This
pilot is too small for interval calibration, coverage language, or promotion
language.

## Boundary

This artifact covers only fixed-effect Student-t shape models with
`bf(y ~ x, sigma ~ z, nu ~ w)`. It does not test random effects, bivariate
responses, structured effects, Julia bridge behavior, profile/bootstrap
interval calibration, stress data generated with true `nu <= 2`, external
comparators, speed, release readiness, or CRAN readiness.

The reporting follows the ADEMP framing from Morris, White, and Crowther (2019)
and the simulation-reporting discipline in Williams et al. (2024).
