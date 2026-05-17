# After Task: Slice 128 emmeans transformed-predictor recovery

## Goal

Add explicit evidence that the first fixed-effect univariate `mu` `emmeans()`
bridge can recover raw source variables for ordinary transformed predictors.
The concrete test case is `log(size)`, with the reference grid supplied through
`at = list(size = 1.5)`.

## Implemented

`tests/testthat/test-emmeans-methods.R` now fits a Gaussian fixed-effect `mu`
model with `log(size)` and checks that `emmeans::emmeans()` at `size = 1.5`
matches `predict(dpar = "mu")` on both link and response scales.

`tests/testthat/test-emmeans-recover-data.R` now checks the recovery side
directly: the preflight returns the raw `size` column in the retained model
frame and records `size` as a predictor for the first `mu` path.

NEWS, the Phase 17 roadmap, and the `emmeans` design notes now make this
transformed-predictor coverage visible without claiming transformed-response,
slope, custom-weight, non-`mu`, or blocked-model support.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-128-emmeans-transformed-predictor.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-211819-codex-checkpoint.md`
- `tests/testthat/test-emmeans-methods.R`
- `tests/testthat/test-emmeans-recover-data.R`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md tests/testthat/test-emmeans-methods.R tests/testthat/test-emmeans-recover-data.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 128 transformed-predictor wording and
  tests: found the expected entries.
- Stale-claim scan for transformed predictors as unsupported or planned in the
  `emmeans` contract: no matches.
- `git diff --check`: passed.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-16-211819-codex-checkpoint.md`.

Post-rebase checks:

- PR #92 merged as `f52b692f6a53925336286e723022bd3184400fec`.
- `git rebase --onto origin/main 8d98ae1c6897c47d1e9c3cd44ac0fa5cba87d7e5`:
  passed.
- `git diff --check origin/main...HEAD`: passed.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|emmeans-recover-data|emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.

## Consistency Audit

This slice is deliberately narrower than a transformed-response feature.
`log(size)` is a predictor transformation inside the fixed-effect `mu` formula;
the EMM target remains the native distributional parameter `mu`. Slopes, custom
weights, non-`mu` targets, transformed responses, and blocked model structures
still need separate algebra and tests before support can be advertised.

## Known Limitations

- Coverage is limited to ordinary transformed predictors whose raw source
  variables are available in stored data.
- No transformed-response, slope, custom-weight, non-`mu`, or blocked-model
  workflow is added.

## Team Notes

Curie should keep using local-scope tests for recovery work. Rose should keep
checking that "transformed predictor" is not accidentally described as
"transformed response" in future docs.
