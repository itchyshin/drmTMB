# CRAN policy consult — access refresh for 0.7.0 readiness

**Access date:** 2026-08-07  
**Prior consult:** `docs/dev-log/release-audits/2026-07-20-cran-policy-consult.md` (0.6.0 RC era)

## Scope of this refresh

This readiness slice claims **source-clean** only. It does **not** claim
tarball-clean, platform-clean, or submission-ready. Upload is out of scope.

## Standing facts carried forward

- First submission → expect "New submission" NOTE.
- Compiled TMB → size INFO/NOTE likely; sanitizer/valgrind/rchk owed at
  platform-clean (deferred).
- Windows vignette timing remains an observed incoming risk (~10 min) —
  confirm at platform-clean, not here.
- `JuliaCall` Suggests-only; Julia tests skip on CRAN.

## Authoritative sources to re-check immediately before upload

- https://cran.r-project.org/web/packages/policies.html
- https://cran.r-project.org/submit.html
- Current CRAN Repository Policy PDF linked from the policies page

Label thresholds as **current policy** vs **observed incoming** vs **local
margin** at the upload gate. This file only records that the readiness lane
re-opened the policy consult on 2026-08-07 without claiming submission-ready.
