# Slice 208 Meta-Analysis Reader Examples

## Goal

Make the meta-analysis tutorial and design examples teach the implemented
preferred spelling, `meta_V(V = V)`, without hiding the compatibility alias.

## What Changed

- Updated the meta-analysis vignette so fitted univariate, repeated-study, and
  bivariate examples use `meta_V(V = V)`.
- Kept `meta_known_V(V = V)` visible as a compatibility alias, not as the main
  teaching syntax.
- Updated the meta-analysis design note examples for vector `V`, dense matrix
  `V`, heterogeneous residual `sigma`, multiple variance components, bivariate
  row-paired `V`, and phylogenetic-plus-study examples.
- Updated the formula grammar and roadmap wording that still described
  `meta_V(V = V)` as only a future replacement.
- Added NEWS and check-log entries.

## Role Notes

- Pat checked the user path: the first runnable example now uses the same
  syntax that the reference page exports.
- Darwin kept the restoration, repeated-study, and bivariate examples as
  biological examples rather than abstract syntax only.
- Boole kept the compatibility alias visible but not dominant.
- Fisher kept the weights and proportional-variance warning adjacent to the
  examples that users are likely to copy.
- Grace required pkgdown because this is reader-facing documentation.
- Rose checked for stale "future replacement" wording.

## Remaining Boundary

This slice does not add a new worked dataset, run vignettes end to end, or
implement proportional sampling variance, sparse known covariance, or
non-Gaussian known covariance.
