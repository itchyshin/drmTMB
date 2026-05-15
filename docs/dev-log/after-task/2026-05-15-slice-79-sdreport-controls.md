# After Task: Slice 79 Standard-Error And sdreport Controls

## Goal

Make optimized `drmTMB` fits survive intentional or accidental absence of
`TMB::sdreport()` without pretending that Wald uncertainty is available.

## Implemented

- Added `drm_control(se = TRUE)` with `se = FALSE` as an opt-in path that
  skips `TMB::sdreport()` after optimization.
- Added `fit$uncertainty` with `status = "ok"`, `"skipped"`, or `"failed"`
  and a user-facing message.
- Wrapped requested `sdreport()` failures so `drmTMB()` still returns the
  optimized fit, with Wald uncertainty marked unavailable.
- Made `vcov()` fail clearly when the fixed-effect covariance is unavailable,
  including the recovery action to refit with
  `control = drm_control(se = TRUE)`.
- Made `summary()` keep point estimates while marking unavailable standard
  errors with `std_error.status`, and made Wald interval requests return
  `conf.status = "wald_unavailable"` instead of fabricated intervals.
- Added a first-class `sdreport_status` row to `check_drm()` and separated
  deliberate skipping, which is a note, from requested `sdreport()` failure,
  which is a warning.
- Rejected ambiguous plain lists such as `control = list(se = FALSE)` so users
  do not accidentally pass `se` as an optimizer control.

## Mathematical Contract

The optimized likelihood, coefficient estimates, log-likelihood, fitted values,
residuals, predictions, simulations, and profile-likelihood routes that retain
`fit$obj` do not require the fixed-effect covariance matrix from
`TMB::sdreport()`. Wald standard errors, `vcov()`, Hessian-positive status from
`sdreport()`, and Wald confidence intervals do require that covariance state.
Slice 79 makes that distinction explicit in the fitted object and downstream
methods.

## Files Changed

- `R/control.R`
- `R/drmTMB.R`
- `R/methods.R`
- `R/check.R`
- `tests/testthat/test-control.R`
- `README.md`
- `vignettes/large-data.Rmd`
- `vignettes/model-map.Rmd`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/design/23-large-data-memory.md`
- `ROADMAP.md`
- `NEWS.md`
- `man/check_drm.Rd`
- `man/drm_control.Rd`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format R/control.R R/drmTMB.R R/methods.R R/check.R tests/testthat/test-control.R NEWS.md ROADMAP.md docs/design/23-large-data-memory.md docs/design/12-profile-likelihood-cis.md vignettes/large-data.Rmd`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "control|summary|check-drm|profile-targets", reporter = "summary")'`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::document()'`:
  passed and updated `man/check_drm.Rd` and `man/drm_control.Rd`.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(reporter = "summary")'`:
  passed after the final profile-retention assertion was added.
- `git diff --check`: passed.
- Source and rendered-site scans confirmed `se = FALSE`,
  `sdreport_status`, `sdreport_skipped`, `sdreport_failed`,
  `wald_unavailable`, and `control = drm_control(se = TRUE)` appear in the
  intended implementation, docs, generated reference, and pkgdown pages.
- Stale-wording scans found only valid historical NEWS/check-list wording for
  finite standard-error diagnostics and no remaining unconditional claim that
  Wald intervals are always available.

## Tests Of The Tests

- The new tests cover the intentional skip path, ambiguous plain-list control
  path, Wald `vcov()`/`confint()` failure path, summary fallback, `check_drm()`
  note status, and a retained-object profile interval under `se = FALSE`.
- The synthetic failed-`sdreport()` test mutates an otherwise valid fit to
  verify that summary and diagnostics distinguish failure from deliberate
  skipping.

## Consistency Audit

- Ada kept the public API narrow: `drm_control(se = FALSE)` is the only new
  user-facing knob.
- Boole flagged the ambiguous `control = list(se = FALSE)` route; it now errors
  with a direction to use `drm_control()`.
- Gauss and Noether treated `sdreport()` as uncertainty state, not likelihood
  state: point estimates and profile routes remain separate from Wald routes.
- Pat and Grace pushed for recovery messages and pkgdown visibility; `vcov()`,
  `summary()`, the large-data article, and rendered reference pages now say
  what to do next.
- Rose checked that the stable-core matrix now conditions Wald intervals on
  `sdreport()` being computed.

## What Did Not Go Smoothly

- The first formatting and `Rscript` commands failed because this shell needed
  `/usr/local/bin:/opt/homebrew/bin` added to `PATH`. Subsequent commands used
  that explicit prefix.
- The initial design relied on `summary()` catching `vcov()` errors; Maxwell
  pointed out that Wald summaries should be gated by known uncertainty state
  rather than broad error catching.
- The local `gh` CLI is not installed. GitHub connector lookup showed one open
  PR, `itchyshin/drmTMB#45`, so this slice was not turned into a new PR in this
  step.

## Team Learning

- Ada: keep optimizer success and uncertainty availability as separate fitted
  object states.
- Boole: reject reserved `drm_control()` names in plain optimizer lists before
  they reach `nlminb()`.
- Gauss: a skipped Hessian is not a numerical warning; a failed requested
  Hessian is.
- Noether: profile likelihood can remain available under `se = FALSE` if the
  TMB object is retained.
- Pat: print and summary methods need a prominent "point estimates only" cue.
- Grace: generated docs and pkgdown pages must carry the same availability
  boundary as the R methods.
- Rose: status inventories should name conditional interval availability, not
  just list the happy path.

## Known Limitations

- `se = FALSE` does not reduce memory used during model construction or
  optimization; it only skips/stores less post-optimization standard-error
  state.
- `summary(conf.int = TRUE, method = "wald")` marks fixed-effect intervals
  unavailable when `sdreport()` is unavailable; it does not attempt a fallback
  bootstrap or sandwich estimator.
- The failed-`sdreport()` branch is unit-tested by mutation rather than by a
  naturally failing TMB fit, to keep the test deterministic.
- GitHub Actions remains the PR-side gate after this branch is pushed.

## Next Actions

- Continue Phase 6d with Slice 80: optimizer, start, map, and multi-start
  design.
- Coordinate with the remaining open PR before opening another review branch.
