# Gaussian spatial (coordinate-kernel) SD recovery (500 reps, 2-cell consistency) — held diagnostic

**Date:** 2026-06-20 · **Author:** Ada (autonomous) · **Outcome:** honest diagnostic, structured sub-type evidence

Native R/TMB recovery for a Gaussian **spatial** random intercept,
`bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1)`. The model's spatial
kernel is a FIXED exponential correlation `exp(-dist / range)` with
`range = median positive pairwise distance` (unit diagonal; only the SD scaling is
estimated, not the range -- see `drm_spatial_coords_precision`). The DGP replicates
that exponential kernel INDEPENDENTLY, so `sd_spatial` maps 1:1 to the reported SD.
This is the **spatial** sub-type of the "Structural dependencies" matrix row
(animal / phylo / relmat / spatial / kernel / SPDE).

## Design (deterministic, `master_seed = 20260620`)

- 2 cells: `n_site in {20, 40}`, `n_each = 7` records/site. 500 reps/cell (1000 fits).
  Fixed known random coordinates per cell (`runif` in the unit square).
- Truth: `b0 = 0.3`, `b1 = 0.5`, `sigma = 0.4`, `sd_spatial = 0.5`.
- Spatial effects simulated as `N(0, sd_spatial^2 * K)`, `K = exp(-D / median(D>0))`;
  the model uses the same exponential kernel internally.
- Recovered: fixed effects, the spatial RE SD (`fit$sdpars$mu`, `spatial(1 | site)`),
  residual sigma; Wald coverage for the two fixed effects.

## Result (`tables/spatial-recovery-summary.csv`, 0 fit errors, pdHess 1.000)

| target | n_site=20 | n_site=40 |
| --- | --- | --- |
| **sd_spatial** rel bias | **-10.9%** | **-2.8%** |
| b1 (slope) rel bias | +0.1% | 0.0% |
| sigma rel bias | -0.1% | -0.1% |
| intercept rel bias | +3.8% | +7.6% |
| slope Wald coverage | 0.958 | 0.946 |
| intercept Wald coverage | 0.888 | 0.910 |

## Finding (honest diagnostic)

- **The spatial SD recovers and is consistent**: rel bias -10.9% -> -2.8% as sites
  grow (the expected ML small-sample downward bias, shrinking with N). Intermediate
  between the well-conditioned relmat/animal recoveries (-1% to -3%) and the highly
  autocorrelated ultrametric phylo (-32% at 60 species): the exponential
  median-range kernel is moderately autocorrelated.
- **Slope and residual sigma recover cleanly** (rel bias <= 0.1%; slope Wald
  0.946-0.958, at nominal).
- **The intercept is high-variance with under-nominal Wald** (RMSE ~0.32; coverage
  0.888 / 0.910, below the 0.93 floor at both site counts) -- the spatial-field /
  grand-mean confounding (a near-flat spatial mode aliases the intercept), the same
  pattern seen in the phylo and coevolution diagnostics.

## How to reproduce

```sh
cd /Users/z3437171/.codex/worktrees/540b/drmTMB
/usr/local/bin/Rscript --vanilla \
  docs/dev-log/simulation-artifacts/2026-06-20-spatial-coords-recovery/run.R 500
```

## Boundary

Native R/TMB, Gaussian, one `spatial` block with a fixed coordinate kernel, repeated
records per site, complete data. POINT recovery of the spatial SD + fixed effects,
plus fixed-effect Wald coverage only. RE-SD interval calibration NOT claimed; the
intercept Wald is below nominal (spatial-mean confounding). Structured sub-type
evidence toward the "Structural dependencies" row; not a standalone cell promotion
on its own.
