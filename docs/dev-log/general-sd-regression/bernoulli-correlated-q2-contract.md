# Bernoulli correlated q2 SD regression contract

This note records the tested candidate contract for one ordinary Bernoulli
intercept-slope block in native TMB and DRM.jl. It does not claim interval
calibration or support for other families and providers.

For group `g`, let the intercept and slope SDs be

```text
log(tau[g, 0]) = W[g, 0] alpha[0]
log(tau[g, 1]) = W[g, 1] alpha[1]
rho = tanh(eta_rho)
b[g] ~ Normal(0, D[g] R D[g])
D[g] = diag(tau[g, 0], tau[g, 1])
R = [[1, rho], [rho, 1]]
logit(P(y[i] = 1)) = X[i, ] beta + b[g, 0] + x[i] b[g, 1]
```

The corresponding lower factor is

```text
L[g] = [[tau[g, 0], 0],
        [rho tau[g, 1], tau[g, 1] sech(eta_rho)]]
```

Both SDs are marginal coefficient SDs. `rho` is one constant correlation
shared across groups. A selected coefficient can use an SD formula while the
other retains a constant SD parameter. In R syntax, the two selectors are
`sd(id, dpar = "mu", coef = "(Intercept)")` and
`sd(id, dpar = "mu", coef = "x")`; in the Julia formula DSL they are
`sd(id, coef(intercept))` and `sd(id, coef(x))`.

The right-hand-side predictors are fixed effects and must be constant within
the grouping level after response-row filtering. Random effects inside the SD
formula, predictor-dependent correlations, labelled or higher-dimensional
blocks, multiple correlated blocks, structured providers, and more than two
responses are outside this slice. Bernoulli has no free residual `sigma`.

The native TMB partial-target tests now fit intercept-only and slope-only SD
formulas and check covariance reconstruction. The Julia tests compare the
two-target likelihood with independent two-dimensional quadrature, check
finite objective gradients near `rho = 1`, exercise the simulator when finite
`eta_rho` is large enough that `tanh` rounds to one, and refit a slope-only
bootstrap replicate. At `eta_rho = 20`, the Julia likelihood remains unresolved
because the quadrature objective is not finite; the simulator retains a
nonzero innovation through the stable sech transform. This numerical boundary
case remains open and no interval-coverage claim follows from these checks.
A live R-to-Julia smoke now covers fitting, coefficient extraction, group-SD
prediction, and exact coefficient/prediction preservation after RDS reload for
one synthetic dataset. Its fit emitted a singular-Hessian warning, so this
does not establish reliable standard errors or numerical parity with native
TMB. Interval calibration remains open.
