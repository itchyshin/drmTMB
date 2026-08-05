---
name: 135-trace campaign
overview: Outcome-first arc to move up to 14 Prong B cells from point_fit_recovery to interval_feasible (182→196) via a grid-engine campaign runner, Totoro ≤100 cores, ten-clause review, and promotion only of cells that clear. Smoke already PASS; Arc 0 is mostly done.
todos:
  - id: s1-runner
    content: "S1: Build grid-engine 14-cell campaign runner + Totoro driver (real clamp/LR/truth fields)"
    status: in_progress
  - id: s2-c1-smoke
    content: "S2: C1 re-smoke mc-0568 with profile_engine=grid; gate Totoro"
    status: pending
  - id: s3-totoro
    content: "S3: Totoro ≤100-core grid after explicit go; land receipts"
    status: pending
  - id: s4-review
    content: "S4: Ten-clause + Fisher review → PASS/WITHHOLD per cell"
    status: pending
  - id: s5-promote
    content: "S5: Promote PASSes only (ledger, FROZEN 59→45, NEWS, claim_boundary)"
    status: pending
  - id: verify-close
    content: Mechanical verify + Rose claim check + Melissa plan-actual + after-task
    status: pending
isProject: false
---

# ARC CARD + ULTRA PLAN — 135-trace Prong B campaign

```text
GOAL
PLATFORM: Cursor (this session plans; after G0 approval hand to /goal for execution — same worktree).
DELIVERABLE: Up to 14 cells promoted point_fit_recovery → interval_feasible with retained
receipts, truth-gate pass, ten-clause review, and structured-sigma claim_boundary text where required.
HEADLINE: Build the grid-engine campaign runner (fixing the endpoint-engine smoke gap), run Totoro
≤100 cores, review all ~135 traces, promote only cells that clear.
IN PARALLEL: none for compute (embarrassingly parallel inside Totoro job); lane #858 preserved unread.
DEFER (fenced): D-117 discharge; PR #926 re-score; REML design doc; coi/Tier-2 fences; 7-method
coverage grid; predict() scale-axis; CI split; B4-CI; mc-0282.
DISCIPLINE: preregistration already written; smoke-first already green for mc-0568; never hard-code
clamp_limited=FALSE; recorded endpoints from grid engine only; 4/5 truth-bracketing = BLOCK;
Totoro never Actions (D-50); FROZEN_CENSUS 59→45 only at actual promotion.
```

**Default end-state (override if you want receipts-only):** promote every cell that clears the ten-clause contract in this arc. That is the only path that can move the census metric.

---

## ARC CARD — 135-trace Prong B

**Mode:** outcome-first (with measured compute ceiling)  
**Requested outcome:** up to **+14** `interval_feasible` cells (182→196; frozen PFR 59→45)  
**Mechanism authority:** worktree `~/local-scratch/worktrees/drmTMB-135trace` · branch `cursor/135-trace-campaign` · Totoro ≤100 cores · grid-engine profiles · truth gate · ledger promotion of cleared cells only · **exclude** primary-checkout debris · **exclude** #858 / mesh / missing-data  
**Recommended arc:** **6–10 h wall-clock** (range; not a pad)  
**Time contract:** outcome-first / no hard time-box; Totoro compute ≤30 min once launched  
**Estimate confidence:** **measured** for compute (scoping memo + mc-0568 smoke ~30 s profile after load); **inferred** for review (135 traces)  
**Arc 0 outcome:** DONE — preregistration + mc-0568 smoke PASS (engine=endpoint catch recorded)  
**State transition:** `point_fit_recovery` → `interval_feasible` for cleared subset of the 14  
**Executable rung and evidence:** Totoro retained receipts + truth gate + Fisher location review + ledger/evidence edits

### Outcome cohort ladder

| Cohort | Candidates | Shared mechanism | Required action | Acceptance evidence | Expected yield / stop |
| --- | ---: | --- | --- | --- | --- |
| C0 smoke | 1 (`mc-0568`) | local fit+profile | already run | SMOKE_PASS + receipt | **DONE** |
| C1 grid smoke | 1 (`mc-0568`) | same DGP, **grid** engine | force `profile_engine=grid` | brackets + real clamp/LR fields | fail → fix runner before Totoro |
| C2 ordinary zob | 2 | ordinary sigma RE | Totoro 5 seeds | ten-clause + truth gate | best 2 / credible 1–2 / fail→WITHHOLD |
| C3 structured zob σ | 5 | structured σ ML | Totoro 5 seeds + claim_boundary text | ten-clause + bias disclosure | best 5 / credible 3–5; R3 early-stop |
| C4 count mu q2 | 5 | labelled q2 (2 SD + cor) | Totoro 5 seeds; **8 for cor** | ten-clause; R2 cor warnings | best 5 / credible 2–4; cor often WITHHOLD |
| C5 count σ interaction | 2 | phylo_interaction σ | Totoro 5 seeds | ten-clause + bias disclosure | best 2 / credible 1–2 |
| **Goal** | **14** | | | | **credible ~8–12 promoted; failures stay PFR** |

