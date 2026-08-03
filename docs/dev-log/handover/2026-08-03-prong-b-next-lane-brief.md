# Next lane brief — Prong B: open the profile fences

Meta: 2026-08-03 · carried forward from the interval-feasibility programme · **execution-ready**
Full scoping: [`scratchpad/2026-08-03-prong-b-scoping-decision.md`](../../scratchpad/2026-08-03-prong-b-scoping-decision.md) (348 lines, read it first)
Programme handover: [`2026-08-03-claude-handover.md`](2026-08-03-claude-handover.md)

---

## 🎯 GOAL — paste this to start the lane

```text
🎯 GOAL
PLATFORM: Claude (runs the live R/TMB fits, the Totoro campaign, and R CMD check itself).
DELIVERABLE: (1) FIRST, make interval LOCATION machine-checked: add `true_value` and `brackets_truth`
as recorded receipt fields written by tools/run-arc2-profile-feasibility.R and CHECKED by
tools/arc2_profile_reconcile.py. (2) THEN execute Prong B Tier 1: open the 14 zero-one-beta and count
profile fences in R/profile.R and promote the cells the evidence earns.
HEADLINE: the reconciler is blind to whether an interval CONTAINS the truth — three promotions
reconciled 5/5 PASS while missing it. Fix the gate before adding cells behind it.
IN PARALLEL: the 11-cell `zoi` calibration pilot; the one-fit labelled-vs-unlabelled spelling experiment.
DEFER: q12 (16 cells — a POLICY fence; Shinichi's call, not the agent's); the 3 estimator holds
(mc-0182/0183/0261, where REML marginalizes the mean fixed effects so there is no direct target); the 4
diagnosed STOPs; coverage and calibration of any kind; inference_ready/supported.
DO NOT: reopen coi (mc-0570, mc-0578, mc-0613, mc-0614, mc-0617) — the owner's 2026-08-01 disposition
says the receipt stays BLOCKED_POINT_RECOVERY and is not rewritten.
DISCIPLINE: this is the FIRST R/ source change of the programme — it pulls in document(), man/, nine
test call sites, first-ever se=TRUE tests, NEWS for exactly 14 routes, and a local --as-cran. The edits
delete PREDICATES, not cells, so BEFORE MERGE diff profile_targets() across the whole test suite pre-
and post-edit; anything flipping profile_ready TRUE outside the 14 gets re-fenced or accepted in
writing. Five seeds minimum, gate and campaign sharing ONE seed family, per-seed truth-bracketing blocks
promotion even when the mean passes. Compute on Totoro, never GitHub Actions.
```

---

## Task 1 — the reconciler gate (do this first)

**Why it comes first.** `tools/arc2_profile_reconcile.py::reconcile()` validates target, cohort, family,
estimator, `conf_status`, convergence, `pdHess`, boundary, clamp, trace and artifact hashes. Its
`required` dict has **no truth field**. It therefore checks interval *shape* and cannot check interval
*location*. Three promotions were caught only because a human recomputed bracketing by hand, and all
three had reconciled **5/5 PASS**:

| Cell | Receipt | Truth | Failure |
|---|---|---|---|
| `mc-0423` | `[0.137, 0.479]` | 0.55 | truth above the upper endpoint |
| `mc-0409` | `[0.610, 0.902]` | 0.6 | truth below the lower endpoint |
| `mc-0292` | `[0.404, 0.694]` | 0.7 | upper endpoint 0.006 short of truth |

In the `mc-0292` case the producing agent printed the correct endpoints and then asserted "YES".

**The change.** `run-arc2-profile-feasibility.R` already knows each fixture's true value (it is in every
cell registry entry's `true_parameter_scale`). Emit it as `true_value`, compute
`brackets_truth = (lower < true_value) && (true_value < upper)`, and have `reconcile()` require
`brackets_truth == TRUE` for every seed. Add an adversarial test that a receipt with a non-bracketing
interval is **rejected** — mirroring the existing four mutation tests.

**Backfill note:** existing receipts lack the field. Either treat it as optional-if-absent for
already-merged cohorts, or backfill from each cell's registry entry. Do not silently pass old receipts
as if they had been checked.

---

## Task 2 — Prong B Tier 1: the 14 cells

**The 30 fenced cells partition by `dpar` physics, not by family or fence token.** That is the
load-bearing finding of the scoping.

**PROMOTE (14)** — every one profiles a *scale* parameter estimated from all rows, and every spiked
representative gave a clean two-sided profile covering truth on the first seed:

| Group | Cells |
|---|---|
| zero_one_beta `sigma` ordinary | `mc-0568`, `mc-0576` |
| zero_one_beta `sigma` structured | `mc-0593`, `mc-0594`, `mc-0595`, `mc-0596`, `mc-0597` |
| count `mu` labelled q2 | `mc-0418`, `mc-0436`, `mc-0446`, `mc-0450`, `mc-0454` |
| count `sigma` phylo_interaction | `mc-0425`, `mc-0653` |

