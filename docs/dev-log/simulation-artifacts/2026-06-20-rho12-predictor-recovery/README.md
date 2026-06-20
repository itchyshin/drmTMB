# Lead-novelty `rho12 ~ predictors` recovery artifact

This artifact banks the first MCSE-backed **recovery + Wald-calibration** run for
drmTMB's lead novelty: a predictor-dependent residual correlation in a bivariate
Gaussian model (`rho12 = ~ x`). It is native R/TMB and fixed-effect only.

Interpretation label: `promotion_candidate`. Strong enough to promote the
fixed-effect predictor-dependent `rho12` point and Wald cells from `partial` to
`covered`. It is not evidence for random-effect `rho12`, profile/bootstrap
`rho12` intervals, or any Julia bridge route.

## Model and truth

```r
bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ x)
family = biv_gaussian()
```

`rho12_i = 0.999999 * tanh(a0 + a1 * x_i)` with true `a0 = 0.4`, `a1 = 0.5` on
the guarded atanh linear-predictor scale (residual correlation ranges roughly
0.0-0.76 over `x` in +/-2). The run recovers `(a0, a1)` and checks Wald coverage
of each against its true value on the link scale.

## Provenance

- Source SHA: `065cdf05` line; branch `shannon/overnight-audit-gaps-20260619`
- drmTMB 0.1.3.9000; R 4.5.2; TMB 1.9.21; master seed `20260620`
- Conditions: 2 cells (n in {300, 600}); 500 replicates each -> 1,000 fits ->
  2,000 coefficient intervals. Elapsed 75.7 s.
- Reproduce: `Rscript --vanilla run.R 500` from the package root.

## Results

0 fit/confint errors out of 2,000; positive-definite Hessian rate 1.000.

| n | target | truth | mean est | bias | RMSE | Wald coverage | MCSE |
|---|---|---|---|---|---|---|---|
| 300 | rho12:(Intercept) | 0.4 | 0.4008 | 0.0008 | 0.0543 | 0.946 | 0.0101 |
| 300 | rho12:x | 0.5 | 0.5113 | 0.0113 | 0.0573 | 0.920 | 0.0121 |
| 600 | rho12:(Intercept) | 0.4 | 0.4013 | 0.0013 | 0.0375 | 0.964 | 0.0083 |
| 600 | rho12:x | 0.5 | 0.5057 | 0.0057 | 0.0367 | 0.956 | 0.0092 |

Both coefficients are recovered near-unbiased (largest bias 0.0113 on the
`rho12:x` slope at `n = 300`, ~2% of the true value), RMSE shrinks with `n`, and
Wald coverage brackets the nominal 0.95 (0.920-0.964). The one mildly low cell
is the `rho12:x` slope at `n = 300` (0.920, ~2.5 MCSE below nominal); it
recovers to 0.956 at `n = 600`, consistent with a small finite-sample effect
rather than a defect. This is recorded honestly rather than rounded away.

## Boundary

Native R/TMB, fixed-effect predictor-dependent residual `rho12` only, complete
data, correctly specified model. It says nothing about random effects in
`rho12` (a separate, gated cross-`dpar` route), profile or bootstrap `rho12`
intervals, group/phylogenetic/spatial/cross-family correlations, or the Julia
bridge -- all of which remain `planned`. No power claim is made.

## Effect on the capability matrix

Promotes the bivariate residual `rho12` **point**, **Wald**, and **simulation**
cells from `partial` to `covered` (fixed-effect predictor-dependent route) in
`docs/design/168-r-julia-finish-capability-matrix.md`, the status.json matrix
row, and the `drmTMB#60` lead-novelty finish-board row. `engine`, `profile`,
`bootstrap`, `bridge`, `visual`, and `release` stay `partial`/`planned`.
