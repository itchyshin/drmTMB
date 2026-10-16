# [sweep-oct16 t6] predict_parameters(:response) uses the wrong inverse link for Student ν, SkewNormal ν, and ZeroOneBeta μ (LogNormal μ also disagrees with drmTMB)

`_param_response` in `src/gaussian_core.jl` (~1892) maps `:nu` to `exp.(η)` except Tweedie, and maps `:mu` through `_mean_response`. That disagrees with this package's own stored scales and with drmTMB `predict(..., type = "response")` on pin `f71b292` / `ca3ddefa5`. Link-scale predictions match to ~1e-15. Response-scale max |R−Julia| fails the t6 1e-8 bar by O(1).

**Expected:** `predict_parameters(fit, nd; type = :response)` returns the same quantity stored on the fit (`fit.scales[:nu]`, `fit.means[:mu]`) and the same quantity drmTMB returns for that dpar.

**Actual (standalone, same CSVs):**

| Family | dpar | Julia `:response` | Correct (this pkg / drmTMB) | Cause in `_param_response` |
| --- | --- | --- | --- | --- |
| Student | ν | `exp(η) = 0.479` | `2+exp(η) = 2.479` = `fit.scales[:nu]` | `:nu` always `exp` except Tweedie |
| SkewNormal | ν | `exp(η) = 0.378` | identity `η = −0.974` (drmTMB) | same `:nu` → `exp` |
| ZeroOneBeta | μ | `η = −0.082` | `logistic(η) = 0.480` (drmTMB) | `_mean_response` misses ZeroOneBeta logit |
| LogNormal | μ | `exp(η) = 1.028` | drmTMB identity `η = 0.028` (documented: log-Y μ, not exp(μ)) | Julia treats LogNormal μ as log-linked; drmTMB does not. Refs itchyshin/drmTMB#1320 |

Tweedie ν (`_logit12`) and the usual log/logit families (Gaussian, Gamma, Poisson, NB2, Beta, Binomial, BetaBinomial) passed the 1e-8 bar.

### Source
Simulated data, not a package dataset. Lane t6 seeds `20261016600+`. CSVs: `sweep-oct16/t6/data/{lognormal,student,skew_normal,zero_one_beta}_fe.csv`. drmTMB 0.7.1 `ca3ddefa5`; DRModels.jl 0.7.2 `f71b292`.

### Preparation
`n = 80`, `x ~ N(0,1)`, `f ∈ {a,b,c}` recycled. Generator: `sweep-oct16/t6/t6_gen_data.R`. No missing values.

### Minimal repro

```julia
using DRModels, DelimitedFiles
# pin f71b292; data = sweep-oct16/t6/data/student_fe.csv
raw, hdr = readdlm("student_fe.csv", ','; header = true)
cols = Dict(String(h) => j for (j, h) in enumerate(vec(hdr)))
dat = (y = Float64.(raw[:, cols["y"]]), x = Float64.(raw[:, cols["x"]]),
       f = string.(raw[:, cols["f"]]))
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ 1), @formula(nu ~ 1)),
          Student(); data = dat)
nd = (x = [0.0], f = ["a"])
pp = predict_parameters(fit, nd; type = :response)
pp[:nu][1]          # 0.479
fit.scales[:nu][1]  # 2.479
2 + exp(predict_parameters(fit, nd; type = :link)[:nu][1])  # 2.479
```

Same pattern on `skew_normal_fe.csv` (`pp[:nu] == exp(η)`, drmTMB `η`) and `zero_one_beta_fe.csv` (`pp[:mu] == η`, drmTMB `logistic(η)`).

<details><summary>Prepared data (first 8 rows of student_fe.csv)</summary>

```
y,x,f,g,trials
-0.0265795469337351,-0.703073689938788,a,g01,12
1.12513594800157,0.486961258682204,b,g01,12
-0.495281383810396,0.697787818454671,c,g01,12
-0.3031579243416,-0.594491718994473,a,g01,12
1.87225368725938,0.357874452370676,b,g01,12
3.73579673602027,0.377008399387102,c,g01,12
0.109312535388408,-0.740551699035013,a,g01,12
1.12810689206109,0.410739893608466,b,g01,12
```

</details>

<details><summary>sessionInfo / versioninfo</summary>

```
drmTMB 0.7.1  SHA ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
DRModels.jl 0.7.2 SHA f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
R 4.6.1 (2026-06-24) x86_64-pc-linux-gnu Ubuntu 24.04.5 LTS
TMB 1.9.25  Matrix 1.7-6
Julia 1.11.6
```

</details>

Refs #1092 (newdata is invlink(Xβ); this issue is the *wrong* invlink).
Refs itchyshin/drmTMB#1320 (lognormal type=response is documented as log-Y μ).
