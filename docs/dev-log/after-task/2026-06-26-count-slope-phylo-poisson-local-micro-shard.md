## 1. Goal

Execute the first local diagnostic micro-shard for the ordinary count
one-slope recovery lane: the exact `phylo()` plus `poisson()` q1 `mu`
one-slope cell. Keep the evidence local, diagnostic, and separate from
coverage, interval, bridge, REML, AI-REML, public support, Totoro, and DRAC
claims.

## 2. Implemented

- Added a source-controlled runner,
  `tools/run-structured-re-count-slope-phylo-poisson-local-micro-shard.R`,
  that installs the current source into a temporary local library when needed,
  builds a minimal balanced `"phylo"` object, runs four fixed-seed Poisson
  one-slope fits, and writes replicate, summary, and run-log TSV artifacts.
- Added
  `docs/dev-log/dashboard/structured-re-count-slope-phylo-poisson-local-micro-shard.tsv`
  as the one-row mission-control sidecar for the local diagnostic execution.
- Added generated artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-phylo-poisson-local-micro-shard/`.
  The final summary records four attempted fits, four converged fits, zero fit
  errors, zero `pdHess` failures, and four finite estimate rows.
- Updated mission-control validation, the focused R dashboard contract test,
  the dashboard README, the q-series completion map, and the check log.

## 3a. Decisions and Rejected Alternatives

- I kept this as a local micro-shard rather than marking the existing
  Totoro/DRAC shard pack as executed. The shard pack still needs explicit
  human approval before external compute submission.
- I did not widen the evidence to NB2, spatial, animal, relmat, q2/q4, sigma,
  labelled slopes, multiple slopes, intervals, bridge parity, or coverage. The
  purpose was to prove one exact cell can run through the recovery runner path.
- I fixed runner path quoting for the space in `Github Local` and formula
  environment scoping for `tree` before treating the final artifact as
  evidence.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-26-count-slope-phylo-poisson-local-micro-shard.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-phylo-poisson-local-micro-shard.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-phylo-poisson-local-micro-shard/structured-re-count-slope-phylo-poisson-local-micro-shard-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-phylo-poisson-local-micro-shard/structured-re-count-slope-phylo-poisson-local-micro-shard-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-phylo-poisson-local-micro-shard/structured-re-count-slope-phylo-poisson-local-micro-shard-summary.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-count-slope-phylo-poisson-local-micro-shard.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-count-slope-phylo-poisson-local-micro-shard.R --n_rep=4 --attempt-temp-install` passed after runner fixes and wrote the three artifact TSVs.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported one count-slope phylo Poisson local micro-shard row.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-count-slope-phylo-poisson-local-micro-shard.md')"` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"` could not run because `devtools` is absent from the local R library.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"` could not run because `testthat` is absent from the local R library.

## 6. Tests of the Tests

- The first runner execution failed to install the current package because the
  repository path with a space was not shell-quoted inside `system2()`. That
  exposed that the artifact path would catch execution-path bugs rather than
  silently passing.
- The second runner execution reached the package and failed every replicate
  because `tree` was not in the formula calling environment. Adding
  `tree <- sim$tree` changed the final artifact from four fit errors to four
  successful fits.
- The mission-control validator now checks the exact four-row replicate file,
  the one-row summary, the one-row run log, and the one-row dashboard sidecar.
  It would fail if the row were edited into coverage, interval, REML,
  AI-REML, bridge, or public-support evidence.

## 7a. Issue Ledger

- Fixed: runner path quoting for the repository path containing a space.
- Fixed: formula environment scoping for the `tree` object used by `phylo()`.
- Deferred: full eight-shard count recovery execution remains gated on human
  review before Totoro or DRAC submission.
- Deferred: MCSE-calibrated recovery, coverage-evaluable denominator evidence,
  intervals, bridge parity, and public support remain outside this slice.

## 8. Consistency Audit

- Checked the existing count-slope recovery runner, dispatch, and shard-pack
  contracts before adding a separate local micro-shard sidecar.
- Verified that the new sidecar links back to the existing phylo Poisson
  shard-pack, runner, q-series cell, and generated artifacts.
- Kept the q-series support-cell row unchanged: the local micro-shard adds
  diagnostic execution evidence but does not promote the support-cell ladder.
- Scanned neighbouring dashboard README and q-series map text to keep the
  boundary language aligned with the existing dry-run pack.

## 9. What Did Not Go Smoothly

- The first direct `R CMD INSTALL` probes reused or rebuilt a local shared
  object that segfaulted under the active R/TMB toolchain. Running the runner
  through a quoted temporary source install resolved the practical execution
  path for this shard.
- The first generated artifact recorded a script quoting error, and the second
  recorded a formula scoping error. Both were useful failures and were fixed
  before the final artifact was banked.

## 10. Known Residuals

- The local micro-shard has only four seeds and is not a coverage-evaluable
  denominator. It is not MCSE-calibrated recovery evidence.
- Some fitted random-slope SD estimates are near the boundary, so this is
  smoke evidence only, not a stability or support claim.
- The local R library still lacks `devtools` and `testthat`, so focused R tests
  could not be executed here outside the validator and runner path.
- Totoro and DRAC remain unused in this slice.

## 11. Team Learning

Use a source-controlled runner before submitting external count-recovery
shards. It catches mundane execution problems, such as spaces in paths and
formula environment scoping, before the team spends Totoro or DRAC time. Keep
the resulting local smoke row separate from coverage and support rows.
