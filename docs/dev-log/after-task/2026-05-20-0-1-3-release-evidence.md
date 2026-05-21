# After Task: 0.1.3 Release Evidence

## Goal

Complete the `0.1.3` preview dispatch after PR #270 passed CI by merging the
candidate, pushing the annotated tag, watching tag-triggered CI, running the
clean install smoke, and recording release evidence.

## Implemented

- Merged PR #270, "Prepare 0.1.3 preview candidate", to `main` at `f410d065`.
- Created and pushed annotated tag `v0.1.3` with message
  `drmTMB 0.1.3 preview`.
- Watched main-branch R-CMD-check run `26198145314` to green on macOS, Ubuntu,
  and Windows.
- Watched tag-triggered R-CMD-check run `26198578993` to green on macOS, Ubuntu,
  and Windows.
- Confirmed pkgdown run `26198571230` built and deployed the site for the merge
  commit.
- Ran `Rscript tools/install-smoke.R v0.1.3 0.1.3` against the pushed tag.
- Updated the `0.1.3` release checklist so candidate, PR, CI, tag, pkgdown, and
  install-smoke gates are recorded as complete.

## Evidence

- PR: <https://github.com/itchyshin/drmTMB/pull/270>
- Merge commit: `f410d06551507287028ed2db9307e03102c7d813`
- Tag: `v0.1.3`
- Tag commit: `f410d06551507287028ed2db9307e03102c7d813`
- PR CI: <https://github.com/itchyshin/drmTMB/actions/runs/26197684642>
- Main CI: <https://github.com/itchyshin/drmTMB/actions/runs/26198145314>
- Tag CI: <https://github.com/itchyshin/drmTMB/actions/runs/26198578993>
- pkgdown deploy: <https://github.com/itchyshin/drmTMB/actions/runs/26198571230>

## Checks Run

- `gh pr checks 270 --watch --interval 30`: passed on macOS in 7m08s, Ubuntu in
  9m57s, and Windows in 13m11s.
- `gh run watch 26198145314 --exit-status --interval 30`: passed on macOS in
  6m45s, Ubuntu in 10m52s, and Windows in 12m48s.
- `git tag -a v0.1.3 -m "drmTMB 0.1.3 preview" && git push origin v0.1.3`:
  pushed the annotated tag.
- `gh run watch 26198578993 --exit-status --interval 30`: passed on macOS in
  8m56s, Ubuntu in 9m58s, and Windows in 11m39s.
- `gh run view 26198571230 --json status,conclusion,url,jobs`: confirmed pkgdown
  and deploy jobs both succeeded.
- `Rscript tools/install-smoke.R v0.1.3 0.1.3`: passed; installed
  `drmTMB 0.1.3` from GitHub ref `f410d06` into a clean temporary library,
  loaded the package, fitted the smoke model, and confirmed the version.

## Standing Review Notes

- Ada: the release boundary is now real. Animal/`relmat()` phylogenetic parity
  remains the next lane, not part of `0.1.3`.
- Grace: release evidence includes PR CI, main CI, tag CI, pkgdown deploy, and
  install smoke.
- Rose: tag `v0.1.3` points to the same merge commit as the active `0.1.3`
  preview docs, so install instructions and tagged package state agree.

## Known Limitations

This is still a GitHub preview release, not a CRAN submission. The first
known-matrix animal/`relmat()` slice is fitted, but full phylogenetic parity for
animal/`relmat()` remains post-`0.1.3` work.

## Next Actions

1. Merge this release-evidence PR after CI passes.
2. Start the post-`0.1.3` phylo-parity lane for animal/`relmat()` and remaining
   structured-dependence siblings.
