# Phase 18 Skew-Normal Implementation Gate, Slices 1689-1702

This note records the implementation gate for the first skew-normal source
slice. It was originally written as a no-fit boundary. On 2026-06-08 the
fixed-effect first slice moved into package code with a constructor, TMB
likelihood branch, simulation method, diagnostics, roxygen documentation, and
focused source tests.

The admitted lane is still narrow and univariate:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  family = skew_normal(),
  data = dat
)
```

Here `mu` is the response mean, `sigma` is the response standard deviation, and
`nu` is the residual slant or shape parameter. The lane models
observation-level residual asymmetry after location and scale are accounted
for. It is not latent-effect skewness, not bivariate skew-normal support, and
not a `rho12` model.

## Gate Rule

Support is exposed only for the fixed-effect first slice after density tests,
normal-limit tests, sign-orientation tests, malformed-neighbour tests,
extractor and method checks, documentation, provenance review, and local TMB
compile/test evidence agree. Passing only a density branch is not enough to
advertise `skew_normal()`.

This slice keeps the formula grammar unchanged except for admitting canonical
fixed-effect `nu ~ ...` in `family = skew_normal()`. `skew ~ ...`,
`skew(id) ~ ...`, random effects in `mu`, `sigma`, or `nu`, `sd(group)` scale
formulas, structured effects, meta-analysis known sampling covariance,
bivariate responses, composed families, and `rho12` stay outside the first
lane.

## Density And Normal-Limit Tests

The implementation uses the public moment parameterization from
`docs/design/127-phase-18-skew-normal-parameterization-decision-slices-1669-1672.md`.
For each row:

```text
delta_i = nu_i / sqrt(1 + nu_i^2)
omega_i = sigma_i / sqrt(1 - 2 * delta_i^2 / pi)
xi_i = mu_i - omega_i * delta_i * sqrt(2 / pi)
z_i = (y_i - xi_i) / omega_i
log f_i(y_i) = log(2) - log(omega_i) + log phi(z_i) + log Phi(nu_i z_i)
```

The source tests use a deterministic grid of `mu`, `sigma`, and `nu` values
with negative, zero, and positive `nu`, plus central and tail `y` values. They
check constants, numerical integration to one, the third-moment sign
orientation, and the normal limit.

At `nu = 0`, the same density reduces to the Gaussian location-scale density
with public `mu` and `sigma`:

```text
log f_i(y_i) = dnorm(y_i, mean = mu_i, sd = sigma_i, log = TRUE)
```

The normal-limit tests compare log likelihood, fixed-effect coefficients,
`fitted()` response means, `sigma()` response standard deviations, and
`predict(dpar = "nu")` output before any recovery, benchmark, or external
fitted-model comparator claim.

## Sign-Orientation Tests

The public sign convention remains:

```text
nu > 0  -> right-skewed residual distribution
nu = 0  -> Gaussian residual distribution
nu < 0  -> left-skewed residual distribution
```

The sign test is density-level. It verifies that the third central moment has
the same sign as `nu` under the public moment transform and that positive `nu`
maps to positive native `alpha`. This avoids inferring the sign convention from
one fitted coefficient, one simulated data set, or the direction of a residual
histogram.

## Malformed-Neighbour Tests

The source tests keep unsupported neighbours rejected before or during spec
construction. Required malformed-neighbour cases are:

- random-effect bar terms in `mu`, `sigma`, or `nu`;
- latent-effect skewness spellings such as `skew(id) ~ x`;
- `skew ~ x` as a public alias before any alias decision;
- `sd(id) ~ x` and other random-effect scale formulas;
- `phylo()`, `spatial()`, `animal()`, `relmat()`, `gr()`, or similar
  structured-effect helpers in any skew-normal formula;
- `meta_V(V = V)` or deprecated `meta_known_V(V = V)`;
- bivariate responses, `mvbind()`, mixed responses, composed families, and
  `rho12`;
- non-finite continuous responses after model-frame filtering.

Finite missing rows are handled by ordinary complete-case model-frame
filtering. A finite continuous response is the only response-support
requirement for the first lane.

## Extractor And Method Expectations

The implementation is not complete when the density branch merely optimizes.
User-facing methods must preserve the public parameterization:

- `fitted()` returns `E[y]`, not native `xi`;
- `predict(dpar = "mu")` returns the response-mean parameter on the requested
  scale;
- `sigma()` returns response `SD[y]`, not native `omega`;
- `predict(dpar = "nu")` returns the public slant or shape value under the
  identity link;
- `logLik()` includes the skew-normal normalizing constants;
- `simulate()` draws from the same public `mu`, `sigma`, and `nu` contract as
  the likelihood;
- response and Pearson residuals use `y - mu` and public `sigma` in the first
  diagnostic slice.

If a method is not ready, it should fail clearly or document that status. It
should not return native parameters under public names.

## Documentation And Provenance

The first slice has roxygen2 documentation for `skew_normal()` and generated
reference documentation after `devtools::document()`. Examples stay small and
fixed-effect. User-facing articles should show the fitted route only inside the
first-slice boundary.

The package can use `sn`, `RTMBdist`, `brms`, and `glmmTMB` as comparators or
semantic precedents, but not as unrecorded code sources. No likelihood or
simulation code was ported from another package for this slice; if that changes,
`inst/COPYRIGHTS` must document provenance before the task is complete.

Issue `#3 Add skew-normal location-scale-shape family` remains the tracking
issue for broader skew-normal work. The implementation closeout should update
the local check log and after-task report, but this design gate deliberately
does not close future random-effect, structured, bivariate, or comparator
tasks.

