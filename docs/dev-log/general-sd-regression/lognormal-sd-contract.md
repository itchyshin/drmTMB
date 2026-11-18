# Native lognormal ordinary random-effect SD contract

For positive response `Y_gi`, the ordinary location random-effect SD is defined
on the log-response scale. For a selected independent slope coefficient,

\[
\log Y_{gi}=X_{gi}\beta+x_{gi}\tau_g u_g+\sigma_{gi}\epsilon_{gi},\qquad
\log\tau_g=W_g\alpha,\quad\log\sigma_{gi}=Z_{gi}\gamma.
\]

Here `x` is the random-slope loading and `u_g` is standard normal. The
independent standard-normal group and observation effects imply the exact
log-response covariance `diag(sigma_g^2) + tau_g^2 x_g x_g'`. The
response-scale log likelihood includes the Jacobian `-sum(log(Y))`. The
independent Cholesky reference evaluates this marginal density without package
fitting helpers.

| Symbol | Formula | Meaning |
|---|---|---|
| X beta | `y ~ x + (0 + x | id)` | Conditional log-location and slope loading |
| Z gamma | `sigma ~ z` | Log residual SD on the log-response scale |
| W alpha | `sd(id, dpar = "mu", coef = "x") ~ w` | Log ordinary location-slope SD on the log-response scale |

The slope target uses the common `dpar = "mu"` and `coef = "x"` selectors to
retain its identity. SD predictors must be constant within retained groups;
ordinary complete-case filtering precedes that validation. No averaging or
implicit rescaling occurs. A constant SD formula must match the existing
constant-slope model.

This native slice admits complete data, one ordinary independent numeric
location slope target, and fixed-effect `sigma` regression. Correlated or
labelled blocks, multiple same-group targets, structured providers, and
missing-data combinations remain outside this location-slope slice. Seeded
point recovery, an independent marginal-likelihood calculation, constant-SD
equivalence, prediction, and simulation are checked. These checks do not
establish interval calibration or Julia parity.

## Sigma-endpoint random-intercept SD regression

For one ordinary random intercept in the `sigma` formula, the target is the
SD of a latent effect on `log(sigma)`:

\[
\log(\sigma_{gi}) = Z_{gi}\gamma + \tau_g u_g,\qquad
u_g \sim N(0,1),\qquad
\log(\tau_g) = W_g\alpha.
\]

The corresponding formula is:

```r
bf(
  y ~ 1,
  sigma ~ 1 + (1 | id),
  sd(id, dpar = "sigma") ~ w
)
```

The first fitted route requires complete data, fixed-effect `mu`, one
independent `sigma` intercept, and `w` constant within each `id`. `tau_g` is
not residual `sigma`; it controls between-group variation in the log residual
scale. The focused synthetic test checks point recovery, coefficient
covariance, group-SD predictions, and equivalence between `sd(id) ~ 1` and the
legacy constant-SD intercept model. It does not establish interval coverage
or Julia parity.
