# Pre-registration — 135-trace Prong B interval campaign

**Committed BEFORE any campaign fit.** Written 2026-08-05 against
`origin/main = 56449fd64` (handover recorded tip `b8d738fb4`; delta is PR #929
merging this lane's handover only).
Platform: Cursor, worktree `~/local-scratch/worktrees/drmTMB-135trace`, branch
`cursor/135-trace-campaign`. Foreign lane: codex PR **#858** (Lane B E0,
draft) — no file overlap with this campaign; preserved, not edited.

Authority: `docs/dev-log/handover/2026-08-05-cursor-handover.md` §7.1 ·
`scratchpad/2026-08-03-prong-b-scoping-decision.md` §4 · ten-clause contract.

## 1. Aim

Promote the 14 Prong B Tier-1 cells from `point_fit_recovery` →
`interval_feasible` **if and only if** each cell's retained profile evidence
clears the ten-clause contract below. Target census move: **182 → 196**
`interval_feasible` and `FROZEN_CENSUS_POINT_FIT_RECOVERY` **59 → 45**.

This campaign claims **interval existence + truth-bracketing at the tested
design**. It does **not** claim coverage, calibration, inference-ready,
supported, or CRAN-readiness.

## 2. Cells, targets, truths

| Group | Cells | Targets / cell | Truth (parameter scale) |
|---|---|---|---|
| zob `sigma` ordinary | `mc-0568`, `mc-0576` | 1 SD | **0.45** |
| zob `sigma` structured | `mc-0593`–`mc-0597` | 1 SD | **0.45** |
| count `mu` labelled q2 | `mc-0418`, `mc-0436`, `mc-0446`, `mc-0450`, `mc-0454` | 2 SD + 1 `cor` | SD truths from each cell's recovery DGP; cor truth **0.50** (spike) |
| count `sigma` phylo_interaction | `mc-0425`, `mc-0653` | 1 SD | **0.60** |

Exact target strings and DGP constructors are taken from the recovery runners
named in the scoping memo's turnkey step 3 (Lane C recovery scripts + zob
helpers). The campaign runner must pin them in a cell registry and refuse a
CLI typo that would run a different contract than the named cell.

**Structured-sigma disclosure (locked owner decision, Arc 7b):** for
`mc-0593`–`mc-0597` and `mc-0425`/`mc-0653`, any eventual `claim_boundary`
must name the documented ML sigma-axis low bias and state that REML is
unavailable for these families. Promotion without that text is forbidden.

## 3. Design (fits and seeds)

- **One `se = TRUE` fit per `(cell, seed)`** — same object feeds the point-fit
  gate and `stats::profile()`. Gate and campaign **cannot** use different
  seed families (contract clause 1 / risk R6).
- Seeds: **5 per cell**; **8 for each `cor:mu:...` target** (extra seeds on
  the five q2 cells only for the correlation target → ~135 profile runs).
- Seed integers: `20260805 + 1000000 * cell_index + seed_index` (cell_index
  1..14 in the table order above; seed_index 1..5 or 1..8). Stays inside R's
  32-bit `set.seed()` range (the first draft `202608051000+…` overflowed).
  Recorded in every receipt. Do not reuse recovery-campaign seeds as the
  primary family.
- Profile engine for **recorded endpoints**: grid engine
  (`stats::profile()` → `TMB::tmbprofile()`), one call per target.
  Endpoint-engine (`profile_engine = "endpoint"`) is an independent
  cross-check only; disagreement beyond ~1e-2 is a stop, not a silent prefer.

## 4. Decision rule — fixed now, before any data

For each cell, after all retained seeds:

**PROMOTE** that cell to `interval_feasible` only if **all ten contract
clauses pass for every retained seed** (and Fisher location review signs
the cell). Mean statistics never promote. **4/5 truth-bracketing is a
BLOCK**, not an 80% pass.

**WITHHOLD** the cell (stay `point_fit_recovery`) if any clause fails on any
retained seed. Root-cause before regenerating data (scoping §6.5).

**Census edits** (`cells.tsv` / evidence / `FROZEN_CENSUS_POINT_FIT_RECOVERY`
59→45) happen **only at actual promotion**, never before.

