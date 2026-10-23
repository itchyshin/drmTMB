# Dinnage Arc3 Wave A Ultra-Plan

## Key Decisions

- Wave A only is active now.
- Wave B and Wave C are held until Wave A integration says otherwise.
- PR branches and worktrees are based on `origin/main`, not the dirty foreground checkout.
- `git push` and `gh pr create` are allowed for specialist wave branches; merge, tag, release, CRAN submission, and email are not.
- Any branch touching `R/methods.R` or `R/drmTMB.R` must run `tools/recertify-c17.py` last.

## Coordinator Duties

1. Keep `CLAIMS.md` accurate without holding a broad lane-directory lease.
2. Track A1-A4 owners, leases, branches, tests, commits, and PRs.
3. Resolve collisions before integration.
4. Write the morning handoff by 2026-09-16 05:00 MDT.

## Specialist Dispatch

- A1 docs: documentation specialist.
- A2 check/profile: check.R specialist, with Curie test support.
- A3 misc code/TMB: Gauss owns code-sensitive work, with Curie test support.
- A4 record: coordinator/Rose can handle vault release-gate line plus issue comment.
