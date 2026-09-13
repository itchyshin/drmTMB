# 273. Fixed-alpha phylogenetic OU sensitivity API

`ou_sensitivity()` is an experimental robustness tool, not the OU-v1 programme.
It fits the unchanged Brownian-motion comparator and a prespecified grid of
location-side OU rates using the same formula, rows, tree, and optimizer
controls.  For `alpha_scale = "root_depth"`, a displayed alpha is divided by
the common root-to-tip depth before the native fit.  Therefore a value such as
`0.7` has the same meaning across ultrametric trees after scale normalisation.
`alpha_scale = "raw"` accepts rates already expressed in the ultrametric
tree's branch-length units; it does not relax the package's ultrametric-tree
requirement.

Its admitted model is one complete-response univariate Gaussian response with
one unlabelled `phylo(1 | group, tree = tree, model = "ou")` intercept in
`mu`, and fixed predictors in `mu` and `sigma`.  It refuses scale-side OU,
free alpha estimation, phylogenetic slopes, labels/coupled blocks, direct-SD
formulae, ordinary random effects, known sampling covariance, weights,
missingness, REML, bivariate/non-Gaussian models, temporal terms, and
new-data/forecast use.

The output carries the BM fit and every fixed-OU fit, a likelihood/diagnostic
table, and fixed effects for every distributional parameter.  AIC differences
are conditional on each stated fixed alpha.  They do not estimate alpha, prove
that one process is preferred generally, or turn a weak empirical result into a
selection or interval claim.

Full OU v1 remains parked.  In particular, this API does not change the
frozen 29-row capability manifest: no row becomes `SUPPORTED` because this
tool exists.
