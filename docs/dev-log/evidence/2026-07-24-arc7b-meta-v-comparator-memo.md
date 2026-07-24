# Arc 7B comparator and parameterization memo

For diagonal known sampling variances, the exact external ML comparator is:

```r
metafor::rma(yi, vi, mods = ~ x, scale = ~ z, method = "ML", data = dat)
```

`drmTMB` uses log-SD coefficients in `sigma ~ z`; `metafor` uses log-variance
coefficients in its scale model. If `gamma` is the `drmTMB` coefficient and
`alpha` is the `metafor` coefficient, `alpha = 2 * gamma`. Coefficients must
never be squared: that would lose their sign.

This comparator is intentionally limited to diagonal `V` and no extra latent
hierarchy. Local `metafor` 5.0-1 confirmed that `rma.mv(..., V = dense_V,
scale = ~ z)` disregards `scale`. Dense `V`, LSS, LSSS, and DH are instead
checked against the direct marginal Gaussian oracle in
`inst/sim/fit/sim_meta_v_lss_oracle.R`.

`brms` and `blsmeta` are secondary conceptual comparators, not local
certification routes: neither was installed in this environment. The supplied
location-scale meta-analysis guide's `brms::gr(effect_id, cov = V)` route is
an additive known-covariance formulation; `se(sei, sigma = TRUE)` is a different
multiplicative sampling-variance model and must not be used as a `meta_V`
equivalence check.

Sources: Nakagawa et al. (2025), *Global Change Biology* 31:e70204,
doi:10.1111/gcb.70204; [location-scale meta-analysis guide](https://itchyshin.github.io/location-scale_meta-analysis/);
[`metafor::rma.uni` documentation](https://wviechtb.github.io/metafor/reference/rma.uni.html).
