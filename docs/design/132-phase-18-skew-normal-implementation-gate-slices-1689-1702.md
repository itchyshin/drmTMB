# Phase 18 Skew-Normal Implementation Gate, Slices 1689-1702

This note is a design-only gate for the first skew-normal implementation
slice. It does not implement `skew_normal()`, add a family constructor, expose
reference documentation, or add a C++ likelihood branch. Its reader is the R
package contributor who will turn the accepted parameterization into the first
source-level tests before user-facing support is opened.

The planned first lane is still univariate and fixed-effect:

```r
# Planned, not fitted yet:
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  family = skew_normal(),
  data = dat
)
```

Here `mu` is the response mean, `sigma` is the response standard deviation,
and `nu` is the residual slant or shape parameter. The first lane models
observation-level residual asymmetry after location and scale are accounted
for. It is not latent-effect skewness, not bivariate skew-normal support, and
not a `rho12` model.

## Gate Rule

No support is exposed until the first implementation PR has density tests,
normal-limit tests, sign-orientation tests, malformed-neighbour tests,
extractor and method checks, documentation, provenance notes, and no-fit
boundary checks. Passing only one of these checks is not enough to advertise
`skew_normal()`.

This slice keeps the formula grammar unchanged. The canonical planned syntax
is `nu ~ ...`; `skew ~ ...`, `skew(id) ~ ...`, random effects in `nu`, random
effects in `sigma`, structured effects, meta-analysis known-`V`, bivariate
responses, composed families, and `rho12` stay outside the first lane.

## Density And Normal-Limit Tests

The first implementation must test the public moment parameterization from
`docs/design/127-phase-18-skew-normal-parameterization-decision-slices-1669-1672.md`.
For each row:

```text
delta_i = nu_i / sqrt(1 + nu_i^2)
omega_i = sigma_i / sqrt(1 - 2 * delta_i^2 / pi)
xi_i = mu_i - omega_i * delta_i * sqrt(2 / pi)
z_i = (y_i - xi_i) / omega_i
log f_i(y_i) = log(2) - log(omega_i) + log phi(z_i) + log Phi(nu_i z_i)
```

The density tests should use a deterministic grid of `mu`, `sigma`, and `nu`
values with negative, zero, and positive `nu`, plus central and tail `y`
values. The test must check constants, log-density values, and numerical
integration to one. If `sn` or `RTMBdist` is used, it is an optional comparator
after transforming to native `xi`, `omega`, and `alpha = nu`; no comparator
source should be copied into package code.

At `nu = 0`, the same density must reduce to the Gaussian location-scale
density with public `mu` and `sigma`:

```text
log f_i(y_i) = dnorm(y_i, mean = mu_i, sd = sigma_i, log = TRUE)
```

The normal-limit tests should compare per-row log densities, summed negative
log likelihood, `fitted()` response means, `sigma()` response standard
deviations, `predict(dpar = "mu")`, and future `predict(dpar = "nu")` output.
They should run before recovery, benchmark, or external fitted-model
comparators.

## Sign-Orientation Tests

The public sign convention remains:

```text
nu > 0  -> right-skewed residual distribution
nu = 0  -> Gaussian residual distribution
nu < 0  -> left-skewed residual distribution
```

The first sign test should be density-level. For matched positive and negative
`nu`, it should verify that the third central moment has the same sign as
`nu` under the public moment transform and that positive `nu` maps to positive
native `alpha`. Do not infer the sign convention from one fitted coefficient,
one simulated data set, or the direction of a residual histogram.

## Malformed-Neighbour Tests

The first implementation PR must add pre-TMB rejection tests for unsupported
neighbours. These tests should name the unsupported feature and tell the user
what to try instead when possible.

Required malformed-neighbour cases are:

- random-effect bar terms in `nu`, including `nu ~ x + (1 | id)` and
  `nu ~ x + (0 + x | id)`;
- latent-effect skewness spellings such as `skew(id) ~ x`;
- `skew ~ x` as a public alias before canonical `nu ~ x` exists;
- `sigma ~ x + (1 | id)`, `sd(id) ~ x`, and other random-effect scale
  formulas;
- `phylo()`, `spatial()`, `animal()`, `relmat()`, `gr()`, or similar
  structured-effect helpers in any skew-normal formula;
- `meta_known_V(V = V)` or any successor known-sampling-covariance syntax;
- bivariate responses, `mvbind()`, mixed responses, composed families, and
  `rho12`;
- zero-inflation, hurdle, zero-one-inflation, ordinal, denominator, count, and
  bounded-response neighbours;
