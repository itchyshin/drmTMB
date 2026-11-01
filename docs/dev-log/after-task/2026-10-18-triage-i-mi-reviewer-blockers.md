# After Task: #1513 Code Reviewer blockers

Reader: Shinichi, checking the five Code Reviewer items on draft PR #1513.

## Goal

Confirm or fix: live classed abort, live `drm_rethrow_mi_quadrature_error`,
Beta `mu = 0.02` at `1e-4`, `#1459` warning only on unweighted Gaussian
priors, and C17 recertify on the final cpp. Do not merge. Do not file
the CV `> 1` GitHub issue. Refs only.

## Result

1. Confirmed. A live `drmTMB()` Gamma `mi()` fit with `y = 1e200` on a
   missing-x row raises classed `drmTMB_mi_quadrature_nonfinite`.
2. Confirmed live, and the unused wrapper was removed.
   `drm_fit_spec()` calls `drm_rethrow_mi_quadrature_error` on MakeADFun
   errors; the start/fitted probe calls it on `fn`/`gr`. The dead
   `drm_wrap_mi_quadrature_objective` (C-stack overflow) was deleted.
   A new test classifies a C++ tape token through the helper.
3. Not met at `1e-4`. Frozen 15-node Gauss-Legendre is `4.81e-3` at
   `mu = 0.02`, `sigma = 1`, `beta_x = 2`. 101 Gauss-Legendre nodes
   still `3.0e-4`. Labelled skip, refs #1476 / #1531. Beta rule unchanged.
4. Confirmed and tightened. Warning cites `:1434`, `:1475`, `:4678`.
   Gamma and Beta `mi()` plus `weights = 2` do not warn. Gaussian
   `weights = 2` does. Second-slot `mi()` must also be Gaussian.
5. Confirmed. C17 `--label mi-quadrature-1513-r5` already ran on the
   final cpp (`|change| 0.000e+00`). This slice does not edit
   `src/drmTMB.cpp`. `--check-c14-receipt-equivalence` still prints OK.

## Files changed

`R/mi-weights.R`, `tests/testthat/test-mi-quadrature-1476-1477.R`,
`tests/testthat/test-mi-weights-1459.R`, census, NEWS and design line
numbers for the unweighted prior sites.

## Checks run

`test-mi-quadrature-1476-1477.R` 0 fail (2 labelled skips).
`test-mi-weights-1459.R` 0 fail. C17 equivalence OK.

## GitHub issue maintenance

No issue filed. CV `> 1` leftover stays
`docs/dev-log/2026-10-12-gamma-mi-cv-gt1-pole-follow-up-issue.md`
(refs #1477).
