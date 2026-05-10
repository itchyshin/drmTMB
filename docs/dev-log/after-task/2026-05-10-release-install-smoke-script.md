# After Task: Release Install Smoke Script

## Goal

Turn the `v0.1.0`/`drm_control()` mismatch into a reusable release check so
future tagged previews are tested as users install them.

## Implemented

- Added `tools/install-smoke.R`.
- The script installs a GitHub ref into a clean temporary R library with `pak`.
- It optionally checks the installed package version.
- It confirms key exported functions, including `drm_control()`.
- It fits a Gaussian location-scale model with all three storage controls
  disabled and checks the expected fitted-object components are dropped.
- It checks that `check_drm()` includes the `optimizer_budget` and
  `fixed_effect_design_size` rows.
- Added a `0.1.1` release checklist with branch CI, tag CI, pkgdown, and
  tag-install smoke evidence.

## Mathematical Contract

No package code, likelihood equations, or parameter transforms changed.

## Files Changed

- `tools/install-smoke.R`
- `docs/dev-log/release-checklists/2026-05-10-0.1.1-preview-release.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-release-install-smoke-script.md`

## Checks Run

- `air format tools/install-smoke.R docs/dev-log/release-checklists/2026-05-10-0.1.1-preview-release.md docs/dev-log/after-task/2026-05-10-release-install-smoke-script.md docs/dev-log/check-log.md`:
  passed.
- `Rscript tools/install-smoke.R v0.1.1 0.1.1`: passed; installed
  `drmTMB 0.1.1` from GitHub ref `b4e222c`, confirmed required exports, fitted
  the storage-control smoke model, and confirmed the expected diagnostics.
- `git diff --check`: passed.
- `rg -n "install-smoke|v0\\.1\\.1|drm_control|optimizer_budget|fixed_effect_design_size|25639416001|25639248630|25639387716" tools/install-smoke.R docs/dev-log/release-checklists/2026-05-10-0.1.1-preview-release.md docs/dev-log/after-task/2026-05-10-release-install-smoke-script.md docs/dev-log/check-log.md`:
  passed and found the expected script, release checklist, and evidence entries.

## Known Limitations

The script installs from GitHub and is therefore a release/hygiene check, not a
fast unit test for routine development.
