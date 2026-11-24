# After Task: Julia refuses all-singleton random-effect groups (#1776)

## Goal

`engine = "julia"` fitted `y ~ x + (1 | g)` with every group a singleton,
reported convergence, and split the unidentified variance between sigma and the
group SD. Native `engine = "tmb"` refuses. Decided by Shinichi
(SHINICHI-0900-1119): Julia refuses too, with the same wording.

## Implemented

The native check is now a shared helper, `drm_refuse_all_singleton_groups()` in
`R/drmTMB.R`, used by both native builders (message text unchanged) and by a new
pre-check `drm_julia_refuse_all_singleton_groups()` in `R/julia-bridge.R`. The
pre-check walks every ordinary `(... | g)` bar in every formula entry (mean and
`sd()` scale side) and runs before the later route gates and before Julia starts.
Bars whose group is not a plain column name (for example `a:b`) are skipped, as
before.

## Mathematical Contract

No likelihood, parameterization, or formula grammar changed.

## Files Changed

- `R/drmTMB.R`, `R/julia-bridge.R`
- `tests/testthat/test-julia-singleton-groups-refuse.R`
- `inst/extdata/env-skip-census.tsv` (regenerated; one new live-Julia skip site)
- `NEWS.md`, `vignettes/julia-engine.Rmd`

## Checks Run

Narrow tests in R: new file (9 pass, 1 live-Julia skip), `test-julia-bridge-default-labels.R`,
`test-julia-ordinary-laplace-bridge.R`, `test-env-skip-census.R`,
`test-gaussian-random-intercepts.R` (native message unchanged). Live Julia was
not available here.

## Tests Of The Tests

The pure-R test compares the Julia and TMB error messages for equality for
gaussian and poisson, so a wording drift fails it. It also checks that one
repeated group is enough to pass.

## Consistency Audit

Moved expectations: none. No existing test changed. The non-Gaussian cases in the
issue (nbinom2, binomial) go through the same pre-check, which does not depend on
family; only gaussian and poisson are exercised by test.

## Team Learning

When a native refusal exists, share the helper rather than copy the wording.

## Known Limitations

The live Julia test is skipped without DRM.jl. Nested or interaction groups
(`a:b`, `a/b`) are not checked on the Julia route.

## Next Actions

None for this slice.
