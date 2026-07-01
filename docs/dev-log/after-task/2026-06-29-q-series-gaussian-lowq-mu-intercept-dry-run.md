# After Task: Q-Series Gaussian low-q q1 mu-intercept dry-run

## 1. Goal

Run the first local screen for the four Gaussian low-q q1 `mu` intercept rows
selected by the row-selection contract, without promoting any Q-Series row or
spending DRAC denominator time.

## 2. Implemented

This promotes exactly no Q-Series row under the Gaussian low-q q1 `mu`
intercept local dry-run channel, with a local n=2 screen and artifact TSV
evidence only. It does not claim `interval_status`, `coverage_status`,
`inference_ready`, `supported`, sigma readiness, q2/q4/q8 readiness,
non-Gaussian interval readiness, REML, AI-REML, DRAC readiness, bridge support,
or public support.

Added `tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R`. The
script reads `structured-re-gaussian-lowq-row-selection.tsv`, requires exactly
the four rows in the `first_smoke_candidate_location_intercept` class, and
accepts either the historical local dry-run state or the later reviewed
Totoro/FIIA smoke state. It runs a true intercept-only Gaussian structured-RE
DGP and fit for:

- `qseries_phylo_q1_mu_intercept`;
- `qseries_spatial_q1_mu_intercept`;
- `qseries_animal_q1_mu_intercept`;
- `qseries_relmat_q1_mu_intercept`.

The dry-run writes:

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-dry-run.tsv`;
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-dry-run-local/structured-re-gaussian-lowq-mu-intercept-dry-run.tsv`;
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-dry-run-local/structured-re-gaussian-lowq-mu-intercept-dry-run-replicates.tsv`;
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-dry-run-local/structured-re-gaussian-lowq-mu-intercept-dry-run-seed-manifest.tsv`;
- `sessionInfo.txt`;
- `git-sha.txt`.

All four provider rows passed the local screen: 2/2 fits, 2/2 convergence, 2/2
`pdHess`, and 2/2 usable default Wald intervals for each provider. The tiny
screen coverage is 2/2 for each provider, but n=2 is not coverage evidence.

Mission control now validates the dry-run summary, raw replicates, seed
manifest, artifact mirror, no-promotion wording, and linked support-cell
statuses. The widget renders a "Low-q mu dry" card/table at build `r119`, with
the row header explicitly marked as an n=2 screen rather than coverage
evidence.

## 3a. Decisions and Rejected Alternatives

Decision: keep this as a local screen only. Passing rows may go to Fisher/Rose
review and then a tiny Totoro/FIIA smoke; Nibi/Rorqual/DRAC remain blocked
until that smoke passes.

Decision: use true intercept-only DGPs for phylo and animal rather than reusing
the q1 `mu` one-slope DGP with a near-zero slope. The dry-run should test the
actual row shape, not a neighbouring model.

Rejected alternatives:

- Do not use this n=2 screen as coverage or inference evidence.
- Do not promote q1 `mu` intercept rows to `inference_ready`.
- Do not let sigma, matched `mu+sigma`, q2, q4/q8, direct-SD,
  `phylo_interaction()`, or non-Gaussian rows inherit this result.
- Do not submit DRAC denominator jobs from this screen.

## 4. Files Touched

- `tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-dry-run.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-mu-intercept-dry-run-local/`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-mu-intercept-dry-run.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'parse("tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R"); cat("parse_ok\n")'`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R --n-rep=2 --overwrite=true`:
  passed; wrote 4 summary rows and 8 replicate rows.
- `/opt/homebrew/bin/air format tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Dashboard JavaScript parse check: passed with `dashboard_js_parse_ok`.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series cells,
  23 Gaussian low-q row-selection rows, and 4 Gaussian low-q mu-intercept
  dry-run rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  7445 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed after a fresh `mission_control_ok`; the dashboard was already
  listening at `http://127.0.0.1:8765/`.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt` returned
  `r119`, `structured-re-gaussian-lowq-mu-intercept-dry-run.tsv` served 5
  lines including the header, `/` contained `Low-q mu dry`, `/` contained the
  dry-run TSV fetch path, `/` contained `gaussianLowQMuInterceptDryRun`, and
  the rendered dry-run table marks the values as `n=2 screen only` / not
  coverage evidence.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-mu-intercept-dry-run.md')"`:
  passed.
- `git diff --check`: passed.
- `find tools -type d -name __pycache__ -print`: returned no paths after
  removing the `tools/__pycache__` directory created by `py_compile`.

## 6. Tests of the Tests

The new focused test requires exactly four dry-run rows, exact q1 `mu` intercept
cell IDs, n=2 local-only counts, matching support-cell `point_fit/planned/planned`
statuses, byte-for-field agreement between dashboard and artifact summary TSVs,
eight successful raw replicate rows, and a seed manifest with two seeds per
provider.

Mission control repeats the same checks and also validates the artifact mirror,
raw replicate schema, seed tuples, no-promotion wording, evidence URL, and
blocked Nibi/Rorqual/DRAC next gate.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence and host-gate hygiene inside the active Q-Series board.

## 8. Consistency Audit

Checked the support-cell TSV, Gaussian low-q row-selection TSV, dashboard
renderer, dashboard README, validator, focused tests, and generated dry-run
artifacts.

The board remains 104 rows with exactly five interval-and-coverage
`inference_ready` rows and no structured `supported` row. The dry-run does not
change support-cell status and does not authorize DRAC.

## 9. What Did Not Go Smoothly

The first harness run failed before fitting because the runner sourced the
phylo/animal DGP files without sourcing `inst/sim/R/sim_utils.R`, where
`phase18_with_seed()` lives. That was useful: the dry-run caught a harness
problem before any cluster compute.

The initial phylo/animal generator also reused a near-zero-slope DGP. I replaced
that with true intercept-only DGPs before accepting the local result.

## 10. Known Residuals

At the time of this dry-run report, the four q1 `mu` intercept rows still
needed Fisher/Rose review before a tiny Totoro/FIIA smoke. That review was
later recorded in
`docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-mu-intercept-smoke-contract.md`.
The current gate is reviewed but host-held; the rows remain
`point_fit/planned/planned`, not `inference_ready`.

Sigma, matched `mu+sigma`, q2 intercept, direct-SD, `phylo_interaction()`,
q4/q8, and non-Gaussian interval rows remain separate unfinished arcs.

## 11. Team Learning

The first compute after a row-selection contract should stay tiny and local.
It is cheap enough to catch missing harness dependencies and wrong model shape,
and it protects Totoro/FIIA/Nibi/Rorqual/DRAC time for rows that have already
passed the local contract.
