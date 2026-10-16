# New issue intended for itchyshin/drmTMB

GitHub write from this cloud task may return 403. Paste this if posting by hand.

Title: [sweep-oct16 t7] engine="julia" refuses R offset() in bf(); log-2 identity unscored on the bridge

Refs #1565, Refs #1097, Refs #467, Refs #727. Do not close those issues.

## Summary

After PR #1565 stopped the JuliaCall SIGSEGV (R exit 139), every t7 `engine="julia"` formula-`offset()` cell completes with a **loud Julia `ArgumentError`**. Native `engine="tmb"` on the same tables PASSES the log-2 intercept-shift bar. Native DRModels.jl `drm()` can parse `offset()` (Poisson FE PASSES; NB2/Gamma FAIL as #1097). The R→Julia **bridge** cannot express a fixed (non-estimated) offset coefficient, so `bf(y ~ x + offset(off))` is inexpressible on `engine="julia"`.

Not #1097 (silent free offset coef in native `drm()`). Not #727 (that closed when native Julia gained `offset()`). Not #467 (closed as “reject with a sharper reason”; this is the live user-facing gap that refuse now exposes).

## Expected

`drmTMB(bf(y ~ x + offset(off)), family = poisson(link = "log"), data = d, engine = "julia")` either (a) fits with the same log-2 identity as `engine="tmb"` (intercept drops by `log(2)` to 1e-8, logLik unchanged to 1e-6), or (b) refuses in **R** before Julia starts, with a drmTMB-worded next step.

## Actual

Julia starts (`drm_julia_setup` / first call ~58 s). The bridge translator then throws:

```
Error happens in Julia.
ArgumentError: drmTMB(engine="julia"): R's `offset(...)` is unsupported via engine="julia"; it needs a fixed (non-estimated) coefficient that formula translation cannot express here.
```

Thrown from DRModels.jl `src/bridge.jl:1571` via `_BRIDGE_REJECT_CALLS[:offset]` at `:921` on pin `f71b2923`.

t7 matrix at drmTMB `b0cf1d8a` / DRModels `f71b2923`: 6/6 mu formula-offset cells REFUSED this way (poisson/nbinom2/gamma × fe/re). `offset=` unused-argument REFUSED in R (same as TMB). Sigma `offset()` same Julia reject for nbinom2/gamma; poisson `sigma ~` has no dispersion dpar (loud). **0 CRASH, 0 PASS, log-2 unscored on the bridge.**

## Commits

- drmTMB PR #1565 head `b0cf1d8a7bdc365d17c4c626e71c970543efa77a` (install source; workspace branch `sweep-oct16/t7` is receipt-only)
- DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`

## Source

Simulated. Campaign seed family `20261016700+` overflows R's 32-bit `set.seed()` integer. Table seed: `set.seed(202610167L)` (Poisson offset table). n = 200, 20 groups × 10. Prepared CSV: `sweep-oct16/t7/data_offset_poisson.csv` on branch `sweep-oct16/t7`.

## Preparation

```r
set.seed(202610167L)
n_g <- 20L; per <- 10L; n <- n_g * per
g <- factor(rep(sprintf("g%02d", seq_len(n_g)), each = per))
x <- rnorm(n)
effort <- runif(n, min = 0.5, max = 2.5)
off <- log(effort)
u <- rnorm(n_g, 0, 0.35)
eta <- 0.25 + 0.40 * x + u[as.integer(g)]
y <- rpois(n, lambda = effort * exp(eta))
d <- data.frame(y, x, off, g)
```

Or `d <- read.csv("sweep-oct16/t7/data_offset_poisson.csv")`.

## Minimal repro

```r
Sys.unsetenv("JULIA_PROJECT")
Sys.unsetenv("DRM_JL_PATH")
Sys.setenv(
  DRMODELS_JL_PATH = "<DRModels.jl pin f71b2923>",
  DRMTMB_JULIA_TESTS = "true",
  NOT_CRAN = "true"
)
library(drmTMB)
d <- read.csv("sweep-oct16/t7/data_offset_poisson.csv")
# TMB: log-2 identity PASSES (|delta − log(2)| ≤ 1.7e-12 on this table)
drmTMB(bf(y ~ x + offset(off)), family = poisson(link = "log"), data = d)
# bridge: ArgumentError, no fit
drmTMB(bf(y ~ x + offset(off)), family = poisson(link = "log"), data = d, engine = "julia")
```

Control that now PASSES on the same host after #1565 (no offset):

```r
set.seed(202610167L)
d0 <- data.frame(y = rnorm(40), x = rnorm(40))
drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d0, engine = "julia")
# FIT OK, logLik ≈ -57.026
```

Host: `DRMODELS_JL_PATH` set; `JULIA_PROJECT` **unset**.

## Environment

R 4.6.1 (2026-06-24), x86_64, Ubuntu 24.04.5 LTS, drmTMB 0.7.1 installed from `b0cf1d8a`, TMB 1.9.25, Matrix 1.7-6, JuliaCall 0.17.6, Julia 1.12.6, DRModels 0.7.2 at `f71b2923`.

Receipt: `sweep-oct16/t7/RECEIPT_t7.md` (follow-up section). CSV: `sweep-oct16/t7/results_offset_julia_1565.csv`.
