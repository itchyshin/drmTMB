# After task: edge tests for pedigree and known-precision helpers

## What changed

- New `tests/testthat/test-pedigree-known-precision-edges.R` (test only; no
  `R/`, `NAMESPACE`, `NEWS.md` or ledger edits). It calls the internal helpers
  in `R/phylo-utils.R` directly with `drmTMB:::`:
  `drm_standardize_pedigree`, `drm_normalize_pedigree_parent`,
  `drm_pedigree_topological_order`, `drm_pedigree_inbreeding_parent_index`,
  `drm_pedigree_quaas_ainv`, `drm_validate_known_precision_matrix`,
  `drm_covariance_to_known_precision` and
  `drm_standardize_relatedness_matrix`.
- Covered: standardised columns and order with founders coded `NA`, `"0"` and
  `""`; topological ordering of a shuffled pedigree; aborts for a cycle, a
  self-parent, a duplicated id, an unknown parent, a blank id and missing
  columns; Quaas A-inverse against `solve(A)` to 1e-10 with and without
  inbreeding (a full-sib mating gives F = 0.25); precision times covariance is
  the identity; aborts for non-square, non-finite, unnamed, duplicate-named,
  mismatched-dimname and non-positive-definite input.

## Behaviour

Characterisation only. One finding recorded as a test rather than a bug:
`drm_validate_known_precision_matrix()` and
`drm_covariance_to_known_precision()` do not abort on an asymmetric matrix;
`forceSymmetric(uplo = "U")` silently uses the upper triangle. Squareness and
dimname checks live in `drm_standardize_relatedness_matrix()`.

## Verification

- `devtools::load_all(); testthat::test_file(...)`: 0 failures, 0 skips, 66
  passes. The file adds no `skip_*` calls, so the skip census is unchanged.
- The tests pass on unmodified main because no code changed; they pin existing
  behaviour that was previously unchecked.