### Budget (Arc 0 already spent ~45–60 min)

| Segment | Minutes | Output / stop |
| --- | ---: | --- |
| Orient (spent) | 45 | worktree, classify, prereg, smoke |
| Core — runner + grid smoke | 90–120 | `tools/run-135-trace-campaign.R` (+ Totoro driver); C1 PASS |
| Core — Totoro grid | 30–45 | ~135 receipts under artifact dir |
| Verify — trace review | 180–240 | per-cell PASS/WITHHOLD + Fisher notes |
| Repair reserve | 60–90 | provider early-stops, cor failures, clamp/LR bugs |
| Closeout — promote + PR | 60–90 | ledger, FROZEN 59→45, NEWS, after-task, PR |
| **Total remaining** | **~7–10 h** | |

**In scope:** runner (grid + real clamp/LR), Totoro campaign, review, promote cleared cells.  
**Not in this arc:** owner D-117/#926/REML-doc decisions; Tier-2/zoi/coi; Actions compute.  
**Evidence used:** [PREREGISTRATION.md](docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/PREREGISTRATION.md); smoke PASS; [scoping §4](scratchpad/2026-08-03-prong-b-scoping-decision.md); Arc 2 runner pattern in [tools/run-arc2-profile-feasibility.R](tools/run-arc2-profile-feasibility.R); DGP sources in fence fixtures / Lane C recovery scripts.  
**Risk branch:** If C1 grid smoke fails by minute 30 of runner work, stop Totoro and repair engine wiring. If any provider seed-1 rel_err >0.25, pilot that provider alone (R3).

**Done when:** every one of the 14 has a retained PASS or WITHHOLD with reasons; every PASS is promoted with claim_boundary (structured-σ disclosure where required); census/frozen constant updated only for promotions; after-task + plan-actual written.  
**First action after G0:** implement grid-engine path in campaign runner and re-smoke mc-0568 with `profile_engine=grid`.

### Actuals (fill at close)
*(empty until execution)*

---

## Phase 0.25 sweep receipt

| Surface | Evidence | Finding | Call |
| --- | --- | --- | --- |
| repo git | `git status -sb`; `branch_drift_check.sh` → 0 ahead/0 behind `origin/main` | worktree clean except this lane’s uncommitted prereg/smoke/lane-split; tip `56449fd64` | **resume** `cursor/135-trace-campaign` |
| twin/sister | gllvmTMB not owning these 14 cells; #858 foreign | no co-opt for this slate | n/a |
| brain | `search_notes` 135-trace/Prong B; `grep DECISIONS` D-117 | campaign **UNFENCED** 2026-08-05; D-117 **not discharged** (PASS withheld) | reuse unfence; **do not** reopen D-117 in this arc |
| log/journal | `grep AGENT_LOG/DECISIONS/journal` | Prong B stack landed 2026-08-04; campaign next | build-the-gap = **runner + Totoro + review + promote** |
| **Verdict** | | | **Gap:** full 14-cell grid-engine campaign + promotion. Reuse Arc2 receipt shape, Lane C DGPs, existing truth gate. |

Foreign lane: PR **#858** draft — preserve; no overlap.

---

## Phase 0.4 — questions for you (1–2)

**Already defaulted:** promote cleared cells in this arc (not receipts-only). Say if you want receipts-only instead.

**Still needed before Totoro launch (execution trigger):** explicit **Totoro go** after C1 grid smoke is green. Unfence authorizes the campaign; launching ≤100 cores still wants a spoken go under D-50 habit.

