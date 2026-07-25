# Handover → fresh Claude session (2026-07-25): ULTRA-PLAN Arc A — cross-package parity as an evidence tier

**From:** Claude (cleanup + hygiene lane) · **To:** a fresh Claude session · **Task:** ultra-plan Arc A
**Why a new lane:** context exhaustion in the originating session, not a blocker. Nothing is half-built.

This doc stands alone. Read `AGENTS.md` first, then this. **Your job is to ULTRA-PLAN Arc A, not to
implement it** — planning first, then Shinichi approves scope before any sweep runs.

---

## The problem Arc A solves

drmTMB's capability census (`docs/dev-log/dashboard/capability-census/_master.tsv`, 676 cells) on
`main`:

| evidence_tier | cells |
| --- | ---: |
| `point_fit_recovery` | **158** ← the stuck pool |
| `diagnostic_only` | 70 |
| `interval_feasible` | 44 |
| `inference_ready_with_caveats` | 27 |
| `supported` | 4 |
| `none` | 3 |

676 total = 306 implemented + 330 rejected_by_design + 40 not_implemented.

**The throughput arithmetic is the whole problem.** Promoting `mc-0227` cost one full arc plus a
14,400-fit Totoro campaign to move **one** cell. At that unit cost the 158-cell pool is unreachable.
Any plan that does not change *cost per cell* is theatre.

## The finding that defines the arc

`tests/testthat/test-comparators.R` is **1,245 lines** of agreement tests against lme4/glmmTMB at
1e-4 tolerance. The AGHQ arc matched `glmmTMB(REML = TRUE)` to **7.3e-9** and `glmer(nAGQ = 25)` to
**3.6e-5**.

Of 306 implemented cells, **exactly 2 cite comparator evidence** in `evidence_source`.

Rigorous cross-package validation is already being done and is **structurally invisible to the
ledger**. There is no tier a parity result can promote a cell *into*. That is a missing instrument,
not excessive conservatism.

## The governing distinction (do not lose this)

Shinichi's framing: *"if it's good enough for glmmTMB or brms, it should be good enough for drmTMB."*

**Right:** glmmTMB, brms, gamlss and mgcv have *no per-cell coverage certification at all*. Their
credibility rests on likelihood correctness, broad regression tests, a few published simulation
studies, and years of field use. drmTMB is holding itself to a standard no comparable package meets,
then reporting ~23–31 green cells out of 676 — which reads to a user as "this package can't do much"
when the truth is "this package is the only one that checked."

**Wrong:** the argument licenses the **overlap** region, not the **frontier**. Where drmTMB is
genuinely novel — scale-side random effects, `sd()` regression, bivariate LSS, phylo on residual
log-SD — no established implementation exists to borrow credibility from, and that is exactly where
`mc-0242` and `mc-0227` found real small-sample bias.

**Therefore: parity retires the overlap cheaply; the expensive Monte-Carlo campaign concentrates on
the frontier, where it actually earns something.** This is the arc's thesis. A design that blurs
overlap and frontier is credibility-laundering and must be rejected.

## Arc A, as scoped

1. **Define a `parity_validated` evidence tier** — what agreement with an established implementation
   does and does not license. This is a ledger-policy change and needs Rose + Fisher review.
2. **Build the comparator mapping table** — per cell: which comparator, which exact model, what
   tolerance, and critically **what the match does NOT cover**. That last column is what separates
   evidence transfer from laundering, and it is most of the intellectual work.
3. **Sweep the overlap region** and record results. Disagreements are bugs, found against ground truth.
4. **Publish it as a vignette** — the user-facing artifact.

**Fold in a risk-stratified triage of the 158** as the arc's first slice: classify by predicted
difficulty (asymptotically standard + high information → cheap; small-M / boundary / low-information
/ scale-side → expensive). This tells you which cells legitimately qualify for parity and which must
go to campaign, and it prevents the tier being invented ad hoc.

## Why this before the C++ audit

Shinichi asked whether to look at the C++ (`src/drmTMB.cpp`) first. **No — parity first.** Parity
against an independent implementation has ground truth; reading C++ does not. A defect that does not
show as disagreement with glmmTMB on the same model is either in the frontier region (no comparator
— which is precisely where a C++/numerical audit earns its keep) or is not changing results. So Arc A
finds bugs *and* moves the ledger; the C++ audit goes second, aimed where parity cannot reach.

When the C++ audit does run: scope it correctness-first (log-sum-exp and overflow paths, link and
inverse-link edge cases, boundary parameterizations, finite-difference vs TMB AD gradient agreement).
*Efficiency* claims need profiling evidence — a model reading C++ can flag suspicious patterns but
cannot tell you what is hot. Do not let it produce performance claims without a profiler.

## The audience test (Shinichi's own framing)

Ben Bolker (glmmTMB), Wolfgang Viechtbauer (metafor), Jarrod Hadfield (MCMCglmm), David Warton
(mvabund/ecostats) **will not read a coverage ledger.** Each validates a new package the same way:
fit a model they already trust, in their own package, and check it matches.

- **Bolker** → glmmTMB overlap; note `dispformula` maps onto drmTMB's `sigma ~ x`.
- **Viechtbauer** → `metafor::rma.mv` with known `V` is a near-exact oracle for `meta_V(V = V)`, and
  it sits directly on the Arc 7B/8 lane just completed. **Recommended first target.**
- **Hadfield** → phylogenetic / animal relationship matrices.
- **Warton** → residual diagnostics and mean–variance checking.

## Comparator availability (verified 2026-07-25, this machine)

