## 1. Goal

Execute the exact NB2 sibling local diagnostic micro-shard for the ordinary
count one-slope recovery lane: `phylo()` plus `nbinom2()` q1 `mu` one-slope,
with `sigma` kept as fixed-effect overdispersion. Keep the evidence local,
diagnostic, and separate from coverage, interval, bridge, REML, AI-REML,
public support, Totoro, and DRAC claims.

## 2. Implemented

- Added a source-controlled runner,
  `tools/run-structured-re-count-slope-phylo-nbinom2-local-micro-shard.R`,
  that installs the current source into a temporary local library when needed,
  builds a minimal balanced `"phylo"` object, simulates NB2 counts with
  `Var(y) = mu + sigma^2 * mu^2`, runs four fixed-seed NB2 one-slope fits, and
  writes replicate, summary, and run-log TSV artifacts.
- Added
  `docs/dev-log/dashboard/structured-re-count-slope-phylo-nbinom2-local-micro-shard.tsv`
  as the one-row mission-control sidecar for the local diagnostic execution.
- Added generated artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-phylo-nbinom2-local-micro-shard/`.
  The final summary records four attempted fits, four converged fits, zero fit
  errors, zero `pdHess` failures, and four finite estimate rows.
- Updated mission-control validation, the focused R dashboard contract test,
  the dashboard README, the q-series completion map, and the check log.

## 3a. Decisions and Rejected Alternatives

- I kept this as the NB2 sibling of the local Poisson micro-shard rather than
  marking the Totoro/DRAC shard pack as executed. The shard pack still needs
  explicit human approval before external compute submission.
- I kept `sigma` fixed-effect only because the support cell is NB2 q1
  structured `mu` one-slope. Structured count `sigma`, zero-inflated NB2
  structure, q2/q4 count covariance, labelled slopes, multiple slopes,
  intervals, bridge parity, and coverage remain outside this slice.
- I used the package's NB2 variance convention, `size = 1 / sigma^2`, when
  simulating with base R so the runner truth columns match the package family
  contract.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-26-count-slope-phylo-nbinom2-local-micro-shard.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-phylo-nbinom2-local-micro-shard.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-phylo-nbinom2-local-micro-shard/structured-re-count-slope-phylo-nbinom2-local-micro-shard-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-phylo-nbinom2-local-micro-shard/structured-re-count-slope-phylo-nbinom2-local-micro-shard-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-phylo-nbinom2-local-micro-shard/structured-re-count-slope-phylo-nbinom2-local-micro-shard-summary.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-count-slope-phylo-nbinom2-local-micro-shard.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-count-slope-phylo-nbinom2-local-micro-shard.R --n_rep=4 --attempt-temp-install` passed and wrote the three artifact TSVs.
- `air format tools/run-structured-re-count-slope-phylo-nbinom2-local-micro-shard.R tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported one count-slope phylo NB2 local micro-shard row.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-count-slope-phylo-nbinom2-local-micro-shard.md')"` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"` could not run because `devtools` is absent from the local R library.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"` could not run because `testthat` is absent from the local R library.

## 6. Tests of the Tests

- The runner uses the same temporary source-install path as the Poisson shard,
  so the previously exposed path-quoting and formula-environment failure modes
  remain covered by the execution path.
- The mission-control validator now checks the exact four-row NB2 replicate
  file, the one-row summary, the one-row run log, and the one-row dashboard
  sidecar. It would fail if the row were edited into coverage, interval, REML,
  AI-REML, bridge, structured count `sigma`, or public-support evidence.
- The R dashboard contract test has a separate NB2 test, so the NB2 row cannot
  be inferred from the existing Poisson row.
- `git diff --check` and `python3 tools/validate-mission-control.py` passed
  after adding the test and sidecar, which exercises the exact artifact paths,
  row counts, claim-boundary phrases, and q-series linkage.

## 7a. Issue Ledger

- Fixed: the NB2 support cell now has one local execution smoke row matching
  the already banked dry-run shard-pack row.
- Deferred: full eight-shard count recovery execution remains gated on human
  review before Totoro or DRAC submission.
- Deferred: MCSE-calibrated recovery, coverage-evaluable denominator evidence,
  intervals, bridge parity, structured count `sigma`, and public support remain
  outside this slice.

## 8. Consistency Audit

- Checked the existing count-slope recovery runner, dispatch, shard-pack, and
  q-series rows before adding the NB2 sidecar.
- Verified that the new sidecar links back to the existing phylo NB2
  shard-pack, runner, q-series cell, and generated artifacts.
- Kept the q-series support-cell row unchanged: the local micro-shard adds
  diagnostic execution evidence but does not promote the support-cell ladder.
- Scanned the dashboard README and q-series map text to keep the Poisson and
  NB2 local smoke rows family-specific.

## 9. What Did Not Go Smoothly

- The NB2 sibling runner itself executed cleanly once it reused the Poisson
  runner's source-install and formula-environment pattern.
- The first local evidence still shows random-slope SD estimates close to the
  boundary in some seeds, which is acceptable for smoke evidence but reinforces
  that this is not recovery, stability, or coverage evidence.

## 10. Known Residuals

- The local micro-shard has only four seeds and is not a coverage-evaluable
  denominator. It is not MCSE-calibrated recovery evidence.
- The local R library still lacks `devtools` and `testthat`, so focused R tests
  need remote CI or a fuller local R library after the validator is wired.
- Totoro and DRAC remain unused in this slice.

## 11. Team Learning

Treat Poisson and NB2 as separate support cells even when the runner mechanics
are parallel. A family sibling smoke row is useful progress, but it must not be
used to claim calibrated count recovery, structured count scale support, or
neighbouring q2/q4 count covariance.
