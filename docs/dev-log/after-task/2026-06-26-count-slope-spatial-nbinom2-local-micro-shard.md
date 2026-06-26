## 1. Goal

Execute the exact fixed-covariance spatial NB2 local diagnostic micro-shard
for the ordinary count one-slope recovery lane:
`spatial(1 + x | site, coords = coords)` in `mu`, `nbinom2()` family, q1, and
one independent structured slope, with `sigma` kept as fixed-effect
overdispersion. Keep the evidence local, diagnostic, and separate from
range-estimating spatial support, coverage, interval, bridge, REML, AI-REML,
public support, Totoro, and DRAC claims.

## 2. Implemented

- Added a source-controlled runner,
  `tools/run-structured-re-count-slope-spatial-nbinom2-local-micro-shard.R`,
  that installs the current source into a temporary local library when needed,
  builds a fixed coordinate data frame, derives the simulation covariance from
  `drmTMB:::drm_spatial_coords_precision()`, simulates NB2 counts with
  `Var(y) = mu + sigma^2 * mu^2`, runs four fixed-seed NB2 one-slope fits, and
  writes replicate, summary, and run-log TSV artifacts.
- Added
  `docs/dev-log/dashboard/structured-re-count-slope-spatial-nbinom2-local-micro-shard.tsv`
  as the one-row mission-control sidecar for this exact local diagnostic
  execution.
- Added generated artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-spatial-nbinom2-local-micro-shard/`.
  The final summary records four attempted fits, four converged fits, zero fit
  errors, zero `pdHess` failures, and four finite estimate rows.
- Updated mission-control validation, the focused R dashboard contract test,
  the dashboard README, the q-series completion map, and the check log.

## 3a. Decisions and Rejected Alternatives

- I kept this as the fixed-covariance spatial NB2 sibling of the spatial
  Poisson smoke row rather than marking the Totoro/DRAC shard pack as executed.
  The shard pack still needs explicit human approval before external compute
  submission.
- I kept `sigma` fixed-effect only because the support cell is NB2 q1
  structured `mu` one-slope. Structured count `sigma`, zero-inflated NB2
  structure, q2/q4 count covariance, labelled slopes, multiple slopes,
  intervals, bridge parity, coverage, REML, AI-REML, range-estimating spatial
  support, and public support remain outside this slice.
- I used the package's NB2 variance convention, `size = 1 / sigma^2`, when
  simulating with base R so the runner truth columns match the package family
  contract.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-26-count-slope-spatial-nbinom2-local-micro-shard.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-spatial-nbinom2-local-micro-shard.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-spatial-nbinom2-local-micro-shard/structured-re-count-slope-spatial-nbinom2-local-micro-shard-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-spatial-nbinom2-local-micro-shard/structured-re-count-slope-spatial-nbinom2-local-micro-shard-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-spatial-nbinom2-local-micro-shard/structured-re-count-slope-spatial-nbinom2-local-micro-shard-summary.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-count-slope-spatial-nbinom2-local-micro-shard.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-count-slope-spatial-nbinom2-local-micro-shard.R --n_rep=4 --attempt-temp-install` passed and wrote the three artifact TSVs.
- `air format tools/run-structured-re-count-slope-spatial-nbinom2-local-micro-shard.R tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported one count-slope spatial NB2 local micro-shard row.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-count-slope-spatial-nbinom2-local-micro-shard.md')"` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"` could not run because `devtools` is absent from the local R library.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"` could not run because `testthat` is absent from the local R library.

## 6. Tests of the Tests

- The runner uses the same temporary source-install path as the other count
  micro-shards, so it exercises the current source rather than an unrelated
  installed package.
- The simulation helper builds a coordinate data frame and spatial precision
  matrix matching the runtime formula cell, then simulates NB2 counts with a
  fixed overdispersion truth column.
- The mission-control validator checks the exact four-row replicate file, the
  one-row summary, the one-row run log, and the one-row dashboard sidecar. It
  would fail if the row were edited into coverage, interval, REML, AI-REML,
  bridge, range-estimating spatial, structured count `sigma`, or public-support
  evidence.
- The R dashboard contract test has a separate spatial NB2 test, so the NB2 row
  cannot be inferred from the spatial Poisson, phylo Poisson, or phylo NB2
  rows.

## 7a. Issue Ledger

- Fixed: the spatial NB2 support cell now has one local execution smoke row
  matching the already banked dry-run shard-pack row.
- Deferred: full eight-shard count recovery execution remains gated on human
  review before Totoro or DRAC submission.
- Deferred: MCSE-calibrated recovery, coverage-evaluable denominator evidence,
  intervals, bridge parity, range-estimating spatial support, structured count
  `sigma`, labelled or multiple slopes, and public support remain outside this
  slice.

## 8. Consistency Audit

- Checked the existing spatial NB2 q-series, runner, dispatch, and shard-pack
  rows before adding the local sidecar.
- Verified that the new sidecar links back to the existing spatial NB2
  shard-pack, runner, q-series cell, and generated artifacts.
- Kept the q-series support-cell row unchanged: the local micro-shard adds
  diagnostic execution evidence but does not promote the support-cell ladder.
- Updated the dashboard README and q-series map text to keep the phylo Poisson,
  phylo NB2, spatial Poisson, and spatial NB2 smoke rows family- and
  provider-specific.

## 9. What Did Not Go Smoothly

- The runner was created from the spatial Poisson runner and then hand-patched
  for NB2; I reran it after tightening the run-log boundary to mention
  fixed-effect overdispersion and no structured count `sigma`.
- Three of the four smoke seeds estimate one structured SD near the lower
  boundary. That is acceptable for smoke evidence, but it reinforces that this
  is not recovery, stability, or coverage evidence.

## 10. Known Residuals

- The local micro-shard has only four seeds and is not a coverage-evaluable
  denominator. It is not MCSE-calibrated recovery evidence.
- The local R library still lacks `devtools` and `testthat`, so focused R tests
  need remote CI or a fuller local R library after the validator is wired.
- Totoro and DRAC remain unused in this slice.

## 11. Team Learning

Family siblings need their own evidence even when the provider and formula
shape are parallel. A spatial Poisson smoke row did not prove spatial NB2
behavior, and the NB2 row needs its own fixed-overdispersion truth and boundary
checks so later prose cannot accidentally promote structured count scale.
