# After Task: lighter CI on draft pull requests

## Goal

Shinichi approved plan A on 18 Nov 2026: draft pull requests in `drmTMB`
should stop launching the full check and coverage matrices. Ready pull
requests and `main` should keep the jobs they already run. The reader of
this note is the next contributor who touches `.github/workflows/`.

## Implemented

Draft activity still triggers `R-CMD-check`. The matrix setter runs, and
it emits one job: `ubuntu-latest (release) shard 1/8`. That job is the
smoke check. It is the same shard the ready matrix already runs, including
the Linux ledger, citation, and Julia-glue steps that shard has today.
Shards 2–8 are not in the draft matrix.

`source-tree tests (blind spot)`, `validate-shard-records`, and
`ubuntu-latest (release) shard 1/4` through `4/4` use
`if: github.event_name != 'pull_request' || github.event.pull_request.draft == false`.
On a draft they are skipped. On a ready pull request, a tag, or
`workflow_dispatch` the condition is true, and `always()` still lets the
rollup run after a failed shard, which is the previous failure behaviour.

`test-coverage` skips all nine shards on a draft. On a ready pull request
a `coverage path filter` job compares the pull request diff with the path
list that push-to-main already uses (`R/**`, `src/**`, `tests/**`,
`DESCRIPTION`, `NAMESPACE`, the two coverage workflow files, `codecov.yml`,
and `tools/covr-source-tree-layout.sh`). Matching diffs run the nine
shards. A filter failure also runs them, so a broken diff cannot hide the
suite. Push-to-main keeps its workflow-level path filter. Manual
`workflow_dispatch` still measures every shard.

`pkgdown` was left unchanged. It does not run on pull requests.

No wrong-close, closing-keyword, merge-strict, or lease workflow exists
under `.github/workflows/`, and none of the seven workflows trigger on
`edited`. Those files were not edited. At the time of the change, GitHub
reported 36 queued workflow runs in this repository; zero of them belong
to a closing-keyword guard, because that workflow is not in the repo.

## Mathematical Contract

No likelihood, formula, or tolerance changed.

## Files Changed

- `.github/workflows/R-CMD-check.yaml`
- `.github/workflows/test-coverage.yaml`
- `docs/dev-log/check-log.d/2026-11-18-ci-light-drafts.md`
- `docs/dev-log/after-task/2026-11-18-ci-light-drafts.md`

## Checks Run

`actionlint` 1.7.7 exited 0 on every file in `.github/workflows/`.
`yaml.safe_load` parsed the same files. The Codecov and C14 receipt
workflow tests passed: 11 tests, OK. Details are in the check-log shard
named above.

## Tests Of The Tests

The existing `tools/tests/test_codecov_workflow.py` guards still require
the nine shard specs, the main-only upload `if`, and the absence of
`pull_request_target` and `id-token` on the producer. They passed with
the new job in the file. No tolerance or coverage threshold was edited.

## Consistency Audit

This slice does not change family, formula, or user-facing model text.
`README.md`, `NEWS.md`, the roadmap, known limitations, the formula
grammar, and `_pkgdown.yml` were not edited. `pkgdown.yaml` still has no
`pull_request` trigger.

## GitHub Issue Maintenance

No issue was opened or commented on. The change follows an owner decision
already given in the task, and this agent did not find a separate open
issue that the workflow edit had to update.

## What Did Not Go Smoothly

A job-level `if` cannot read `matrix` (GitHub's context table;
`actionlint` rejects it). The draft cut for the eight R check shards is
therefore the matrix JSON from `os-matrix`, not a per-shard `if`. Shards
2–8 are missing on a draft run, not skipped. The rollup and source-tree
jobs can be skipped because their `if` uses only `github`.

Branch protection could not be read (`gh api` returned 403 on
`branches/main/protection`). The names below are taken from the workflow
and from `docs/dev-log/coordination-board.md`, which says protection keys
on the release-shard and blind-spot names.

## Team Learning

When a required check must stay visible, skip the job with `if`. Do not
use a workflow-level `paths` filter on `pull_request`: the workflow never
starts, and the check is missing. Push-to-main can keep a path filter
when that filter is already the behaviour to preserve.

## Known Limitations

`os-matrix` still runs on a draft. It is a few-second shell step, and the
shard job needs its JSON. The smoke run is one R check job plus that
setter.

If the repository treats a skipped required check as a success, the four
`shard N/4` rollups are skipped on a draft and would not block a merge.
Marking the pull request ready starts a new run in which those jobs
execute. Until that run posts a status, the previous skipped conclusion
is the latest one on that commit.

On a main coverage run, and on `workflow_dispatch` of `test-coverage`,
the new `coverage path filter` job is skipped. The nine shards still run
when the push path filter starts the workflow. That skipped job is the
only addition on those events.

## Next Actions

Confirm in the branch-protection or ruleset UI that skipped
`ubuntu-latest (release) shard N/4` checks do not count as success, if
drafts must be unable to merge. This change does not merge and does not
edit the ruleset.
