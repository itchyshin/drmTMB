# After Task: Phase 18 Current-State Map Clean-Branch Salvage

## Goal

Restore the Phase 18 core family completion map onto
`codex/phase18-reconcile-small` without replaying the conflicted local-only
stack.

## Implemented

Added a clean-branch version of
`docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md` and
linked it from `ROADMAP.md` and
`docs/design/41-phase-18-simulation-programme.md`.

## Mathematical Contract

No model, likelihood, formula grammar, or parameterization changed. The map
separates fitted ordinary count routes, q=1 phylogenetic smoke/formal-admission
routes, fixed-effect family artifact lanes, and planned skew-family work.

## Files Changed

- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-26-phase18-current-state-map-clean-branch-salvage.md`

## Checks Run

```sh
git cherry-pick --no-commit 0de73de0
git restore --source=HEAD --staged --worktree -- ROADMAP.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/41-phase-18-simulation-programme.md docs/dev-log/after-task/2026-05-25-phase18-core-family-completion-map-slices-1279-1288.md docs/dev-log/after-task/2026-05-25-phase18-current-state-revalidation-slices-909-1008.md docs/dev-log/check-log.md
air format ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-26-phase18-current-state-map-clean-branch-salvage.md
rg -n 'formal recovery.*(now complete|is complete|passed|closed)|coverage.*(now complete|is complete|passed|closed)|broad.*non-Gaussian.*(ready|complete)|skew_normal\(\).*supported|skew-t.*supported|proportion.*artifact.*done|positive-continuous.*artifact.*done|ordinal.*artifact.*done' ROADMAP.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/41-phase-18-simulation-programme.md
git diff --check
```

## Tests Of The Tests

No R tests were added or changed. This was a docs-only routing slice, so the
guard was a targeted stale-promotion scan plus whitespace hygiene.

## Consistency Audit

The restored map says the clean branch has fitted count and shape surfaces where
the current ledgers already support them. It does not claim that the
proportion, positive-continuous, or ordinal artifact lanes are already restored
on this clean branch.

## GitHub Issue Maintenance

No issue was opened or changed. This was local branch reconciliation.

## What Did Not Go Smoothly

The direct cherry-pick of `0de73de0` conflicted in `ROADMAP.md` and
`docs/dev-log/check-log.md`, so Ada abandoned the replay and restored the map as
a smaller current-branch patch.

## Team Learning

Rose should treat old local commits as evidence sources, not automatic patches,
when the clean branch already contains overlapping upstream work.

## Known Limitations

The fixed-effect proportion, positive-continuous, and ordinal artifact lanes are
still not carried forward on this clean branch. They remain separate future
salvage slices.

## Next Actions

Carry forward the fixed-effect proportion artifact lane as the next small
non-code or low-code review slice, after checking for upstream overlap.
