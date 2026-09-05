# A8c root-cause receipt -- DRM.jl #646 on the gaussian_response_mask route

Measured 2026-09-05. Every number below was produced in this run.

Fixture (identical to `tests/testthat/test-julia-missing.R` and to
`row_gaussian_response_mask_data()` in `tools/parity-p2-pilot.R`):

```r
set.seed(1); n <- 60
x <- rnorm(n); y <- 0.3 + 0.5 * x + rnorm(n) * exp(0.1 * x); y[1:6] <- NA
bf(y ~ x, sigma ~ x), family = gaussian(),
missing = miss_control(response = "include")
```

- DRM.jl pin (RED): `drmjl-430ef64cc`
- DRM.jl fix (GREEN): worktree `wt-a8c-drmjl`, branch
  `claude/parity-a8c-response-mask-drmjl`
- drmTMB: worktree `wt-a8c`, branch `claude/parity-a8c-response-mask`

## G1 -- both defects reproduced live at the pin, through the R bridge

```
is_converged(fj)      = FALSE
fj$opt$convergence    = 1
str(fj$opt)           = List of 1 / $ convergence: int 1     <- a bare list
logLik                = -70.5452569967742
nobs                  = 54
coef mu    = (Intercept) 0.3830935   x 0.4654449
coef sigma = (Intercept) -0.1090747  x -0.0282590
bridge$estim_method   = ML
```

`confint(fj, parm = "fixef:mu:x", method = "bootstrap", R = 99)`:

```
Error happens in Julia.
all 99 bootstrap replicates failed
Stacktrace:
 [1] _bootstrap_result(...)  @ DRM .../src/inference.jl:2127
 [2] bootstrap_result(...)   @ DRM .../src/inference.jl:1668
 [3] drmTMB_drm_bridge_fixef_inference(...)  @ Main ./none:0
```

`engine = "tmb"` control on the identical fixture: `is_converged` TRUE,
`opt$convergence` 0, bootstrap `99/99 successful refits`, `bootstrap.failed`
0 for all four targets. The two engines' coefficients agree to the printed
7 decimals.

## G2 -- root cause 1 is a WRONG RETURN-CODE MAPPING, not a tolerance or a near-miss

Probed inside Julia on the same fixture:

| quantity | masked fit (60 rows, 6 NA) | complete-case control (54 rows) |
| --- | --- | --- |
| `fit.converged` (raw `Optim.converged`) | **true** | true |
| `is_converged(fit)` | **false** | **true** |
| `_nondegenerate_fit(fit)` | **false** | true |
| `theta` | identical, max abs diff **0.0** | identical |
| `loglik` | -70.54525699677419 | -70.54525699677419 |
| `|grad|inf` at the optimum | **6.412634312447096e-12** | 6.412634312447096e-12 |
| `g_tol` | 1e-8 | 1e-8 |
| iterations | **-1** (lost) | **7** |
| `smax` = max abs sigma | 0.954574553349397 | 0.954574553349397 |
| `yscale` = `std(fit.obs[:mu])` | **NaN** | 0.9929619129086243 |
| bar `1e-6 * max(yscale, eps)` | **NaN** | 9.929619129086243e-7 |
| `smax > bar` | **false** | true |

The optimiser converged: `|grad|inf` is 6.41e-12 against a `g_tol` of 1e-8,
four orders of magnitude inside tolerance, and the parameter vector is
*bit-identical* to the complete-case fit. The single quantity that differs is
`yscale`, because `fit.obs[:mu]` still holds NaN in the 6 masked positions and
`std` of a NaN-carrying vector is NaN. Under IEEE-754 every `>` against NaN is
false, so `_nondegenerate_fit` returned false for **any** `smax`. Recomputing
the same bar over the observed entries only gives
`smax > 9.93e-7 == true`.

Verdict: a wrong return-code mapping caused by a data-hygiene oversight in
`_nondegenerate_fit` (`src/summary.jl:130-143`). Not a loose tolerance, not a
genuine near-miss, and not an R-side bug -- `R/julia-bridge.R` faithfully
mirrored the Bool Julia sent.

## G3 -- root cause 2 is a length/`nobs` inconsistency inside the fit object

Calling the replicate draw directly on ONE replicate:

```
DRM.simulate(fit; rng = MersenneTwister(20260905))
-> DimensionMismatch: arrays could not be broadcast to a common size;
   got a dimension with lengths 60 and 54
```

`_simulate_once` (`src/gaussian_core.jl`) drew `randn(rng, fit.nobs)` -- 54
values -- and broadcast them against `fit.means[:mu]` and
`fit.scales[:sigma]`, which `_with_full_fixed_gaussian_rows` had rebuilt over
the FULL 60-row design. Measured on the fit object: `nobs = 54`,
`length(means[:mu]) = 60`, `length(scales[:sigma]) = 60`,
`count(isnan, obs[:mu]) = 6`.

The throw is deterministic and identical for every seed, so `failures = :skip`
collected `used = 0` and `_bootstrap_result` raised
`"all $B bootstrap replicates failed"` at `src/inference.jl:2119` (2127 in the
worktree). The mechanism is **wrong response length**, not a lost missing
pattern and not a `Union{Missing,Float64}` type instability: `simulate` fails
before any refit is attempted.

## Which length is correct -- measured against engine = "tmb"

The TMB engine's own parametric bootstrap on this fixture was probed directly:

```
stats::simulate(ft, nsim = 2)      -> 60 rows, 0 NA
bootstrap_response_data(ft, sm, 1) -> 60 rows, 0 NA in y
refit on that data                 -> nobs = 60
```

So drmTMB's established semantics on the masked route is that a replicate
response spans the FULL design and the refit uses all rows; the missing
pattern is deliberately not re-applied. Drawing at the mean-vector length
therefore reproduces the reference engine exactly, and needs no re-masking.

BOUNDARY, stated rather than silently "improved": because replicates refit on
60 rows while the original fit used 54, a parametric bootstrap interval on a
masked fit is very slightly narrower than one that preserved the mask. That is
pre-existing, shared by both engines, and out of this leaf's scope -- changing
it is a cross-engine design decision, not a parity fix.

## Third defect found while fixing these two

`_with_full_fixed_gaussian_rows` used the 19-argument compatibility
constructor, which defaults `phylo_penalty` / `penalty` / `iterations` to
"absent". The masked fit therefore reported `niterations = -1` ("not
recorded") where the identical complete-case fit reported `7`, and the bridge
exports that value as `iterations`. `_with_full_response_rows` -- the
non-Gaussian missing-response rebuilder -- had the same defect and is fixed
with it.

## G6 -- re-qualification against the fixed DRM.jl

See `a8c-g3-requalification-receipt.md` (generated by
`tools/parity-p2-pilot.R --g3-qualify`, A8's mode). For
`gaussian_response_mask`, target `fixef:mu:x`:

```
converged: tmb=TRUE julia=TRUE; julia estimator=ML
wald:      delta = [7.85573e-08, 7.85425e-08]                  (< 1e-6)
profile:   delta = [5.1288e-06, 7.17584e-06]  PASS(tol=1e-4)=TRUE
bootstrap (R=99): tmb failed=0/99, julia failed=0/99, OVERLAP=TRUE
```

`fit_j$estimator` = `ML` and `fj$bridge$estim_method` = `ML` -- they agree.

Bootstrap intervals are reported as OVERLAP-ONLY: the two engines draw from
independent RNG streams, so the bounds are not expected to match numerically.

The other two qualifiable routes are numerically IDENTICAL to A8's receipt
(`base_gaussian_location_scale` wald delta 6.69774e-09 / profile delta
2.79654e-06 / julia bootstrap [-0.739446, -0.544052];
`plain_binomial_nonphylo` wald delta 5.18431e-09 / profile delta 9.35263e-08 /
julia bootstrap [0.368069, 0.551723]). The fix changed the masked route and
nothing else.

## Red controls

DRM.jl, per hunk, reverted in the worktree and restored byte-identically
(`src/summary.jl` sha256
`14a4bcf3c8c74528b946e08fd9258198bc360dda31a5a231cec67a65b69d47a6`,
`src/gaussian_core.jl` sha256
`216e1716f9d0950e3b18062e7be9ee0ea306802a17317dcc7f09035721b821d0` before and
after):

| reverted | result |
| --- | --- |
| `_nondegenerate_fit` NaN guard | FAIL: `_nondegenerate_fit(fit)`, `is_converged(fit)` (19 pass, 2 fail) |
| `_simulate_once` draw length | ERROR: `DimensionMismatch ... lengths 60 and 54` (13 pass, 1 error) |
| 22-arg constructor | FAIL: `niterations(fit) == niterations(fit_cc)`, `niterations(fit) > 0` (19 pass, 2 fail) |

Each hunk is load-bearing and guards distinct assertions; no assertion is
redundant. Fixed state: **21/21 pass**.

drmTMB:

- The new `test-julia-missing.R` block run against the UNFIXED pin FAILS with
  `all 19 bootstrap replicates failed` and the same Julia stack -- the
  assertions have real bite.
- The ledger's own control: with the fixture de-masked (`y[1:6] <- NA`
  removed) the same block PASSES against the UNFIXED pin, confirming the
  assertions bite only on the masked route. Planted and restored
  byte-identically (`tests/testthat/test-julia-missing.R` sha256
  `862fcb6bbe3c5259776b0b037c75117e137f33f9de4562e8d3eaf7ec7a32cf8a` before
  and after). The block keeps `expect_equal(res$n_missing, 6L)` so the fixture
  cannot be silently de-masked in future.

## Suite status

- DRM.jl blast radius (21 files: simulate, every bootstrap file, every
  missing-response file, gaussian core, AIC/BIC): 19 OK.
  Two failures are PRE-EXISTING on the clean worktree with the fix stashed,
  with identical numbers, and are NOT caused by this change:
  `test_bootstrap_marginal.jl` (`res.failed == 0` evaluates `1 == 0`,
  `res.used == 60` evaluates `59 == 60`) and `test_lss_missing_response.jl`
  (`Package StableRNGs not found` -- a missing test dependency in this
  environment).
- drmTMB `filter = "julia"`, pure-R paths: 1304 pass, 0 fail, 0 error.
- drmTMB live against the fixed DRM.jl (bridge / inference / missing /
  diagnostics / bridge-summary): 413 pass, 0 fail, 0 error, 12 live tests ran.
- `tools/capability_ledger.py --check`: `OK (31 generated outputs)`.
- `tools/validate-mission-control.py`: 33 lines, **0 new** versus clean
  `origin/main` (`wt-main-probe`, pulled `--ff-only` in this run).
