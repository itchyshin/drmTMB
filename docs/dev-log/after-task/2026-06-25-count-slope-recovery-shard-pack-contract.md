# After Task: Count Slope Recovery Shard-Pack Contract

## 1. Goal

Bank a dry-run shard-pack contract for the ordinary Poisson/NB2 q1 structured
`mu` one-slope recovery rows without recording human approval or submitting
Totoro or DRAC jobs.

## 2. Implemented

- Added
  `docs/dev-log/dashboard/structured-re-count-slope-recovery-shard-pack-contract.tsv`
  with eight provider/family shard-pack rows.
- Added a matching shard-pack index plus one target manifest and one run log
  per provider/family shard under
  `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/`.
- Added mission-control validation for exact dispatch and runner links,
  private shard manifest and run-log paths, no-execution status, retained
  failure accounting, and conservative claim boundaries.
- Added an R dashboard contract test that checks the sidecar, index,
  per-shard manifests, per-shard run logs, and links back to the dispatch and
  runner rows.
- Updated the dashboard README, q-series completion map, and check log.

## 3a. Decisions and Rejected Alternatives

- Treated this as a dry-run shard-pack contract, not as Shinichi approval and
  not as execution. The rows use `human_approval_status = pending`,
  `submission_status = not_submitted`, `compute_status = not_executed`, and
  `recovery_status = shard_pack_only`.
- Rejected writing a single shared shard manifest or run log. Each provider
  and family cell now has private manifest and run-log filenames so a later
  scheduler run cannot overwrite the all-target runner contract.
- Rejected moving recovery, denominator, coverage, interval reliability,
  bridge parity, q2/q4 count covariance, REML, AI-REML, and public support.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-recovery-shard-pack-contract.tsv`
- `docs/dev-log/after-task/2026-06-25-count-slope-recovery-shard-pack-contract.md`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-shard-pack-index.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-target-manifest-phylo-poisson.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-target-manifest-phylo-nbinom2.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-target-manifest-spatial-poisson.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-target-manifest-spatial-nbinom2.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-target-manifest-animal-poisson.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-target-manifest-animal-nbinom2.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-target-manifest-relmat-poisson.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-target-manifest-relmat-nbinom2.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-run-log-phylo-poisson.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-run-log-phylo-nbinom2.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-run-log-spatial-poisson.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-run-log-spatial-nbinom2.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-run-log-animal-poisson.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-run-log-animal-nbinom2.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-run-log-relmat-poisson.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-count-slope-recovery-shard-pack-contract/structured-re-count-slope-recovery-run-log-relmat-nbinom2.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `air format tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed with 86 structured RE
  q-series cells, 8 structured RE count-slope recovery-dispatch review rows,
  and 8 structured RE count-slope recovery-shard-pack rows.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-25-count-slope-recovery-shard-pack-contract.md')"`
  passed.
- `gh issue list --repo itchyshin/drmTMB --search '"count slope recovery shard pack"' --limit 20 --json number,title,state,url,labels`
  returned `[]`.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  could not run because `devtools` is absent from the clean local R library.
  Non-vanilla startup points arm64 R 4.6 at an old
  `x86_64-pc-linux-gnu-library/4.4` library.
- `Rscript --no-environ --no-init-file -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"`
  could not run because `testthat` is also absent from the clean local R
  library.

## 6. Tests of the Tests

The new R dashboard contract reads
`structured-re-count-slope-recovery-shard-pack-contract.tsv`, checks the
matching artifact index, opens every shard manifest and run log, verifies
private shard filenames, and joins each shard row back to the dispatch and
runner rows. The Python validator independently checks the same schema,
artifact links, linked row identities, no-execution statuses, and claim
boundaries.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --search '"count slope recovery shard pack"' --limit 20 --json number,title,state,url,labels`
returned no matching issues. No issue was opened because this is a narrow
stacked-PR execution-contract slice.

## 8. Consistency Audit

- Confirmed each shard-pack row maps to exactly one dispatch row and one
  recovery-runner row.
- Confirmed each shard uses a private manifest and run-log filename instead of
  the all-target runner manifest and run log.
- Kept every row at `not_submitted`, `not_executed`, and
  `not_coverage_evidence`.
- Kept NEWS, roxygen, examples, and formula grammar unchanged because no
  runtime behavior or user-facing API changed.

## 9. What Did Not Go Smoothly

The main risk was making concrete scheduler-ready filenames look like executed
compute. The new rows therefore keep `human_approval_status = pending` and say
plainly that no Totoro or DRAC job has been submitted.

## 10. Known Residuals

- No recovery simulation has been executed.
- No Totoro or DRAC job has been submitted.
- Human approval for execution is still pending.
- Bridge parity, intervals, coverage, q2/q4 count covariance, REML, AI-REML,
  public support, labelled or multiple count slopes, structured count scale
  routes, zero-inflated structured effects, and broad bridge support remain
  unsupported or planned.

## 11. Team Learning

For compute-heavy q-series slices, create private shard manifests and run logs
before scheduler approval. That gives Totoro/DRAC execution a recoverable file
contract without turning planning artifacts into recovery evidence.
