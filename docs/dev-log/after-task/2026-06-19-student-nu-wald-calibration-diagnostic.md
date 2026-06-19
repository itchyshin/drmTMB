# After Task: Student-t Nu Wald Calibration Diagnostic

## Goal

Add the next conservative `drmTMB#59` numerical-guard slice by deepening the
fixed-effect Student-t finite-variance boundary pilot with a deterministic
Wald interval diagnostic.

## Implemented

The artifact at
`docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/`
uses the existing Phase 18 Student-t shape simulation writer for
`bf(y ~ x, sigma ~ z, nu ~ w)` with `family = student()`. It runs two cells,
100 replicates per cell, and records fit status, `student_nu` status rows from
`check_drm()`, Wald interval success, Wald coverage, MCSE, missed intervals,
and unusable intervals.

## Mathematical Contract

The fitted Student-t shape remains `nu = 2 + exp(eta_nu)`. This is a
finite-variance model, not support for `nu <= 2`. The two cells use
`nu(w = 0) = 2.8` and `nu(w = 0) = 8.0`, both with `nu_slope = 0`. The slice
therefore tests diagnostic and Wald interval behavior inside the fitted
finite-variance parameter space.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/`
- `docs/design/176-numerical-guard-simulation-audit.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/168-r-julia-finish-capability-matrix.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/run-pilot.R
/usr/local/bin/Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-19-student-nu-wald-calibration-diagnostic/run-pilot.R
```

The artifact run reproduced 200 requested fits. The minimum convergence rate
was 0.91, the minimum `pdHess` rate was 0.89, the maximum `student_nu` warning
rate was 0.23, and the maximum `student_nu` error rate was 0.11. Shape-term
Wald coverage was 0.87-0.90, with coverage MCSE up to 0.03363034 and interval
success rates of 0.89-0.90.

The remaining validation commands are recorded in
`docs/dev-log/check-log.md`.

## Tests Of The Tests

This slice reuses the existing Phase 18 Student-t writer rather than adding a
parallel fitting path. The low-`nu` cell retained the intended stress signal:
`student_nu` warnings and errors stayed visible in the per-fit status table,
and failed or unusable intervals reduced the interval-success denominator.

## Consistency Audit

The design ledger, worklist, finish matrix, dashboard status, dashboard sweep,
and check log all describe the same claim: this is Wald-only diagnostic
calibration evidence for fixed-effect Student-t shape models. It does not
promote Student-t profile/bootstrap intervals, random effects, bivariate
responses, structured effects, true `nu <= 2` stress behavior, Julia bridge
parity, release readiness, CRAN readiness, or non-Gaussian REML/AI-REML.

## GitHub Issue Maintenance

`drmTMB#59` remains the correct umbrella issue. A PR comment should be posted
after CI passes, with the artifact path, key rates, and claim boundary.

## What Did Not Go Smoothly

The first generated run-summary included a dirty-worktree flag because the
artifact was being generated before the new files were committed. The runner
now records the commit SHA but leaves dirty-state reporting to git and CI
evidence.

## Team Learning

Curie's next Student-t slice should move from Wald-only diagnostics to
targeted profile or bootstrap feasibility, not another small Wald rerun. Rose
should keep the finite-variance boundary explicit whenever `nu` results are
summarized.

## Known Limitations

The artifact has 100 replicates per cell, so the MCSE is still too wide for
promotion language. It does not run profile intervals, bootstrap intervals,
external comparators, true infinite-variance stress data, random effects,
structured effects, bivariate responses, or Julia bridge parity.

## Next Actions

After this PR is banked, the next safe Student-t-specific step is a small
profile/bootstrap feasibility diagnostic for the same finite-variance cells.
The broader `drmTMB#59` queue also still includes larger bivariate scale-route
grids, larger skew-normal guard grids, additional random-effect and structured
correlation guard depth, larger scale-side phylogeny grids, and broader
interval consequences.
