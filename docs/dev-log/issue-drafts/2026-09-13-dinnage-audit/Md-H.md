TITLE: [Dinnage audit Md-H] beta_binomial is missing both numerical guards its siblings carry
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-H; severity moderate).
Supporting working: site-by-site comparison of the three beta-shaped families' numerical guards.

## What Russell found
`beta_binomial` (model type 14) is missing both guards its two beta-shaped
siblings carry, in two separate files. Under quasi-complete separation
(`eta_mu > 36.7`), the objective goes NaN. Not Major because `check_drm()`
catches the consequences with three warnings -- "textbook copy-paste divergence:
written three times, two hardened."

## Where (at 945da24f)
`src/drmTMB.cpp:3532`, `src/drm_response_kernels.h:119`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. The `beta` family (case 10 in src/drm_response_kernels.h:80-95) nudges
`mu` off the boundary (`beta_mu_eps <- 1e-12`) and floors `alpha`/`beta_shape` at
`1e-8` via `CppAD::CondExpLt(...)` before taking `lgamma()`. The `beta_binomial`
family (case 14, src/drm_response_kernels.h:119-135, line numbers unchanged from
the report) computes `mu`, `alpha`, and `beta_shape` with no epsilon nudge and no
floor guard at all. The same gap is mirrored in the main TMB template: the
`model_type == 14` block computes `alpha(i) = mu(i) * phi(i)` and
`beta_shape(i) = (Type(1.0) - mu(i)) * phi(i)` at src/drmTMB.cpp:3539-3540 (drift
from the cited :3532, same missing guard) with no corresponding `CondExpLt` floor
before the `lgamma()` calls a few lines below.

## Proposed fix (Russell's, if stated)
~4 lines: add the same `mu` epsilon nudge and `alpha`/`beta_shape` floor guard
used by `beta`, in both src/drmTMB.cpp and src/drm_response_kernels.h.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
