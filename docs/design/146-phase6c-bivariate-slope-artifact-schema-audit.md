# Phase 6c Bivariate Slope Artifact-Schema Audit

## Purpose

This audit checks whether the existing `biv_gaussian_mu_slope` Phase 18 artifact
writer can support the #440/#446 bivariate Gaussian slope-only ADEMP sheet
without confusing residual coscale `rho12` with the group-level slope-slope
correlation.

The audit is source and schema evidence only. It does not run a new grid, does
not estimate coverage or power, and does not promote the now source-tested q4
location block, p8/q8, random effects in `rho12`, mixed-response bivariate
models, or residual-scale slope covariance.

## Schema Check

| ADEMP estimand | Current artifact field | Evidence | Audit status |
| --- | --- | --- | --- |
| `mu1` fixed effects | `parameter = "mu1:(Intercept)"`, `parameter = "mu1:x"`, `parameter_class = "fixed_mu1"` | `phase18_summarise_biv_gaussian_mu_slope_fit()` constructs separate `mu1` rows. | Captured |
| `mu2` fixed effects | `parameter = "mu2:(Intercept)"`, `parameter = "mu2:x"`, `parameter_class = "fixed_mu2"` | `phase18_summarise_biv_gaussian_mu_slope_fit()` constructs separate `mu2` rows. | Captured |
| Random-slope SDs | `parameter = "sd:mu:..."`, `parameter_class = "random_sd"` | Truth labels come from `sd_mu` and estimates from `fit$sdpars$mu`. | Captured |
| Group-level slope-slope correlation | `parameter = "cor:mu:cor(mu1:x,mu2:x | p | id)"`, `parameter_class = "random_correlation"` | Truth comes from `rho_slope`; estimates come from `fit$corpars$mu`. | Captured, point estimate only |
| Residual scales | `parameter = "sigma1"` and `parameter = "sigma2"`, `parameter_class = "residual_sigma"` | Estimates are exponentiated `sigma1` and `sigma2` coefficients. | Captured |
| Residual coscale | `parameter = "rho12"`, `parameter_class = "residual_rho12"` | Truth comes from `residual_rho`; estimates come from `rho12(fit)`. | Captured |
| Diagnostics | `converged`, `pdHess`, `warning_count`, `warnings`, `elapsed`, `manifest`, `failures` | The runner stores replicate summaries, manifests, and failures. | Captured |
| Coverage and power | no interval or rejection-rule table in this writer | The random-slope operating-characteristic plan labels coverage and power `planned_not_estimated`. | Planned |

## Separation Gate

The current schema has a usable separation gate because the slope-slope
correlation and residual `rho12` have different `parameter` and
`parameter_class` values in both replicate and aggregate CSV artifacts. The
test in `tests/testthat/test-phase18-biv-gaussian-mu-slope.R` now asserts this
mapping directly:

- `cor:mu:cor(mu1:x,mu2:x | p | id)` must be `random_correlation`;
- `rho12` must be `residual_rho12`;
- neither row may appear under the other class in replicate or aggregate
  artifacts.

## Remaining Gap

The writer is adequate for a small accuracy and failure-rate pilot. A formal
coverage or power grid still needs an interval-status artifact and a named
null/alternative rule before it can support coverage, Type I error, or power
claims.
