# Handover — drmTMB interval-feasibility programme

Meta: 2026-08-03 · Claude · covers Arcs 2–6 · **start the next lane from this file**

## Where the surface stands

`161 interval_feasible / 77 point_fit_recovery` at the start of 2026-08-02 → **`~181 / 62`** once PRs
#907 and #908 merge. Fifteen cells promoted across the two days, with **four honest withholdings** rather
than forced passes.

Merged: #869, #891, #893 (mesh/SPDE), #895, #897 (Arc 2, six cells), #900 (Arc 3, six cells),
#904 (`mc-0417`), #905 (`mc-0207` split + demotion).
In flight: **#907** (`mc-0123`, `mc-0205`, `mc-0206`), **#908** (nine Gaussian cells).

## The one finding that outranks every cell

**(DONE, Arc 7b, 2026-08-03.)** This finding is fixed, not outstanding — see the corrected paragraphs
below and `docs/dev-log/after-task/2026-08-03-arc7b-profile-truth-gate.md` for the authoritative
account. The rest of this section is retained as the historical record of the gap.

**The mechanical reconciler cannot detect a mislocated interval.**
`tools/arc2_profile_reconcile.py::reconcile()` validates target, cohort, family, estimator,
`conf_status`, convergence, `pdHess`, boundary, clamp, trace, and artifact hashes. Its `required` dict
has **no truth field**. It therefore checks interval *shape* and is structurally blind to interval
*location*. *(CORRECTED 2026-08-03, Arc 7b: no longer true — `tools/profile_truth_gate.py` now checks
interval location and is wired into `reconcile()`.)*

Three promotions were caught **only** because a human-lens reviewer recomputed bracketing from the raw
receipts, and all three had reconciled **5/5 PASS**:

| Cell | Receipt | Truth | Failure |
|---|---|---|---|
| `mc-0423` | `[0.137, 0.479]` | 0.55 | truth above the upper endpoint |
| `mc-0409` | `[0.610, 0.902]` | 0.6 | truth below the lower endpoint |
| `mc-0292` | `[0.404, 0.694]` | 0.7 | upper endpoint 0.006 short of truth |

In the `mc-0292` case the build agent **printed the correct endpoints and then asserted "YES"** for
bracketing. That is a false claim, not a transcription slip.

