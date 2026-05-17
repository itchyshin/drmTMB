# After Task: Slice 127 emmeans offset recover-data contract

## Goal

Make the first fixed-effect univariate `mu` `emmeans()` bridge robust for
ordinary formula offsets such as `offset(log(exposure))`. The reader-facing
target is exposure-adjusted count-rate EMMs that match `predict(dpar = "mu")`,
not a broader fitted-response or non-`mu` marginal-effects layer.

## Implemented

`recover_data.drmTMB()` now accepts the `data` argument that
`emmeans::ref_grid()` passes during data recovery and forwards an explicit data
frame to `emmeans::recover_data()`. This avoids relying on the original call
environment when the terms contain functions such as `offset(log(exposure))`.

`drm_emmeans_recover_data()` now augments the retained model frame with missing
model variables from `object$data`, aligned by retained row names. This restores
offset source variables such as `exposure`, which are needed by `emmeans` when it
builds the reference grid.

`tests/testthat/test-emmeans-methods.R` now fits a Poisson fixed-effect `mu`
model with `offset(log(exposure))` and checks that
`emmeans(..., at = list(x = 0, exposure = 2))` matches
`predict(dpar = "mu")` on both link and response scales. The recover-data tests
also confirm that the preflight exposes `exposure` as a predictor.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now state that this
offset support is part of the first fixed-effect univariate `mu` bridge only.

## Files Changed

- `R/emmeans-preflight.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-127-emmeans-offset-contract.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-210359-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`
- `tests/testthat/test-emmeans-recover-data.R`

## Checks Run

- `air format R/emmeans-preflight.R tests/testthat/test-emmeans-methods.R tests/testthat/test-emmeans-recover-data.R NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 127 offset wording, offset tests, and
  recover-data helper changes: found the expected entries.
- Stale-claim scan for offset as an unsupported `emmeans` target: returned only
  older general count-model roadmap/NEWS mentions outside the `emmeans`
  contract.
- `git diff --check`: passed.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-210359-codex-checkpoint.md`.

Post-rebase checks:

- PR #91 merged as `89326081ceea98b42057c6a5d12269951500929c`.
- `git rebase --onto origin/main a5e4326e39306f0f4ce3aee3d243cf8e08b5910d`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

The first failed local test was useful: the offset example only worked before
because the original `dat` object still existed in the global environment.
Inside testthat, `emmeans` could not reconstruct `exposure` from the retained
model frame. The fix removes that environment dependency for retained-data fits.

The slice does not widen the `emmeans` gate. Non-`mu`, random-effect, bivariate,
zero-inflated, hurdle, ordinal, slope, custom-weight, and fitted-response
targets still need their own algebra and tests before they can be advertised.

## Known Limitations

- Offset source variables must be available in stored data.
- Only ordinary fixed-effect univariate `mu` offsets are covered.
- No custom offset helper, custom weighting contract, or fitted-response EMM is
  added.

## Team Notes

Rose should keep watching for examples that pass only because a global data
object still exists. Curie should prefer testthat-local data scopes for future
`emmeans` recovery work so hidden call-environment dependencies fail early.
