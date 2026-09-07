# Bridge-axis receipts and fences for three accessor suites

**Date measured:** 2026-09-05
**DRM.jl commit:** `aee371cc9627c24945859f4caa749e0d5b691782` (parked reference
checkout `/Users/z3437171/local-scratch/parity-joint/drmjl-ref-aee371cc`)
**drmTMB branch:** `claude/parity-uncited-accessors` off `origin/main`
**Engine env:** `OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true NOT_CRAN=true`
**Julia:** 1.10.0

**The programme pin `430ef64cc` was NOT used.** It predates DRM.jl #646 and
#648 and two other leaves measured it unusable on the night of 2026-09-05.
Every number below was measured at `aee371cc9`. A number without its commit is
not evidence, so the commit is repeated beside each table.

## Why this document exists

Three capability rows shipped as native R functions on 2026-09-05 --
`chibar_pvalue()`/`lrt_boundary()`, the `aicc()`/`lrtest` model-comparison
suite, and the heritability/ICC accessors -- each ported term-for-term from
`DRM.jl`. Both engines therefore HAVE the capability. What no one had checked
is the **bridge axis**: whether the accessor is reachable at all when the fit
came back through `engine = "julia"`, and whether the R port agrees with the
Julia original on the same numbers. These are pure functions of a fitted
object, so the comparison is cheap: one fixture, both engines, plus DRM.jl's
own accessor on the same payload as the oracle.

## Fixture

Gaussian random intercept, `set.seed(20260905)`, `G = 30` groups of `m = 12`,
`n = 360`:

```r
dat <- data.frame(y = 0.5 - 0.4 * x + b[g] + 0.7 * rnorm(360), x = x, g = g)
full    <- bf(y ~ x + (1 | g), sigma ~ 1)   # 4 parameters
reduced <- bf(y ~ x,           sigma ~ 1)   # 3 parameters
```

Both models fitted under `engine = "tmb"` and `engine = "julia"`; all four
converged (`is_converged()` TRUE).

## 1. Same-target agreement between the two engines (the premise)

DRM.jl `aee371cc9`. Every accessor number below inherits this agreement, so it
is stated first.

| Model | max abs coef diff | abs logLik diff | max abs SE diff |
|---|---|---|---|
| full (`y ~ x + (1 \| g)`) | 3.949e-12 | 9.493e-12 | < 1e-6 over 3 shared targets |
| reduced (`y ~ x`) | 6.911e-15 | 5.684e-13 | < 1e-6 over 3 shared targets |

logLik full: `-424.2590794883` (both engines). logLik reduced:
`-563.1040832046` (both engines). `df` 4 / 3 and `nobs` 360 identical.

Random-intercept SD: tmb `0.934156435178773`, julia `0.934156435182997`
(diff 4.2e-12). Residual sigma: tmb `0.689989662480851`, julia
`0.689989662480147`.

**Boundary noted, not hidden:** the two engines spell `vcov()` dimnames
differently -- `mu:(Intercept)`, `mu:x` natively against `mu_(Intercept)`,
`mu_x` through the bridge. The `_` spelling is the entrenched bridge
convention and is asserted by existing tests
(`tests/testthat/test-coefficient-labels.R:293`,
`tests/testthat/test-julia-family-cumulative_logit.R:201`), so it is reported
here and NOT changed. `coef()` block names agree on both engines. SEs are
therefore compared by position after checking the two orderings agree term for
term.

## 2. RECEIPT -- Chi-bar-square boundary LRT p-value

### 2a. `chibar_pvalue()`: a pure function, compared exactly

`chibar_pvalue()` takes a statistic and `q`, so it needs no fit at all and is
engine-independent by construction. Compared against DRM.jl `src/chibar.jl`
`chibar_pvalue` on an 11-point grid including both boundary cases and a
negative statistic:

| q | max abs diff, R port vs DRM.jl |
|---|---|
| 1 | 7.633e-17 |
| 2 | 8.327e-17 |

