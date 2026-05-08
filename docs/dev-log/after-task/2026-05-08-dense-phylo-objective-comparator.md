# After Task: Dense Phylogenetic Objective Comparator

## Goal

Add a small independent check that the fitted sparse phylogenetic Gaussian
model has the same marginal likelihood as the dense Brownian covariance model.

## Implemented

- Added `dense_phylo_gaussian_nll()` to
  `tests/testthat/test-phylo-gaussian.R`.
- Added a fitted-model test on a four-tip ultrametric tree with three
  observations per species.
- Added a second fitted-model test combining a non-phylogenetic species random
  intercept and a phylogenetic species random intercept.
- Added a third fitted-model test combining known sampling variances from
  `meta_known_V(V = vi)` and a phylogenetic species random intercept.
- The test fits:

```r
drmTMB(
  bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
  family = gaussian(),
  data = dat
)
```

- At the fitted parameters, the test computes the independent dense marginal
  covariance:

```text
Sigma = sigma^2 I + sd_phylo^2 A[species, species]
```

and compares the dense Gaussian negative log likelihood with
`fit$opt$objective`.

For the combined species model, the test fits:

```r
drmTMB(
  bf(y ~ x + (1 | species) + phylo(1 | species, tree = tree), sigma ~ 1),
  family = gaussian(),
  data = dat
)
```

and compares against:

```text
Sigma = sigma^2 I + sd_species^2 I_species + sd_phylo^2 A[species, species]
```

For the known-variance meta-analytic model, the test fits:

```r
drmTMB(
  bf(
    yi ~ x + meta_known_V(V = vi) + phylo(1 | species, tree = tree),
    sigma ~ 1
  ),
  family = gaussian(),
  data = dat
)
```

and compares against:

```text
Sigma = V_known + sigma^2 I + sd_phylo^2 A[species, species]
```

## Mathematical Contract

The fitted sparse path integrates a latent tree effect:

```text
y_i | a_species[i] ~ Normal(X_mu[i, ] beta_mu + a_species[i], sigma^2)
a ~ MVN(0, sd_phylo^2 A)
```

Marginally, the observed response vector satisfies:

```text
y ~ MVN(X_mu beta_mu, sigma^2 I + sd_phylo^2 A_obs)
```

With an additional non-phylogenetic species intercept:

```text
y ~ MVN(
  X_mu beta_mu,
  sigma^2 I + sd_species^2 I_species + sd_phylo^2 A_obs
)
```

With known sampling variance from meta-analysis:

```text
y ~ MVN(X_mu beta_mu, V_known + sigma^2 I + sd_phylo^2 A_obs)
```

where `A_obs = A[species, species]`. For Gaussian random effects, the TMB
Laplace objective should match this dense marginal likelihood up to numerical
tolerance.

## Files Changed

- `tests/testthat/test-phylo-gaussian.R`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'phylo-gaussian')"`
- `Rscript -e "devtools::test(filter = 'phylo')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

## Tests Of The Tests

The new test is independent of the sparse augmented precision calculation used
by the fitted TMB path. It computes a dense covariance matrix from the
Brownian tip covariance helper and evaluates the marginal Gaussian density via
`chol()`. This directly checks the end-to-end mapping from `phylo()` formula
to sparse TMB objective.

## Consistency Audit

- The test matches `docs/design/16-phylo-spatial-common-math.md`, which says
  the first fitted path should be validated against a dense tip covariance on
  small examples.
- The tests use supported public syntax only: ordinary univariate Gaussian
  random intercepts, `meta_known_V(V = V)`, and intercept-only univariate
  Gaussian `phylo()` in `mu`.
- No README, roadmap, or user-facing syntax changed.

## What Did Not Go Smoothly

Nothing substantial. Both comparators passed on targeted runs.

## Team Learning

- Curie correctly identified that sparse algebra tests were already strong,
  but the fitted model still needed a marginal objective comparator.
- Dense comparators are ideal for tiny trees: clear, independent, and
  CRAN-safe.

## Known Limitations

- The comparators validate tiny trees and fitted parameter points.
- Larger simulation and comparator studies are still needed for many species,
  weak phylogenetic signal, near-zero variance components, dense or sparse
  block covariance matrices, and simultaneous phylogenetic plus
  non-phylogenetic species effects.

## Next Actions

1. Add optional long simulations outside CRAN tests for larger trees and
   boundary cases.
2. Keep the dense comparator pattern for the future spatial SPDE path.
