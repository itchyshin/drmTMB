# Check log — 2026-11-21 — fix #1749 drm_impute_family_type gaussian link

## Change

- `R/missing-data.R`: reject non-identity `gaussian()` links in `drm_impute_family_type()` (same message as `drm_family_type()` #1695).

## Verification

- `testthat::test_file("tests/testthat/test-fix-1749-impute-gaussian-link.R")`