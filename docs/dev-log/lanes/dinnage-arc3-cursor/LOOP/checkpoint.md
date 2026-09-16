# Dinnage Arc3 Coordinator Checkpoint

Updated: 2026-09-15 18:10 MDT

## Current Scope

Wave A only.

## Done

- Rehydrated from PR #1366 on branch/worktree `claude/lane-dinnage-arc3-cursor`.
- Ran required lane preflight from the foreground checkout and coordinator worktree.
- Confirmed all 39 Dinnage audit issues were open before A4 was closed.
- Released the broad `docs/dev-log/lanes/dinnage-arc3-cursor/` lease that blocked specialists.
- A4 #1351 is DONE: https://github.com/itchyshin/drmTMB/issues/1351#issuecomment-5689879524. Vault CRAN release-gate skill was updated by a separate agent and is being committed in the vault.

## Active

- **Blocker class:** WIP in worktrees but **no commits, no pushes, no PRs** (Ada poll 18:10 MDT).
- A1 docs PR: uncommitted `R/formula-markers.R` + partial `NEWS.md` (A-4 only); 9 issues still open in lane scope.
- A2 check.R PR: uncommitted `R/check.R` (A-8); Mi-5 / wave4a tests / NEWS still open; `R/profile.R` leased to `claude:drmTMB-a1-docs`.
- A3 misc code PR: uncommitted TMB beta_binomial nudge (Md-H); Curie test file untracked under separate lease; `cursor:dinnage-arc3-a3-misc` lease on src/R paths.

## Held

- Wave B and Wave C remain held.
- Deferred/protected items remain out of Wave A scope.

## Lease Guidance

Do not lease the whole `docs/dev-log/lanes/dinnage-arc3-cursor/` directory. Use exact file paths.

Gauss A3:

```sh
LANE_ID='gauss:dinnage-arc3-A3' ~/shinichi-brain/tools/lane_lease.sh --claim drmTMB --paths 'src/,R/drmTMB.R,R/methods.R,R/phylo-utils.R,R/associate-pairs.R,R/aghq-coxreid.R,tests/testthat/test-numeric-kernel-oracle.R,tests/testthat/test-dinnage-audit-wave4a.R,NEWS.md'
```

## Resume

```sh
cd /Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor
cat docs/dev-log/lanes/dinnage-arc3-cursor/LOOP/GOAL.md
cat docs/dev-log/lanes/dinnage-arc3-cursor/CLAIMS.md
~/shinichi-brain/tools/lane_lease.sh --list drmTMB
```
