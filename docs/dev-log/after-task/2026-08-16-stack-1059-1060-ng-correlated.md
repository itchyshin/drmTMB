# After Task: Stack #1060 onto #1059 (Design 257 Wave 1 then Wave 2)

**Reader:** the post-quiesce merger, plus Fisher / Noether if they re-read the stack.
**Lane:** Cursor stacked `cursor/ng-correlated-slope-wave2` onto
`cursor/ng-correlated-slope-impl`. Worktree
`/Users/z3437171/local-scratch/lanes/drmTMB-ng-corr-stack`.
**Quiesce:** neither PR merges to `main`. Drafts only.

## Goal

Remove the high merge-conflict risk between #1059 (`mc-0717`) and #1060
(`mc-0718`) by rebasing Wave 2 onto the Wave 1 tip and retargeting #1060 to
the Wave 1 branch.

## Files created or changed

Wave 2 commit replayed onto Wave 1. Shared paths now carry both cells:

- `NEWS.md` — both wave notes
- `docs/design/257-nongaussian-ordinary-correlated-slope.md` — one file; Wave 0
  “no family” text replaced by the live Wave 1+2 contract
- `docs/design/01-formula-grammar.md` — both routes
- ledger `cells.tsv` / `evidence.tsv` / `transitions.tsv` / `schema.json` —
  `mc-0717` source_order 717 then `mc-0718` source_order 718;
  `MODEL_SURFACE_COUNT = 701`
- regenerated census / surface / vignette includes
- `tools/capability_ledger.py` and `tools/tests/test_capability_ledger.py`

## Checks run and exact outcomes

| Check | Result |
| --- | --- |
| `python3 tools/capability_ledger.py --check` | OK (31 generated outputs); C14 receipt equivalence OK |
| `python3 -m unittest tools.tests.test_capability_ledger -q` | 79 OK |
| Focused R tests | `binomial-correlated-re-mspl-prereq\|reml-binomial-coxreid\|poisson-ordinary-correlated-q2\|poisson-mean` FAIL 0 / WARN 0 / SKIP 0 / PASS 250 |

## Consistency audit

Both cells are `point_fit_recovery` only. `mc-0061` and `mc-0431` stay the
independent-slope neighbours. `rho12` is not used for the group-level
correlation. No merge to `main`. Foreign lanes (#1033, MSPL, Ligges, CRAN)
were not touched.

## What did not go smoothly

The Dropbox worktree `.worktrees/ng-corr-w2` raced the first rebase (local
changes after checkout of the Wave 1 tip). The stack was completed in
`local-scratch` instead.

## Known limitations and next actions

After quiesce: merge #1059 to `main`, then #1060 (already based on Wave 1).
Do not open NB2, intervals, REML, or `supported` from this stack.
