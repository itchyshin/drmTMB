# Phase 18 Skew-Normal Comparator Scale Map

This note closes the comparator-scale design gap left by the skew-normal
Hessian pilot. The reader is the statistical method developer or R package
contributor preparing external comparator fits for the fixed-effect
`skew_normal()` first slice.

## Fitted Surface

The implemented first slice is univariate and fixed-effect:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  family = skew_normal(),
  data = dat
)
```

Public `mu` is the response mean, public `sigma` is the response standard
deviation, and public `nu` is the Azzalini slant parameter, also called
`alpha` by several comparator packages. Random effects, structured effects,
known sampling covariance, bivariate skew-normal, residual coscale `rho12`,
skew-t, and latent `skew(id)` remain outside this surface.

## Moment-To-Native Transform

`drmTMB` fits public moment parameters but evaluates an Azzalini-style
skew-normal density internally. For observation `i`:

```text
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
alpha_i = nu_i = eta_nu_i
delta_i = alpha_i / sqrt(1 + alpha_i^2)
omega_i = sigma_i / sqrt(1 - 2 * delta_i^2 / pi)
xi_i = mu_i - omega_i * delta_i * sqrt(2 / pi)
z_i = (y_i - xi_i) / omega_i
log f(y_i) = log(2) - log(omega_i) + log phi(z_i) + log Phi(alpha_i z_i)
```

This transform makes `mu_i = E[y_i]` and `sigma_i = SD[y_i]`. A positive
`nu_i` gives right-skewed residuals; a negative `nu_i` gives left-skewed
residuals; `nu_i = 0` gives the Gaussian location-scale likelihood.

The dependency-free source test helper
`skew_normal_comparator_scale_map()` records both scales:

```r
skew_normal_comparator_scale_map(mu = 0.4, sigma = 1.2, nu = -2.5)
```

It returns `public_moment` (`mu`, `sigma`, `alpha`) and `native_azzalini`
(`xi`, `omega`, `alpha`) rows, plus a comparator table that marks which
external packages can be compared on which scale.

## Comparator Scale Table

| Comparator | Scale to pass or compare | Comparator status |
| --- | --- | --- |
| `sn::dsn()` | native Azzalini `xi`, `omega`, `alpha` | density comparator after transforming from public `mu`, `sigma`, `nu` |
| `RTMBdist::dskewnorm()` | native Azzalini `xi`, `omega`, `alpha` | density comparator after transforming from public `mu`, `sigma`, `nu` |
| `RTMBdist::dskewnorm2()` | public moment `mu`, `sigma`, `alpha` | density comparator on the same response-moment scale |
| `brms::skew_normal()` | public moment `mu`, `sigma`, `alpha` | fitted-model comparator when priors and MCMC settings are documented |
| `glmmTMB::skewnormal()` | public moment `mu`, `sigma`, `alpha` | fitted-model comparator where the same fixed-effect formulas are available |
| `gamlss.dist::SN2` | different two-piece skew-normal family | not an Azzalini density comparator for this first slice |

The `gamlss.dist::SN2` row is deliberately explicit. The names `mu`, `sigma`,
and `nu` are not enough to make the distribution comparable. Treating SN2 as the
same density would compare a two-piece skew-normal parameterization against an
Azzalini-style density and could create a false agreement or false failure.

## Test Evidence

`tests/testthat/test-skew-normal-density-contract.R` now checks two source-level
contracts:

1. the comparator map reconstructs the public mean and standard deviation from
   native `xi`, `omega`, and `alpha`;
2. the native Azzalini log density equals the public `skew_normal()` reference
   density after the scale conversion.

These are not external comparator fits. They are the preflight that makes later
fits safe to interpret.

## glmmTMB Comparator Smoke

The first fitted comparator smoke wrote:

```text
docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-glmmtmb-comparator-smoke/
```

It used one simple fixed-effect data set with `sigma ~ 1` and `nu ~ 1`.
`glmmTMB` was available locally; `sn`, `RTMBdist`, and `gamlss` were not. The
local `drmTMB` fit and `glmmTMB::skewnormal()` agreed on the fitted mean,
standard deviation, and shape when `glmmTMB` was started with nonzero `psi`
values. With the default `glmmTMB` start, the fit converged but stayed at the
symmetric shape boundary, with reported shape about `2e-14`.

This smoke result is useful comparator hygiene, not formal external evidence. It
says that future `glmmTMB` comparator fits must record shape starts and should
not trust the default shape start for skewed cells. It does not cover
heteroscedastic `sigma ~ z`, predictor-varying `nu ~ w`, random effects,
structured effects, false-positive rates, or recovery grids.

## Decision

The next external-comparator task can extend the `glmmTMB` smoke to the formal
fixed-effect grid only after shape-start policy, package versions, and model
settings are recorded with the fitted artifacts. `sn`, `RTMBdist`, and `gamlss`
were not available in this local run. `gamlss.dist::SN2` should stay out of the
Azzalini comparator lane unless a separate two-piece-skew-normal family is
designed.
