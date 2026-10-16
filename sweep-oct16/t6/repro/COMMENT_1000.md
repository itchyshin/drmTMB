## sweep-oct16 t6: univariate non-Gaussian predict also rebuilds contrasts from newdata

#1000 is written as bivariate-only (training-schema cache from #609 is univariate-only). On pin `f71b292`, **univariate** `predict(fit, nd)` for Student / Gamma / Poisson / NB2 / Binomial / Beta / Tweedie / SkewNormal / BetaBinomial / ZeroOneBeta / LogNormal refuses a `newdata` that is a proper subset of the fitted factor levels:

```
ArgumentError: predict: the `mu` design built from `newdata` has columns [(Intercept), x, f: c] but the fitted coefficients are [(Intercept), x, f: b, f: c]. … supply every fitted level …
```

Gaussian univariate on the same design **accepts** `f = ["a", "c"]` and returns finite predictions. drmTMB `ca3ddefa5` accepts the subset on every family (missing level → 0 contrast). A 1-row unseen level `f = "z"` is named correctly on Gaussian (`level(s) z not seen`) but on the other families often becomes `only one level found: z (need at least two to compute contrasts)`.

Not a new bivariate bug — extra univariate evidence that the schema cache is Gaussian-only.

### Source
Simulated FE CSVs, seeds `20261016600+`, `n = 80`, `f ∈ {a,b,c}`. `nd = (x = [-0.5, 0.5], f = ["a", "c"])`.

Refs #1000. Refs #609. Not closing.
