# After-task: R-bridge batch 20 (Gaussian structured slope SD, Binomial relmat scaling audit, NB2 animal simulate)

## Inconsistency

DRM.jl 40da69c72 and fbcf4d0e3 (origin/codex/general-sd-regression) added a
Gaussian structured slope-only SD route (`animal`, `relmat`, coordinate
`spatial`) and an NB2 animal slope-only marginal simulator. The R gates refused
the Gaussian slopes, and `simulate()` on a Julia NB2 random-effect fit refused.
Batch 18 also left an open question: the Binomial relmat slope bridge might
hide the K-scaling mismatch found for Poisson, because its test compares at
tolerance 0.1.

## What was done

- `R/julia-bridge.R`
  - `drm_julia_gaussian_{animal,relmat,spatial}_sd_slope_route_admitted()` and
    the union `drm_julia_gaussian_structured_sd_slope_route_admitted()`.
    Shape-only gates that reuse the NB2 animal, Poisson relmat and Binomial
    spatial shapes (single `mu` structured slope, matching `sd()` target,
    optional `sigma ~ 1`).
  - Gaussian animal slope is admitted (marker-slope guard, SD label key, payload
    coefficient and marker-type checks).
  - Gaussian relmat and coordinate-spatial slopes are REFUSED in
    `drm_julia_structured_payload()` with a specific message (see Findings 2).
  - A coordinate spatial slope would be sent as a relmat slope with the native
    covariance, as the Binomial spatial route already does; the SD key rewrite
    now also fires for the Gaussian spatial slope.
- `R/julia-simulate.R`: `simulate()` on a Julia NB2 animal slope-only fit.
  New `drm_julia_nbinom2_animal_sd_slope_simulation_spec()` and
  `drm_julia_simulate_nbinom2_animal_sd_slope()`; marginal only (conditional
  simulation refused, as for Gamma and Binomial). The draw is done in R: latent
  `chol(A) z`, scaled by the fitted group SD, added as `x * u` to the fixed
  linear predictor, then `rnbinom(size = drm_nbinom2_size(sigma))`. It does not
  call the Julia simulator (`_marginal_simulator_build`), which the bridge does
  not expose.
- `tests/testthat/test-julia-b20-gaussian-slope-binomial-relmat-bridge.R` (new).
- `inst/extdata/env-skip-census.tsv`: three rows for the new file.
- No receipted test file was edited.

## Results (Mac, Julia 1.10.0, DRM.jl `general-sd-julia` at fbcf4d0e3, 2 threads)

Tolerances fixed in advance: coefficients 1e-3 absolute (every block), logLik
1e-2 absolute, native TMB with `se = FALSE`.

| Route | Fixture | max coef diff | logLik diff | Verdict |
|---|---|---|---|---|
| Binomial relmat slope, non-unit K (diag 0.64-2.56) | 64 groups x 32, seed 20261102 | mu 2.1e-09, sd_relmat 3.3e-08 | 1.2e-05 | engines agree; no refusal needed |
| Binomial relmat intercept, same K | same | mu 9.2e-09, sd_relmat 4.3e-08 | 1.5e-05 | engines agree |
| Gaussian animal slope, raw non-unit A (diag 0.64-2.25) | 48 offspring x 14, seed 20261102 | mu 3.9e-11, sigma 8.4e-13, sd_animal 1.1e-10 | 7.8e-12 | admitted |
| Gaussian relmat slope, raw non-unit K | 48 x 14 | (current Julia head) the call aborts in Julia | n/a | refused on R |
| Gaussian spatial slope | 48 x 14, sine-curve coords | (current Julia head) same abort | n/a | refused on R |
| NB2 animal slope `simulate()` | 64 offspring x 20, nsim 200 | seeded repeat identical; counts non-negative integers; mean ratio simulated/observed 0.9999 | n/a | admitted (sanity band only) |

Neighbouring tests re-run clean (offline paths): b18 bridge, Binomial relmat
slope bridge, admission docs and census, env-skip census, marker-slope guard,
structured, structured dimnames, slope-nongaussian, Gamma animal simulation,
Poisson animal slope parity, Binomial animal-iid bridge.

## Findings

1. **The Binomial relmat route does not have the Poisson K-scaling problem.**
   With a non-unit-diagonal K the Julia and native fits agree to 3e-8 in
   coefficients and 1.2e-5 in logLik, for both the slope and intercept forms.
   The batch 18 suspicion ("probably has the same issue") is false; no refusal
   was added. The existing file
   `tests/testthat/test-julia-binomial-relmat-slope-sd-bridge.R` still compares
   at 0.1, which is looser than the measured agreement but not wrong. It is a
   receipted file and was not edited; it could be tightened to 1e-3 in a later
   change.
