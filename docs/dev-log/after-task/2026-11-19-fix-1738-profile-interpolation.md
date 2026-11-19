# After Task: exact tmbprofile endpoints on the auto profile route (#1738)

## Goal

Stop the default profile interval for fixed-effect targets from being cut
short where the profile curve bends between `TMB::tmbprofile()` grid points.

## Implemented

`drm_profile_target_tmbprofile_confint()` gains `refine_endpoints`, set only
when `confint()` runs with `profile_engine = "auto"` and no
`TMB::tmbprofile()` controls. For a single-parameter target it calls the new
`drm_tmbprofile_refine_interval()`, which takes the two grid points that
bracket each interpolated limit and solves
`nll(theta) - nll_anchor = qchisq(level, 1) / 2` between them with
`stats::uniroot()` on `profile_endpoint_evaluator()`, the constrained solver
the endpoint engine already uses. `nll_anchor` is the grid minimum, the same
anchor `drm_tmbprofile_confint()` uses. A side that has no sign change in its
bracket, or whose solve fails, keeps the interpolated value.

## Mathematical Contract

The profile interval is unchanged as an estimand: the set of `theta` with
profile deviance below `qchisq(level, 1)`. Only the numerical solution of the
boundary equation changed. No likelihood or parameterization changed;
`docs/design/03-likelihoods.md` was not edited.

## Files Changed

- `R/profile.R`, `man/confint.drmTMB.Rd` (`profile_engine` text)
- `tests/testthat/test-fix-1738-profile-interpolation.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-19-fix-1738-profile-interpolation.md`

## Checks Run

See the check-log shard.

## Tests Of The Tests

On main the #1738 lower limit is -0.6137, outside the 1e-3 window around
the exact -0.62615, and the hand-written profile deviance there is 3.805,
outside the 0.01 window around 3.841. The helper unit test uses a convex
`0.5 * t^4` objective whose chord between `t = 1` and `t = 2` lands more
than 0.1 inside the true root.

## Consistency Audit

The first attempt refined every `tmbprofile` interval and broke 20
expectations in `test-profile-targets.R` that pin the explicit
`tmbprofile` route to `confint(TMB::tmbprofile(...))` at `1e-12`. That
contract is documented ("preserves the previous full-profile route for
comparison"), so the refinement is limited to the `auto` route and those
tests were not touched.

## GitHub Issue Maintenance

Refs #1738. The issue's owner question offered (1) tightening the default
engine or (2) documenting the error; this PR implements (1) for review.

## Known Limitations

`profile()` curves, row-specific `newdata` profiles and the explicit
`tmbprofile` engine still use interpolated limits. Each refined limit costs a
few constrained refits.

## Next Actions

Draft pull request for #1738.
