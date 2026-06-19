# Student-t Nu Wald Calibration Diagnostic

This artifact extends the Student-t finite-variance guard audit with a
larger Wald interval diagnostic for the fixed-effect Student-t shape route.
It uses the existing Phase 18 Student-t shape simulation writer and keeps
the interpretation label at `diagnostic_calibration_pilot`.

The fitted model is `bf(y ~ x, sigma ~ z, nu ~ w)` with
`family = student()`. The Student-t shape is parameterized as
`nu = 2 + exp(eta_nu)`, so the fitted model is deliberately finite-variance
and does not include `nu <= 2`.

## ADEMP Summary

**Aim.** Quantify whether the Student-t finite-variance diagnostic remains
visible in a 100-replicate-per-cell Wald interval pilot, and record the
first MCSE-backed Wald interval consequences for ordinary and low-`nu`
fixed-effect cells.

**Data-generating mechanism.** Each replicate uses `n = 180`,
`beta_mu = (0.25, 0.55)`, `beta_sigma = (log(0.65), 0.20)`,
`nu_slope = 0`, and `rho(x, w) = 0.20`. The two cells differ only in
`nu(w = 0)`: 2.8 for the low-boundary cell and 8.0 for the ordinary cell.

**Estimands.** Formula-scale fixed effects for `mu`, `sigma`, and `nu`,
with `student_nu` status/value/message rows from `check_drm()` retained
beside interval status.

**Methods.** Each replicate fits `drmTMB(..., family = student())` through
the existing Phase 18 Student-t shape runner. This diagnostic uses Wald
intervals only. Profile and bootstrap intervals are intentionally absent
from this slice.

**Performance measures.** The committed tables report convergence,
`pdHess`, warning, `student_nu` status rates, Wald interval success, Wald
coverage, MCSE, interval width, missed intervals, and unusable intervals.

## Files

- `run-pilot.R`: reproducible runner.
- `student-nu-wald-calibration-run-summary.csv`: one-row headline summary.
- `session-info.txt`: R session information.
- `tables/student-nu-calibration-conditions.csv`: simulation cells.
- `tables/student-nu-calibration-fit-status.csv`: one row per fitted replicate.
- `tables/student-nu-calibration-status-summary.csv`: diagnostic status rates.
- `tables/student-nu-wald-diagnostics.csv`: Wald interval diagnostics for all parameters.
- `tables/student-nu-wald-shape-diagnostics.csv`: Wald interval diagnostics for `nu` terms.
- `tables/student-shape-*.csv`: standard Phase 18 Student-t shape artifact tables.

The raw per-replicate RDS files are generated transiently by the runner and
deleted before the artifact is committed.

## Conditions

| Cell | Label | n | `nu(w = 0)` | `nu` slope | `sigma` slope | `rho(x, w)` |
| --- | --- | --- | --- | --- | --- | --- |
| student_shape_001 | low_nu_boundary | 180 | 2.800 | 0.000 | 0.200 | 0.200 |
| student_shape_002 | ordinary_nu | 180 | 8.000 | 0.000 | 0.200 | 0.200 |

Each cell uses 100 replicates, for 200 fitted models.

## Results

The run attempted 200 fits. The minimum convergence rate was 0.910, the minimum `pdHess` rate was 0.890, and the maximum `student_nu` warning rate was 0.230.

| Cell | Fits | Converged | `pdHess` | `student_nu` ok | `student_nu` warning | `student_nu` error | `student_nu` note |
| --- | --- | --- | --- | --- | --- | --- | --- |
| low_nu_boundary | 100 | 0.910 | 0.900 | 0.660 | 0.230 | 0.110 | 0.000 |
| ordinary_nu | 100 | 0.920 | 0.890 | 0.640 | 0.080 | 0.030 | 0.250 |

Wald interval diagnostics for the shape terms:

| Cell | Parameter | Replicates | Usable intervals | Coverage | Coverage MCSE | Interval success | Interval failure | Missed | Unusable |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| low_nu_boundary | nu:(Intercept) | 100 | 90 | 0.870 | 0.034 | 0.900 | 0.100 | 3 | 10 |
| low_nu_boundary | nu:w | 100 | 90 | 0.900 | 0.030 | 0.900 | 0.100 | 0 | 10 |
| ordinary_nu | nu:(Intercept) | 100 | 89 | 0.890 | 0.031 | 0.890 | 0.110 | 0 | 11 |
| ordinary_nu | nu:w | 100 | 89 | 0.890 | 0.031 | 0.890 | 0.110 | 0 | 11 |

The low-boundary cell keeps the finite-variance warning/error surface
visible and loses more usable intervals than the ordinary cell. The ordinary
cell has higher interval availability but still carries Gaussian-tail notes
when fitted `nu` moves toward a high-degree-of-freedom limit. These results
are useful for prioritizing future Student-t profile/bootstrap work, but the
replicate count and Wald-only interval method are not a promotion gate.

## Boundary

This artifact covers only fixed-effect Student-t shape models with
`bf(y ~ x, sigma ~ z, nu ~ w)`. It does not test random effects, bivariate
responses, structured effects, true `nu <= 2` misspecification stress,
profile/bootstrap intervals, external comparators, speed, Julia bridge
behavior, release readiness, CRAN readiness, or non-Gaussian REML/AI-REML.

The reporting follows the ADEMP framing from Morris, White, and Crowther
(2019) and the simulation-reporting discipline in Williams et al. (2024).
