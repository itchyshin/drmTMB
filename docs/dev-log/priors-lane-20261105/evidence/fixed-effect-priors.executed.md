---
title: "Regularize selected coefficients with normal priors"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Regularize selected coefficients with normal priors}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



Does survival vary with temperature anomaly? The six deliberately separated observations below illustrate an estimation problem: all survivors have positive anomalies and all failures have negative anomalies. They are invented teaching data, not biological evidence. A binomial coefficient can run toward infinity under this separation. Independent normal priors can keep selected coefficients finite. Choose their scales in the units of your predictors and the link-scale effect you consider plausible. The fit is a penalized or maximum-a-posteriori (MAP) point estimate; this workflow does not sample a full posterior.


``` r
d <- data.frame(x=c(-3,-2,-1,1,2,3), y=c(0,0,0,1,1,1))
p <- drm_priors(
  drm_prior_normal("mu", "(Intercept)", mean=0, sd=3),
  drm_prior_normal("mu", "x", mean=0, sd=2)
)
drm_resolve_priors(bf(mu=y~x), binomial(), d, p)
#>   dpar coefficient matrix_column mean sd precision       reason   kind
#> 1   mu (Intercept)             1    0  3 0.1111111 exact column normal
#> 2   mu           x             2    0  2 0.2500000 exact column normal
f <- drmTMB(bf(mu=y~x), binomial(), data=d, priors=p)
coef(f, dpar="mu")
#>   (Intercept)             x 
#> -1.531075e-09  1.758742e+00
```

Let `x` be temperature anomaly in degrees Celsius and `y` survival (0 or 1). In this example, a one-degree warmer anomaly multiplies fitted survival odds by 5.81, from a slope of 1.76 log-odds units. These values depend on the chosen priors. Here `mu` is the event-probability parameter and its predictor uses the logit link. The priors act on the intercept and slope of that predictor. A proper prior on only one coefficient cannot guarantee a finite estimate for every unpenalized direction. Both directions receive priors in this example.

For a simulated growth-rate response, suppose temperature anomaly predicts both mean growth and variation among observations. For Gaussian data, `mu` describes location and `sigma` residual scale. The `mu` predictor is on the response scale, while the `sigma` predictor is on log SD. The two blocks can receive different priors even when both contain a column named `x`.


``` r
set.seed(5105)
g <- data.frame(x=rnorm(120))
g$y <- 0.4 + 1.2*g$x + rnorm(120, sd=exp(-0.3 + 0.2*g$x))
gp <- drm_priors(
  drm_prior_normal("mu", "x", sd=2),
  drm_prior_normal("sigma", "x", sd=0.5)
)
drm_resolve_priors(bf(mu=y~x, sigma=~x), gaussian(), g, gp)
#>    dpar coefficient matrix_column mean  sd precision       reason   kind
#> 1    mu           x             2    0 2.0      0.25 exact column normal
#> 2 sigma           x             2    0 0.5      4.00 exact column normal
gf <- drmTMB(bf(mu=y~x, sigma=~x), data=g, priors=gp)
coef(gf)
#> $mu
#> (Intercept)           x 
#>   0.2589885   1.1318094 
#> 
#> $sigma
#> (Intercept)           x 
#>  -0.3813179   0.2009149
```

In this simulated example, the fitted mean changes by 1.13 response units per degree. The residual SD is multiplied by 1.22 per degree, from a log-SD slope of 0.2. These fitted associations describe the teaching data.

To penalize a whole coefficient block, choose the intercept policy explicitly. The ridge constructor adds `0.5 * lambda * sum(beta^2)` to the negative data log-likelihood. For positive lambda, it has the same optimum and curvature as a mean-zero normal prior with SD `1/sqrt(lambda)`; the ridge objective omits the normal density constant.


``` r
r <- drm_priors(drm_prior_ridge("mu", "all", lambda=0.25,
                               intercept="exclude"))
drm_resolve_priors(bf(mu=y~x), gaussian(), g, r)
#>   dpar coefficient matrix_column mean sd precision                 reason  kind
#> 1   mu           x             2    0  2      0.25 all; intercept exclude ridge
```

Exact coefficient names refer to the final design matrix, including factor contrasts and interactions. `coef="all"` includes or excludes the conventional intercept using design metadata. Level columns in a no-intercept factor formula remain ordinary coefficients. No automatic centring or scaling occurs. To discover factor and interaction names before selecting a column, inspect `colnames(model.matrix(~ f*x, data))`, using the predictor formula for that distributional parameter; then check `drm_resolve_priors()` on the complete-case data you will fit. Unknown names, empty or overlapping selections and rank-deficient designs fail before fitting. Zero lambda adds nothing but still validates the requested selection and design.

`logLik(f)` returns the data log-likelihood at the penalized estimate. `f$fixed_prior_penalty` records the separate prior contribution. `summary()` and `vcov()` describe local penalized-Hessian curvature. Confidence intervals and ordinary AIC, BIC, likelihood-ratio and profile comparisons are unavailable for active fixed priors. Point predictions and simulations use the fitted parameter values, without drawing coefficient uncertainty.

This first slice accepts complete, unit-weight, fixed-effect Gaussian and binomial-logit models. Fits with active priors use an unclamped log-scale predictor; when passing `drm_control()`, set `logsigma_clamp=NULL` explicitly. REML, MSPL, structured effects, existing phylogenetic penalties and other response families refuse. If your analysis needs weights or random effects, fit that supported model without `priors`, or use another method whose regularization has been validated for that structure. Random-effect SD priors and tmbstan require separate validation. A wider prior or a different coding can change the result; use the resolved table and compare several scientifically plausible scales.
