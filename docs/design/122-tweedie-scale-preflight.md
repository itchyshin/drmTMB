# Tweedie Scale-Mapping Preflight

This note is for the package contributor who would implement the first
`tweedie()` lane after the design decision is accepted. It does not claim fitted
Tweedie support. The current source map says Tweedie is future-only in
`docs/design/27-tweedie-family-plan.md`, and the planned likelihood section in
`docs/design/03-likelihoods.md` is a contract draft rather than an implemented
TMB branch.

## Pre-Implementation Decision To Carry Forward

Use public `sigma` as the square root of Tweedie dispersion in the first
implementation proposal:

```text
y_i | mu_i, sigma_i, nu_i ~ Tweedie(mu_i, phi_i, nu_i)
log(mu_i) = eta_mu_i
log(sigma_i) = eta_sigma_i
phi_i = sigma_i^2
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

This is a design commitment for the proposed lane, not fitted-package support.
It matches the package-level scale convention better than exposing `sigma =
phi` directly. In the implemented positive-continuous families, larger `sigma`
means larger response variability: Gamma uses `Var[y_i] = mu_i^2 sigma_i^2`,
and NB2 uses the same square-scale orientation for overdispersion. The Tweedie
lane should keep that reader-facing rule. Comparator tests must therefore name
the transform explicitly: compare `sigma_i^2` from `drmTMB` with Tweedie
dispersion `phi_i` from comparator software.

The power parameter should use canonical `nu` and stay in the open interval
`1 < nu < 2`. The first implementation should use intercept-only `nu ~ 1`.
Predictor-dependent power models are deferred because power, zero mass, scale,
and mean effects can trade off in small ecological data sets.

## Comparator Target

The first comparator target is `glmmTMB::tweedie(link = "log")`. Local design
notes already record that glmmTMB reports Tweedie dispersion `phi`, uses a
variance form `phi * mu^power`, and constrains the power parameter to
`1 < power < 2`. `glmmTMB` is already listed in `DESCRIPTION` under `Suggests`,
so comparator tests can be optional without adding a package dependency.

`statmod` is not currently listed in `DESCRIPTION`. Use it only if an
implementation-specific source review shows that it provides the safest density
or simulation reference for the intended parameterization. If any density code
or algorithm is ported or adapted from `statmod`, glmmTMB, or another package,
record provenance in `inst/COPYRIGHTS` before treating the lane as complete.

## First Slice Boundary

The first Tweedie slice should be univariate, fixed-effect, and non-spatial:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ 1),
  family = tweedie(),
  data = dat
)
```

That syntax is future syntax until the family helper, R builder, TMB branch,
methods, tests, and documentation land together. The first slice should accept
non-negative finite responses with exact zeros and positive continuous values.
It should reject negative responses.

The first slice should not admit:

- random effects in `mu`, `sigma`, or `nu`;
- random slopes;
- labelled covariance blocks;
- `sd(group) ~ ...` random-effect scale formulas;
- `meta_V(V = V)` or deprecated `meta_known_V(V = V)`;
- `phylo()`, `spatial()`, `animal()`, or `relmat()` structured effects;
- bivariate Tweedie models, mixed-response models, `mvbind()`, or `rho12`;
- predictor-dependent `nu ~ x`; and
- zero-inflation, hurdle, or conditional-positive aliases.

These are malformed neighbours for the first lane, not implementation
shortcuts. Each needs its own likelihood, extractor, diagnostic, interval, and
simulation-recovery evidence before becoming fitted syntax.

## Minimum Tests Before Code Lands

CRAN-safe tests should be small, deterministic, and source their own simulated
data. The minimum set is:

1. Simulate from known `mu`, `sigma`, and intercept-only `nu`; fit the model;
   check optimizer convergence, positive Hessian status when available, and
   recovery on the link scale.
2. Include at least two support regimes: a low-zero-mass setting and a
   high-zero-mass setting, with simulations preserving both exact zeros and
   positive continuous values.
3. Cover small and large public `sigma`, and `nu` values near the interior
   edges without placing truth exactly on the boundaries.
4. Include factor predictors in `mu` and `sigma`, plus missing-value filtering
   before the response-support check.
5. Check `fitted()` as the unconditional response mean `mu`, not the
   conditional positive mean.
6. Check `sigma()` and `predict(dpar = "sigma")` on the public `sigma` scale,
   with comparator tests comparing `sigma^2` to comparator `phi`.
7. Compare a small fitted data set against `glmmTMB::tweedie(link = "log")`
   when glmmTMB is available, including coefficient agreement on named scales
   and log-likelihood agreement within a documented tolerance.
8. Add malformed-neighbour tests for every boundary listed above.

Longer operating-characteristic grids belong in optional `inst/sim` runners,
not routine tests. A larger grid should vary sample size, baseline `sigma`,
power `nu`, mean-scale predictor correlation, zero mass, and factor predictors;
it should report Monte Carlo error before making coverage or recovery claims.

## Files Read For This Preflight

- `docs/design/27-tweedie-family-plan.md`: existing design gate and open
  questions.
- `docs/design/03-likelihoods.md`: planned Tweedie equations and comparator
  wording.
- `docs/design/02-family-registry.md`: current fitted-versus-planned family
  status and future Tweedie scale note.
- `docs/design/06-distribution-roadmap.md`: positive-continuous roadmap order.
- `docs/design/19-family-link-contract.md`: existing `sigma`, `fitted()`, and
  response-scale conventions.
- `DESCRIPTION`: optional comparator availability through `Suggests`.
