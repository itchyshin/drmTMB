# After Task: Slice 146 predict newdata reference docs

## Goal

Make the `predict.drmTMB()` reference documentation state the validation
contract added by Slices 143-145.

## Implemented

`R/methods.R` now documents the `newdata` requirements for
`predict.drmTMB()`: supplied prediction data must include predictors used by
the requested `dpar`, required predictor values must be complete, required
numeric predictors must be finite, and factor predictors must use fitted
levels.

`devtools::document()` regenerated `man/predict.drmTMB.Rd`.

## Files Changed

- `R/methods.R`
- `man/predict.drmTMB.Rd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-146-predict-newdata-docs.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-010455-codex-checkpoint.md`

## Checks Run

- `air format R/methods.R`: passed.
- `Rscript -e "devtools::document()"`: passed and rewrote
  `man/predict.drmTMB.Rd`.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for the new `predict.drmTMB()` `newdata`
  wording: found the expected entries in roxygen, Rd, after-task notes, and
  rendered pkgdown reference.
- Stale-claim scan for accidental new-support language: no matches.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-010455-codex-checkpoint.md`.

## Consistency Audit

This is a documentation-only slice. It records behaviour implemented in the
preceding prediction-newdata validation slices without changing formulas,
likelihoods, fitted coefficients, prediction targets, or `emmeans` support.

## Known Limitations

- This slice does not add new prediction behaviour.
- It does not add new estimands, non-`mu` `emmeans` support, transformed
  responses, empirical marginalisation, random-effect workflows, or blocked
  model structures.

## Team Notes

Pat should keep examples and help text explicit about the columns required in
`newdata`. Rose should keep checking that documentation-only slices do not
silently imply new model support.
