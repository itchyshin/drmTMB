## sweep-oct16 t6: lognormal `type = "response"` is still log-Y μ, and the Julia twin disagrees

On pin `ca3ddefa5` this docs finding is still true in code, and `?predict.drmTMB` now *does* say lognormal returns μ on the log-response scale (R/methods.R ~2915). The new t6 fact is the **twin mismatch**: DRModels.jl `f71b292` `predict_parameters(..., type = :response)[:mu]` returns `exp(η)` (the lognormal median), while drmTMB returns `η`. Link-scale predictions match to 2e-15; response-scale max |R−Julia| = 1.046 vs the 1e-8 bar.

**Expected (this issue):** docs name the families where `type = "response"` is not `E[Y]`.
**Actual on this pin:** R docs are now explicit for lognormal; Julia still applies a log inverse link. Not a drmTMB defect relative to its own Rd. Julia inverse-link gaps drafted as `ISSUE_predict_invlinks.md`.

### Source / repro
Simulated `lognormal_fe.csv`, seed `20261016620`. `n = 80`, `x ~ N(0,1)`, `f ∈ {a,b,c}`. Generator `sweep-oct16/t6/t6_gen_data.R`.

```r
library(drmTMB)
dat <- read.csv("sweep-oct16/t6/data/lognormal_fe.csv", stringsAsFactors = FALSE)
dat$f <- factor(dat$f, levels = c("a", "b", "c"))
fit <- drmTMB(bf(y ~ x + f, sigma ~ 1), family = lognormal(), data = dat)
nd <- data.frame(x = c(-0.5, 0, 0.5), f = factor(c("a", "b", "c")))
identical(predict(fit, newdata = nd, type = "response"),
          predict(fit, newdata = nd, type = "link"))  # TRUE; values 0.028, 0.287, 0.189
```

Julia on the same CSV: response = `exp(link)` = 1.028, 1.333, 1.208.

<details><summary>sessionInfo</summary>

```
drmTMB 0.7.1 SHA ca3ddefa5ea11bbfd3b765615dfbb89305d2485a
R 4.6.1 TMB 1.9.25
DRModels.jl 0.7.2 SHA f71b292
```

</details>

Refs #1320. Not closing.
