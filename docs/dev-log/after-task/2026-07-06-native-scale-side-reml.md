# After-task — native scale-side REML (debias the sigma variance component)

Meta: 2026-07-06 · Shannon (Opus 4.8) drove; Noether math review; Gauss (tmb_engineer)
dispatched but crashed early, so the change was made directly. Branch
`drmtmb/a1-spatial-sigma-slope-interval`.

## What & why

The structured random-effect **SD on the sigma (log-dispersion) axis is biased low at small
group counts** under ML, which drives the interval under-coverage measured in the g-sweep
(`docs/dev-log/simulation-artifacts/2026-07-06-sigma-axis-gsweep-coverage/`: profile coverage
0.895 for the sigma-intercept SD at g=8). REML debiases variance components, but drmTMB's
native REML **rejected the scale side** (`docs/design/199`, `211`).

This slice extends drmTMB's existing **random-block REML idiom** (the glmmTMB/gllvmTMB pattern:
add fixed effects to TMB's Laplace-integrated `random` set) from the **mean** fixed effects to
the **sigma** fixed effects, so the restricted likelihood also adjusts for the scale
coefficients — the Cox-Reid / adjusted-profile REML that debiases the sigma variance component.

## Change (R only — no C++, no Julia)

`R/drmTMB.R`:
- `drm_apply_estimator_spec()` — under REML, when a sigma variance component is present, also
  append `beta_sigma` to `spec$tmb_random_names` (gated on a sigma effect, so **mean-only REML
  is byte-identical**).
- `drm_validate_reml_spec()` — admit a **pure scale-side phylo** effect (sigma endpoint, no mean
  endpoint) under REML; keep rejecting **matched mean+scale** phylo (`1 | p | species`), whose
  mean-scale coupling is not yet REML-calibrated and whose `sdreport` is unstable.

`tests/testthat/test-reml-phylo-location.R` — updated the (now-stale) "REML rejects scale-side"
assertions: pure scale-side phylo is admitted; matched mean+scale is still rejected.

## Math verification (Noether, 2026-07-06)

Marginalizing `beta_sigma` via TMB's Laplace is an **adequate approximate restricted
likelihood** (Laplace / adjusted-profile REML), NOT exact — `beta_sigma` enters V nonlinearly
(`σ² = exp(2·η_σ)`). Key points:
- It captures the DoF lost to the scale coefficients via the **observed** information
  `0.5·log|∂²f/∂β_ψ²|` — the correct nonlinear generalization of `log|XᵀV⁻¹X|`.
- **No missing Jacobian term**: TMB auto-differentiates the exact density (the `−log σ_i`
  standardization Jacobian is inside the objective), so the log-link curvature is captured
  automatically.
- **Does NOT inherit the DRM.jl AI-quadratic bug** — that flaw was the analytic
  average-information quadratic in the shrunk BLUP; the Laplace route is the AD analogue of
  DRM.jl's *valid* observed-information path.
- Residual bias is **O(1/g)** — smaller than the ML bias it removes, largest at small g and the
  σ→0 boundary. So REML cuts the bias but does not make g=8 perfectly nominal.

## Evidence

Native ML-vs-REML on the phylo sigma-intercept cell (g=8, truth SD=0.60, 30 seeds;
`.../2026-07-06-native-scale-side-reml/`):
- mean SD: ML **0.429** (bias −0.171) → REML **0.506** (bias −0.094) — bias ≈ halved.
- REML − ML = **+0.077** (SE 0.011); **30/30** reps REML > ML.
- Contrast: the DRM.jl-bridge REML was 0/30 (wrong direction) because it restricts β_μ only.
- `devtools::test(filter = "reml")`: **FAIL 0 / PASS 74** (mean-side REML + hand-reference
  restricted-likelihood test intact).

## Scope / limitations (deliberate first slice)

Admitted: **pure phylo sigma-intercept**, univariate Gaussian, `engine = "tmb"`. Still rejected /
deferred: matched mean+scale phylo, ordinary `(1 | id)` sigma random effects (gate at
`drm_validate_reml_spec` ~L1948), bivariate, spatial/animal/relmat sigma structured effects,
scale-side random slopes. `docs/design/199` + `211` still describe the old rejection and need a
follow-up update.

## Next

1. **Curie** — coverage grid: does the halved bias lift the sigma-intercept profile coverage
   from 0.895 toward nominal across g? (the arc payoff).
2. **Fisher** — adjudicate bias/coverage for an `inference_ready` claim.
3. **DRM.jl fix** — `_glsp_reml_penalty` restricts β_μ only; extend to β_ψ (Julia path).
4. **Harden** — ordinary/biv/other-provider scale-side REML + design-doc updates.
