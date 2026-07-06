# Next arc — intervals/coverage + structured-covariance families (DRAFT for review)

## Context / why this arc

`104/104` is a **fit/recovery** surface: every catch-all cell has one recovered
representative. The next milestone is **depth** — give cells honest *intervals* and
*coverage*, and admit the harder *structured-covariance* families that were kept
`planned`. The board already re-partitions along exactly this axis (the v1 release
ledger's tiering), which gives a clean three-track decomposition.

## The landscape (grounded in the board + engine)

**Interval/coverage state (104 cells):** interval_status = 8 `inference_ready` · 4
`interval_feasible` · 18 `diagnostic_only` · 37 `planned` · 37 `unsupported`;
coverage_status = 8 `inference_ready` · 94 `planned` · 2 `unsupported`. `supported`
authority = **0/104** (never cleared).

**The "done" template — 8 Gaussian anchors** (phylo/spatial/animal/relmat × {q1
mu-intercept, q1 sigma-slope, q2 mu-labelled-slope}). They reached `inference_ready` via:
- **Interval routes** (`R/profile.R`): Wald (default) + a simulation-calibrated
  small-sample correction (design 219 — width `qt(df=g-1)` + centre shift `log(g/(g-1))`,
  **location-axis, structured-block only**; promoted exactly the 2 q2 mu-slope cells);
  a scalar **endpoint-profile** solver for direct SD/scale/correlation targets; and a
  parametric **bootstrap** (percentile).
- **Coverage grids**: SR475 (≈475 reps) run as **DRAC Nibi SLURM array jobs** (sharded by
  `--shard`, `/project/def-snakagaw/…`). Gate = MCSE ≤ 0.01 + pdHess/finite ≥ 0.95 +
  miss-balance, then **Fisher/Rose/Grace sign-off**. ADEMP contracts in design 217.

**The deep blockers (why `supported` is 0, and why non-Gaussian is hard):**
1. **Miss-asymmetry** — a ~6:1 right-tail miss at SD≈0.9. This is a **finite-sample
   *skew*** of the SD estimator × effective-df, *not* a sim-size or code defect. The fix is
   a **skew-aware interval** or a **REML route** — more replicates won't close it.
2. **REML is not a drop-in fix** — drmTMB's native REML only marginalizes *location* fixed
   effects, not the sigma/rho submodel where the bias lives. DRM.jl (Julia) currently has
   the only relevant q4 correction.
3. **High-q Hessian wall** — q4/q6/q8 free-correlation manifolds are `pdHess=FALSE` on hard
   seeds (design 220); a genuine identifiability wall, not engineering.
4. **Non-Gaussian has NO interval method yet** — 18 count structured cells fit fine
   (pdHess ~99%) but there is *no* interval-construction route for count-family structured
   SDs. This is the real architectural headline of the arc.

## C++ capability today (engine scout)

The q-generic labelled-covariance kernel (`drm_separable_cov_logdet_quad` +
`drm_qgt2_corr_matrix`, `src/drmTMB.cpp:159-246`) is called from **only** model_type 1
(gaussian) and 2 (biv_gaussian) — **zero non-Gaussian branches**. But two things make the
non-count extension cheaper than expected:
- The **shared R assembler** `build_structured_mu_structure()` (family-agnostic) already
  gives any family the slope column + GMRF precision + node alignment for free.
- The **non-count families (Gamma/Student/Beta) already route the structured field to their
  sigma/shape/nu `dpar` in C++** for the independent case — so "structured non-count
  sigma/shape" is largely an R-validator relaxation, *not* new C++.
- **Count** dispersion (NB2 `log_sigma`) has **zero C++ hook** — genuinely new C++.
- **ZI** already routes a structured field to `eta_zi` (model_type 8), gated to `spatial()`
  only by the R validator — extending to phylo/animal/relmat is mostly R-side.

## Three tracks

### Track A — Gaussian interval/coverage *extension* (P2, ~59 cells, NO new C++)
Extend the 8-anchor template to the missing Gaussian companions (sigma-side intercepts,
spatial/animal q2 labelled-slope, q1 mu one-slope). Reuse the SR475 runners + bias-t
correction + the reviewer gate wholesale. Two sub-tiers:
- **A1 low-q (~23 cells)** — same code paths, uncalibrated intervals; the tractable bulk.
- **A2 high-q (q4/q6/q8/q12, ~36 cells)** — blocked on the Hessian/geometry wall (design
  220); a hard, lower-priority sub-track (reduced-rank / identifiability research).

### Track B — Non-Gaussian intervals/coverage (P3, 18 count + 2 recovery) — THE HEADLINE
Build the **first count-family structured-SD interval method** (none exists), then
coverage-grid the count structured cells + row 87's non-count cells. This is where the arc
delivers the most *new* honest inference, and it's more method-research than C++.

### Track C — New structured-covariance *capability* (P3, ~17 `_rejected` cells) — the C++ families
Sized (S/M/L):

| Family group | Size | Why |
| --- | --- | --- |
| **ZI structured** (spatial → phylo/animal/relmat) | **S** | C++ already routes to `eta_zi`; R-validator relaxation, mirrors row 87 |
| **Simultaneous providers** beyond the one cell (additive) | **S–M** | additive-sum block already written twice; per-family duplication |
| **Same-family q=2 labelled cross-term** (Gamma/Student/Beta mu×shape) | **M** | port model_type-2's closed-form q=2 block per family; avoids the q>2 wall |
| **Labelled non-count covariance** (q2/q4) | **M** | port the q-generic kernel into ~4–6 branches; mechanical, no new math |
| **Count `sigma`/shape structured** | **L** | NB2 dispersion has no C++ hook — new dpar code + routing |
| **Multiple structured slopes** (q6/q12) non-count | **L** | inherits the q>2 Hessian wall on top of new C++ |

## Recommended sequencing

- **Phase 1 — quick wins (low risk, mostly R-side):** ZI structured extension (**S**);
  same-family q=2 non-count labelled cross-term (**M**, the smallest genuine C++ slice that
  proves the non-count covariance path); simultaneous-provider extension (**S–M**). In
  parallel, **scope the count-interval method** (Track B research).
- **Phase 2 — the headline:** ship the count-family structured-SD interval method → coverage
  grids for the 18 count cells + row 87; labelled non-count covariance (q2/q4).
- **Phase 3 — hard / research:** count `sigma`/shape structured (**L**); the q6/q12 +
  high-q Hessian wall (**L**, design 220); and the **`supported` sub-project** — a
  skew-aware interval (or a DRM.jl/REML route) for the miss-asymmetry that currently caps
  everything at `inference_ready`.

## Cross-cutting

- **Compute:** coverage grids run on **DRAC Nibi** (SLURM array, SR475). Claude cannot
  ssh/scp to clusters — I produce self-contained deploy runbooks; you (or Codex) run them.
  Local Mac / Totoro for smoke + pilot.
- **Gate:** every promotion = 4-lens (Curie/Noether/Fisher/Rose) + Fisher/Rose/Grace
  sign-off + an ADEMP contract (design 217), row-local (no propagation).
- **Honesty:** `supported` stays 0 until the skew-aware/REML sub-project lands; everything
  else is `inference_ready` at most.

## Decisions for you (before I turn this into a scoped ultra-plan / design doc)

1. **First track** — Phase-1 quick wins first (ZI + same-family q2, mostly R-side), or go
   straight at the headline (Track B count-interval method)?
2. **`supported` ambition** — is closing the miss-asymmetry (skew-aware interval / a DRM.jl
   REML route) in scope for this arc, or explicitly deferred (arc caps at `inference_ready`)?
3. **Breadth vs depth** — one exemplar per track (like the Q-Series' one-representative
   discipline), or full family coverage within a track?
4. **Compute** — should I write the DRAC runbooks assuming Nibi, or has the cluster access
   changed?
