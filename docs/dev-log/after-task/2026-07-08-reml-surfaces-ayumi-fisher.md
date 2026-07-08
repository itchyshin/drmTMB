# After-task — REML downstream surfaces, Ayumi's ceiling, the Fisher audit (2026-07-08)

Meta: 2026-07-08 · Claude (Opus 4.8) · branch `drmtmb/biv-scale-side-reml` → `main` (FF, pushed).
Tag `v0.2.0.9001` cut mid-session for Ayumi Mizuno.

## 1. Goal

Take over the "crosses to ticks" arc (turn ✗ → ✓ / `inference_ready` on the structured-RE q-series).
En route, a live user report (Ayumi, issue #3) redirected substantial effort into REML's *downstream
surfaces* and a memory ceiling. The session became: verify the inherited branch, attribute the
under-coverage, fix Ayumi's blockers, and — before promoting anything — audit whether the promotion
gate actually binds.

## 2. Implemented

- **`drm_control(se_group_sd = FALSE)` default** + `se_report_covariance`, `se_skip_delta_method`
  pass-throughs. Per-group direct-SD `ADREPORT` is now opt-in; fixes Ayumi's 48 GB `sdreport()`
  ceiling at root (report vector 41,773 → ~13 at 10,440 tips). New `DATA_INTEGER(report_group_sd)`.
- **Narrowed the REML `missing =` gate** — fires only when the engine actually engages, not on the
  setting (`drm_reml_missing_engine_engages()`).
- **Guard reorder** in `parse_random_sigma_term()` so `sigma ~ (1 + x | p | id)` gets its specific
  rejection message.
- **`(REML × downstream-surface) conformance table + test`** (`estimator-surface-conformance.tsv`,
  `test-estimator-surface-conformance.R`): 36 declared cells, self-validating evidence citations,
  undeclared-cell + drifted-citation guards both negative-tested.
- **After-task §12 "Cross-Product Coverage"** added to `check-after-task.R` as a *gate* (requires the
  literal `does NOT cover`) and to `protocols/after-task.md`, in lockstep.
- **`tools/gate-inference-ready.R`** — Fisher's binding gate (P0–G4) computed from a replicate TSV.
- **F3**: corrected design 219's false "dispersion SDs already over-cover" premise to regime-dependent.
- **Tag `v0.2.0.9001`** cut + pushed; two comments posted to Ayumi's issue (`@`-mentioned).

## 3a. Decisions and Rejected Alternatives

- **Per-group SD ADREPORT opt-in (breaking default)** over a plain flag — REML's `vcov()` reads the
  joint ADREPORT covariance, so a flag alone left `vcov()` broken. Shinichi chose opt-in.
- **REML becomes the Gaussian inference default** (decided) — but Phase-1 evidence shrank its reach:
  REML is *phylo-only* for structured effects (36 of 58 Gaussian cells gated), and debiases only the
  variance component whose *fixed counterpart* is in the model.
- **Investigate the 8 ticks before any status change** (Shinichi) — not demote, not promote. Fisher's
  SOFT verdict is from a recomputation; a compute campaign at `n_miss ≥ 40` is the arbiter.
- **Fix F3 now** (Shinichi) — cheap, and it routes ~23 Track-A cells around the only correction.
- **Reverted the location-scale-scale C++** rather than ship a fit that failed its recovery gate.

## 4. Files Touched

Landed on `main`: `R/control.R`, `R/drmTMB.R`, `src/drmTMB.cpp`, `man/*.Rd`, `NEWS.md`,
`DESCRIPTION` (→ 0.2.0.9001), `.gitignore`, `tests/testthat/{test-control,test-comparators,test-phylo-utils,test-estimator-surface-conformance}.R`,
`docs/dev-log/dashboard/estimator-surface-conformance.tsv` (new), `tools/gate-inference-ready.R` (new),
`docs/design/{219,222}...md`, `docs/dev-log/after-task/2026-07-06-native-scale-side-reml.md`,
plus committed evidence scripts under `scratchpad/`. Hub: `~/shinichi-brain/tools/check-after-task.R`,
`protocols/after-task.md`, `memory/LEARNINGS.md`, the `Native scale-side REML` brain note.
Reverted (NOT landed): the location-scale-scale edits to `R/drmTMB.R`, `src/drmTMB.cpp`, `test-phylo-utils.R`.

## 5. Checks Run

Full unfiltered `devtools::test()` — FAIL 0 (found and fixed 5 that focused runs hid, then a 6th class
from the C++ change). `R CMD check --as-cran` — 0 errors, 0 warnings, 2 benign notes. 4 board
validators exit 0. `gate-inference-ready.R` verified against the g-sweep g8 (returns FAIL correctly).

## 6. Tests of the Tests

- Conformance guard: added a fake surface → "UNDECLARED cells" failure; flipped a rejection to `ok` →
  "expected admission" failure; both restored to green. Evidence-citation guard caught a *fifth* stale
  pointer on its first run, and a shifted citation → "line numbers have drifted".
- §12 gate: missing section → fail; section present but no "does NOT cover" → fail; complete → pass.
- Location-scale-scale: the recovery ladder (arms A/B/C) is what *rejected* the implementation.

## 7a. Issue Ledger

- Ayumi #3 — (1) `missing=` gate FIXED; (2) memory ceiling FIXED at root, verified to n=400 +
  extrapolated (she must confirm at 10,440); (3) location-scale-scale ATTEMPTED, failed, reverted,
  still rejected. Two comments + pinned tag delivered.
- Fisher SOFT verdict — the 8 `inference_ready` cells are unadjudicated; investigation queued.
- F3 — design 219 premise corrected.

## 8. Consistency Audit

Melissa (detail auditor) run before merge: caught the stale evidence pointers, the `DESCRIPTION` 0.2.0
vs NEWS 0.3.0 mismatch, the "DRM.jl not pushed" false claim (it IS pushed), stale docs 199/210/211/221.
All corrected. Overruled her on `.gitignore scratchpad/` (13 files deliberately tracked) — ignored only
`*.log`/`*.rds`. Sweep for other `DATA_*`-contract mirrors: only `test-phylo-utils.R` needed the fix.

## 9. What Did Not Go Smoothly

- The inherited "REML is done / 0 FAIL" was false: focused-runs-only hid 5 failures. The whole
  cross-product-conformance idea grew out of this.
- I asserted "DRM.jl fix unpushed" and "Track A1 never spiked" from stale docs without checking — both
  wrong. Recall-for-conventions-before-publishing is now banked in `LEARNINGS.md`.
- I forgot the `@username` on the first Ayumi comment (banked).
- The location-scale-scale C++ fit cleanly and returned inverted parameters — caught only by the
  recovery gate, not by convergence/pdHess.
- I over-claimed "design 219 premise is FALSE"; the recheck pilot showed it's regime-dependent, and I
  corrected my own correction.

## 10. Known Residuals

- The 8 `inference_ready` cells remain flagged but unchanged, pending the investigation campaign.
- Location-scale-scale unimplemented (design 222 records the failed attempt + leading hypothesis).
- REML provider-gate relaxation (spatial/animal/relmat) scoped + recovery-validated (40/40 intercept)
  but NOT built — and cannot be *certified* until the binding gate lands.
- `sdreport_scaling_probe.R` should become a benchmark test asserting sub-quadratic cost.
- `animal()`/`relmat()`/`spatial()` precisions are dense (O(n³) build) — the separate big-data arc.
- `DESCRIPTION` at `.9001` triggers a CRAN "large version components" note; revert before real release.

## 11. Team Learning

A cross-cutting flag (REML) is a transformation, not a feature; validate it on the *product* axis. A
promotion gate that is prose + an allowlist is not a gate — make it a computation that fails
(`gate-inference-ready.R`). A model that converges with `pdHess=TRUE` and returns plausible numbers is
exactly what a known-truth recovery gate exists to catch. Recall the brain for *conventions* before any
outward-facing action, not only for facts.

## 12. Cross-Product Coverage

The flag audited this session is **REML**. Coverage of the `(REML × surface)` product, from
`estimator-surface-conformance.tsv` (36 cells, machine-checked):

- **Covers ✓** — univariate Gaussian phylo, both REML values, across: fit, sdreport, vcov,
  summary SEs, Wald CI, profile-SD CI, profile-targets, check_drm, ranef, predict, simulate, pdHess.
  Admission gates declared for all 10 scenarios (phylo admitted; spatial/animal/relmat/poisson/
  aggregate/sparse/ordinary-direct-sd/missing-engine/sd_phylo+sigma rejected).
- **Does NOT cover ✗** — REML on `spatial`/`animal`/`relmat` structured effects (conservative gate,
  recovery-validated but unbuilt); REML `confint(method="profile")` on **fixed effects** (capability
  loss — integrated into the Laplace block; documented, not a bug); non-Gaussian families under REML
  (Gaussian-only by construction); the location-scale-scale model (attempted, reverted); bivariate
  `sd_phylo1/2` with a residual-scale phylo endpoint; the `(REML × surface)` grid for any model shape
  other than the base univariate Gaussian phylo cell (e.g. bivariate, ordinary `(1|id)`, direct-SD) —
  the conformance table is seeded on one shape and must be extended per shape.
- **Other flags NOT audited this session** — `penalty`, `engine="julia"`, `aggregate_gaussian`,
  `sparse_fixed` have no conformance rows yet. Each is its own future grid.
