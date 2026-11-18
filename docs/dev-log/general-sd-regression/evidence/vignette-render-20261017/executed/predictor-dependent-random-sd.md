---
title: "When group variation changes with a predictor"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{When group variation changes with a predictor}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---



This guide shows how to ask whether groups differ in their typical spread, and
whether that spread changes with a group-level predictor. It uses synthetic
Bernoulli and Poisson data so the data-generating values are known. The fitted
models estimate a random-intercept standard deviation; they do not estimate a
separate residual `sigma` for either response.

## The model

For a binary response, the group effect shifts the log odds:

\[
Y_{ig} \mid b_g \sim \operatorname{Bernoulli}\!\left[
  \operatorname{logit}^{-1}(\beta_0 + \beta_1 x_{ig} + b_g)
\right], \qquad
b_g \sim \operatorname{Normal}(0, s_g^2), \qquad
\log(s_g) = \alpha_0 + \alpha_1 w_g.
\]

For counts, the same random effect shifts the log expected count:

\[
Y_{ig} \mid b_g \sim \operatorname{Poisson}\!\left[
  \exp(\beta_0 + \beta_1 x_{ig} + b_g)
\right], \qquad
b_g \sim \operatorname{Normal}(0, s_g^2), \qquad
\log(s_g) = \alpha_0 + \alpha_1 w_g.
\]

Here, `x` varies among observations and `w` is constant within each group.
The fixed-effect coefficient for `x` describes a change in the mean predictor.
The coefficient `alpha_1` describes how the spread of group effects changes:
because the log link is used for `s_g`, a one-unit increase in `w` multiplies
the random-intercept SD by `exp(alpha_1)`. It does not multiply the variance by
that amount; the variance ratio is `exp(2 * alpha_1)`.

The R formula keeps those questions separate. For example,
`y ~ x + (1 | group)` models the response predictor, while
`sd(group) ~ w` models the SD of the latent group intercept. The group-level
predictor must have one value per group; a within-group predictor belongs in
the mean formula instead.

## Make two small synthetic data sets

The examples use 60 groups with 10 observations per group. The two values of
`w` differ by one unit, so exponentiating its fitted coefficient gives the
high-`w` to low-`w` random-intercept SD ratio.


``` r
set.seed(20261017)
n_group <- 60L
n_per_group <- 10L
group_info <- data.frame(
  group = factor(seq_len(n_group)),
  w = rep(c(-0.5, 0.5), each = n_group / 2)
)
group_index <- rep(seq_len(n_group), each = n_per_group)

bernoulli_data <- group_info[group_index, , drop = FALSE]
bernoulli_data$x <- stats::rnorm(nrow(bernoulli_data))
bernoulli_b <- exp(-0.4 + 0.45 * group_info$w) *
  stats::rnorm(n_group)
bernoulli_data$y <- stats::rbinom(
  nrow(bernoulli_data),
  size = 1,
  prob = stats::plogis(
    -0.25 + 0.5 * bernoulli_data$x + bernoulli_b[group_index]
  )
)

poisson_data <- group_info[group_index, , drop = FALSE]
poisson_data$x <- stats::rnorm(nrow(poisson_data))
poisson_b <- exp(-0.4 + 0.45 * group_info$w) *
  stats::rnorm(n_group)
poisson_data$y <- stats::rpois(
  nrow(poisson_data),
  lambda = exp(-0.2 + 0.3 * poisson_data$x + poisson_b[group_index])
)
```

Each data set has a binary group-level predictor and an observation-level
predictor. The latent effects are generated with an SD that increases with
`w`. The response-specific intercept and slope values differ between the two
examples, so the Bernoulli and Poisson fits are independent illustrations.

## Fit a Bernoulli model

The Bernoulli likelihood has no free residual `sigma`. The fitted random
intercept is on the logit scale, and `sd(group) ~ w` describes its group-level
standard deviation on that same latent scale.


