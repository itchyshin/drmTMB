# After Task: Q-Series spatial NB2 count-slope Rorqual top-up recovery

## 1. Goal

Use the connected Rorqual/DRAC lane for one narrow non-Gaussian recovery
top-up: the fixed-covariance spatial NB2 q1 `mu` one-slope row whose original
count-slope cluster run retained a 2/80 `pdHess = FALSE` caveat.

## 2. Implemented

This promotes exactly no Q-Series row under the non-Gaussian count q1 `mu`
one-slope recovery-only channel. It records a Rorqual SLURM job `14936279`
top-up for `qseries_spatial_nbinom2_q1_mu_one_slope`.

The top-up itself has 80/80 fit_ok, 0 nonconverged rows, 0/80 `pdHess =
FALSE`, and 80/80 finite estimates. Combined with the original Rorqual array
`14916938`, the retained denominator is 160/160 fit_ok, 0 nonconverged rows,
2/160 `pdHess = FALSE`, and 160/160 finite estimates.

Mission control now reads the one-row top-up sidecar before the older
count-slope cluster sidecar for widget display. The spatial NB2 count-slope
row is therefore `cluster_confirmed_recovery_only` in the non-Gaussian recovery
rollup, while the original array sidecar remains unchanged as provenance.
Intervals and coverage stay `unsupported/planned`.

## 3a. Decisions and Rejected Alternatives

Decision: keep this as recovery-only evidence. The top-up is useful because it
shows the original spatial NB2 count-slope Hessian caveat is not persistent
across the next retained seed window, but it is not an interval route and not a
coverage denominator.

Decision: leave the original
`structured-re-count-slope-cluster-recovery-results.tsv` row as a historical
`cluster_recovery_caveat`. The new top-up sidecar supersedes display state
through the rollup, not by rewriting the original array evidence.

Rejected alternatives:

- Do not call the row `inference_ready`.
- Do not promote non-Gaussian intervals, coverage, `supported`, REML,
  AI-REML, q2/q4 count covariance, bridge support, high-q readiness,
  structured count sigma, zero-inflation, labelled/multiple count slopes,
  count-scale routes, or public support.
- Do not use failed staging job `14935975` or cancelled staging job `14936258`
  as fit evidence.
- Do not generalize this one spatial NB2 top-up to other non-Gaussian rows.

## 4. Files Touched

- `tools/slurm/count-slope-recovery-rorqual.sbatch`
- `docs/dev-log/dashboard/structured-re-count-slope-spatial-nb2-topup-recovery-results.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-recovery-rollup.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-count-slope-spatial-nb2-topup-rorqual/`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-count-slope-spatial-nb2-topup-recovery.md`

## 5. Checks Run

- Rorqual SLURM job `14936279`: completed with `State: COMPLETED (exit code
  0)` and runner exit code 0. `seff` reported 00:02:02 wall time and 3.17 GB
  memory.
- Top-up artifact summary: 80/80 fit_ok, 0 fit errors, 0 nonconverged rows,
  0/80 `pdHess = FALSE`, and 80/80 finite estimates.
- Combined original-plus-top-up denominator: 160/160 fit_ok, 0 nonconverged
  rows, 2/160 `pdHess = FALSE`, and 160/160 finite estimates.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `python3 tools/validate-mission-control.py`: passed with
  `mission_control_ok`, including 104 structured RE Q-Series cells, 37
  non-Gaussian status-audit rows, 18 non-Gaussian recovery-rollup rows, and 1
  count-slope spatial NB2 top-up recovery row.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 7,996 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-count-slope-spatial-nb2-topup-recovery.md')"`:
  passed with `after-task structure check passed`.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed; the dashboard was already listening at `http://127.0.0.1:8765/`.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt` returned
  `r131`, the top-up TSV served 2 lines including the header, and the served
  non-Gaussian recovery rollup shows the spatial NB2 slope row as
  `cluster_confirmed_recovery_only` with `2/160 pdHess false`.

## 6. Tests of the Tests

The focused test now requires the non-Gaussian rollup to have exactly 17
`cluster_confirmed_recovery_only` rows and 1 `cluster_recovery_caveat` row. It
also requires the spatial NB2 count-slope row to cite Rorqual job `14936279`,
retain the combined 2/160 `pdHess = FALSE` signal, keep 0/80 `pdHess = FALSE`
in the top-up sidecar, and keep `unsupported/planned` interval and coverage
status.

Mission control repeats those checks and validates the top-up sidecar schema,
local artifact path, no-promotion wording, support-cell source text, audit
row, and rollup display precedence.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is a local
mission-control evidence update inside the active Q-Series board.

## 8. Consistency Audit

Checked the top-up sidecar, original count-slope cluster sidecar,
non-Gaussian recovery rollup, non-Gaussian status audit, Q-Series support-cell
TSV, dashboard README, dashboard build/version, mission-control validator, and
focused test file.

Stale-wording scans used:

- `rg -n "16 confirmed|2 caveat|16.*confirmed|2.*caveat|cluster_recovery_caveat|14936279|14935975|14936258|spatial NB2" docs/dev-log/dashboard docs/dev-log/after-task tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`
- `rg -n "count-slope.*spatial.*nbinom2|spatial-nbinom2|qseries_spatial_nbinom2_q1_mu_one_slope" docs/dev-log/dashboard tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`

The live dashboard sources now say 17 confirmed non-Gaussian recovery-only rows
and 1 retained non-Gaussian recovery caveat. Historical after-task reports were
left intact because they were true when written; the new report supersedes them
for current state.

## 9. What Did Not Go Smoothly

Two Rorqual staging attempts were intentionally not used as evidence. Job
`14935975` failed before useful fit evidence because the staged source lacked
the compiled `drmTMB.so`; job `14936258` was cancelled before running while I
replaced the staging bundle. The clean top-up was job `14936279`.

The first artifact listing looked sparse because I only listed three directory
levels. A full artifact walk confirmed the expected logs, metadata,
`sessionInfo.txt`, `git-sha.txt`, `module-list.txt`, scheduler output, `seff`,
run log, and raw replicate/summary TSVs.

## 10. Known Residuals

The spatial NB2 count-slope row is recovery-confirmed only. It still has no
count-specific interval route, no coverage denominator, no MCSE-calibrated
interval grid, no bridge support, no q2/q4 count covariance evidence, no REML,
no AI-REML, and no public support claim.

The combined denominator still records 2/160 `pdHess = FALSE` from the
original array. That is acceptable for recovery-grade display here, but it is
not acceptable as interval or coverage evidence.

## 11. Team Learning

For narrow DRAC top-ups, keep the old cluster sidecar immutable as provenance
and add a one-row override sidecar for display precedence. That preserves the
audit trail, lets the widget reflect stronger evidence, and keeps recovery,
stability, interval, and coverage as separate signals.
