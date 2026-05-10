# drmTMB <a href="https://itchyshin.github.io/drmTMB/"><img src="man/figures/drmTMB-logo.png" align="right" height="138" alt="drmTMB hex logo" /></a>

`drmTMB` fits fast distributional regression models for one or two responses
using Template Model Builder. Use it when predictors may affect not only the
expected response `mu`, but also residual scale `sigma`, shape such as
Student-t `nu`, zero or hurdle probabilities, random-effect scales, or
bivariate residual correlation `rho12`.

The first examples are motivated by ecology, evolution, and environmental
science, but the package is general-purpose. The public scale parameter is
`sigma`; when a paper reports residual variance or predictability, summarize
`sigma^2` from fitted values rather than changing the model grammar.

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

This site is built from preview version `0.1.1`. The package is still
pre-CRAN and intentionally bounded: use it for the implemented one-response and
two-response workflows listed below, and treat unsupported model classes as
roadmap work rather than hidden features.

## Install

`drmTMB` is not on CRAN yet. Install the tagged `0.1.1` preview from GitHub
with `pak`:

```r
install.packages("pak")
pak::pak("itchyshin/drmTMB@v0.1.1")
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
head(sigma(fit))
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

- **Continuous response, changing mean or residual variation.** Use Gaussian,
  Student-t, lognormal, Gamma, or beta location-scale regression with
  `drm_formula(y ~ x, sigma ~ x)`. Read
  [Which scale are you modelling?](https://itchyshin.github.io/drmTMB/articles/which-scale.html).
- **Successes out of known trials.** Use `beta_binomial()` with
  `cbind(successes, failures)`. Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Overdispersed, zero-heavy, truncated, or hurdle counts.** Use
  `poisson()`, `nbinom2()`, `truncated_nbinom2()`, `zi ~`, or `hu ~`. Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Ordered categories.** Use `cumulative_logit()` for fixed-effect
  cumulative-logit ordinal regression. See the
  [reference index](https://itchyshin.github.io/drmTMB/reference/index.html).
- **Two Gaussian responses with changing residual correlation.** Use bivariate
  Gaussian location-coscale regression with `mu1`, `mu2`, `sigma1`,
  `sigma2`, and `rho12`. Read
  [Changing residual coupling with `rho12`](https://itchyshin.github.io/drmTMB/articles/bivariate-coscale.html).
- **Known sampling variance or covariance.** Use Gaussian meta-analysis with
  `meta_known_V(V = V)`. Read
  [Mean effects and residual heterogeneity](https://itchyshin.github.io/drmTMB/articles/meta-analysis.html).
- **Structured Gaussian location effects.** Use ordinary random effects,
  `sd(group) ~ x`, or the implemented intercept-only phylogenetic path
  `phylo(1 | species, tree = tree)`. Read
  [Phylogenetic and spatial structured effects](https://itchyshin.github.io/drmTMB/articles/phylogenetic-spatial.html).

## Current boundaries

`drmTMB` currently supports one-response and two-response models. Higher
dimensional multivariate models belong in a different tool.

Random effects are strongest in the Gaussian routes. Many non-Gaussian
families currently use fixed effects only, with random-effect extensions
planned after the fixed-effect likelihoods and simulations are stable.

Residual `rho12` is a within-observation bivariate Gaussian correlation. It is
not the same as a group-level correlation among individual intercepts, slopes,
or residual-scale random effects.

Full double-hierarchical individual-difference models are planned work. These
models would jointly describe individual differences in average behaviour,
plasticity, predictability, and malleability. The package direction is to keep
the public `sigma` grammar, report variance-facing summaries as `sigma^2`, and
eventually expose both group-level individual-difference correlations and
residual `rho12`.

Spatial syntax is part of the structured-effect design, but routine spatial
model fitting is still planned rather than a first landing-page workflow.

## Project status

The package is under active development. See the
[roadmap](https://itchyshin.github.io/drmTMB/ROADMAP.html), the
[reference index](https://itchyshin.github.io/drmTMB/reference/index.html), and
the articles above for the current fitted workflows.
