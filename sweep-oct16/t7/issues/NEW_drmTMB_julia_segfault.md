# SUPERSEDED — do not file

Confirmed **fixed** on drmTMB PR #1565 head `b0cf1d8a7bdc365d17c4c626e71c970543efa77a` (t7 follow-up, 16 Oct 2026). Same host, `DRMODELS_JL_PATH` only, `JULIA_PROJECT` unset: harness R exit 0, Gaussian `engine="julia"` FIT OK. Paste-ready comment: `COMMENT_drmTMB_1565.md`. Keep this file as the original 139 evidence, not as an issue to open.

---

# New issue intended for itchyshin/drmTMB (not a duplicate of #1157)

GitHub write from this cloud task returned 403. Paste this if posting by hand.

Title: engine="julia" segfaults (R exit 139) on the first fit after a successful drm_julia_setup() at ca3ddef / Julia 1.12.6

Pins: drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`, DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`.

**Expected.** `drmTMB(..., engine = "julia")` returns a fit (or a classed R error).

**Actual.** `drmTMB:::drm_julia_setup()` returns TRUE. `JuliaCall::julia_eval("1+1")` is 2. `Pkg.activate` + `drm_julia_load_module` return `"DRModels"`. The first `engine = "julia"` **fit** then kills R with Segmentation fault, exit 139. `tryCatch` does not catch it. Native `drm()` in Julia on the same pin fits.

Not #1157 (that one prints a recovered `ERROR` and continues).

**Source.** Simulated `data.frame(y = rnorm(40), x = rnorm(40))`. Seed `202610167L`.

**Minimal repro.**
```r
library(drmTMB)
Sys.setenv(DRMODELS_JL_PATH = "<DRModels.jl pin f71b292>", DRMTMB_JULIA_TESTS = "true", NOT_CRAN = "true")
set.seed(202610167L)
d <- data.frame(y = rnorm(40), x = rnorm(40))
drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d, engine = "julia")
```

Controls that pass: `julia_setup()` + `1+1`; `drm_julia_setup()`; native `drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), Gaussian(); data=...)`.

R 4.6.1, Julia 1.12.6, JuliaCall CRAN, Ubuntu 24.04.5.
