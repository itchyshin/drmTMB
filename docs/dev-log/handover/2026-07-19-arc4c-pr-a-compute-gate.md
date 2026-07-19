# Session Handoff: Arc 4c PR A open; CI, merge, and compute gate pending

Meta: 2026-07-19 · from Codex · PR-A infrastructure closeout

## Critical Context

Arc 4c PR-A infrastructure is implemented, locally verified, and open as draft PR #797 from `codex/arc4c-mu-slope-coverage-infra`. No Arc 4c model fit, Fir compile, smoke, array, campaign result, or ledger promotion has run. The next two gates are distinct: first pass CI, let the maintainer merge PR A, and verify its exact `origin/main` merge SHA; then obtain Shinichi's explicit Gate A compute approval.

## What Was Accomplished

- Froze the three-family ML-Laplace runner, all-attempt coverage gate, deterministic seed/shard mapping, smoke-selection rule, and Fir resource policy.
- Added retained-attempt execution, atomic checksum checkpoints, fail-closed resume/aggregation, preflight provenance, and three Slurm workers.
- Added 242 focused expectations plus a 3,600-row executable synthetic aggregation and corruption cases.
- Completed local package, ledger, pkgdown, Mission Control, after-task, and source-tarball checks. Final `devtools::check()` reported 0 errors, 0 warnings, and 0 actionable notes; the outer check retained only the repository's report-only spelling transcript NOTE.
- Preserved the dirty root worktree without edits or cleanup.

## Current Working State

- Working: branch `codex/arc4c-mu-slope-coverage-infra`; draft PR #797 is open from the clean isolated worktree.
- In progress: ordinary package/docs CI and maintainer review.
- Not working / blocked: every fit-based Arc 4c action is blocked until PR A merges and Shinichi separately approves Gate A.

## Key Decisions & Rationale

- Keep `estimator=ML`; O3/Cox-Reid is a later family-specific response to negative evidence.
- Primary coverage is hits over all 1,200 attempts; unavailable intervals are noncoverage.
- M=64 must pass and acceptable non-exploratory rungs must form a contiguous suffix of `{16,32,64}`.
- M=8 is exploratory and never sets the deployment floor.
- Fir runs at most 96 single-threaded tasks concurrently; no simulation runs or artifacts use GitHub Actions.

## Landing State

The handoff gate found the active branch clean and pushed, but also reported 360 commits on pre-existing other branches. Those other branches are outside Arc 4c and were neither inspected nor modified.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `drmTMB` `codex/arc4c-mu-slope-coverage-infra` | yes | yes | #797 draft | CARRIED-OVER |

`CARRIED-OVER` because PR #797 still needs green CI and maintainer merge, while compute requires a later, separate approval. Resume with `cd '/Users/z3437171/Dropbox/Github Local/drmTMB-wt-arc4c-infra' && git fetch origin --prune && git status --short --branch`.

## Next Immediate Steps

1. Monitor PR #797's ordinary package/docs CI and repair any genuine failures, then mark it ready for maintainer review. Do not merge it as Codex.
2. After the maintainer merges, fetch and verify the exact merge SHA on `origin/main` and use a fresh `/project` clone at that SHA.
3. Stop and request explicit Gate A compute approval for the frozen twelve N=1 smokes and mechanically selected full array.
4. Only after approval, run preflight and smoke; apply the frozen selection rule without judgment calls.

## Blockers / Open Questions

- PR #797 is open but not yet merged.
- Compute approval has not been granted and cannot be inferred from PR-A implementation approval.
- Fir runtime/RSS and family-specific profile behavior remain unknown until the approved smoke.

## Gotchas & Failed Approaches

- Top-level `tools/` are excluded from source tarballs; development tests must skip there but execute in source checkouts.
- Quote paths passed to SHA helpers because the real workspace contains `Github Local`.
- Totoro's installed drmTMB is stale; Arc 4c is frozen for a fresh Fir clone and `pkgload::load_all()`.
- Do not change the ledger estimator token from `ML`; that would make the family-map slope appear absent.

## How to Resume

```sh
cd '/Users/z3437171/Dropbox/Github Local/drmTMB-wt-arc4c-infra'
git fetch origin --prune
git status --short --branch
git log -1 --oneline
sed -n '1,220p' docs/dev-log/handover/2026-07-19-arc4c-pr-a-compute-gate.md
sed -n '1,220p' docs/dev-log/2026-07-19-arc4c-three-cell-mu-slope-drac-s0.md
```
