# Phase 6c Bivariate Gaussian Slope-Only ADEMP Sheet

## Purpose

This note is the second #446 operating-characteristic design sheet for the
random-slope sprint. It plans the #440 bivariate Gaussian matching
`mu1`/`mu2` slope-only lane. It does not run grids or promote the lane from
artifact-ready to recovery, coverage, or power evidence.

The central boundary is separation: residual coscale `rho12` is an observation-
level residual correlation, while the slope-only random-effect correlation is a
group-level covariance row reported through `corpairs()`. They are different
estimands and must not be combined in simulation summaries.

## A - Aims

Primary aim: estimate when the matching bivariate Gaussian `mu1`/`mu2`
slope-only model recovers both response-specific fixed slopes, both
group-level random-slope SDs, and the group-level slope-slope correlation.

Secondary aim 1: check that residual `rho12` recovery remains stable when a
group-level slope-slope covariance is fitted at the same time.

Secondary aim 2: keep the q4 and q6 location smoke lanes,
p8/q8 bivariate random-slope covariance, residual-scale slope
covariance, and random effects in `rho12` out of this slope-only lane.

## D - Data-Generating Mechanism

Use paired responses `y1_ij` and `y2_ij` for observation `i` in group `j`.

```text
(y1_ij, y2_ij)' ~ MVN(mu_ij, R)
mu1_ij = beta10 + beta11 x_ij + b1_j x_ij
mu2_ij = beta20 + beta21 x_ij + b2_j x_ij
(b1_j, b2_j)' ~ MVN(0, Sigma_b)
R = [[sigma1^2, rho12 sigma1 sigma2],
     [rho12 sigma1 sigma2, sigma2^2]]
```

Fit the intended model with matching slope-only group terms:

```r
drm_formula(
  mu1 = y1 ~ x + (0 + x | p | id),
  mu2 = y2 ~ x + (0 + x | p | id),
  sigma1 = ~ 1,
  sigma2 = ~ 1,
  rho12 = ~ 1
)
```

First-wave condition grid:

| Factor | Pilot levels | Why it matters |
| --- | --- | --- |
| groups | 30, 80 | The group-level slope-slope correlation is group-count limited. |
| observations per group | 4, 8 | Within-group spread drives slope identification. |
| slope SDs | `(0.20, 0.20)`, `(0.20, 0.45)` | Checks balanced and imbalanced random-slope scales. |
| slope-slope correlation | 0, 0.4 | Tests the group-level covariance row without q4 endpoints. |
| residual `rho12` | 0, 0.5 | Keeps residual coscale recovery separate from group covariance. |
| residual scale ratio | 1, 2 | Checks whether unequal response scales destabilize correlation rows. |

Use `n_rep = 200` only for a pilot. A formal coverage grid should choose the
replicate count from the Monte Carlo standard error target before dispatch.

## E - Estimands

Store truth and estimates for:

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Response-specific fixed slopes | `beta11`, `beta21` | `coef(fit, "mu1")["x"]`, `coef(fit, "mu2")["x"]` |
| Random-slope SDs | diagonal SDs of `Sigma_b` | `sdpars$mu`, `profile_targets()` direct SD rows |
| Group-level slope-slope correlation | correlation in `Sigma_b` | `corpairs(fit, class = "mean-slope")` and `summary(fit)$covariance` point row |
| Residual scales | `sigma1`, `sigma2` | `sigma(fit)$sigma1`, `sigma(fit)$sigma2` |
| Residual coscale | `rho12` in `R` | `rho12(fit)` and direct residual `profile_targets()` row |
| Diagnostics | known successful fit status | convergence, `pdHess`, warnings, boundary flags, elapsed time |

The group-level slope-slope correlation and residual `rho12` should appear in
separate report columns.

## M - Methods

Fit the intended `drmTMB` bivariate Gaussian model and two nested `drmTMB`
comparators:

1. no group-level slope covariance, keeping residual `rho12`;
2. residual `rho12 = ~ 1` with the matching slope-only block retained, for
   recovery checks where residual coscale is part of the target.

External comparators are out of scope unless #60 defines a method with the
same residual and group-level covariance targets.

## P - Performance Measures

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(theta_hat - theta_true)` for fixed slopes, SDs, residual scales, residual `rho12`, and group-level slope correlation |
| RMSE | `sqrt(mean((theta_hat - theta_true)^2))` |
| Coverage | Direct fixed-effect, SD, residual-scale, and residual `rho12` targets only, unless group-level correlation intervals are explicitly direct and validated |
| Separation errors | count any report row that swaps residual `rho12` and group-level slope correlation targets |
| Convergence rate | proportion with optimizer convergence and usable `pdHess` |
| Boundary rate | proportion with near-zero slope SD, correlation boundary, or diagnostic flags |
| Runtime | median and high quantiles of elapsed fit time |
| Power | planned only until the null/alternative and rejection rule are named |

## Williams 11-Item Self-Audit

| Item | Current status |
| --- | --- |
| 1. Aims | Covered for bivariate slope-only recovery and residual/group-correlation separation. |
| 2. Data-generating mechanisms | Pilot hierarchy, residual covariance, slope covariance, and condition factors are specified. |
| 3. Estimands | Fixed slopes, SDs, group-level correlation, residual scales, residual `rho12`, and diagnostics are named. |
| 4. Methods | Intended and nested `drmTMB` models are specified; external comparators are deferred. |
| 5. Performance measures | Bias, RMSE, direct-target coverage, separation errors, diagnostics, runtime, and planned-only power are specified. |
| 6. Software and computing details | To be recorded by the runner with session info, package versions, seed, and backend. |
| 7. Code availability | To be recorded when a runner/grid writer is added or extended under `inst/sim/`. |
| 8. Random-number generation | To be specified in the runner using master and replicate-level seeds. |
| 9. Empirical application | Not required for this planning sheet; tutorial examples should keep residual and group correlations separate. |
| 10. Results reporting | To include aggregate plus replicate-level artifacts, failed fits, and interval-status rows. |
| 11. Monte Carlo uncertainty | Pilot uses 200 replicates; formal coverage/power needs an MCSE target before dispatch. |

## Boundary

This sheet does not design the q4 or q6 location smoke lanes, the q2
`sigma1`/`sigma2` scale-slope lane, p8/q8 bivariate random-slope covariance,
random effects in `rho12`, mixed-response families, or same-response
location-scale slope covariance. Those remain separate design or failure-ledger
surfaces.
