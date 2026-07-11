# Track A: CI trio (Wald vs Profile) coverage (2026-07-09)

Wald vs Profile coverage + finite-rate for the coverage-validated unstructured
non-Gaussian cells. n-ladder {60,150,400,800}, 400 seeds, Totoro. Confirmed maps:
beta `phi = exp(-2*log_sigma)`, nbinom2 `size = exp(-2*log_sigma)`.

## Findings

1. **Mean coefficients stay calibrated across the whole n-ladder** (binomial /
   poisson / beta / nbinom2, incl. a 2-covariate Poisson robustness case):
   Wald coverage 0.93-0.97, finite-rate 1.0. Confirms and extends the 0.4.0 claim.

2. **Profile is the correct channel for nbinom2 dispersion coefficients.** The
   Wald interval for `fixef:sigma:*` is UNRELIABLE at small n — mean width 1517 at
   n=60, 319 at n=150 (the dispersion SE explodes under weak small-n identifiability;
   coverage is only ~0.95-0.98 because the absurd interval trivially covers). PROFILE
   gives sane widths (5.1 at n=60, 1.2 at n=150) with coverage 0.93-0.97. This is the
   #682 thesis confirmed: feature profile where Wald is suspect. (Profile finite-rate
   dips to ~0.88 at n=60 — a few profiles don't close at very small n; use bootstrap
   fallback there.)

3. **beta location-scale has a large-n fit-stability limitation.** finite-rate
   degrades with n: 0.995 (n60) -> 0.993 (n150) -> 0.955 (n400) -> **0.907 (n800)**,
   failing the 0.95 floor at n=800. Profile does NOT rescue it (same finite-rate) —
   the failure is at the FIT level, not the interval method. Needs root-causing
   (likely a boundary/optimizer issue as phi grows). Document as a beta-LS large-n
   caveat until fixed.

## Actionables
- Update the vignette interval guidance: prefer `method="profile"` for nbinom2
  dispersion (`sigma`) coefficients; note Wald over-widths at small n.
- Investigate the beta-LS large-n finite-rate drop (a real limitation).
