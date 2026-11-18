# NB2 ordinary independent-slope SD alignment

This slice extends predictor-dependent latent SDs from an ordinary NB2 random
intercept to one independent numeric location slope. The dispersion submodel
and its existing NB2 parameterization remain unchanged.

For observation `i` in group `g`,

\[
\eta_{ig}=x_i^\top\beta+x_{ig}b_g,\qquad
b_g=\tau_g u_g,\qquad
u_g\sim N(0,1),\qquad
\log\tau_g=z_g^\top\alpha,
\]

and the response contribution is the existing NB2 likelihood
\(f_{\mathrm{NB2}}(y_i\mid\eta_{ig},\sigma)\), with fixed `sigma ~ 1`.
The group likelihood integrates over the single standard-normal slope effect.
`x_ig` varies within group; each row of the SD design `z_g` is constant within
group and the retained group-level design has full column rank.

| Symbol | Formula / implementation | Synthetic draw or calculation | Recovery extractor | Truth |
|---|---|---|---|---|
| \(\beta\) | Fixed `mu` formula; unchanged family design matrix | Fixed coefficients generate \(x_i^\top\beta\) | Location coefficients from the fitted `mu` block | DGP coefficient vector |
| \(x_{ig}\) | `(0 + x | id)`; TMB `mu_re_value`, Julia observation loading `w` | Within-group numeric slope predictor | Independent likelihood oracle uses the same row loading | Observed `x` values |
| \(u_g\) | One scalar standard-normal latent effect per group; existing Laplace (TMB) or adaptive quadrature (Julia) integral | Draw one `N(0,1)` value per group | Likelihood/integration oracle and fitted latent-effect route | Standard-normal distribution |
| \(\alpha\) | `sd(id) ~ z`; TMB `X_sd_mu` / Julia `Zg` | Set \(\tau_g=\exp(z_g^\top\alpha)\) before drawing \(b_g\) | `beta_sd_mu` / Julia `fit.sdpars[:mu]` | Prespecified intercept and slope coefficients |
| \(\sigma\) | `sigma ~ 1`; existing NB2 dispersion slot | Use the same fixed NB2 dispersion in simulation and fit | Existing `sigma` coefficient/output | Fixed DGP value; no random sigma effect |
| \(y_i\) | Existing NB2 response | Draw from the repository NB2 parameterization at \(\eta_{ig}\) and fixed \(\sigma\) | Fitted likelihood, fitted means, simulation and refit outputs | Synthetic response vector |

The recovery DGP will use independent synthetic groups, a binary group-level
`z` for the log-SD coefficient, and a centered continuous within-group `x` for
the random slope. The ordinary slice will test a positive SD slope and include
a wrong-loading negative control. It will retain existing NB2 clamp behavior,
complete-response requirements, and uncertainty semantics. One seeded recovery
and cross-engine agreement do not establish interval calibration.
