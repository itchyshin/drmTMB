# M3 determination: the q8 all-four one-slope cell is already admitted — 102/104 needs a decision

Meta: 2026-07-05 · Claude (Shannon) · branch `drmtmb/fix-family-conventions` (M2
merged to main at e6f87ca8) · M3 of the Q-Series 104/104 arc.

## The finding that reshapes M3

M3 was scoped as "admit the four q8 all-four one-slope rows on recovery → 102/104."
**That premise does not hold.** The concrete q8 all-four one-slope cell —
`(1 + x | p | id)` on mu1/mu2/sigma1/sigma2, 8 SD + 28 correlations, the exact
cell M1 recovered — is **already admitted for all four providers**:

- `qseries_{phylo,spatial,animal,relmat}_q4_all_four_one_slope_planned`:
  `fit_status = point_fit`, `extractor_ready`, `bridge_status = fixture_parity`,
  `interval_status = diagnostic_only`. Already counted in the 98/104.
- These sit in the **`q8_stability_blocked`** closure bucket: "q8 exact/shared-label
  rows have stability or Hessian geometry blockers; run stability/geometry work
  before inference grids." That is exactly M1's `pdHess=FALSE` weak-identification:
  fit + recovery are done; the **inference tier (intervals/coverage) is blocked**.

The four rows that remain `planned` — `qseries_{provider}_q8_planned` — are **not**
that cell. Their `formula_cell` is a description, not a formula ("*broader
{provider} q8 variants beyond the exact shared-label all-four one-slope cell*"),
their `next_gate` says "**design** broader q8 cells," and design/59 + doc-218 list
"broader q8 support / multiple slopes / slope correlations / q8 coverage" as
**unpromoted future work**. They are undefined placeholders.

So the ultra-plan/handover **conflated** two things: the 8-SD-28-corr all-four
one-slope cell (done) versus the vague "broader q8" placeholders (undefined).

## What M3 honestly delivers (this session)

- **Cross-provider q8 recovery** (`docs/dev-log/simulation-artifacts/2026-07-05-m3-q8-recovery/`):
  M1 recovered q8 only for phylo; the exact cell for spatial/animal/relmat rested
  on fixture parity. This session runs native Santi-scale recovery for all four,
  confirming the exact q8 block recovers its known Σ AND characterizing pdHess
  cross-provider. RESULTS: _[to fill from 03-recovery-results.tsv]_
  - phylo n=128: conv=1, **pdHess=FALSE**, rmse 0.179, max|ρ|=0.951 (no cap-sat).
  - _spatial/animal/relmat at n=256: [fill]_
- This is **recovery evidence only** — it does not move the count. The exact q8
  cells are already point_fit; the recovery corroborates + documents the weak-ID.

## Why 102/104 is not honestly reachable as a recovery-gate

The only Gaussian rows left outside the practical surface are the four
`*_q8_planned` placeholders. Moving them off `planned` requires one of:

1. **Define a concrete "broader q8" cell** (e.g. two-slope all-four → q12, or a
   block-diagonal q8 layout, or multiple/predictor-dependent slopes) and
   build + recover it. This is design + engine work, not a recovery-gate.
2. **The reduced-rank factor-analytic estimator** (glmmTMB `rr()` / Meyer-WOMBAT)
   — the real q8 frontier M1 identified. It gets the *already-admitted* exact q8
   cell to `pdHess=TRUE`, unblocking its intervals/coverage (moving it from
   `q8_stability_blocked` toward inference-ready). A genuine multi-day C++/parser/
   test arc.
3. **Reject/reclassify** the placeholders as documented out-of-v1 design rows
   (a rejection, not an admission — does not add to the practical surface).

Pretend-admitting the undefined placeholders to `point_fit` would be exactly the
claim inflation the arc's Rose gate exists to prevent.

## Recommendation

**Take option 2 — commission the reduced-rank factor-analytic q8 arc.** It is the
genuinely valuable q8 work: it unblocks the inference tier of the cell that is
*already recovering*, rather than inventing placeholder "broader variants" to tick
a number. It moves the four exact q8 cells from `q8_stability_blocked`
(point_fit, diagnostic intervals) toward `inference_ready` — the honest headline.
This is a scoped methods arc (its own plan), not a session finish.

If instead you want a countable 102/104 now, tell me the concrete "broader q8"
formula for the `*_q8_planned` rows (option 1) and I will build + recover it like q6.

## State

- Mission Control: **98/104 / 8/104 / 0/104 / 6/104** (unchanged this session).
- The M3 q8 recovery evidence is banked; no dashboard/claim moved (the exact cell
  is already admitted; the placeholders are honestly left planned pending your call).
