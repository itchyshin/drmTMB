# After Task: Julia cross-family Gaussian link guard (#1750)

## Goal

Stop the `engine = "julia"` cross-family route from fitting a
`gaussian(link = "log")` or `gaussian(link = "inverse")` axis as an
identity-link Gaussian axis.

## Implemented

`drm_julia_xfam_family_tag()` returns `NULL` unless the Gaussian link is
`"identity"`. This mirrors the link guards on every other cross-family axis.

## Mathematical Contract

No likelihood changed. The DRM.jl cross-family Gaussian axis models
`E(y1) = X1 beta1` with an identity link; the R side now refuses to send a
different link to it. `docs/design/03-likelihoods.md` was not edited.

## Files Changed

- `R/julia-bridge.R`
- `tests/testthat/test-fix-1750-xfam-gaussian-link.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-19-fix-1750-xfam-gaussian-link.md`

## Checks Run

See the check-log shard: the new file fails on main (4 failures, 1 error) and
passes with the fix; `test-xfam-bridge.R` and `test-env-skip-census.R` pass.

## Tests Of The Tests

On main the end-to-end test reaches `drm_julia_call_xfam()`, which is the
point where the mislabelled axis would be fitted when Julia is present.

## Consistency Audit

The abort reuses the existing mixed-response message. The native TMB route
for a non-identity Gaussian link is #1482 / PR #1695 and is not touched.

## GitHub Issue Maintenance

Refs #1750.

## Known Limitations

The user-facing message is the general mixed-response message and does not
name the link. A live-Julia test was not added (env-skip census).

## Next Actions

Draft pull request for #1750.
