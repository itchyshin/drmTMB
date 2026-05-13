# After Task: Slice 4 `profile_targets()` Registry Inventory

## Goal

Make random-effect correlation rows in `profile_targets()` use the labelled
covariance-block registry for currently implemented two-member group-level
blocks, while preserving the public target inventory.

## Implemented

`drm_profile_targets()` now adds registry-derived random-effect correlation
targets before falling back to the older `corpars` name parser. Registry rows
provide the canonical correlation target name and TMB parameter mapping. Fitted
estimates still come from the existing `object$corpars` entries.

For old or partial objects, any fitted correlation not covered by the registry
is still reported through the legacy parser. Fixed-effect targets, random-effect
SD targets, constant `sigma` targets, residual `rho12` targets, and ordinal
internal targets were not changed.

## Mathematical Contract

This patch does not change profile likelihood evaluation. It changes the
inventory source for current random-effect correlation targets:

```text
target metadata = covariance block registry
target estimate = existing fitted corpars entry
target index    = registry tmb_index
```

The profile target remains a direct one-dimensional TMB parameter target on the
same transformed correlation scale as before.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `tests/testthat/test-biv-gaussian.R`
- `ROADMAP.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-4-profile-target-registry-inventory.md`

## Checks Run

- `air format R/profile.R tests/testthat/test-profile-targets.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "profile-targets")'`: passed with 215 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "profile-targets|biv-gaussian|gaussian-random-intercepts|corpairs|check-drm")'`: passed with 1159 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Tests Of The Tests

The new tests corrupt fitted `corpars` names after fitting for ordinary
`mu` correlations, univariate `mu`/`sigma`, bivariate `mu1`/`mu2`, bivariate
`sigma1`/`sigma2`, and same-response bivariate `mu`/`sigma`. The expected
target names still appear, proving that `profile_targets()` is taking metadata
from the registry for covered pairs.

## Consistency Audit

The roadmap and slice-4 design note now state that `corpairs()`,
`check_drm()`, and `profile_targets()` are registry-backed for covered
two-member group-level covariance pairs. The next slice is therefore C++
visibility for the dormant two-member block contract, not `q > 2` likelihood.

## What Did Not Go Smoothly

The previous counter-based correlation loop assigned target indices implicitly.
The registry path needed to preserve the original one-based TMB index directly,
and the fallback path needed to skip only covered `dpar:index` pairs rather
than all of `object$corpars`.

## Team Learning

Extractor migrations should keep the old target names and direct TMB indices as
the acceptance test. That is the user-facing contract that downstream profiling
and confidence-interval code depends on.

## Known Limitations

The dormant block TMB data is still not passed to C++. Larger `q > 2` labelled
blocks remain planned and need a positive-definite parameterization plus
simulation recovery before exposure.

## Next Actions

1. Pass the two-member block contract through the C++ boundary as a no-op
   visibility check.
2. Add a guarded three-member simulation scaffold.
3. Prototype a positive-definite `q > 2` block parameterization.
