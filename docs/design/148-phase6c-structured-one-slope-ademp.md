# Phase 6c Structured Gaussian One-Slope ADEMP Sheet

## Purpose

This note is the #442/#446 operating-characteristic design sheet for fitted
Gaussian structured `mu` one-slope paths. It follows the ADEMP framework of
Morris, White, and Crowther (2019) and the Williams et al. (2024)
transparent-reporting checklist for simulation studies.

The sheet covers only one numeric univariate Gaussian `mu` slope with
independent structured intercept and slope fields for `phylo()`, `spatial()`,
`animal()`, and `relmat()`. It does not run grids, does not promote coverage or
power evidence, and does not open multiple structured slopes, structured slope
correlations, residual-scale structured slopes, structured `rho12`,
non-Gaussian structured slopes, mesh/SPDE spatial slopes, or q2/q4 covariance.

`spatial()` is the Actions-ready artifact route because it already has the
manual `spatial_mu_slope` Phase 18 task. `phylo()`, `animal()`, and
`relmat()` now have local wrapper-target artifact writers. None of these
route-maturity labels is recovery, coverage, or power evidence.

## A - Aims

Primary aim: estimate when one numeric Gaussian structured `mu` slope recovers
the fixed `mu` slope, the structured intercept-field SD, and the structured
slope-field SD without optimizer, Hessian, boundary, or diagnostic failures.

Secondary aim 1: compare the four structured routes without borrowing artifact
maturity across them. Coordinate-spatial one-slope evidence may use the
existing `spatial_mu_slope` task; phylogenetic, animal-model, and generic
known-matrix routes may use their local wrapper-target writers.

Secondary aim 2: keep q2/q4 structured covariance, `corpairs()`, residual
coscale `rho12`, residual-scale structured effects, non-Gaussian structured
effects, and multiple or correlated structured slopes out of this lane.

## D - Data-Generating Mechanism

For observation `i` in structured level `j`, use one numeric predictor with
within-level variation:

```text
y_ij ~ Normal(mu_ij, sigma^2)
mu_ij = beta0 + beta1 x_ij + a0_j + a1_j x_ij
a0 ~ MVN(0, sd_intercept^2 C)
a1 ~ MVN(0, sd_slope^2 C)
Cov(a0, a1) = 0
```

The structured covariance or precision object `C` depends on the route:

| Route | Structure in the DGP | Intended fitted syntax |
| --- | --- | --- |
| `phylo()` | Tree-derived species covariance, scaled to a correlation matrix. | `bf(y ~ x + phylo(1 + x | species, tree = tree), sigma ~ 1)` |
| `spatial()` | Coordinate-derived spatial covariance or precision over sites. | `bf(y ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1)` |
| `animal()` | Dense pedigree or known relationship matrix for individuals. | `bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1)` |
| `relmat()` | User-supplied known covariance `K` or precision `Q`. | `bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1)` |

First-wave condition grid:

| Factor | Pilot levels | Why it matters |
| --- | --- | --- |
| structured route | `phylo()`, `spatial()`, `animal()`, `relmat()` | Keeps route-specific covariance construction and artifact maturity separate. |
| levels | 30, 80 | Structured SD recovery is limited by the number of taxa, sites, individuals, or matrix levels. |
| observations per level | 3, 8 | Within-level replication and covariate spread identify the slope field. |
| intercept-field SD | 0.20, 0.60 | Checks weak and moderate structured intercept signal. |
| slope-field SD | 0.10, 0.35 | Checks near-boundary and moderate structured slope signal. |
| residual `sigma` | low, moderate | High residual noise can mask slope-field recovery. |
| covariate spread | narrow, regular | Separates weak design information from weak structured signal. |
| structure stress | route-specific mild, hard | Tree imbalance, spatial clustering, pedigree density, or matrix conditioning can dominate failures. |

Use `n_rep = 200` only for route-specific pilots. A formal interval, coverage,
or power grid should set replicates from a Monte Carlo standard-error target
before dispatch. For example, 500 replicates gives approximately 1 percentage
point MCSE for 95% coverage; 1000 replicates gives about 0.7 percentage points.

## E - Estimands