Grid: `0, 1e-8, 0.25, 1, 2.7055, 3.5, 5.9915, 10, 25, 100, -1.5`. Boundary
point masses reproduce exactly: `chibar_pvalue(0, 1) = 0.5`,
`chibar_pvalue(0, 2) = 0.75`; a negative statistic clamps to the same values on
both sides. Agreement is at machine epsilon, i.e. the two implementations are
the same function.

### 2b. `lrt_boundary()` IS reachable through `engine = "julia"`

`drm_validate_lrt_boundary_fit()` admits `drmTMB_julia`, and every field the
test reads (`logLik`, `df`, `nobs`, `estimator`, `REML`, `coefficients`) is on
the bridge object. Measured, DRM.jl `aee371cc9`:

| Quantity | R port on julia fits | R port on tmb fits | DRM.jl's own `lrt_boundary` |
|---|---|---|---|
| statistic | 277.6900074326 | 277.6900074326 | 277.6900074326 |
| pvalue | 1.1966327035e-62 | 1.1966327035e-62 | 1.1966327035e-62 |
| pvalue_naive | 2.3932654071e-62 | 2.3932654071e-62 | 2.3932654071e-62 |
| q / df | 1 / 1 | 1 / 1 | 1 / - |

Differences: julia vs tmb max 2.012e-11 across all five fields; julia vs
DRM.jl's own 0.000e+00 on the statistic, 1.986e-76 on `pvalue`, 3.973e-76 on
`pvalue_naive`. Absolute tolerances are vacuous at p ~ 1e-62, so the banked
test also asserts agreement on the log scale.

**Banked at** `tests/testthat/test-lrt-boundary.R`, test
`"lrt_boundary reaches engine = 'julia' fits and agrees with tmb and DRM.jl"`.
The pre-existing live block in that file compares the R port to DRM.jl with
the R side fitted NATIVELY; it never exercised a bridge object. That is the
gap this closes.

## 3. RECEIPT -- Model comparison suite, and two written boundaries

DRM.jl `aee371cc9`, same fixture.

| Verb | Bridge axis verdict | Measured |
|---|---|---|
| `aicc()` | **REACHES** `engine = "julia"` via `aicc.default()` | 856.6308350330 == DRM.jl `aicc` to 0.000e+00; vs `aicc(tmb_fit)` 1.899e-11. Reduced model: 1132.2755821396, same agreement. |
| `lrtest` | **REACHES**, but the R verb is INTERNAL | `drm_lrtest(fj_red, fj_full)`: statistic 277.6900074326, df 1, p 2.393265e-62 -- identical to DRM.jl `lrtest(reduced, full)`. Not exported, not wired into `anova()`. |
| `anova()` | **BOUNDARY** (deliberate refusal, both engines) | `anova.drmTMB()` has always refused. `anova(julia_fit)` had NO method and failed with a bare `UseMethod` error; `anova.drmTMB_julia()` now gives the same refusal. |
| `weights()` | **DEFECT FIXED** | Returned `NULL` SILENTLY via `stats:::weights.default`, while `weights(tmb_fit)` on the same unweighted model returns 360 ones and DRM.jl's `weights(fit)` returns `ones(nobs)` (measured: length 360, all one). `weights.drmTMB_julia()` now returns ones. |
| `update()` | REACHES both engines | base R's refit verb; re-evaluates the call. No port needed. |

`aicc()` works on the bridge because `logLik.drmTMB_julia()`
(`R/julia-bridge.R:5196`) attaches both `df` and `nobs`; `aicc.default()` reads
exactly those two attributes. No `drmTMB_julia` method is needed and none was
added.

**Banked at** `tests/testthat/test-model-comparison.R`: the live test
`"aicc() reaches an engine = 'julia' fit and matches tmb and DRM.jl"` plus two
Julia-free dispatch tests for the `anova()` and `weights()` fences.

## 4. WRITTEN BOUNDARY -- Heritability / repeatability / ICC

### What the native axis cites, and whether it is still true

