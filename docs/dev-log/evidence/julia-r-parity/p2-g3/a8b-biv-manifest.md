# A8b manifest -- biv_gaussian_residual bridge inference (G3 fence)

Committed BEFORE the qualification run (D-139). This is the one route leaf A8
measured as NOT COVERED: through `engine = "julia"`, the residual-only
bivariate Gaussian fit had **no profile or bootstrap target on any parameter**.

## Environment for every run below

```
OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true
DRM_JL_PATH=/Users/z3437171/local-scratch/parity-joint/wt-a8b-drmjl
DRM_JL_PHYLO_PATH=<same>
devtools::load_all("/Users/z3437171/local-scratch/parity-joint/wt-a8b")
threads = FALSE; ONE Julia session per script invocation.
```

`DRM_JL_PATH` points at the A8b DRM.jl worktree, not the 430ef64cc pin,
because the bootstrap half of this leaf needs DRM.jl PR #647. The pin is
retained as the RED baseline (G1) and is what the "before" numbers were
measured on.

## What was measured RED first (G1, on the pin, before any change)

- `profile_targets()` on the julia fit reports `profile_ready = FALSE` and
  `profile_note = "missing_tmb_parameter"` for all 9 rows.
- `confint(fit, parm = "fixef:mu1:x", method = "profile")` and the same call
  with `method = "bootstrap"` are both refused **R-side, before any Julia
  call**, with:

  ```
  Julia-engine target "fixef:mu1:x" is not ready for profile or bootstrap
  intervals.
  i Inventory note: "missing_tmb_parameter".
  ```

- The same two calls on `parm = "fixef:rho12:(Intercept)"` are refused
  identically.

## Route, fixture and targets

| item | value |
|---|---|
| capability_id | `biv_gaussian_residual` |
| fixture | `test/parity/fixtures/gaussian-bivariate-rho12/data.csv` (n = 180, columns y1, y2, x) |
| formula | `bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)` |
| family | `biv_gaussian()` |
| compared targets | `fixef:mu1:x` and `fixef:rho12:(Intercept)` |
| profiled targets | every profile-ready fixed-effect row the inventory offers |

## Committed tolerances

| comparison | bar | why this bar |
|---|---|---|
| Wald, both bounds | 1e-6 | the two engines compute the same closed-form z-interval from the same Hessian; the only difference is optimizer round-off |
| profile, both bounds | 1e-4 | two different endpoint solvers (TMB's `tmbprofile` vs DRM.jl's L-BFGS root search) on the same likelihood; leaf A8 measured 1e-6..7e-6 on its three univariate routes at this bar |
| bootstrap R = 99 | OVERLAP ONLY | no same-seed design exists -- `engine = "tmb"` draws from R's RNG and `engine = "julia"` from a Julia `MersenneTwister`, so the same `seed` value does not produce the same replicates |
| G6(a) red control | 1e-9 | expected a priori to FAIL, proving the profile comparison is live |

## Time estimate (D-139)

Under 15 minutes wall clock for the single qualification invocation: one Julia
session boot (~25 s measured on the G1 run), two fits, at most nine profile
calls through the bridge, and four bootstrap calls at R = 99. No compute target
beyond this laptop; nothing here is a campaign.

## What this cell will NOT claim

- Interval COVERAGE. One fixture, one seed, one target per block.
- Anything about the STRUCTURED (q = 4 / q = 2) bivariate route, whose
  fixed-effect rows stay deliberately not-ready.
- Anything about `meta_V` bivariate fits or a partially observed bivariate
  response; neither is exercised by this fixture.
