# After Task: Q-Series phylo-interaction NB2 count-intercept top-up recovery

## 1. Goal

Use the connected Rorqual/DRAC lane for one narrow non-Gaussian recovery
top-up: the `qseries_phylo_interaction_nbinom2_q1_mu` row whose original
count-intercept cluster reproduction retained a 5/80 near-zero and
boundary-warning caveat.

## 2. Implemented

This promotes exactly no Q-Series row under the non-Gaussian count q1 `mu`
recovery-only channel. It records Rorqual SLURM job `14936834` as a top-up for
`qseries_phylo_interaction_nbinom2_q1_mu`.

The top-up itself has 80/80 fit_ok, 0 nonconverged rows, 0/80 `pdHess =
FALSE`, 80/80 finite estimates, and 1/80 near-zero/boundary-warning row.
Combined with the original Rorqual job `14918220`, the retained denominator is
160/160 fit_ok, 0 nonconverged rows, 0/160 `pdHess = FALSE`, 160/160 finite
estimates, and 6/160 near-zero/boundary-warning rows.

Mission control now reads the one-row top-up sidecar before the older
count-intercept cluster sidecar for widget display. The phylo-interaction NB2
row is therefore `cluster_confirmed_recovery_only` in the non-Gaussian
recovery rollup, while the original cluster sidecar remains unchanged as
provenance. Intervals and coverage stay `unsupported/planned`.

## 3a. Decisions and Rejected Alternatives

Decision: keep this as recovery-only evidence. The top-up shows the original
5/80 lower-boundary caveat does not persist across the next retained seed
window, but it is not an interval route and not a coverage denominator.

Decision: leave
`structured-re-count-intercept-cluster-recovery-results.tsv` unchanged as
historical provenance. The new one-row sidecar supersedes display state through
the rollup, not by rewriting old evidence.

Rejected alternatives:

- Do not call the row `inference_ready`.
- Do not promote non-Gaussian intervals, coverage, `supported`, REML,
  AI-REML, q2/q4 count covariance, bridge support, high-q readiness,
  structured count sigma, zero-inflation, labelled/multiple count slopes,
  count-scale routes, or public support.
- Do not generalize this one NB2 `phylo_interaction()` top-up to Poisson,
  ordinary phylo, spatial, animal, relmat, sigma, q2, q4, or q8 rows.
- Do not route this already completed row to Totoro/FIIA just because those
  hosts are connected. This exact lane is a Rorqual recovery reproduction; use
  Totoro/FIIA for the Gaussian smoke gates that explicitly require them.

## 4. Files Touched

- `tools/run-structured-re-count-intercept-recovery-grid.R`
- `tools/slurm/count-intercept-recovery-rorqual.sbatch`
- `docs/dev-log/dashboard/structured-re-count-intercept-phylo-interaction-nb2-topup-recovery-results.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-recovery-rollup.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-phylo-interaction-nb2-recovery-topup-smoke-local/`
- `docs/dev-log/simulation-artifacts/2026-06-29-phylo-interaction-nb2-topup-rorqual/`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-phylo-interaction-nb2-topup-recovery.md`

## 5. Checks Run

- Local exact-lane smoke:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-count-intercept-recovery-grid.R --output_dir=docs/dev-log/simulation-artifacts/2026-06-29-phylo-interaction-nb2-recovery-topup-smoke-local --n_rep=2 --seed_start=2026064001 --cores=1 --backend=none --lanes=phylo_interaction --families=nbinom2 --overwrite`:
  passed with 2/2 fit_ok, 0 nonconverged, 0/2 `pdHess = FALSE`, 2/2 finite
  estimates, 0 near-zero estimates, and `recovery_only_passed`.
- Rorqual SLURM job `14936834`: completed with `State: COMPLETED (exit code
  0)` in `sacct`; runner exit code 0. The fetched `seff.txt` metadata was
  refreshed after accounting settled and now records 00:02:07 wall time and
  3.20 GB memory.
- Top-up artifact summary: 80/80 fit_ok, 0 nonconverged rows, 0/80 `pdHess =
  FALSE`, 80/80 finite estimates, 1/80 near-zero/boundary-warning row, bias
  -0.043927, RMSE 0.14935, bias MCSE 0.016059, and RMSE MCSE 0.013049.
