# After Task: Q-Series Tranche 3 q4 Location Target Admission Map

## 1. Goal

Bank the exact target-level q4 location admission map before any coverage work.
The map should connect each direct-SD `profile_targets()` name to the existing
SR475 retained-denominator evidence and keep the no-admission decision visible.

## 2. Implemented

Added `structured-re-q4-location-target-admission-map.tsv` with 16 rows: four
direct-SD endpoint members for each of `phylo()`, fixed-covariance
`spatial()`, A-matrix `animal()`, and K-matrix `relmat()`. Each row records the
exact `profile_targets()` name, the dispatch-plan row, the interval-diagnostic
row, the SR475 q4-location coverage-source row, finite Wald/profile counts,
admission decision, coverage decision, promotion decision, and the
Rose/Fisher/Gauss/Noether no-claim guard.

Mission Control now loads the sidecar, shows a `Q4 target map` summary card,
and renders the target-level map under Structured RE contracts. The validator
and focused R tests cross-check every row against the dispatch plan, interval
status, and SR475 source rows.

No support-cell status changed. The map admits zero q4 targets and authorizes
zero coverage work.

## 3a. Decisions and Rejected Alternatives

I kept this as a target-level admission map rather than a new runner or cluster
job. The SR475 source rows already show the blocker: finite-Wald/pdHess survivor
rates range from 0.514 to 0.775 for the q4 location provider cells, below the
95% admission gate. Launching coverage from that state would treat censored
survivor evidence as interval reliability.

I included profile-finite rates even when they look high for some intercept
targets, because they are conditional on the same retained denominator and do
not override the failed pdHess/Wald survivor gate.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-target-admission-map.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche3-q4-location-target-admission-map.md`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`:
  passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}' docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js && node --check /tmp/drmtmb-dashboard-index.js`:
  passed.
- `git diff --check`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series support cells, 14
  q4 admission-denominator contract rows, 14 q4 admission-review synthesis
  rows, and 16 q4 location target-admission map rows.
- `air format tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed `10692 PASS / 0 FAIL / 0 WARN / 0 SKIP`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche3-q4-location-target-admission-map.md')"`:
  passed.

## 6. Tests of the Tests

The new validator and R test are source-linked: they require the target map to
match the exact dispatch-plan `profile_target`, interval-status diagnostic ID,
SR475 coverage ID, finite counts, rates, and no-coverage/no-promotion decisions.
Changing the map without updating the source evidence should fail validation.

## 7a. Issue Ledger

No GitHub issue was opened or closed. This is a local Mission Control evidence
artifact for the active Q-Series Tranche 3 lane.

## 8. Consistency Audit

The sidecar keeps the same four q4 location support cells as the Tranche 3
admission review and expands them to the 16 direct-SD targets already named by
the q4 location bootstrap dispatch plan. It does not add derived-correlation
targets, q8-shaped rows, all-four intercept rows, or ordinary comparator rows.

All rows have `coverage_decision = coverage_not_authorized` and
`promotion_decision = do_not_promote`. The claim boundary repeats no
`inference_ready`, no `supported`, no q4 REML, no REML, no AI-REML, no q8
inference, no derived-correlation interval claim, no broad bridge support, and
no public support.

## 9. What Did Not Go Smoothly

The q4 location evidence is awkward because the historical SR475 file is named
as coverage output, but the current admission question treats it as retained
denominator negative evidence. The new sidecar names that boundary explicitly.

## 10. Known Residuals

This does not supply q4 admission evidence, interval reliability, coverage, or
support. The next scientific step is still a retained-denominator q4 location
admission runner/design that counts every failed fit, pdHess false, profile
warning, boundary, finite direct-SD interval, and unavailable
derived-correlation interval before coverage is even designed.

## 11. Team Learning

For high-q admission work, exact target names should be banked as their own
artifact before any compute route is discussed. That gives Rose, Fisher, Gauss,
and Noether a concrete denominator map to audit without turning the map into a
status claim.
