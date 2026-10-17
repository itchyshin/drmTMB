# After task: engine = "julia" keeps K/A dimnames (#1512)

Lane B, Refs #1512. Paired DRModels.jl PR: itchyshin/DRModels.jl#1068.

## Change
`drm_julia_structured_matrix()` (R/julia-bridge.R) now aligns a labelled
`relmat()` K / `animal()` A to the first-appearance order of the grouping
variable before `drm_julia_as_matrix()` strips the dimnames. DRModels.jl pairs
row i with the i-th group in that order and never sees names.

- Labelled and alignable: reordered by name (as.character matching).
- Labelled but unalignable (duplicates, row/column names differ, a group level
  missing): classed error `drmTMB_julia_structured_labels`.
- Unlabelled: unchanged, with classed warning
  `drmTMB_julia_unlabelled_structured_matrix` (the order cannot be checked).

## Tests
`tests/testthat/test-julia-structured.R`: shuffled labelled K/A give the same
aligned matrix; numeric ids; refusals; unlabelled warning. Pure R, no Julia.

## Review round (2026-10-16)
- Levels come from the rows actually sent: both structured bridges
  (`drmTMB_julia_structured_bridge`, `drmTMB_julia_biv_known_structured_bridge`)
  now drop incomplete rows before the payload, as the non-structured bridge does
  (#694). Previously a row dropped for `NA` left its group level in the
  alignment. Side effect: the stored `data`/`nobs` of a structured Julia fit are
  the complete cases, as for the non-structured route.
- The aligned matrix's row names cross as `K_labels` / `A_labels` with
  `structured_group` (`drm_julia_call_structured()` -> `drmTMB_drm_bridge_structured`),
  so DRModels.jl re-aligns by name or refuses (DRModels.jl#1068). Spatial
  (coords-derived K) and unlabelled matrices send no labels. The Julia glue only
  forwards the keywords when present.
- Numeric ids: `drm_julia_group_key()` writes integer-valued doubles without a
  decimal point or exponent (`1e5` -> `"100000"`); DRModels.jl's `_group_label`
  does the same for `Float64` ids, so R `"1"` matches Julia `1.0`.

## Not done / caveats
- The container had no R: tests, `devtools::document()` and the full suite were
  NOT run here. No roxygen was changed, so no man/ or NAMESPACE diff is expected.
- The live engine = "julia" vs "tmb" logLik comparison from the issue repro was
  not run (needs Julia + nadiv/MCMCglmm).
- The bridge does not yet pass labels through to DRModels.jl's new
  `K_labels`/`A_labels`; the R-side reorder alone fixes the bug.
