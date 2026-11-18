# General SD-regression symbolic alignment

Status: approved programme contract; cell-specific admission and research review
remain open. No blanket capability promotion.

| Symbol | Formula/target | DGP | Recovery extractor | Truth |
|---|---|---|---|---|
| beta | mu mean predictors | X beta | fixef(fit)$mu | per fixture |
| alpha | sd(group) fixed predictors | W alpha | fixef(fit)[[sd target]] | per fixture |
| tau[g] | latent coefficient amplitude | exp(W[g,] alpha) | predict(dpar=sd target) | exp(W alpha) |
| u[g] | standardized latent intercept | N(0,1) | realized latent effects / tau | per seed |
| b[g] | (1 | group) in mu | tau[g] u[g] | ranef(fit) | per seed |
| R | existing latent coefficient correlation | valid existing correlation map | corpairs(fit) | per fixture |
| K | existing structured kernel | preserve normalization | stored provider metadata | supplied fixed kernel |

Bernoulli first: y[i] | b ~ Bernoulli(logit_inverse(X[i,] beta + b[g[i]])).
There is no independent residual sigma. Binomial grouped counts retain their
declared trial counts. SD predictors are constant within each retained latent
group. Ordinary covariance D R D and structured covariance D (K tensor R) D
preserve positive definiteness for positive tau and an admitted base covariance.

All coefficient/prediction and interval checks use the same target/coding map.
Unknown newdata levels and within-group-varying SD predictors do not silently
change that map. Existing clamping and boundary diagnostics remain visible.

## Next ordinary-family slice: Poisson

For a location random intercept, use
`Y[i] | u ~ Poisson(exp(X[i,] beta + exp(W[g[i],] alpha) u[g[i]]))`,
with independent `u[g] ~ N(0,1)`. The syntax remains
`bf(y ~ x + (1 | id), sd(id) ~ w)` with `poisson()`.
The SD is on the log-mean link scale, and a unit change in `w` multiplies that
latent SD by `exp(alpha[w])`. No free Poisson residual scale is introduced.
The generator must use a distinct group-level `w_group` and observation-to-group
index; constant-SD equivalence and independent scalar integration remain
separate likelihood checks. This is the next implementation contract, not a
claim that Poisson SD fitting or inference already passes.