Store truth and estimates for:

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Fixed `mu` intercept and slope | `beta0`, `beta1` | `coef(fit, "mu")` rows |
| Structured intercept-field SD | `sd_intercept` | `sdpars$mu` intercept row and direct `profile_targets()` SD row where available |
| Structured slope-field SD | `sd_slope` | `sdpars$mu` slope row and direct `profile_targets()` SD row where available |
| Conditional structured slope signal | realised `a1_j` values | `ranef(fit, "mu")` slope terms and signal/rank correlation with truth, reported as a diagnostic |
| Residual scale | `sigma` | `sigma(fit)` or `coef(fit, "sigma")` on the documented scale |
| Diagnostics | known successful fit status | convergence, `pdHess`, warnings, `check_drm()` rows, boundary flags, elapsed time |
| Artifact maturity | route-specific route status | `spatial_mu_slope` task status or local `phylo()`/`animal()`/`relmat()` writer status |

Do not report slope-field SD recovery as evidence for q2/q4 covariance,
`corpairs()`, residual `rho12`, or structured residual-scale effects. Those are
different estimands.

## M - Methods

Fit the intended `drmTMB` Gaussian one-response model for each route:

```r
bf(y ~ x + phylo(1 + x | species, tree = tree), sigma ~ 1)
bf(y ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1)
bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1)
bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1)
```

First pilots should include two nested `drmTMB` comparators for the same DGP:

1. fixed `x` plus structured intercept only;
2. fixed `x` plus ordinary grouped `(1 + x | id)` where the grouping levels
   match and the comparison is diagnostic rather than a substitute for the
   structured target.

External comparators stay out unless #60 defines a matched estimator with the
same known covariance or precision target. Comparator-package success does not
count as `drmTMB` recovery, coverage, or power evidence.

## P - Performance Measures

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(theta_hat - theta_true)` for fixed `mu`, residual scale, and structured SD targets |
| RMSE | `sqrt(mean((theta_hat - theta_true)^2))` |
| Link-scale accuracy | fixed-effect and structured SD errors on the fitted Gaussian `mu`/SD scales |
| Conditional-signal recovery | correlation and rank correlation between realised `a1_j` and estimated slope terms |
| Coverage | planned only until direct fixed-effect and SD interval-status artifacts identify Wald, profile, failed, or not-requested rows |
| Power or Type I error | planned only until a null/alternative, nested comparator, rejection rule, and MCSE target are named |
| Convergence rate | proportion with optimizer convergence and usable `pdHess` |
| Boundary rate | near-zero structured SDs, non-positive-definite covariance construction, warnings, or `check_drm()` non-ok rows |
| Route artifact readiness | `spatial_mu_slope` task status and local `phylo()`/`animal()`/`relmat()` writer status |
| Failed-fit retention | failed and warning-heavy replicates remain in manifest/failure artifacts rather than being silently dropped |
| Runtime | median and high quantiles of elapsed fit time |

Every aggregate metric should include an MCSE column or companion MCSE table
before formal reporting.

## Williams 11-Item Self-Audit

| Item | Current status |
| --- | --- |
| 1. Aims | Covered for one numeric Gaussian structured `mu` slope recovery and artifact admission. |
| 2. Data-generating mechanisms | Hierarchy, structured intercept and slope fields, route-specific covariance objects, and first-wave conditions are specified. |
| 3. Estimands | Fixed `mu`, structured intercept and slope SDs, conditional slope signal, residual scale, diagnostics, and artifact maturity are named. |
| 4. Methods | Intended `drmTMB` formulas and nested `drmTMB` comparators are specified; external comparators are gated through #60. |
| 5. Performance measures | Bias, RMSE, signal recovery, diagnostics, runtime, artifact readiness, and planned-only coverage/power are specified. |
| 6. Software and computing details | To be recorded by the runner with session info, package versions, seed, backend, and covariance-construction details. |
| 7. Code availability | Spatial, `phylo()`, `animal()`, and `relmat()` DGPs, runners, and grid writers live under `inst/sim/`. |
| 8. Random-number generation | To be specified in the runner using master and replicate-level seeds. |
| 9. Empirical application | Not required for this planning sheet; tutorials should keep each structured route tied to its biological or known-matrix question. |
| 10. Results reporting | To include aggregate plus replicate-level artifacts, failures, boundary flags, interval-status rows, and route maturity. |
| 11. Monte Carlo uncertainty | Pilot uses 200 replicates; formal coverage/power needs an MCSE target before dispatch. |

## Boundary

This sheet does not design q2/q4 structured covariance, direct-SD regression,
`corpair()`/`corpairs()` regression, random effects in residual `rho12`,
residual-scale structured slopes, multiple structured slopes, structured
slope correlations, mesh/SPDE spatial slopes, count structured slopes, or
non-Gaussian structured slopes. Those remain separate planned, diagnostic-only,
or blocked surfaces until their own likelihood, extractor, interval,
diagnostic, and simulation evidence exists.
