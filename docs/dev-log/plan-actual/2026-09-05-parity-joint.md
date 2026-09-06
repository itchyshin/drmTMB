# Plan vs actual -- parity-joint lane, 2026-09-05

**SKELETON. Every status below reads `TODO`. Filling them is the A11 closure pass.**

Reader: Shinichi, and whoever runs the closure. This file reconciles the approved
ultra-plan against what actually landed, one row per arc, so the closure states a
measured outcome for every arc it promised -- including the arcs that were dropped,
descoped, or replaced. It exists as a skeleton BEFORE the closure so the final pass
is a fill-in against a fixed, provably complete arc list, not an authoring job under
time pressure, which is how a closure ends up claiming more than it did.

## Provenance

| | |
|---|---|
| arc list derived from | `docs/dev-log/loop/parity-joint-20260905/ultra-plan.md` |
| at drmTMB sha | `df1aca4a60f9f450629238f241392d11f44d2d3a` |
| arcs listed | 23 |
| ARC PROGRAM table rows in that file | 12 |

The arc list was extracted mechanically and checked at generation time: every
`| **A...** |` row of the plan's ARC PROGRAM table is represented below, and
generation aborts if one is not. Two rows expand: `A4.1`-`A4.9` expand the plan's
single `A4.1-A4.9` row into its nine named families, in the order the plan gives
them (cheapest payload first); `A7.1`-`A7.3` expand the plan's `A7` row into the
three leaves it names. `A0.5` is the one arc that is NOT in the ARC PROGRAM table --
the 24-HOUR BURN section adds it -- and it is cited to the line that adds it.

## How to fill this

1. For each arc, replace `TODO` with one of `DONE`, `PARTIAL`, `DROPPED`, `REPLACED`
   or `NOT STARTED`, and fill `actual` with a MEASURED outcome carrying a citation
   (a merged PR number read from GitHub, a receipt id, or a file:line). A relayed
   "done" is not evidence: read the merge state from GitHub.
2. Fill `drift` with the difference between planned and actual, including drift that
   flatters the lane -- an arc that turned out unnecessary is drift too.
3. Add every arc that was EXECUTED BUT NOT PLANNED to the second table. That table
   being empty at closure would itself be a finding, not a pass.
4. A working draft with candidate content -- another agent's, written mid-flight and
   explicitly marked for re-measurement -- sits at
   `~/local-scratch/lanes/parity-joint-20260905/LOOP/2026-09-05-parity-joint-plan-vs-actual.DRAFT.md`.
   Treat it as a source of leads, never as measured evidence. Its A2 row says the
   matrix has 43 rows; the matrix at this sha has 45. Re-measure before copying any
   number out of it.

## Arcs

