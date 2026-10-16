Target repo: itchyshin/DRModels.jl (new issue)
Status: NOT FILED. GitHub MCP `issue_write` create returned 403 "Resource not accessible by personal access token". Do not duplicate if this lands later. Related: drmTMB#1554 (flag contract), drmTMB#1470/#1478 (collinear sigma; this design is not collinear).

Proposed title: `[sweep-oct16 t8] Beta loc-scale on betareg::GasolineYield (sigma ~ batch, n=32) misses drmTMB/glmmTMB optimum by 0.017 and still prints SEs when not converged`

---

**Expected.** On `betareg::GasolineYield` the Beta location-scale model `yield ~ temp + batch`, `sigma ~ batch` should match drmTMB / glmmTMB logLik to 1e-4, and if the fit is not converged the reported SEs should not be presented as usable. **Actual.** DRModels.jl stops 0.0168 nats short of the drmTMB/glmmTMB optimum (both R engines agree to 2.9e-10), reports `is_converged = false`, and still prints a full `coeftable` of finite SEs. drmTMB also reports not converged, but refuses `vcov()` because TMB `sdreport()` did not report a positive-definite Hessian. glmmTMB reports converged at the same logLik as drmTMB.

This is not the #1554 case where both engines sit at the same optimum and only the flag disagrees. Here the Julia optimum is different. It is also not drmTMB#1470 (exact alias `sigma ~ x + xdup`): 10 batch levels with 2–4 observations each make the scale weakly identified, not collinear.

| engine | logLik | converged | SEs |
|---|---|---|---|
| drmTMB `ca3ddef` | 92.0596218477018 | FALSE (`opt` "relative convergence (4)"; Hessian not PD) | refused |
| glmmTMB 1.1.15.2 | 92.0596218474146 | TRUE | finite |
| DRModels.jl `f71b292` | 92.04282636918045 | FALSE | finite (e.g. `sigma: batch: g10` SE 0.551) |

Pass bar: `|ΔlogLik| = 0.0167955 > 1e-4`; 0/21 matched coefficients pass 1e-4 relative (max rel 0.196 on `sigma:batchg10`); drmTMB has no SEs to compare.

**Source.** `betareg::GasolineYield` (betareg 3.2-6; 32 rows, 10 batches). Deterministic; no seed. Batch labels 1:10 are prefixed `g` so CSV.jl does not parse them as a numeric covariate.

**Preparation.**

```r
chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(GasolineYield, package = "betareg")
d <- GasolineYield
d$batch <- chr_factor(d$batch)
write.csv(d, "GasolineYield.csv", row.names = FALSE)
```

**Minimal repro** (pins drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`, DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`).

```r
library(drmTMB); library(glmmTMB)
d <- read.csv("GasolineYield.csv")
fit <- drmTMB(bf(mu = yield ~ temp + batch, sigma = ~ batch), family = beta_family(), data = d)
c(logLik(fit), is_converged(fit))
# 92.0596218477018  FALSE
# vcov(fit) → "Fixed-effect covariance is unavailable because TMB::sdreport() did not report a positive-definite Hessian."
logLik(glmmTMB(yield ~ temp + batch, dispformula = ~ batch, family = glmmTMB::beta_family(), data = d))
# 92.0596218474146
```

```julia
using DRModels, CSV
df = CSV.File("GasolineYield.csv")
fit = drm(bf(@formula(yield ~ 1 + temp + batch), @formula(sigma ~ 1 + batch)), Beta(); data = df)
println(loglik(fit), "  ", is_converged(fit))  # 92.04282636918045  false
println(coeftable(fit))                        # 21 finite SEs printed
```

<details><summary>Prepared data `GasolineYield.csv` (32 rows)</summary>

```csv
"yield","gravity","pressure","temp10","temp","batch"
0.122,50.8,8.6,190,205,"g1"
0.223,50.8,8.6,190,275,"g1"
0.347,50.8,8.6,190,345,"g1"
0.457,50.8,8.6,190,407,"g1"
0.08,40.8,3.5,210,218,"g2"
0.131,40.8,3.5,210,273,"g2"
0.266,40.8,3.5,210,347,"g2"
0.074,40,6.1,217,212,"g3"
0.182,40,6.1,217,272,"g3"
0.304,40,6.1,217,340,"g3"
0.069,38.4,6.1,220,235,"g4"
0.152,38.4,6.1,220,300,"g4"
0.26,38.4,6.1,220,365,"g4"
0.336,38.4,6.1,220,410,"g4"
0.144,40.3,4.8,231,307,"g5"
0.268,40.3,4.8,231,367,"g5"
0.349,40.3,4.8,231,395,"g5"
0.1,32.2,5.2,236,267,"g6"
0.248,32.2,5.2,236,360,"g6"
0.317,32.2,5.2,236,402,"g6"
0.028,41.3,1.8,267,235,"g7"
0.064,41.3,1.8,267,275,"g7"
0.161,41.3,1.8,267,358,"g7"
0.278,41.3,1.8,267,416,"g7"
0.05,38.1,1.2,274,285,"g8"
0.176,38.1,1.2,274,365,"g8"
0.321,38.1,1.2,274,444,"g8"
0.14,32.2,2.4,284,351,"g9"
0.232,32.2,2.4,284,424,"g9"
0.085,31.8,0.2,316,365,"g10"
0.147,31.8,0.2,316,379,"g10"
0.18,31.8,0.2,316,428,"g10"
```
</details>

<details><summary>sessionInfo / versioninfo</summary>

```
R 4.3.3 (2024-02-29), Ubuntu 24.04.5 LTS x86_64
drmTMB 0.7.1 @ ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
glmmTMB 1.1.15.2, TMB 1.9.25, betareg 3.2-6, Matrix 1.6-5
Julia 1.11.6 (9615af0f269), Linux x86_64, 1 thread
DRModels 0.7.2 @ f71b2923360e9e5d4591e0d6e15a9ef9db0356d7
```
</details>