The row read `point-fit-recovery`, citing `docs/design/capability-status.md`:
the accessors recover a known variance ratio across seeded simulations and
report a delta-method Wald interval carrying only a small-N sanity check, no
calibrated coverage study. **Re-checked 2026-09-05: still true.** On the
fixture above, `heritability(tmb_fit)` returns estimate `0.647012871707612`,
se `0.06444`, 95% CI `[0.5207, 0.7733]`. No coverage campaign exists, and none
was run here (D-139: it is not a sub-30-minute job).

### The bridge axis: fenced, and why

`drm_variance_ratio()` is a delta-method ratio on the **working (log-SD)
scale**. It reads `object$opt$par` -- which carries `log_sd_mu` and
`beta_sigma` -- and the TMB `sdreport` joint covariance of those working
parameters, then applies the Jacobian of
`exp(2 log_sd) / (sum exp(2 log_sd) + exp(2 beta_sigma))`.

A `drmTMB_julia` fit exposes **neither**:

* `drm_julia_opt_slot()` (`R/julia-bridge.R`) stores only `convergence`,
  `iterations` and `message`. Measured: `fj$opt$par` is `NULL`.
* the public `object$vcov` is SUBSET to the fixed-effect coefficients; the
  structured `resd_*` log-SD row and column are dropped on the way out.
  Measured: public dimnames are `mu_(Intercept)`, `mu_x`, `sigma_(Intercept)`
  -- `resd_g` is gone.

Before this change the call therefore produced a bare `UseMethod` dispatch
error naming nothing. `heritability.drmTMB_julia()`, `icc.drmTMB_julia()` and
`repeatability.drmTMB_julia()` now abort with class
`drmTMB_variance_ratio_julia_unsupported`, naming what is missing and telling
the user to refit with `engine = "tmb"`.

### This is "not wired", not "not possible" -- and the measurement says so

DRM.jl `aee371cc9`. One layer down, the ingredients ARE present.
`drm_julia_vcov(fj$bridge$vcov, fj$bridge$coef_names)` returns the FULL 4x4
**working-scale** covariance, which is TMB's `sdreport` `cov_fixed` renamed:

| | tmb `sdreport` cov_fixed | julia full bridge vcov |
|---|---|---|
| names | `beta_mu`, `beta_mu`, `beta_sigma`, `log_sd_mu` | `mu_(Intercept)`, `mu_x`, `sigma_(Intercept)`, `resd_g` |
| [1,1] | 3.041085e-02 | 3.041085e-02 |
| [2,2] | 1.476632e-03 | 1.476632e-03 |
| [3,3] | 1.515337e-03 | 1.515338e-03 |
| [4,4] (log-SD) | 1.824453e-02 | 1.824454e-02 |
| [3,4] | -7.103517e-05 | -7.103509e-05 |

And the h2 **point** formed by hand from the bridge fit's `sdpars`/`sigma()`:

| Quantity | Value |
|---|---|
| h2 by hand, julia `sdpars`/`sigma()` | 0.647012871710144 |
| h2 by hand, tmb `sdpars`/`sigma()` | 0.647012871707612 |
| `heritability(tmb_fit)$estimate` | 0.647012871707612 |
| abs diff, hand-julia vs `heritability(tmb_fit)` | 2.532e-12 |

**The scale check the brief asked for.** `resd_g` is a log-SD:
`log(0.934156435182997) = -0.0681114`, which is exactly TMB's `log_sd_mu`
optimum `-0.06811137`. Both engines are on the same working scale, so a future
wiring would not hit the "agree on the point, differ in the ratio" failure --
but that is a claim about the FIXTURE measured here, not a general one.

### What a wiring would still need (not done here, deliberately)

1. A name map from drmTMB's component labels (`(1 | g)`, `phylo`, `animal`,
   `relmat`, `spatial`) to DRM.jl's `resd_*` / `recov_*` spelling.
