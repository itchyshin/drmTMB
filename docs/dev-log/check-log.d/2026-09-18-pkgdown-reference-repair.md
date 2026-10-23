# 2026-09-18 — pkgdown reference-index repair

Documentation-only PASS locally. `_pkgdown.yml` no longer lists the deliberately
internal `drm_missing_explicit_predictor_fail()` helper, which has `@noRd` and no
Rd alias. `drm_validate_complete_predictors()` remains listed because its Rd topic
exists.

Verification: `pkgdown::build_reference()` in a temporary destination PASS;
`git diff --check` PASS. PR #1382 is open and its fresh CI is pending. No package
API, test, release, or Pages deployment changed.
