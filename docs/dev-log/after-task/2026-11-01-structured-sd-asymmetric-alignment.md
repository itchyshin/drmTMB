# After-task: asymmetric alignment tests for structured SD providers

Date: 2026-11-01. Lane: predictor-dependent random-effect SD regression (branch codex/general-sd-regression). New file only: `tests/testthat/test-structured-sd-asymmetric-alignment.R`. No package code, no existing test, and no tolerance was changed.

## Why

The earlier alignment fixtures for the spatial and relatedness providers passed a shuffled or reversed ring or Toeplitz kernel. A reflection or rotation is a symmetry of those kernels, so a positional misreading could survive. Several oracles also built the covariance with `drm_spatial_coords_precision()`, the helper under test.

## What the new file does

For five routes (Poisson spatial, NB2 relmat, NB2 spatial, Gaussian relmat, Gaussian spatial), each with `sd(g, level = ...) ~ z`:

- Coordinates are irregular and non-symmetric (uniform x, exponential y). The relatedness matrix is `D R D` with a random correlation matrix `R` and a random positive diagonal `D` (diagonal range above 0.3), so it is dense, non-Toeplitz and has unequal non-unit diagonals.
- Data factor levels are in a shuffled order. `rownames(K)` and `rownames(coords)` are in a second, different shuffle, and data rows are shuffled as well.
- The covariance is built in the test by hand. Spatial: `exp(-d / m) + 1e-6 I`, with `d` from an explicit double loop of Euclidean distances and `m` the median positive distance, which is the kernel read from the R code. The helper is never called.
- Oracles: Gaussian uses the exact marginal likelihood. Poisson and NB2 use a dense Laplace approximation (damped Newton mode, then `f(u*) - 0.5 log|Sigma| - 0.5 log|H|`). All are evaluated at the fitted parameters with the hand-built covariance indexed by level name.

## Tolerances (fixed before the first run)

- Fitted logLik versus oracle: relative 1e-6.
- Misalignment gap: more than 1000 x 1e-6 x |logLik| and more than 0.5 log-likelihood units.
- Positional reading of the supplied kernel differs from the named one by more than 0.2 (max abs entry).

One adjustment: on the first run the Gaussian relmat gap was 0.36, under the 0.5 absolute bar. I did not loosen the bar. I raised the data-generating SD intercept from log(0.6) to log(0.9) for all routes, which strengthens the random-effect signal, and re-ran everything.

## Results

Test file: 52 expectations, 0 failures. Per route (fitted logLik, relative gap to the oracle, bug-oracle gap):

| Route | logLik | rel. diff to oracle | permuted-level gap |
|---|---|---|---|
| Poisson spatial | -143.21 | 1.6e-13 | 0.67 |
| NB2 relmat | -229.97 | 1.0e-14 | 13.8 |
| NB2 spatial | -318.12 | 3.0e-14 | 12.3 |
| Gaussian relmat | -108.06 | 9.9e-15 | 2.31 |
| Gaussian spatial | -99.70 | 9.1e-15 | 28.0 |

## Permuted-level bug demonstration

The permuted-level bug is simulated in the oracle: the supplied kernel (or coordinates) is read by position against `levels(data$g)`, as a fit would if it ignored row names. The oracle log-likelihood then moves by the "permuted-level gap" column, between 0.67 and 28 log-likelihood units. Against the match tolerance of 1e-6 relative (about 1e-4 absolute here), the smallest gap is thousands of times larger. The Poisson spatial gap is the smallest (0.67 versus the 0.5 bar), so it is the least robust of the five margins; the other four clear 0.5 by a factor of four or more.

This shows the test would catch a positional bug. It does not show the engine has one: the engine matched the by-name oracle to about 1e-13 on every route.

## Not covered

Slope-only fields, Toeplitz, phylo and animal providers, Q or Ainv inputs, `se = TRUE` inference, any family other than Gaussian, Poisson and NB2, calibration or parity claims. The spatial kernel constant (1e-6 jitter, median-distance range) is hand-written from the helper's documented formula, so a change to that formula in the package would fail these tests by design.
