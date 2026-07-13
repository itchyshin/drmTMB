# Laplace vs AGHQ, and the RE-SD bias vs sample size

**Date:** 2026-07-12 · **Question (Shinichi):** is the downward random-effect-SD bias
we saw in Arc 2b/2c *exactly what we expect* (a small-sample effect), and how does
ML-Laplace compare to adaptive Gauss–Hermite quadrature (AGHQ)?

## Design

Model: a **binomial random intercept** `y ~ x + (1 | id)`, Bernoulli (trials = 1) — the
most integral-biased case. drmTMB fits by **Laplace**. `lme4::glmer` is the external
reference: `nAGQ = 1` is Laplace (a cross-check on drmTMB), `nAGQ = 25` is **AGHQ**.
True RE-SD = 0.80, 80 seeds per cell. Generator: `generate.R`.

Two axes, because the RE-SD bias has **two distinct sources**:
- **Integral (Laplace) bias** — the single-point Laplace approximation of each cluster's
  contribution. Shrinks as the **per-cluster size n grows**. **AGHQ removes it.**
- **Finite-cluster (df) bias** — ML "uses up" degrees of freedom on the fixed effects.
  Shrinks as the **number of clusters M grows**. **REML removes it (Gaussian only); AGHQ
  does not.**

## Results (`laplace-vs-aghq.tsv`)

**Panel A — vary clusters M, per-cluster n = 8 fixed (the df bias):**

| M | drmTMB (Laplace) | glmer Laplace | glmer AGHQ | drmTMB rel-bias | AGHQ rel-bias |
|--:|--:|--:|--:|--:|--:|
| 8 | 0.723 | 0.723 | 0.746 | −9.6% | −6.7% |
| 32 | 0.741 | 0.740 | 0.766 | −7.4% | −4.3% |
| 64 | 0.750 | 0.750 | 0.776 | −6.2% | −3.1% |
| 128 | 0.762 | 0.761 | 0.787 | −4.8% | −1.6% |

**Panel B — M = 40 fixed, vary per-cluster n (the integral bias):**

| n/cluster | drmTMB (Laplace) | glmer Laplace | glmer AGHQ | Laplace rel-bias | AGHQ rel-bias |
|--:|--:|--:|--:|--:|--:|
| 2 | 0.615 | 0.615 | **0.816** | **−23%** | **+2.0%** |
| 4 | 0.691 | 0.690 | 0.759 | −14% | −5.1% |
| 8 | 0.721 | 0.721 | 0.746 | −10% | −6.8% |
| 20 | 0.803 | 0.802 | 0.809 | +0.3% | +1.1% |

## What it means

1. **drmTMB's Laplace is correct.** drmTMB and glmer-Laplace agree to ~3 decimals in every
   cell. The bias is a property of the *estimator*, not a drmTMB bug.
2. **The bias is exactly the expected finite-sample ML-Laplace effect.** It vanishes along
   both axes: as n → ∞ (integral) and as M → ∞ (df).
3. **AGHQ is dramatic where it should be.** At tiny clusters (n = 2) Laplace underestimates
   the SD by **−23%**, while AGHQ is essentially **unbiased (+2%)** — AGHQ almost entirely
   removes the integral bias. This is the concrete case for the planned AGHQ estimator axis
   for the logit/binary families (it is *not* "just rejected"; it is the right tool, and
   here is the evidence).
4. **AGHQ does not fix the df bias.** In Panel A the residual AGHQ bias (−6.7% → −1.6%) is
   the ML-vs-REML gap; it shrinks with M, not with quadrature — consistent with the
   estimator-axis framing (REML for the Gaussian df bias, AGHQ for the non-Gaussian
   integral bias).
5. **On the Arc 2b/2c sweeps.** Those ran at 40 groups × 15/obs — the mild regime (Panel B
   n = 8→20 spans −10%→0). So the −2% to −9% we reported is precisely on the expected
   curve, not an anomaly. A larger design would show ≈0; the small design was chosen to
   *surface* the bias for an honest caveat.

**Caveat:** AGHQ here is glmer's, on a scalar random *intercept* (the case glmer's `nAGQ>1`
supports). The same integral-bias logic applies to the Arc 2b slopes and Arc 2c sigma REs,
but glmer cannot AGHQ-reference a vector/scale RE — a native drmTMB AGHQ path is the future
arc. `boundary (singular)` glmer fits at the smallest cells were dropped via `na.rm`.
