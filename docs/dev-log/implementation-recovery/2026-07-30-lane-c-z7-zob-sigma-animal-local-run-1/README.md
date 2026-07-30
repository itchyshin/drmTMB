# Lane C Z7 — zero-one-beta sigma animal q1 local recovery

## Exact target

```r
bf(y ~ x, sigma ~ animal(1 | species, Ainv = Ainv), zoi ~ 1, coi ~ 1)
```

This is ordinary ML `zero_one_beta()` only.  With the supplied precision
matrix `Ainv`, the only latent estimand is
\(\tau_\sigma = \exp(\ell_\sigma)\), where
\(u \sim N(0, Ainv^{-1})\) and
\(\log\sigma_i = X_{\sigma i}\beta_\sigma + \tau_\sigma u_{species(i)}\).
The zero and one atom models remain fixed intercepts.  The retained route does
not cover slopes, other animal representations (`A` or pedigree), other
distributional parameters, covariance, profiles, intervals, bootstrap,
coverage, or inference readiness.

## Provenance and decision

The code source is `1a93c1d66aeb263a850422e957d298afc8d3978e`; the runner MD5
is `d9e81174731af44d0f5432dd0bf6f3d3`.  `raw-attempts.tsv` retains every
planned attempt and `summary.tsv` records 4/4 passing at truth
\(\tau_\sigma=0.45\), with mean relative error 0.04777.  Each fit converged,
had `pdHess = TRUE`, maximum gradient at most 0.00278, no boundary or clamp
flag, and conditional-mode correlation 0.939--0.959.  The independent oracle
uses the observed zero/one/interior mixture likelihood and the reordered
`Ainv` Gaussian penalty, including its determinant normalization.

`fixed-sigma-animal-boundary-diagnostic.tsv` is a diagnostic-only fixed-SD
run.  It is not recovery or interval evidence.
