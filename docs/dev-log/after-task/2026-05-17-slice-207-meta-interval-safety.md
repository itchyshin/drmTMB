# Slice 207 Meta-Analysis Interval Safety

## Goal

Confirm that interval tooling for meta-analysis treats known sampling
covariance as data and estimated heterogeneity or correlation as model
parameters.

## What Changed

- Added profile-target tests for `meta_V(V = V)` univariate Gaussian fits with
  vector `V`, dense full `V`, ordinary random intercepts, and bivariate row-
  paired `V`.
- Confirmed `profile_targets()` exposes estimated `sigma`, `sd:mu:(1 | study)`,
  `sigma1`, `sigma2`, and `rho12` where those quantities exist.
- Confirmed `profile_targets()` does not create interval rows for known `V`,
  `meta_V()`, or `meta_known_V()`.
- Added a profile-summary check that `summary(..., method = "profile",
  ci_parm = "sigma")` profiles `sigma` while keeping fixed-effect intervals on
  the Wald path.
- Added an interval-safety section to the meta-analysis design note and updated
  the roadmap and NEWS.

## Role Notes

- Fisher checked that the confidence-interval target set distinguishes
  estimated quantities from known sampling covariance.
- Gauss kept `V` out of the parameter namespace because it is an additive data
  covariance, not a TMB parameter.
- Noether checked the equation-level meaning: `V + Omega_estimated` means only
  `Omega_estimated` contributes interval targets.
- Pat kept the reader-facing rule simple: profile `sigma` or correlation
  targets, not `V`.
- Grace required this as a test slice before the meta-analysis tutorial refresh.
- Rose checked that this did not overclaim bootstrap, proportional variance, or
  full confidence-interval coverage for every future surface.

## Remaining Boundary

This slice does not implement bootstrap intervals, proportional sampling-
variance intervals, sparse matrix `V`, non-Gaussian known covariance, or broad
Phase 18 simulation.
