Target: https://github.com/itchyshin/DRModels.jl/issues/1097
Status: NOT POSTED. GitHub MCP `add_issue_comment` returned 403 "Resource not accessible by personal access token". `gh issue comment` as the Cursor GitHub App returned 403 "Resource not accessible by integration". Paste this body when write access is available. Refs #1097 / #938. Do not re-file.

---

**sweep-oct16 t8 (16 Oct 2026).** Second real-data hit on the same pin, different mean formula. `glmmTMB::Owls` NB2 location-scale with `offset(logBroodSize)` and no random effect. Refs #938.

**Expected.** `offset(logBroodSize)` is held at 1 (drmTMB and glmmTMB). **Actual.** DRModels.jl estimates it as a free coefficient `0.7553831788766235` (SE 0.1456), so logLik is 1.426 nats higher than the twins that hold the offset at 1.

| engine | logLik | converged | coef `offset(logBroodSize)` |
|---|---|---|---|
| drmTMB `ca3ddef` | −1699.24301683246 | TRUE | (held at 1; not in `coef()`) |
| glmmTMB 1.1.15.2 | −1699.24301683248 | TRUE | (held at 1) |
| DRModels.jl `f71b292` | −1697.81701775589 | TRUE | **0.7553831788766235** |

Every named location/scale coefficient then fails the 1e-4 relative pass bar (max rel 0.1487 on the FoodTreatment × ArrivalTime interaction). Not a new bug: same silent free-coefficient path as this issue's L2.

**Source.** `glmmTMB::Owls` (glmmTMB 1.1.15.2; 599 rows). Deterministic; no seed.

**Preparation.** Digit-only factor labels are prefixed with `g` so CSV.jl does not parse them as numeric (Nest labels here are not all-digit, so the prefix is a no-op).

```r
chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(Owls, package = "glmmTMB")
d <- glmmTMB::Owls
d$FoodTreatment <- chr_factor(d$FoodTreatment)
d$SexParent <- chr_factor(d$SexParent)
d$Nest <- chr_factor(d$Nest)
d$NCalls <- d$SiblingNegotiation
write.csv(d, "Owls.csv", row.names = FALSE)
```

**Minimal repro** (pins drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`, DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`).

```r
library(drmTMB)  # 0.7.1 at ca3ddef
d <- read.csv("Owls.csv")
fit <- drmTMB(bf(mu = NCalls ~ FoodTreatment * ArrivalTime + offset(logBroodSize),
                 sigma = ~ FoodTreatment), family = nbinom2(), data = d)
c(logLik(fit), is_converged(fit))  # -1699.24301683246  TRUE
```

```julia
using DRModels, CSV  # 0.7.2 at f71b292
df = CSV.File("Owls.csv")
fit = drm(bf(@formula(NCalls ~ 1 + FoodTreatment * ArrivalTime + offset(logBroodSize)),
             @formula(sigma ~ 1 + FoodTreatment)), NegBinomial2(); data = df)
println(loglik(fit))           # -1697.8170177558927
println(is_converged(fit))     # true
println(coeftable(fit))        # includes mu: offset(logBroodSize) = 0.75538
```

Prepared CSV (37 KB) is in this receipt: `sweep-oct16/t8/data/Owls.csv`.

<details><summary>sessionInfo / versioninfo</summary>

```
R 4.3.3 (2024-02-29), Ubuntu 24.04.5 LTS x86_64, drmTMB 0.7.1 @ ca3ddef, glmmTMB 1.1.15.2, TMB 1.9.25, Matrix 1.6-5
Julia 1.11.6 (9615af0f269), Linux x86_64, 1 thread, DRModels 0.7.2 @ f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
```
</details>
