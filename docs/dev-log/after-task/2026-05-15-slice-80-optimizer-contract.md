# After Task: Slice 80 Optimizer, Start, Map, And Multi-Start Contract

## Goal

Record the optimizer/start/map contract before public starts, fixed parameters,
fallback optimizers, or multi-start fitting are exposed, and make current TMB
callbacks use the selected optimizer result consistently.

## Implemented

- Added `docs/design/35-optimizer-start-map-multistart.md`.
- Reserved future control names in plain optimizer lists and inside
  `drm_control(optimizer = list(...))`: `start`, `starts`, `map`, `fixed`,
  `fallback_optimizer`, `multi_start`, and `multistart`.
- Added `fit$tmb_state` to store the selected TMB `last.par` and
  `last.par.best` state at the chosen optimum.
- Added `drm_pin_tmb_object_to_optimum()` and call it before
  `TMB::sdreport()` and before profile-likelihood calls.
- Updated `drm_tmbprofile()` so profiles re-pin the TMB object to the stored
  selected state before calling `TMB::tmbprofile()`.
- Added focused tests for reserved names, reported quantities from
  `opt$par`, fixed-effect profile repair after stale TMB state, and
  random-effect state preservation.

## Mathematical Contract

The selected optimum is `fit$opt$par`. Coefficients, `sdpars`, `corpars`,
`TMB::sdreport()`, and profile intervals must be tied to that selected
optimizer result, not to whichever mutable TMB state happens to remain in
`obj$env$last.par` after a prior callback. For random-effect models,
`last.par` contains fixed and latent random-effect mode slots, so pinning must
restore the selected full TMB state rather than replacing it with the
fixed-only `opt$par`.

## Files Changed

- `R/control.R`
- `R/drmTMB.R`
- `R/profile.R`
- `tests/testthat/test-control.R`
- `tests/testthat/test-optimizer-contract.R`
- `docs/design/35-optimizer-start-map-multistart.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format R/control.R R/drmTMB.R R/profile.R tests/testthat/test-control.R tests/testthat/test-optimizer-contract.R docs/design/35-optimizer-start-map-multistart.md ROADMAP.md NEWS.md`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "optimizer-contract|control|profile-targets", reporter = "summary")'`:
  failed on the first attempt because the initial pinning helper overwrote
  TMB's full fixed-plus-random `last.par` state with fixed-only `opt$par`.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "optimizer-contract|control|profile-targets", reporter = "summary")'`:
  passed after storing and restoring `fit$tmb_state`.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(reporter = "summary")'`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`:
  passed with 0 errors, 0 warnings, and 0 notes in 2m 23.8s.
- `git diff --check`: passed.
- Source and rendered-site scans confirmed the Slice 80 contract, reserved
  names, selected-`opt$par` wording, and NEWS/ROADMAP rendered output.
- Stale-claim scans found only future-contract examples in the design doc and
  no README/model-map claim that public start/map/multi-start support exists.

## Tests Of The Tests

- The first profile-target run failed before the random-effect-safe pinning
  repair, catching the exact risk this slice is meant to prevent.
- The new random-effect test corrupts mutable TMB state, restores from
  `fit$tmb_state`, and verifies fixed slots, random-mode slots, and
  `ranef()` remain finite.
- The profile test corrupts a fixed-effect fit's TMB state and verifies a
  profile interval still contains the selected coefficient estimate.

## Consistency Audit

- Ada kept the slice as contract and internal invariant work, not public start
  or multi-start support.
- Boole ensured reserved names error before reaching `nlminb()`.
- Gauss caught the fixed-only pinning bug for random-effect profiles.
- Noether required `fit$coefficients`, `sdpars`, `corpars`, `sdreport()`, and
  profiles to share the same selected optimum.
- Pat pushed the error wording toward "reserved future control name" rather
  than implying implemented support.
- Grace required pkgdown, full tests, and `devtools::check()` because mutable
  TMB state handling changed.
- Rose checked that README/model-map did not gain a new fitted-surface claim.

## What Did Not Go Smoothly

- The first helper treated TMB state as fixed-parameter-only. That was true for
  simple fixed-effect fits but wrong for random-effect models. The targeted
  `profile-targets` run caught this before commit.
- `last.par.best` can appear as fixed-only or full fixed-plus-random state
  depending on TMB operations. Storing the selected state at fit time is safer
  than reconstructing it later from fixed slots.

## Team Learning

- Ada: public starts/maps should wait until the namespace, transformed scale,
  degrees-of-freedom, and diagnostic contracts are all implemented together.
- Boole: reserve future names now so users do not accidentally rely on
  misspelled or silently ignored optimizer controls.
- Gauss: never overwrite full TMB state with fixed-only vectors in
  random-effect models.
- Noether: "selected optimum" means both fixed parameters and the associated
  latent random-effect modes.
- Grace: profile tests are the right smoke alarm for mutable TMB state changes.
- Rose: design docs should say "reserved" and "planned" plainly when no public
  API exists yet.

## Known Limitations

- Public `start`, `map`, `fixed`, `fallback_optimizer`, and `multi_start`
  controls remain planned, not implemented.
- The future `fixed` name means fixed or mapped TMB parameters, not fixed
  effects in a regression formula.
- The current implementation still uses one primary `nlminb()` optimization.
- GitHub Actions remains the PR-side gate after push.

## Next Actions

- Continue Phase 6d with Slice 81: dense covariance and large-data guardrails.
- Do not open a new PR until the remaining open PR is coordinated.
