# After Task: Slice 4 `corpairs()` Registry Extraction

## Goal

Make the fitted correlation-pair table use the labelled covariance-block
registry for currently implemented two-member group-level covariance blocks,
without changing accepted syntax or the TMB likelihood.

## Implemented

`corpairs.drmTMB()` now asks `object$model$random$covariance_blocks` for
group-level pair metadata before using the older label parser. Registry rows
provide the level, group, block label, distributional parameters, coefficients,
response names, pair class, and public parameter name. The fitted estimate
still comes from the existing `object$corpars` lists, matched by the registry
fields `tmb_parameter` and `tmb_index`.

The fallback parser remains active for old objects and partial transitional
objects. If a future registry covers only some fitted correlations,
`corpairs()` reports registry rows for the covered pairs and parses the
remaining `corpars` labels rather than dropping them.

Residual `rho12` reporting remains separate. This task did not add new formula
grammar, TMB data passed to `TMB::MakeADFun()`, C++ likelihood code, or new
covariance parameters.

## Mathematical Contract

This patch does not change the fitted model. It changes the reporting source
for existing two-member covariance bridges:

```text
reported pair metadata = covariance block registry
reported pair estimate  = existing fitted corpars entry
```

The block registry still represents currently implemented two-member group
blocks. Larger `q > 2` labelled blocks require a complete positive-definite
parameterization before they can become fitted models.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-corpairs.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `ROADMAP.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-4-corpairs-registry-extraction.md`

## Checks Run

- `air format R/methods.R tests/testthat/test-biv-gaussian.R tests/testthat/test-corpairs.R tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e 'devtools::test(filter = "corpairs")'`: passed with 48 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "corpairs|biv-gaussian|gaussian-random-intercepts|profile-targets|check-drm")'`: passed with 1150 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Tests Of The Tests

The new tests corrupt `names(fit$corpars$*)` after fitting and then check that
`corpairs()` still reports the registry-derived group, block, coefficient, and
parameter metadata. Another test removes one registry pair from a two-block
bivariate fit and checks that the uncovered fitted correlation still appears
through the legacy parser.

## Consistency Audit

The roadmap and slice-4 design note now state the changed order: public
extractors first, then no-op C++ visibility, then simulation scaffolding, and
only after that a `q > 2` Cholesky or `UNSTRUCTURED_CORR_t` likelihood path.
This keeps the roadmap honest: `corpairs()` is now registry-derived for covered
two-member group rows, but `profile_targets()` and `check_drm()` still need the
same treatment.

## What Did Not Go Smoothly

The first extractor bridge would have hidden uncovered `corpars` rows if a
future registry became partial. Turing/Boole-copy caught that before closeout,
and the final implementation now mixes registry rows with parsed fallback rows
instead of choosing one surface globally.

## Team Learning

Mendel/Rose-copy recommended a clearer slice-4 order: derive public reporting
from the registry before trying to consume the dormant TMB contract. That order
reduces the chance of building a second internal representation that user-facing
extractors do not trust.

## Known Limitations

`corpairs()` is the only extractor moved in this pass. `profile_targets()` and
`check_drm()` still contain pair-specific logic for the current covariance
bridges. The dormant `random$covariance_blocks$tmb_data` contract is still not
passed to C++ and still supports only two-member blocks.

## Next Actions

1. Route `check_drm()` covariance diagnostics through the block registry while
   preserving the current diagnostic names and messages.
2. Route random-effect correlation target inventory through the same registry
   surface in `profile_targets()`.
3. Add a no-op C++ visibility pass for the two-member block contract before
   attempting any `q > 2` likelihood.
