# After Task: Q-Series Non-Gaussian Recovery Rollup

## 1. Goal

Make non-Gaussian count recovery evidence visible as a separate row-level
signal in the Q-Series widget while keeping recovery distinct from inference,
interval readiness, coverage readiness, and support.

## 2. Implemented

This promotes exactly no support cell. I added
`structured-re-nongaussian-recovery-rollup.tsv`, an 18-row recovery-grade
ledger for Poisson/NB2 count `mu` rows. The rollup records three
`cluster_confirmed_recovery_only` rows from Rorqual SLURM job `14897050`,
fourteen `local_recovery_only` rows, and one
`local_recovery_hessian_caveat` row for the fixed-covariance spatial NB2
one-slope row.

The Q-Series widget now has a separate `Recovery` column beside `Stability` and
`Inference`. The three Rorqual-confirmed count-intercept rows in the source
support-cell TSV now point at the Rorqual top-up artifact and explicitly state
the recovery-only boundary. The local rollup-linked count `mu` source rows now
name the recovery sidecar instead of stale "add recovery evidence" gates. The
fixed-covariance spatial NB2 one-slope row carries the retained
`2/80 pdHess false` caveat in both source and non-Gaussian audit tables. Their
status fields remain `fit_status = point_fit`, `interval_status = unsupported`,
and `coverage_status = planned`.

## 3a. Decisions and Rejected Alternatives

I kept the new rollup display-only and validation-owned rather than changing
the interval or coverage state of any non-Gaussian row. Recovery evidence is
useful for the board, but it is not coverage evidence and does not define an
interval route.

Rejected alternatives: I did not call the three Rorqual rows
`inference_ready`, did not mark any non-Gaussian interval as feasible, did not
collapse the old caveat diagnostics, and did not hide the spatial NB2 slope
`pdHess` caveat inside a generic recovery-only bucket.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-recovery-rollup.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-nongaussian-recovery-rollup.md`

## 5. Checks Run

```sh
/opt/homebrew/bin/air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
node --check /tmp/drmtmb-dashboard-script.js
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/version.txt
curl -fsS http://127.0.0.1:8765/structured-re-nongaussian-recovery-rollup.tsv
R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-nongaussian-recovery-rollup.md')"
```

Results: mission control passed with 18 non-Gaussian recovery-rollup rows;
dashboard JavaScript syntax passed; the focused structured-RE conversion test
passed with 6381 PASS / 0 FAIL / 0 WARN / 0 SKIP; `git diff --check` passed;
the after-task structure check passed; and the served dashboard reported build
`r96`.

## 6. Tests of the Tests

The validator now checks the rollup schema, exact 18-row cell set, exact grade
counts, support-cell status links, evidence URLs, recovery-only claim phrases,
stale support-cell recovery gates, and the retained `2/80 pdHess false` Hessian
caveat. The focused test mirrors the same contract and verifies that the three
Rorqual rows still have `interval_status = unsupported` and `coverage_status =
planned` in the source support-cell TSV.

## 7a. Issue Ledger

No GitHub issue action was taken. This slice updates local mission-control
evidence and widget routing only; it does not create a public support claim.

## 8. Consistency Audit

The 104-row Q-Series table still has 5 interval+coverage `inference_ready`
rows, 40 `unsupported` interval rows, and 78 `planned` coverage rows. The new
Recovery column displays recovery grades without changing those inference
counts. The dashboard README, check-log, validator, focused test, and served
dashboard build all name the same 3/14/1 recovery split.

Fisher reviewed the evidence path and recommended these exact Rorqual-confirmed
count-intercept rows as the safest next recovery-only tranche. Rose's read-only
audit found stale support-cell recovery gates and one under-propagated Hessian
caveat; both are now fixed and guarded by mission control.

## 9. What Did Not Go Smoothly

The first attempted test patch used the wrong local context and had to be split
into smaller inserts. Rose then caught two status-surface drifts: local
recovery rows still carrying "add recovery evidence" gates, and the spatial NB2
slope Hessian caveat not appearing outside the rollup. The dashboard refresh
command also stayed attached even after the server was already healthy; I
stopped that shell after confirming `r96` was being served.

## 10. Known Residuals

Non-Gaussian interval and coverage evidence are still absent. The rollup does
not solve the count-specific interval route, q2/q4 covariance, count sigma,
zero-inflation, bridge parity, REML, AI-REML, or public support. The spatial NB2
one-slope recovery row keeps a local Hessian caveat and needs primary-cluster
top-up or diagnosis before public recovery wording.

## 11. Team Learning

Recovery needs its own first-class board signal. Mixing recovery into row state
alone makes it too easy to read point-estimation evidence as inference
readiness. The widget should continue showing Stability, Recovery, Inference,
Interval, and Coverage as separate columns whenever row-level evidence is being
triaged.
