# Gamma phylogenetic SD parity at non-unit tree height

This receipt covers one synthetic univariate Gamma(log) model with a phylogenetic mean intercept and predictor-dependent phylogenetic SD. The tree branches are doubled so its maximum tip height is 6.404475. The same formula, response and tree are fit through native TMB and the live Julia bridge.

The focused test passed 6 assertions. It checks convergence, SD coefficient names, coefficient agreement and tip-level SD prediction agreement, using an absolute tolerance of 1e-3. This is one same-data parity fixture. It is not a recovery study, a claim about non-ultrametric trees, or evidence for every structured provider or family.

The Julia fit warns that `sd_phylo` is on the raw branch-length scale when tree height is not one. For an ultrametric tree the marginal scale differs from the correlation scale by `sqrt(tree_height)`. The JuliaCall setup also printed a non-fatal extension-loading error for `LogExpFunctionsInverseFunctionsExt` (`loglogistic` undefined); the bridge loaded and the test completed. Both warnings are preserved in `test-console.log`.

Exact command and source hashes are in `source-manifest.md`.
