# After Task: Julia Bridge Intentional Gate Registry

## Goal

Start `drmTMB#544` with a small CI-enforced gate ledger. The immediate problem
is not that every R-side rejection is wrong; it is that intentional rejections,
stale rejections, and accidental bridge drift have been living in the same
place. This slice names the current intentional `engine = "julia"` rejections
and tests representative calls so future gate changes are visible.

## Implemented

- Added internal `drm_julia_intentional_gates()` in `R/julia-bridge.R`.
- Added registry rows for the current base bridge, bivariate q4 phylo bridge,
  structured-covariance bridge, and cross-family bridge.
- Added `tests/testthat/test-julia-gate-vs-engine.R` to assert that each named
  registry row corresponds to a representative pre-JuliaCall error.

## Claim Boundary

This is a guard slice, not a new model capability. It does not relax any gate
and does not prove that the R wrapper is now synchronized with every DRM.jl
engine feature. The full `drmTMB#544` task still needs the generated/audited
comparison against the DRM.jl capability table and follow-up bridge parity
tests for newly admitted cells.

## Files Changed

- `R/julia-bridge.R`
- `tests/testthat/test-julia-gate-vs-engine.R`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format R/julia-bridge.R tests/testthat/test-julia-gate-vs-engine.R`
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-gate-vs-engine.R", reporter = "summary")'`
  - Result: 54 passes, 0 failures, 0 warnings, 0 skips.
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-bridge.R", reporter = "summary")'`
  - Result: 85 passes, 0 failures, 0 warnings, 0 skips.
- `Rscript --vanilla -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-julia-sigma-phylo-reml.R", reporter = "summary")'`
  - Result: 17 passes, 0 failures, 0 warnings, 1 guarded live-engine skip.
- `git diff --check`

## Rose Audit Notes

The registry prevents a quiet class of drift: a future agent can no longer
delete, soften, or add a Julia bridge rejection without changing a named row or
breaking a representative gate test. The registry is still manually curated,
so it should not be treated as the final capability source of truth.

## Ayumi Boundary

The Ayumi q4 REML bridge-forwarding fix is already separate from this slice.
Native `engine = "tmb"` is still not a full REML fallback for the bivariate q4
phylogenetic location-scale model. It is useful for supported reduced or
point-estimate checks, but the Julia route remains the diagnostic route for
boundary SD profile/bootstrap work in this q4 model until native TMB REML is
implemented and verified for that cell.

## Next Actions

1. Extend this registry into the full `drmTMB#544` generated/audited
   gate-versus-engine matrix.
2. Add bridge parity tests when a registry row is promoted from intentional
   rejection to supported route.
3. Keep `engine_control` as the future explicit Julia-control surface rather
   than overloading the current `control` argument.
