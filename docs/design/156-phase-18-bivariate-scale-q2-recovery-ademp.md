# Phase 18 Bivariate Gaussian q2 Scale-Intercept Recovery ADEMP Sheet

This sheet follows the ADEMP structure of Morris, White, and Crowther (2019)
and the transparent-reporting checklist of Williams et al. (2024). It promotes
the bivariate Gaussian q2 scale-intercept covariance lane from a single-replicate
smoke check to a multi-replicate recovery and coverage lane. The reader is an
applied ecology or evolution user who wants to know whether the two residual-scale
random intercepts and their correlation are recovered accurately, and the
contributor maintaining the Phase 18 grid.

The lane fits the implemented model

```r
bf(
  mu1 = y1 ~ x,
  mu2 = y2 ~ x,
  sigma1 = ~ 1 + (1 | p | id),
  sigma2 = ~ 1 + (1 | p | id),
  rho12 = ~ 1
)
```

under `biv_gaussian()`. The two log-`sigma` intercepts share a q=2 scale-scale
covariance block, while residual `rho12` stays a separate layer. This is the
fittable scale-covariance prerequisite the q8 endpoint gate
(`docs/design/67-sdstar-p8-poisson-q1.md`) requires; bivariate residual-scale
random slopes remain closed and are gated separately in
`docs/design/155-bivariate-residual-scale-random-slope-gate.md`.

## A - Aims

Primary aim: estimate bias, RMSE, empirical SE, Monte Carlo standard error
(MCSE), convergence rate, and Wald interval coverage for the fixed-effect
endpoints of the q2 scale-intercept model over many replicates.

Secondary aims: report point-estimate bias and MCSE for the two residual-scale
random-effect SDs (`sd:sigma:sigma1:(1 | p | id)`,
`sd:sigma:sigma2:(1 | p | id)`) and the derived scale-scale correlation
(`cor:sigma:cor(sigma1,sigma2 | p | id)`), while keeping those SD and
correlation rows at `derived_interval_unavailable` rather than reporting Wald
intervals for them. Keep residual `rho12`, group-level scale-scale correlation,
random scale slopes, and q8 endpoints as separate concerns.

## D - Data-Generating Mechanism

This lane reuses the smoke DGP `phase18_dgp_biv_gaussian_q2_scale()`. For groups
`j = 1, ..., n_id` with `n_each` observations each:

```text
x_ij ~ standardized Normal predictor
mu1_ij = beta_mu1_0 + beta_mu1_x * x_ij
mu2_ij = beta_mu2_0 + beta_mu2_x * x_ij
log(sigma1_ij) = log(sigma1) + a_1j
log(sigma2_ij) = log(sigma2) + a_2j
[a_1j, a_2j]' ~ MVN(0, D),  D = diag(sd_sigma1, sd_sigma2) R diag(sd_sigma1, sd_sigma2)
R = [[1, cor_sigma], [cor_sigma, 1]]
```

with residual correlation `residual_rho` applied at the observation level
between the two responses. Default truth: `sd_sigma1 = 0.28`,
`sd_sigma2 = 0.34`, `cor_sigma = 0.45`, `residual_rho = 0.20`.

The recovery grid varies group count (`n_id = 48, 96`) at fixed `n_each = 8`.
Random-effect SDs and correlations need many groups and adequate within-group
replication to be identified, so smaller group counts are expected to show
larger MCSE and weaker correlation recovery; that is a reported result, not a
defect.

## E - Estimands

Ten estimands per cell, kept as separate rows: `mu1:(Intercept)`, `mu1:x`,
`mu2:(Intercept)`, `mu2:x`, the two residual scales `sigma1`/`sigma2`, the two
random-effect SDs, the scale-scale correlation, and residual `rho12`.

## M - Methods

A single estimator: `drmTMB()` with the formula above and the
`biv_gaussian()` family. Replicates run through the existing runner
`phase18_run_biv_gaussian_q2_scale_smoke()` at recovery-scale `n_rep`. The
recovery summariser `phase18_summarise_biv_gaussian_q2_scale_recovery()` adds
Wald intervals on the formula-coefficient scale and an interval-coverage table.

Wald intervals are reported only for endpoints that carry a standard error in
`summary(fit)$coefficients` (the fixed `mu1`/`mu2` coefficients). The random-effect
SD and derived scale-scale correlation rows have no Wald standard error, so their
interval endpoints stay `NA`; coverage for those targets requires profile,
derived-profile, or bootstrap methods and is deliberately left for a later
slice, consistent with the q8 gate's `derived_interval_unavailable` policy.

## P - Performance Measures

- Convergence and positive-definite Hessian (`pdHess`) rate.
- Bias, RMSE, and empirical SE per estimand, with MCSE for bias and RMSE.
- Wald interval coverage and coverage MCSE for the fixed-effect endpoints.
- Mean elapsed time per fit.

A formal run uses at least 500 replicates per cell before any coverage claim is
treated as final; the continuous-integration test runs a small replicate count
to check the machinery and column contract, not to make a coverage claim.

## Reporting Plan

The grid writer `phase18_write_biv_gaussian_q2_scale_recovery_grid_outputs()`
emits aggregate, replicate, manifest, failures, Wald-interval, Wald-coverage,
and interval evidence/diagnostics/failure tables under the
`biv-gaussian-q2-scale-recovery-*` prefix. The registry row
`bivariate_gaussian_scale_q2_recovery` dispatches the lane through the
`biv_gaussian_q2_scale_recovery` Actions task as an opt-in matrix entry
(`include_in_all: false`). Reports should keep residual `rho12` separate from
the group-level scale-scale correlation and must not present SD or correlation
Wald intervals.

## Standing Review

| Perspective | Decision for this lane |
| --- | --- |
| Ada | Keep registry, Actions task, writer, test, ADEMP, and after-task report aligned. |
| Gauss | Treat this as a recovery lane for an already-fitted likelihood, not new algebra. |
| Noether | Match the DGP, R syntax, estimand labels, and the log-scale meaning of the SDs. |
| Fisher | Report Wald coverage only for fixed-effect endpoints; keep SD/correlation intervals unavailable until a validated method exists. |
| Darwin | Frame the lane as coupled baseline residual variability across two responses. |
| Pat | Tell users this lane reports recovery for scale intercepts, not scale slopes or q8 endpoints. |
| Rose | Watch for any wording that promotes the derived scale-scale correlation to interval-ready. |
