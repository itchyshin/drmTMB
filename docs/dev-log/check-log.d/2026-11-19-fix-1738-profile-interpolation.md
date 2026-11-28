# Check log: exact tmbprofile endpoints on the auto profile route (#1738)

**Date:** 2026-11-19
**Branch:** `cursor/fix-1738-profile-interp-726d`

## Change

On `profile_engine = "auto"` without `TMB::tmbprofile()` controls, a
single-parameter `tmbprofile` interval limit is solved with `uniroot()` on
the constrained profile between the two grid points that bracket it
(`drm_tmbprofile_refine_interval()` in `R/profile.R`). The explicit
`tmbprofile` engine and calls with `ystep`, `ytol`, `profile_precision` or
`profile_maxit` keep `TMB`'s interpolated limits.

## Failure on main

`74007c485`, the #1738 reproducer. The `tmbprofile` grid jumps from
`nu = -0.747` (deviance 4.25) to `-0.542` (deviance 3.62) across a profile
that flattens towards 0, and linear interpolation returned -0.6137. The
hand-written skew-normal profile deviance there is 3.805 (cutoff 3.841).
`tests/testthat/test-fix-1738-profile-interpolation.R` on main: 2 failures
(lower limit, deviance at the lower limit) and 1 error (helper absent).

## Verification with the fix

R 4.6.2, TMB 1.9.25, `pkgload::load_all()`.

| Check | Result |
| --- | --- |
| #1738 reproducer | lower -0.6261471, upper 3.161973; exact -0.6261533, 3.16195; deviance at lower 3.841441 |
| `test-fix-1738-profile-interpolation.R` | 8 pass |
| All 63 test files that mention `method = "profile"`, `profile_engine` or `tmbprofile` | 28,946 expectations, 0 failures, 0 errors, 106 skips (Julia, optional packages) |

A first version that refined every `tmbprofile` interval failed 20
expectations in `test-profile-targets.R` that pin the explicit `tmbprofile`
route to `confint(TMB::tmbprofile(...))` at `1e-12`; the refinement was then
limited to the `auto` route and those tests pass unchanged.

## Claim boundary

Only interval limits on the `auto` route change. `profile()` curves,
row-specific `newdata` profiles and the endpoint engine are untouched.
