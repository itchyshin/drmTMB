## 1. Goal

Execute the exact animal A/Ainv Poisson local diagnostic micro-shard for the
ordinary count one-slope recovery lane: `animal(1 + x | id, Ainv = Q)` in
`mu`, `poisson()` family, q1, and one independent structured slope. Keep the
evidence local, diagnostic, and separate from pedigree/Ainv bridge
marshalling, recovery, coverage, interval, bridge, REML, AI-REML, public
support, Totoro, and DRAC claims.

## 2. Implemented

- Added a source-controlled runner,
  `tools/run-structured-re-count-slope-animal-poisson-local-micro-shard.R`,
  that installs the current source into a temporary local library when needed,
  builds an A-matrix covariance and inverse precision route, runs four
  fixed-seed Poisson one-slope fits, and writes replicate, summary, and run-log
  TSV artifacts.
- Added
  `docs/dev-log/dashboard/structured-re-count-slope-animal-poisson-local-micro-shard.tsv`
  as the one-row mission-control sidecar for this exact local diagnostic
  execution.
- Added generated artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-animal-poisson-local-micro-shard/`.
  The final summary records four attempted fits, four converged fits, zero fit
  errors, zero `pdHess` failures, and four finite estimate rows.
- Updated mission-control validation, the focused R dashboard contract test,
  the dashboard README, the q-series completion map, and the check log.

## 3a. Decisions and Rejected Alternatives

- I used the exact `Ainv = Q` local formula because the dry-run runner contract
  names the broader animal A/Ainv route, but this smoke row should be tied to
  the concrete source-controlled fit.
- I kept this as the animal Poisson sibling of the local phylo and spatial
  smoke rows rather than marking the Totoro/DRAC shard pack as executed. The
  shard pack still needs explicit human approval before external compute
  submission.
- I did not promote pedigree/Ainv bridge marshalling, structured count
  `sigma`, zero-inflated structure, q2/q4 count covariance, labelled slopes,
  multiple slopes, intervals, bridge parity, coverage, REML, AI-REML, or public
  support.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-26-count-slope-animal-poisson-local-micro-shard.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-animal-poisson-local-micro-shard.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-animal-poisson-local-micro-shard/structured-re-count-slope-animal-poisson-local-micro-shard-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-animal-poisson-local-micro-shard/structured-re-count-slope-animal-poisson-local-micro-shard-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-animal-poisson-local-micro-shard/structured-re-count-slope-animal-poisson-local-micro-shard-summary.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-count-slope-animal-poisson-local-micro-shard.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-count-slope-animal-poisson-local-micro-shard.R --n_rep=4 --attempt-temp-install` passed and wrote the three artifact TSVs.
- `air format tools/run-structured-re-count-slope-animal-poisson-local-micro-shard.R tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported one count-slope animal Poisson local micro-shard row.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-count-slope-animal-poisson-local-micro-shard.md')"` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"` could not run because `devtools` is absent from the local R library.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"` could not run because `testthat` is absent from the local R library.

## 6. Tests of the Tests

- The runner uses the same temporary source-install path as the phylo and
  spatial count micro-shards, so it exercises the current source rather than an
  unrelated installed package.
- The simulation helper builds a covariance matrix and inverse precision matrix
  for the same levels used in the runtime formula. The sidecar records the
  concrete `Ainv = Q` formula so the smoke evidence is not inferred from the
  broader animal A/Ainv contract row.
- The mission-control validator checks the exact four-row replicate file, the
  one-row summary, the one-row run log, and the one-row dashboard sidecar. It
  would fail if the row were edited into coverage, interval, REML, AI-REML,
  bridge, structured count `sigma`, or public-support evidence.
- The R dashboard contract test has a separate animal Poisson test, so the
  animal row cannot be inferred from phylo or spatial smoke rows.

## 7a. Issue Ledger

- Fixed: the animal Poisson support cell now has one local execution smoke row
  matching the already banked dry-run shard-pack row.
- Deferred: full eight-shard count recovery execution remains gated on human
  review before Totoro or DRAC submission.
- Deferred: MCSE-calibrated recovery, coverage-evaluable denominator evidence,
  intervals, bridge parity, pedigree/Ainv bridge marshalling, structured count
  `sigma`, labelled or multiple slopes, zero-inflated structure, q2/q4 count
  covariance, and public support remain outside this slice.

## 8. Consistency Audit

- Checked the existing animal Poisson q-series, runner, dispatch, and
  shard-pack rows before adding the local sidecar.
- Verified that the new sidecar links back to the existing animal Poisson
  shard-pack, runner, q-series cell, and generated artifacts.
- Kept the q-series support-cell row unchanged: the local micro-shard adds
  diagnostic execution evidence but does not promote the support-cell ladder.
- Updated the dashboard README and q-series map text to keep the phylo,
  spatial, and animal smoke rows family- and provider-specific.

## 9. What Did Not Go Smoothly

- The copied-runner risk was lower than in the spatial shard, but I still
  checked the formula and level matrix route before treating the artifacts as
  evidence.
- One smoke seed estimates the slope SD near the lower boundary. That is
  acceptable for smoke evidence, but it reinforces that this is not recovery,
  stability, or coverage evidence.

## 10. Known Residuals

- The local micro-shard has only four seeds and is not a coverage-evaluable
  denominator. It is not MCSE-calibrated recovery evidence.
- The local R library still lacks `devtools` and `testthat`, so focused R tests
  need remote CI or a fuller local R library after the validator is wired.
- Totoro and DRAC remain unused in this slice.

## 11. Team Learning

Animal A/Ainv rows need exact formula-level evidence too. The generic dry-run
contract row says an animal one-slope recovery shard can be executed later, but
the local smoke row should name the concrete matrix route that was actually fit
before any neighboring cell or bridge route is trusted.
