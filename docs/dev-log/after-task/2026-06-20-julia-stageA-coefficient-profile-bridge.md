# After-task: Julia Stage A — bridge profiles coefficient targets (cross-repo)

**Date:** 2026-06-20 · **Author:** Ada (autonomous, owner-directed "push") · **Gate:** callr Julia harness parity + R-only regression
**Branches:** drmTMB `shannon/overnight-audit-gaps-20260619`; DRM.jl `shannon/overnight-audit-verify-20260619`

## Task goal

Owner-directed (design 179 Stage A, "maximized in Julia"): widen the R-Julia bridge so
`confint(engine = "julia", method = "profile")` returns fixed-effect coefficient
profile CIs (previously locked to the phylogenetic SD block), with parity against
native R/TMB profile intervals.

## Files changed

- DRM.jl `src/bridge.jl` (commit `1ef441e`): `drm_bridge_inference` profile branch
  reads `opts[:profile_param]`/`[:profile_coef]`; profiles that block via
  `profile_result(fit; parm = block)` and returns the matching row. Backward
  compatible (absent options -> legacy single SD row).
- drmTMB `R/julia-bridge.R`: (1) `drm_julia_profile_targets` enumerates mu coefficient
  targets (target_class "fixed-effect", transformation "linear_predictor");
  (2) `drm_julia_validate_inference_targets` admits a single fixed-effect coef target;
  (3) `drm_julia_inference_confint_row` applies the identity transform for
  linear_predictor; (4) `drm_julia_call_inference` merges `profile_param`/`profile_coef`
  into the bridge options; (5) `confint.drmTMB_julia` keeps no-parm = legacy SD-only
  and rejects bootstrap-of-coefficients.
- drmTMB tests: `test-julia-bridge.R` synthetic profile-targets contract updated to
  the new SD+coefficients enumeration; `test-julia-inference.R` gains a guarded live
  parity test.
- `docs/design/179-...md` (Stage A LANDED), check-log, this report.

## Checks run and exact outcomes

- Coefficient profile parity (callr harness, Gaussian phylo fixture, n_tip=40):
  engine="julia" vs native TMB profile endpoints -- mu:x max|diff| **1.0e-6**,
  mu:(Intercept) **2.3e-5**. Both engines fit identically (coefs match to 5 dp).
- Regression: SD profile path + no-parm default unchanged; bootstrap-of-coef rejected.
- R-only suites (test-julia-inference/bridge/biv-confint): 165 assertions, **0 failed**
  (after updating the synthetic contract test). Live file run: **0 failed** including
  the existing Poisson round-trip and the new Stage-A parity test.

## Consistency audit

- Cross-repo change committed + pushed in both repos. Backward compatibility preserved
  (legacy SD path, no-parm default). No matrix/finish cell promoted here -- a capability
  cell promotion (Julia bridge coefficient-profile parity) is Fisher-gated separately,
  citing the asserted tolerance (1e-3 in the committed test; measured ~2e-5).

## Tests of the tests

- The live test asserts engine agreement (parity) to 1e-3 and engine label
  "julia_profile_result"; the synthetic test pins the new profile-targets enumeration
  (SD + 2 coef rows) and the single-row builder on the selected SD row.

## Boundary

Parity = engine agreement, NOT interval coverage. First Stage-A increment (single
coefficient via the single-row path). Remaining: multi-coefficient batching (the
SD-axis-specific multi-row join), sigma/scale/correlation coefficient targets, and
bootstrap-of-coefficients (design 179 Stage B). Native R/TMB and Julia-via-R lanes
kept separate.

## Follow-ups

- Fisher-gate + record the Julia bridge coefficient-profile parity capability cell.
- A full `devtools::check()` (only targeted suites run here).
- Stage A multi-coef + Stage B (warm-start bootstrap) per design 179.
