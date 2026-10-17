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
