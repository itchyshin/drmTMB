# Arc 4a — profile interval vs Wald for the RE-SD (Totoro)

> **Superseded evidence — do not use for a capability claim.** This retained
> centered-v1 campaign subtracted each simulated random-effect sample mean but
> scored coverage against the unadjusted population SD. That estimand mismatch
> invalidates its promotion recommendation. The corrected IID campaign and
> auditable raw results are documented in `README-profile-iid-v2.md`.

**Date:** 2026-07-13 · **Compute:** Totoro, 80 cores, drmTMB 0.6.0.9000 · **Design:** 3 specs ×
M ∈ {8,16,32,64} × 600 sims = 7,200 fits, all converged. Generator: `generate-profile.R`.
Data: `profile-coverage-results.tsv`. Follows the DG3 Wald finding (`README.md`).

## Result

| spec | M | Wald cov | Wald ∞-rate | **Profile cov** | Profile finite | Profile fail |
|---|--:|--:|--:|--:|--:|--:|
| gaussian slope | 8 | 0.993 | 0.025 | **0.918** | 1.000 | 0.000 |
| gaussian slope | 16 | 0.967 | 0.002 | **0.940** | 1.000 | 0.000 |
| gaussian slope | 32 | 0.938 | 0.000 | **0.933** | 1.000 | 0.000 |
| gaussian slope | 64 | 0.930 | 0.000 | **0.928** | 1.000 | 0.000 |
| binomial slope | 8 | 0.937 | 0.002 | **0.907** | 1.000 | 0.000 |
| binomial slope | 16 | 0.912 | 0.000 | **0.907** | 1.000 | 0.000 |
| binomial slope | 32 | 0.942 | 0.000 | **0.943** | 1.000 | 0.000 |
| binomial slope | 64 | 0.945 | 0.000 | **0.950** | 1.000 | 0.000 |
| lognormal sigma | 8 | 0.997 | 0.047 | **0.905** | 1.000 | 0.000 |
| lognormal sigma | 16 | 0.980 | 0.002 | **0.935** | 1.000 | 0.000 |
| lognormal sigma | 32 | 0.932 | 0.000 | **0.917** | 1.000 | 0.000 |
| lognormal sigma | 64 | 0.942 | 0.000 | **0.938** | 1.000 | 0.000 |

## What it means

1. **The profile interval fixes the ∞-width defect completely.** `profile_finite_rate = 1.000`
   and `profile_failed_rate = 0.000` in all 12 cells — every profile interval is bounded, where
   2.5–4.7% of Wald intervals at M=8 diverged to `[x, ∞)` (lognormal's mean Wald width at M=8 was
   328; profile 0.55). This is a real correctness improvement and validates D-12's featured method.
2. **Profile reveals the honest small-M coverage.** The Wald "over-coverage" at M=8 (0.99+) was an
   artifact of the ∞-upper intervals; the finite profile shows the true coverage is ~0.905–0.918
   at M=8 — below nominal, driven by the residual downward point-bias (which changing the interval
   method cannot fix).
3. **The old apparent M pattern is not a certified floor.** The centered-v1
   estimand defect means these values cannot authorize any tier or extrapolation.
4. **binomial is point-bias-limited, as predicted.** Profile ≈ Wald coverage at every M — the
   interval construction was never binomial's problem; its residual gap is the integral bias that
   **AGHQ** removes (see the Laplace-vs-AGHQ study). Profile still helps it by removing the ∞-width.

## Promotion recommendation withdrawn

No cell may be promoted from this centered-v1 result. See
`README-profile-iid-v2.md` for corrected IID evidence and the discrete claim
domains submitted to fresh D-43 review.
