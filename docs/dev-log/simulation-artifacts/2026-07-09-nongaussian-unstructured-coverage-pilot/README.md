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

## Phase 2 (2026-07-09) — scale coefficients + stress

Extends the pilot to the **scale (`sigma`) coefficients** of `beta`/`nbinom2`
location-scale models plus two mean stress cases. Wald channel, 400 seeds,
n ∈ {150, 400, 800}. Driver: `phase2-driver.R`. Results: `phase2-results.tsv`.

**Symbolic-alignment table (confirmed empirically — build BEFORE simulating):**

| family | dispersion ↔ scale | simulate with |
| --- | --- | --- |
| `beta` | `phi  = exp(-2·log_sigma)` | `phi_i  = exp(-2·(sig0 + sig1·x_i))` |
| `nbinom2` | `size = exp(-2·log_sigma)` | `size_i = exp(-2·(sig0 + sig1·x_i))` |

An initial `size = exp(+2·log_sigma)` guess gave nbinom2 scale coverage **0.000** — caught
by a smoke test, fixed by an empirical known-input probe. (Lesson: write the map table first.)

**Result:**
- **nbinom2 location-scale (mean + scale):** finite-rate 1.00, coverage 0.93–0.97 at every
  n → inference-ready-grade.
- **binomial rare-event (~8% base) and Poisson low-count (mean 1):** finite-rate 1.00,
  coverage 0.94–0.97 → mean intervals stay calibrated under stress.
- **beta location-scale (mean + scale):** coverage 0.93–0.95 (calibrated), but interval
  finite-rate falls with n (0.978 → 0.958 → 0.885 at n=800). **Root cause (confirmed):**
  every non-finite case has an observation with `y == 1.0` exactly — `rbeta` rounding to the
  boundary at extreme covariates (low `phi`, high `mu`). `beta()` correctly requires
  `y ∈ (0, 1)` and returns non-finite on boundary data; this is correct behaviour, not an
  interval defect. Boundary proportions (exact 0/1) should use `zero_one_beta()`.

**Verdict:** unstructured non-Gaussian **mean** intervals (binomial/poisson/beta/nbinom2,
incl. rare/low-count) and **nbinom2 scale** intervals are calibrated (inference-ready-grade,
Wald). `beta` scale intervals are calibrated for interior data; exact-0/1 proportions need
`zero_one_beta()`.
