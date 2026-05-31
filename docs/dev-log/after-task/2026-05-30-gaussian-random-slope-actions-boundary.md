# After Task: Gaussian Random-Slope Actions Boundary

## Goal

Close the #439 documentation ambiguity about where ordinary Gaussian
random-slope simulation smoke grids run in the Phase 18 Actions machinery.

## Implemented

- `inst/sim/README.md` now states that the ordinary Gaussian `mu` q=3 and
  independent `sigma` random-slope smoke grids are included in the first-wave
  summary runner.
- The Actions-dispatch paragraph now says standalone random-slope tasks outside
  the first-wave summary are manual-only and excluded from `task = "all"`.

## Boundary

No simulation code, workflow matrix, likelihood, parser, or support registry
changed. This slice documents the existing dispatch route only. It does not
make a recovery, power, accuracy, coverage, or cross-platform robustness claim.

## Validation

Validation is recorded in `docs/dev-log/check-log.md` for 2026-05-30. The
checks covered positive wording scans, stale broad-random-slope scans, and diff
hygiene.
