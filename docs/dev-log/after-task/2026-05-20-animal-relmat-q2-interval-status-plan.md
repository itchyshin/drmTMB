# After Task: Animal/Relmat Q2 Interval-Status Plan

## Task Goal

Create a design gate for interval-status artifacts before adding interval CSVs
to the known-matrix `animal()`/`relmat()` q=2 Phase 18 grid. The goal was to
decide which rows can use Wald intervals, which rows need opt-in profiles,
which rows are known inputs, and how failed profiles should be reported.

## Files Created Or Changed

- `docs/design/55-phase-18-animal-relmat-q2-interval-status.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-20-animal-relmat-q2-interval-status-plan.md`

## Checks Run

Checks run:

```sh
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
rg -n 'interval coverage waits|formal-condition runner with interval status|interval artifact code remains' docs/design
```

Outcomes:

- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.
- The targeted wording scan found the expected readiness and code-availability
  rows only.

## Consistency Audit

The plan keeps known matrices out of interval rows, fixed `mu1`/`mu2`
coefficients on the Wald formula-coefficient path, public residual
`sigma1`/`sigma2` as not requested for the first interval artifact, and
structured SDs, structured correlations, and residual `rho12` on opt-in direct
profile routes.

## Tests Of The Tests

No executable tests were added in this slice. The next code slice should add
tests that unrequested interval rows remain visible, requested profile rows
produce standard interval-evidence artifacts, and failed profiles are counted
as interval-method failures rather than model-estimation failures.

## What Did Not Go Smoothly

No blocker. The main risk is future overclaiming: a grid writer can make files
look official even when interval routes have not been requested or have failed.

## Team Learning And Process Improvements

Fisher and Noether should keep interval-status design separate from DGP design
for boundary-sensitive structured effects. Rose should continue to check that
failed profiles stay in interval diagnostics rather than disappearing from
coverage denominators.

## Design-Doc Updates

The Phase 18 programme, readiness matrix, and ADEMP sheet now point to the new
interval-status plan. The plan itself states the next implementation order for
optional profile parameters, Wald fixed-effect rows, profile interval rows,
interval-evidence tables, and interval-failure tables.

## Pkgdown And Documentation Updates

No pkgdown article or reference page was added. This is a design note under
`docs/design`.

## GitHub Issue Maintenance

This slice remains part of issue #147. The PR should reference that issue after
the branch is pushed.

## Known Limitations And Next Actions

The next code step is to add optional profile parameters and interval-evidence
CSV artifacts to the q=2 animal/`relmat()` grid writer while keeping profiling
off by default in CRAN-facing tests.
