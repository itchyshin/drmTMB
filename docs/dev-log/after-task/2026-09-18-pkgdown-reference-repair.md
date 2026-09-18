# Pkgdown reference-index repair — after-task report

## 1. Goal

Repair the scheduled `main` pkgdown failure caused by a stale reference-index
entry, without exposing an internal helper as public API.

## 2. Implemented

Removed `drm_missing_explicit_predictor_fail` from `_pkgdown.yml`'s reference
contents list. The helper remains deliberately `@noRd`; the adjacent documented
`drm_validate_complete_predictors` entry remains unchanged.

## 3a. Decisions and Rejected Alternatives

Removed the stale index item rather than adding an Rd alias or removing `@noRd`.
The latter alternatives would change the public API for a private implementation
helper and were neither needed nor supported by the existing source contract.

## 4. Files Touched

- `_pkgdown.yml`
- `docs/dev-log/check-log.d/2026-09-18-pkgdown-reference-repair.md`
- `docs/dev-log/after-task/2026-09-18-pkgdown-reference-repair.md`

## 5. Checks Run

- The failing scheduled run `35359543184` was read: `build_reference_index()`
  named the stale helper as an unknown Rd topic or alias.
- `pkgdown::build_reference(pkg = ".", lazy = TRUE, override = list(destination = tempdir()))`
  PASSed after the removal.
- `git diff --check` PASSed before commit.

## 6. Tests of the Tests

The original scheduled pkgdown failure is a direct counterfactual: the reference
builder rejected the configured helper before this change. The same builder
succeeds after removal in an isolated temporary destination.

## 7a. Issue Ledger

Tracked in PR #1382, independent of the D-269 compatibility bridge PR #1381.
No issue, capability, or release claim was created.

## 8. Consistency Audit

Confirmed `R/missing-data.R` marks the removed helper `@noRd`; no matching
`man/drm_missing_explicit_predictor_fail.Rd` exists. Confirmed the immediately
following retained entry has `man/drm_validate_complete_predictors.Rd`.

## 9. What Did Not Go Smoothly

The failure appeared beside the D-269 bridge CI but came from an independent
scheduled `main` run. Separating its exact log from bridge evidence avoided an
unrelated code change.

## 10. Known Residuals

PR #1382 remains open and CI is pending. It does not deploy pkgdown or merge to
`main`; those remain explicit maintainer gates.

## 11. Team Learning

Pkgdown reference lists must name only exported or documented Rd topics. Keep
private helper names out of `_pkgdown.yml` rather than promoting them only to
satisfy the index generator.

## 12. Cross-Product Coverage

This covers ✓ the pkgdown reference-index build and the reader-facing function
listing. It does NOT cover a full pkgdown deployment, a release build, package
API behavior, the D-269 bridge, or any Pages publication.