**THE FIX, and it should be the next lane's first task:** make `true_value` and `brackets_truth`
recorded receipt fields, written by `tools/run-arc2-profile-feasibility.R` and *checked* by the
reconciler. Until that exists, every promotion depends on a human remembering to do arithmetic the
machine could do. It will recur. *(CORRECTED 2026-08-03, Arc 7b: this fix landed — `true_value` and
`brackets_truth` are recorded and checked, alongside a separate derived-truth manifest and gate. It is
no longer the next lane's task; see the DONE note at the top of this section.)*

## The contract as it now stands

Tightened twice during the programme, both times because something got through:

- Endpoints from **ONE** `stats::profile()` call — never separate `profile()`/`confint()`.
- A **predeclared point-fit recovery gate** (mean relative error ≤ 0.35) runs **before** any profile.
- **Five seeds** minimum, and the gate and the campaign must **share one seed family**.
  (`mc-0423`'s gate ran on seeds 423/523/623 while its campaign ran 2026080301-03 — its fragile seed
  was never gated at all.)
- **Per-seed truth-bracketing.** Any single seed with >0.35 relative error *or* an interval excluding the
  true value blocks promotion **even if the mean passes**.
- Never profile a variance component whose true value is zero — that hits the `[0, ∞)` boundary by
  construction and proves nothing about the software.

## What is left, honestly

**62 point_fit_recovery cells. ~25 reachable, ~37 not.**

### Reachable — Prong B, and it is turnkey
Full memo: `scratchpad/2026-08-03-prong-b-scoping-decision.md`.

The 30 fenced cells partition by **`dpar` physics, not by family or fence token** — that is the finding.

- **Tier 1, PROMOTE (14).** Everything profiling a *scale* parameter estimated from all rows. Every
  spiked representative gave a clean two-sided profile covering truth on the first seed.
  `sigma` ordinary (mc-0568, mc-0576) · `sigma` structured (mc-0593-0597) · count `mu` labelled q2
  (mc-0418, mc-0436, mc-0446, mc-0450, mc-0454) · count `sigma` phylo_interaction (mc-0425, mc-0653).
  *(ADDED 2026-08-03, Arc 7b owner decision: the `sigma` structured and count `sigma`
  phylo_interaction groups are ML-fit structured-sigma cells; a sibling nbinom2 cohort shows a
  family-level ML sigma-axis low bias
  (`docs/dev-log/after-task/2026-08-03-nbinom2-structured-sigma-family-low-bias.md`, fit-level
  p=0.0032, cell-level p=0.0625) and REML does not reach either family (`R/drmTMB.R:2221-2225`).
  Decision: fund all 14, but name both facts in each structured-sigma cell's `claim_boundary`.)*
- **Tier 2, PILOT FIRST (11).** `zoi` failed two different ways at two sample sizes — at n=288 the NLL
  was flat to `log_sd_zoi = -1.5e22`; at n=1600 it profiled cleanly but with 46.4% point-fit error and
  truth *below* the lower bound. Structured `mu` returned a CI excluding truth. Fixture problems, not
  mechanism problems; a short calibration pilot likely converts them.
- **Tier 3, KEEP FENCED (5).** The `coi` cells. **Governance, not statistics:** the 2026-08-01 owner
  disposition states in writing that the receipt "remains BLOCKED_POINT_RECOVERY … and is not
  rewritten." Do not reopen without a new decision from Shinichi.

Compute is trivial — **70 fits, 135 profile runs, ≤30 min Totoro**. The real budget is reviewing traces.

**THE BIGGEST RISK — collateral unlock.** The edits delete *predicates*, not cells. Every route a
predicate governed becomes profile-ready, **including routes with no ledger cell and no evidence**
(`zero_one_beta_sigma_q1_profile_restricted` never constrains `random$mu$n_re`). **Mandatory gate before
merge:** dump `profile_targets()` across the whole test suite pre- and post-edit and diff
`profile_ready`. Anything flipping TRUE outside the 14 gets re-fenced or accepted in writing.

This is the **first `R/` source change of the whole programme** — it pulls in `document()`,
`man/profile_targets.Rd`, nine test call sites, first-ever `se=TRUE` tests, NEWS for exactly 14 routes,
and a local `--as-cran`.

### Not reachable without new method or a policy decision
- **16 q12** — a policy fence, *not* a capability limit. `mc-0124` (a q6 sibling) is already
  `interval_feasible`. Lifting it is Shinichi's call, and they become candidates on the same footing.
- **3 estimator holds** (`mc-0182`, `mc-0183`, `mc-0261`) — REML *marginalizes* the mean fixed effects,
  so there is no direct target to profile. Method design, not fixture work.
- **4 diagnosed STOPs** — `mc-0310`, `mc-0289`, `mc-0292`, `mc-0423`. See below.

## The diagnosed STOPs — do not re-run blind

- **`mc-0289` + `mc-0292`** (both gaussian **spatial × sigma**): failed in **two independent lanes, two
  different designs, same provider×dpar**. Treat spatial-on-sigma as a diagnosed fragility, not a fixture
  accident. `mc-0292`'s five estimates average 0.626 against truth 0.7 — 4/5 below — and two upper
  endpoints sit within 0.012 of truth.
- **`mc-0310`** (relmat mu q1): κ = 3.43 rules out conditioning; genuine ML sampling variance at M=16.
  Untried next rung: M=32.
- **`mc-0423`** (nbinom2 sigma animal): two mechanisms ruled out (drawn-component correlation −0.142 at
  the failing seed; pedigree κ = 66.7). A third — the NB2 dispersion/SD confound — was later identified
  but not yet converted into a passing design.

## Known DGP failure mechanisms (check before inventing new ones)

1. **Ill-conditioned structure.** `ape::rcoal()` coalescent trees hit κ = 98,563, and **enlarging
   `n_tip` made it worse** (up to 540,883) — near-tip coalescent events pile into near-duplicate pairs.
   Grafen branch lengths: κ = 183.
2. **Finite-sample correlation between independently drawn components** — |cor| 0.457 at n_id=40 created
   an alternate local optimum mid-profile-sweep. n_id → 80 gave 0.135.
3. **NB2 dispersion/SD confounding** — `cor(sigma_hat, sd_hat) = −0.74`.
4. **Plain small-group-count recovery failure** — fixed by raising group counts, not changing structure.
5. **Signal-free fixture** — the manifest prescribed mean-only DGPs for scale-side targets, making the
   true value exactly zero.

## Open defects worth fixing

- **`tests/testthat/test-reml-ordinary-sigma.R:3-4,105-108`** contains stale comments claiming the cell
  "stays gated" / "stays rejected", contradicted by the source since July (`1b3e852bb`).
- **Receipt `source_sha` vs ledger `ARC*_SOURCE_SHA` diverge** — receipts record the git HEAD at run
  time, the ledger records one anchor. Flagged independently by three agents. Nothing is lost (raw
  receipts keep the true SHA) but the convention should be reconciled.
- **Groups 2 and 3 disagreed on the shape of the same ledger rows** — labelled `provider(1 | p | group)`
  vs unlabelled auto-linked spelling. `mc-0291`/`mc-0292` may be one block or two. **A single toy fit
  comparing `profile_targets()` on both spellings would settle it**, and it decides whether those
  ledger pairs share an evidence base.
- **The Arc 0 manifest is defective in four distinct ways** — signal-free fixtures; a cell id absent
  from the fixture registry; a named coefficient absent from the cited model; fixtures that do not
  exist (`tools/b2-q6-q12-admission-contracts.R` is cited but is not in the tree). **Its STOP verdicts
  are exactly as suspect as its fixture prescriptions were** — that insight is what produced twelve of
  today's fifteen promotions. Recommended fix: every candidate row gains a *"true value of this exact
  target under the prescribed fixture"* column.

## Operational notes

- Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file …`
- `capability_ledger.py --write` emits **30 outputs and not all live under
  `docs/dev-log/dashboard/`** — notably `vignettes/includes/capability-ledger-family-map.md`. **Stage
  whatever `--write` touches, never a fixed directory list.** That broke CI once.
- Campaign drivers must use `^` as field delimiter, **never `|`** — random-effect targets embed a
  literal `|`, which silently shifts every field. It killed three runs.
- Totoro: `R CMD INSTALL` **ignores `R_LIBS_USER`**; pass `-l <lib>`. The package persists in
  `~/R/lib`; recreating the workspace is one `git worktree add` plus a few `scp`s.
- Structured markers need their tree/matrix as a **bare local symbol**.
- After every batch, adversarially flip one extra frozen cell and confirm `--check` fails.
