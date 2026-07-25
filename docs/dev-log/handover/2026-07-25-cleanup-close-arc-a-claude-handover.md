# Session Handoff: cleanup lane CLOSED; next arc = Arc A (cross-package parity)

**Meta:** 2026-07-25 · from Claude · target **Claude** · cleanup/hygiene lane → new arc lane

You are **Claude**, picking up drmTMB from a previous Claude session. This doc stands alone —
you will not see that chat. Read `AGENTS.md` first, then this doc.

**Your job is to ULTRA-PLAN Arc A. Planning only.** Nothing is half-built; the previous lane
closed cleanly.

---

## Critical Context

Two things, or you will go wrong:

1. **This is a MULTI-LANE repository. Do not collapse the lanes into one "latest" task.** The
   cleanup lane described here is finished. Three *other* lanes are live and are **not yours**:
   the eta/bivariate lane (PR #829), `codex/arc6-6-bernoulli-nb2-plan`, and
   `codex/pkgdown-formal-closeout`. Each is declared in Landing State below. Do not resolve,
   reset, or merge any of them.
2. **Do not trust the root checkout.** `/Users/z3437171/Dropbox/Github Local/drmTMB` sits on
   `claude/handover-freshness-0718`, roughly **170 commits behind `main`**, with **65
   uncommitted files** belonging to the AGHQ/REML lane. **Work in a fresh worktree off
   `origin/main`.** This actually bit the previous session: an audit run against that stale
   tree produced a false "7 anchors still broken" result that had to be re-verified and
   retracted. Assume the same trap.

## Goals / mission

drmTMB = fast univariate/bivariate distributional regression on TMB, marching toward a v1.0
capability surface. The live programme turns `point_fit_recovery` ledger cells into
`inference_ready_with_caveats` with honest, pre-registered evidence. North star: packages that
ecologists and evolutionary biologists actually use and trust — not one-off analyses.

## The problem Arc A solves

Capability census on `main` (`docs/dev-log/dashboard/capability-census/_master.tsv`, 676 cells):

| evidence_tier | cells |
| --- | ---: |
| `point_fit_recovery` | **158** ← the stuck pool |
| `diagnostic_only` | 70 |
| `interval_feasible` | 44 |
| `inference_ready_with_caveats` | 27 |
| `supported` | 4 |
| `none` | 3 |

676 = 306 implemented + 330 rejected_by_design + 40 not_implemented.

**The throughput arithmetic is the whole problem.** Promoting `mc-0227` cost one full arc plus a
14,400-fit Totoro campaign to move **one** cell. At that unit cost the 158-cell pool is
unreachable. **Any plan that does not change cost-per-cell is theatre.**

### The finding that defines the arc

`tests/testthat/test-comparators.R` is **1,245 lines** of agreement tests against lme4/glmmTMB at
1e-4 tolerance. The AGHQ arc matched `glmmTMB(REML = TRUE)` to **7.3e-9** and `glmer(nAGQ = 25)`
to **3.6e-5**.

Of 306 implemented cells, **exactly 2 cite comparator evidence** in `evidence_source`.

Rigorous cross-package validation is already happening and is **structurally invisible to the
ledger**: there is no tier a parity result can promote a cell *into*. That is a missing
instrument, not excessive conservatism.

### The governing distinction — do not lose this

Shinichi's framing: *"if it's good enough for glmmTMB or brms, it should be good enough for
drmTMB."*

**Right:** glmmTMB, brms, gamlss and mgcv have *no per-cell coverage certification at all*. Their
credibility rests on likelihood correctness, broad regression tests, a few published simulation
studies, and years of field use. drmTMB holds itself to a standard no comparable package meets,
then reports ~31 green cells out of 676 — which reads to a user as "this package can't do much"
when the truth is "this package is the only one that checked."

**Wrong:** the argument licenses the **overlap** region, not the **frontier**. Where drmTMB is
genuinely novel — scale-side random effects, `sd()` regression, bivariate LSS, phylo on residual
log-SD — no established implementation exists to borrow credibility from, and that is exactly
where `mc-0242` and `mc-0227` found real small-sample bias.

**Therefore: parity retires the overlap cheaply so the expensive Monte-Carlo campaign can
concentrate on the frontier.** A design that blurs overlap and frontier is credibility-laundering
and must be rejected in review.

## Arc A, as scoped

1. **Define a `parity_validated` evidence tier** — what agreement with an established
   implementation does and does not license. Ledger-policy change; needs Rose + Fisher review.
2. **Build the comparator mapping table** — per cell: which comparator, which exact model, what
   tolerance, and critically **what the match does NOT cover**. That last column is most of the
   intellectual work and is what separates evidence transfer from laundering.
3. **Sweep the overlap region.** Disagreements are bugs, found against ground truth.
4. **Publish as a vignette** — the user-facing artifact.

**Slice 1 = risk-stratified triage of the 158**: classify by predicted difficulty
(asymptotically standard + high information → cheap; small-M / boundary / low-information /
scale-side → expensive). This says which cells legitimately qualify for parity and prevents the
tier being invented ad hoc.

### Audience test (Shinichi's own framing)

Ben Bolker (glmmTMB), Wolfgang Viechtbauer (metafor), Jarrod Hadfield (MCMCglmm), David Warton
(mvabund/ecostats) **will not read a coverage ledger.** Each validates a new package the same
way: fit a model they already trust, in their own package, check drmTMB matches.

- **Bolker** → glmmTMB overlap; `dispformula` maps onto drmTMB's `sigma ~ x`.
- **Viechtbauer** → `metafor::rma.mv` with known `V` is a near-exact oracle for `meta_V(V = V)`,
  and sits directly on the Arc 7B/8 lane just completed. **Recommended first concrete target.**
- **Hadfield** → phylogenetic / animal relationship matrices.
- **Warton** → residual diagnostics, mean–variance checking.

### Comparator availability (verified 2026-07-25, this machine)

Installed: **metafor 5.0.1**, glmmTMB 1.1.14, lme4 2.0.1, mgcv 1.9.4, ordinal 2025.12.29,
VGAM 1.1.14, statmod 1.5.2. Absent: **brms**, gamlss, betareg, rstan, cmdstanr, spaMM.

metafor being present means the Viechtbauer target needs **no install**. brms is the only
comparator covering skew_normal, tweedie, zero_one_beta, ordinal **and** distributional σ
simultaneously, but needs a Stan toolchain — treat installing it as an explicit scoping decision
with a real cost, not a default.

Targeting shape — implemented cells by family: biv_gaussian 144, gaussian 55, nbinom2 19,
poisson 15, beta 8, student 8, gamma 7, lognormal 7, zero_one_beta 6, skew_normal 5, tweedie 5,
remainder ≤4 each. By effect type: structured 198, fixed 50, ordinary_re_slope 30,
ordinary_re_intercept 28. **Note the 198 structured cells are largely frontier, not overlap.**

## Why Arc A before the C++ audit

Shinichi asked whether to audit `src/drmTMB.cpp` first. **No — parity first.** Parity against an
independent implementation has ground truth; reading C++ does not. A defect that does not show as
disagreement with glmmTMB on the same model is either in the frontier region (no comparator —
precisely where a C++ audit earns its keep) or is not changing results. So Arc A finds bugs *and*
moves the ledger; the C++ audit goes second, aimed where parity cannot reach.

When it does run: scope it **correctness-first** (log-sum-exp and overflow paths, link/inverse-link
edge cases, boundary parameterizations, finite-difference vs TMB AD gradient agreement).
*Efficiency* claims need **profiling evidence** — a model reading C++ can flag suspicious patterns
but cannot tell you what is hot. Do not let it emit performance claims without a profiler.

## What Was Accomplished (previous session)

- **Merged, each after confirming green checks + `CLEAN` merge state + no blocking reviews, and
  each on Shinichi's explicit approval:** #832 (Arc 8 meta-`V`) `d8888cfa`, #835 (next-days
  overview) `247611c6`, #837 (anchor hygiene) `eabca4fd`. #838 (Arc A brief) `1e572197` was
  merged by Shinichi.
