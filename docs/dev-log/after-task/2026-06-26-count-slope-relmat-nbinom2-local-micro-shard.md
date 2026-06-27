## 1. Goal

Execute the exact relmat K/Q NB2 local diagnostic micro-shard for the ordinary
count one-slope recovery lane: `relmat(1 + x | id, Q = Q)` in `mu`,
`nbinom2()` family, q1, one independent structured slope, and fixed-effect
overdispersion `sigma`. Keep the evidence local, diagnostic, and separate from
Q bridge marshalling, recovery, coverage, interval, bridge, REML, AI-REML,
public support, Totoro, and DRAC claims.

## 2. Implemented

- Added a source-controlled runner,
  `tools/run-structured-re-count-slope-relmat-nbinom2-local-micro-shard.R`,
  that installs the current source into a temporary local library when needed,
  builds a K covariance matrix plus inverse precision route, runs four
  fixed-seed NB2 one-slope fits through `Q = Q`, and writes replicate, summary,
  and run-log TSV artifacts.
- Added
  `docs/dev-log/dashboard/structured-re-count-slope-relmat-nbinom2-local-micro-shard.tsv`
  as the one-row mission-control sidecar for this exact local diagnostic
  execution.
- Added generated artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-relmat-nbinom2-local-micro-shard/`.
  The final summary records four attempted fits, four converged fits, zero fit
  errors, zero `pdHess` failures, and four finite estimate rows.
- Updated mission-control validation, the focused R dashboard contract test,
  the dashboard README, the q-series completion map, and the check log.

## 3a. Decisions and Rejected Alternatives

- I used the exact `Q = Q` local formula because the dry-run runner contract
  names the broader relmat K/Q route, but this smoke row should be tied to the
  concrete source-controlled fit.
- I kept `sigma` as fixed-effect overdispersion only. This slice does not add a
  structured count-scale random effect.
- I kept this as the relmat NB2 sibling of the local relmat Poisson smoke row
  rather than marking the Totoro/DRAC shard pack as executed. The shard pack
  still needs explicit human approval before external compute submission.
- I did not promote Q bridge marshalling, structured count `sigma`,
  zero-inflated structure, q2/q4 count covariance, labelled slopes, multiple
  slopes, intervals, bridge parity, coverage, REML, AI-REML, or public support.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-26-count-slope-relmat-nbinom2-local-micro-shard.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-relmat-nbinom2-local-micro-shard.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-relmat-nbinom2-local-micro-shard/structured-re-count-slope-relmat-nbinom2-local-micro-shard-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-relmat-nbinom2-local-micro-shard/structured-re-count-slope-relmat-nbinom2-local-micro-shard-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-relmat-nbinom2-local-micro-shard/structured-re-count-slope-relmat-nbinom2-local-micro-shard-summary.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-count-slope-relmat-nbinom2-local-micro-shard.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-count-slope-relmat-nbinom2-local-micro-shard.R --n_rep=4 --attempt-temp-install` passed and wrote the three artifact TSVs.
- `air format tools/run-structured-re-count-slope-relmat-nbinom2-local-micro-shard.R tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported one count-slope relmat NB2 local micro-shard row.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-count-slope-relmat-nbinom2-local-micro-shard.md')"` passed.
- `Rscript --vanilla -e "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R')); cat('parse_ok\n')"` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"` could not run because `devtools` is absent from the local R library.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"` could not run because `testthat` is absent from the local R library.

## 6. Tests of the Tests

- The runner uses the same temporary source-install path as the phylo, spatial,
  animal, and relmat Poisson count micro-shards, so it exercises the current
  source rather than an unrelated installed package.
- The simulation helper builds a K covariance matrix and inverse precision
  matrix for the same levels used in the runtime formula. The sidecar records
  the concrete `Q = Q` formula so the smoke evidence is not inferred from the
  broader relmat K/Q contract row.
- The mission-control validator checks the exact four-row replicate file, the
  one-row summary, the one-row run log, and the one-row dashboard sidecar. It
  would fail if the row were edited into coverage, interval, REML, AI-REML,
  bridge, structured count `sigma`, or public-support evidence.
- The R dashboard contract test has a separate relmat NB2 test, so the relmat
  NB2 row cannot be inferred from the relmat Poisson, animal, spatial, or phylo
  smoke rows.

## 7a. Issue Ledger

- Fixed: the relmat NB2 support cell now has one local execution smoke row
  matching the already banked dry-run shard-pack row.
- Deferred: full eight-shard count recovery execution remains gated on human
  review before Totoro or DRAC submission.
- Deferred: MCSE-calibrated recovery, coverage-evaluable denominator evidence,
  intervals, bridge parity, Q bridge marshalling, structured count `sigma`,
  labelled or multiple slopes, zero-inflated structure, q2/q4 count covariance,
  and public support remain outside this slice.

## 8. Consistency Audit

- Checked the existing relmat NB2 q-series, runner, dispatch, and shard-pack
  rows before adding the local sidecar.
- Verified that the new sidecar links back to the existing relmat NB2
  shard-pack, runner, q-series cell, and generated artifacts.
- Kept the q-series support-cell row unchanged: the local micro-shard adds
  diagnostic execution evidence but does not promote the support-cell ladder.
- Updated the dashboard README and q-series map text to keep the phylo,
  spatial, animal, and relmat smoke rows family- and provider-specific.

## 9. What Did Not Go Smoothly

- The relmat local formula needed to use the concrete `Q = Q` route even though
  the broader dry-run contracts are named as K/Q rows. I kept both names visible
  so later work does not confuse a fitted precision route with bridge
  marshalling.
- Several smoke seeds estimate one of the random-effect SDs close to the lower
  boundary. That is acceptable for smoke evidence, but it reinforces that this
  is not recovery, stability, or coverage evidence.

## 10. Known Residuals

- The local micro-shard has only four seeds and is not a coverage-evaluable
  denominator. It is not MCSE-calibrated recovery evidence.
- The local R library still lacks `devtools` and `testthat`, so focused R tests
  need remote CI or a fuller local R library after the validator is wired.
- Totoro and DRAC remain unused in this slice.

## 11. Team Learning

Relmat K/Q count rows need the same exact route discipline as the Gaussian K/Q
rows. A fitted `Q = Q` smoke shard is useful, but it is not Q bridge
marshalling, not recovery-grid evidence, and not a reason to infer neighboring
q-cells.
