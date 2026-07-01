# After Task: Q-Series count-intercept Rorqual recovery reproduction

## 1. Goal

Record primary-cluster recovery evidence for the ten non-Gaussian Poisson/NB2
q1 count `mu` count-intercept and `phylo_interaction()` Q-Series rows without
promoting intervals, coverage, `inference_ready`, or `supported`.

## 2. Implemented

This promotes exactly no Q-Series row under the non-Gaussian count q1 `mu`
recovery-only channel, with Rorqual SLURM job 14918220 and 80 seed replicates
per row design. It does not claim `interval_status`, `coverage_status`,
`inference_ready`, `supported`, REML, AI-REML, q2/q4 count covariance, high-q
readiness, bridge support, structured count sigma, zero-inflation,
labelled/multiple count slopes, count scale routes, non-Gaussian intervals, or
public support.

Added `tools/summarize-structured-re-count-intercept-cluster-recovery.R`. The
fetched Rorqual artifacts live under
`docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-rorqual/`,
and the dashboard sidecar is
`docs/dev-log/dashboard/structured-re-count-intercept-cluster-recovery-results.tsv`.

The Rorqual sidecar records ten rows. Six rows are
`cluster_confirmed_recovery_only`; four original-grid caveats remain visible
inside the sidecar. Three of those caveats are superseded for widget row state
by the stronger-denominator Rorqual top-up (`qseries_phylo_poisson_q1_mu_intercept`,
`qseries_phylo_nbinom2_q1_mu_intercept`, and
`qseries_spatial_nbinom2_q1_mu_intercept`). The retained new caveat is
`qseries_phylo_interaction_nbinom2_q1_mu`, which had 80/80 fit success, 0
`pdHess = FALSE`, 80/80 finite estimates, and 5/80 boundary-warning rows.

Mission control now reads the count-intercept cluster sidecar, prefers it over
the local count-intercept recovery sidecar unless the stronger top-up supersedes
the row, and keeps the separate recovery grade visible. The recovery rollup now
has 16 `cluster_confirmed_recovery_only` rows and two
`cluster_recovery_caveat` rows. The dashboard build is `r121`.

## 3a. Decisions and Rejected Alternatives

Decision: use Rorqual as the primary-cluster reproduction layer for this
non-Gaussian count-intercept recovery slice. Totoro/FIIA remain smoke lanes,
and the cluster output is still recovery-only evidence.

Decision: keep the ten-row Rorqual cluster sidecar as provenance, even though
the stronger-denominator top-up supersedes three rows for widget row state. The
sidecar is evidence provenance, not a smoothed display table.

Rejected alternatives:

- Do not call any non-Gaussian row `inference_ready`.
- Do not hide the `phylo_interaction()` NB2 boundary-warning caveat.
- Do not let count-intercept recovery evidence spill into count slopes, count
  sigma, zero-inflation, q2/q4 count covariance, Gaussian, REML, AI-REML,
  bridge, or public support claims.

## 4. Files Touched

- `tools/slurm/count-intercept-recovery-rorqual.sbatch`
- `tools/summarize-structured-re-count-intercept-cluster-recovery.R`
- `docs/dev-log/dashboard/structured-re-count-intercept-cluster-recovery-results.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-recovery-rollup.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-rorqual/`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-count-intercept-cluster-recovery.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file
  tools/summarize-structured-re-count-intercept-cluster-recovery.R
  --artifact_dir=docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-rorqual/results/count-intercept-recovery-rorqual/artifacts
  --output=docs/dev-log/dashboard/structured-re-count-intercept-cluster-recovery-results.tsv
  --evidence_url=docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-rorqual
  --cluster_job_id=14918220 --expected_rows=10`: passed; wrote ten rows.
- Stale literal scan for the old Rorqual job id and obsolete seven-row sidecar
  wording: no matches in the checked Q-Series surfaces after the final repair.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- R parse check for
  `tools/summarize-structured-re-count-intercept-cluster-recovery.R` and
  `tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed
  with `mission_control_ok`, including 104 structured RE q-series cells, 37
  structured RE non-Gaussian status-audit rows, 18 structured RE
  non-Gaussian recovery-rollup rows, and 10 structured RE count-intercept
  cluster recovery-results rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 7523 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt`
  returned `r121`; `structured-re-count-intercept-cluster-recovery-results.tsv`
  served 11 lines including the header; the sidecar served 10 `14918220`
  claim-boundary matches; and `/` contained the Q-Series table plus the
  count-intercept cluster sidecar fetch path. After the temporary foreground
  check, a detached `screen` server named `drmtmb-mission-control` was launched
  for the in-app browser and rechecked successfully.

## 6. Tests of the Tests

The new focused test requires exactly ten count-intercept cluster recovery
rows, the Rorqual job 14918220 claim boundary, 80 seed replicates, denominators
equal to seed replicates times internal conditions, linked support-cell
`unsupported/planned` status, clean rows with 0 nonconverged fits, and recovery
grade agreement between the sidecar, audit table, rollup, and support-cell
text.

Mission control repeats those checks and also validates the sidecar schema,
evidence URL, support-cell/audit/rollup consistency, superseding top-up
precedence, and no-promotion wording.

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

The first source staging attempt tried to transfer stale local build artifacts
and a large simulation-results tree. I aborted it, cleaned the incomplete
Rorqual run root, restaged a small source bundle that excluded compiled objects
and `inst/sim/results`, removed AppleDouble `._*` files, and submitted job
14918220 successfully.

The sidecar contract briefly oscillated between a seven-row display file and
an all-ten provenance file. The final rule is explicit: the Rorqual cluster
sidecar preserves all ten reproduced rows, and the widget/rollup apply top-up
precedence for the three stronger-denominator rows.

## 10. Known Residuals

`qseries_phylo_interaction_nbinom2_q1_mu` now retains a cluster recovery caveat
from 5/80 boundary-warning rows. The fixed-covariance spatial NB2 one-slope row
also retains its earlier Rorqual count-slope Hessian caveat. No non-Gaussian
row has a count-specific interval route, coverage denominator, MCSE-calibrated
interval grid, bridge support, REML, AI-REML, or public support claim.

Non-Gaussian q2/q4, count sigma, zero-inflation, labelled/multiple count
slopes, count scale routes, and non-Gaussian interval/coverage claims remain
future arcs.

## 11. Team Learning

Cluster reproduction sidecars should keep all row-level outcomes, including
rows later superseded by stronger sidecars. The widget can apply precedence,
but the evidence ledger should preserve caveats and make new caveats visible.
