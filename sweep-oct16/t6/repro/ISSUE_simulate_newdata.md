# [sweep-oct16 t6] simulate() has no newdata; draws are always training rows (twin of drmTMB #1536)

`simulate(fit::DrmFit; nsim, rng)` at `src/gaussian_core.jl:2187` has no `newdata` formal. There is no way to draw for a new design. drmTMB has the same gap (`simulate.drmTMB` also lacks `newdata` and ignores it via `...`) — itchyshin/drmTMB#1536. Do not treat this as a drmTMB re-file; this is the Julia twin.

**Expected:** `simulate(fit; newdata = nd)` draws one row per `nd` row, or errors naming the unused argument.

**Actual:** the method is `simulate(fit::DrmFit; nsim, rng)` only. Draws are training rows.

### Source
Simulated Gaussian FE, seed `20261016600` (`gaussian_fe.csv`). DRModels.jl 0.7.2 `f71b292`.

### Preparation
`n = 80`, `x ~ N(0,1)`, `f ∈ {a,b,c}`. Generator: `sweep-oct16/t6/t6_gen_data.R`.

### Minimal repro

```julia
using DRModels
dat = (y = [0.2, 0.5, 1.1, 1.4], x = [-1.0, 0.0, 1.0, 2.0])
fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gaussian(); data = dat)
methods(simulate)   # simulate(fit::DrmFit; nsim, rng) — no newdata
size(simulate(fit; nsim = 1))  # (4, 1) training rows
```

<details><summary>sessionInfo / versioninfo</summary>

```
DRModels.jl 0.7.2 SHA f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
Julia 1.11.6
Twin: drmTMB 0.7.1 ca3ddefa5 — same gap, already filed as itchyshin/drmTMB#1536
```

</details>

Refs itchyshin/drmTMB#1536.
