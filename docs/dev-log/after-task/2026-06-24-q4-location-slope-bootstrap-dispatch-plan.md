# q4 Location One-Slope Bootstrap Dispatch Plan

## Purpose

This slice turns the q4 location one-slope bootstrap budget result into a
reviewable Totoro/DRAC dispatch manifest without submitting any compute jobs.
The goal is to make the next denominator run auditable before it leaves the
local workstation.

## What Changed

- Added `tools/plan-structured-re-q4-location-slope-bootstrap-dispatch.R`.
- Added
  `docs/dev-log/dashboard/structured-re-q4-location-slope-bootstrap-dispatch-plan.tsv`.
- Added
  `docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-bootstrap-dispatch-plan/structured-re-q4-location-slope-bootstrap-dispatch-target-manifest.tsv`.
- Wired the new sidecar into mission-control validation and the focused
  structured random-effect conversion-contract tests.
- Updated the q-series completion map, dashboard README, and check log.

## Result

The dispatch manifest names all 16 direct-SD q4 location bootstrap targets:
four endpoint members crossed with `phylo()`, fixed-covariance `spatial()`,
A-matrix `animal()`, and K-matrix `relmat()`. It records provider-rotating
shards, planned Totoro/DRAC backends, two bootstrap refits per target, seed
assignments, and retention of failed profiles, nonconverged fits, nonfinite
intervals, bootstrap refit attempts, and scheduler exit status.

Every row remains `scheduler_status = dry_run_not_submitted`,
`compute_status = not_executed`, `denominator_status = dispatch_plan_only`,
and `coverage_evaluable = FALSE`. The representative bootstrap budget source
is explicitly `mu1:(Intercept)`, so the manifest cannot be read as target-level
bootstrap evidence for the remaining 15 targets.

## Evidence

- `Rscript --vanilla tools/plan-structured-re-q4-location-slope-bootstrap-dispatch.R`
  completed and wrote the dashboard sidecar plus target manifest.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 16
  structured RE q4 location slope bootstrap-dispatch plan rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with the new dry-run dispatch contract included.
- `git diff --check` passed.

## Boundary

This is dry-run dispatch planning only. It does not submit Totoro jobs, submit
DRAC jobs, admit all-target bootstrap denominators, promote
derived-correlation intervals, interval reliability, interval coverage, q4
REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML,
broad bridge support, public optimizer controls, public support, partial
location-scale support, Q precision marshalling, K/Q same-target parity,
broader q8 support, SR150 coverage readiness, or an Ayumi-facing reply.

## Next Gate

Review the manifest before execution. If approved, run one provider shard at a
time on Totoro first, or through a reviewed DRAC/totoro submission plan. The
execution artifact must retain every provider/target outcome before any
denominator accounting or coverage-grid design.
