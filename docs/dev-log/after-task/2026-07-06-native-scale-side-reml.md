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

## Coverage + Ayumi-scale results (overnight, 2026-07-06)

Coverage grid on Totoro: phylo sigma-intercept, **tmbprofile** interval engine, 480 paired
ML/REML reps per g at g ∈ {8,16,32}, plus an Ayumi-scale probe at g ∈ {64,128} (15 reps).
Evidence: `docs/dev-log/simulation-artifacts/2026-07-06-native-reml-coverage/`.

| g | ML cov | REML cov | ML bias | REML bias | REML finite-rate | REML s/fit (vs ML) |
| --- | --- | --- | --- | --- | --- | --- |
| 8 | 0.960 | 0.968 | −0.092 | −0.029 | 0.925 (vs 0.88) | 0.16 (vs 1.08) |
| 16 | 0.951 | 0.960 | −0.041 | −0.008 | | |
| 32 | 0.933 | 0.938 | −0.030 | −0.007 | | |
| 64 | 0.933 | 0.933 | −0.041 | −0.024 | | 0.64 (vs 4.9) |
| 128 | 0.933 | 0.933 | −0.009 | +0.019 | | 1.59 (vs 10.5) |

**REML wins on four fronts:** clear point-estimate **debiasing**; a small consistent **coverage**
gain (+0.005–0.01); a better **finite-rate** (0.925 vs 0.88 at g=8); and dramatically **faster**
intervals (0.16 vs 1.08 s at g=8; 1.6 vs 10.5 s at g=128).

**Two honest nuances:**
1. **Interval engine matters.** With `profile_engine = "tmbprofile"` ML already covers ~nominal
   (0.96), not the 0.895 seen earlier with the `"endpoint"` engine — so the earlier
   under-coverage was substantially an *endpoint-engine* artifact, not pure bias. REML's headline
   gains are debiasing + finite-rate + speed; coverage is fixed by *engine + REML together*.

   > ### ⚠️ CORRECTION (2026-07-08) — nuance 1 above is WRONG. Do not build on it.
   >
   > **The comparison was confounded across four factors at once.** The 0.895 came from the
   > g-sweep (`.../2026-07-06-sigma-axis-gsweep-coverage/`): **spatial** provider, truth SD
   > **0.50**, `endpoint` engine, median interval width **0.65**. The 0.960 came from this
   > document's own grid: **phylo** provider, truth SD **0.60**, `tmbprofile` engine, median
   > width **1.20**. Provider, truth, runner *and* engine all differ, and the phylo intervals
   > are nearly **twice as wide**. That contrast is not evidence about the interval engine.
   >
   > **The controlled test refutes it.** Running all three arms on the *same fitted objects*
   > (`scratchpad/engine_equivalence_probe.R`, 12 seeds, spatial sigma-slope cell):
   >
   > ```
   > UPPER  endpoint@90    − tmbprofile : median +0.0000
   > UPPER  endpoint@uncap − tmbprofile : median +0.0000
   > LOWER  endpoint@90    − tmbprofile : median −0.0000
   > ```
   >
   > `endpoint@90` and `endpoint@uncapped` are bit-identical — the runner's
   > `profile_endpoint_max_eval = 90L` (`tools/run-structured-re-sigma-slope-coverage-grid.R:515`)
   > **never binds**. Two solvers on the same profile likelihood agree, as they must.
   > *(Incidentally `tmbprofile` was the **less** reliable engine here: finite on 9/12 seeds vs
   > `endpoint`'s 12/12.)*
   >
   > **Therefore the under-coverage is centre bias (ML small-`g` variance-component bias), not a
   > solver artifact.** `mean est 0.3885` against truth `0.50` reproduces the pilot's −0.105.
   > Doc 218's "interval-method levers exhausted" verdict stands on its own evidence; it is not
   > rescued by an engine switch.
   >
   > Superseded by: this session's Phase-1 attribution work. The banked brain note
   > *"Native scale-side REML debiases sigma-phylo variance components"* carries the same
   > erroneous claim and has been corrected in place.
2. **The `"endpoint"` engine ERRORS on REML fits** (`'d' must be a nonempty numeric vector`,
   `conf.status=profile_failed`) — because β_μ/β_σ move into the Laplace `random` block, the
   endpoint refit gets an empty free-parameter vector. `tmbprofile` works; the endpoint-solver
   REML gap is a separate follow-up (R/profile.R).

**Ayumi-scale engine smoke (g = 64, 128 — bird-tree-scale stand-in):** native scale-side REML
**converges 15/15, debiases, returns finite intervals, and is fast** (0.6 s at g=64, 1.6 s at
g=128 — faster than ML). So the engine scales; "might Ayumi's bird data run?" → the engine
smoke says **yes** (respecting the parked-thread boundary — this is an engine smoke, not an
Ayumi reply; the full run still needs the actual data + coverage certification).

## DRM.jl β_ψ fix (the Julia path)

`_glsp_reml_refit_clean` (via `_glsp_reml_penalty`) restricted only the **mean** fixed effects
(`pμ`); the σ variance component needs the **scale** fixed effect β_ψ integrated too. Fixed both
wired σ-phylo branches in `../DRM.jl/src/gaussian_locscale_phylo.jl` (lines ~574, ~656):
`pμ` → `pμ + pψ` (restrict β_μ AND β_ψ — the complete Cox-Reid restricted likelihood; corroborated
by DRM.jl's own q4 route, which already profiles β_μ AND β_σ). **Verified via the bridge: REML now
debiases 7/8 (mean 0.423 → 0.484, truth 0.60; was 0/30 the *wrong* way before the fix)** — the same
correction as native drmTMB, now on the Julia path. Committed on the DRM.jl branch `drmjl/sigma-phylo-reml-beta-psi-fix` (`ab17c0e`), **pushed to
`origin`** (verified 2026-07-08; this doc previously said "not pushed", which was true when written
and became stale). DRM.jl σ-phylo REML tests likely need updating to the corrected (debiasing) behavior.
