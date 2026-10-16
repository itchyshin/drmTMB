# t7 receipt — Offset and contrasts (16 Oct 2026)

Lane: t7 | Offset and contrasts checks (drmTMB side plus the bridge).
Hard timeouts: `timeout(1)` 90–180 s per fit / 600–1500 s per harness; `callr` 90 s (TMB); `setTimeLimit` 90 s (julia-engine script). A hang becomes TIMEOUT/CRASH, not a stall.

## Pins (`git rev-parse HEAD`)

| repo | SHA | note |
|---|---|---|
| itchyshin/drmTMB | `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a` | already at pin on checkout |
| itchyshin/DRModels.jl | `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7` | cloned to `/home/ubuntu/DRModels.jl` |

No PR. Branch `sweep-oct16/t7` only. Did not push to `main`, did not merge.

## Runtime

- R 4.6.1 (2026-06-24), drmTMB 0.7.1 (this pin, `R CMD INSTALL`), TMB 1.9.25, Matrix 1.7-6
- Julia 1.12.6, DRModels 0.7.2 at the pin (`Pkg.instantiate` + `precompile`)
- Ubuntu 24.04.5 LTS, x86_64
- Campaign seed family `20261016700+` **overflows** R's 32-bit `set.seed()` integer (`NAs introduced by coercion`). Representable seed used: `202610167L` (+0 Poisson offset, +1 NB2, +2 Gamma, +50 contrasts).

## Commands run

```sh
git rev-parse HEAD   # ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
git clone https://github.com/itchyshin/DRModels.jl /home/ubuntu/DRModels.jl
git -C /home/ubuntu/DRModels.jl checkout f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
Rscript sweep-oct16/t7/generate_data.R
timeout 1200 Rscript sweep-oct16/t7/harness_offset.R tmb
timeout 600  Rscript sweep-oct16/t7/harness_contrasts.R tmb
timeout 1500 Rscript sweep-oct16/t7/harness_julia_engine.R
timeout 600  julia --project=/home/ubuntu/DRModels.jl sweep-oct16/t7/harness_offset_drmmodels.jl
timeout 60   julia --project=/home/ubuntu/DRModels.jl sweep-oct16/t7/harness_contrasts_drmmodels.jl
```

Isolated probes (timeout 30–180 s): Gamma log-2 on TMB; ordered-factor name dump; unordered `contr.sum` control; JuliaCall `1+1`; `drm_julia_setup()`; `engine="julia"` Gaussian/Poisson fits (segfault); Poisson RE offset guard vs interaction; NB2/Gamma `theta` blocks.

## Pass bars

1. **Offset log-2 shift.** Fit with offset `off`, refit with `off + log(2)`. Location intercept must drop by `log(2) ≈ 0.693147180559945` to 1e-8; other mu slopes unchanged to 1e-8; logLik unchanged to 1e-6. Loud refuse of an unsupported route is not a silent wrong answer.
2. **Contrasts.** `contr.treatment` / `contr.sum` / `contr.helmert` / `contr.poly` on an ordered 4-level factor. Fitted values invariant across encodings to 1e-8. Coefficients equal `lm`/`glm` with the same coding (Gaussian / Poisson).

Known (do not re-file): DRModels #1097 / #938 (offset, being fixed in #1096); drmTMB #1495 (contrasts, in #1501); DRModels #1027 (extra dpars swallowed).

## Offset results

### drmTMB native TMB (`results_offset_tmb.csv`)

| family | re | dpar | syntax | status | \|delta − log 2\| |
|---|---|---|---|---|---|
| poisson | fe | mu | formula | **PASS** | 1.7e-12 |
| poisson | re | mu | formula | **PASS** | 0 |
| nbinom2 | fe | mu | formula | **PASS** | 1.1e-16 |
| nbinom2 | re | mu | formula | **PASS** | 1.1e-16 |
| gamma | fe | mu | formula | **PASS** | 1.7e-13 |
| gamma | re | mu | formula | **PASS** | 7.4e-14 |
| * | * | mu | offset_arg | REFUSED | unused argument `offset` |
| nbinom2/gamma | * | sigma | formula | REFUSED | `sigma` formula unsupported term `offset` |
| poisson | * | sigma | formula | REFUSED | Poisson has no `sigma` (loud) |

All six supported mu-`offset()` cells pass the exact log-2 bar. `offset=` is not a `drmTMB()` argument (classed unused-dots error). Sigma offsets are refused.

### DRModels.jl native (`results_offset_drmmodels.csv`)

