# Target: new issue on itchyshin/drmTMB
# GitHub MCP 403 blocked posting from this agent.

Title: [sweep-oct16 t4] Gaussian location-scale at n=8 (sigma ~ x): likelihood unbounded on 6/50 seeds; drmTMB reports converged=TRUE at a finite logLik 0.5–13.6 nats below the ridge

Independent cloud-agent replicate of lane t4 (not PR #1552). Pins: drmTMB `ca3ddefa5ea11bbfd3b765615dfbb89305d2485a`, DRModels.jl `f71b2923360e9e5d4591e0d6e15a9ef9db0356d7`.

## Summary

Cell `gauss_n8` fits `y ~ x`, `sigma ~ x` (4 parameters) on **n = 8**. On 6 of 50 seeds the Gaussian location-scale likelihood is unbounded. DRModels.jl walks toward that ridge, reports `is_converged = false`, and warns that the Hessian is singular. drmTMB stops at a finite logLik 0.50 to 13.62 nats lower, reports `is_converged() = TRUE` / `convergence_status() = "converged"`, and emits no user-facing warning.

Pass-bar fail: `converged = TRUE` with a silently wrong answer. Distinct from #1469 (two finite optima after rescaling y). Related: #1554.

| rep | R logLik | R conv | J logLik | J conv | ΔlogLik (J−R) |
|---|---|---|---|---|---|
| 4 | 6.156 | TRUE | 6.725 | false | +0.57 |
| 6 | 16.376 | TRUE | 29.344 | false | +12.97 |
| 19 | 6.157 | TRUE | 19.778 | false | +13.62 |
| 30 | 7.335 | TRUE | 14.161 | false | +6.83 |
| 31 | −5.103 | TRUE | −4.406 | false | +0.70 |
| 49 | −4.003 | TRUE | −3.498 | false | +0.50 |

The other 44/50 agree to 5e-9.

## Data source and prep

Simulated, cell k = 1. Nominal seed `20261016400 + (rep-1)`; R uses `seed %% 2^31`.

```r
RNGkind("Mersenne-Twister", "Inversion", "Rejection")
gen <- function(rep, n = 8) {
  set.seed(as.integer((20261016400 + (rep - 1)) %% 2^31))
  x <- rnorm(n)
  data.frame(y = 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * rnorm(n), x = x)
}
```

## Minimal repro (rep 6)

Expected: not `converged = TRUE` without a warning (MLE does not exist).
Actual: drmTMB logLik 16.376, conv TRUE; Julia logLik 29.344, conv false.

```r
library(drmTMB)
d <- gen(6)
f <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d)
c(logLik = as.numeric(logLik(f)), conv = is_converged(f), status = convergence_status(f))
```

```julia
using DRModels
fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = (; y, x))
loglik(fit), is_converged(fit), fit.theta
# 29.343888090366388  false  [1.187, 0.775, -11.182, 8.393]
```

<details>
<summary>Prepared data (dput of rep 6)</summary>

```r
structure(list(y = c(-0.441871770107243, 1.26378780565074, 1.03038787038423,
-0.0153625801466957, 2.49644234970613, 1.66733975379137, 0.629089528280424,
1.99163948719048), x = c(-2.10032048573547, 1.36622547816976,
1.53113068360739, 1.50417636656935, 1.66021564925424, 1.64085039426733,
-0.719240170220848, 1.34234778780536)), class = "data.frame", row.names = c(NA, -8L))
```
</details>

<details>
<summary>sessionInfo() / versioninfo()</summary>

```
R 4.3.3, Ubuntu 24.04.5, drmTMB 0.7.1 @ ca3ddefa, TMB 1.9.25, Matrix 1.6-5
Julia 1.11.6, DRModels 0.7.2 @ f71b292
```
</details>

Refs #1469, #1554.