Installed: **metafor 5.0.1**, glmmTMB 1.1.14, lme4 2.0.1, mgcv 1.9.4, ordinal 2025.12.29,
VGAM 1.1.14, statmod 1.5.2.
Absent: **brms**, gamlss, betareg, rstan, cmdstanr, spaMM.

metafor being present means the Viechtbauer target is actionable immediately with no install.
brms is the only comparator covering skew_normal, tweedie, zero_one_beta, ordinal **and**
distributional σ simultaneously — but it needs a Stan toolchain. Treat installing it as an explicit
scoping decision with a real cost, not a default.

Census shape for targeting: by family, implemented cells are biv_gaussian 144, gaussian 55,
nbinom2 19, poisson 15, beta 8, student 8, gamma 7, lognormal 7, zero_one_beta 6, skew_normal 5,
tweedie 5, remainder ≤4 each. By effect type: structured 198, fixed 50, ordinary_re_slope 30,
ordinary_re_intercept 28. Note the 198 structured cells are largely *frontier*, not overlap.

## Landing state

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `main` `247611c6` | yes | yes | #835 merged | LANDED |
| Arc 8 meta-`V` | yes | yes | **#832 MERGED** `d8888cfa` | LANDED (this session, on Shinichi's explicit approval) |
| Next-days overview | yes | yes | **#835 MERGED** `247611c6` | LANDED (this session, same approval) |
| `claude/estimator-surface-anchor-hygiene` `9dba8c4a` | yes | yes | **#837 OPEN** | CARRIED-OVER: awaiting CI. Merge when green. Local target-file run was 147 passing / 0 failures. |
| `codex/fix-bivariate-nav-dup` | yes | yes | #829 dirty | CARRIED-OVER FOREIGN: eta/bivariate owner. Conflict is **solely** `docs/dev-log/check-log.md`; the one-line `_pkgdown.yml` change merges clean. Do not resolve from another lane. |
| `codex/arc6-6-bernoulli-nb2-plan` | yes | **no (2 commits)** | none | CARRIED-OVER FOREIGN: `a3d58b2e`, `de87ffe2`. Do not modify; resume only on that branch with explicit scope confirmation. |
| `codex/pkgdown-formal-closeout` | yes | **no (1 commit)** | none | CARRIED-OVER FOREIGN: `c018908a` "docs: close pkgdown reader-surface audit". Unpushed and undeclared by any prior handover — surfaced by `handoff_gate.sh`. Needs an owner decision. |
| root checkout `claude/handover-freshness-0718` | partial | no | none | CARRIED-OVER FOREIGN: 65 uncommitted files (AGHQ/REML lane, incl. a 2026-07-22 Cox–Reid citation audit). **Do not touch.** Resume only in its own checkout. Note the root checkout was 168 commits behind `main` at session start. |

## What this session actually did

- Merged #832 and #833-follow-on lane work per the 2026-07-25 Codex handover's step 2/3, after
  confirming green checks + `CLEAN` merge state + no blocking reviews, and after explicit approval.
- **Settled the handover's open question on the seven baseline failures.** All seven are *drifted
  line anchors*, none semantic: every cited `cli::cli_abort()` message still exists verbatim in its
  original file. Five of seven detail strings occur 2–3× in `R/drmTMB.R`, so each site was inspected
  to confirm it belongs to *that* gate rather than a coincidental substring match. → PR #837.
- Diagnosed #829: it is a **nav de-duplication**, not an article update or deletion. The bivariate
  non-Gaussian article was listed in both Tutorials and Specialist Routes; the PR removes the
  duplicate. The article stays.

## Gotchas

- **`docs/dev-log/check-log.md` (~4.7 MB, append-only) is a structural conflict magnet.** Nearly
  every PR appends to it, so concurrent PRs collide there for no substantive reason. It is the sole
  cause of #829's conflict and will keep recurring. Deserves its own decision (per-run log files, or
  drop from version control) — flagged, not fixed.
- **Do not use GitHub Actions for any simulation/recovery/coverage campaign** (D-50). Totoro or DRAC,
  results local + repo dev-log.
- **Standing compute gate:** no campaign fit until a plan-reviewed S0 gate spec has Shinichi's
  explicit approval. Arc A's parity sweep is *cheap* (one fit per cell, no replication), so it may not
  need a campaign at all — but say so explicitly in the plan rather than assuming.
- The `capability_ledger.py` mechanics for any tier change: key edits by `cell_id` never line number;
  keep `estimator = "ML"` (a new token flips the family-map slope to "absent"); substitute stale prose
  rather than appending; then `--write`, `--check`, and
  `python3 -m unittest tools.tests.test_capability_ledger`.
- Minor reconciliation item: the served capability surface shows 23 inference-ready; the census on
  `main` shows 27 `inference_ready_with_caveats` + 4 `supported`. Probably pre-dates the mc-0227 /
  mc-0242 promotions. Worth confirming.

## How to resume

Work in a **fresh worktree off `origin/main`** — the root checkout is dirty with a foreign lane.
Use the `ultra-plan` skill. Deliverable is a **plan**, reviewed by Fisher (inference) and Rose
(systems audit) before any sweep runs.

```
Rehydrate from docs/dev-log/handover/2026-07-25-arc-a-parity-handover.md, then ultra-plan Arc A:
cross-package parity as a new `parity_validated` evidence tier, with a risk-stratified triage of the
158 point_fit_recovery cells as slice 1 and metafor/meta_V parity as the first concrete target.
Plan only — Fisher + Rose review before anything runs.
```
