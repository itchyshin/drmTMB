# After Task: Slice 93 0.1.2 Release Gate

## Goal

Prepare the `0.1.2` preview release PR without changing formula grammar,
likelihood code, TMB templates, extractors, or tutorial content. The release
surface should point active users from `0.1.1` to `0.1.2` while preserving
historical release logs.

## Implemented

- Bumped `DESCRIPTION` from `0.1.1` to `0.1.2`.
- Dated the `NEWS.md` `0.1.2` section for `2026-05-16` and added the active
  tagged-preview install instruction.
- Updated README, getting-started install code, `_pkgdown.yml`, and the roadmap
  preview-release section from `0.1.1` to `0.1.2`.
- Added `docs/dev-log/release-checklists/2026-05-16-0.1.2-preview-release.md`
  with separate Slice 93 PR and Slice 94 tag gates.

## Mathematical Contract

No statistical contract changed. Slice 93 changes release metadata and active
installation guidance only.

## Files Changed

- `DESCRIPTION`
- `NEWS.md`
- `README.md`
- `_pkgdown.yml`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/release-checklists/2026-05-16-0.1.2-preview-release.md`
- `docs/dev-log/after-task/2026-05-16-slice-93-0-1-2-release-gate.md`
- `vignettes/drmTMB.Rmd`

## Checks Run

- `PATH=/opt/homebrew/bin:$PATH air format DESCRIPTION NEWS.md README.md _pkgdown.yml ROADMAP.md vignettes/drmTMB.Rmd docs/dev-log/check-log.md docs/dev-log/release-checklists/2026-05-16-0.1.2-preview-release.md docs/dev-log/after-task/2026-05-16-slice-93-0-1-2-release-gate.md`:
  passed.
- `git diff --check`: passed.
- `rg -n "0\\.1\\.1|v0\\.1\\.1|0\\.1\\.2|v0\\.1\\.2|development version" README.md ROADMAP.md _pkgdown.yml vignettes/drmTMB.Rmd NEWS.md docs/dev-log/release-checklists/2026-05-16-0.1.2-preview-release.md docs/dev-log/after-task/2026-05-16-slice-93-0-1-2-release-gate.md docs/dev-log/check-log.md`:
  confirmed active source install/version surfaces now point to `0.1.2`; the
  remaining `0.1.1` matches are historical or explicitly describe the previous
  immutable preview.
- `Rscript -e 'devtools::test()'`: passed with 3,526 tests, 0 failures, 0
  warnings, and 0 skips.
- `Rscript -e 'pkgdown::build_site()'`: passed and rendered the home page,
  roadmap, getting-started article, and news page with `0.1.2` preview
  metadata.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`:
  passed for `drmTMB 0.1.2` with 0 errors, 0 warnings, and 0 notes in 2m
  36.2s.

## Standing Review Notes

- Ada: keep the release gate narrow and do not start Slice 95 in the same PR.
- Grace: require local checks, PR CI, tag CI, and install smoke before calling
  `0.1.2` complete.
- Rose: stale active `v0.1.1` install text should disappear from user-facing
  docs, while historical release logs should remain intact.
- Curie: full tests pass without skips, so this release gate did not hide
  platform-sensitive model checks behind optional paths.
- Pat: rendered README and getting-started pages show the same `v0.1.2`
  install instruction.

## Known Limitations

This slice does not tag the release. Tagging, tag-triggered CI, and install
smoke belong to Slice 94 after the release-gate PR merges.

## Next Actions

1. Open the Slice 93 PR and wait for GitHub Actions.
2. After merge, run Slice 94: annotated tag, tag CI, install smoke, and evidence
   recording.
