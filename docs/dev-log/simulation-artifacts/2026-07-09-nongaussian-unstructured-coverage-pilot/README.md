# Unstructured non-Gaussian coverage pilot (2026-07-09)

Pilot for the v0.4.0 → v1.0 goal of promoting **unstructured (fixed-effect)
non-Gaussian** intervals toward `inference_ready`. Run on Totoro (90 cores,
`OPENBLAS_NUM_THREADS=1`).

## Design

- **Families**: `binomial()`, `poisson()`, `beta()`, `nbinom2()`.
- **Model**: `bf(y ~ x)` (single continuous covariate); constant scale.
- **Target**: the two **mean** (location) coefficients on the link scale —
  `fixef:mu:(Intercept)`, `fixef:mu:x`.
- **Channel**: Wald (`confint()` default, link scale).
- **n-ladder**: n ∈ {50, 150, 500}; **400 seeds** per cell.
- **Bar**: the `gate-inference-ready.R` shape — `finite_rate >= 0.95` AND
  `coverage + 2*MCSE >= 0.94` (nominal, no small-g penalty since these are
  unstructured fixed effects).
- Driver: `driver.R` (in this directory). Results: `results.tsv`.

## Result

**All 24 cells clear the floor.** `finite_rate = 1.00` everywhere; mean-coefficient
Wald coverage is at nominal across all four families and all three n (range
0.922–0.973, MCSE ≈ 0.008–0.013). No systematic under-coverage, and no worsening
with n — even n = 50 is well-calibrated.

⇒ **Unstructured non-Gaussian fixed-effect *mean* intervals are inference-ready-grade
(calibrated Wald, finite-rate 1.0)** for binomial / poisson / beta / nbinom2.

## Scope / caveats (honest)

- **Mean coefficients only.** The **scale (`sigma`) coefficients** for `beta`/`nbinom2`
  — drmTMB's distributional-regression selling point — are NOT tested here.
- **Wald only** (the well-calibrated case; profile/bootstrap are the fallbacks for
  when Wald fails, which it does not here).
- **Single DGP per family** (fixed truth, one covariate). Not yet varied over effect
  size, number of covariates, or boundary/rare-event stress (rare-event binomial,
  low-count Poisson).

## Next (phase 2)

Scale-coefficient coverage with the model's own parameterization —
`beta`: `phi = exp(-2·log_sigma)`; `nbinom2`: `alpha = exp(2·log_sigma)`
(`src/drmTMB.cpp`, `src/drm_count_kernels.h`) — plus a few stress DGPs, at higher
seed counts. Only then extend any `inference_ready` wording to the scale side.
