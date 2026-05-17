# drmTMB <a href="https://itchyshin.github.io/drmTMB/"><img src="man/figures/drmTMB-logo.png" align="right" height="138" alt="drmTMB hex logo" /></a>

`drmTMB` fits fast distributional regression models for one or two responses
using Template Model Builder. Use it when predictors may affect not only the
expected response `mu`, but also residual scale `sigma`, shape such as
Student-t `nu`, zero or hurdle probabilities, random-effect scales, or
bivariate residual correlation `rho12`.

The first examples are motivated by ecology, evolution, and environmental
science, but the package is general-purpose. The public scale parameter is
`sigma`. For Gaussian residual-variance or meta-analytic heterogeneity
summaries, report fitted `sigma^2`; for Gamma, beta, count, zero-inflated,
hurdle, Student-t, and bivariate models, use the family-specific
transformations in
[Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
The design rule is that larger `sigma` should mean larger modelled
variability, even when another package or textbook writes the same likelihood
with a precision parameter such as `phi` or `theta`.

## Start here

- New to the package? Read
  [Getting started](https://itchyshin.github.io/drmTMB/articles/drmTMB.html).
- Not sure which response family fits your data? Use
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- Unsure whether you are modelling residual variation, group variation, or
  known sampling uncertainty? Read
  [Which scale are you modelling?](https://itchyshin.github.io/drmTMB/articles/which-scale.html).
- Fitting a bivariate Gaussian model? See
  [Changing residual coupling with `rho12`](https://itchyshin.github.io/drmTMB/articles/bivariate-coscale.html).
- Working with effect sizes or study-level sampling uncertainty? See
  [Mean effects and residual heterogeneity](https://itchyshin.github.io/drmTMB/articles/meta-analysis.html).
- Checking a fitted model? See
  [Model workflow](https://itchyshin.github.io/drmTMB/articles/model-workflow.html)
  and the [`check_drm()` reference](https://itchyshin.github.io/drmTMB/reference/check_drm.html).

## Preview status

This site is built from preview version `0.1.2`. The package is still
pre-CRAN and intentionally bounded: use it for the implemented one-response and
two-response workflows listed below, and treat unsupported model classes as
roadmap work rather than hidden features.

## Install

`drmTMB` is not on CRAN yet. Install the tagged `0.1.2` preview from GitHub
with `pak`:

```r
install.packages("pak")
pak::pak("itchyshin/drmTMB@v0.1.2")
```

If you want the newest development build from `main`, use:

```r
pak::pak("itchyshin/drmTMB")
```

Then load the package and run a small smoke test:

```r
library(drmTMB)

set.seed(1)
dat <- data.frame(x1 = rnorm(80))
dat$y <- rnorm(
  80,
  mean = 0.2 + 0.4 * dat$x1,
  sd = exp(-0.4 + 0.5 * dat$x1)
)

fit <- drmTMB(
  drm_formula(y ~ x1, sigma ~ x1),
  family = gaussian(),
  data = dat
)

summary(fit)
check_drm(fit)
head(sigma(fit))

sigma_x1 <- coef(fit, "sigma")["x1"]
exp(sigma_x1) # residual SD ratio for a one-unit increase in x1
exp(2 * sigma_x1) # residual variance ratio
```

You need R 4.1.0 or newer and a working compiler toolchain because TMB models
are compiled during installation. If installation fails while compiling C++,
install the usual R build tools for your platform: Rtools on Windows, Xcode
Command Line Tools on macOS, or the R development toolchain on Linux.

Core runtime dependencies are installed automatically by `pak`: `cli`,
`Matrix`, `TMB`, and the compiled headers from `RcppEigen` and `TMB`.
Some articles, comparators, and development checks also use optional packages
such as `glmmTMB`, `lme4`, `MASS`, `metafor`, `knitr`, `rmarkdown`,
`testthat`, and `withr`; site checks use `pkgdown`.

## Tiny example

A Gaussian location-scale model lets the same predictor change the expected
response and the residual standard deviation:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = beta_0 + beta_1 x1_i
log(sigma_i) = gamma_0 + gamma_1 x1_i
```

```r
fit <- drmTMB(
  drm_formula(y ~ x1, sigma ~ x1),
  family = gaussian(),
  data = dat
)
```

Here `x1` can change the expected response through `y ~ x1` and the residual
standard deviation through `sigma ~ x1`. A positive `sigma` coefficient means
residual variation increases with `x1`. The coefficient is on the log-SD
scale, so exponentiate it before interpreting it:

```r
sigma_x1 <- coef(fit, "sigma")["x1"]
exp(sigma_x1) # residual SD ratio for a one-unit increase in x1
exp(2 * sigma_x1) # residual variance ratio
head(sigma(fit)^2) # fitted residual variances
```

`bf()` is available as a short alias for `drm_formula()`.

## What can I model now?

- **Continuous response, changing mean or family-specific variation.** Use
  Gaussian, Student-t, lognormal, Gamma, or beta location-scale regression with
  `drm_formula(y ~ x, sigma ~ x)`. Read
  [Which scale are you modelling?](https://itchyshin.github.io/drmTMB/articles/which-scale.html).
- **Successes out of known trials.** Use `beta_binomial()` with
  `cbind(successes, failures)`. Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Overdispersed, zero-heavy, truncated, or hurdle counts.** Use
  `poisson()`, `nbinom2()`, `truncated_nbinom2()`, `zi ~`, or `hu ~`.
  Ordinary Poisson `mu` random intercepts and independent numeric random slopes
  such as `bf(count ~ x + (1 | id) + (0 + x | id))` are the first
  non-Gaussian random-effect slice; correlated Poisson slope blocks and
  zero-inflation random effects remain planned. Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Ordered categories.** Use `cumulative_logit()` for fixed-effect
  cumulative-logit ordinal regression. See the
  [reference index](https://itchyshin.github.io/drmTMB/reference/index.html).
- **Two Gaussian responses with changing residual correlation.** Use bivariate
  Gaussian location-coscale regression with `mu1`, `mu2`, `sigma1`,
  `sigma2`, and `rho12`. Matching labelled random intercepts in `mu1` and
  `mu2`, such as `(1 | p | id)` in both formulas, fit the first bivariate
  group-level covariance block. Read
  [Changing residual coupling with `rho12`](https://itchyshin.github.io/drmTMB/articles/bivariate-coscale.html).
- **Known sampling variance or covariance.** Use Gaussian meta-analysis with
  `meta_known_V(V = V)`. Read
  [Mean effects and residual heterogeneity](https://itchyshin.github.io/drmTMB/articles/meta-analysis.html).
- **Structured Gaussian effects.** Use ordinary random effects,
  residual-scale random intercepts or independent random slopes in `sigma`,
  `sd(group) ~ x`, the implemented intercept-only phylogenetic path
  `phylo(1 | species, tree = tree)`, or the first coordinate-spatial path
  `spatial(1 | site, coords = coords)` plus one numeric spatial slope,
  `spatial(1 + x | site, coords = coords)`, for univariate Gaussian `mu`.
  Matching `phylo()` terms in bivariate `mu1` and `mu2` fit the first
  phylogenetic mean-mean correlation slice, and matching labelled all-four
  `phylo()` terms fit the first constant q=4 phylogenetic location-scale
  covariance block. Read
  [Phylogenetic and spatial structured effects](https://itchyshin.github.io/drmTMB/articles/phylogenetic-spatial.html).

## Stable-core matrix

Use this table when you need a quick status check before fitting a model.
"Stable" means a routine fitted surface with tests and user-facing docs. "First
slice" means fitted but intentionally narrow. "Opt-in control" means a
hardening or large-data path, not a general modelling guarantee.
The evidence and debt ledger behind these rows lives in
`docs/design/34-validation-debt-register.md`.

| Surface | Current status | Interval and diagnostic status | Main boundary |
| --- | --- | --- | --- |
| Fixed-effect one-response families | Stable for Gaussian, Student-t, lognormal, Gamma, beta, beta-binomial, Poisson, NB2, truncated NB2, hurdle NB2, zero-inflated Poisson, zero-inflated NB2, and cumulative-logit ordinal location; ordinary Poisson `mu` random intercepts and independent numeric slopes are the first non-Gaussian random-effect slice | Wald fixed-effect intervals by default; explicit direct profile targets are listed by `profile_targets()`; Poisson random-effect SDs are direct `log_sd_mu` profile targets | Random effects are otherwise mostly Gaussian-only; non-Gaussian `sigma` and shape random effects, correlated Poisson slopes, NB2 random effects, ordinal scale, and richer bounded-response families including zero-one inflation remain planned |
| Gaussian ordinary random effects | Stable for `mu` intercepts, independent slopes, and one-slope correlated blocks; stable for `sigma` intercepts and independent slopes | `check_drm()` reports replication, weak-slope, boundary, and Hessian diagnostics; direct SD and fitted correlation targets are profile-ready when the TMB object is retained | Correlated residual-scale slope blocks and coefficient-specific `sd()` slope models remain planned |
| Random-effect scale models | First slice fitted for `sd(group) ~ x_group` on unlabelled Gaussian `mu` random intercepts | Fixed SD-surface coefficients are direct targets; row-specific group SD summaries are derived | Slope-specific `sd(id, dpar = "mu", coef = "x") ~ ...` is reserved and rejected |
| Known sampling covariance | Stable for Gaussian `meta_known_V(V = V)`, including diagonal, dense, and row-paired bivariate known covariance | `check_drm()` reports dense full `V` as a note with dimension, density, size, rank, and conditioning; fixed effects and response-scale residual summaries use the usual interval routes | Dense covariance is small-to-moderate unless sparse or block-sparse evidence is added; full dense known `V` with non-unit likelihood weights is rejected |
| Bivariate Gaussian residual `rho12` | Stable for fixed-effect `mu1`, `mu2`, `sigma1`, `sigma2`, and predictor-dependent residual `rho12` | `rho12()` extracts response-scale residual correlations; row-specific profile intervals use `confint(..., parm = "rho12", newdata = ...)` | Residual `rho12` is not a group-level, phylogenetic, or spatial correlation |
| Ordinary bivariate covariance and `corpairs()` | First slice fitted for matching labelled random intercepts in `mu1`/`mu2`, `sigma1`/`sigma2`, same-response `mu`/`sigma`, all-four q=4 blocks, and q=2 `corpair(..., level = "group") ~ x` | Constant q=2 SD/correlation targets are profile-ready; predictor-dependent `corpair()` values use `newdata`; q=4 unstructured-correlation rows are derived and report unavailable derived intervals | Bivariate random slopes and slope1-slope2 plasticity-syndrome correlations remain planned |
| Phylogenetic structured effects | First slices fitted for univariate `mu`, bivariate `mu1`/`mu2`, labelled q=4 location-scale blocks, `sd_phylo*()` direct-SD surfaces, and q=2 phylogenetic `corpair()` regression | Direct phylogenetic SD and constant q=2 correlation targets are profile-ready; predictor-dependent `corpair()` values use `newdata`; q=4 phylogenetic correlations are derived-only for intervals | Phylogenetic slopes, standalone or partial phylogenetic scale terms, structured `rho12`, and predictor-dependent q=4 correlations remain planned |
| Coordinate spatial structured effects | First slice fitted for univariate Gaussian `mu`: `spatial(1 | site, coords = coords)` and one numeric `spatial(1 + x | site, coords = coords)` slope | `sdpars$mu`, `ranef("spatial_mu")`, `profile_targets()`, and `check_drm()` expose the coordinate fields | Mesh/SPDE, multiple spatial slopes, spatial slope correlations, spatial `sigma`, bivariate spatial covariance, and spatial `corpair()` remain planned |
| Profile intervals and diagnostics | First slice for fixed effects, direct SD/correlation targets, row-specific `sigma`, `sigma1`, `sigma2`, `rho12`, and fitted q=2 `corpair()` values | Interval output uses `conf.status`, `profile.boundary`, and `profile.message`; derived q=4 rows report `derived_interval_unavailable` | Profile support is target-specific, and public bootstrap intervals are not implemented yet |
| Large-data fit controls | Opt-in controls for memory-light fitted objects, sparse fixed-effect `mu` matrices, and Gaussian sufficient-statistic aggregation | `check_drm()` reports sparse design and aggregation diagnostics where fitted | These controls are first univariate Gaussian paths, not broad scalability claims |
| Reserved or planned neighbours | Reserved/rejected or design-only for coefficient-specific `sd()` slopes, random effects in `rho12`, shape random effects, ID-level skewness such as future `skew(id) ~ x`, phylogenetic slopes, mesh/SPDE, spatial `corpair()`, bivariate random slopes, and mixed composed families | Planned-feature errors should fire before fitting; no interval target is advertised | These need likelihood code, recovery tests, diagnostics, documentation, and after-task evidence before use |

## Current boundaries

`drmTMB` currently supports one-response and two-response models. Higher
dimensional multivariate models belong in a different tool.

Random effects are strongest in the Gaussian routes. Many non-Gaussian
families currently use fixed effects only, with random-effect extensions
planned after the fixed-effect likelihoods and simulations are stable.

Residual `rho12` is a within-observation bivariate Gaussian correlation. It is
not the same as a group-level correlation among individual intercepts, slopes,
or residual-scale random effects. Univariate Gaussian `sigma` formulas now
fit residual-scale random intercepts and independent random slopes, while
`drmTMB` fits four first group-level covariance slices: a univariate labelled
`mu`/`sigma` random-intercept correlation from matching `(1 | p | id)` terms,
bivariate labelled `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept
correlations, and one same-response bivariate `mu`/`sigma` random-intercept
correlation such as `mu1` with `sigma1`.

Full double-hierarchical individual-difference models are planned work. These
models would jointly describe individual differences in average behaviour,
plasticity, predictability, and malleability. The package direction is to keep
the public `sigma` grammar, report variance-facing summaries as `sigma^2`, and
eventually expose both group-level individual-difference correlations and
residual `rho12`.

For comparative mammal, bird, or other trait protocols, the current practical
path is staged: fit bivariate residual coupling, ordinary group-level
correlations, univariate phylogenetic structure, fitted phylogenetic
`corpairs()`, and the first bivariate phylogenetic location-scale blocks as
separate implemented models. The
[model map](https://itchyshin.github.io/drmTMB/articles/model-map.html) shows
how to keep those answers separate until the full phylogenetic
location-scale double-hierarchical endpoint is implemented.

Spatial syntax is part of the structured-effect design. The fitted coordinate
path supports a univariate Gaussian location random intercept,
`spatial(1 | site, coords = coords)`, and one numeric location slope,
`spatial(1 + x | site, coords = coords)`, with `sdpars$mu`,
`ranef("spatial_mu")`, profile targets, and a `check_drm()` spatial diagnostic
row. Mesh/SPDE fields, multiple spatial slopes, spatial slope correlations,
spatial scale terms, and bivariate spatial covariance blocks are still planned
rather than landing-page workflows.

For uncertainty, `confint()` returns Wald intervals for fixed effects by
default when `TMB::sdreport()` has been computed, and profile-likelihood
intervals only for explicit direct targets. Use `profile_targets(fit)` to see
which SD, correlation, scale, or `rho12` targets are ready. Interval-aware
summaries use `conf.status` to separate returned intervals from rows that need
`newdata`, derived-profile methods, or refitting with
`control = drm_control(se = TRUE)` for Wald standard errors; profile rows also
report `profile.boundary` and `profile.message` so boundary or
near-correlation-limit intervals are visible before interpretation.

## Project status

The package is under active development. See the
[roadmap](https://itchyshin.github.io/drmTMB/ROADMAP.html), the
[reference index](https://itchyshin.github.io/drmTMB/reference/index.html), and
the articles above for the current fitted workflows.
