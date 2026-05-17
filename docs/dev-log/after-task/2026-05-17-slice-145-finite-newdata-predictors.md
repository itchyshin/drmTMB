# After Task: Slice 145 finite newdata predictors

## Goal

Reject non-finite numeric values in required fixed-effect prediction predictors
before model-matrix construction.

## Implemented

`R/methods.R` now checks required numeric predictors in fixed-effect prediction
`newdata` for finite values before building the model matrix. Values such as
`x = Inf` now error with the offending predictor named instead of flowing
through `stats::model.matrix()` to produce a non-interpretable linear
prediction.

`tests/testthat/test-fixed-effect-basis.R` covers this with a Poisson
fixed-effect `mu` fit and a prediction request containing `x = Inf`.

NEWS, the Phase 17 roadmap, and the `emmeans` design note record this as
fixed-effect prediction data validation. The note mentions `emmeans` because
the first public bridge uses the same fixed-effect basis path.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/methods.R`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-145-finite-newdata-predictors.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-004423-codex-checkpoint.md`
- `tests/testthat/test-fixed-effect-basis.R`

## Checks Run

- No-edit scout:
  `predict()` with `x = Inf` previously returned a numeric prediction rather
  than an early validation error.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis', reporter = 'summary')"`:
  passed.
- `air format NEWS.md ROADMAP.md R/methods.R docs/design/40-emmeans-interface-contract.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-145-finite-newdata-predictors.md tests/testthat/test-fixed-effect-basis.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 145 finite-newdata wording and test
  evidence: found the expected entries.
- Stale-claim scan for accidental new-estimand, non-`mu`, or new `emmeans`
  support claims from finite-value validation wording: no matches.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-004423-codex-checkpoint.md`.

## Consistency Audit

This patch changes validation of supplied prediction data only. It does not
change formula parsing, likelihood parameterization, fitted coefficients, or
the supported `emmeans` target set.

The finite-value guard is target-specific: only numeric predictors required by
the requested distributional parameter are checked.

## Known Limitations

- The fix applies to fixed-effect prediction/newdata paths.
- It does not add new estimands, non-`mu` `emmeans` support, transformed
  responses, empirical marginalisation, random-effect workflows, or blocked
  model structures.

## Team Notes

Pat should keep prediction examples explicit about finite numeric grid values.
Rose should keep watching for silent nonsensical prediction inputs that can be
turned into early validation errors.
