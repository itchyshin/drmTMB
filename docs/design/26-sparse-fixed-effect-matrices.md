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

## Implemented First Path

The first fitted sparse path is opt-in and deliberately narrow:

```r
drmTMB(
  bf(y ~ habitat + x1, sigma ~ 1),
  family = gaussian(),
  data = dat,
  control = drm_control(sparse_fixed = TRUE)
)
```

This stores the `mu` fixed-effect design as a `Matrix` sparse matrix and routes
the univariate Gaussian fixed-effect location predictor through a sparse TMB
matrix multiply. It leaves `sigma` dense and intercept-only. The first path
rejects ordinary random effects, direct random-effect SD models, phylogenetic
and spatial structured effects, known sampling covariance, non-Gaussian
families, bivariate Gaussian models, and non-intercept `sigma` formulas.

The current public control is scalar. A later parameter-specific control could
be added when more distributional parameters are covered:

```r
drm_control(sparse_fixed = c(mu = TRUE, sigma = FALSE))
```

Do not enable sparse fixed effects implicitly. Users should opt in until
dense-versus-sparse parity tests cover all implemented families and prediction
paths.

The internal scaffold uses `drm_fixed_effect_matrix()` to construct either the
existing dense `stats::model.matrix()` result or the matching
`Matrix::sparse.model.matrix()` result. `drm_sparse_fixed_parity()` checks
shape, column names, matrix entries, and a test linear predictor.

## First Supported Scope

The implemented first sparse target is univariate Gaussian fixed-effect
location models without random effects:

```r
drmTMB(
  bf(y ~ habitat + x1, sigma ~ 1),
  family = gaussian(),
  data = dat,
  control = drm_control(sparse_fixed = TRUE)
)
```

After this path has broader likelihood, prediction, simulation, and diagnostic
parity, extend in this order:

- Gaussian `sigma` fixed effects;
- Poisson and negative-binomial `mu` fixed effects with offsets;
- bivariate Gaussian fixed effects for `mu1`, `mu2`, `sigma1`, `sigma2`, and
  `rho12`;
- zero-inflation and hurdle fixed effects.

Random effects, known dense sampling covariance, and phylogenetic precision
matrices should not be the first sparse-fixed implementation target. They add
separate data structures and identifiability checks.

## TMB Data Contract

The sparse path does not replace existing dense matrix names in one step. It
uses a parallel field and flag so dense and sparse implementations can coexist
during testing:

```text
use_sparse_X_mu
X_mu
X_mu_sparse
```

The C++ template routes the first Gaussian `mu` predictor as:

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
any large benchmark claim. The first Gaussian `mu` path checks:

- fixed-effect coefficient estimates within numerical tolerance;
- matching `logLik()`, `fitted()`, fitted-row `predict()`, new-data
  `predict()`, `residuals()`, and seeded `simulate()` output within numerical
  tolerance;
- `check_drm()` design-size reporting for sparse retained matrices;
- explicit tests for factors with unused levels and interactions with empty
  combinations;
- rejection tests for random effects, non-intercept `sigma`, and non-Gaussian
  families;
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

The current dense path reports the density of the largest retained fixed-effect
design block. A wide design with low density is not automatically an error, but
it is a concrete signal that high-cardinality factors or sparse interactions
may be better served by the sparse fixed-effect path when the model is inside
the implemented scope.

The large-data vignette should continue to distinguish the implemented
univariate Gaussian `mu` path from the broader sparse roadmap.

## Open Questions

- Should sparse fixed effects be opt-in globally or parameter-specific?
- Should sparse support require the `Matrix` package at runtime, or is the
  current dependency already sufficient through phylogenetic utilities?
- Should prediction with `newdata` use sparse matrices when the fitted model
  was sparse, or should it choose dense or sparse from the new data shape?
- What threshold should trigger a recommendation to refit with sparse fixed
  effects once the feature exists?
