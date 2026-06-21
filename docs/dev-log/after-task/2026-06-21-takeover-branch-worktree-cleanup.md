# After Task: Takeover Branch And Worktree Cleanup

## Goal

Complete the first housekeeping slice from the Claude/Shannon-to-Codex handover:
delete the three stale merged `claude/*` remote branches tracked by
`drmTMB#476`, remove clean stale drmTMB worktrees, and preserve dirty local
state.

## Implemented

Deleted these remote branches from `origin`:

- `claude/power-simulation-prep`
- `claude/clause-team-mirror-followup`
- `claude/clause-team-analysis-s1RRw`

Removed 29 clean non-main registered drmTMB worktrees with `git worktree
remove`, then ran `git worktree prune`. The cleanup skipped
`/private/tmp/drmtmb-main-after609-bDAfMv` because that detached worktree has an
untracked `tools/__pycache__/` directory.

## Mathematical Contract

No model, likelihood, formula grammar, estimator, interval method, or
simulation claim changed. This was repository housekeeping only.

## Files Changed

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-21-takeover-branch-worktree-cleanup.md`

## Checks Run

```sh
git status --short --branch
gh issue view 476 --repo itchyshin/drmTMB --json number,title,state,body,comments,updatedAt,url
git fetch origin --prune
for b in claude/power-simulation-prep claude/clause-team-mirror-followup claude/clause-team-analysis-s1RRw; do git ls-remote --heads origin "$b"; done
git branch -r --format='%(refname:short)' | rg '^origin/(claude/power-simulation-prep|claude/clause-team-mirror-followup|claude/clause-team-analysis-s1RRw)$' || true
git push origin --delete claude/power-simulation-prep claude/clause-team-mirror-followup claude/clause-team-analysis-s1RRw
git fetch origin --prune
git worktree list --porcelain
git worktree remove <clean non-main registered drmTMB worktree>
git worktree prune
gh issue close 476 --repo itchyshin/drmTMB --comment <verification note>
```

After deletion and prune, `git ls-remote --heads origin <branch>` returned no
refs for all three branch names, the remote-tracking branch scan returned no
matches, and `git worktree list --porcelain` showed only the main checkout plus
the intentionally preserved dirty detached worktree.

## Tests Of The Tests

The verification was ref-level: each target branch was checked before deletion
with `git ls-remote`, then checked again after deletion and `git fetch
origin --prune`. The post-delete remote-tracking scan used exact branch-name
anchors so nearby `claude/*` branches were not counted.

## Consistency Audit

No package source, generated documentation, dashboard JSON, registry TSV,
simulation artifact, or user-facing status page changed. The check-log entry
records the housekeeping boundary so future status summaries do not treat this
as release, CRAN, bridge, or capability evidence.

## GitHub Issue Maintenance

Closed `drmTMB#476` with a comment listing the three deleted branches and the
post-delete verification commands. No new issue was opened.

## What Did Not Go Smoothly

The initial cleanup loop used `status` as a shell variable, which is read-only
in `zsh`; the loop exited before removing worktrees. The rerun used
`wt_status` and completed. The current `origin/main` tree is much newer than
the three old branches, so a plain tree diff is noisy; the cleanup relied on
the issue's branch-specific deletion request and post-delete ref checks.

## Team Learning

For takeover cleanup, separate three operations explicitly: remote branch
deletion, registered worktree removal, and local branch pruning. Delete only
the refs named by the issue or handover, and preserve dirty worktrees.

## Known Limitations

Many local branch names remain. This slice removed stale registered worktree
directories and the three issue-tracked remote branches only; it did not prune
local branch names or delete other remote `claude/*` / `codex/*` refs.

## Next Actions

Pick the next defended work slice from `drmTMB#491` and
`docs/design/157-capability-completion-worklist.md`, or start the Ayumi rescue
lane from a fresh DRM.jl worktree rather than the dirty saved checkout.
