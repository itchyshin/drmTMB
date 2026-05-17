# Slice 205 Meta-V Additive Alias

## Goal

Implement the preferred additive known-covariance spelling after the Slice 204
API decision.

## What Changed

- Added exported `meta_V(V = V)` formula marker documentation.
- Routed `meta_V(V = V)` through the same additive known sampling covariance
  path as `meta_known_V(V = V)`.
- Kept `meta_known_V(V = V)` as a compatibility alias.
- Rejected positional `meta_V(vi)` calls because the response already lives on
  the left-hand side of the formula.
- Rejected `meta_V(w = w, scale = "proportional")` before fitting with a
  message that says the proportional route needs its own likelihood,
  diagnostics, and tests.
- Added tests showing `meta_V(V = vi)` and `meta_known_V(V = vi)` return the
  same coefficients and log likelihood.
- Updated pkgdown, NEWS, ROADMAP, and the check log.

## Role Notes

- Boole checked that `meta_V(V = V)` is memorable and does not repeat the
  response as a positional argument.
- Gauss kept the alias on the existing additive likelihood path rather than
  creating a second implementation.
- Fisher kept the proportional branch out until it has a true variance-component
  likelihood and interval story.
- Pat kept the current fitted spelling visible for readers while the alias
  lands.
- Grace required roxygen, targeted tests, pkgdown, and NEWS because this is a
  new exported marker.
- Rose checked that this slice does not claim proportional sampling variance or
  non-Gaussian known-`V` support.

## Remaining Boundary

This slice does not implement proportional sampling-variance models, sparse
known covariance, non-Gaussian known covariance, or a deprecation warning for
`meta_known_V()`.