- **Settled the inbound handover's open question on the seven baseline failures.** All seven were
  *drifted line anchors*, **none semantic**: every cited `cli::cli_abort()` message still exists
  verbatim in its original file. Five of seven detail strings occur 2–3× in `R/drmTMB.R`, so each
  candidate site was inspected to confirm it belongs to *that* gate rather than being a
  coincidental substring match. Fixed in #837; **0 failing anchors on `main`**, verified against
  `main`'s own sources.
- **Diagnosed #829:** it is a **nav de-duplication**, not an article update or deletion. The
  bivariate non-Gaussian article was listed in both Tutorials and Specialist Routes; the PR
  removes the duplicate. The article stays. Its conflict is **solely** `docs/dev-log/check-log.md`
  — the one-line `_pkgdown.yml` change merges clean.
- **Diagnosed the CI red wave as a GitHub Actions outage**, not a repo defect (see Gotchas).

## Current Working State

- **Working:** `main` @ `eabca4fd`, fully green (`os-matrix` + `ubuntu-latest (release)`).
  Baseline test signal restored — `test-estimator-surface-conformance.R` passes 147 expectations,
  0 failures, with `NOT_CRAN=true` so the live REML admission gates run against real fits.
- **In progress:** nothing. The cleanup lane is closed.
- **Blocked / not yours:** PR #829 (conflict-dirty, other owner); PR #836 (the inbound Codex
  handover, still DRAFT — Shinichi's to close); PR #828 (**never merge**, standing instruction).

