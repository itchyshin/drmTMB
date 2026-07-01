# After Task: Q-Series Gaussian low-q q1 mu-intercept smoke runner

## 1. Goal

Make the reviewed n=5 Gaussian low-q q1 `mu` intercept smoke contract
executable without reusing the n=2 dry-run artifact names, IDs, or claim
wording.

## 2. Implemented

This promotes exactly no Q-Series row. It adds a smoke-specific execution path
for the four reviewed q1 `mu` intercept smoke candidates:

- `qseries_phylo_q1_mu_intercept`;
- `qseries_spatial_q1_mu_intercept`;
- `qseries_animal_q1_mu_intercept`;
- `qseries_relmat_q1_mu_intercept`.

`tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R` now accepts
`--run-kind=dry_run|smoke`. Dry-run mode keeps the existing dashboard sidecar
schema. Smoke mode requires `--n-rep=5`, reads
`structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv`, verifies the
Totoro/FIIA-only host gate and `do_not_promote` decision, writes
`smoke-results` artifact files with `smoke_id` and `source_contract_id`, and
refuses dashboard writes.

`tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R` is the
smoke-named wrapper. It injects `--run-kind=smoke` and
`--write-dashboard=false` unless the caller already supplied those arguments.

## 3a. Decisions and Rejected Alternatives

The runner does not change the estimand. It uses the same intercept-only
Gaussian structured-RE DGP and default `confint()` Wald direct-SD `mu` target
as the dry-run. The smoke result remains fixture evidence only:
`n=5` is not coverage evidence, and every attempted replicate is retained.

Decision: keep smoke mode artifact-only. The runner refuses dashboard writes
because the widget should only import reviewed smoke results through a
validator-owned sidecar.

Rejected alternative: do not ask maintainers to run the n=2 dry-run script with
`--n-rep=5`; that path now has a smoke-specific wrapper and smoke-specific
artifact IDs.

## 4. Files Touched

- `tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R`
- `tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-mu-intercept-smoke-runner.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R")); invisible(parse("tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R")); cat("parse_ok\n")'`:
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R --help`:
  passed and printed the shared runner help with `--run-kind=dry_run|smoke`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R --run-kind=smoke --n-rep=1 --write-dashboard=false --output-dir=/tmp/drmtmb-lowq-mu-smoke-should-fail --overwrite=true`:
  failed as intended with `Smoke mode is the reviewed n=5 fixture smoke. Use --n-rep=5.`
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R --n-rep=5 --seed-start=201 --seed-base=814000 --host-class=local_rehearsal --output-dir=/tmp/drmtmb-lowq-mu-smoke-rehearsal --overwrite=true`:
  passed; wrote 4 smoke summary rows and 20 replicate rows under `/tmp`, with
  `smoke_id`, `source_contract_id`, `host_class = local_rehearsal`,
  `smoke_status = smoke_passed_fixture_only`, and no dashboard sidecar.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R --n-rep=1 --seed-start=301 --seed-base=815000 --output-dir=/tmp/drmtmb-lowq-mu-dry-run-rehearsal --write-dashboard=false --overwrite=true`:
  passed; dry-run mode kept `dry_run_id` and dry-run fields while naming
  `n=1` as not coverage evidence.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series
  cells, 4 Gaussian low-q mu-intercept dry-run rows, and 4 Gaussian low-q
  mu-intercept smoke-contract rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  7598 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-mu-intercept-smoke-runner.md')"`:
  passed after the required numbered section headings were synced.
- `env DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`, followed by a detached `drmtmb-mission-control` server restart:
  passed; served checks returned `version.txt = r123` and `/` contained
  `Q-Series Support Cells`, `r123`, and `Low-q mu smoke`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The new focused test parses both runner scripts and checks that the smoke
wrapper injects `--run-kind=smoke` plus `--write-dashboard=false`. It also
checks that the shared runner contains smoke-specific artifact terms:
`smoke_id`, `smoke-results`, `source_contract_id`,
`n=5 is smoke, not coverage evidence`,
`fisher_rose_review_pending_no_promotion`, and
`point_fit/planned/planned`.

The local smoke rehearsal is a test of the execution path, not a status claim.
It proves that smoke mode writes separate smoke artifacts and does not overwrite
the dashboard.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control execution-path hygiene inside the active Q-Series board.

## 8. Consistency Audit

Checked the runner, wrapper, smoke contract TSV, dry-run TSV, focused test, and
dashboard README. The support-cell table remains unchanged: the linked rows
stay `point_fit/planned/planned`, with no `inference_ready`, `supported`,
interval, or coverage promotion.

## 9. What Did Not Go Smoothly

The first runner edit briefly constructed a data frame without assigning it
before renaming the ID column. The parse/rehearsal pass caught that before any
dashboard artifact was touched.

## 10. Known Residuals

The local smoke rehearsal is not the reviewed Totoro/FIIA smoke result. It does
not appear in the widget and does not authorize Nibi/Rorqual/DRAC denominator
work. A future import sidecar must review host, artifacts, warning/error state,
and Fisher/Rose sign-off before the smoke appears as board evidence.

## 11. Team Learning

Smoke and dry-run are different evidence modes even when they use the same DGP.
The command name, artifact IDs, sidecar names, and claim boundary must all say
which mode produced the file.

## Next Actions

Run `tools/run-structured-re-gaussian-lowq-mu-intercept-smoke.R` on Totoro/FIIA
from an authenticated session, or ask Fisher/Rose whether Nibi/Rorqual may be
used as a substitute smoke host. Then import the reviewed smoke artifacts
through a validator-owned sidecar before any denominator campaign.
