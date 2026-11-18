# Check log: lighter CI on draft pull requests

**Date:** 2026-11-18
**Branch:** `cursor/ci-light-drafts`
**Reader:** Shinichi and the next person who edits `.github/workflows/`.

## Goal

Cut GitHub Actions load from draft pull requests. Ready pull requests and
`main` keep the suites they run today.

## What changed

`R-CMD-check` and `test-coverage` now listen for `ready_for_review` as well
as `opened`, `synchronize`, and `reopened`. A draft run of `R-CMD-check`
asks `os-matrix` for ubuntu release shard 1/8 only. `source-tree-tests`,
`validate-shard-records`, and the four `ubuntu-latest (release) shard N/4`
rollups stay in the workflow and are skipped when
`github.event.pull_request.draft` is true. Tag pushes and
`workflow_dispatch` are not pull_request events, so they still take the
three-OS unsharded matrix.

`test-coverage` no longer has a workflow-level `paths` filter on
`pull_request`. A `coverage_paths` job diffs the pull request against the
same path list the push trigger still uses. Ready pull requests run the
nine coverage shards when that diff matches, and also run them if the
filter job fails. Drafts skip the filter and all nine shards. Push to
`main` still has its workflow-level path filter. `workflow_dispatch` still
runs all nine shards.

`pkgdown` does not run on pull requests (tags, a daily schedule, and
`workflow_dispatch` only), so no docs path filter was added.

## Verification

| Check | Result |
| --- | --- |
| `actionlint` 1.7.7 on `.github/workflows/*.yaml` | exit 0, no findings |
| `yaml.safe_load` of the same seven files | parsed |
| `python3 -m unittest tools.tests.test_ci_wires_c14_receipt_equivalence tools.tests.test_codecov_workflow` | 11 tests, OK |
| Local case-statement check of the coverage path list, including a rename out of `R/` | matched `R/old.R`, ignored a vignette-only diff |

Shell stand-in for the `os-matrix` branch: draft pull request selects shard
1; a non-draft pull request selects shards 1–8; `workflow_dispatch` and a
`refs/tags/v*` ref select the three-OS shard 0 matrix.

## Not run

No `R CMD check`, coverage shard, or pkgdown build. Those suites were not
edited. This slice only changes when GitHub schedules them.
