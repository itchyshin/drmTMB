# After Task: CRAN Incoming Pre-test Resubmission Fix

## Goal

Resolve the two DESCRIPTION spelling flags and the Windows overall-checktime
NOTE reported by CRAN's incoming pre-tests for drmTMB 0.5.0.

## Implemented

The DESCRIPTION now quotes the proper method name `'Tweedie'` and uses
`semi-continuous`. Routine CRAN checks exclude the internal Phase 18
simulation/reporting harness and the generated structured-conversion contract,
while repository CI explicitly sets `NOT_CRAN=true` and continues to execute
the full validation suite. Two individually measured high-dimensional
diagnostics also use the package's existing `skip_on_cran()` boundary.

## Mathematical Contract

No likelihood, parameterization, formula grammar, estimator, or user-facing R
behavior changed. This patch changes only which internal validation campaigns
run during routine CRAN checks.

## Files Changed

- `DESCRIPTION`
- `tests/testthat.R`
- `tests/testthat/test-profile-targets.R`
- `tests/testthat/test-animal-relmat-gaussian.R`
- `.github/workflows/R-CMD-check.yaml`
- `cran-comments.md`
- release evidence in this report and `docs/dev-log/check-log.md`

## Checks Run

- CRAN incoming Windows log: no error or warning; spelling and 23-minute
  overall-checktime notes only; `testthat.R` took 18 minutes.
- CRAN incoming Debian log: no error or warning; spelling note only;
  `testthat.R` took 550 seconds.
- Exact submitted-source JUnit profiling identified 1,362 active local seconds,
  including 909 seconds in 91 Phase 18 files and 86 seconds in the generated
  structured-conversion contract.
- Patched installed-package CRAN-mode test entry point: 10,414 passed, 92
  skipped, 0 failed in 296.30 seconds.
- Direct `R CMD check --as-cran --no-manual` on the built tarball with
  `NOT_CRAN=false`: 0 errors, 0 warnings, 1 expected new-submission NOTE. The
  test stage passed in 144 seconds and vignette rebuilding passed in 75
  seconds. The incoming spell check no longer flags either word.

## Tests Of The Tests

The timing policy was exercised through the real `tests/testthat.R` entry point
against an installed package with `NOT_CRAN=false`. Repository CI sets
`NOT_CRAN=true`, so the same entry point selects the full suite there. The two
individual slow diagnostics retain explicit `skip_on_cran()` calls rather than
conditional sample-size changes.

## Consistency Audit

The patch leaves version 0.5.0 and the submitted source behavior unchanged.
The resubmission explanation now describes the exact test lanes moved and does
not claim that validation was removed.

## GitHub Issue Maintenance

No new product issue was opened. This is an isolated response to CRAN's
incoming-pretest email and does not alter missing-response parent issue #761.

## What Did Not Go Smoothly

The first timing pass used `devtools::test()` without forcing
`NOT_CRAN=false`, so it included tests already marked non-CRAN. A second pass
used the explicit CRAN environment, and final verification used the actual
installed-package `tests/testthat.R` entry point.

## Team Learning

An exhaustive simulation framework can remain a first-class CI artifact
without being part of routine CRAN checks. The package entry point should make
that boundary explicit and CI should opt into the full lane explicitly.

## Known Limitations

Local timing cannot certify Windows elapsed time. A new win-builder or CRAN
incoming pre-test remains necessary before calling the timing NOTE closed.

## Next Actions

1. Run the full GitHub Actions matrix with `NOT_CRAN=true`.
2. Confirm the patched Windows timing, then let the maintainer resubmit 0.5.0.
