# Lane C Z7 — zero-one-beta sigma spatial q1 local recovery

```r
bf(y ~ x, sigma ~ spatial(1 | site, coords = coords), zoi ~ 1, coi ~ 1)
```

This exact ordinary-ML q1 route estimates only the natural-scale latent
sigma SD \(\tau_\sigma=\exp(\ell_\sigma)\), with a fixed coordinates-derived
precision. `raw-attempts.tsv` retains all four source-bound attempts on
`dd34f73b577dff00acd0526f7eb6cfc4453e5e16`; all pass, with mean SD relative
error 0.17448, gradients below 0.00087, `pdHess = TRUE`, no clamp/boundary
flag, and mode correlations 0.955--0.978. The independent oracle separately
rebuilds coordinates-to-precision and the full zero/one/interior mixture.

This receipt does NOT cover mesh/range estimation, slopes, labels, other
providers/dpars, profiles, intervals, bootstrap, coverage, or inference.