2. The structured-SD scale conversion the bridge already applies elsewhere
   (tree height, #693) -- the coevolution accessors do this; a phylogenetic
   h2 would need it too and the Gaussian `(1 | g)` fixture measured here does
   NOT exercise it.
3. The same guards the native path carries: random slopes rejected, constant
   residual scale required, Gaussian `model_type` only.

Half-wiring this is worse than fencing it, so it is fenced. That is the
finding, not a failure to try.

## 5. Coevolution accessors: already cited, checked not re-measured

`coevolution_cor()` / `coevolution_vc()` / `coevolution_summary()` already
carry a bridge route (`drm_coevolution_sigma_a_julia()`), a documented
tree-height scale convention, and a live three-tier test
(`tests/testthat/test-coevolution-accessors.R`) that compares the R port on an
`engine = "julia"` fit against DRM.jl's own accessors on the same payload. That
file was run green in this session but the q4 fixture was NOT re-measured
independently here; its receipts stand on their own test. Confirmed reachable
in passing: `coevolution_cor()` on the univariate Gaussian fixture above
refuses with the documented q = 4 message, not a dispatch error.

## 6. Reproduce

```sh
OPENBLAS_NUM_THREADS=1 NOT_CRAN=true DRMTMB_JULIA_TESTS=true \
  DRM_JL_PATH=<DRM.jl checkout at aee371cc9> \
  DRM_JL_PHYLO_PATH=<same> \
  R -q -e 'devtools::load_all("."); testthat::test_local(
    filter = "heritability|model-comparison|lrt-boundary|coevolution-accessors")'
```

Run 2026-09-05: all green, 6 live Julia tests ran, 0 failures. The two live
blocks print their receipts to stdout:

```
[lrt_boundary BRIDGE] julia stat=277.6900074326 p=1.19663270353e-62 | tmb stat=277.6900074326 p=1.19663270351e-62 | DRM.jl stat=277.6900074326 p=1.19663270353e-62 | |dstat| julia-tmb=2.01e-11 julia-DRM.jl=0.00e+00
[aicc BRIDGE] julia=856.6308350330 tmb=856.6308350329 DRM.jl=856.6308350330 | |d julia-tmb|=1.90e-11 |d julia-DRM.jl|=0.00e+00
```

## 7. Red control for every negative claim

Three negative claims are made above: `heritability(julia_fit)`,
`anova(julia_fit)` and `weights(julia_fit)` were broken or silent before this
change. Each was verified by planting the defect -- renaming the five new S3
methods so dispatch cannot find them -- and re-running the Julia-free tests.
Removing the `S3method()` lines from `NAMESPACE` alone is NOT a valid plant:
`devtools::load_all(export_all = TRUE)` leaves the functions visible by name,
so dispatch still finds them and the tests stay green. Renaming the
definitions is the plant that bites. Verbatim failures:

```
-- 1. Error ('test-heritability.R:253:5'): heritability/icc/repeatability refuse
Error in `UseMethod("heritability")`: no applicable method for 'heritability' applied to an object of class "drmTMB_julia"

-- 2. Error ('test-model-comparison.R:221:3'): anova() refuses an engine = 'juli
Error in `UseMethod("anova")`: no applicable method for 'anova' applied to an object of class "drmTMB_julia"

-- 3. Failure ('test-model-comparison.R:236:3'): weights() on an engine = 'julia
Expected `w` to have type "double".
Actual type: "NULL"

-- 4. Failure ('test-model-comparison.R:237:3'): weights() on an engine = 'julia
Expected `w` to have length 7.
Actual length: 0.
```

Restored byte-identically afterwards (`shasum -a 256 -c`: `NAMESPACE`,
`R/heritability.R`, `R/model-comparison.R` all OK).

## 8. What this does NOT cover

* No coverage or calibration claim for any interval, on either engine.
* One fixture, one seed, `n = 360`, Gaussian `(1 | g)` only. No phylogenetic,
  spatial, `relmat`, bivariate or non-Gaussian cell was measured on these
  accessors.
* `q = 2` `lrt_boundary` was NOT measured on the bridge axis; the crossed
  two-intercept fixture in `test-lrt-boundary.R` is native-only.
* REML was not exercised on the bridge axis for any of these three suites.
* The heritability/ICC bridge route is FENCED, not implemented. The
  feasibility measurement in section 4 is evidence that wiring is possible on
  this fixture, not a claim that a wiring would be correct anywhere else.
* No multi-seed, no simulation recovery, no bootstrap.
