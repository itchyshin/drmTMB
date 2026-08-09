# Gate H — durable HOLD checkpoint (Stage A closed, Stage B fenced)

**Date:** 2026-08-09 · **Lane:** Claude task 1, staged 0.7.0 candidate preparation
**Branch:** `claude/07-candidate-preparation-staged` @ `8eac0846f` (3 ahead of `origin/main`,
0 behind; **not pushed, no PR** — deliberate)
**Baseline:** `origin/main@ac363cadb605a2eda567de9027b873eebc4788c5`

## Status in one line

**NOT READY.** Highest rung proven for current `main`: **none**. `DESCRIPTION`: **`0.6.0`**.
Stage A is complete; **Stage B must not start** until the synchronization gate below clears.

## The gate

Stage B begins **only** when Claude task 2 lands a reviewed finite disposition —
**MERGE** validated package work, **DEFER** with no demonstrated release defect, or
**DEFECT** repaired with tests and review — **merged to `main`**, at
`docs/dev-log/after-task/2026-08-09-separation-finite-disposition.md`.

At that point, and not before:

1. Re-read the merged disposition receipt. **Never stage task 2's worktree.**
2. `git fetch origin main`; create a **fresh** clean worktree at the merged SHA. Do not
   reuse this Stage A worktree for the candidate build.
3. Re-run A1's drift check against the new tip; if the 15-file drift figure moved, the
   product contract and rights ledger are re-read before anything is frozen.

## Stage B sequence (fenced until then)

| Step | Action | Gate |
| --- | --- | --- |
| B0 | Refresh CRAN policy (**first**, before the freeze) | clears `current_cran_policy` |
| B0 | Land the intended release bytes as **one** reviewed commit: the three prepared fixes + `devtools::document()` | see `…-stage-b-byte-fixes.md` |
| B0 | Bump `DESCRIPTION` → `0.7.0` **inside** that release slice (D-86) | — |
| B1 | Freeze: clean worktree, empty `git status --porcelain`, record the SHA | — |
| B2 | `R CMD build` — **one** immutable tarball; hash, size, inventory, forbidden-path scan | D-49 |
| B3 | `R CMD check --as-cran --run-donttest`; install/load/examples in a clean temp library; `pkgdown::check_pkgdown()` + real site build; `urlchecker::url_check()`; **measure the Windows vignette total** | clears `tarball-clean`, `rendered_site`, `size_and_vignette_budget` |
| B4 | Authorized external checks on the **candidate hash** — 3-OS, win-builder, R-hub sanitizers | `platform-clean` **needs Shinichi's word**, unchanged |
| V/V2 | Mechanical verify + bounded review (not D-43) | — |
| C | Candidate decision packet → Shinichi | **STOP** |

## Hard stops — unchanged

**Do not**: fire D-43 · write `platform-clean` · finalise `cran-comments.md` · tag · publish
a GitHub release · upload to CRAN · rerun D-117 or any campaign · implement #870 · reinstate
any withheld claim.

## What Stage A produced

| Artifact | What it settles |
| --- | --- |
| `…-gate-orientation.md` | Gate -1 profile; the 15-file drift; the three coexisting artifact identities |
| `…-instrument-salvage.md` | Predecessor instruments are already on `main`; reuse map; nothing to cherry-pick |
| `release/0.7.0-cran-gate/STALE-EVIDENCE-QUARANTINE.md` | Written **into** the stale evidence directory so the trap is unmissable |
| `…-product-contract.md` | Current-main contract; supersedes the 2026-08-07 one (stale census) |
| `…-rights-ledger.md` | Component ledger; no blocking rights defect; three items owed at Stage B |
| `…-cran-release-ledger.json` | Deliberately **fails** the gate; the failure is the Stage B checklist |
| `…-ledger-gate-receipt.md` | The captured FAIL + the predecessor's misleading PASS side by side |
| `…-870-offset-analysis.md` | #870's premise inverted; a real docs-vs-code defect found instead |
| `…-stage-b-byte-fixes.md` | Three exact reviewed diffs, **prepared and held** |
| `…-pre-release-user-gap-review.md` | Four blind lenses; the convergent tier-visibility finding |
| `plan-actual/2026-08-09-0.7-candidate-stage-a.md` | 8 deviations, all adaptive, none drift |

## The three decisions waiting on Shinichi

1. **#870 `offset()`** — the roxygen grants `offset(log(exposure))` to `truncated_nbinom2`;
   a live fit rejects it. **Recommendation: Option 1**, delete three words, regenerate the
   `.Rd`. Option 2 (implement it) is a capability addition with a real evidence burden and
   belongs post-0.7.
2. **Tier surfacing** — four blind reviewers converged that the evidence tier is invisible
   at point of use. Ship 0.7 as-is and make surfacing the 0.8 headline, **or** take the one
   narrow fix (warn on the unguarded bootstrap-boundary path, mirroring the shipped profile
   warning). This changes user-facing output, so it is a scope call, not packaging.
3. **D-93 / D-117 publish-discharge** — unchanged, and candidate preparation does not answer
   it.

## Cross-lane, not mine to act on

The brain's deep-research index carries **`dr32-separation-rare-species-jsdm-distilled`**:
Konis's dual-LP separation detection at ~1 IRLS iteration, shipped in `detectseparation` /
`brglm2`, plus Albert–Anderson existence ⟺ overlap. Task 2's retained STOP is an invalid LP
infeasibility certificate and an unsupported `brglm2` interface. **Routed to Shinichi for
task 2; not acted on from this lane.**

## Protected state — untouched, verified

#858 · #937 · historical #947 · five repository stashes · the dirty primary checkout on
`claude/handover-freshness-0718` · `/Users/z3437171/local-scratch/worktrees/drmTMB-separation-s0`
· every other foreign worktree. No `git add -A` was used at any point.

## Resume command

```sh
cd /private/tmp/drmTMB-07-candidate-prep && git status --short --branch
```

Then read this file, then `…-ledger-gate-receipt.md` §5 for the exact owed evidence rows.
