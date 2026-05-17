# After Task: Slice 143 factor newdata level validation

## Goal

Accept character `newdata` values that match fitted factor levels and error
clearly when fixed-effect prediction `newdata` contains an unknown factor level.

## Implemented

`R/methods.R` now validates factor-valued fixed-effect prediction `newdata`
before model-matrix construction. Matching character values such as
`habitat = "reef"` are coerced through the fitted factor coding. Unknown values
such as `habitat = "forest"` and missing factor values now error with the
offending predictor named, instead of falling through to an internal
offset-length error. Extra factor columns not used by the requested
distributional parameter are ignored.

`tests/testthat/test-fixed-effect-basis.R` covers both routes. The positive
case checks that character levels matching the fitted factor produce the same
model matrix as explicit fitted-level factors. The negative case checks both
`drm_fixed_effect_basis()` and `predict()` for the unknown-level error. A
separate test covers missing factor values and unused factor columns.

NEWS, the Phase 17 roadmap, and the `emmeans` design note record this as
fixed-effect prediction data validation. The note mentions `emmeans` only
because the first public bridge uses the same fixed-effect basis path.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/methods.R`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-143-factor-newdata-levels.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-002704-codex-checkpoint.md`
- `tests/testthat/test-fixed-effect-basis.R`

## Checks Run

- No-edit scout:
  `predict()` with `habitat = "forest"` previously failed with
  `Internal error: fixed-effect basis offsets do not match design-matrix rows.`
- First focused test attempt caught a test fixture mistake: Poisson models do
  not accept `sigma ~ 1`; the fixture was corrected to `bf(y ~ x + habitat)`.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis', reporter = 'summary')"`:
  passed after the fixture correction; passed again after adding missing-factor
  and unused-column coverage.
- `air format NEWS.md ROADMAP.md R/methods.R docs/design/40-emmeans-interface-contract.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-143-factor-newdata-levels.md tests/testthat/test-fixed-effect-basis.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 143 unknown-factor-level wording and
  test evidence: found the expected entries.
- Stale-claim scan for accidental new-estimand or non-`mu` support claims from
  factor-level validation wording: no matches.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-002704-codex-checkpoint.md`.

## Consistency Audit

This patch changes validation and coercion of supplied prediction data. It does
not change likelihood parameterization, formula parsing, fitted coefficients,
or the supported `emmeans` target set.

The error is intentionally early: a prediction request with an unknown factor
level cannot be aligned with the fitted design matrix, so it should not proceed
to an `emmGrid`, model matrix, or offset calculation.

## Known Limitations

- The fix applies to fixed-effect prediction/newdata paths.
- It does not add new estimands, non-`mu` `emmeans` support, transformed
  responses, empirical marginalisation, random-effect workflows, or blocked
  model structures.

## Team Notes

Pat should prefer examples that show fitted levels explicitly when teaching
prediction grids. Rose should keep watching for internal-error messages that
can be converted into user-actionable validation errors.