Owner decisions (D-117 / #926 / REML design doc) stay **surfaced, not assumed** — out of this arc.

---

## TEAM RAISED (compact)

- **Fisher** — clause 8 + Fisher location review are load-bearing; endpoint-only smoke is not contract-complete until grid C1 passes. · Recommend: C1 gate before Totoro.  
- **Rose** — do not promote on mean stats; structured-σ cells need claim_boundary bias text; do not touch #858.  
- **Gauss** — clamp_limited must be computed; never copy arc1/arc2 `clamp_limited=FALSE`.  
- **Ada** — outcome-first; Arc 0 done; remaining work is runner → Totoro → review → promote; after G0 hand to `/goal`.

---

## ULTRA PLAN — slice table (post-G0 via `/goal`)

| Slice | Member | Model+effort | Bar | Time | Detail | Dep |
| --- | --- | --- | --- | --- | --- | --- |
| RECON (done) | Ada | — | Cursor Models | done | classify, prereg, smoke | — |
| S1 runner+registry | Gauss/build | Composer or Sonnet med | Cursor Models | 90–120m | New `tools/run-135-trace-campaign.R` (+ bash Totoro driver): 14-cell registry from Lane C / fence DGPs; one `se=TRUE` fit per (cell,seed); **grid** endpoints; compute clamp_limited + both-sides LR; emit Arc2-shaped receipts + `true_value`/`brackets_truth` | — |
| S2 C1 grid smoke | Curie | Composer | Cursor Models | 20–30m | Re-smoke mc-0568 with grid; abort Totoro on fail | S1 |
| S3 Totoro grid | Ada+Curie | Cursor parent + SSH | Cursor / hand HPC | 30–45m | ≤100 cores; artifact dir under `simulation-artifacts/2026-08-05-135-trace-campaign/` | S2 + Totoro go |
| S4 review panel | Fisher+Rose | Other Models (judgment) | Other Models | 180–240m | Ten-clause + location review per cell; PASS/WITHHOLD table | S3 |
| S5 promote | Ada+Emmy | Sonnet/Composer | Cursor Models | 60–90m | Ledger/evidence/NEWS/`FROZEN` only for PASSes; structured-σ claim_boundary | S4 |
| MECHANICAL-VERIFY | Luna/Haiku | Composer | Cursor Models | 20m | `capability_ledger.py --check`; adversarial frozen flip; fence integrity | S5 |
| VERIFY (judgment) | Rose | Other Models | Other Models | 30m | D-43-style claim vs evidence on promotions | S5 |
| RECONCILE | Melissa | Sonnet med | Other Models | 20m | `docs/dev-log/plan-actual/2026-08-05-135-trace-campaign.md` | close |

**FAN-OUT BUDGET:** checkpoint=`135-trace` · children ≤4 · scout 0–1 · build 2–3 · ceiling 0–1 (Fisher/Rose review)  
**LUNA SUITABILITY:** yes — mechanical verify + receipt inventory  
**ULTRA EFFORT:** no  
**CONTEXT BRAKE:** after S3 or S4 milestone → prefer `/goal` fresh task if context heavy  
**D-43 PANEL:** fire once before any public promotion claim

### Architecture (execution)

```mermaid
flowchart LR
  prereg[PREREGISTRATION]
  runner[CampaignRunner_grid]
  c1[C1_grid_smoke]
  totoro[Totoro_le_100]
  review[TenClause_Fisher]
  promo[Ledger_promote]
  prereg --> runner --> c1 --> totoro --> review --> promo
```

### Key implementation pins

- Work only in [~/local-scratch/worktrees/drmTMB-135trace](~/local-scratch/worktrees/drmTMB-135trace); never stage primary-checkout debris.
- Reuse DGP constructors from [tools/profile-fence-fixtures.R](tools/profile-fence-fixtures.R) / [tools/run-lane-c-c17c1-c14-model15-compatibility.R](tools/run-lane-c-c17c1-c14-model15-compatibility.R) and Lane C recovery scripts named in scoping turnkey step 3.
- Receipt contract: extend Arc2 fields with **computed** `clamp_limited`, LR both-sides, unimodality, `true_value`, `brackets_truth`; wire [tools/profile_truth_gate.py](tools/profile_truth_gate.py).
- Seeds: `20260805 + 1000000 * cell_index + seed_index` (32-bit safe).
- Delimiter `^` in Totoro driver (never `|`).

---

## After G0 approval

Do **not** continue Phase 3 in this planning chat. Paste a `/goal` prompt:

```text
/goal Execute the approved 135-trace plan in ~/local-scratch/worktrees/drmTMB-135trace on branch cursor/135-trace-campaign. Start at S1 (grid-engine campaign runner), then C1 grid smoke of mc-0568. STOP for Totoro go before S3. Promote only cells that clear the preregistered ten-clause contract. Do not touch primary-checkout debris or PR #858.
```

**HAND TO ULTRA PLAN / GOAL:** outcome-first 135-trace campaign · ~7–10 h remaining · promote cleared cells · Totoro after C1 · Cursor platform.