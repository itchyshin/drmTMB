# Ayumi/Santi No-Real-Data Simulation Slices

Reader: Ayumi, Santi, and `drmTMB` contributors checking what can be tested
before the prepared mammal, avian, and ecogeographic datasets are available.

This note records the simulated-only finish for the first five Ayumi/Santi
phylogenetic protocol slices. It uses no real Ayumi or Santi data. The purpose
is to check model routes, extraction, and diagnostic reporting before applied
interpretation begins.

## Slice Set

The driver is `tools/ayumi-santi-finish-sim-slices.R`. Its default output is
`docs/dev-log/ayumi-santi/sim-slices/`.

| Slice | Protocol role | Artifact |
| --- | --- | --- |
| 1 | q2 Objective 1 mini-grid for body mass with clutch or litter size | `q2-mini-grid-summary.csv` |
| 2 | univariate ecogeographic PLSM with phylogenetic `mu` and `sigma` | `univariate-plsm/summary.csv` |
| 3 | q4 bivariate PLSM diagnostic positive control | `q4-positive-control/summary.csv` |
| 4 | lifestyle or nest-habitat split-fit analogue | `split-fit-class-contrast/summary.csv` |
| 5 | integration README and saved result object | `README.md`, `all-results.rds` |

## Simulation Design

Aim: test whether currently fitted Gaussian phylogenetic routes can recover
strong simulated signals and export the tables needed for the protocols.

Data-generating mechanisms:

- q2 mini-grid: species-level bivariate Gaussian traits with known
  phylogenetic location-location correlation, residual `rho12`, and
  trait-specific phylogenetic SDs.
- univariate PLSM: one Gaussian trait with fixed climate predictors in `mu`
  and `sigma`, plus correlated phylogenetic `mu` and `sigma` intercepts.
- q4 bivariate PLSM: two Gaussian traits with fixed predictors and matching
  phylogenetic terms in `mu1`, `mu2`, `sigma1`, and `sigma2`.
- split-fit contrast: three class-pruned q2 fits that mimic terrestrial,
  aquatic, and aerial lifestyle contrasts.

Estimands: phylogenetic `corpairs()` rows, residual `rho12`, convergence code,
`pdHess`, maximum absolute gradient, `check_drm()` rows, and
`profile_targets()` status where available.

Methods: all fitted models use existing `drmTMB` Gaussian univariate or
bivariate phylogenetic surfaces. No new formula grammar, likelihood
parameterization, package API, or class-specific covariance feature is added.

## Current Results

The default run on May 24, 2026 wrote these summaries:

- q2 mini-grid: three cells converged with `pdHess = TRUE`; largest gradient
  was `0.000554`.
- univariate PLSM: truth `mu`-`sigma` phylogenetic correlation was `0.70`,
  estimate was `0.893`, convergence was `0`, `pdHess = TRUE`, and gradient was
  `0.000344`.
- q4 bivariate PLSM: all six phylogenetic correlation rows were exported;
  convergence was `0`, `pdHess = TRUE`, and gradient was `0.00262`. The
  location-location truth was `0.50` with estimate `0.430`; the scale-scale
  truth was `0.55` with estimate `0.564`; residual `rho12` truth was `0.15`
  with estimate `0.145`.
- split-fit class contrast: terrestrial, aquatic, and aerial fits all
  converged with `pdHess = TRUE`. The estimated phylogenetic correlations were
  `-0.839`, `-0.271`, and `0.648` for truths `-0.75`, `-0.20`, and `0.65`.

These results support the developer workflow and extraction path. They do not
support biological claims because every input is simulated.

## What This Closes

The simulated path now covers the first five no-real-data slices requested for
the Ayumi/Santi work:

1. q2 Objective 1 runner and mini-grid.
2. univariate ecogeographic PLSM positive control.
3. q4 bivariate PLSM diagnostic positive control.
4. class-pruned split-fit covariance sensitivity.
5. integrated artifact bundle for handoff.

The next applied step remains unchanged: when the prepared data arrive, run
`tools/ayumi-santi-q2-objective1-runner.R --dry-run true` on the mammal and
avian Objective 1 datasets before fitting representative trees.

## Boundaries

The script deliberately does not implement single-model class-specific
covariance, missing-response marginalization, Bayesian posterior tree pooling,
predictor-dependent q4 `corpair()` formulas, or q4 derived intervals. Those
remain separate design and validation tasks.
