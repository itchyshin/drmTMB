# R5: fixed-alpha OU sensitivity grid

R5 parks free OU-rate estimation and evaluates sensitivity to *assumed*
location-side OU decay. It fits an unchanged BM phylogenetic-intercept baseline
and OU fits with fixed `alpha_mu` values `0.1, 0.3, 0.7, 1.3, 2.5`. Every fit
uses the same univariate Gaussian response, tree, rows, fixed-effect formula,
residual scale, and optimizer. No sigma-side OU field, `alpha_sigma`,
cross-field correlation, alpha profile, or rate-estimation claim is admitted.

The initial evidence runner uses the retained 128-species fixture. Ayumi's
all-species model is the first empirical example only once an exact data/tree
receipt is available. Outputs are objective/AIC, fixed effects, convergence,
Hessian status, and the assumed alpha label. The grid is a robustness display,
not a test selecting a biological evolutionary process.
