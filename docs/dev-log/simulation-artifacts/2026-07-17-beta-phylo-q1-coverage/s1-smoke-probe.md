# S1 — confint(profile) smoke + runtime probe (Beta phylo q1 direct-SD coverage arc)

**Local machine, R 4.6.0, TMB 1.9.21, `pkgload::load_all()` of a9b2633c worktree.**
Two single fits via the existing runner DGP + fit path (`tools/run-beta-phylo-q1-sd-interior-recovery.R`
→ predecessor `run-beta-phylo-q1-sd-regression-recovery.R`), frozen-design seeds.

## Working confint invocation (CONFIRMED)

```r
confint(fit,
        parm   = c("fixef:sd_phylo(spp_id):(Intercept)", "fixef:sd_phylo(spp_id):x_tau"),
        method = "profile")   # -> profile.engine = tmbprofile (slow full-curve); conf.status = profile
confint(fit, parm = <same>, method = "wald")   # ~instant
```
Returns a data.frame with `parm, level, lower, upper, scale(=link), method, profile.engine,
conf.status, profile.boundary, profile.message`. For these fixed-effect / `linear_predictor`
targets `profile.boundary = FALSE`, `profile.message = "ok"`.

## Intervals (finite, in-range; truth alpha0=log0.30≈-1.204, alpha1=0.25)

| cell (seed) | coef | Wald | Profile |
| --- | --- | --- | --- |
| g256,m2 distinct (2079989999) | Intercept | [-1.31963, -0.50519] | [-1.31295, -0.50579] |
| | x_tau | [0.20388, 0.46281] | [0.20959, 0.47031] |
| g1024,m4 distinct (2079939999) | Intercept | [-1.36722, -0.83380] | [-1.37083, -0.83812] |
| | x_tau | [0.13460, 0.26372] | [0.13573, 0.26457] |

Point estimates: g256 Intercept -0.91241 / x_tau 0.33335; g1024 Intercept -1.10051 / x_tau 0.19916.

## Timings (system.time elapsed, seconds)

| cell | fit | Wald confint | **profile confint (both coeffs)** |
| --- | --- | --- | --- |
| g256, m2 | 3.05 | 0.16 | **157.5** |
| g1024, m4 | 28.92 | 0.40 | **1456.1  (24.3 min)** |

## Key findings

1. **Profile wiring works** with no new plumbing (rides the generic fixed-effect path →
   `beta_sd_mu`), finite intervals, clean boundary/message.
2. **Full-curve `tmbprofile` is the only expensive step** and scales ~10× g256→g1024
   (157 s → 1456 s). Fits (29 s) and Wald (0.4 s) are cheap.
3. **Wald ≈ profile to ~0.003 at BOTH g** — as predicted for unbounded linear-predictor
   coefficients with no SD=0 boundary. Profile coverage will closely track Wald; the profile
   campaign is confirmatory (and demonstrates method-robustness), not a different signal.

## Campaign-sizing consequence

Promotion-arm profile at N≈1000 (2 arms) ≈ 2·1000·24.3 min ≈ **810 core-hours**. Decision
(per user): full profile at high N on the promotion arms. Venue: **DRAC fir** (reachable,
~57k idle cores, no MFA this session) if the build reproduces (Grace's gate), else **Totoro
overnight** (ready, same env as the point campaign). Wald full grid + context profile at lower N
are cheap add-ons either way.