| family | re | dpar | syntax | status | note |
|---|---|---|---|---|---|
| poisson | fe | mu | formula | **PASS** | delta 3.9e-14; logLik matches TMB |
| poisson | re | mu | formula | REFUSED | intended FE-only offset guard fires on `(1\|g)` |
| nbinom2 | fe | mu | formula | **FAIL** | offset free coef 0.974; intercept moves 0.675 |
| nbinom2 | re | mu | formula | **FAIL** | intercept moves 0.665; mu block length 3 |
| gamma | fe | mu | formula | **FAIL** | offset free coef 1.154; intercept moves 0.800 |
| gamma | re | mu | formula | **FAIL** | intercept moves 0.719 |
| * | * | mu/sigma | offset_arg | REFUSED | MethodError, no `offset=` keyword |
| nbinom2/gamma | * | sigma | formula | **FAIL** | offset estimated, no warning |
| poisson | * | sigma | formula | **FAIL** | extra `sigma` formula swallowed (#1027); intercept unmoved |

Gamma is new evidence for #1097 (same silent-estimate mechanism). Poisson `(1|g)` + offset on `~ 1 + x` and `~ 1 + x*z` **does** refuse at this pin; the Owls `Food*Sex` route in #1097 is the one that skipped the guard.

### drmTMB `engine = "julia"` (`results_offset_julia.csv`)

| route | status |
|---|---|
| `offset=` | REFUSED (unused dots; never reaches Julia) |
| poisson `sigma ~` | REFUSED (no dispersion dpar) |
| formula `offset()` that reaches the bridge | **CRASH** — R Segmentation fault, exit 139 |

`drm_julia_setup()` returns TRUE. `julia_eval("1+1")` is 2. The first `engine = "julia"` **fit** (Gaussian FE, no offset; Poisson FE, with or without offset) kills the process. Native `drm()` on the same pin fits. Not #1157 (that recovered). Issue draft: `issues/NEW_drmTMB_julia_segfault.md`. Ordered-factor contrast cells never reached this crash: they were refused in R first.

## Contrasts results

### drmTMB native TMB (`results_contrasts_tmb.csv`)

| family | coding | coef vs lm/glm | fitted vs lm/glm | fitted invariance |
|---|---|---|---|---|
| gaussian | treatment | FAIL (`g.L/g.Q/g.C` vs `g2/g3/g4`) | 8.1e-15 | |
| gaussian | sum | FAIL | 7.9e-15 | |
| gaussian | helmert | FAIL | 7.1e-15 | |
| gaussian | poly | **PASS** 6.7e-16 | 7.9e-15 | |
| gaussian | INVARIANCE | — | — | **PASS** max\|diff\|=0 |
| poisson | treatment | FAIL | 1.3e-10 | |
| poisson | sum | FAIL | 1.3e-10 | |
| poisson | helmert | FAIL | 1.3e-10 | |
| poisson | poly | **PASS** 5.8e-11 | 1.3e-10 | |
| poisson | INVARIANCE | — | — | **PASS** max\|diff\|=0 |

#1495 still live at `ca3ddef`. On an **ordered** factor the silent replacement is `contr.poly`, not treatment. Unordered `contr.sum` still becomes `gb gc`. Predictions do not flag it (bar 1e-8 holds vs `lm`/`glm` fitted values).

### drmTMB `engine = "julia"` (`results_contrasts_julia.csv`)

All eight cells (Gaussian/Poisson × four encodings) **REFUSED** before Julia starts: `g: an ordered factor (R codes it with contr.poly)`. Requested `contr.treatment` is also refused because `#1495` restored poly first. Loud, named, next-step present — correct for the bridge given the dropped contrasts.

### DRModels.jl native (`results_contrasts_drmmodels.csv`)

StatsModels dummy/treatment coding only. No `contrasts=` / `C()` API at this pin. `sum`/`helmert`/`poly` recorded REFUSED (not expressible). Default dummy-coded Gaussian and Poisson fits succeed (`PASS_TREATMENT_ONLY`).

## Issues filed or commented

**None landed on GitHub.** `add_issue_comment` / `issue_write` / `gh issue comment` all returned **403 Resource not accessible by personal access token / integration**. `get_me` and issue **reads** worked as itchyshin. Drafts (ready to paste):

| intended action | URL | one line |
|---|---|---|
| comment | https://github.com/itchyshin/drmTMB/issues/1495 | ordered-factor live fits: droplevels → contr.poly; invariance PASS; coef match only poly |
| comment | https://github.com/itchyshin/DRModels.jl/issues/1097 | Gamma+NB2 log-2 FAIL (silent free offset coef); Poisson FE PASS; simple Poisson RE REFUSES |
| comment | https://github.com/itchyshin/DRModels.jl/issues/938 | same offset evidence (twin of #1097) |
| comment | https://github.com/itchyshin/DRModels.jl/issues/1027 | Poisson `sigma ~ offset` swallowed; intercept unmoved |
| new | drmTMB (draft `issues/NEW_drmTMB_julia_segfault.md`) | `engine="julia"` segfault 139 after successful setup |

Did not re-file #1097, #938, #1495, #1027. Did not open #1501/#1096. Used "Refs", never "Closes".

## PR head SHA

None. No PR opened.
