# After Task: Takeover PR Queue Cleanup

## Goal

Take over the open PR list before new implementation work by separating real
merge candidates from stale stacked PRs, failed unsupported-control work, and
paused drafts.

## Implemented

PR #474 was refreshed against current `origin/main`, passed fresh current
Ubuntu, macOS, and Windows R-CMD-check, and was squash-merged.

The visible Julia bridge stack #520, #522, #523, #527, #528, #530, #532, and
#534 was closed as stale queue bookkeeping rather than merged. Current
`origin/main` already contains the represented bridge code, tests, and
dashboard evidence. For #522 through #534, `git cherry -v origin/main
origin/<head>` reported no unmerged patch commits. For #520, only the
ASCII-escape commit remained in `git cherry`, and that patch is already
equivalent to current `origin/main`.

PR #540 was closed instead of converted or merged. It still had one real
unmerged commit, but it was conflicting, failed all three prior R-CMD-check jobs,
and exposed an optimizer-control surface that the mission-control plan keeps
unsupported until it has an explicit `engine_control` design.

Draft PRs #473, #475, #571, #573, and #574 remain paused and dirty against
current `main`; each needs a separate refresh decision before any merge path.

## Mathematical Contract

No model or likelihood contract changed in this slice. The queue cleanup makes
no new support claim for cross-family inference, variance/correlation
parameters, optimizer controls, q8, numerical guards, or release readiness.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-takeover-pr-queue-cleanup.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`

## Checks Run

```sh
gh pr view 474 --json statusCheckRollup,mergeable,mergeStateStatus
gh pr merge 474 --squash --delete-branch
git cherry -v origin/main origin/shannon/xfam-bridge
git cherry -v origin/main origin/shannon/xfam-bridge2
git cherry -v origin/main origin/shannon/s2-largep
git cherry -v origin/main origin/shannon/bridge-sigma
git cherry -v origin/main origin/shannon/bridge-breadth
git cherry -v origin/main origin/shannon/bridge-structured
git cherry -v origin/main origin/shannon/bridge-inference
git cherry -v origin/main origin/shannon/bridge-predict
python /Users/z3437171/.codex/plugins/cache/openai-curated-remote/github/0.1.2/skills/gh-fix-ci/scripts/inspect_pr_checks.py --repo /Users/z3437171/Dropbox/Github\ Local/drmTMB --pr 540 --json
gh pr list --state open --json number,title,isDraft,headRefName,baseRefName,mergeStateStatus
python3 tools/validate-mission-control.py
```

`python3 tools/validate-mission-control.py` reported
`mission_control_ok: 21/68 banked_or_verified, 3 active, 17 matrix rows, 11
finish rows, 15 Julia gate rows, 9 Julia capability rows`.

## Tests Of The Tests

No package tests were added or changed. The relevant test of this task was the
fresh #474 CI gate: Ubuntu, macOS, and Windows R-CMD-check all passed before
merge. For stale bridge PRs, the test was not rerun because there was no
remaining patch to test after comparing against current `origin/main`.

## Consistency Audit

The queue audit compared each visible bridge-stack head against current
`origin/main` using `git cherry -v`. The open-PR inventory after cleanup showed
only paused drafts:

- #473 `claude/power-simulation-grid`
- #475 `claude/release-hygiene`
- #571 `codex/ayumi-beak-binomial-plan`
- #573 `codex/project-state-handover`
- #574 `codex/ayumi-beak-start-ladder`

The mission-control metrics stayed conservative: `21/68` banked or verified,
`3` active, `0` blocked, and `1` deferred.

## GitHub Issue Maintenance

Each closed PR received a takeover audit comment before closure. The GitHub app
could not write PR comments (`403 Resource not accessible by integration`), so
the authenticated `gh` CLI was used for comments and closures.

No new issue was opened. The next `engine_control` attempt should be a new
design/implementation PR or issue rather than a revival of #540 as-is.

## What Did Not Go Smoothly

The initial expectation was to restack and merge #520 first. Fresh comparison
showed that the stack content was already represented on current `main`; trying
to replay #522 would have downgraded newer tests. The correct action was to
close stale wrappers rather than force a no-op merge.

## Team Learning

Rose should treat old stacked PRs with green checks as suspicious until their
head branches are compared against current `origin/main`. Grace should require
fresh direct-main CI only for branches with a real remaining patch. Ada should
record whether a PR was merged, closed as superseded, or kept paused so the
open-PR count stays meaningful.

## Known Limitations

The live browser dashboard at `http://127.0.0.1:8765/` reads from
`/tmp/drm-dashboard` and must be refreshed from this branch or the merged source
with `sh tools/start-mission-control.sh --background`.

## Next Actions

Resume the mission-control work from the five paused drafts and the explicit
remaining phases: Phase 1 matrix truth, Phase 2 bridge truth, Phase 3 inference
status, missing values, visual/article review, cross-team visits, ADEMP
comparators, and release gates. Do not reintroduce `engine_control` without a
design-backed slice.
