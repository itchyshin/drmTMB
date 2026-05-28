# Phase 18 Tweedie Comparator Contract, Slices 1619-1628

This note closes the first Team A follow-on gate after the fitted
`tweedie()` admission. Its reader is the package contributor who needs to know
which scale to compare with `glmmTMB::tweedie()` before broad Tweedie
simulation artifacts are trusted.

## Purpose

The first `drmTMB` Tweedie implementation uses public `sigma` as the square
root of the usual Tweedie dispersion:

```text
phi_i = sigma_i^2
Var(y_i) = sigma_i^2 * mu_i^nu_i
```

`glmmTMB::tweedie(link = "log")` uses the same response-mean and power
interpretation, but its dispersion formula is on the log-`phi` scale. The
direct coefficient comparison is therefore:

```text
beta_mu(drmTMB)      ~= beta_cond(glmmTMB)
2 * beta_sigma(drmTMB) ~= beta_disp(glmmTMB)
nu(drmTMB)           ~= power(glmmTMB)
logLik(drmTMB)       ~= logLik(glmmTMB)
```

This is the comparator contract. It does not change the fitted surface and it
does not open predictor-dependent `nu`, random effects, structured effects,
bivariate Tweedie, zero-inflation aliases, or hurdle aliases.

## Test Fixture

`tests/testthat/test-tweedie-location-scale.R` now includes an optional
`glmmTMB` comparator test. The fixture uses deterministic data from the local
compound Poisson-Gamma simulator:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ 1),
  family = tweedie(),
  data = dat,
  control = drm_control(se = FALSE)
)

glmmTMB::glmmTMB(
  y ~ x,
  dispformula = ~ z,
  family = glmmTMB::tweedie(link = "log"),
  data = dat
)
```

The test is guarded with `testthat::skip_if_not_installed("glmmTMB")`, so
`glmmTMB` remains a `Suggests` comparator rather than a required dependency.
The test compares location coefficients, doubled public-scale `sigma`
coefficients against `glmmTMB` dispersion coefficients, the intercept-only
power parameter, and log-likelihood.

## What This Proves

The comparator test proves that the first fixed-effect Tweedie implementation
matches `glmmTMB` on the overlapping location-scale-power model when the scale
transform is named correctly. It also proves that log-likelihood constants are
aligned for this overlap, because the numeric log-likelihoods match directly in
the deterministic fixture.

It does not prove coverage, recovery across the full operating-characteristic
grid, or behaviour for unsupported neighbours. Those claims still require
Phase 18 artifact rows with sample size, zero fraction, baseline `sigma`,
power, predictor correlation, convergence, Hessian status, runtime, Monte Carlo
error, and failure-ledger fields.

## Slice Status

| Slice | Status | Evidence |
| --- | --- | --- |
| 1619 | Done | The branch was rehydrated after PR #347 merged; the follow-on branch starts from `origin/main` at the merged commit. |
| 1620 | Done | The previous two-lane branch was published as PR #347 before this follow-on work began. |
| 1621 | Done | This note records the `glmmTMB::tweedie()` comparator contract. |
| 1622 | Done | The deterministic optional fixture is in `tests/testthat/test-tweedie-location-scale.R`. |
| 1623 | Done | The test uses `skip_if_not_installed("glmmTMB")`; no hard dependency was added. |
| 1624 | Done | Coefficient names are mapped as `mu` to `cond`, public `sigma` to half of `disp`, and `nu` to `power`. |
| 1625 | Done | Log-likelihoods are compared directly in the overlap fixture. |
| 1626 | Planned | Low-zero and high-zero comparator cells remain a future expansion after this first optional comparator passes. |
| 1627 | Planned | The high-zero comparator cell should not place `nu` near the boundary. |
| 1628 | Done for the first fixture | The public-scale assertion compares `2 * coef(fit, "sigma")` to log-`phi` coefficients. |
