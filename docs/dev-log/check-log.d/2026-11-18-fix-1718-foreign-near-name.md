# 2026-11-18 — fix #1718 foreign near-name families

## Scope

`drm_family_type()` calls `drm_maybe_abort_foreign_near_name_family()` before
the generic unsupported-family message. A stats `family` whose name
normalises to `betabinomial` or `skewnormal` aborts with class
`drmTMB_foreign_near_name_family` and names `drmTMB::beta_binomial()` or
`drmTMB::skew_normal()`. Nothing is fitted. Exact constructor collisions
such as `nbinom2` are left to #1706.

## Evidence

`tests/testthat/test-fix-1718-foreign-near-name.R` before the hint: ERR 2.
Both names died in the generic "currently supported families" list, which
does not say `drmTMB::beta_binomial()` or `drmTMB::skew_normal()`. The
unrelated name `quack` and `gaussian()` passed.

After the hint: FAIL 0, ERR 0, PASS 8.
