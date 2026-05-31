# Phase 6c Gaussian Random-Slope ADEMP Sheet

## Purpose

This note is the first #446 operating-characteristic design sheet for the
random-slope sprint. It plans a simulation lane; it does not run grids or claim
accuracy, coverage, or power. The first lane is ordinary Gaussian grouped
random slopes because #439 has already separated fitted q > 2 `mu` support,
independent `sigma` slope support, and planned residual-scale covariance
neighbours.

The design follows the ADEMP structure from Morris, White, and Crowther (2019)
and the transparent-reporting checklist of Williams et al. (2024). The reader
is a future Curie or Fisher agent choosing the first replicate grid, not a user
trying to fit a production model.

## A - Aims

Primary aim: estimate when ordinary Gaussian `mu` q > 2 grouped random-slope
models recover fixed effects and random-effect SDs with acceptable bias, RMSE,
diagnostics, and interval coverage.

Secondary aim 1: estimate when independent Gaussian residual-scale random
slopes on `log(sigma)`, such as `sigma ~ z + (0 + w | id)`, recover the
residual-scale fixed effect and slope SD without boundary or Hessian failures.

Secondary aim 2: define a later power lane for random-slope SDs only after the
null and alternative models, rejection rule, replicate count, and Monte Carlo
standard-error target are specified.

## D - Data-Generating Mechanism

Use one grouped hierarchy with observations `i` nested in groups `j`. For the
first `mu` lane,

```text
y_ij ~ Normal(mu_ij, sigma^2)
mu_ij = beta_0 + beta_1 x1_ij + beta_2 x2_ij + b_0j + b_1j x1_ij + b_2j x2_ij
b_j ~ MVN(0, Sigma_b)
```

Fit the intended model with `(1 + x1 + x2 | id)` in `mu`. The q > 2 SD rows are
direct interval targets; q > 2 correlation rows are derived rows and should be
reported as point-estimate diagnostics unless a later interval method lands.

For the first `sigma` lane,

```text
y_ij ~ Normal(mu_ij, sigma_ij^2)
mu_ij = beta_0 + beta_1 x_ij + b_0j
log(sigma_ij) = gamma_0 + gamma_1 z_ij + a_j w_ij
a_j ~ Normal(0, sigma_a^2)
```

Fit the intended model with `sigma ~ z + (0 + w | id)`. Do not add
`sigma ~ z + (1 + w | id)` or labelled residual-scale covariance in this lane.

First-wave condition grid:

| Factor | Pilot levels | Why it matters |
| --- | --- | --- |
| groups | 30, 80 | Random-slope SD and correlation estimates are group-count limited. |
| observations per group | 4, 8 | Slope and residual-scale effects need within-group spread. |
| slope SD | 0.15, 0.45 | Small SDs test boundary behaviour; larger SDs test recovery. |
| covariate spread | standard normal, low-spread within group | Weak within-group variation should increase diagnostics. |
| residual `sigma` | 0.6, 1.2 | Separates random-slope signal from residual noise. |
| random-effect correlation | 0, 0.4 for `mu` q > 2 only | Correlations are fitted point estimates but not direct interval targets. |

Use `n_rep = 200` for a pilot labelled as exploratory. A formal coverage grid
should use at least 500 replicates for about one percentage point of Monte
Carlo standard error near 95 percent coverage, or 1000 replicates for about
0.7 percentage points.

## E - Estimands

Store replicate-specific truths and estimates for:

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Fixed effects | `beta` or `gamma` used in the DGP | `coef(fit, "mu")` or `coef(fit, "sigma")` |
| Random-effect SDs | diagonal SDs of `Sigma_b` or `sigma_a` | `sdpars$mu`, `sdpars$sigma`, and direct `profile_targets()` rows |
| `mu` q > 2 correlations | off-diagonal correlations in `Sigma_b` | `corpars$re_cov`, `corpairs()`, and `summary(fit)$covariance` point rows |
| Residual scale | `sigma` or row-specific `sigma_ij` | `sigma(fit)` and fitted `log(sigma)` coefficients |
| Diagnostics | known successful fit status | convergence, `pdHess`, warnings, boundary flags, elapsed time |

Do not treat q > 2 correlation intervals as an estimand until a direct or
derived interval method exists.

## M - Methods

Fit the intended `drmTMB` model and one nested `drmTMB` comparator per lane.
For the `mu` lane, the nested comparator omits random slopes and keeps the
random intercept. For the `sigma` lane, the nested comparator omits the
residual-scale random slope while keeping the `mu` random intercept. External
comparators are out of scope for the first grid unless #60 defines a matching
parameter target.

## P - Performance Measures

Report each metric with a Monte Carlo standard error or an explicit pilot-only
label:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(theta_hat - theta_true)` |
| RMSE | `sqrt(mean((theta_hat - theta_true)^2))` |
| Coverage | `mean(lo <= theta_true & theta_true <= hi)` for direct targets only |
| Boundary rate | proportion of fits with near-zero SD, failed Hessian, or `check_drm()` boundary flags |
| Convergence rate | proportion with optimizer convergence and usable `pdHess` |
| Runtime | median and high quantiles of elapsed fit time |
| Power | planned only until the null/alternative, target, rejection rule, and MCSE target are named |

## Williams 11-Item Self-Audit

| Item | Current status |
| --- | --- |
| 1. Aims | Covered above for `mu` q > 2 recovery and independent `sigma` slope recovery. |
| 2. Data-generating mechanisms | Pilot hierarchy and first condition grid are specified. |
| 3. Estimands | Fixed effects, SDs, correlation point rows, residual scale, and diagnostics are named. |
| 4. Methods | Intended `drmTMB` fits and one nested `drmTMB` comparator per lane are specified. |
| 5. Performance measures | Bias, RMSE, coverage for direct targets, diagnostics, runtime, and planned-only power are specified. |
| 6. Software and computing details | To be recorded by the runner with session info, package versions, seed, and backend. |
| 7. Code availability | To be recorded when a runner/grid writer is added under `inst/sim/`. |
| 8. Random-number generation | To be specified in the runner using master and replicate-level seeds. |
| 9. Empirical application | Not required for this planning sheet; #444 tutorial work provides the reader-facing example lane. |
| 10. Results reporting | To be aggregate plus replicate-level artifacts, including failed fits and interval status. |
| 11. Monte Carlo uncertainty | Pilot uses 200 replicates; formal coverage requires the MCSE target before dispatch. |

## Boundary

This sheet does not admit correlated residual-scale slope blocks, labelled
residual-scale slope covariance, broader bivariate random slopes, or non-Gaussian
random-slope recovery. Those surfaces stay in their own child issues or in the
failure ledger until fitted evidence and operating-characteristic designs exist.
