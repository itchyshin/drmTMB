# After Task: `mc-0576` ADEMP freeze (ZO-beta sigma slope)

**Branch:** `cursor/mc0576-ademp-freeze` (docs-only off `origin/main`)
**Date:** 2026-08-16
**Lane:** Cursor. Stayed off PRs #1033 / #1059 / #1060 and off all `R/` / `src/`.

## Goal

Freeze the ADEMP + DGP/gate sheet for capability cell `mc-0576` so a later
coverage campaign cannot invent `M`, true SD, or `n_each`. The cell is already
`interval_feasible` on `origin/main`. This task does not run fits and does not
move the ledger.

## Implemented

One research ADEMP:

`docs/dev-log/research/2026-08-16-mc-0576-zo-beta-sigma-slope-ademp-freeze.md`

Frozen contract:

- estimand `sd:sigma:(0 + x | id)` on
  `bf(y ~ x, sigma ~ x + (0 + x | id), zoi ~ 1, coi ~ 1)`;
- true SD **0.45**, `n_each` **50**, `M ∈ {8, 16, 32, 64}`;
- Arc 4c / `mc-0242` profile-coverage gate language;
- later ceiling `inference_ready_with_caveats`, never `supported` in the first
  campaign;
- **do not launch**; Totoro-or-DRAC waits for owner GO.

The sheet names the neighbours it is not: `mc-0575` (`mu` slope), `mc-0568`
(sigma intercept), and correlated `(1 + x | id)`.

## Mathematical Contract

Unchanged. The freeze restates the existing Z5 / 135-trace DGP:

```text
log(sigma_{jk}) = -1 + b_j x_{jk},   b_j ~ N(0, 0.45^2)
```

Family `sigma` remains the interior-beta log-scale; `phi = 1 / sigma^2`. No
likelihood or grammar edit.

## Files Changed

- `docs/dev-log/research/2026-08-16-mc-0576-zo-beta-sigma-slope-ademp-freeze.md` (new)
- `docs/dev-log/after-task/2026-08-16-mc-0576-ademp-freeze.md` (this file)
- `docs/dev-log/check-log.md` (prepend)
- `docs/dev-log/coordination-board.md` (one peer-lane pointer)

No `R/`, `src/`, tests, ledger TSV, or NEWS.

## Checks Run

| Check | Result |
| --- | --- |
| `git show origin/main:…/cells.tsv` `mc-0576` | `interval_feasible`; next_gate = coverage out of scope |
| 135-trace constructor vs Z5 runner | same `M = 32`, `n_each = 50`, SD 0.45, target string |
| Neighbour collision | sheet excludes `mc-0575`, `(1 + x \| id)`, REML, Wave 3, NB2 |
| Stale-wording `rg` (below) | no accidental `supported` or `mu`-slope claim in the new files |
| Package tests / `--as-cran` | not run (docs only; no R/src) |

```sh
rg -n "supported|mc-0575|\\(1 \\+ x \\| id\\)|do not launch|n_each" \
  docs/dev-log/research/2026-08-16-mc-0576-zo-beta-sigma-slope-ademp-freeze.md
```

## Tests Of The Tests

No new tests. The verification is that the frozen numbers match the committed
135-trace cell registry and the Lane C Z5 simulator, and that the sheet
contains an explicit do-not-launch line.

## Consistency Audit

`README.md`, `ROADMAP.md`, `NEWS.md`, family registry, and formula-grammar
docs still describe `zero_one_beta` `sigma` random effects at the
pre-coverage claim. This PR does not refresh those surfaces; the ADEMP is
the prospective coverage contract, not a shipped-capability change.

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" \
  docs/dev-log/research/2026-08-16-mc-0576-zo-beta-sigma-slope-ademp-freeze.md \
  docs/dev-log/after-task/2026-08-16-mc-0576-ademp-freeze.md
```

`tau` appears only as the Z5 simulator argument name (`tau = 0.45`) and as
the explicit “not meta-analysis `tau`” fence. Public API remains `sigma`.

## GitHub Issue Maintenance

No issue opened or closed. Coverage for `mc-0576` was already recorded as a
separate goal on the ledger `next_gate`. PRs #1033 / #1059 / #1060 were not
touched.

## What Did Not Go Smoothly

The first worktree add into `.worktrees/` under Dropbox copied ~18k files
slowly. The branch itself is docs-only off `origin/main` and does not use the
dirty `claude/handover-freshness-0718` checkout.

## Team Learning

An `interval_feasible` cell still needs an ADEMP freeze before coverage:
the 135-trace DGP (`n_each = 50`, SD 0.45, ~33% structural 0/1) is not the
Arc 4c `mu`-slope DGP (`n_each = 15`, SD 0.50, 15% boundary). Reusing the
wrong sibling fixture would have been a silent design change.

## Known Limitations

This freeze does not choose Totoro vs DRAC, does not size wall-time or
memory, and does not authorize `N = 1200`. `N = 1200` is written only so a
later GO cannot shrink the denominator after seeing results.

## Next Actions

1. Merge this docs PR if the freeze is accepted.
2. Owner GO naming Totoro or DRAC, plus the immutable source SHA, before any
   smoke.
3. Do not start Wave 3, NB2, or REML 4b/4c from this cell.