``` r
fit_bernoulli <- drmTMB(
  bf(y ~ x + (1 | group), sd(group) ~ w),
  family = stats::binomial(link = "logit"),
  data = bernoulli_data
)

check_drm(fit_bernoulli)
#> <drm_check: 18 checks>
#> ok: 17; notes: 1; warnings: 0; errors: 0
#>                         check status
#>         optimizer_convergence     ok
#>            convergence_status     ok
#>              optimizer_budget     ok
#>              finite_objective     ok
#>         logsigma_clamp_active     ok
#>                fixed_gradient     ok
#>               sdreport_status     ok
#>     hessian_positive_definite     ok
#>          hessian_conditioning     ok
#>        standard_errors_finite     ok
#>      standard_errors_inflated     ok
#>    observations_per_parameter     ok
#>                  dropped_rows     ok
#>                positive_scale     ok
#>     random_effect_sd_boundary     ok
#>    interval_reliability_scope   note
#>      fixed_effect_design_size     ok
#>  mu_random_effect_replication     ok
#>                                                                                  value
#>                                                                                      0
#>                                                                              converged
#>                                                iterations=14; function=18; gradient=15
#>                                                                                  391.5
#>                                                                                   <NA>
#>                                             max=0.00000000002452; component=beta_mu[1]
#>                                                                                     ok
#>                                                                                   TRUE
#>                                                              min_eig=2.565; cond=42.00
#>                                                                 range=[0.09926,0.6024]
#>                                   n_inflated=0; max_se=0.6024; reference_median=0.2069
#>                                                        n_obs=600; n_par=4; ratio=150.0
#>                                                                    nobs=600; dropped=0
#>                                                                              min=1.000
#>                             min=0.3985; boundary=0.0001000; term=sd(group).sd(group):1
#>                                                         sd_targets=60; assessed_here=0
#>  total_mb=0.05186; max_cols=2; largest=mu; largest_class=matrix; largest_density=1.000
#>                                                                         (1 | group)=10
#>                                                                                                                                                                                                                                                                                                                                                                                           message
#>                                                                                                                                                                                                                                                                                                                                                                     nlminb convergence code is 0.
#>                                                                                                                                                                                                                                                                                                  Optimizer convergence and uncertainty diagnostics are consistent with a proper interior optimum.
#>                                                                                                                                                                                                                                                                                                               Optimizer evaluation counts recorded; no eval.max or iter.max control was supplied.
#>                                                                                                                                                                                                                                                                                                                                                          Objective and log-likelihood are finite.
#>                                                                                                                                                                                                                                                                                                                                                 The log-scale clamp is not active at the optimum.
#>                                                                                                                                                                                                                                                                                                                     Maximum absolute fixed gradient is <= 0.001; largest component is beta_mu[1].
#>                                                                                                                                                                                                                                                                                                                                                           TMB::sdreport() completed successfully.
#>                                                                                                                                                                                                                                                                                                                                                     sdreport reports a positive-definite Hessian.
#>  Minimum eigenvalue and condition number of TMB's sdreport() fixed-effect covariance (sdr$cov.fixed), inverted. These are a genuinely different read of the fit's conditioning than TMB's internal pdHess flag -- comparable across fits, not claimed to be numerically identical to any raw TMB gradient or Hessian quantity. This fit's Hessian conditioning is within the requested threshold.
#>                                                                                                                                                                                                                                                                                                                                                      All fixed-effect standard errors are finite.
#>                                                                                                                                                                                                                                                                                                                                No fixed-effect standard error is inflated relative to the others.
#>                                                                                                                                                                                                                                                                                                         Observations per estimated parameter are at or above the small-samplenote threshold (10).
#>                                                                                                                                                                                                                                                                                                                                No rows were dropped by model-frame or known-covariance filtering.
#>                                                                                                                                                                                                                                                                                                                                                  All fitted scale values are finite and positive.
#>                                                                                                                                                                                                                                                                      All fitted random-effect standard deviations are finite, positive, and above the requested lower-boundary warning threshold.
#>                                                         This fit has 60 random-effect standard-deviation targets. `check_drm()` assesses the fit, not interval reliability: a target can pass every check above and still return an interval that `confint()` warns about at a variance boundary. Before reporting an interval, call `confint()` and read `conf.status` and any boundary warning.
#>                                                                                                                                                                                                                                                                                                                                       Dense fixed-effect design matrices are modest for this fit.
#>                                                                                                                                                                                                                                                                                                                                   Every random-effect level has at least two fitted observations.
coef(fit_bernoulli, "sd(group)")
#> (Intercept)           w 
#>  -0.6826388   0.4745828
exp(coef(fit_bernoulli, "sd(group)")["w"])
#>        w 
#> 1.607343
```

