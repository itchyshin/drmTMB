# [sweep-oct16 t6] LogNormal drm() has no marginal= keyword (Poisson / Gamma / NB2 / Binomial / Beta / Student accept it)

`drm(::DrmFormula, ::LogNormal; data, tree, K, g_tol)` at `src/lognormal.jl:58` has no `marginal`. Passing `marginal = :Laplace` (the t6 twin of drmTMB's Laplace RE default) is a `MethodError`. The same call is accepted for Poisson, Gamma, NegBinomial2, Binomial, Beta, and Student on this pin. The LogNormal RE *fit* succeeds if you omit `marginal=` (default GHQ-32 / `:LA`).

Related but different: #942 is the missing `se=` on Gaussian/LogNormal. #1071/#1070 are about naming the default marginal. This issue is the missing *keyword* on LogNormal.

**Expected:** `drm(form, LogNormal(); data, marginal = :Laplace)` is accepted or a clear "LogNormal has no Laplace route" error.

**Actual:** `MethodError: no method matching drm(::DrmFormula, ::LogNormal; data, marginal::Symbol)`. Closest candidate lists `data, tree, K, g_tol` only.

### Source
Simulated lognormal RE, seed `20261016611`, `sweep-oct16/t6/data/lognormal_re.csv`. DRModels.jl 0.7.2 `f71b292`.

### Preparation
`n = 80`, 8 groups, `x ~ N(0,1)`, `f ∈ {a,b,c}`. Generator: `sweep-oct16/t6/t6_gen_data.R`.

### Minimal repro

```julia
using DRModels
dat = (y = abs.(randn(40)) .+ 0.2, x = randn(40), g = string.(repeat(1:8, inner = 5)))
form = bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1))
drm(form, LogNormal(); data = dat)                       # OK, converged
drm(form, LogNormal(); data = dat, marginal = :Laplace)  # MethodError
drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)),
    Gamma(); data = dat, marginal = :Laplace)            # accepted
```

On `lognormal_re.csv`: no-`marginal` fit converged, loglik ≈ −31.67.

<details><summary>sessionInfo / versioninfo</summary>

```
DRModels.jl 0.7.2 SHA f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
Julia 1.11.6
```

</details>

Refs #942 (missing `se=` on Gaussian/LogNormal).
Refs #1071 (name the marginal approximation).