**Compute is trivial: ~70 fits, 135 profile runs, ≤30 min Totoro** under the 100-core cap. The real
budget is reviewing 135 traces.

### The source change

Four surgical edits in `R/profile.R` (exact lines in the memo):
- delete the disjuncts at **4028** and **4029**
- **KEEP 4030** — `zi_nbinom2` ordinary sigma is deliberately out of scope
- narrow **4031–4035** to `c("mu", "zoi", "coi")`
- delete the correlation branch at **1507–1515**
- delete `zero_one_beta_sigma_q1_profile_restricted` (**4103–4112**) plus its call sites at **1408** and
  **4039–4044**, then remove the orphans

Then: `document()` → `man/profile_targets.Rd`, nine test call sites, the **first-ever `se=TRUE` tests**,
NEWS claim-boundary text for exactly 14 routes, ledger `point_fit_recovery → interval_feasible`, and a
local `R CMD check --as-cran`.

### ⚠ THE MANDATORY PRE-MERGE GATE — collateral unlock

**The edits delete *predicates*, not *cells*.** Every route a predicate governed becomes profile-ready,
**including routes with no ledger cell and no evidence** — `zero_one_beta_sigma_q1_profile_restricted`
never constrains `random$mu$n_re`, for instance.

**Before merge: dump `profile_targets()` across the whole test suite pre- and post-edit and diff
`profile_ready`. Anything flipping TRUE outside the 14 must be re-fenced or accepted in writing.**

This is the single biggest risk in the lane and it is invisible to `--check`.

---

## Task 3 — the `zoi` pilot (11 cells, short)

**HOLD, pilot first.** `zoi` failed the contract in two different ways at two sample sizes: at n=288 the
NLL was flat to `log_sd_zoi = -1.5e22`; at n=1600 it profiled cleanly but with 46.4% point-fit error and
truth **below** the lower bound. Structured `mu` (`mc-0583`–`mc-0587`) returned a CI `[0.246, 0.534]`
excluding true 0.55 on its spike.

These look like **fixture problems, not mechanism problems**. A ~10-minute calibration pilot would likely
convert them into a second slate. Do not fold them into Tier 1's evidence.

Cells: `mc-0569`, `mc-0577` (ordinary) · `mc-0603`, `mc-0604`, `mc-0605`, `mc-0607` (structured) ·
`mc-0583`–`mc-0587` (structured `mu`).

---

## Task 4 — the one-fit spelling experiment

Two independent lanes disagreed on whether labelled `provider(1 | p | group)` and the **unlabelled
auto-linked** spelling are the same fitted model. That decides whether `mc-0291`/`mc-0292` are **one
ledger block or two**, and whether the two halves of several "matched blocks" share an evidence base at
all.

**A single toy fit comparing `profile_targets()` output on both spellings settles it.** Cheap, and it
unblocks a claim-boundary question already written into three merged cells.

---

## KEEP FENCED — do not reopen

`coi`: `mc-0570`, `mc-0578` (ordinary), `mc-0613`, `mc-0614`, `mc-0617` (structured).

Two independent reasons:
1. **Governance.** The 2026-08-01 owner disposition states in writing that the receipt "remains
   BLOCKED_POINT_RECOVERY … and is not rewritten." Opening these extends a scoped point-fit allowance
   into interval territory Shinichi explicitly declined.
2. **Statistics.** `coi` is a conditional boundary probability, `Pr(y = 1 | y ∈ {0,1})`, estimated only
   from observations already at a boundary, with `min_group_one` as low as 1–2. Near-zero per-cluster
   information by design.

---

## Carried-over PRs to land first

**#907** (`claude/arc5-final-three`) and **#908** (`claude/arc6-gaussian-nine`) were both CI-green and
were conflicted by #905 merging. Rebase onto current `main`, re-run CI, merge. **#908 deliberately
withholds `mc-0292` — do not re-add it.**

Landing these moves the surface from 172/70 to roughly **184/58**.

## Operational notes

- `capability_ledger.py --write` emits **30 outputs, not all under `docs/dev-log/dashboard/`** — notably
  `vignettes/includes/capability-ledger-family-map.md`. **Stage whatever `--write` touches.**
- Campaign drivers use `^` as delimiter, **never `|`** — targets embed a literal `|`.
- Totoro: `R CMD INSTALL` ignores `R_LIBS_USER`, pass `-l <lib>`; connect only via the existing
  ControlMaster socket (`ls ~/.ssh/cm-*totoro*`), a fresh login triggers Duo.
- After every batch, adversarially flip one extra frozen cell and confirm `--check` fails.
