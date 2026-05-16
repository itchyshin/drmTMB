# After Task: Slice 94 0.1.2 Release Evidence

## Goal

Complete the `0.1.2` preview dispatch after Slice 93 merged by pushing the
annotated tag, waiting for tag-triggered CI, running the clean install smoke,
and recording release evidence.

## Implemented

- Merged PR #53, "Prepare 0.1.2 preview release gate", to `main` at
  `abe58f2`.
- Created and pushed annotated tag `v0.1.2` with message
  `drmTMB 0.1.2 preview`.
- Watched tag-triggered GitHub Actions R-CMD-check run `25964723611` to green
  on macOS, Ubuntu, and Windows.
- Ran `Rscript tools/install-smoke.R v0.1.2 0.1.2` against the pushed tag.
- Updated the `0.1.2` release checklist so Slice 93 and Slice 94 gates are
  recorded as complete.

## Evidence

- PR: <https://github.com/itchyshin/drmTMB/pull/53>
- Merge commit: `abe58f2f6be488db461e4b51d776e8a9c8f8ac5e`
- Tag: `v0.1.2`
- Tag commit: `abe58f2f6be488db461e4b51d776e8a9c8f8ac5e`
- PR CI: <https://github.com/itchyshin/drmTMB/actions/runs/25964521301>
- Main CI: <https://github.com/itchyshin/drmTMB/actions/runs/25964714336>
- Tag CI: <https://github.com/itchyshin/drmTMB/actions/runs/25964723611>
- pkgdown deploy: <https://github.com/itchyshin/drmTMB/actions/runs/25964880488>

## Checks Run

- `gh pr checks 53 --watch`: passed on macOS, Ubuntu, and Windows before merge.
- `gh run watch 25964723611 --exit-status`: passed on macOS in 6m30s, Ubuntu
  in 7m24s, and Windows in 9m8s.
- `gh run watch 25964880488 --exit-status`: passed; pkgdown built in 4m36s and
  deployed in 8s.
- `Rscript tools/install-smoke.R v0.1.2 0.1.2`: passed; installed
  `drmTMB 0.1.2` from GitHub ref `abe58f2`, confirmed required exports, fitted
  the storage-control Gaussian location-scale smoke model, and confirmed the
  `optimizer_budget` and `fixed_effect_design_size` diagnostic rows.

## Standing Review Notes

- Ada: Slice 94 completed the release mechanics and should not be mixed with
  the Slice 95 meta-analysis tutorial lane.
- Grace: release evidence now includes PR CI, main CI, tag CI, pkgdown deploy,
  and install smoke.
- Rose: the tag points to the same merge commit as the active `0.1.2` preview
  docs, avoiding the mismatch that forced the earlier `0.1.1` patch preview.

## Known Limitations

This is still a GitHub preview release, not a CRAN submission. Phase 20 remains
the later CRAN and paper-preparation phase.

## Next Actions

1. Merge this evidence-only Slice 94 PR after CI passes.
2. Start Slice 95 as a separate meta-analysis tutorial/source-map lane.
