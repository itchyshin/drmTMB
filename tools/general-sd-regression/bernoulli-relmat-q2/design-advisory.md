# Pending addition to `docs/design/03-likelihoods.md`

The native logit relatedness slice accepts one unlabelled
`relmat(1 + x | id, K = K)` term, or its named precision input `Q = solve(K)`.
It accepts either the constant-SD base model with no direct-SD formula or two
coefficient-selected SD formulas, one for `(Intercept)` and one for the
numeric slope `x`. For each field `k` independently, `u_k ~ N(0, K)` and
`b_{gk} = exp(W_{gk} alpha_k) u_{gk}`. Its covariance is `D_k K D_k`, where
`D_k = diag(exp(W_{gk} alpha_k))`; the fields have zero cross-covariance.
The observation predictor is `eta_i = X_i beta + b_{g(i),0} + x_i b_{g(i),1}`
and `Y_i ~ Bernoulli(logistic(eta_i))`. The base model estimates two constant
field SDs. The two direct-SD formulas replace those constants, rather than
adding scales on top. The model retains the supplied non-unit kernel diagonal
and fits no correlation or residual `sigma`.

This first slice accepts complete, unweighted, explicit 0/1 responses. Probit
and complementary log-log links, other structured providers, labelled blocks,
and missing-data routes require separate evidence. The independent dense
Laplace check and one fixed-seed recovery fixture are implementation evidence;
they do not establish interval coverage or calibrated uncertainty.

This paragraph was removed from the shared design file pending its active
owner's integration. It is not a public capability claim.
