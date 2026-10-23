# A7 — Symbolic alignment: `mp-zi-poisson-bernoulli`

**G0.** Approved 2026-08-27 as option (b) / D-23.
**Cell.** `zi_poisson` × one Bernoulli `mi()` in `mu` only; `zi ~ 1`.

| Symbol | Keyword / formula | DGP draw | Recovery | Truth |
|---|---|---|---|---|
| `η_μ` | `y ~ z + mi(x)` | `0.4 + 0.5 z + 0.7 x` | `coef(fit, "mu")` | `c(0.4, 0.5, 0.7)` |
| `μ(x)` | `exp(η_μ)` | Poisson mean of the count component | — | — |
| `η_zi` | `zi ~ 1` | intercept only | `coef(fit, "zi")` | `-0.8` |
| `π` | `logit^{-1}(η_zi)` | `plogis(-0.8)` | from `zi` | `≈ 0.31` |
| `P(y=0)` | ZIP mixture | `π + (1-π) e^{-μ}` | logLik identity | — |
| `P(y>0)` | ZIP mixture | `(1-π) Pois(y | μ)` | logLik identity | — |
| `η_x` | `impute_model(x ~ z, binomial())` | `0.3 + 0.8 z` | `coef(fit, "mi_x")` | `c(0.3, 0.8)` |

**Not in this cell.** `mi()` on `zi`. `zi_nbinom2`. Shared-leaf
`eta_zi`. FIML. `impute_joint`. k ≥ 2. Continuous missing predictor.

The 2-point sum is

```
log P(y, x missing) = logsumexp(
  log p(x=1) + log ZIP(y | μ(x=1), π),
  log p(x=0) + log ZIP(y | μ(x=0), π)
)
```

with the **same** `π` in both arms. Do not substitute `dpois`.