## Key Decisions & Rationale

- **Arc A before the C++ audit** — parity has ground truth, code reading does not (above).
- **Parity licenses the overlap, not the frontier** — the arc's load-bearing constraint (above).
- **Merged branches deleted after merge** (`claude/estimator-surface-anchor-hygiene`,
  `handover/2026-07-25-arc-a-parity`); commits are all on `main`.
- **Arc 8's boundary is unchanged by its merge:** target-wise direct-SD profile/bootstrap
  *engineering feasibility* only. It establishes no recovery, coverage, calibrated inference,
  capability tier, or authority for Totoro/DRAC work.
- **`meta_V(V = V)` remains the known-sampling-covariance contract.** Do not add a `tau ~`
  grammar; do not treat direct-SD engineering feasibility as calibrated inference.

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `main` `eabca4fd` | yes | yes | — | **LANDED** — green |
| Arc 8 meta-`V` `d8888cfa` | yes | yes | #832 merged | LANDED |
| Next-days overview `247611c6` | yes | yes | #835 merged | LANDED |
| Arc A brief `1e572197` | yes | yes | #838 merged | LANDED |
| Anchor hygiene `eabca4fd` | yes | yes | #837 merged | LANDED |
| This handover | pending | pending | to be opened | CARRIED-OVER: the transfer itself; **merge only after human review**. |
| `codex/fix-bivariate-nav-dup` | yes | yes | #829 dirty | **CARRIED-OVER FOREIGN** — eta/bivariate owner. Conflict is solely `check-log.md`. Do not resolve from this lane. |
| `handover/2026-07-25-claude` | yes | yes | #836 DRAFT | CARRIED-OVER — the inbound Codex handover; Shinichi closes it. |
| `codex/arc6-6-bernoulli-nb2-plan` | yes | **no (2 commits)** | none | **CARRIED-OVER FOREIGN** — `a3d58b2e`, `de87ffe2` unpushed. Do not modify; resume only on that branch with explicit scope confirmation. |
| `codex/pkgdown-formal-closeout` | yes | **no (1 commit)** | none | **CARRIED-OVER FOREIGN** — `c018908a` "docs: close pkgdown reader-surface audit". Unpushed and undeclared by any prior handover; surfaced by `handoff_gate.sh`. **Needs an owner decision.** |
| root checkout `claude/handover-freshness-0718` | partial | no | none | **CARRIED-OVER FOREIGN** — 65 uncommitted files (AGHQ/REML lane, incl. a 2026-07-22 Cox–Reid citation audit), ~170 commits behind `main`. **Do not touch.** Resume only in its own checkout after reading its own handover. |

## Files Created / Modified (this session's landed diff, `e4f392f3..eabca4fd`)

- `docs/dev-log/dashboard/estimator-surface-conformance.tsv` — seven `evidence` anchors refreshed.
- `docs/dev-log/after-task/2026-07-25-estimator-surface-anchor-hygiene.md` — new.
- `docs/dev-log/handover/2026-07-25-arc-a-parity-handover.md` — new (Arc A brief; this doc
  supersedes and extends it).
- `inst/sim/run/sim_run_meta_v_lss_smoke.R`, `docs/dev-log/check-log.md` — via #832.
- `docs/dev-log/2026-07-25-next-days-overview.md` — via #835.
- Plus this handover doc and the `AGENTS.md` snapshot edit.

## Next Immediate Steps

1. **Create a fresh worktree off `origin/main`.** Do not use the root checkout (Critical Context).
2. **Ultra-plan Arc A** with the `ultra-plan` skill. Deliverable is a **plan**, not an
   implementation.
3. **Slice 1 = risk-stratified triage of the 158** `point_fit_recovery` cells (cheap / medium /
   expensive), which determines which cells legitimately qualify for parity.
4. **Slice 2 = the `parity_validated` tier definition** + the comparator mapping table schema,
   including the mandatory "what this match does NOT cover" column.
5. **First concrete target = metafor `rma.mv` known-`V` parity for `meta_V(V = V)`.** No install
   needed.
6. **Review before anything runs:** Fisher (inference lens) + Rose (systems audit). Rose is
   mandatory before any public capability claim; default verdict is NOT-DONE.
7. Only then propose execution, and **stop for Shinichi's explicit approval**.

## Blockers / Open Questions

- **Which arc first is Shinichi's call.** Arc A recommended; the C++/numerical audit is the
  natural second.
- **brms install** is an open scoping decision (Stan toolchain cost vs. the only comparator
  covering skew_normal/tweedie/zero_one_beta/ordinal with distributional σ).
- **Reconciliation item:** the served capability surface shows 23 inference-ready; the census on
  `main` shows 27 `inference_ready_with_caveats` + 4 `supported`. Probably pre-dates the
  mc-0227/mc-0242 promotions — worth confirming, not assumed.
