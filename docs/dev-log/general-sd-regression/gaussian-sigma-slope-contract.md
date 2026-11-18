# Gaussian residual-scale random-slope SD contract

This candidate adds one ordinary independent random slope to the Gaussian
residual-scale predictor. It is a native TMB slice. The SD predictor is fixed
at the grouping-factor level; the random slope itself varies by observation.

For observation `i` in group `g`, the model is

\[
\log(\sigma_{ig}) = X_{\sigma,ig}\beta_\sigma + z_{ig}u_g,
\qquad u_g \sim N(0,\tau_g^2),
\qquad \log(\tau_g) = W_g\alpha.
\]

The implementation, simulation, and recovery must agree term by term:

| Symbol | R formula / implementation | Synthetic data draw | Recovery or check | Truth |
|---|---|---|---|---|
| `X_sigma beta_sigma` | Fixed part of `sigma ~ 1 + (0 + z | id)` | Fixed log-residual-scale intercept | `coef(fit, "sigma")` and fitted `sigma` | Intercept `0` |
| `z_ig u_g` | Independent sigma random slope `(0 + z | id)` | Draw one `u_g` per group, then multiply by row-level `z` | `sigma_random_effect_contribution(fit)` and fitted scale | `u_g z_ig` |
| `tau_g` | `sd(id, dpar = "sigma", coef = "z") ~ w` | `u_g ~ Normal(0, exp(alpha_0 + alpha_1 w_g)^2)` | `coef(fit, dpar = 'sd(id, dpar = "sigma", coef = "z")')` | `alpha_0 = log(0.2)`, `alpha_1 = 0.4` |
| `W_g` | Fixed-effect model matrix for the `sd()` formula | `w` is assigned once per group and repeated over its observations | Within-group constancy rejection | Constant within `id` |

The test also compares the constant-SD formula with the same sigma random-slope
model without an `sd()` formula. This checks the existing constant-SD limit;
it does not assess interval coverage or Julia parity.
