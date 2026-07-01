# After Task: Q-Series count-slope Rorqual recovery reproduction

## 1. Goal

Record primary-cluster recovery evidence for the eight non-Gaussian Poisson/NB2
q1 `mu` one-slope Q-Series rows without promoting intervals, coverage,
`inference_ready`, or `supported`.

## 2. Implemented

This promotes exactly no Q-Series row under the non-Gaussian count q1 `mu`
one-slope recovery-only channel, with Rorqual SLURM array 14916938 and 80
replicates per provider-family row. It does not claim `interval_status`,
`coverage_status`, `inference_ready`, `supported`, REML, AI-REML, q2/q4 count
covariance, high-q readiness, bridge support, structured count sigma,
zero-inflation, labelled/multiple count slopes, count scale routes, or public
support.

Added `tools/slurm/count-slope-recovery-rorqual.sbatch` and
`tools/summarize-structured-re-count-slope-cluster-recovery.R`. The fetched
Rorqual artifacts live under
`docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual/`,
and the dashboard sidecar is
`docs/dev-log/dashboard/structured-re-count-slope-cluster-recovery-results.tsv`.

Seven rows are `cluster_confirmed_recovery_only`: phylo Poisson, phylo NB2,
spatial Poisson, animal Poisson, animal NB2, relmat Poisson, and relmat NB2.
The fixed-covariance spatial NB2 one-slope row remains
`cluster_recovery_caveat` because the Rorqual run reproduced 2/80 `pdHess =
FALSE`. All eight rows keep `interval_status = unsupported` and
`coverage_status = planned`.

Mission control now reads the cluster sidecar, prefers it over the older local
count-slope recovery sidecar for board state, and keeps the separate recovery
grade visible. The top cards now report 10 cluster-confirmed non-Gaussian
recovery rows, 7 local-only recovery rows, and 1 recovery caveat. The dashboard
build is `r120`.

## 3a. Decisions and Rejected Alternatives

Decision: use Rorqual as the primary-cluster reproduction layer for this
non-Gaussian recovery slice. FIIA/Totoro remain rehearsal lanes, and the
cluster output is still recovery-only evidence.

Decision: keep the support-cell `evidence_url` pointing at
`tests/testthat/test-count-structured-mu.R`, because that field owns the native
point/extractor fixture evidence. The Rorqual artifact is linked through the
cluster sidecar, rollup, claim boundary, and widget recovery link.

Rejected alternatives:

- Do not call the eight count-slope rows `inference_ready`.
- Do not treat the seven clean Rorqual rows as interval or coverage evidence.
- Do not hide the spatial NB2 `pdHess` caveat inside a clean recovery bucket.
- Do not let count-slope recovery evidence spill into count intercept, count
  sigma, zero-inflation, q2/q4 count covariance, Gaussian, REML, AI-REML, or
  public support claims.

## 4. Files Touched

- `tools/slurm/count-slope-recovery-rorqual.sbatch`
- `tools/summarize-structured-re-count-slope-cluster-recovery.R`
- `docs/dev-log/dashboard/structured-re-count-slope-cluster-recovery-results.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-recovery-rollup.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual/`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-count-slope-cluster-recovery.md`

## 5. Checks Run

- Rorqual SLURM array 14916938: completed all eight tasks with exit code 0;
  each runner log records `runner_exit_code=0`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-count-slope-cluster-recovery.R --artifact_dir=docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual/results/count-slope-recovery-rorqual --output=docs/dev-log/dashboard/structured-re-count-slope-cluster-recovery-results.tsv --evidence_url=docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual --cluster_job_id=14916938 --expected_rows=8`:
  passed and wrote 8 rows.
- `/opt/homebrew/bin/air format tests/testthat/test-structured-re-conversion-contracts.R tools/summarize-structured-re-count-slope-cluster-recovery.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Dashboard JavaScript parse check from extracted `index.html` script:
  passed with `node --check /tmp/drmtmb-dashboard-index.js`.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series cells,
  37 non-Gaussian status-audit rows, 18 non-Gaussian recovery-rollup rows, 8
  count-slope local recovery rows, and 8 count-slope cluster recovery rows.
- First focused test run:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`
  failed with two stale aggregate expectations: 18 clean non-Gaussian recovery
  rows and 0 caveats.
- Second focused test run after updating the aggregate expectation:
  7485 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-count-slope-cluster-recovery.md')"`:
  passed.
- `find docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual -type d -exec chmod u+rwx,go+rx,g-s {} +` and
  `find docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual -type f -exec chmod u+rw,go+r {} +`:
  normalized fetched Rorqual artifact permissions for local dashboard serving;
  raw artifact contents were unchanged.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed after permission normalization; the dashboard was already listening at
  `http://127.0.0.1:8765/`.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt` returned
  `r120`, `structured-re-count-slope-cluster-recovery-results.tsv` served 9
  lines including the header, and `/` contained `Cluster recovery`,
  `Recovery caveat`, and
  `structured-re-count-slope-cluster-recovery-results.tsv`.

## 6. Tests of the Tests

The new focused test requires exactly eight count-slope cluster recovery rows,
the Rorqual array 14916938 claim boundary, 80/80 fit_ok, 0 fit errors, 0
nonconverged rows, 80/80 finite estimates, linked support-cell
`unsupported/planned` status, seven clean `cluster_confirmed_recovery_only`
rows, and one spatial NB2 `cluster_recovery_caveat` row with 2/80 `pdHess
false`.

Mission control repeats those checks and also validates the sidecar schema,
evidence URL, support-cell/audit/rollup consistency, and no-promotion wording.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence and Rorqual artifact ingestion inside the active
Q-Series board.

## 8. Consistency Audit

Checked the cluster sidecar, non-Gaussian recovery rollup, non-Gaussian status
audit, support-cell TSV, dashboard renderer, dashboard README, mission-control
validator, and focused test file.

The board remains 104 rows with exactly five interval-and-coverage
`inference_ready` rows and no structured `supported` row. Non-Gaussian rows
remain point/recovery/rejection/design evidence only.

## 9. What Did Not Go Smoothly

The first Rorqual staging attempt submitted array 14916814 against an
incomplete source tree and failed because `drmTMB.so` was unavailable. I
cancelled that array, restaged a minimal source tarball into a fresh run root,
removed AppleDouble `._*` files, and submitted array 14916938, which completed.

The fetched Rorqual artifact directories retained restrictive group/setgid
permissions. The mission-control server could validate the TSVs but initially
could not copy the artifact tree into `/tmp/drm-dashboard`. I normalized local
permissions on that fetched artifact tree only, then restarted the dashboard.

The first focused test rerun also caught stale aggregate expectations from the
old local-only recovery table. That was useful: the row-level logic was right,
but the summary counts still assumed no recovery-caveated non-Gaussian row.

## 10. Known Residuals

The spatial NB2 count q1 `mu` one-slope row retains a Hessian caveat. None of
the count-slope rows has a count-specific interval route, coverage denominator,
MCSE-calibrated interval grid, bridge support, REML, AI-REML, or public support
claim.

Non-Gaussian q2/q4, count sigma, zero-inflation, labelled/multiple count
slopes, count scale routes, and non-Gaussian interval/coverage claims remain
future arcs.

## 11. Team Learning

Primary-cluster recovery reproductions should land as a separate sidecar that
overrides local display state but preserves the older local artifact. That lets
the widget show stronger evidence without losing the smoke history or blurring
recovery, stability, interval, and coverage into one status.
