## 1. Goal

Execute the exact fixed-covariance spatial Poisson local diagnostic
micro-shard for the ordinary count one-slope recovery lane:
`spatial(1 + x | site, coords = coords)` in `mu`, `poisson()` family, q1, and
one independent structured slope. Keep the evidence local, diagnostic, and
separate from range-estimating spatial support, coverage, interval, bridge,
REML, AI-REML, public support, Totoro, and DRAC claims.

## 2. Implemented

- Added a source-controlled runner,
  `tools/run-structured-re-count-slope-spatial-poisson-local-micro-shard.R`,
  that installs the current source into a temporary local library when needed,
  builds a fixed coordinate data frame, derives the simulation covariance from
  `drmTMB:::drm_spatial_coords_precision()`, runs four fixed-seed Poisson
  one-slope fits, and writes replicate, summary, and run-log TSV artifacts.
- Added
  `docs/dev-log/dashboard/structured-re-count-slope-spatial-poisson-local-micro-shard.tsv`
  as the one-row mission-control sidecar for this exact local diagnostic
  execution.
- Added generated artifacts under
  `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-spatial-poisson-local-micro-shard/`.
  The final summary records four attempted fits, four converged fits, zero fit
  errors, zero `pdHess` failures, and four finite estimate rows.
- Updated mission-control validation, the focused R dashboard contract test,
  the dashboard README, the q-series completion map, and the check log.

## 3a. Decisions and Rejected Alternatives

- I replaced the copied phylo-shaped scaffold with a true fixed-covariance
  spatial coordinate helper before treating the run as evidence. The runner
  uses `drm_spatial_coords_precision()` rather than a fake tree-like object.
- I kept this as the spatial Poisson sibling of the local phylo Poisson smoke
  row rather than marking the Totoro/DRAC shard pack as executed. The shard
  pack still needs explicit human approval before external compute submission.
- I did not promote range-estimating spatial support, structured count
  `sigma`, zero-inflated structure, q2/q4 count covariance, labelled slopes,
  multiple slopes, intervals, bridge parity, coverage, REML, AI-REML, or
  public support.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-26-count-slope-spatial-poisson-local-micro-shard.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-spatial-poisson-local-micro-shard.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-spatial-poisson-local-micro-shard/structured-re-count-slope-spatial-poisson-local-micro-shard-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-spatial-poisson-local-micro-shard/structured-re-count-slope-spatial-poisson-local-micro-shard-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-26-count-slope-spatial-poisson-local-micro-shard/structured-re-count-slope-spatial-poisson-local-micro-shard-summary.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-count-slope-spatial-poisson-local-micro-shard.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-count-slope-spatial-poisson-local-micro-shard.R --n_rep=4 --attempt-temp-install` passed and wrote the three artifact TSVs.
- `air format tools/run-structured-re-count-slope-spatial-poisson-local-micro-shard.R tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported one count-slope spatial Poisson local micro-shard row.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-count-slope-spatial-poisson-local-micro-shard.md')"` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"` could not run because `devtools` is absent from the local R library.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"` could not run because `testthat` is absent from the local R library.

## 6. Tests of the Tests

- The runner uses the same temporary source-install path as the phylo count
  micro-shards, so it exercises the current source rather than an unrelated
  installed package.
- The simulation helper now builds a coordinate data frame and spatial
  precision matrix matching the runtime formula cell. This would fail earlier
  if the copied phylo-shaped object leaked back into the runner.
- The mission-control validator checks the exact four-row replicate file, the
  one-row summary, the one-row run log, and the one-row dashboard sidecar. It
  would fail if the row were edited into coverage, interval, REML, AI-REML,
  bridge, range-estimating spatial, structured count `sigma`, or public-support
  evidence.
- The R dashboard contract test has a separate spatial Poisson test, so the
  spatial row cannot be inferred from the phylo Poisson or phylo NB2 rows.

## 7a. Issue Ledger

- Fixed: the spatial Poisson support cell now has one local execution smoke row
  matching the already banked dry-run shard-pack row.
- Deferred: full eight-shard count recovery execution remains gated on human
  review before Totoro or DRAC submission.
- Deferred: MCSE-calibrated recovery, coverage-evaluable denominator evidence,
  intervals, bridge parity, range-estimating spatial support, structured count
  `sigma`, labelled or multiple slopes, and public support remain outside this
  slice.

## 8. Consistency Audit

- Checked the existing spatial Poisson q-series, runner, dispatch, and
  shard-pack rows before adding the local sidecar.
- Verified that the new sidecar links back to the existing spatial Poisson
  shard-pack, runner, q-series cell, and generated artifacts.
- Kept the q-series support-cell row unchanged: the local micro-shard adds
  diagnostic execution evidence but does not promote the support-cell ladder.
- Updated the dashboard README and q-series map text to keep the phylo Poisson,
  phylo NB2, and spatial Poisson smoke rows family- and provider-specific.

## 9. What Did Not Go Smoothly

- The first copied runner scaffold still had phylo-shaped code, including a
  fake tree-like object with class `"spatial"`. I replaced that before running
  the shard, so the banked artifacts come from the real fixed-covariance
  spatial path.
- Two of the four smoke seeds estimate one structured SD near the lower
  boundary. That is acceptable for smoke evidence, but it reinforces that this
  is not recovery, stability, or coverage evidence.

## 10. Known Residuals

- The local micro-shard has only four seeds and is not a coverage-evaluable
  denominator. It is not MCSE-calibrated recovery evidence.
- The local R library still lacks `devtools` and `testthat`, so focused R tests
  need remote CI or a fuller local R library after the validator is wired.
- Totoro and DRAC remain unused in this slice.

## 11. Team Learning

Provider siblings need their own evidence even when the formula shape is
parallel. A phylo Poisson smoke row did not prove fixed-covariance spatial
Poisson behavior, and a copied runner scaffold can accidentally preserve the
wrong provider semantics unless the support cell owns its own simulation path.