The final value is the estimated ratio of random-intercept SDs between the
two `w` groups. It is not a ratio of event probabilities. Compare it with the
known ratio from the data-generating model, `exp(0.45)`, as a check that the
example behaves as intended; a single generated data set need not recover the
truth exactly.

## Fit a Poisson model

In the Poisson model, the latent intercept is on the log-mean scale. The
Poisson sampling distribution already determines the observation-level
variance from its mean; `sd(group)` describes additional variation among
group-specific log means.


``` r
fit_poisson <- drmTMB(
  bf(y ~ x + (1 | group), sd(group) ~ w),
  family = stats::poisson(link = "log"),
  data = poisson_data
)

check_drm(fit_poisson)
#> <drm_check: 17 checks>
#> ok: 16; notes: 1; warnings: 0; errors: 0
#>                       check status
#>       optimizer_convergence     ok
#>          convergence_status     ok
#>            optimizer_budget     ok
#>            finite_objective     ok
#>       logsigma_clamp_active     ok
#>              fixed_gradient     ok
#>             sdreport_status     ok
#>   hessian_positive_definite     ok
#>        hessian_conditioning     ok
#>      standard_errors_finite     ok
#>    standard_errors_inflated     ok
#>  observations_per_parameter     ok
#>                dropped_rows     ok
#>              positive_scale     ok
#>   random_effect_sd_boundary     ok
#>  interval_reliability_scope   note
#>    fixed_effect_design_size     ok
#>                                                                                  value
#>                                                                                      0
#>                                                                              converged
#>                                                iterations=21; function=29; gradient=22
#>                                                                                  821.9
#>                                                                                   <NA>
#>                                             max=0.00000000007964; component=beta_mu[1]
#>                                                                                     ok
#>                                                                                   TRUE
#>                                                              min_eig=14.64; cond=42.98
#>                                                                 range=[0.04014,0.2586]
#>                                   n_inflated=0; max_se=0.2586; reference_median=0.1079
#>                                                        n_obs=600; n_par=4; ratio=150.0
#>                                                                    nobs=600; dropped=0
#>                                                                              min=1.000
#>                             min=0.3870; boundary=0.0001000; term=sd(group).sd(group):1
#>                                                         sd_targets=60; assessed_here=0
#>  total_mb=0.05186; max_cols=2; largest=mu; largest_class=matrix; largest_density=1.000
#>                                                                                                                                                                                                                                                                                                                                                                                           message
#>                                                                                                                                                                                                                                                                                                                                                                     nlminb convergence code is 0.
#>                                                                                                                                                                                                                                                                                                  Optimizer convergence and uncertainty diagnostics are consistent with a proper interior optimum.
#>                                                                                                                                                                                                                                                                                                               Optimizer evaluation counts recorded; no eval.max or iter.max control was supplied.
#>                                                                                                                                                                                                                                                                                                                                                          Objective and log-likelihood are finite.
#>                                                                                                                                                                                                                                                                                                                                                 The log-scale clamp is not active at the optimum.
#>                                                                                                                                                                                                                                                                                                                     Maximum absolute fixed gradient is <= 0.001; largest component is beta_mu[1].
#>                                                                                                                                                                                                                                                                                                                                                           TMB::sdreport() completed successfully.
#>                                                                                                                                                                                                                                                                                                                                                     sdreport reports a positive-definite Hessian.
#>  Minimum eigenvalue and condition number of TMB's sdreport() fixed-effect covariance (sdr$cov.fixed), inverted. These are a genuinely different read of the fit's conditioning than TMB's internal pdHess flag -- comparable across fits, not claimed to be numerically identical to any raw TMB gradient or Hessian quantity. This fit's Hessian conditioning is within the requested threshold.
#>                                                                                                                                                                                                                                                                                                                                                      All fixed-effect standard errors are finite.
#>                                                                                                                                                                                                                                                                                                                                No fixed-effect standard error is inflated relative to the others.
#>                                                                                                                                                                                                                                                                                                         Observations per estimated parameter are at or above the small-samplenote threshold (10).
#>                                                                                                                                                                                                                                                                                                                                No rows were dropped by model-frame or known-covariance filtering.
#>                                                                                                                                                                                                                                                                                                                                                  All fitted scale values are finite and positive.
#>                                                                                                                                                                                                                                                                      All fitted random-effect standard deviations are finite, positive, and above the requested lower-boundary warning threshold.
#>                                                         This fit has 60 random-effect standard-deviation targets. `check_drm()` assesses the fit, not interval reliability: a target can pass every check above and still return an interval that `confint()` warns about at a variance boundary. Before reporting an interval, call `confint()` and read `conf.status` and any boundary warning.
#>                                                                                                                                                                                                                                                                                                                                       Dense fixed-effect design matrices are modest for this fit.
coef(fit_poisson, "sd(group)")
#> (Intercept)           w 
#>  -0.5027392   0.8930412
exp(coef(fit_poisson, "sd(group)")["w"])
#>        w 
#> 2.442547
```