## Boundary Checks

The boundary test has changed from "constructor must be absent" to "constructor
exists only for the fixed-effect first slice." A safe scan now checks:

- `skew_normal()` exists, is exported, and declares `dpars = c("mu", "sigma",
  "nu")` with identity, log, and identity links;
- `R/`, `src/`, `NAMESPACE`, and reference docs expose only the fixed-effect
  first slice;
- design examples do not imply random-effect, structured, bivariate, known-`V`,
  `rho12`, or latent `skew(id)` support;
- broader skew-normal wording remains planned or unsupported until code, tests,
  docs, diagnostics, and after-task evidence exist.

This boundary is intentional friction. It prevents a partial density branch or
example from teaching users that all skew-normal support is ready before the
mathematical, numerical, method, and documentation gates agree.

## Slice Status

| Slice | Status | Gate |
| --- | --- | --- |
| 1689 | Superseded | Formula grammar still uses canonical `nu ~ ...`; the fixed-effect skew-normal first slice now fits. |
| 1690 | Superseded | Family-registry wording now marks the fixed-effect first slice implemented and broader surfaces planned. |
| 1691 | Superseded | Likelihood design now points to the C++ `model_type = 17` branch for the first slice. |
| 1692 | Superseded | README, pkgdown, and vignettes may mention the first slice only with its fixed-effect boundary. |
| 1693 | Done | This note defines the implementation checklist and its post-admission boundary. |
| 1694 | Done | Density tests cover constants, tail points, quadrature, and the normal limit. |
| 1695 | Done | Source tests fit intercept-only `nu`, `nu ~ w`, and positive/negative skew examples. |
| 1696 | Partial | A deterministic Gaussian-limit false-positive source test now keeps intercept-only `nu` near zero; broader Gaussian heteroscedasticity, outlier, and mean-misspecification grids remain future simulation work. |
| 1697 | Partial | A deterministic correlated-predictor source test now covers `mu`, `sigma`, and constant `nu`; formal confounding grids where `mu`, `sigma`, and `nu` predictors are all correlated remain future simulation work. |
| 1698 | Pending | Interval status for `nu` is not promoted beyond the current fixed-effect Wald/profile machinery. |
| 1699 | Done | `check_drm()` reports finite and large-magnitude `nu` diagnostics for the fitted first slice. |
| 1700 | Pending | Runtime benchmarks against Gaussian and Student-t fixed-effect fits remain future evidence. |
| 1701 | Pending | A formal skew-normal simulation DGP plan remains future work. |
| 1702 | Pending | Deterministic source tests now check recovery direction and Gaussian-limit false-positive behaviour, but formal bias, RMSE, convergence, Hessian, false-positive skew, runtime, and Monte Carlo error summaries remain future work. |

## Fixed-Effect Boundary

This gate adds the constructor, C++ branch, fixed-effect methods, docs, and
tests for the first skew-normal slice only. It adds no formula grammar beyond
fixed-effect `nu`, no random effects, no structured effects, no known sampling
covariance, no bivariate skew-normal route, no residual `rho12`, and no
`skew` or `skew(id)` alias.
