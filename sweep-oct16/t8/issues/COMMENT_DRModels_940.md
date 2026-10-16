Target: https://github.com/itchyshin/DRModels.jl/issues/940
Status: NOT POSTED (GitHub write 403). Do not re-file. R twin: drmTMB#1451.

---

**sweep-oct16 t8 (16 Oct 2026).** Same ZI+RE gap on `glmmTMB::Owls`. A first probe with `marginal = :Laplace` was a harness miss: it refused because of `zi`, not because of `(1 | Nest)`. Retrying with the default integrator gives the true gap message.

**Expected.** ZINB with `(1 | Nest)` on mu. **Actual.** Refused with a clear error (gap, not a silent failure):

```
NegBinomial2() random effects cannot be combined with `zi`/`hu` yet
```

Laplace-first error (for the record, not the gap):

```
ArgumentError: marginal = :Laplace is not available for NegBinomial2() with a `zi` formula. This route covers exactly one ordinary random intercept `(1 | g)` on the mean for Poisson, Binomial, NegBinomial2, Gamma and Beta (`sigma ~ 1` for the three scale families), fitted by maximum likelihood. Omit `marginal` (the default `:LA`) for other models.
```

**Source.** `glmmTMB::Owls` (glmmTMB 1.1.15.2; 599 rows). Deterministic; no seed.

**Preparation.** Same as drmTMB#1451 t8 comment / `sweep-oct16/t8/fits/Owls/prepare.R`.

**Minimal repro** (DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`):

```julia
using DRModels, CSV
df = CSV.File("Owls.csv")
f = bf(@formula(NCalls ~ 1 + FoodTreatment * ArrivalTime + offset(logBroodSize) + (1 | Nest)),
       @formula(zi ~ 1 + FoodTreatment))
drm(f, NegBinomial2(); data = df)   # default integrator: ZI+RE gap message above
```

Prepared CSV: `sweep-oct16/t8/data/Owls.csv`.

<details><summary>versioninfo</summary>

```
Julia 1.11.6, Linux x86_64, 1 thread, DRModels 0.7.2 @ f71b292
```
</details>
