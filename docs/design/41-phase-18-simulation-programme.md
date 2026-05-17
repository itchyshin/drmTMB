# Phase 18 Simulation Programme

Phase 18 is the evidence layer for `drmTMB`: simulation, power, accuracy,
coverage, runtime, and failure-mode reporting. It should follow the ADEMP
structure of Morris, White, and Crowther (2019) and the transparent-reporting
items of Williams et al. (2024), but it should stay practical for ecology,
evolution, and meta-analysis readers.

The first rule is scope. A surface enters the comprehensive simulation only
after it has a fitted likelihood, parser validation, extractors, diagnostics,
interval status, and focused recovery tests. Surfaces that are still only
planned belong in the failure ledger, not in a broad simulation table.

## A - Aims

Primary aim: quantify when fitted `drmTMB` surfaces recover scientifically
interpretable distributional parameters with acceptable bias, coverage, and
diagnostic behaviour.

Secondary aims:

- estimate power for effects on `sigma`, `rho12`, random-effect SDs,
  structured-effect SDs, and direct-SD models under realistic eco-evo sample
  sizes;
- compare narrow `drmTMB` surfaces with standard practice where a comparator is
  defensible, such as Gaussian meta-analysis with known `V`;
- record failure rates, boundary hits, non-positive-definite Hessians, and
  unsupported surfaces instead of silently dropping hard cases.

## D - Data-Generating Mechanisms

Each DGP should be a small named surface, not a giant all-features grid. The
minimum first wave is:

| Surface | Current gate | DGP sketch | Vary first |
| --- | --- | --- | --- |
| Gaussian location-scale | Fitted | `y_i ~ Normal(mu_i, sigma_i^2)` with `mu ~ x` and `log(sigma) ~ z` | `n`, sigma slope, collinearity |
| Gaussian ordinary random effects | Fitted | `y_ij = mu_ij + u_j + e_ij`, optional slopes | groups, observations per group, SD size |
| Gaussian location-scale covariance | Fitted | matched `mu`/`sigma` random intercept blocks | group count, correlation, SD ratio |
| Bivariate Gaussian coscale | Fitted | two responses with `sigma1`, `sigma2`, and `rho12` | residual correlation, missing rows excluded |
| Phylogenetic and spatial Gaussian | Fitted subsets | known relatedness or coordinate covariance plus Gaussian residuals | number of taxa/sites, signal size |
| Gaussian meta-analysis | Fitted | `y ~ MVN(mu, V + Omega_estimated)` with vector or matrix `V` | effect sizes, dense `V`, heterogeneity |
| Poisson `mu` random effects | Pilot only | log-mean count model with ordinary random intercepts/slopes | groups, mean count, SD size |

Later waves can add NB2, zero inflation, hurdle, ordinal, shape/skew, and
non-Gaussian scale/random-effect surfaces only after their focused gates are
closed. The failure ledger in `docs/design/34-validation-debt-register.md`
names these blocked surfaces.

Every DGP file should state the hierarchy, true fixed effects, random-effect
distributions, covariance labels, sampling covariance `V` when present,
interval target truths, varied conditions, and number of replicates per cell.

## E - Estimands

Store both the true value and the estimator output for each estimand:

| Class | Truth | Estimator output |
| --- | --- | --- |
| Fixed effects | DGP coefficient on the link scale | `coef(fit, dpar)` |
| Residual scale | response-scale `sigma` or sigma ratio | `sigma(fit)` or documented transform of `coef(fit, "sigma")` |
| Residual correlation | true `rho12` or mean true `rho12_i` | `rho12(fit)` and `profile_targets()` rows |
| Random-effect SD | true group-level SD | `sdpars` and direct profile target |
| Random-effect correlation | true block correlation | `corpars`, `corpairs()`, and profile target when direct |
| Known sampling covariance | supplied `V` | no estimator; it is input data and must not become an interval target |
| Derived quantities | repeatability, variance share, total observation variance | explicit formula from fitted components |

Replicate-specific truths should be saved when they depend on realised sample
sizes, realised `V`, or a generated covariance matrix.

## M - Methods

The first implementation should fit the intended `drmTMB` model, a simpler
nested `drmTMB` model when the question is power or false-positive rate, and at
most one external comparator per surface where the parameterization and
likelihood are close enough to be honest.

Do not create a comparator zoo. If `glmmTMB`, `brms`, `metafor`, ASReml, or
MCMCglmm cannot fit the same parameter target, the report should say that
directly rather than forcing an unfair comparison.

## P - Performance Measures

Each report should include the metric and its Monte Carlo standard error:

| Measure | Formula | Report with |
| --- | --- | --- |
| Bias | `mean(theta_hat - theta_true)` | MCSE of the mean |
| Relative bias | `mean((theta_hat - theta_true) / theta_true)` when denominator is stable | MCSE of the mean |
| RMSE | `sqrt(mean((theta_hat - theta_true)^2))` | bootstrap or delta MCSE |
| Coverage | `mean(lo <= theta_true & theta_true <= hi)` | `sqrt(p * (1 - p) / n_sim)` |
| Power | `mean(ci_excludes_null)` or test rejection | binomial MCSE |
| Convergence | `mean(converged & pdHess)` | binomial MCSE |
| Boundary rate | `mean(check_drm_boundary_flag)` | binomial MCSE |
| Runtime | median and high quantiles | MCSE or bootstrap interval |

Coverage MCSE should be planned before running large grids. Coverage near 0.95
has MCSE about 1.0 percentage point with 500 replicates and about 0.7
percentage points with 1000 replicates. A pilot grid can use fewer replicates
if it is labelled as a pilot and does not make final coverage claims.

## Implementation Layout

Use a resumable layout:

```text
inst/sim/
  dgp/
    sim_dgp_gaussian_ls.R
    sim_dgp_meta_v.R
  fit/
    sim_fit_drmtmb.R
    sim_fit_comparators.R
  run/
    0_prepare_cells.R
    1_run_cells.R
    2_summarise_cells.R
  reports/
    phase18-gaussian-ls.qmd
    phase18-meta-analysis.qmd
```

Per-cell results should be saved as RDS files with replicate seeds, fit status,
warnings, elapsed time, `check_drm()` rows, interval status, and session info.
CRAN tests should only run smoke checks for seed stability and output shape.

## Williams-Style Self-Audit

| Item | Covered by this blueprint |
| --- | --- |
| 1. Aims | Named in the A section. |
| 2. Data-generating mechanisms | Named by surface with required DGP fields. |
| 3. Estimands | Truth and estimator output table. |
| 4. Methods | `drmTMB`, nested models, and limited comparators. |
| 5. Performance measures | Bias, RMSE, coverage, power, convergence, boundary, runtime. |
| 6. Software and settings | Required session info and seeds in per-cell output. |
| 7. Code availability | Planned under `inst/sim/` and rendered reports. |
| 8. Replicability | Per-cell RDS output and replicate-level seeds. |
| 9. Real-data motivation | Reports should pair each simulation wave with the relevant tutorial/example. |
| 10. Complete results | Failed fits, boundary hits, and diagnostics are reported, not dropped. |
| 11. Monte Carlo uncertainty | Every aggregate metric carries an MCSE or bootstrap uncertainty estimate. |

## First Three Slices

1. Slice 210 adds the `inst/sim/` skeleton, seed helper, cell registry, and
   one tiny CRAN-safe smoke test.
2. Slice 211 should implement the Gaussian location-scale DGP and a pilot
   summariser.
3. Slice 212 should implement the Gaussian meta-analysis `meta_V(V = V)` DGP
   with vector `V`, dense matrix `V`, and interval-target checks.
