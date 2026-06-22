# After-Task Report: Julia Home CI Smoke

## Task

Bank slice S036 by adding focused test coverage for the R-side Julia home
environment helpers used by live Julia bridge tests.

## Changes

- Added `tests/testthat/test-julia-home-path.R` to test
  `DRM_JL_JULIA_HOME` precedence, `JULIA_HOME` fallback, explicit
  `JULIA_HOME` setup, and caller-scoped local setup.
- Updated `drm_test_local_julia_home()` so the local environment change is
  registered in the calling test frame rather than restored when the helper
  itself returns.
- Added `docs/dev-log/dashboard/julia-home-smoke.tsv` and
  `docs/design/190-julia-home-ci-smoke.md` to keep the smoke evidence visible
  without promoting bridge support.
- Extended the mission-control validator and dashboard copier to include the
  new Julia-home smoke table.

## Checks

```sh
Rscript -e 'devtools::test(filter = "julia-home-path", reporter = "summary")'
tools/validate-mission-control.py
git diff --check
```

## Result

The Julia-home smoke helper contract is covered locally and is now part of the
mission-control dashboard contract.

## Claim Boundary

S036 tests environment helper behavior only. It does not add R-via-Julia
fitting, relax bridge gates, change formula grammar, change REML support, add
q4 interval coverage, claim non-Gaussian REML, expose public `engine_control`,
or touch Ayumi-facing text.