2. **Gaussian relmat and spatial slopes need a one-line DRM.jl change before
   they can be admitted.** `_bridge_rendered_regression_blocks`
   (`src/bridge.jl` line 2076) has
   `binomial_relmat_sd_slope_only = fit.family isa Union{Binomial,Poisson} && ...`.
   For Gaussian the fit succeeds, then the label check aborts with
   "typed schema labels do not match fitted raw columns for `mu`". A coordinate
   spatial slope is sent as a relmat slope, so it aborts the same way. With a
   private copy of DRM.jl whose line 2076 reads
   `Union{Binomial,Poisson,Gaussian}`, both routes match native: relmat (raw
   non-unit K, diag 0.64-2.25) logLik diff 4.0e-11; spatial (K = native
   covariance, diag about 1) logLik diff 3.5e-11, coefficients identical to the
   printed precision. The same union appears at `src/inference.jl` line 3266
   (marginal simulator) and was not tested. Once that line lands in DRM.jl,
   remove the `gaussian_relmat_slope || gaussian_spatial_slope` refusal block
   in `drm_julia_structured_payload()` and the matching test; the live tests
   for those two providers are then a copy of the animal one.
3. **Kernel scaling.** Gaussian relmat and animal keep the raw K or A in DRM.jl
   and match native (checked with non-unit diagonals). The spatial fixture has
   diag(K) about 1, so it does not test scaling; the spatial route sends the
   native covariance as a raw K, which is the same object native uses.
4. `predict(fit)` on the Julia Gaussian animal fit returns the existing
   "did not retain its random-effect payload" message; unchanged behaviour,
   not touched.
5. The NB2 slope SD predictions are group-named, not `sd_animal(id):group`
   as the Gamma route expects; the new simulator accepts both spellings.

## Not covered

- One fixture per route, one seed; no SE, coverage, profile or bootstrap claim.
- Gaussian: ML only, `sigma ~ 1` only, no `Ainv`, REML, missing responses or
  extra random effects (Julia limits); no Gaussian simulate on these routes.
- The NB2 simulator is the R-side one; agreement with the Julia
  `_marginal_simulator_build` was not compared. The mean-ratio check is a
  sanity band, not a calibration test.
- Docs (julia-engine vignette, capability and parity registry) not updated;
  the docs lane should add the Gaussian animal slope route, the Gaussian
  relmat/spatial hold, and NB2 animal simulate.

## Batch 22 addendum (2026-11-02): Gaussian relmat and spatial slope SD admitted

DRModels.jl 5ac051eed (branch `codex/general-sd-regression`) widens the bridge
label allowance: `binomial_relmat_sd_slope_only` now covers Gaussian, and a
Gaussian-only spatial slope allowance is passed through
`_bridge_render_formula_block` (the spatial slope needs `allow_spatial_slope`
in `_split_ranef`, not only the relmat union). The `src/inference.jl` union
(`_marginal_simulator_build`) is the non-Gaussian marginal simulator and was
left unchanged. New Julia test
`test/test_bridge_gaussian_relmat_spatial_slope_sd.jl` fails before (typed
schema labels mismatch) and passes after (6/6). All 40 bridge and Gaussian
test files passed on Totoro (Julia 1.10.12, 1 thread, 6 processes, exit 0).

R side, this batch:

1. Removed the Gaussian relmat/spatial refusal block in
   `drm_julia_structured_payload()`; the refusal assertion in
   `test-julia-b20-gaussian-slope-binomial-relmat-bridge.R` is now an
   admission check.
2. Live parity (tolerances fixed beforehand: 1e-3 coefficients, 1e-2 logLik,
   native TMB `se = FALSE`), DRM_JL_PATH at the pushed worktree:
   - relmat, non-unit-diagonal K (diag 0.49-2.56, 40 groups): max coefficient
     diff mu 2.7e-14, sigma 5.2e-14, sd 5.3e-14; logLik diff 1.4e-11.
   - coordinate spatial, shuffled rows and coords not in first-seen order:
     mu 3.7e-12, sigma 1.2e-12, sd 5.5e-11; logLik diff 2.7e-11.
3. **Bug found by the spatial fixture (existing, not specific to Gaussian
   slopes).** `drm_julia_structured_matrix()` stripped the coordinate rownames
   (`drm_julia_as_matrix()` sets `dimnames` to NULL), so
   `drm_spatial_coords_precision()` assumed the rows were already in first-seen
   group order. Named coords listed in any other order paired the wrong kernel
   rows with groups: before the fix the shuffled Gaussian spatial slope fit had
   logLik -547.5 (Julia) against -523.8 (native). The fix keeps the rownames
   for `coords` only; the unit test checks that the payload kernel follows the
   data's first-seen order. This affects every Gaussian and Binomial spatial
   route through the bridge with unordered named coords; I did not re-measure
   the other spatial routes live beyond the existing test files below.
4. Unnamed coords are still taken as already in first-seen order (same as
   native), so no refusal was needed.

Not covered: one fixture and seed per route; no SE, coverage or profile claim;
Gaussian ML with `sigma ~ 1` only; docs and registry rows not updated.

## Coordinator rerun of live Julia tests touching coords (2026-11-02)

After applying the coords rownames fix, every live Julia test file that uses
`coords` was rerun on the Mac against DRModels.jl `5ac051eed` with
`NOT_CRAN=true`: b20 (67 pass), binomial spatial SD bridge (37), biv
inference (57), marker-slope guard (41), structured inference (59), structured
(86). Two files fail one convergence expectation each,
`test-julia-biv-q2-reml.R:259` (bivariate phylo q2 REML) and
`test-julia-tmb-parity.R:661`. Both fail identically at the pre-patch commit
`a63b56e6e`, so they predate this fix; they are open live-Julia convergence
items, not regressions from the coords change.