- **`docs/dev-log/check-log.md` needs a decision.** ~4.7 MB, append-only, touched by nearly every
  PR, so concurrent PRs collide there for no substantive reason. Sole cause of #829's conflict and
  will recur. Options: per-run log files, or drop from version control. Flagged, not fixed.

## Gotchas & Failed Approaches

- **The stale-root trap (cost a real retraction).** Verifying `main`'s TSV against the root
  checkout's R files produced a confident, wrong "7 anchors still broken." The root tree is ~170
  commits old. Always verify against the tree you are actually claiming about.
- **A CI red wave on 2026-07-25 was a GitHub Actions outage, not a repo defect.** Symptoms worth
  recognising: `startup_failure` (workflow never starts — no jobs, no logs, no annotations) across
  *every* branch at once, plus runs marked `failure` while **all their jobs succeeded** (seen on
  R-CMD-check #1836 and pkgdown #821). A run cannot be failed by repo content when all jobs pass.
  Check `githubstatus.com` before debugging. Fix was `gh run rerun`; nothing in the repo changed.
- **Do not use GitHub Actions for any simulation/recovery/coverage campaign** (D-50). Totoro or
  DRAC; results stay local + in the repo dev-log. Never store campaign output as Actions artifacts.
- **Standing compute gate:** no campaign fit until a plan-reviewed S0 gate spec has Shinichi's
  explicit approval. Arc A's parity sweep is *cheap* (one fit per cell, no replication), so it may
  need no campaign at all — but **say so explicitly in the plan** rather than assuming.
- **Ledger mechanics for any tier change:** key edits by `cell_id`, never line number; keep
  `estimator = "ML"` (a new token flips the family-map slope to "absent"); substitute stale prose
  rather than appending; a promotion must decrement `test_capability_ledger.py`'s
  `point_fit_recovery` count; then `capability_ledger.py --write`, `--check`, and
  `python3 -m unittest tools.tests.test_capability_ledger`.
- **`devtools::test(reporter = "summary")` piped to `tail` buffers everything** — you get no
  partial output and cannot judge progress. Write to a file or use a streaming reporter.
- **Never merge PR #828.** Standing instruction, carried forward.

## Mission Control

| Lane | Branch / PR | State | Evidence / boundary | Next by leverage |
| --- | --- | --- | --- | --- |
| Cleanup + baseline hygiene | `main` `eabca4fd` | **CLOSED, green** | 147 expectations / 0 failures; full CI 29m58s | Nothing. Done. |
| **Arc A — parity tier** | none yet | **NOT STARTED ← next** | 1,245 lines of comparator tests; 2/306 cells cite them | **Ultra-plan it.** Triage 158 → tier definition → metafor first |
| C++ / numerical audit | none | Not started | — | Second arc; correctness-first, profiler for any efficiency claim |
| Eta / bivariate | #829 | Dirty, foreign | Conflict solely `check-log.md` | Owner resolves; do not touch |
| Arc 6.6 Bernoulli/NB2 | `codex/arc6-6-bernoulli-nb2-plan` | 2 unpushed, foreign | — | Needs scope confirmation |
| pkgdown closeout | `codex/pkgdown-formal-closeout` | 1 unpushed, foreign | — | **Needs an owner** |
| AGHQ / REML | root checkout | 65 uncommitted, foreign | — | Resume in its own checkout only |
| `check-log.md` hygiene | none | Flagged | 4.7 MB conflict magnet | Shinichi decides: split or untrack |

## How to Resume

1. Read `AGENTS.md` — the "▶ Latest — start here" snapshot — then **this doc**.
2. Read the Arc A brief `docs/dev-log/handover/2026-07-25-arc-a-parity-handover.md` and the
   planning source `docs/dev-log/2026-07-25-next-days-overview.md`.
3. **Fresh worktree off `origin/main`** — never the root checkout.
4. Team lenses live in `.claude/agents/` (mirrors `.codex/agents/`). **Rose's systems audit is
   mandatory before any capability claim; default NOT-DONE.** Fisher reviews inference claims.
5. Claude plans, refactors, writes prose, and runs logic/CI checks. Route real R/TMB fits,
   `R CMD check`, rendering, or any approved compute campaign to a live-toolchain session.
   Useful exports: `export NOT_CRAN=true` (full testthat suite, not the CRAN subset).

**One-command resume** (paste in an authenticated terminal at the repo root):

```
claude "Rehydrate from docs/dev-log/handover/2026-07-25-cleanup-close-arc-a-claude-handover.md + the AGENTS.md snapshot, then ultra-plan Arc A: cross-package parity as a `parity_validated` evidence tier, with risk-stratified triage of the 158 point_fit_recovery cells as slice 1 and metafor/meta_V parity as the first concrete target. Plan only — Fisher + Rose review before anything runs."
```