- non-finite continuous responses after model-frame filtering;
- rank-deficient `X_mu`, `X_sigma`, or `X_nu` behaviour that silently changes
  the fitted target.

Finite missing rows should be handled by ordinary model-frame filtering before
support validation. A finite continuous response is the only support
requirement for the first lane.

## Extractor And Method Expectations

The first implementation is not complete when a density branch merely
optimizes. It must prove that user-facing methods preserve the public
parameterization:

- `fitted()` returns `E[y]`, not native `xi`;
- `predict(dpar = "mu")` returns the response-mean linear predictor on the
  expected scale;
- `sigma()` returns response `SD[y]`, not native `omega`;
- future `predict(dpar = "nu")` returns the public slant or shape value under
  the identity link;
- `logLik()` includes the skew-normal normalizing constants;
- `simulate()` draws from the same public `mu`, `sigma`, and `nu` contract as
  the likelihood;
- residual or diagnostic methods document whether they are ordinary response
  residuals, randomized quantile residuals, or unavailable for the first PR.

If a method is not ready, the first implementation PR should fail clearly or
document that status. It should not return native parameters under public
names.

## Documentation And Provenance

The first implementation PR must add roxygen2 documentation for
`skew_normal()` before exporting support. Examples must be runnable only after
the constructor, likelihood branch, methods, and tests exist. Until then, every
code example with `family = skew_normal()` must be labelled planned or future.

The package can use `sn`, `RTMBdist`, `brms`, and `glmmTMB` as comparators or
semantic precedents, but not as unrecorded code sources. If any likelihood or
simulation code is ported from another package, `inst/COPYRIGHTS` must document
provenance before the task is complete.

Issue `#3 Add skew-normal location-scale-shape family` remains the tracking
issue. The implementation PR should update the local check log and after-task
report, but this Team B design gate deliberately leaves those shared closeout
files to the parent rollout.

## No-Fit Boundary Checks

Until the implementation PR lands, the boundary test must keep checking that
the constructor remains absent from the package namespace and that design notes
say planned, not fitted. A safe no-fit scan checks:

- no `skew_normal()` object exists in `asNamespace("drmTMB")`;
- no `R/`, `src/`, `NAMESPACE`, or exported reference page exposes support;
- design examples are labelled "Planned, not fitted yet" or equivalent;
- `rho12`, bivariate skew-normal, latent `skew(id)`, and random-effect shape
  syntax remain closed.

This boundary is intentional friction. It prevents a partial density branch or
example from teaching users that skew-normal support is ready before the
mathematical, numerical, method, and documentation gates agree.

## Slice Status

| Slice | Status | Gate |
| --- | --- | --- |
| 1689 | Done | Formula grammar remains unchanged; canonical planned syntax is still `nu ~ ...`. |
| 1690 | Done | Family-registry wording must stay planned until constructor, likelihood, methods, docs, and tests land together. |
| 1691 | Done | Likelihood design may state the moment transform but must not claim C++ support exists. |
| 1692 | Done | README and pkgdown examples remain absent or explicitly planned-only. |
| 1693 | Done | This note defines the first implementation checklist. |
| 1694 | Done | Density tests must cover constants, tail points, quadrature, and optional native-density comparators. |
| 1695 | Done | Recovery tests start with intercept-only `nu`, then `nu ~ w`, under positive and negative skew. |
| 1696 | Done | False-positive tests must keep Gaussian heteroscedasticity, outliers, and mean misspecification from being reported as skewness evidence. |
| 1697 | Done | Confounding tests must control correlations among `mu`, `sigma`, and `nu` predictors. |
| 1698 | Done | Interval status for `nu` is recorded as available, unavailable, or unsafe before examples make uncertainty claims. |
| 1699 | Done | Diagnostics must include convergence, gradient, Hessian, boundary, and skewness-detection status. |
| 1700 | Done | Runtime benchmarks compare Gaussian, Student-t, and skew-normal fixed-effect fits at small and moderate sample sizes. |
| 1701 | Done | Simulation data-generating plans name `mu`, `sigma`, `nu`, skew direction, predictor correlation, and sample size cells. |
| 1702 | Done | Simulation summaries include bias, RMSE, convergence, Hessian status, false-positive skew, runtime, and Monte Carlo error. |

## Closed Boundary

This gate adds no constructor, no density helper in package code, no C++ or TMB
branch, no exported documentation, no `NAMESPACE` entry, no new formula
grammar, and no fitted skew-normal claim. The next contributor can start the
implementation only after keeping this no-fit boundary intact.
