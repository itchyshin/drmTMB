# Slice 206 Proportional Sampling-Variance Boundary

## Goal

Keep the planned proportional sampling-variance route separate from both
additive known sampling covariance and top-level likelihood weights.

## What Changed

- Strengthened the `meta_V()` parser boundary so reserved arguments such as
  `w` and `scale` error before fitting.
- Added tests for `meta_V(w = w, scale = "proportional")`, `meta_V(w = w)`,
  and `meta_V(V = V, scale = "exact")`.
- Added a test that diagonal/vector `meta_V(V = V)` can still use ordinary
  likelihood weights, with constant weights doubling the log likelihood.
- Added a test that full matrix-`V` fits reject non-unit top-level weights under
  the new `meta_V(V = V)` spelling.
- Updated the meta-analysis design note, roadmap, NEWS, and check log so the
  boundary says what the code does: likelihood weights are row multipliers, not
  proportional sampling variances.

## Role Notes

- Boole kept the grammar boundary simple: implemented additive `V`, reserved
  `w` and `scale`.
- Fisher kept the proportional route closed until it has a likelihood,
  identifiable parameterization, diagnostics, and interval plan.
- Gauss kept full dense known-`V` weighting out because it is a joint
  multivariate likelihood block, not independent row likelihoods.
- Pat and Darwin kept the documentation focused on the reader's practical
  choice: use `V` for known sampling variance, `sigma` for residual
  heterogeneity, and `weights` only for likelihood weighting.
- Grace required targeted tests and pkgdown because the boundary is
  user-facing.
- Rose checked that the docs no longer overclaim that every additive known-`V`
  fit rejects top-level weights.

## Remaining Boundary

This slice does not implement proportional sampling-variance likelihoods,
non-Gaussian known covariance, sparse known covariance, or joint-block weighting
for full dense matrix `V`.
