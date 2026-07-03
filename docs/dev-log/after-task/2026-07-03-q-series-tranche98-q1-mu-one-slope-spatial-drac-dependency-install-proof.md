# After Task: Q-Series Tranche 98 q1 mu one-slope spatial DRAC dependency-install proof

## Goal

Bank the Tranche 98 q1 `mu` one-slope spatial-only DRAC dependency proof before
any repeat model job. The claim is narrow: Rorqual was reachable, the exact T83
source/run root still existed, the default R 4.4.0 library route lacked
`cli`, `TMB`, and `RcppEigen`, and login-node package compilation was stopped.

## Implemented

Added
`docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche98-spatial-drac-dependency-install-proof.tsv`
with 8 decision rows. Added fetched Rorqual artifacts under
`docs/dev-log/simulation-artifacts/2026-07-03-gaussian-mu-slope-tranche98-spatial-drac-dependency-install-proof/`,
including host provenance, module/R version, `.libPaths()`, dependency
availability, source/run-root provenance, `sessionInfo()`, and a compact
terminal-review note. Appended SC438 member-board rows and moved the q1 `mu`
one-slope queue primary evidence to T98.

## Mathematical Contract

No formula, estimand, covariance structure, likelihood, or interval rule changed.
The direct-SD target identity remains `sd_mu_intercept` and `sd_mu_x` for the
spatial q1 `mu` one-slope cell. T98 is not fit evidence, interval evidence,
admission evidence, coverage evidence, or support evidence.

## Files Changed

- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-tranche98-spatial-drac-dependency-install-proof.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

- Parsed the T98 sidecar, q1 `mu` one-slope queue, and member-discussions TSVs:
  9 T98 TSV lines including header, 45 columns, no bad-width rows; queue rows
  have 14 columns and member rows have 12 columns.
- Extracted dashboard JavaScript from `docs/dev-log/dashboard/index.html` and
  ran `node --check /tmp/drmtmb-mission-control-index-r292.js`; passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py`
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`
  passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py` passed and reported 8 T98 rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'Sys.setenv(OMP_NUM_THREADS = "1", OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1"); devtools::test(filter =
  "structured-re-conversion-contracts", reporter = "summary")'` passed with
  `DONE` after three stale queue string expectations were corrected from T98 to
  T99.
- Support-cell invariant scan reported `104 96 8 0 0 0 0`: 104 Q-Series cells,
  96 non-ordinary structured-provider cells, 8 interval+coverage
  `inference_ready` rows, 0 authority `supported` rows, 0 structured
  `supported` rows, 0 q4 coverage-ready rows, and 0 q4 coverage-authorized
  rows.
- Refreshed the `/tmp/drm-dashboard` served copy for Mission Control at
  `http://127.0.0.1:8765/`; `/version.txt` reports `r292`, the rendered page
  includes the `Mu T98 dep proof` card/table note and T99 gate, and the served
  T98 TSV has 8 data rows with `missing_cli_TMB_RcppEigen`,
  `not_attempted_login_node_compile_policy`, `not_run` sbatch, and `not_run`
  model-command status.
- `git diff --check` passed.
- `tools/check-after-task.R` is not present in this checkout, so the named
  after-task checker could not be run.

## Tests Of The Tests

The focused conversion-contract test now reads the T98 TSV, checks the expected
8 decision IDs, validates linked artifacts, verifies `cli`, `TMB`, and
`RcppEigen` are absent in the dependency probe, confirms no package install/load
or model command occurred, and checks that SC438 includes Rose/Fisher/Grace
blocking claims. The validator separately enforces the same row-level contract.

## Consistency Audit

Mission Control build `r292` renders a T98 summary card, table, ledger entry, and
TSV loader. The dashboard README, completion map, queue, member board, validator,
tests, and check log all state the same boundary: no package install on the DRAC
login node, no `sbatch`, no model, no denominator, no coverage, and no support
status movement.

## GitHub Issue Maintenance

No GitHub issue action was needed. This tranche updates local dashboard and
development-log evidence only; it does not change public APIs, formula grammar,
package code, pkgdown, README, NEWS, or support-cell statuses.

## What Did Not Go Smoothly

The first local wrapper attempted to use GNU `timeout`, which is not available
on this macOS shell. I reran the SSH probe through a short Perl `alarm` wrapper.
The first member-board append also used stale column names; the script stopped
before rewriting the member/queue files, and the rerun used the actual
`negative_evidence`, `sibling_impact`, `next_gate`, and `timestamp` columns.

## Team Learning

Grace's rule is now explicit in the queue: after missing compiled dependencies
are confirmed, dependency installation must move to an allocation-safe route
through `sbatch` or `salloc`. Rose and Fisher keep T98 out of fit, denominator,
admission, coverage, and support claims.

## Known Limitations

T98 does not make `drmTMB` loadable on Rorqual. It only proves that the default
R 4.4.0 module library lacks `cli`, `TMB`, and `RcppEigen`, and that login-node
compilation was not attempted. The q1 `mu` one-slope spatial support cell
remains `point_fit/planned/planned`.

## Next Actions

Checkpoint before any compute. Tranche 99 may only be an allocation-safe
no-model dependency install/load proof: use `sbatch` or `salloc`, install
exactly `cli`, `RcppEigen`, and `TMB` into `Rlib-tranche98` or a documented
project library, then prove `R CMD INSTALL drmTMB` and `library(drmTMB)` for the
exact T83 DRAC source path. Stop before any smoke runner, model formula, model
fit, retained denominator, coverage, top-up, or status movement.
