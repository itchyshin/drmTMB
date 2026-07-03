# After Task: Q-Series Tranche 43 q4 relmat Dependency-Install Terminal Review

## 1. Goal

Install only the missing Totoro dependencies for the relmat q4 temp-install
path, capture provenance, and stop before any q4 retry, retained denominator,
coverage, or status claim.

## 2. Implemented

Ran a Totoro-only dependency-install tranche for `RcppEigen` and `TMB` under:

`docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche43-relmat-dependency-install-totoro/`

The first install script failed before installation because the
`download.packages()` result was parsed as if it had column names. The corrected
second attempt installed `RcppEigen` 0.3.4.0.2 and `TMB` 1.9.21 into
`/home/snakagaw/R/lib` from CRAN source tarballs.

Added
`docs/dev-log/dashboard/structured-re-q4-location-tranche43-relmat-dependency-install-terminal-review.tsv`
as a three-row Mission Control sidecar. Mission Control build `r237` now loads
and renders it.

## 3a. Decisions and Rejected Alternatives

The execution decision is `dependency_install_only_no_q4_retry`. The successful
attempt recorded source tarball hashes, installed-package tables,
`sessionInfo()`, and namespace checks:

- `RcppEigen` 0.3.4.0.2:
  `ecad7ba2129fd48b7ebb825558d38492ed1f3a8934959e27fcd6688175e542bb`
- `TMB` 1.9.21:
  `b07fff7186b3025507038cd69cdee99c7efb9269947cb80f3f55ea376d45e53a`

Rejected treating dependency installation or `requireNamespace()` as admission
evidence. Rejected any q4 retry, shard execution, shards 14-16, DRAC
submission, `drmTMB` load, q4 fit, retained denominator, coverage, promotion,
support-cell status movement, q4/q8 claim, REML, AI-REML, derived-correlation
interval, bridge, denominator pooling, or public-support claim.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-tranche43-relmat-dependency-install-terminal-review.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-tranche43-relmat-dependency-install-totoro/`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche42-q4-relmat-dependency-route-preflight.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche43-q4-relmat-dependency-install-terminal-review.md`

## 5. Checks Run

- Totoro reachability precheck: ControlMaster socket present; host `totoro`
  returned R 4.5.3 and load average near 95-98 on a 384-core machine.
- Attempt 1: exited 1 before installation with
  `Error in downloaded[, "Package"] : no 'dimnames' attribute for array`.
- Attempt 2: exited 0 after installing `RcppEigen` and `TMB` into
  `/home/snakagaw/R/lib`.
- Attempt 2 namespace check: `RcppEigen TRUE`, `TMB TRUE`.
- Attempt 2 installed-package table: `RcppEigen` 0.3.4.0.2 and `TMB` 1.9.21
  in `/home/snakagaw/R/lib`, with existing `Rcpp` 1.1.1 and `Matrix` 1.7-5.
- Tranche 43 TSV shape check: 4 lines including header, 37 columns, no
  bad-width rows.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r237.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 3 Tranche 43 dependency-install
  terminal-review rows, and 195 member-discussion rows.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "Sys.setenv(OMP_NUM_THREADS='1', OPENBLAS_NUM_THREADS='1',
  MKL_NUM_THREADS='1'); devtools::test(filter =
  'structured-re-conversion-contracts', reporter = 'summary')"`: passed with
  `DONE`.
- Invariant scan: 104 support cells, 8 interval `inference_ready` rows, 8
  coverage `inference_ready` rows, 0 structured-provider rows with any
  `supported` status, 0 q4 coverage-authorized rows, and all 3 Tranche 43 rows
  set to `dependency_install_only_no_q4_retry`, `coverage_not_authorized`,
  `do_not_promote`, `rscript_exit_status = 0`, and `ssh_exit_status = 0`.
- Served dashboard probe on `http://127.0.0.1:8766`: `version.txt` returned
  `r237`, the Tranche 43 sidecar served with 4 lines and 37 columns, and
  `index.html` contained the Tranche 43 summary label, render label, and
  sidecar load.
- After-task checker:
  `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche43-q4-relmat-dependency-install-terminal-review.md')"`:
  passed with `after-task structure check passed`.
- Recovery checkpoint written:
  `docs/dev-log/recovery-checkpoints/2026-07-01-203248-codex-checkpoint.md`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused R test reads the Tranche 43 sidecar, checks schema and source links
to Tranche 42, verifies the first failed script transcript, verifies the
successful namespace check, installed-package table, source tarball hashes, and
stdout status, confirms unchanged relmat q4 support-cell status, and checks the
SC387 Rose/Fisher/Grace rows.

The Python validator independently checks the sidecar schema, row count,
artifact paths, package versions, SHA-256 hashes, namespace table,
installed-package table, successful stdout status, claim-boundary phrases,
next-gate phrases, unchanged support-cell status, and member-board rows.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This tranche records internal Mission
Control dependency-install evidence only. It does not change public APIs,
formula grammar, package behavior, user-facing support status, or release text.

## 8. Consistency Audit

The q4 relmat support cell remains unchanged. Tranche 43 carries
`execution_decision = dependency_install_only_no_q4_retry`,
`coverage_decision = coverage_not_authorized`, and
`promotion_decision = do_not_promote` on every row.

Mission Control still reports 104 Q-Series support cells, 8 interval
`inference_ready` rows, 8 coverage `inference_ready` rows, 0 structured-provider
rows with any `supported` status, and 0 q4 coverage-authorized rows.

Public APIs, formula grammar, `R/`, `src/`, pkgdown, README, NEWS, and
support-cell statuses were not changed by Tranche 43.

## 9. What Did Not Go Smoothly

The first install script had a local R bookkeeping bug: it treated
`download.packages()` output as though it had dimnames. That failed before
installation, so it did not change the Totoro library. The corrected attempt
kept the failed transcript separate and installed only the two approved
packages.

## 10. Known Residuals

No q4 retry ran in Tranche 43 and no coverage-evaluable relmat q4 denominator
exists. The next tranche must create a checkpoint, get Rose/Fisher/Grace
approval, then run exactly one relmat q4 shard-13 temp-install retry from the
Tranche 39 source snapshot with
`DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace` and
`--attempt-temp-install`. That later tranche must stop for a Tranche 44 terminal
review before any denominator, status, shards 14-16, DRAC, or coverage
discussion.

Supersession note: Tranche 44 has now banked that single shard-13 retry. The
run exited 0 after loading `drmTMB`, but relmat q4 admission failed because
`pdHess` and Wald-finite retained-denominator rates were both 112/150 = 0.7467,
below the 0.95 gate. No further shards, denominator admission, coverage,
status movement, DRAC submission, or top-up are authorized from the Tranche 43
install evidence.

The full Q-Series completion campaign remains active.

## 11. Team Learning

Rose kept a successful dependency install from becoming a status claim. Fisher
kept namespace checks out of denominator accounting. Grace made the install
reproducible by requiring source tarball hashes, session evidence, and installed
package tables before a retry.
