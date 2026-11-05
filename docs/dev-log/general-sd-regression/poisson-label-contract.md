# Poisson scalar block identity

For retained group g and observation i, Y_gi follows a Poisson distribution with
log mean X_gi beta + tau_g u_g, where u_g is standard normal and
log(tau_g) = W_g alpha. A scalar block label names this same coefficient. It adds
no correlation parameter and does not change the likelihood or kernel scaling.

| Symbol | Formula | Independent DGP | Extractor | Truth |
| --- | --- | --- | --- | --- |
| X beta | y ~ x + (1 \| p \| id) | -0.2 + 0.35 x | coef(fit, "mu") | (-0.2, 0.35) |
| W alpha | sd(id, block = "p") ~ w | log(0.6) + 0.45 w_g | coef(fit, selected SD name) | (log(0.6), 0.45) |
| tau_g u_g | selected scalar coefficient | exp(W_g alpha) rnorm(G) | predicted SD and latent simulation | exp(W_g alpha) |

Labelled ordinary terms combined with structured effects or response-missing
integration remain fenced.

The existing independent Poisson fixture supplies this DGP without calling package
simulation. Compare labelled and unlabelled fits on the same generated observations,
including constant-SD reduction. Wrong labels must list available targets. Duplicate
same-group intercepts remain an overlap error. NB2 labels, labelled slopes and
correlated blocks retain their current admission boundaries. This slice does not
establish recovery or uncertainty calibration for a new scientific domain.