| arc | planned | status | actual (measured, cited) | drift |
|---|---|---|---|---|
| **A0** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:157`) | RE-PIN to DRM.jl 430ef64cc (f7 protocol: probe clone, copy Manifest, precompile, full 37-file sweep, vendor run_suite.sh, write source-pins.json); receipt regenerated LAST | TODO | TODO | TODO |
| **A0.5** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:200`) | Split family admission into per-family files so nine A4 children own nine disjoint files (added by the 24-HOUR BURN section, not in the original arc table) | TODO | TODO | TODO |
| **A1** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:158`) | CI trust: #1083 errors->skips, #1081 0% bridge glue, #1150 receipt checks in CI (detect, not regenerate) | TODO | TODO | TODO |
| **A2** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:159`) | THE MATRIX as a generated artefact: tools/write-parity-matrix.R -> docs/design/parity-matrix.md; rename-guard for the phylo_gamma_beta_binomial trap; a test that fails when an ADMITTED family lacks a TSV row | TODO | TODO | TODO |
| **A3** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:160`) | Ledger the admitted-but-unledgered routes (Student-t, LogNormal, FE Gamma/Poisson/NB2/Beta) with parity_fixture.R / parity_se.R receipts each | TODO | TODO | TODO |
| **A4.1** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:161`) | ADMIT Tweedie through the bridge (family tag, dpar payload + coef_labels, four limbs, receipts, TSV row, RED control) | TODO | TODO | TODO |
| **A4.2** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:161`) | ADMIT skew-normal through the bridge | TODO | TODO | TODO |
| **A4.3** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:161`) | ADMIT zero-one-inflated beta through the bridge | TODO | TODO | TODO |
| **A4.4** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:161`) | ADMIT beta-binomial through the bridge | TODO | TODO | TODO |
| **A4.5** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:161`) | ADMIT zero-inflated Poisson (ZIP) through the bridge | TODO | TODO | TODO |
| **A4.6** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:161`) | ADMIT zero-inflated NB2 (ZINB) through the bridge | TODO | TODO | TODO |
| **A4.7** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:161`) | ADMIT truncated NB2 through the bridge | TODO | TODO | TODO |
| **A4.8** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:161`) | ADMIT hurdle NB2 through the bridge | TODO | TODO | TODO |
| **A4.9** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:161`) | ADMIT cumulative logit (ordinal) through the bridge, incl. cutpoints and #1144 | TODO | TODO | TODO |
| **A5** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:162`) | Ordinary RE: measure DRM.jl's ML/REML support for (1|g), random slope and sigma-RE with the estim_method oracle; rows + receipts for what verifies, a written boundary for what does not | TODO | TODO | TODO |
| **A6** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:163`) | DRM.jl #467 + #609 factors: factor()/I()/poly()/^/- through the bridge with R-contrast fidelity | TODO | TODO | TODO |
| **A7.1** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:164`) | U port: #1116 chibar / lrt_boundary, same-target tests against the Julia original | TODO | TODO | TODO |
| **A7.2** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:164`) | U port: #1117 aicc + anova/lrtest | TODO | TODO | TODO |
| **A7.3** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:164`) | U port: #1118 coevolution accessors | TODO | TODO | TODO |
| **A8** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:165`) | P2 - G3 bridge-side inference qualification (profile + bootstrap through engine="julia"), per route, small convergent cells; promotes TSV rows 2/3/5/12 partial->supported | TODO | TODO | TODO |
| **A9** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:166`) | Remaining P: DRM.jl #620 two-SD slope, #609 varying-scale g_tol, #1156 profile_targets union, #1144 cutpoint polish, #569/#1108 route-aware diagnostics | TODO | TODO | TODO |
| **A10** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:167`) | P4 - warm-workflow performance grid; the designed pre-run runs first, the full grid only after the pre-run receipt AND Shinichi's explicit go (D-139 gate) | TODO | TODO | TODO |
| **A11** (`docs/dev-log/loop/parity-joint-20260905/ultra-plan.md:168`) | P5 closure: regenerate the matrix; scoreboard; capability-status join; NEWS on both repos; the handover; Melissa plan-vs-actual; Rose after-task | TODO | TODO | TODO |

## Executed but not planned

Arcs, leaves and owner tasks that were not in the approved plan. One row each, with
the same evidence bar as the table above.

| what | why it appeared | status | actual (measured, cited) |
|---|---|---|---|
| TODO | TODO | TODO | TODO |

## Node gates (the plan's own acceptance ledger)

| gate | requirement | status | evidence |
|---|---|---|---|
| `N1` | every leaf `gate-check.mjs --reverify` exit 0 in its own worktree (`--status` is not evidence) | TODO | TODO |
| `N2` | `parity_ledger.py` reports CLOSURE: PASS at the FINAL pin | TODO | TODO |
| `N3` | `write-parity-matrix.R` regenerates byte-identically from committed inputs | TODO | TODO |
| `N4` | Rose refutes at least one passing gate per arc | TODO | TODO |
| `N5` | every negative gate has a red control recorded | TODO | TODO |

## Closure checklist

| item | status | evidence |
|---|---|---|
| `capability_ledger.py --check` green | TODO | TODO |
| both receipt checkers `--self-test` pass | TODO | TODO |
| full drmTMB `devtools::test()` once per major arc (NOT_CRAN=true), with its D-139 estimate line | TODO | TODO |
| `docs/design/parity-matrix.md` regenerated at the FINAL pin | TODO | TODO |
| `docs/design/parity-scoreboard.md` regenerated at the FINAL pin; the UNCITED count re-measured and quoted | TODO | TODO |
| `docs/design/capability-status-join.md` regenerated against DRM.jl `origin/main` | TODO | TODO |
| NEWS on both repos | TODO | TODO |
| DESCRIPTION -> 0.7.1 PREPARED, NOT TAGGED | TODO | TODO |
| Rose after-task on BOTH repos | TODO | TODO |
| handover with the exact RESUME line | TODO | TODO |

## Process drift (honest)

TODO. Record what went wrong in the RUNNING of the lane, not only in its output:
outages and relaunches, wrong model tiers, over-claimed landings, pushes that broke
a file, gates declared green on an empty result set. A closure that reports only
product drift and no process drift has not looked.

## What this lane did NOT cover

TODO. Name the limits explicitly: capabilities still UNCITED on the bridge axis
(`docs/design/parity-scoreboard.md` counts them and lists them one by one), gates
that stayed red, campaigns that were gated and never ran, and anything a reader
might reasonably assume the word "parity" covers and this lane did not measure.
