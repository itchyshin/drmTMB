# Phase 18 Skew-Normal Source Map, Slices 1519-1538

This note is an admission gate for the first skew-normal lane. It does not
implement `skew_normal()`. Its reader is the R package contributor who will
eventually add a fixed-effect likelihood and must know which existing software,
parameterizations, tests, and claims are safe to copy.

The first target is residual or observation-level asymmetry in a univariate
continuous response:

```r
# Planned, not fitted yet:
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  family = skew_normal(),
  data = dat
)
```

Here `mu` is the arithmetic response mean, `sigma` is the response standard
deviation, and `nu` is the first GAMLSS-style shape slot. `nu ~ w` changes the
conditional residual distribution after `mu` and `sigma` are accounted for. It
is not latent-effect skewness. Grammar such as `skew(id) ~ x` remains future
work until simulations show that latent-effect skewness can be separated from
residual skewness, heteroscedasticity, ordinary random effects, and outliers.

## Local Contract

The local design already fixes the narrow boundary:

| Source | Current local contract |
| --- | --- |
| `docs/design/03-likelihoods.md`, "Planned Skew-Normal Location-Scale-Shape Gate" | Candidate moment-parameter contract with public `mu = E[y]`, public `sigma = SD[y]`, `nu_i = eta_nu_i`, normal limit at `nu = 0`, and positive `nu` as right-skewed residuals after transforming internally to native `xi`, `omega`, and `alpha`. |
| `docs/design/02-family-registry.md`, "Planned: Skew-Normal Location-Scale-Shape" | Planned family object has `dpars = c("mu", "sigma", "nu")` and links `identity`, `log`, and `identity`; no constructor is implemented. |
| `docs/design/14-gamlss-parameter-names.md` | `nu` is the canonical first shape parameter. `skew` can be considered later as an alias, not as the first public spelling. |
| `docs/design/19-phylogenetic-location-scale-shape.md` | Residual `nu ~ x` and future latent-effect `skew(id) ~ x` are different scientific questions. |
| `docs/design/41-phase-18-simulation-programme.md` and `docs/design/46-pre-simulation-readiness-matrix.md` | Fixed-effect Student-t `nu` is admitted; skew-normal and skew-t remain design-only until likelihood, interval, diagnostic, and recovery evidence exists. |
| `R/drmTMB.R` and `tests/testthat/test-student-location-scale.R` | Bar terms in `nu` or future `tau` formulas fail with a shape-specific boundary, including a message that future skew-normal and skew-t shape parameters need fixed-effect recovery before random effects. |
| `ROADMAP.md`, Phase 16 and row 1953 | First asymmetry slice is fixed-effect and univariate; no `sigma` random effects, `nu` random effects, `sd(group)` scale models, `phylo()`, `spatial()`, bivariate skew-normal, or `rho12`. |

## Software Source Map

