# After Task: Slice 144 required newdata variables

## Goal

Validate that fixed-effect prediction `newdata` supplies every required
predictor for the requested distributional parameter and has complete values
before model-matrix construction.

## Implemented

`R/methods.R` now checks the target formula variables before building the
fixed-effect prediction matrix. Missing required columns now error with the
missing predictor named. Missing values in required predictors now error before
`stats::model.matrix()` can drop rows and trigger an internal offset-length
error. Extra columns not used by the requested distributional parameter remain
harmless.

`tests/testthat/test-fixed-effect-basis.R` covers missing required factor
columns, missing numeric values, and extra unused columns.

NEWS, the Phase 17 roadmap, and the `emmeans` design note record this as
fixed-effect prediction data validation. The note mentions `emmeans` because
the first public bridge uses the same fixed-effect basis path.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/methods.R`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-144-required-newdata-variables.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-003323-codex-checkpoint.md`
- `tests/testthat/test-fixed-effect-basis.R`

## Checks Run

- No-edit scout:
  `predict()` with missing `habitat` previously failed with
  `object 'habitat' not found`; `predict()` with `x = NA_real_` failed with
  `Internal error: fixed-effect basis offsets do not match design-matrix rows`.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis', reporter = 'summary')"`:
  passed.
- `air format NEWS.md ROADMAP.md R/methods.R docs/design/40-emmeans-interface-contract.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-144-required-newdata-variables.md tests/testthat/test-fixed-effect-basis.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 144 required-newdata wording and
  test evidence: found the expected entries.
- Stale-claim scan for accidental new-estimand, non-`mu`, or new `emmeans`
  support claims from required-predictor validation wording: no matches.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-003323-codex-checkpoint.md`.

## Consistency Audit

This patch changes validation of supplied prediction data only. It does not
change formula parsing, likelihood parameterization, fitted coefficients, or
the supported `emmeans` target set.

The validation is intentionally target-specific: predictors used by the
requested distributional parameter are required and must be complete; columns
not used by that target formula are ignored.

## Known Limitations

- The fix applies to fixed-effect prediction/newdata paths.
- It does not add new estimands, non-`mu` `emmeans` support, transformed
  responses, empirical marginalisation, random-effect workflows, or blocked
  model structures.

## Team Notes

Pat should keep prediction examples explicit about required columns in
`newdata`. Rose should continue watching for base R or internal errors that can
be converted into target-specific validation messages.
