# Coverage grid — results

The "thousands of tests" half of Trust Dossier #1. Produced by
[`../totoro/run_grid.R`](../totoro/run_grid.R) and summarised by
[`../totoro/summarise_grid.R`](../totoro/summarise_grid.R).

- `grid-coverage-summary.csv` — pooled Wald 95% coverage per effect-measure × parameter,
  with per-cell min/max and the total interval count.
- `grid-coverage-bycell.csv` — one row per DGP cell × parameter (measure, n_study, σ,
  sampling_sd, coverage, MCSE), for the n_study / σ trends.

## This run (local broad tier, `TD_LOCAL=1`)
- 4 effect-measure regimes (SMD, lnRR, logOR, logIRR) × 12 σ>0 DGP cells each
  (n_study {20,40,80} × σ {0.25,0.50} × 2 sampling-SD scales; vector known V),
  400 replicates per cell = **57,600 Wald intervals**. Wall time ≈ 13 min, 8 cores.
- σ=0 boundary cells are run but excluded from Wald coverage (variance component at the
  true-zero boundary).

## Headline
Wald 95% coverage is **0.91–0.94**, uniformly across all four measures: near-nominal for the
mean, mildly low for the heterogeneity SD at small study counts — the known conservative
behaviour of Wald intervals for τ² (why metafor offers Q-profile CIs). Coverage climbs toward
0.95 as study count grows (σ: 0.90 → 0.92 → 0.94 for n=20 → 40 → 80). Not a defect — correct
asymptotic behaviour with well-understood finite-sample Wald under-coverage.

## Full calibrated campaign
The publication-grade version — 768 cells × 2000 reps (adds n_study {10,80}, σ {0,0.1},
dense known V, ρ {0.2,0.5}) — runs on Totoro. See [`../totoro/DISPATCH.md`](../totoro/DISPATCH.md).
The RDS replicate artifacts (~28k files) are NOT committed; regenerate with the driver.
