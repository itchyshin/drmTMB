# After Task: promote gaussian_response_mask partial -> covered (bridge response-mask parity)

**Date:** 2026-06-21 (autonomous; Ada orchestrating, session 5)
**Worktree:** `/Users/z3437171/.codex/worktrees/540b/drmTMB`, branch
`shannon/overnight-audit-gaps-20260619`.
**Lane:** Julia-via-R bridge only. Engine-vs-engine parity, NOT interval coverage,
NOT a native-TMB-standalone or direct-DRM.jl claim, NOT release/CRAN.

## Goal

Move the `gaussian_response_mask` mission-control capability cell from `partial` to
`covered` — one of the "partial/planned" cells the owner asked to advance. A scoping
fan-out found it was the lowest-effort honest promotion on the board.

## Key finding: the capability already worked; only the parity test was missing

`gaussian_response_mask` is `engine = "julia"` fitting Gaussian location-scale data
with NA responses under `missing = miss_control(response = "include")`. The mask is
already implemented end-to-end — the R bridge ships the full data to DRM.jl, and
DRM.jl's `gaussian_core` fits the observed-data likelihood while keeping the full
design. The pre-existing `tests/testthat/test-julia-missing.R` checked the Julia
engine in ISOLATION (finite logLik + observed nobs) but never compared it to native
TMB. So the cell was `partial` only because the engine-vs-engine parity test — the
doctrine's certification for `covered` — was never written.

## What was done

- New masked-data parity block in `tests/testthat/test-julia-tmb-parity.R`
  (`drm_parity_fit_route_c_missing` + its `test_that`): a clone of the Route C
  harness that injects NA responses and fits BOTH `engine='tmb'` and
  `engine='julia'` under `miss_control(response='include')`, asserting
  |dlogLik| < 1e-6, max|dcoef| < 1e-5, max|dWald-endpoint| <= 1e-4, plus nobs
  agreement, on one seed-fixed fixture (8/120 masked) matching the Route C/B
  single-fixture convention.
- Promoted the R registry `drm_julia_capability_comparison()` row (`R/julia-bridge.R`,
  index 3): `claim_status` partial -> covered, with updated `claim_boundary` +
  `next_action`. Regenerated BOTH capability TSVs from the registry
  (`tools/write-julia-capability-comparison.R`).
- Reconciled the per-cell-vs-aggregate claim surfaces (mirroring the rho12
  precedent): added a note to the design-168 "Missing values" row and the dashboard
  `status.json` that the narrow per-cell row is `covered` while the aggregate
  Missing-values bridge cell stays `planned` (predictors, non-Gaussian masks,
  bivariate-mask parity, EM/FIML still open).
- Added a one-line pointer in `test-julia-missing.R` to the new parity block.

## Verification (live, this session, callr-isolated)

- Committed fixture (8/120 masked, the Route C/B single-fixture house standard):
  |dlogLik| 4.25e-10, max|dcoef| 1.39e-6, max|dWald-endpoint| 1.39e-6,
  nobs_tmb == nobs_jl == 112, both converged.
- Fraction-robustness (banked via Fisher's review, not in CI): Fisher swept 2-30
  masked rows; logLik parity stays 1.2e-10..5.5e-10 and coefficient parity stays
  ~1e-6..~1e-5 (mildly looser at heavier masking / fewer observed rows -- still 5
  significant figures).
- `test-julia-gate-vs-engine.R` 113/113 (artifact == registry, both TSVs);
  `tools/validate-mission-control.py` `mission_control_ok`.
- Full `test-julia-tmb-parity.R` in-suite: 0 fail (Route A is the pre-existing
  deliberate skip).

## Review

- **Fisher (inference): GO.** Anchored the logLik parity — the masked TMB logLik is
  BIT-IDENTICAL to the physical `na.omit` complete-case fit, so 4.3e-10 is parity
  against an independently-correct quantity, not a two-engine coincidence;
  independent per-engine SEs agree to ~2e-6 (genuine covariance transport).
  Recommended the heavier-mask fixture + nobs-agreement assertion (both applied).
- **Rose (claim-boundary): NO-GO -> GO after fixes.** Caught a real overclaim — the
  draft boundary said "bivariate response masks remain gated," but the gate
  `drm_julia_missing_supported` admits `biv_gaussian` (a passing test proves it
  routes); corrected to scope the cell to the univariate mask and note that
  bivariate-mask *parity* is unbanked. Also flagged the design-168/status.json
  Missing-values cell now contradicting the per-cell registry; reconciled per the
  rho12 precedent.

## Boundaries respected

Bridge lane only. `covered` = point + logLik + coefficient + Wald-endpoint parity
(engine vs engine), on the univariate Gaussian response mask only. The non-Gaussian
rejection gate is unchanged and still rejects non-Gaussian `response="include"`.
Only the one registry cell moved (claim_status vector changed at index 3 only). No
GPL code referenced.

## Next (separate slices)

- A second masked-data parity cell for the BIVARIATE Gaussian response mask (the
  gate already routes it; only the engine-vs-engine parity is unbanked).
- The other scoped partial/planned cells: `phylo_coef_profile_bridge` (mu multi-coef
  batching is do-now; sigma-boundary + warm-start prereqs are DRM.jl-lane),
  `biv_q4_phylo_reml` (covered is structurally impossible — one engine; bank a
  defended partial), `plain_binomial_nonphylo` (owner decision: keep intentionally
  gated vs promote for parity-completeness; #569 has landed).
