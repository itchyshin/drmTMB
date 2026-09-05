# A8b G3 qualification receipt -- biv_gaussian_residual bridge inference

Measured 2026-09-05 13:23:18 MDT. Every number below is from this run.

- route: `biv_gaussian_residual`; fixture `gaussian-bivariate-rho12` (n = 180), formula `bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)`, `family = biv_gaussian()`
- DRM.jl checkout: `/Users/z3437171/local-scratch/parity-joint/wt-a8b-drmjl`
- tolerances: Wald 1e-06, profile 0.0001; bootstrap R = 99, seed = 20260905
- fits: tmb 0.25 s (converged = TRUE); julia 30.85 s (converged = TRUE)

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

- wald:    tmb [0.2052308029, 0.4974051478]  julia [0.2052305063, 0.4974046901]  delta [2.96678e-07, 4.57625e-07]  PASS(1e-06) = TRUE
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

## What this receipt does NOT claim

- NOT interval coverage. One fixture, one seed, one target per block.
- NOT a claim about the STRUCTURED (q = 4 / q = 2) bivariate route,
  whose fixed-effect rows remain deliberately not-ready.
- NOT a claim about `meta_V` bivariate fits or a partially observed
  bivariate response: neither is exercised by this fixture.