| Source | What exists | Lesson for `drmTMB` |
| --- | --- | --- |
| `sn::dsn()` documentation, <https://www.rdocumentation.org/packages/sn/versions/2.1.1/topics/dsn> | Classic skew-normal density uses `xi`, `omega`, and `alpha`; the normalized density is `2 * phi(x) * Phi(alpha * x)`, and `alpha = 0` gives the normal model. | Use `sn` as the sign-convention and density comparator for the native Azzalini candidate. Do not name `drmTMB` parameters `xi`, `omega`, and `alpha` unless the family page explicitly maps them from `mu`, `sigma`, and `nu`. |
| `gamlss.dist::SN2()` local help and source `R/SN2.R` | `SN2(mu.link = "identity", sigma.link = "log", nu.link = "log")` uses `mu`, `sigma`, and positive `nu`; `dSN2()` is a two-piece skew normal type 2, not the Azzalini `2 phi Phi` density. | Keep the GAMLSS names but do not silently copy `SN2` as the Azzalini likelihood. If `SN2` is used as a comparator, label it as a different distribution. |
| `gamlss::gamlss()` documentation, <https://www.rdocumentation.org/packages/gamlss/versions/5.4-12/topics/gamlss> | The package models up to four parameters, conventionally `mu`, `sigma`, `nu`, and `tau`, using separate formula arguments such as `sigma.formula`, `nu.formula`, and `tau.formula`. | `drmTMB` should keep one formula per distributional parameter, but avoid copying the broad "any parameter, any smoother, any random effect" surface before recovery evidence exists. |
| `gamlss2` manual, <https://gamlss-dev.r-universe.dev/gamlss2/doc/manual.html> | New infrastructure works with `gamlss.dist` or `gamlss2.family` objects and predicts distribution parameters such as `mu`, `sigma`, `tau`, and `nu`. | The reusable lesson is explicit distribution-family infrastructure, not broad family admission. |
| `brms::skew_normal()` and `brms::SkewNormal` local help; <https://paulbuerkner.com/brms/reference/SkewNormal.html> | `brms` exposes `mu`, `sigma`, and `alpha`, where `mu` and `sigma` are response mean and response SD. Its family page uses `link_alpha = "identity"`. | Use as the main fitted-value semantics precedent for the moment-parameter contract. |
| `brms` installed vignette `doc/brms_families.html` | The vignette maps mean/SD `mu`, `sigma` to native `xi`, `omega` using `alpha`, and states that `alpha = 0` gives a Gaussian distribution. | Copy the explicit moment-to-native mapping pattern into `drmTMB` design and tests. |
| `glmmTMB::skewnormal()` local help under `?nbinom2` | `glmmTMB` has a `skewnormal(link = "identity")` family, parameterized by mean, standard deviation, and shape; extra family parameters are exposed by `family_params()`. | Add a direct comparator test to `glmmTMB` for fitted fixed-effect models after the `drmTMB` density branch exists. |
| `RTMBdist` reference manual, <https://stat.ethz.ch/CRAN/web/packages/RTMBdist/refman/RTMBdist.html> | `dskewnorm()` is AD-compatible for RTMB and uses `xi`, `omega`, `alpha`; `dskewnorm2()` reparameterizes to mean, SD, and alpha. `dskewt()` warns that skew should not be initialized exactly at zero in numerical optimization. | Use `RTMBdist` as a source-level comparator and numerical-starting warning, not as copy-paste code. If TMB derivatives vanish at `nu = 0`, start `nu` slightly away from zero while still testing the normal limit. |
| `mgcv::shash()` local help | `shash` models location, scale, skewness, and kurtosis with four linear predictors, and explicitly warns to check whether the data support such flexibility. | This is a documentation pattern to copy: warn about identifiability before offering flexible shape surfaces. Do not copy `shash` as the first skew-normal target. |
| `mgcv::gaulss()` local help | Gaussian location-scale models use a list of formulae and guard the SD away from zero. | Useful warning for scale-boundary protection; not a reason to add `sigma` random effects to the first skew-normal lane. |
| `sdmTMB::Families` local help | `sdmTMB` supports ecological families such as Student-t, Tweedie, generalized gamma, and delta families, but no skew-normal family in the local installed version. | Use as a negative comparator: `drmTMB` can be novel for skew-normal distributional fixed effects among TMB eco-evo packages, but not novel among all R distributional-regression packages. |
| `metafor::rma.uni()` local help | Location-scale meta-analysis models allow moderators for residual heterogeneity `tau_i^2`, with documented optimization and flat-likelihood warnings. | Keep meta-analysis notation separate. Do not introduce `tau ~` for skew-normal; in `drmTMB`, `tau` is reserved for a possible second shape parameter. |
| `MCMCglmm::MCMCglmm()` local help | Supports many response families and residual covariance structures such as `idh` and `us`, but no skew-normal residual family in the local help. | Do not copy broad residual covariance grammar into the first skew-normal lane. |
| `spaMM` documentation, <https://www.rdocumentation.org/packages/spaMM/versions/4.5.0/topics/spaMM> | Handles spatial GLMMs, structured correlation, COM-Poisson, negative-binomial, beta, beta-binomial, and truncated families; no skew-normal family appears in the inspected docs. | Treat as a structured-effect comparator, not a skew-normal comparator. |

