# After-Task: Numerical-Guard ADEMP Design Refresh

Date: 2026-06-17

## Purpose

Hao Qin's concern about constants and truncation-like guards is a real
simulation question, not something the project should dismiss with a coding
explanation. This slice turns that concern into a concrete guard-sensitivity
design contract for the later big simulations.

## Changes

- Expanded `docs/design/176-numerical-guard-simulation-audit.md` with an
  ADEMP plan following Morris, White & Crowther (2019) and the Williams et al.
  (2024) transparent simulation-reporting checklist.
- Added explicit aims, DGP lanes, estimands, methods, performance measures,
  MCSE tiers, and a Williams 11-item self-audit.
- Added a constant-classification rule so ordinary mathematical constants,
  legal parameter-space transforms, support floors, tail floors,
  likelihood-altering guards, and starting-value floors are not collapsed into
  one category.
- Refreshed `docs/dev-log/dashboard/status.json` and
  `docs/dev-log/dashboard/sweep.json` so mission control shows the ADEMP design
  as banked while keeping broader guard-class simulations, interval
  consequences, and release readiness planned.
- Added a check-log entry under
  `2026-06-17 -- Numerical-guard ADEMP design refresh`.

## Evidence

The design now requires future guard simulations to record package SHA, dirty
state, OS, R/package versions, seeds, optimizer settings, guard setting, guard
activation when detectable, estimates, standard errors, log likelihood,
objective, AIC/BIC, convergence, `pdHess`, gradient diagnostics, warnings,
failures, elapsed time, intervals, and Monte Carlo standard errors.

The first fixed-effect Gaussian `log(sigma)` clamp pilot remains the only
banked numerical result. This slice does not add new simulation evidence.

## Boundary

This is a design, dashboard, check-log, and after-task slice only. It does not
change `src/drmTMB.cpp`, the Gaussian clamp, any likelihood, any optimizer
path, Claude-owned Ayumi work, DRM.jl code, or public release/readiness claims.

The intended user-facing rule remains: a numerical guard can prevent overflow
or singular covariance evaluations, but it does not upgrade convergence,
Hessian, interval, or inference claims unless sensitivity simulations show
negligible impact in the intended operating range.

## Next Steps

1. Open or update the issue-led guard-sensitivity tracker, likely `drmTMB#59`,
   with the ADEMP contract and the distinction between design evidence and
   simulation evidence.
2. Implement the next executable guard lane as a small Phase 18/19 artifact,
   not as a broad all-guard grid.
3. For each guard class, add a pilot before any promotion grid: correlation
   guards, Student-t finite-variance shape, support floors, skew-normal tail
   floor, `log(sigma)` guard extensions, and starting-value floors.
