# After Task: Q-Series q1 mu-intercept local smoke import

## 1. Goal

Run and import a local n=5 rehearsal of the reviewed Gaussian low-q q1 `mu`
intercept smoke runner, without treating that local run as the reviewed
Totoro/FIIA host smoke and without promoting any Q-Series row.

## 2. Implemented

This promotes exactly no Q-Series row under the Gaussian low-q q1 `mu` intercept
local-rehearsal smoke channel, with all attempted smoke replicates retained and
fixture-only interpretation. It does not claim `interval_status`,
`coverage_status`, `inference_ready`, `supported`, sigma readiness, matched
`mu+sigma` readiness, q2/q4/q8 readiness, direct-SD readiness,
`phylo_interaction()` readiness, non-Gaussian interval readiness, REML, AI-REML,
Nibi/Rorqual/DRAC denominator evidence, bridge support, or public support.

Ran the smoke wrapper for exactly four q1 `mu` intercept rows:

- `qseries_phylo_q1_mu_intercept`;
- `qseries_spatial_q1_mu_intercept`;
- `qseries_animal_q1_mu_intercept`;
- `qseries_relmat_q1_mu_intercept`.

The run wrote:

- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-smoke-local/structured-re-gaussian-lowq-mu-intercept-smoke-results.tsv`;
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-smoke-local/structured-re-gaussian-lowq-mu-intercept-smoke-results-replicates.tsv`;
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-smoke-local/structured-re-gaussian-lowq-mu-intercept-smoke-results-seed-manifest.tsv`;
- `sessionInfo.txt`;
- `git-sha.txt`.

The dashboard import sidecar is:

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-smoke-results.tsv`.

The Q-Series widget now shows this local n=5 rehearsal separately from the n=2
dry run, Totoro/FIIA smoke contract, interval status, coverage status, and
inference-readiness state.

While verifying the refreshed widget, the non-Gaussian state counter still
showed one recovery caveat from older sidecars even though
`structured-re-nongaussian-recovery-rollup.tsv` has all 18 recovery rows at
`cluster_confirmed_recovery_only`. The renderer now prefers the current recovery
rollup when assigning row state, so the visible non-Gaussian recovery count
matches the validator-owned rollup.

## 3a. Decisions and Rejected Alternatives

Decision: label this as `local_rehearsal`, not as Totoro/FIIA smoke evidence.
The approved host contract still says Totoro/FIIA n=5, with Nibi/Rorqual/DRAC
blocked until that smoke result is reviewed.

Rejected alternatives:

- Do not replace the Totoro/FIIA smoke gate with a local run.
- Do not call the local n=5 run coverage evidence.
- Do not promote q1 `mu` intercept rows to `inference_ready`.
- Do not let sigma, matched `mu+sigma`, q2, q4/q8, direct-SD,
  `phylo_interaction()`, or non-Gaussian rows inherit this local smoke result.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-smoke-results.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-mu-intercept-local-smoke-import.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-smoke-local/`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R --run-kind=smoke --n-rep=5 --seed-start=1 --seed-base=812000 --providers=phylo,spatial,animal,relmat --host-class=local_rehearsal --host-name=$(hostname -s) --output-dir=docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-smoke-local --overwrite=true --write-dashboard=false`:
  passed; wrote 4 smoke summary rows and 20 replicate rows.
- `/opt/homebrew/bin/air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Dashboard JavaScript parse check with `node --check /tmp/drmtmb-dashboard-index.js`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series cells,
  4 Gaussian low-q q1 `mu` intercept dry-run rows, 4 smoke-contract rows, and 4
  local smoke-result rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  8253 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q1-mu-intercept-local-smoke-import.md')"`:
  passed.

## 6. Tests of the Tests

The validator and focused test now require the imported smoke-results sidecar to
mirror the local artifact summary exactly, require 20 retained replicate rows
and 20 seed-manifest rows, require all four linked support cells to stay
`point_fit/planned/planned`, require `host_class = local_rehearsal`, and require
the no-promotion claim boundary.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence for the active Q-Series board.

## 8. Consistency Audit

Checked the support-cell TSV, Gaussian low-q row-selection sidecar, local dry-run
sidecar, smoke-contract sidecar, new local smoke-results sidecar, dashboard
renderer, dashboard README, validator, and focused test.

The board remains 104 rows. The four q1 `mu` intercept rows remain
`point_fit/planned/planned`, not `inference_ready` or `supported`.

## 9. What Did Not Go Smoothly

The local run is useful but intentionally incomplete for the original host gate:
Totoro still rejects non-interactive SSH from this shell and no `fiia` alias is
configured here, so the real Totoro/FIIA smoke remains host-held.

## 10. Known Residuals

The four q1 `mu` intercept rows still need an actual Totoro/FIIA n=5 smoke, or
a Fisher/Rose decision that a substitute smoke host is acceptable, before
Nibi/Rorqual/DRAC denominator work.

Sigma, matched `mu+sigma`, q2 intercept, direct-SD, `phylo_interaction()`,
q4/q8, and non-Gaussian interval rows remain separate unfinished arcs.

## 11. Team Learning

Local rehearsal artifacts are useful for runner integrity, but host class is a
scientific status field. Dashboard rows should show the rehearsal without
collapsing it into host-gate completion.
