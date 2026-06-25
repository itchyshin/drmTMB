# After Task: Count Slope Recovery Runner Contract

## 1. Goal

Bank a dry-run recovery-runner contract for the ordinary Poisson/NB2 q1
structured `mu` intercept-plus-one-slope cells in `phylo()`,
fixed-covariance `spatial()`, `animal()`, and `relmat()`.

## 2. Implemented

- Added
  `docs/dev-log/dashboard/structured-re-count-slope-recovery-runner-contract.tsv`
  with eight exact provider/family runner rows.
- Added the selected target manifest and dry-run run log under
  `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-runner-contract/`.
- Added mission-control validation for schema, row count, provider/family
  identity, links to the fixture/recovery contract, links to native fixture
  rows, links to q-series support cells, dry-run status, seed range, recovery
  metrics, retention policy, artifact paths, and conservative claim language.
- Added an R dashboard contract test that keeps the runner rows dry-run only
  and cross-checks the selected manifest against the dashboard contract.
- Updated the q-series support cells, dashboard README, q-series completion
  map, and check log.

## 3a. Decisions and Rejected Alternatives

- Treated this as a runner contract, not an executed recovery result. The
  rows are `runner_contract_only`, `not_executed`, and
  `not_coverage_evidence`.
- Rejected launching Totoro or DRAC work in this slice. The next gate remains
  human review plus provider/family shard execution with retained scheduler
  status.
- Kept bridge, interval, coverage, q2/q4 count covariance, REML, AI-REML, and
  public-support statuses unmoved. Non-Gaussian count cells remain ML/Laplace
  evidence only.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-recovery-runner-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-runner-contract/structured-re-count-slope-recovery-runner-target-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-runner-contract/structured-re-count-slope-recovery-runner-run-log.tsv`
- `docs/dev-log/after-task/2026-06-25-count-slope-recovery-runner-contract.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `air format tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed with 86 structured RE
  q-series cells, 8 structured RE count-slope fixture/recovery contract rows,
  8 structured RE count-slope native-fixture rows, and 8 structured RE
  count-slope recovery-runner rows.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-25-count-slope-recovery-runner-contract.md')"`
  passed.
- `gh issue list --repo itchyshin/drmTMB --search '"count slope recovery runner"' --limit 20 --json number,title,state,url,labels`
  returned `[]`.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  could not run because `devtools` is absent from the clean local R library.
  Non-vanilla startup points arm64 R 4.6 at an old
  `x86_64-pc-linux-gnu-library/4.4` library.

## 6. Tests of the Tests

The new R dashboard contract reads
`structured-re-count-slope-recovery-runner-contract.tsv`, verifies the exact
eight provider/family rows, checks dry-run status, checks recovery targets and
retention policy, and compares the artifact target manifest to the dashboard
contract row-for-row. It also joins each runner row back to
`structured-re-count-slope-fixture-recovery-contract.tsv`,
`structured-re-count-slope-native-fixture-status.tsv`, and
`structured-re-q-series-support-cells.tsv`.

The Python validator independently checks the same schema and linkage, plus
the one-row run log. It requires claim boundaries to name the absence of
executed recovery, Totoro/DRAC submission, bridge parity, interval
reliability, coverage, q2, q4, REML, AI-REML, public support, and broad bridge
support.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --search '"count slope recovery runner"' --limit 20 --json number,title,state,url,labels`
returned no matching issues. No issue was opened because this is a narrow
stacked-PR evidence-contract slice.

## 8. Consistency Audit

- Confirmed the new runner rows link to the exact count one-slope contract and
  native fixture sidecars already banked in the stack.
- Updated the q-series next gate for the count one-slope cells so it now says
  to execute the recovery runner contract instead of adding sidecars that
  already exist.
- Kept NEWS, roxygen, examples, and formula grammar unchanged because no
  runtime behavior or user-facing API changed.

## 9. What Did Not Go Smoothly

The main nuance was terminology. "Runner contract" can sound like execution,
so the dashboard and validator explicitly require `dry_run_not_submitted`,
`not_executed`, `runner_contract_only`, and `not_coverage_evidence`.

## 10. Known Residuals

- No recovery simulation has been executed.
- Totoro and DRAC execution remain unsubmitted pending human review.
- Bridge parity, intervals, coverage, q2/q4 count covariance, REML, AI-REML,
  public support, labelled or multiple count slopes, structured count scale
  routes, zero-inflated structured effects, and broad bridge support remain
  unsupported or planned.

## 11. Team Learning

For non-Gaussian q-series work, bank the execution contract before the
expensive run, and make the dry-run status machine-checkable. That gives
Totoro/DRAC work a recoverable manifest without letting planning evidence turn
into support language.
