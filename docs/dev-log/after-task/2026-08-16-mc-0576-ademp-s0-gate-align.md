# After Task: `mc-0576` ADEMP Arc 4c S0 gate alignment

**Branch:** `cursor/mc0576-ademp-s0-align` (docs-only off `origin/main`)
**Date:** 2026-08-16
**Lane:** Cursor. Builds on merged PR #1062; does not relaunch the freeze.

## Goal

Keep the already-merged `mc-0576` ADEMP freeze, and make its promotion rule
match Arc 4c S0 instead of the weaker “lowest passing non-exploratory `M`”
wording that landed in #1062.

## Implemented

Edits to
`docs/dev-log/research/2026-08-16-mc-0576-zo-beta-sigma-slope-ademp-freeze.md`:

- frozen-contract scan table (SD 0.45, `n_each` 50, `M ∈ {8,16,32,64}`);
- design 257 cited by path (`docs/design/257-nongaussian-ordinary-correlated-slope.md`);
- Performance (2)–(3) now use Arc 4c S0 language: conservative-above-0.975,
  contiguous suffix of `{16, 32, 64}`, `M = 64` required, `M = 8` never sets
  the floor.

The DGP, estimand, do-not-launch line, and claim ceiling are unchanged.
**Do not launch.** Totoro-or-DRAC still waits for owner GO.

## Mathematical Contract

Unchanged from #1062.

## Files Changed

- `docs/dev-log/research/2026-08-16-mc-0576-zo-beta-sigma-slope-ademp-freeze.md`
- `docs/dev-log/after-task/2026-08-16-mc-0576-ademp-s0-gate-align.md` (this file)
- `docs/dev-log/check-log.md` (prepend)

No `R/`, `src/`, ledger, NEWS, or coordination-board rewrite.

## Checks Run

| Check | Result |
| --- | --- |
| #1062 on `origin/main` | freeze already merged; this PR is gate wording only |
| Gate (3) vs Arc 4c S0 | contiguous suffix + `M = 64` required |
| Neighbours | still excludes `mc-0575`, `(1 + x \| id)`, REML, Wave 3, NB2 |
| Package tests | not run (docs only) |

## Tests Of The Tests

No new tests. Verification is that the promotion rule now quotes Arc 4c S0
and that the frozen `(M, SD, n_each)` table is unchanged.

## Consistency Audit

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" \
  docs/dev-log/research/2026-08-16-mc-0576-zo-beta-sigma-slope-ademp-freeze.md
```

`tau` remains the Z5 simulator argument and the “not meta-analysis `tau`”
fence. Public API remains `sigma`.

## Design-Doc Updates

None. Design 257 is cited, not copied.

## pkgdown / Documentation Updates

None.

## GitHub Issue Maintenance

None. Stayed off #1033 / #1059 / #1060.

## What Did Not Go Smoothly

The freeze itself had already merged as #1062 while this lane was still
editing the same research note. This follow-up builds on that merge instead
of forking a second freeze.

## Team Learning

An `interval_feasible` ADEMP that says “reuse Arc 4c S0 gate language”
should copy the contiguous-suffix / `M = 64` rule, not only the
`[0.925, 0.975]` interval.

## Known Limitations

Still no host choice, no wall-time, no authorized `N = 1200`.

## Next Actions

1. Merge this docs PR if the S0 wording is accepted.
2. Owner GO naming Totoro or DRAC before any smoke.
3. Do not start Wave 3, NB2, or REML 4b/4c from this cell.
