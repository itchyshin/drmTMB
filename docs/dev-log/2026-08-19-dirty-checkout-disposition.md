# Dirty checkout disposition: 2026-08-19

## Why `git status` showed about 100 paths

The shared checkout at `/Users/z3437171/Dropbox/Github Local/drmTMB` is not one
unfinished edit. It is a mission-control checkout containing tracked changes,
untracked work products, platform-agent state, and many registered worktrees.
At the final read-only census in this task, ordinary `git status --short`
displayed 102 rows because Git collapses untracked directories. Expanding all
untracked files with `-uall` produced 162 rows: 14 tracked changes and 148
untracked paths. One of those untracked paths is the isolated worktree created
for this repair; the pre-repair census was 161 expanded rows.

| Top-level area | Expanded untracked paths | Disposition |
| --- | ---: | --- |
| `scratchpad/` | 71 | Preserve; ownership and scientific value are ambiguous. |
| `.worktrees/` | 34 | Preserve the registered worktrees; ignore the container directory after this change reaches the checkout. |
| `docs/` | 22 | Preserve; these may be unlanded evidence or handoff records. |
| `.claude/` | 18 | Preserve; another platform may own these files. |
| `.codex/` | 2 | Preserve; agent state requires an owner decision. |
| `tests/` | 1 | Preserve; potentially substantive test work. |

The repository currently has 73 registered worktrees, including this repair
worktree, and 8 stashes. `git worktree prune --dry-run --verbose` proposed no
stale registrations. The shared branch was 1,166 commits behind and 5 commits
ahead of `origin/main` at this census. Rebasing, resetting, deleting, or moving
its files would therefore risk destroying or misattributing active work.

## Safe cleanup completed

This repair adds `.worktrees/` to `.gitignore`. Once that change is merged and
the shared checkout incorporates it, registered worktrees stop inflating the
untracked-path display. The worktrees themselves are not deleted or moved.

The function-map work was isolated on `codex/function-map-cheatsheet-repair`, so
none of the 14 tracked changes or ambiguous untracked files in the shared
checkout were overwritten. Generated `pkgdown-site/` files are ignored build
outputs and were not among the 102 displayed rows.

## Deliberately not cleaned

No stash, worktree, scratchpad file, agent file, document, test, or tracked
change was deleted, reset, moved, staged, or committed from the shared
checkout. Those paths need owner-aware review by subject rather than a bulk
cleanup command. This is a conservative disposition, not a claim that the
shared checkout is clean.
