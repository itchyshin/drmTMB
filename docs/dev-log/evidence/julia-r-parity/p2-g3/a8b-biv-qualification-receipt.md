# A8b G3 qualification receipt -- biv_gaussian_residual bridge inference

Measured 2026-09-05 13:59:53 MDT. Every number below is from this run.

- route: `biv_gaussian_residual`; fixture `gaussian-bivariate-rho12` (n = 180), formula `bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)`, `family = biv_gaussian()`
- DRM.jl checkout: `/Users/z3437171/local-scratch/parity-joint/wt-a8b-drmjl`
- tolerances: Wald 1e-06, profile 0.0001; bootstrap R = 99, seed = 20260905
- fits: tmb 0.27 s (converged = TRUE); julia 52.39 s (converged = TRUE)

## G5 -- estimator honesty (oracle read)

- `fit_julia$estimator` = `ML`
- `fit_julia$bridge$estim_method` = `ML`
- identical: **TRUE**
- `fit_tmb$estimator` = `ML`

## G3 -- target inventory and per-target profile through engine = "julia"

`profile_targets()` on the julia fit: 9 rows, 7 profile-ready, of which 7 fixed-effect.

| parm | profile lower | profile upper | conf.status | finite |
|---|---|---|---|---|
| `fixef:mu1:(Intercept)` | 0.0759530337 | 0.3408818355 | profile | TRUE |
| `fixef:mu1:x` | 0.1988932764 | 0.4607075373 | profile | TRUE |
| `fixef:mu2:(Intercept)` | -0.3310391080 | -0.0130647782 | profile | TRUE |
| `fixef:mu2:x` | 0.2394951308 | 0.5537313090 | profile | TRUE |
| `fixef:rho12:(Intercept)` | 0.2049705593 | 0.4976646375 | profile | TRUE |
| `fixef:sigma1:(Intercept)` | -0.2030959396 | 0.0037474416 | profile | TRUE |
| `fixef:sigma2:(Intercept)` | -0.0205864011 | 0.1862569800 | profile | TRUE |

G3 PASS (a non-empty ready set, every member profiling to a finite interval): **TRUE**

## G4 -- same-target agreement vs engine = "tmb"

### `fixef:mu1:x`

- wald:    tmb [0.1995910886, 0.4600097251]  julia [0.1995910886, 0.4600097251]  delta [3.43336e-14, 3.43059e-14]  PASS(1e-06) = TRUE
- profile: tmb [0.1988954227, 0.4607053910]  julia [0.1988932764, 0.4607075373]  delta [2.14626e-06, 2.14626e-06]  PASS(0.0001) = TRUE
- bootstrap (R = 99): tmb [0.189390, 0.454525] (failed 0/99) julia [0.233072, 0.447526] (failed 0/99) -- OVERLAP ONLY = TRUE

### `fixef:rho12:(Intercept)`

- wald:    tmb [0.2052308029, 0.4974051478]  julia [0.2052305063, 0.4974046901]  delta [2.96678e-07, 4.57625e-07]  PASS(1e-06) = TRUE  pred_guard_offset = 3.77138e-07
- profile: tmb [0.2049770097, 0.4976589741]  julia [0.2049705593, 0.4976646375]  delta [6.45039e-06, 5.66339e-06]  PASS(0.0001) = TRUE
- bootstrap (R = 99): tmb [0.224018, 0.484242] (failed 0/99) julia [0.216558, 0.499635] (failed 0/99) -- OVERLAP ONLY = TRUE

G4 Wald PASS (all targets, tol 1e-06): **TRUE**

G4 profile PASS (all targets, tol 0.0001): **TRUE**

The bootstrap comparison is DISTRIBUTIONAL OVERLAP ONLY. There is no
same-seed design: `engine = "tmb"` draws replicates from R's RNG and
`engine = "julia"` from a Julia `MersenneTwister`, so the same `seed`
value does not produce the same replicates. Overlap is the strongest
claim these two numbers support.

## G6(a) -- RED CONTROL: profile tolerance tightened to 1e-09

- `fixef:mu1:x`: profile delta [2.14626e-06, 2.14626e-06] -> PASS(1e-09) = FALSE
- `fixef:rho12:(Intercept)`: profile delta [6.45039e-06, 5.66339e-06] -> PASS(1e-09) = FALSE

At least one target FAILS at 1e-09: **TRUE** (the comparison is live, not vacuous).
`tol_red` is a script parameter, not committed state, so nothing was
edited and nothing needs restoring for this control.

## rho12 is compared across a guard-constant reparameterisation

`fixef:rho12:(Intercept)` is the atanh-link coefficient on both engines, but
each engine keeps the natural correlation off the +/-1 boundary with a
different guard constant:

- TMB: `rho12 = Type(0.999999) * tanh(eta_rho12)` --
  `src/drmTMB.cpp:679` (the `model_type == 95` RE-covariance-probe branch)
  and `src/drmTMB.cpp:4642` (the plain `model_type %in% c(2, 19, 20)`
  branch this fixture's fit uses). `G_tmb = 0.999999`.
- DRM.jl: `const RHO_GUARD = 0.99999999` --
  `src/sparse_aug_plsm.jl:23`, used by `gaussian_bivariate.jl` and the rest
  of the bivariate kernels. `G_jl = 0.99999999`.

For the same natural correlation `rho`, each engine reports
`eta(rho, G) = atanh(rho / G)` as the linear-predictor coefficient. Since
`G_tmb < G_jl`, dividing by the smaller `G_tmb` gives the larger argument to
`atanh`, so TMB reports the larger `eta` for the same `rho`:

```
offset(rho) = eta(rho, G_tmb) - eta(rho, G_jl)
            = atanh(rho / G_tmb) - atanh(rho / G_jl)
```

Using this fit's TMB Wald interval on `fixef:rho12:(Intercept)`
(`[0.2052308029, 0.4974051478]`), the point estimate is the interval
midpoint `eta_hat = 0.35131797535`, which back-transforms through the TMB
guard to the fitted natural correlation `rho_hat = 0.999999 * tanh(eta_hat)
= 0.3375435365619846` (the `|rho12| ~ 0.3375` quoted for this fixture,
before the extra decimal digits the guard reparameterisation adds).

Predicted offset at that `rho_hat`:

```
atanh(0.3375435365619846 / 0.999999) - atanh(0.3375435365619846 / 0.99999999)
  = 3.7713793e-07
```

Measured point gap (`eta_hat_tmb - eta_hat_jl`, from the two engines' Wald
midpoints) at this fit: `3.5131797535e-01 - 3.5131759820e-01 = 3.7715e-07`.
Predicted `3.77138e-07` vs measured `3.77151e-07` -- agreement to 4
significant figures. The `fixef:rho12:(Intercept)` Wald-endpoint deltas
recorded above (`2.96678e-07`, `4.57625e-07`) straddle this same predicted
offset (a symmetric Wald interval shifts both endpoints by very nearly the
same amount as the point estimate, so the two endpoint deltas differ from
the point-gap prediction only at the next order).

**This rho12 gap is entirely the guard-constant reparameterisation, and is
NOT solver agreement of the kind `fixef:mu1:x` shows** (delta `3.43e-14` on
a target neither engine reparameterises).

A third convention exists in drmTMB's own bridge: `R/julia-bridge.R:5149`,
inside `drm_julia_residual_rho12_corpair()`, back-transforms with
`atanh(pmax(pmin(rho, 1 - 1e-12), -1 + 1e-12))` -- guard effectively 1. See
[itchyshin/drmTMB#1190](https://github.com/itchyshin/drmTMB/issues/1190)
for the cross-engine tracking issue on reconciling the three.

## The G4 Wald bar for rho12 is fixture-conditional, not a general parity claim

The offset above is `atanh(rho/G_tmb) - atanh(rho/G_jl)`, well approximated
(both guards are within `1e-8` of 1) by a first-order expansion in
`(1 - G)`:

```
offset(rho) ~= (G_jl - G_tmb) * rho / (1 - rho^2) = 9.9e-07 * rho / (1 - rho^2)
```

(verified against the exact form above: `9.9e-07` is the coefficient
Fisher predicted, and the approximation tracks the exact value to 4
significant figures across the whole table below). Predicted offset at
several correlations:

| \|rho12\| | exact offset | first-order approx |
|---|---|---|
| 0.3375 | 3.7708e-07 | 3.7708e-07 |
| 0.5    | 6.6000e-07 | 6.6000e-07 |
| 0.62   | 9.9708e-07 | 9.9708e-07 |
| 0.8    | 2.2000e-06 | 2.2000e-06 |
| 0.9    | 4.6895e-06 | 4.6895e-06 |
| 0.99   | 4.9254e-05 | 4.9251e-05 |

The offset crosses the committed 1e-6 Wald bar near `|rho12| ~ 0.6208`, and
reaches `~4.93e-05` at `rho12 = 0.99` -- 49x the bar. **The 1e-6 rho12 Wald
PASS recorded in G4 above is conditional on this fixture's weak correlation
(`|rho12| ~ 0.34`) and is NOT a general parity claim on the rho12 axis until
the guard constants agree** (tracked at
[itchyshin/drmTMB#1190](https://github.com/itchyshin/drmTMB/issues/1190)).
A future bivariate fixture with `|rho12| > ~0.62` would fail this same bar
for this reason alone, with no solver disagreement underneath it.

`tools/parity-p2-pilot.R --g3-qualify-biv` now prints the predicted offset
next to the rho12 delta at fit time; re-run 2026-09-05:

```
[13:59:53]   compare fixef:rho12:(Intercept)      wald d=[2.967e-07, 4.576e-07] profile d=[6.450e-06, 5.663e-06] overlap=TRUE pred_guard_offset=3.77138e-07
```

## What this receipt does NOT claim

- NOT interval coverage. One fixture, one seed, one target per block.
- NOT a claim about the STRUCTURED (q = 4 / q = 2) bivariate route,
  whose fixed-effect rows remain deliberately not-ready.
- NOT a claim about `meta_V` bivariate fits or a partially observed
  bivariate response: neither is exercised by this fixture.
