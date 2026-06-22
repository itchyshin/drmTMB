# Julia Home CI Smoke

This note records slice S036 of the R/Julia finish run. The purpose is narrow:
the R-side test helpers must choose a Julia home path consistently before any
live Julia bridge test runs. This is environment plumbing, not a claim that a
model route is supported.

## Contract

The helper contract is:

- `DRM_JL_JULIA_HOME` takes precedence over `JULIA_HOME`.
- `JULIA_HOME` is used when `DRM_JL_JULIA_HOME` is absent.
- `drm_test_set_julia_home()` writes the effective home into `JULIA_HOME` for
  child setup.
- `drm_test_local_julia_home()` writes the effective home only for the caller
  scope and restores the previous environment afterward.

The last point matters for CI because live bridge tests run in mixed local and
worker environments. A helper that restores too early can make a test appear to
use the configured Julia binary while the child process falls back to ambient
discovery.

## Evidence

The focused evidence lives in
`tests/testthat/test-julia-home-path.R`. The mission-control row lives in
`docs/dev-log/dashboard/julia-home-smoke.tsv` and is validated by
`tools/validate-mission-control.py`.

## Boundary

This is a smoke test for the default engine path only. It does not promote a
public optimizer control, add a new bridge route, relax intentional Julia
bridge gates, or make REML/AI-REML claims beyond the exact-Gaussian rows that
already have direct DRM.jl evidence.
