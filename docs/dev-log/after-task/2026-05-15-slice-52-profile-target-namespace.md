# After Task: Slice 52 Profile Target Namespace Cleanup

## Goal

Stabilize the `profile_targets()` inventory before adding more profile
intervals. Slice 52 should make target names, transformations, `target_type`,
`profile_ready`, and unavailable-status wording hard to drift.

## Implemented

- Added an internal `validate_profile_targets()` guard in `R/profile.R`.
- Made `profile_ready = TRUE` require both a direct target and a retained TMB
  object.
- Added `profile_note = "tmb_object_required"` for direct targets in
  memory-light fits created with `drm_control(keep_tmb_object = FALSE)`.
- Added focused contract tests for representative target classes in
  `tests/testthat/test-profile-targets.R`.
- Regenerated `man/profile_targets.Rd`.
- Updated `NEWS.md`, `ROADMAP.md`, `docs/design/12-profile-likelihood-cis.md`,
  and the check log.

## Contract

`profile_targets(fit)` now has a controlled vocabulary:

- `target_type`: `direct` or `derived`;
- `profile_note`: `ready`, `tmb_object_required`,
  `missing_tmb_parameter`, `derived_target`, or
  `derived_unstructured_correlation`;
- `transformation`: `linear_predictor`, `exp`, `rho12_tanh`, `tanh`,
  `derived_group_scale`, `unstructured_corr`, or `ordered_cutpoint`.

A derived row cannot be profile-ready. A direct row is profile-ready only when
the fitted object still has the TMB automatic-differentiation object needed by
`TMB::tmbprofile()`.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `man/profile_targets.Rd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-slice-52-profile-target-namespace.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "profile-targets", reporter = "summary")'`
- `Rscript -e 'devtools::document()'`
- `PATH=/opt/homebrew/bin:$PATH air format R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/profile_targets.Rd`
- `Rscript -e 'devtools::test(filter = "profile-targets|corpairs|summary", reporter = "summary")'`
- `Rscript -e 'devtools::test(reporter = "summary")'`
- `Rscript -e 'pkgdown::build_site()'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `git diff --check`
- `rg -n "tmb_object_required|validate_profile_targets|Target Namespace Contract|keep_tmb_object = FALSE|profile_ready = TRUE|Slice 52" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-15-slice-52-profile-target-namespace.md man/profile_targets.Rd pkgdown-site/ROADMAP.html pkgdown-site/reference/profile_targets.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`

## Consistency Audit

The new status `tmb_object_required` closes a real inconsistency from the
large-data path: memory-light fits intentionally drop `fit$obj`, so they should
not advertise direct profile intervals as ready. They still list the target
names so users know what to request after refitting with the TMB object kept.

The q4 ordinary and phylogenetic correlation rows remain derived
unstructured-correlation targets. Slice 52 does not turn those Cholesky-derived
point estimates into direct profile-likelihood intervals.

## What Did Not Go Smoothly

Nothing material. The risky part was changing the meaning of `profile_ready`;
the focused tests stayed green after the TMB-object requirement was added.

## Team Learning

- Ada should keep Phase 6 changes small enough that target names, interval
  status, and docs can be reviewed together.
- Boole should treat `parm` as the public name and `tmb_parameter` as a
  diagnostic implementation mapping.
- Gauss should keep direct profile readiness tied to the retained TMB object,
  not just the optimizer parameter vector.
- Noether should preserve the direct-versus-derived distinction before any
  nonlinear interval method is added.
- Fisher should keep bounded variance and correlation intervals on the profile
  path, while marking unsupported derived intervals explicitly.
- Pat should see clear repair advice: refit with
  `drm_control(keep_tmb_object = TRUE)` when `profile_note` says
  `tmb_object_required`.
- Grace should keep `profile-targets`, `corpairs`, and `summary` tests together
  because they share status vocabulary.
- Rose should watch for stale docs that say a target is ready without checking
  `profile_ready`.

## Known Limitations

Slice 52 does not add new confidence-interval algorithms, profile plots,
fix-and-refit derived intervals, or q4 correlation profile intervals. Those
remain later Phase 6 slices.

## Next Actions

Slice 53 should harden direct `TMB::tmbprofile()` failure paths, especially
one-target-only errors, optimizer failures, and messages that tell the user
which target inventory row caused the stop.
