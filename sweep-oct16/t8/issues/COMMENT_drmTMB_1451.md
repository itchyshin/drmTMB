Target: https://github.com/itchyshin/drmTMB/issues/1451
Status: NOT POSTED (GitHub write 403). Do not re-file. Julia twin: DRModels.jl#940.

---

**sweep-oct16 t8 (16 Oct 2026).** Same gap on a second ecology dataset: `glmmTMB::Owls` ZINB with nest intercept. The t8 primary cell dropped ZI+RE and fitted NB2 location-scale with offset only (that cell fails for DRModels.jl#1097).

**Expected.** ZINB with `(1 | Nest)` on mu, as in glmmTMB. **Actual.** drmTMB refuses with the planned-but-not-implemented message (clear error, not a silent failure).

```
Error in validate_poisson_mu_random_terms(...):
  NB2 `mu` random intercepts and slopes are implemented only for ordinary NB2 models.
✖ Zero-inflated NB2 random effects are planned but not implemented.
ℹ Fit `y ~ x + (1 | id) + (0 + x | id)` without a `zi` formula, or use a
  fixed-effect `zi ~ predictors` model.
```

**Source.** `glmmTMB::Owls` (glmmTMB 1.1.15.2; 599 rows). Deterministic; no seed.

**Preparation.**

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

**Minimal repro** (drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`):

```r
library(drmTMB)
d <- read.csv("Owls.csv")
try(drmTMB(
  bf(mu = NCalls ~ FoodTreatment * ArrivalTime + offset(logBroodSize) + (1 | Nest),
     zi = ~ FoodTreatment),
  family = nbinom2(), data = d
))
```

Prepared CSV: `sweep-oct16/t8/data/Owls.csv` (37 KB; regenerates from `glmmTMB::Owls`).

<details><summary>sessionInfo</summary>

```
R 4.3.3, Ubuntu 24.04.5 LTS x86_64, drmTMB 0.7.1 @ ca3ddef, glmmTMB 1.1.15.2, TMB 1.9.25
```
</details>