This ratio also targets the change in random-intercept SD between the two
values of `w`. It does not describe a change in Poisson residual dispersion.

## Predict the group-level standard deviations

With no `newdata`, `predict()` returns one predicted SD for each fitted group.
`type = "link"` returns the log SD; `type = "response"` returns the SD after
exponentiation. These are model-implied group-level scales, not the fitted
conditional random intercepts themselves.


``` r
bernoulli_log_sd <- predict(
  fit_bernoulli, dpar = "sd(group)", type = "link"
)
bernoulli_sd <- predict(
  fit_bernoulli, dpar = "sd(group)", type = "response"
)
bernoulli_sd_table <- data.frame(
  group = names(bernoulli_sd),
  log_sd = unname(bernoulli_log_sd),
  sd = unname(bernoulli_sd)
)
bernoulli_sd_table$w <- group_info$w[
  match(bernoulli_sd_table$group, as.character(group_info$group))
]
head(bernoulli_sd_table)
#>   group     log_sd        sd    w
#> 1     1 -0.9199302 0.3985469 -0.5
#> 2     2 -0.9199302 0.3985469 -0.5
#> 3     3 -0.9199302 0.3985469 -0.5
#> 4     4 -0.9199302 0.3985469 -0.5
#> 5     5 -0.9199302 0.3985469 -0.5
#> 6     6 -0.9199302 0.3985469 -0.5

poisson_sd <- predict(fit_poisson, dpar = "sd(group)")
head(data.frame(group = names(poisson_sd), sd = unname(poisson_sd)))
#>   group        sd
#> 1     1 0.3870274
#> 2     2 0.3870274
#> 3     3 0.3870274
#> 4     4 0.3870274
#> 5     5 0.3870274
#> 6     6 0.3870274
```

The default response-scale predictions are positive SDs. The `w` coefficient
summarises their systematic change; the group-level values also reflect the
observed design matrix and should not be read as one estimate of the realised
random effect in each group.

## Check the fit before interpreting it

Read the complete `check_drm()` table for each model. It reports optimizer,
gradient, Hessian, standard-error, and random-effect boundary diagnostics
where available. Investigate warning or error rows before interpreting the
coefficients. A clean diagnostic table does not establish that the SD
coefficient is well identified in every design, and it does not assess
repeated-sampling interval coverage.

These are likelihood-based fits. `confint()` returns frequentist confidence
intervals; it does not return Bayesian credible intervals. This guide shows
point estimates and group-level predictions only. It makes no calibrated
interval claim for these examples, so do not report nominal confidence
interval coverage as established by running this vignette.

## Scope of this example

The demonstrated non-Gaussian slice is limited to native TMB Bernoulli/binomial
and ordinary Poisson models with one unlabelled random intercept and a
group-constant predictor in `sd(group)`. It does not establish support for
other distributions, random slopes, structured covariance providers, or the
Julia engine. Native Bernoulli/binomial also has a narrow explicit selector
form when a scalar intercept must be named:

```r
bf(
  y ~ x + (1 | p | group),
  sd(group, dpar = "mu", coef = "(Intercept)", block = "p") ~ w
)
```

That selector names one ordinary mean intercept; it does not extend the
example to random slopes or structured effects. For current family-by-family
limits and new evidence, see [What can I fit today?](capability-and-limits.html)
and [the formula grammar](formula-grammar.html).
