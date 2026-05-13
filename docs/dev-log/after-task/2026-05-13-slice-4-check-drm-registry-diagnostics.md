# After Task: Slice 4 `check_drm()` Registry Diagnostics

## Goal

Make the existing covariance diagnostics in `check_drm()` read the labelled
covariance-block registry for currently implemented two-member group-level
blocks, without changing the diagnostic rows users already see.

## Implemented

`check_drm()` now looks up covered covariance pairs in
`object$model$random$covariance_blocks` before using the older pair-specific
random-effect structures. The registry-backed path covers:

- univariate `mu`/`sigma` random-intercept covariance;
- bivariate `mu1`/`mu2` random-intercept covariance;
- bivariate `sigma1`/`sigma2` random-intercept covariance;
- same-response bivariate `mu`/`sigma` random-intercept covariance.

The diagnostic row names, value fields, statuses, and messages are preserved.
Objects without a registry still use the existing fallback logic.

## Mathematical Contract

This patch does not change any fitted model. It changes the metadata source for
diagnostics:

```text
diagnostic block membership = covariance block registry
diagnostic fitted SDs       = existing sdpars
diagnostic residual scales  = existing sigma() extractors
```

The interpretation remains the same: `check_drm()` warns when group replication
is weak or when a fitted component SD is too small for a reliable covariance
interpretation.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `tests/testthat/test-biv-gaussian.R`
- `ROADMAP.md`
- `docs/design/30-labelled-covariance-block-assembler.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-4-check-drm-registry-diagnostics.md`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "check-drm")'`: passed with 96 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter = "check-drm|biv-gaussian|gaussian-random-intercepts|corpairs|profile-targets")'`: passed with 1153 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Tests Of The Tests

The singleton-group diagnostic tests now mutate
`fit$model$random$covariance_blocks$members$latent_index0` directly. This makes
the failure path prove that `check_drm()` is reading registry members, not the
older `model$random$mu` or `model$random$sigma` index arrays by accident.

## Consistency Audit

The roadmap and slice-4 design note now state that `corpairs()` and
`check_drm()` are registry-backed for covered two-member group rows. They still
state that `profile_targets()` registry derivation, C++ contract visibility,
and simulation recovery are required before larger shared labels can be exposed.

## What Did Not Go Smoothly

The original tests mutated the old random-effect index arrays. That was useful
for the old implementation but would not have tested the new registry-backed
path. Mill/Curie-copy identified the exact row contracts to preserve, and Ada
retargeted the mutation tests to the registry member table.

## Team Learning

The safest slice-4 migration pattern is now clear: move one public surface at a
time, preserve the old row contract, and make at least one test mutate the new
registry source so the test cannot pass through the old path.

## Known Limitations

`profile_targets()` still uses pair-specific logic for the current random-effect
correlation target inventory. The dormant block TMB data is still not passed to
C++, and `q > 2` labelled blocks remain unimplemented.

## Next Actions

1. Route random-effect correlation rows in `profile_targets()` through the
   covariance block registry.
2. Add a no-op C++ visibility pass for the two-member block contract.
3. Add a guarded three-member simulation scaffold before enabling any
   positive-definite `q > 2` likelihood.
