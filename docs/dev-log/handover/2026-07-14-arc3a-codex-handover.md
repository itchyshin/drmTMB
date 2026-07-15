# Arc 3a closeout handoff

Meta: 2026-07-14 · Codex to fresh Codex · PR #782

## Critical Context

Arc 3a is complete on `codex/arc3a-positive-continuous-structured-mu` and PR
#782 is open. Do not merge it without Shinichi's explicit authorization. Do not
start the next arc merely because this plan exists. PR #781 is unrelated and
was not touched.

## Goal and Result

The arc adds native univariate-ML pure-`mu` q1 structured intercepts for
Gamma-phylo and lognormal-phylo/relmat. `mc-0251`, `mc-0386`, and `mc-0388` are
verified at `point_fit_recovery`; no interval, coverage, REML, structured
`sigma`, slope, label/q2+, other-provider, bivariate, or supported claim is
included.

## Evidence

- Primary Totoro campaign: 6,000/6,000 valid, no failures, raw SHA-256
  `b303aab6781770e14be096b69c95b5da0e803f703cf3321baa91750a6465dcd3`.
  Lognormal-relmat and Gamma-relmat passed; the two phylo routes retain their
  original absolute-RMSE HOLD.
- Separate predeclared phylo addendum: 2,400/2,400 valid, no failures, raw
  SHA-256 `f4c3a0da9089cffd51a1703d2d2ba6526da5ca84db8ac26d9022926e6032d9cd`.
  Exact GLS and structured-projection oracles passed both phylo cells.
- Focused: 201 expectations, 0 failures. Full suite: 38,676 passes, 0 failures,
  62 known warnings, 24 expected optional-Julia skips.
- Preliminary genuine `--as-cran`: normalized 0/0/0. Final docs/ledger tree
  rebuilt and passed installation, static, Rd, and example checks; the duplicate
  embedded full-test leg was stopped after the independent final suite passed.
- `document()`, pkgdown check/build, all 34 ledger tests, runtime route check,
  generated-output check, and Mission Control passed.
- Fisher, Noether, and Rose: PASS.

## Landing State

| Artifact | State | Resume command |
| --- | --- | --- |
| `codex/arc3a-positive-continuous-structured-mu` | CARRIED-OVER deliberately: committed/pushed, PR #782 open pending current-head CI and explicit merge authorization | `gh pr view 782 --json state,mergeStateStatus,headRefOid,statusCheckRollup` |
| 358 unrelated local branches reported by the handoff gate | CARRIED-OVER protected user state; do not modify | `/Users/z3437171/Dropbox/Github\ Local/Shinichi/tools/handoff_gate.sh /Users/z3437171/.codex/worktrees/3d16/drmTMB` |
| PR #781 | unrelated open PR, untouched | `gh pr view 781` |

The handoff gate was run after PR creation. It reports the active branch as
committed, pushed, and PR-backed, but exits nonzero solely because of the 358
pre-existing unrelated branch tips declared above.

## Next Arc Decision

Recommended, not approved: **Arc 1b-S1**, one existing ML
bivariate-Gaussian, location-only, fixed-covariance spatial q2 intercept cell
under REML. Its exact copy-paste GOAL and ultra-plan are in
`docs/dev-log/2026-07-14-next-arc1b-spatial-q2-reml-ultra-plan.md`. It is next
because an ML comparator and dense restricted-likelihood oracle already exist,
so the slice isolates one REML admission boundary.

The proposed distribution-wide `sd()` arc is banked in
`docs/dev-log/2026-07-14-post-arc3a-sd-arc-candidate.md`. Its Beta example
combines two absent gates. If revived, split it into Beta phylogenetic `mu`,
canonical `sd()` parser/extractor on Gaussian, then combined Beta
location-scale-scale. Every family retains its own scale contract.

## Exact Next Steps

1. Verify PR #782 remains open, the remote head equals local, and current-head
   GitHub CI is green; wait if pending.
2. Report the merge disposition and wait. Never merge without explicit
   authorization.
3. After an authorized merge, synchronize clean `main`.
4. Present the Arc 1b-S1 copy-paste GOAL and ultra-plan again and wait for
   separate execution approval.

Authoritative closeout:
`docs/dev-log/after-task/2026-07-14-arc3a-positive-continuous-structured-mu.md`.