## 5. Ten-clause evidence contract (any single failure blocks the cell)

1. Point-fit gate on the same seed family: mean relative error ≤ 0.35 **and**
   no single seed > 0.35.
2. ≥5 seeds (≥8 for correlation targets).
3. `conf_status == "profile"`; lower/estimate/upper finite; `lower < estimate < upper`.
4. `convergence == 0`; `pdHess == TRUE`.
5. Not boundary- or clamp-limited: `profile.boundary == FALSE`, message ok,
   no contact with the `[-12, 12]` log-scale clamp band.
6. Trace spans both sides and crosses the LR threshold (1.9207 on the
   deviance/2 scale) on **both** sides; unimodal under a 1e-6 monotonicity
   tolerance.
7. Endpoints from **one** `stats::profile()` call per target.
8. **Every** seed's interval contains the true value (truth gate /
   `brackets_truth`).
9. Profiled variance-component truth is non-zero (all Tier-1 DGPs 0.45–0.60).
10. Independent Fisher location review (shape ≠ location).

## 6. Pre-registered falsifiers and guard defects

**(a) Clamp-limited hard-code (known defective guard).** Every arc1/arc2
runner currently writes `clamp_limited = FALSE` unconditionally
(`tools/run-arc2-profile-feasibility.R` and siblings). A green
`clamp_limited == FALSE` from those runners is **not evidence**. This
campaign's runner **must compute** clamp contact from the profile message /
parameter path and record the real boolean. A receipt that hard-codes
`FALSE` fails this preregistration.

**(b) Missing unimodality / two-sided LR check.** No tool under `tools/`
currently enforces clause 6. The campaign runner (or a sibling checker
invoked before promotion) **must implement** both-sides LR crossing and
unimodality; promoting on shape-only reconcilers alone is forbidden.

**(c) Truth gate.** Run `tools/profile_truth_gate.py` (and the wired
`arc2_profile_reconcile` truth path) on every cell before promotion.
Fail-closed on missing truth.

**(d) Early-stop providers (risk R3).** Seed 1 of each structured provider:
if relative error > 0.25 or profile wall-time >5× the phylo spike, stop that
provider and pilot separately — do not burn all 5 seeds.

**(e) Correlation early warning (risk R2).** Any `cor` seed with lower bound
< −0.3, width > 0.85, or `profile.boundary == TRUE` is a flagged seed;
tree condition number > ~10⁴ before fit → conditioning artefact, fix the
tree generator, do not redesign the DGP until green.

## 7. What this does NOT do

- No `coi` fence reopen (`mc-0570`, `mc-0578`, `mc-0613`, `mc-0614`, `mc-0617`).
- No Tier-2 `zoi` / structured-`mu` fences.
- No 7-method coverage-mapping grid.
- No `predict()` scale-axis fix; no CI guard/check split; no B4-CI
  `SOURCE_COMMIT`; no mc-0282 runner-contract change (PROTECTED).
- No GitHub Actions compute or Actions artifacts (D-50).
- No assumption that D-117 is discharged, that PR #926 should be re-scored,
  or that a REML design doc is authorized — those are **owner calls**
  (handover §7.2), surfaced separately.

## 8. Compute

- **Smoke first:** 1 cell × 1 seed (prefer `mc-0568`), confirm non-empty
  in-range receipt with real `clamp_limited`, both-sides LR fields, and
  `brackets_truth`, before any grid.
- Full slate: Totoro, ≤100 cores (handover allows ≤150; scoping memo ≤100 —
  use **≤100**), expect ≤30 min wall-clock.
- Results under
  `docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/`
  (local + repo dev-log; never Actions artifacts).

## 9. Promotion checklist (after review, not after green alone)

For each cell that clears §5–§6:

1. Fisher location sign-off recorded.
2. Structured-sigma `claim_boundary` text written where required.
3. Ledger + evidence rows + frozen census constant updated together.
4. NEWS claim-boundary text limited to the promoted routes.
5. Adversarial: flip one extra frozen cell and confirm `--check` fails.
