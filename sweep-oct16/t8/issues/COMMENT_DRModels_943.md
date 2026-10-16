Target: https://github.com/itchyshin/DRModels.jl/issues/943
Status: NOT POSTED (GitHub write 403). Do not re-file.

---

**sweep-oct16 t8 (16 Oct 2026).** Neighbour of this gap: `marginal = :Laplace` is also refused for **BetaBinomial** with a single `(1 | g)` and `sigma ~ 1`. The family is not in the ordinary-Laplace list (Poisson/Binomial/NegBinomial2/Gamma/Beta). Not a logLik mismatch: the default integrator matched drmTMB Laplace to 4.5e-10 on this dataset because the herd SD collapsed to ~1e-8, so GHQ ≈ Laplace.

**Error** (`lme4::cbpp`, 56 rows, 15 herds):

```
ArgumentError: marginal = :Laplace is not available on this route. `:Laplace` forces the Laplace approximation that drmTMB uses and is implemented for an ordinary random intercept `(1 | g)` on Poisson/Binomial/NegBinomial2/Gamma/Beta ... and for a Gaussian random intercept on `sigma`, `sigma ~ 1 + (1 | g)`. Here use :LA (the default integrator ... 32-node Gauss–Hermite quadrature, not Laplace) ...
```

| engine | logLik | herd SD |
|---|---|---|
| drmTMB Laplace | −88.0416468156531 | (RE on mu) |
| glmmTMB | −88.0416468266861 | |
| DRModels default `:LA` | −88.0416468152059 (Δ R−J 4.47e-10) | 1.22e-8 |
| DRModels `:Laplace` | refused (error above) | |

Gaussian mean RE (`nlme::Orthodont`) is refused with a different named error (`:Laplace` is only for a Gaussian intercept on **sigma**). Default Woodbury matched drmTMB Laplace to 2.8e-13, as documented. Not filed separately.

**Source.** `lme4::cbpp` (lme4 2.0-6; 56 rows). Deterministic; no seed. Herd/period labels are all-digit, so prep prefixes `g`.

**Preparation.**

```r
chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(cbpp, package = "lme4")
d <- lme4::cbpp
d$herd <- chr_factor(d$herd)
d$period <- chr_factor(d$period)
d$fail <- d$size - d$incidence
write.csv(d, "cbpp.csv", row.names = FALSE)
```

**Minimal repro** (pins drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`, DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`):

```r
library(drmTMB)
d <- read.csv("cbpp.csv")
logLik(drmTMB(bf(mu = cbind(incidence, fail) ~ period + (1 | herd), sigma = ~ 1),
              family = beta_binomial(), data = d))
```

```julia
using DRModels, CSV
df = CSV.File("cbpp.csv")
f = bf(@formula(cbind(incidence, fail) ~ 1 + period + (1 | herd)), @formula(sigma ~ 1))
loglik(drm(f, BetaBinomial(); data = df))                          # -88.04164681520592
drm(f, BetaBinomial(); data = df, marginal = :Laplace)             # ArgumentError above
```

Prepared data: `sweep-oct16/t8/data/cbpp.csv` (56 rows, full CSV in that file).

<details><summary>sessionInfo / versioninfo</summary>

```
R 4.3.3, Ubuntu 24.04.5 LTS x86_64, drmTMB 0.7.1 @ ca3ddef, lme4 2.0-6, glmmTMB 1.1.15.2, TMB 1.9.25
Julia 1.11.6, Linux x86_64, 1 thread, DRModels 0.7.2 @ f71b292
```
</details>