## Literature Source Map

| Source | Design lesson |
| --- | --- |
| Azzalini, A. (1985). A class of distributions which includes the normal ones. *Scandinavian Journal of Statistics*, 12, 171-178. | The normal limit and slant-parameter sign convention are core comparator tests. |
| Azzalini, A. and Capitanio, A. (2014). *The Skew-Normal and Related Families*. Cambridge University Press. | Use as the native-parameter reference for `xi`, `omega`, `alpha`, response mean, variance, and skewness. |
| Rigby, R. A. and Stasinopoulos, D. M. (2005). Generalized additive models for location, scale and shape. *Applied Statistics*, 54, 507-554. Local file: `dis_reg_models/Royal Stata Society Series C - 2005 - Rigby - Generalized additive models for location scale and shape.pdf`. | Supports the `mu`, `sigma`, `nu`, `tau` naming pattern and separate predictors for distributional parameters; it does not justify broad random-effect shape grammar in `drmTMB`. |
| Klein, N. (2024). Distributional Regression for Data Analysis. *Annual Review of Statistics and Its Application*, 11, 321-346. Local file: `dis_reg_models/annurev-statistics-040722-053607.pdf`. | Places skewness and full-distribution modelling inside a mature distributional-regression landscape; novelty claims must be narrower than "first distributional regression for skewness". |
| Corrales, M. L. and Cepeda-Cuervo, E. (2022). Bayesian modeling of location, scale, and shape parameters in skew-normal regression models. *Statistical Analysis and Data Mining*, 15, 98-111. DOI: 10.1002/sam.11548. Local file: `dis_reg_models/Statistical Analysis - 2021 - Corrales - Bayesian modeling of location scale and shape parameters in skew-normal.pdf`. | Directly supports `mu`, `sigma`, and skewness predictors in skew-normal regression and reinforces the need for simulations when location, scale, and shape formulas are all active. It is Bayesian, so it does not support a frequentist TMB implementation claim by itself. |
| Local draft `dis_reg_models/Phylogenetic_location_scale_shape_models.pdf` | Names animal and phylogenetic location-scale-shape models as a future scientific target, including skew-normal shape fields. This is local concept evidence, not implementation evidence. |

## Parameterization Choice

The next implementation lane should use the moment contract: `mu = E[y]`,
`sigma = SD[y]`, and `nu = alpha`. This matches `brms::skew_normal()`,
`brms::SkewNormal`, `glmmTMB::skewnormal()`, and
`RTMBdist::dskewnorm2()` most closely. It is friendlier for `fitted()` and
`sigma()`, but the TMB likelihood must transform from mean/SD to native
`xi`/`omega` internally:

```text
delta = alpha / sqrt(1 + alpha^2)
omega = sigma / sqrt(1 - 2 * delta^2 / pi)
xi = mu - omega * delta * sqrt(2 / pi)
```

The native Azzalini contract remains useful for checking the density with
`sn::dsn()` or `RTMBdist::dskewnorm()`, but it is no longer the preferred public
contract for the first fitted `drmTMB` family.

## Malformed-Neighbour Checklist

The first runnable skew-normal lane should reject these neighbours before TMB:

- any random-effect bar term in `nu`, including `nu ~ x + (1 | id)` and
  `nu ~ x + (0 + x | id)`;
- latent-effect skewness spellings such as `skew(id) ~ x`;
- `skew ~ x` as a public alias until canonical `nu ~ x` is implemented and
  documented;
- `sigma ~ x + (1 | id)`, `sd(id) ~ x`, and any random-effect scale formula;
- `phylo()`, `spatial()`, `animal()`, `relmat()`, and `gr()` in any
  skew-normal formula;
