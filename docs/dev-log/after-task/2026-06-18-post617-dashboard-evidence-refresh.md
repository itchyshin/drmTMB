# Post-#617 Dashboard Evidence Refresh

## Task

Refresh mission-control current-state evidence after PR #617 merged and its
post-merge main gates passed. The goal was to remove the stale post-#615 Grace
evidence row and record the current `main` SHA, R-CMD-check run, and pkgdown
run for the Student-t guard-ledger sync.

## What Changed

`docs/dev-log/dashboard/status.json` and `docs/dev-log/dashboard/sweep.json`
now report `updated = "2026-06-18 01:46 MDT"`. The dashboard metrics remain
unchanged: 25/68 banked or verified, 1 active, 0 blocked, and 1 deferred.

The Grace active-work row now records the post-#617 evidence: `main` at
`c57160a`, R-CMD-check run `27742727979` passed on macOS, Ubuntu, and Windows,
and pkgdown run `27744058133` built and deployed. The active finish-board row
remains `drmTMB#59` numerical-guard sensitivity.

## Verification

This dashboard evidence refresh passed JSON validation for `status.json` and
`sweep.json`, `python3 tools/validate-mission-control.py`, `git diff --check`,
`Rscript -e "pkgdown::check_pkgdown()"`, and a served dashboard smoke test at
`http://127.0.0.1:8765/status.json`.

The boundary scan found only intentional or pre-existing boundary wording in
the checked files. No new release-readiness, CRAN-readiness, coverage, power,
calibrated-interval, Julia-bridge-control, or non-Gaussian AI-REML claim was
added.

## Boundaries

Dashboard and check-log evidence only. No R runtime API, TMB likelihood,
formula grammar, simulation result, mission-control metric, coverage claim,
power claim, release-readiness claim, CRAN-readiness claim, or Julia bridge
behavior changed.
