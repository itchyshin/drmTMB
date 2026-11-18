# Poisson independent slope SD

The bounded target is one ordinary independent numeric slope, `(0 + x | id)`,
with a group-constant SD predictor. For group g and observation i,

\[
Y_{gi}\mid b_g\sim\operatorname{Poisson}\{\exp(\beta_0+\beta_1x_{gi}+x_{gi}b_g)\},
\quad b_g=\tau_g u_g,\quad u_g\sim N(0,1),\quad
\log\tau_g=\alpha_0+a w_g.
\]

| Symbol | Formula or metadata | Independent DGP | Recovery extractor | Truth |
| --- | --- | --- | --- | --- |
| beta | y ~ x | 0.2 + 0.35 x | coef(fit, "mu") | (0.2, 0.35) |
| alpha | sd(id, coef = "x") ~ w | -0.45 + 0.75 w_g | coef(fit, selected SD name) | (-0.45, 0.75) |
| u_g | one independent slope axis | rnorm(G) | marginal latent draws | N(0,1) |
| x_gi b_g | random-regression design value | x_gi exp(alpha_0 + a w_g) u_g | ordinary contribution draws | x_gi tau_g u_g |

The SD output is per unit of x on the log-mean scale. Its contribution to the
latent predictor has variance x_gi squared times tau_g squared. No hidden
standardization is applied to x. The marginal response mean is
exp(beta_0 + beta_1 x_gi + x_gi squared times tau_g squared / 2).

The independent scalar reference integrates over b_g directly. Its modal
curvature is 1/tau_g squared plus the sum of x_gi squared times the conditional
Poisson mean. Both Laplace and adaptive integration use this same joint density.
Unit x must reduce to the intercept reference; zero x must remove the random
effect; rescaling x and inversely rescaling tau must preserve the model.

Admission remains separate from target identity. The common scalar resolver keeps
the binomial intercept fence while the Poisson adapter admits the checked slope.
Mixed same-group coefficients, crossed slope layouts, correlated blocks, labelled
slopes, structured partners, zero inflation and missing-data combinations remain
required later slices. A successful single synthetic fit is an implementation and
workflow check, not calibrated recovery evidence.
