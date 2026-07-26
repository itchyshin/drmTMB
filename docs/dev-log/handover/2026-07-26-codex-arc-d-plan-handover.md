# Handover — Arc C closeout, then Arc D plan-only

**Date:** 2026-07-26 · **To:** fresh Codex session

## State at handover creation

- PR #846 (private general latent-normal association sandwich implementation)
  merged to `main` as `1834734a`. It remains private infrastructure: no public
  inference, full-refit comparison, simulation, or compute follows from that
  merge.
- Arc B's C++/numerical audit already merged as PR #842. Do not re-open it as
  the next arc.
- PR #845 (`claude/arc-c-hardening`, tip `0209351d`) is Arc C: beta `mi()`
  clamp ordering (A5) plus citation-anchor hygiene (A7). F5 was attempted and
  deliberately reverted. At this handover's creation, its release CI was still
  pending; refresh GitHub rather than trusting this timestamp.
- This planning branch is `codex/arc-d-inference-contract-plan`, based on the
  Arc C tip. It adds only the Arc D ultra-plan; it has no F5 implementation.

## Landing state

- **LANDED:** `codex/arc-d-inference-contract-plan` at `491604f4` is committed
  and pushed to `origin`.
- **CARRIED-OVER, foreign:** the handoff gate also reports 17 unpushed commits
  on other branch(es), including `claude/arc-a-external-comparator-evidence`
  and `codex/arc6-6-bernoulli-nb2-plan`. They pre-date this handover and are
  outside Arc C/Arc D; do not clean, merge, rebase, or push them from this lane.

## First read

1. `docs/dev-log/2026-07-26-arc-d-scale-clamp-profile-contract-ultra-plan.md`
2. `docs/design/245-f5-sd-regression-clamp-and-identifiability.md`
3. `docs/dev-log/after-task/2026-07-25-arc-c-clamp-ordering-and-anchor-hygiene.md`
4. `docs/dev-log/after-task/2026-07-25-arc-b-cpp-numerical-audit.md`

## First commands

```sh
gh pr checks 845 --repo itchyshin/drmTMB
gh pr view 845 --repo itchyshin/drmTMB --json state,mergeStateStatus,headRefOid,reviews
git status --short --branch
```

## Arc C merge rule

Merge #845 only when the release check is green on its exact tip, the branch is
clean, and review retains both limitations:

1. A5's test is structural rather than falsifying (it also passes pre-repair).
2. F5's finite K=12 profile under the tight clamp is false precision, so the
   reverted implementation must stay reverted.

After merging, verify `origin/main` and merged-main CI before calling Arc C
closed. Then update this handover with the exact merge receipt.

## Arc D boundary

Arc D is **plan-only** until the owner selects a contract in D1. It must not
edit the nine unbounded `sd()` predictor sites, change public interval status,
run the 177-cell campaign, or widen into association-engine validation. The
three candidate contracts and decision gates are in the ultra-plan.

## Do not touch

- The private association engine's validation/public-inference scope.
- Any full-refit, bootstrap, recovery, coverage, simulation, Totoro, or DRAC
  work without a fresh explicit approval.
- Foreign worktrees or old branches; create a fresh worktree from merged main
  for any approved Arc D implementation.
