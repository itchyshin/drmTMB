# Gamma `sigma`-endpoint random-effect SD contract

This slice targets predictor-dependent variation in an existing Gamma random
intercept on the log coefficient-of-variation (CV) predictor. `sigma` remains
the response-level CV; `sd(id, dpar = "sigma")` is the standard deviation of
the group-level latent effect on `log(sigma)`.

For observation `i` in group `g`,

\[
Y_{ig}\mid b_g \sim \operatorname{Gamma}\left(\text{shape}=\sigma_{ig}^{-2},
  \text{scale}=\mu_{ig}\sigma_{ig}^{2}\right),\qquad
\log(\sigma_{ig})=X_{ig}\beta_\sigma+b_g,
\]

with

\[
b_g\mid W_g\sim N(0,\tau_g^2),\qquad
\log(\tau_g)=W_g\alpha.
\]

The first candidate cell is complete-response, univariate Gamma with log link,
fixed-effect `mu`, one ordinary `sigma` random intercept, and SD predictors
constant within `id`. It does not combine random effects on `mu` and `sigma`,
and does not admit random slopes in `sigma` or random effects inside the SD
formula.

| Symbol | R term | Synthetic draw | Recovery target |
|---|---|---|---|
| `mu_ig` | `mu ~ x` | `exp(0.2 + 0.25 x_ig)` | fixed `mu` coefficients |
| `X beta_sigma` | `sigma ~ 1 + (1 | id)` | `-0.6` | fixed log-CV intercept |
| `b_g` | `(1 | id)` in `sigma` | `Normal(0, tau_g^2)` | conditional log-CV effects |
| `log(tau_g)` | `sd(id, dpar = "sigma") ~ w` | `log(0.22) + 0.35 w_g` | SD intercept and slope |
| `Y_ig` | Gamma response | `rgamma(shape = sigma^-2, scale = mu * sigma^2)` | fitted likelihood and public predictions |

The principal numerical check is seeded coefficient recovery on independent
synthetic data. Constant-SD equivalence to the existing Gamma sigma-intercept
fit and group-name-aligned SD prediction are required before this cell is
advertised as implemented. A separate groupwise one-dimensional integration
oracle is desirable if the route requires a distinct likelihood branch; it
must use the same Gamma density and normal prior above. Profile workflow may
be tested, but interval coverage remains a later calibration deliverable.