- Combined original-plus-top-up denominator: 160 unique seeds,
  160/160 fit_ok, 0 nonconverged rows, 0/160 `pdHess = FALSE`, 160/160 finite
  estimates, 6/160 near-zero/boundary-warning rows, bias -0.055491, RMSE
  0.16845, bias MCSE 0.012613, and RMSE MCSE 0.010747.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed
  with `mission_control_ok`, including 104 structured RE Q-Series cells, 37
  non-Gaussian status-audit rows, 18 non-Gaussian recovery-rollup rows, and 1
  phylo-interaction NB2 top-up recovery sidecar row.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8,025 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-phylo-interaction-nb2-topup-recovery.md')"`:
  passed with `after-task structure check passed`.
- `git diff --check`: passed.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt` returned
  `r132`, the new phylo-interaction NB2 top-up TSV served 2 lines including
  the header, and the served non-Gaussian recovery rollup shows
  `qseries_phylo_interaction_nbinom2_q1_mu` as
  `cluster_confirmed_recovery_only` with 160/160 fit_ok and 0/160 `pdHess =
  FALSE`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-phylo-interaction-nb2-topup-recovery.md')"`:
  passed with `after-task structure check passed`.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed; the dashboard was already listening at `http://127.0.0.1:8765/`.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt` returned
  `r132`; the new top-up sidecar served 2 lines including the header; the
  served recovery rollup reported 18 `cluster_confirmed_recovery_only` rows and
  no current `cluster_recovery_caveat` rows.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused test now requires the non-Gaussian rollup to have exactly 18
`cluster_confirmed_recovery_only` rows and zero `cluster_recovery_caveat` rows
in the current widget state. It separately keeps the original local and cluster
sidecars as historical caveat evidence, so the test would fail if the old
5/80 caveat were erased rather than superseded by the new one-row top-up
sidecar.

Mission control repeats those checks and validates the new top-up sidecar
schema, combined 160-seed denominator, artifact path, no-promotion wording,
support-cell source text, audit row, rollup display precedence, and
unsupported/planned interval and coverage statuses.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is a local
mission-control evidence update inside the active Q-Series board.

## 8. Consistency Audit

Checked the top-up sidecar, original count-intercept cluster sidecar,
non-Gaussian recovery rollup, non-Gaussian status audit, Q-Series support-cell
TSV, dashboard README, dashboard build/version, mission-control validator, and
focused test file.

Stale-wording scans used:

- `rg -n "17 are|17 .*cluster|one keeps a cluster recovery caveat|current recovery caveat" docs/dev-log/dashboard/README.md docs/dev-log/dashboard/index.html docs/dev-log/dashboard/*.tsv tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`
- `rg -n "non_gaussian_recovery_caveat|cluster_recovery_caveat|17L, 1L|17 confirmed|1 retained" tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/dashboard/README.md docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv docs/dev-log/dashboard/structured-re-nongaussian-recovery-rollup.tsv`

The live dashboard sources now say 18 confirmed non-Gaussian recovery-only rows
and zero current non-Gaussian recovery caveats. Historical sidecars and tests
still retain the old local/cluster caveat rows as provenance.

## 9. What Did Not Go Smoothly

The first remote staging attempt tried to stream the heavy `inst/sim/results`
and built source objects. I interrupted it and restaged a slim source bundle
with package source, selected `inst/sim` helpers, the filtered runner, and the
SLURM wrapper. The final source bundle on Rorqual was about 194 KB before
installation.

The focused test initially failed because an older family-specific
`phylo_interaction()` test expected both support-cell rows to cite only the
native fixture file. The corrected test now distinguishes Poisson native
fixture evidence from the NB2 recovery-top-up evidence while still requiring
the NB2 claim boundary to retain the native-contract wording.

The cluster pool is now available enough to matter, but that creates a routing
temptation. This row stayed on Rorqual because the queue allowed Rorqual for
non-Gaussian recovery reproduction and because no new Gaussian smoke gate was
part of this slice.

## 10. Known Residuals

The phylo-interaction NB2 q1 `mu` row is recovery-confirmed only. It still has
no count-specific interval route, no coverage denominator, no MCSE-calibrated
interval grid, no bridge support, no q2/q4 count covariance evidence, no REML,
no AI-REML, and no public support claim.

The combined denominator still records 6/160 near-zero or boundary-warning
rows. That is acceptable for recovery-grade display here, but it is not
interval or coverage evidence.

## 11. Team Learning

For narrow recovery top-ups, use a one-row sidecar to supersede display state
while keeping the original sidecar immutable. That gives the widget current
state, preserves old caveats as provenance, and keeps recovery, stability,
interval, and coverage as separate signals.
