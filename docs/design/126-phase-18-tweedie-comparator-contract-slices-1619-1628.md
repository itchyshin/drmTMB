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

## Test Fixtures

`tests/testthat/test-tweedie-location-scale.R` now includes an optional
`glmmTMB` comparator test. The test now uses two deterministic data cells from
the local compound Poisson-Gamma simulator: one low-zero cell and one high-zero
cell. Both cells stay away from the power boundary while exercising the same
public scale mapping.

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
power parameter, and log-likelihood in both cells. The low-zero cell asserts a
positive exact-zero count and a zero fraction below 0.05. The high-zero cell
asserts a zero fraction above 0.20, so the comparator no longer depends on a
single moderate-zero fixture.

## What This Proves

The comparator test proves that the first fixed-effect Tweedie implementation
matches `glmmTMB` on overlapping location-scale-power models when the scale
transform is named correctly. It now proves this in both low-zero and high-zero
semicontinuous regimes. It also proves that log-likelihood constants are
aligned for this overlap, because the numeric log-likelihoods match directly in
both deterministic fixtures.

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
| 1622 | Done | The deterministic optional fixtures are in `tests/testthat/test-tweedie-location-scale.R`. |
| 1623 | Done | The test uses `skip_if_not_installed("glmmTMB")`; no hard dependency was added. |
| 1624 | Done | Coefficient names are mapped as `mu` to `cond`, public `sigma` to half of `disp`, and `nu` to `power`. |
| 1625 | Done | Log-likelihoods are compared directly in the overlap fixture. |
| 1626 | Done | The optional comparator now includes explicit low-zero and high-zero cells; the low-zero cell still requires at least one exact zero. |
| 1627 | Done | The high-zero cell uses `nu = 1.55`, away from the 1 and 2 boundaries. |
| 1628 | Done | The public-scale assertion compares `2 * coef(fit, "sigma")` to log-`phi` coefficients in both cells. |
