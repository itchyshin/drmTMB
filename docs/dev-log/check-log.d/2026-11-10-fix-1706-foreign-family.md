# 2026-11-10 — fix #1706 foreign stats family hint

## Scope

`drm_family_type()` now calls `drm_maybe_abort_foreign_stats_family()` before the generic unsupported-family message when a stats `family` object (not `drm_family`) carries a `family$family` name that collides with drmTMB constructors (`nbinom2`, `truncated_nbinom2`, `tweedie`, `beta`, `lognormal`).

## Evidence

```text
R CMD INSTALL . && Rscript -e 'testthat::test_file("tests/testthat/test-fix-1706-foreign-family.R")'
fix-1706-foreign-family: ...................
PASS (2 tests, 14 expectations)
```

No silent coercion of foreign families; error names source package when inferable from closure environments (glmmTMB) and suggests `drmTMB::<constructor>()`.