- `meta_V(V = V)` and deprecated `meta_known_V(V = V)`;
- bivariate responses, `mvbind()`, composed families, and any `rho12` formula;
- zero-inflation, hurdle, zero-one-inflation, ordinal, denominator, count, and
  bounded-response neighbours;
- non-finite response or predictors after model-frame filtering;
- non-positive or numerically tiny `sigma`;
- rank-deficient `X_mu`, `X_sigma`, or `X_nu` matrices with silent coefficient
  dropping;
- all-zero or near-all-zero initial `nu` states if derivative checks show the
  optimizer can get stuck at the symmetric limit;
- examples, reference docs, or simulation labels that imply fitted support
  before the constructor, density branch, extractors, diagnostics, and tests
  exist.

## Comparator Tests And Benchmarks To Add Later

Comparator tests should be small before they are broad:

- density equality against `sn::dsn()` and `RTMBdist::dskewnorm()` at negative,
  zero, and positive `nu`, including log-density and tail points;
- normal-limit equality against `gaussian()` when `nu = 0`, with the same
  `mu` and `sigma` interpretation stated in the test name;
- sign-convention tests showing positive `nu` produces right-skewed residuals
  and negative `nu` produces left-skewed residuals under the chosen density;
- simulation recovery for intercept-only `nu`, then `nu ~ w`, with positive
  and negative skew conditions;
- false-positive grids where the data are Gaussian but `sigma ~ z` is active,
  to check that `nu ~ w` does not absorb heteroscedasticity;
- confounding grids where `x`, `z`, and `w` have controlled correlations;
- `fitted()`, `predict(dpar = "mu")`, `sigma()`, and future `predict(dpar =
  "nu")` tests that confirm public response-mean, response-SD, and shape
  semantics;
- profile-target or interval-status rows for fixed `mu`, `sigma`, and `nu`
  coefficients before any coverage claim;
- runtime benchmarks against Gaussian and Student-t fixed-effect models at
  small, moderate, and large `n`, with no random effects in the first run.

The first external comparator set should be `sn` plus either `RTMBdist` or
`brms`/`glmmTMB`, depending on the chosen parameterization. Do not build a
comparator zoo. The purpose is to lock density, sign, fitted-value, and
normal-limit semantics.

## Architecture To Avoid Copying

Do not copy the full GAMLSS surface where every parameter can immediately take
smoothers and random effects. `drmTMB` needs the smaller one-response,
fixed-effect recovery path first. Do not copy Bayesian prior syntax from
`brms`; priors are not part of the current frequentist TMB contract. Do not
copy `mgcv::shash()` as a flexible skewness-and-kurtosis shortcut; it is a
different family and has its own data-sufficiency warning. Do not let
`glmmTMB`'s broad family menu imply that `drmTMB` should add `skewnormal()`
without the package-specific `mu`/`sigma`/`nu`, `fitted()`, and simulation
contract.

## Issues And Roadmap Hooks

The open tracking issue is
[`#3 Add skew-normal location-scale-shape family`](https://github.com/itchyshin/drmTMB/issues/3).
The broader comparator issue
[`#60 Phase 19: comparator-package benchmark and model-fit comparison`](https://github.com/itchyshin/drmTMB/issues/60)
should receive the eventual `sn`, `RTMBdist`, `brms`, and `glmmTMB` comparator
plan after the parameterization decision is final. `ROADMAP.md` already has
the Phase 16 shape/asymmetry entry and row 1953 for the continuous-shape design
boundary; Ada can integrate this source map into those serial ledgers later.

## Supported And Unsafe Novelty Claims

Supported now: `drmTMB` has a documented, evidence-gated plan for a univariate
fixed-effect skew-normal location-scale-shape family with canonical
`mu`/`sigma`/`nu` formulas, residual skewness first, and no latent-effect
skewness grammar.

Not supported now: fitted `skew_normal()` support, latent skewness, skew-normal
random effects, bivariate skew-normal `rho12`, broad phylogenetic
location-scale-shape skewness models, or a claim that `drmTMB` is the first R
package to model skew-normal location, scale, and shape predictors.
