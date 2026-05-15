# Sparse Fixed-Effect Matrices

## Purpose

Large `drmTMB` models can fail before TMB optimization when R expands
high-cardinality factors or sparse interactions with dense `model.matrix()`.
This design note scopes the future sparse fixed-effect path. It is for package
contributors and method developers working on large ecological, evolutionary,
and environmental-science datasets.

The goal is not to make every formula sparse. The goal is to keep models with
many mostly-zero fixed-effect columns from copying dense matrices when a sparse
matrix represents the same linear predictor.

## Current Contract

The current R builders create dense matrices such as `X_mu`, `X_sigma`,
`X_nu`, `X_zi`, `X_hu`, `X_mu1`, `X_mu2`, and `X_rho12` with
`stats::model.matrix()`. The TMB data list passes those matrices to the C++
template, and the template multiplies them by the relevant coefficient vectors
inside each likelihood branch.

This path is simple and well tested, but it is not a million-row design. A
100,000-row benchmark with a 40-level factor produced a dense location design
matrix of about 45 MB and did not produce a clean optimizer convergence result
under the benchmark settings. That row is diagnostic evidence, not a
performance claim.

## Proposed Sparse Path

Add an internal construction path that can build selected fixed-effect design
matrices with `Matrix::sparse.model.matrix()`. A future public control could be
explicit, for example:

```r
drm_control(sparse_fixed = TRUE)
```

or parameter-specific if the first implementation needs tighter scope:

```r
drm_control(sparse_fixed = c(mu = TRUE, sigma = FALSE))
```

Do not enable sparse fixed effects implicitly at first. Users should opt in
until dense-versus-sparse parity tests cover all implemented families and
prediction paths.

The first internal scaffold is now in place. `drm_fixed_effect_matrix()` can
construct either the existing dense `stats::model.matrix()` result or the
matching `Matrix::sparse.model.matrix()` result, and
`drm_sparse_fixed_parity()` checks shape, column names, matrix entries, and a
test linear predictor. These helpers are not yet connected to `drmTMB()`
fitting; they exist so the first sparse implementation can start from a tested
dense-versus-sparse contract.

## First Supported Scope

The first sparse target should be univariate Gaussian fixed-effect location
models without random effects:

```r
drmTMB(
  bf(y ~ habitat + x1, sigma ~ 1),
  family = gaussian(),
  data = dat,
  control = drm_control(sparse_fixed = TRUE)
)
```

After that path has likelihood, prediction, simulation, and diagnostic parity,
extend in this order:

- Gaussian `sigma` fixed effects;
- Poisson and negative-binomial `mu` fixed effects with offsets;
- bivariate Gaussian fixed effects for `mu1`, `mu2`, `sigma1`, `sigma2`, and
  `rho12`;
- zero-inflation and hurdle fixed effects.

Random effects, known dense sampling covariance, and phylogenetic precision
matrices should not be the first sparse-fixed implementation target. They add
separate data structures and identifiability checks.

## TMB Data Contract

The sparse path should not replace existing dense matrix names in one step.
Use a parallel set of fields and flags so dense and sparse implementations can
coexist during testing:

```text
use_sparse_X_mu
X_mu
X_mu_sparse
```

The C++ template should route through a small helper for each linear predictor:

```text
eta_mu = X_mu * beta_mu              if dense
eta_mu = X_mu_sparse * beta_mu       if sparse
```

This keeps likelihood equations unchanged:

```text
eta_mu_i = X_mu[i, ] beta_mu
mu_i = eta_mu_i
```

Only the storage and multiplication method changes. The statistical model does
not change.

## Required Tests

Each sparse phase needs dense-versus-sparse parity tests on small data before
any large benchmark claim:

- identical fixed-effect coefficient estimates within numerical tolerance;
- identical `logLik()`, `fitted()`, `predict()`, `residuals()`, and
  `simulate(seed = ...)` output where deterministic;
- matching `check_drm()` status rows except for expected design-size messages;
- explicit tests for factors with unused levels and interactions with empty
  combinations;
- `keep_model_frame = FALSE` compatibility, because large sparse workflows
  should also support memory-light fitted objects.

## User-Facing Diagnostics

`check_drm()` now reports `fixed_effect_design_size`. That diagnostic should
remain useful after sparse support lands:

- dense fits should report dense fixed-effect matrix sizes;
- dense fits should report nonzero counts or density so users can distinguish a
  wide but genuinely dense design from a wide mostly-zero design;
- sparse fits should report sparse fixed-effect matrix sizes and nonzero
  counts;
- mixed dense/sparse fits should name which distributional-parameter block is
  largest.

The current dense path already reports the density of the largest retained
fixed-effect design block. A wide design with low density is not automatically
an error, but it is a concrete signal that high-cardinality factors or sparse
interactions may be better served by the future sparse fixed-effect path.

The large-data vignette should continue to say that sparse fixed effects are
planned until dense-versus-sparse parity tests and TMB branches are in place.

## Open Questions

- Should sparse fixed effects be opt-in globally or parameter-specific?
- Should sparse support require the `Matrix` package at runtime, or is the
  current dependency already sufficient through phylogenetic utilities?
- Should prediction with `newdata` use sparse matrices when the fitted model
  was sparse, or should it choose dense or sparse from the new data shape?
- What threshold should trigger a recommendation to refit with sparse fixed
  effects once the feature exists?
