# Lane C Z7 — zero-one-beta sigma relmat q1 local recovery

## Exact target

```r
bf(y ~ x, sigma ~ relmat(1 | species, K = K), zoi ~ 1, coi ~ 1)
```

This is ordinary ML `zero_one_beta()` only. The supplied covariance `K` is
converted to its precision `Q = K^{-1}`. The only latent estimand is
\(\tau_\sigma=\exp(\ell_\sigma)\), with
\(u \sim N(0,K)\) and
\(\log\sigma_i=X_{\sigma i}\beta_\sigma+\tau_\sigma u_{species(i)}\).
The zero and one atom models remain fixed intercepts. This receipt does NOT
cover `Q` input, slopes, labels, other providers/dpars, covariance, profiles,
intervals, bootstrap, coverage, or inference readiness.

## Provenance and decision

`raw-attempts.tsv` records source `c91dc7b1ffaf272d93dd0cb98412e36df388e23a`
and runner MD5 `cd8d466c07aa8b1dd7cf8dd5e4c8ce59`. All four frozen local
attempts passed at true \(\tau_\sigma=0.45\), with mean relative error 0.08196,
maximum gradient 0.00162, `pdHess = TRUE`, no clamp/boundary flags, and
conditional-mode correlations 0.950--0.976. The independent full
zero/one/interior mixture oracle explicitly checks the reversed `K` order and
the `K` determinant / `K^{-1}` penalty. The fixed-SD record is diagnostic only.
