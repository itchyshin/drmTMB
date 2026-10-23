TITLE: [Dinnage audit Md-M] skew_normal floors log Phi with +1e-300 instead of drm_log_pnorm()
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-M; severity moderate).
Supporting working: gradient measured at `alpha = 10, z = -4`.

## What Russell found
The package ships a tail-safe `drm_log_pnorm()` and tests it, but `skew_normal`
floors `log Phi` with `+1e-300` instead of using it. At `alpha = 10, z = -4` the
gradient with respect to `mu` is wrong by a factor of 100, and the saturating
penalty creates a plateau a maximiser can sit on. The R-side `d()` closure
returns exactly 0 at the same points, so the two "mirrored" implementations are
wrong in different ways.

## Where (at 945da24f)
`src/drm_numeric.h:76`, the skew-normal call site in `src/drmTMB.cpp`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `drm_log_pnorm()` (the tail-safe helper) is still defined at
src/drm_numeric.h:76, unchanged from the cited line. The skew-normal call site
in src/drmTMB.cpp still uses the additive floor rather than the helper:
`Type skew_cdf = pnorm(alpha * z, Type(0.0), Type(1.0));` followed by
`log(skew_cdf + Type(1e-300))` at src/drmTMB.cpp:2653-2657, instead of
`drm_log_pnorm(alpha * z)`.

## Proposed fix (Russell's, if stated)
One line, at the call site: replace `log(skew_cdf + Type(1e-300))` with
`drm_log_pnorm(alpha * z)`.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
