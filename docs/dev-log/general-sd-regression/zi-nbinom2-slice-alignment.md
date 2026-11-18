# Zero-inflated NB2 random-intercept SD slice

This note pins the symbolic model to the synthetic test and fitted outputs for
the complete-response native TMB slice. It covers one ordinary `mu` random
intercept. `sigma` and `zi` remain fixed-effect intercepts. The checks are
implementation and point-recovery evidence, not interval calibration.

| Symbol | Formula or implementation | Synthetic generator | Recovery or check |
| --- | --- | --- | --- |
| `eta_mu_i` | `X_mu beta_mu + tau_g u_g`; `y ~ x + (1 | id)` | `0.25 + 0.3 x_i + tau_g u_g` | `coef(fit, "mu")`; the independent groupwise likelihood recalculates the conditional mean |
| `log(tau_g)` | `W_g beta_sd_mu`; `sd(id) ~ w` | `log(0.55) + 0.4 w_g` | `coef(fit, "sd(id)")`; `predict(fit, dpar = "sd(id)")` |
| `u_g` | `u_g ~ Normal(0, 1)`; scaled before adding to `eta_mu` | One standard-normal draw per group | Independent one-dimensional groupwise Laplace calculation; wrong-group control reverses the scale predictor across groups |
| `log(sigma)` | `sigma ~ 1`; NB2 size is `1 / sigma^2` | Constant `sigma = 0.32` | `coef(fit, "sigma")`; the oracle uses base-R `dnbinom()` |
| `logit(zi)` | `zi ~ 1`; structural-zero probability | Constant `zi = 0.18` | `coef(fit, "zi")`; the oracle independently evaluates the zero mixture |
| `y_i` | Zero-inflated NB2 mixture | Draw NB2 counts, then replace structural-zero rows by zero | Fit convergence, positive Hessian, SD-slope recovery, likelihood agreement, prediction, simulation, and save/reload |

The public route is limited to one ordinary `mu` intercept. The builder rejects
random slopes and SD predictors that vary within a group. Missing responses,
structured effects combined with this SD route, random effects on `zi`, and
Julia execution remain outside this evidence. The existing fixed-`zi` spatial
route and separate NB2 `sigma` random-effect gates have their own limits and
do not inherit these checks.
