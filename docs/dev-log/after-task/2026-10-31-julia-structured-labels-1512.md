# After task: Julia bridge keeps structured-matrix labels (#1512)

Reader: a drmTMB user who fits `relmat()`, `animal()` or Gaussian `spatial()`
with `engine = "julia"` and passes a labelled matrix in an order other than
first appearance in `data`.

## Goal

Close #1512. PR #1533 (merged 2026-10-25) already aligns a labelled K / A by
name, but the issue stayed open because the live tmb-vs-julia repro had not
been run. This task runs it, adds a live regression test, and fixes one
sibling path with the same bug.

## Implemented

- Ran the issue's BTdata / `nadiv::makeA()` repro live. All four fits agree.
- Added a live test: a labelled `relmat()` K in sorted, shuffled and
  first-appearance order must each give the `engine = "tmb"` logLik.
- Sibling fix: `drm_julia_structured_matrix()` dropped the row names of
  `spatial(coords = )` before `standardize_spatial_coords()`, which the native
  engine uses to match per-site rows to sites by name. Labelled coords in any
  other order were paired with the wrong sites. The row names are now kept.

## Files Changed

- `R/julia-bridge.R`: keep coords row names (3 lines).
- `tests/testthat/test-julia-structured.R`: offline spatial-coords test and
  live relmat order test.
- `NEWS.md`

`R/drmTMB.R` and `R/methods.R` are unchanged, so C17 needs no recertification.

## Checks Run

Live checks used DRModels.jl `origin/main` at 64ccb2d8d, Julia 1.12.6.

- Issue repro (BTdata, A from `nadiv::makeA(BTped)`): logLik -1038.32705375
  for tmb and for julia with A in first-appearance, sorted and shuffled order;
  mu coefficients equal to 10 digits.
- New offline spatial test: failed before the fix (K rows permuted), passes
  after.
- `test-julia-structured.R` with live Julia: 0 failures, 2 live tests ran.
- Negative control for the live test: the same data with the sorted K's names
  stripped gives logLik -141.936706033 against tmb -139.856328717, so the test
  can fail.
- Full `devtools::test()`: see the PR body.

## Tests Of The Tests

The spatial test was red before the fix. The live relmat test was checked by
the negative control above.

## Consistency Audit

Both callers of `drm_julia_structured_matrix()` (univariate and bivariate q2
structured payloads) get the coords fix. `drm_julia_as_matrix()` other callers
pass design matrices, where names are not used for matching.

## What Did Not Go Smoothly

DRModels.jl's `drm_bridge` aligns by label and then calls `drm()` with the
aligned bare matrix, so `drm()` prints its "`A` has no labels" warning once per
session even though the labels were used. That is cosmetic and lives in
DRModels.jl; it is not changed here.

## Team Learning

An issue left open for a missing live repro can be closed by running it; the
rerun also found a sibling path the code read had missed.

## Known Limitations

Not covered: live parity for `spatial(coords = )` (the offline test checks
the K sent to Julia against native), and non-Gaussian structured families.

## Next Actions

Owner: decide whether DRModels.jl should silence the "`A` has no labels"
warning when `drm_bridge` has already aligned by label.
