# drmTMB <a href="https://itchyshin.github.io/drmTMB/"><img src="man/figures/drmTMB-logo.png" align="right" height="138" alt="drmTMB hex logo" /></a>

<!-- badges: start -->
[![R-CMD-check](https://github.com/itchyshin/drmTMB/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/itchyshin/drmTMB/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/itchyshin/drmTMB/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/itchyshin/drmTMB/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

`drmTMB` fits fast distributional regression models for one or two responses
using Template Model Builder. Use it when predictors may affect not only the
expected response `mu`, but also residual scale `sigma`, shape such as
Student-t `nu`, zero or hurdle probabilities, random-effect scales, or
bivariate residual correlation `rho12`.

The first examples are motivated by ecology, evolution, and environmental
science, but the package is general-purpose. The public scale parameter is
`sigma`: read [Which scale are you modelling?](https://itchyshin.github.io/drmTMB/articles/which-scale.html)
before translating a family-specific precision or dispersion parameter.

## Start with one route

- **Fit a first model:** [Getting started](https://itchyshin.github.io/drmTMB/articles/drmTMB.html)
  and the [function map and cheat sheet](https://itchyshin.github.io/drmTMB/articles/function-map-cheatsheet.html).
- **Choose the model:** [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html),
  [Which scale are you modelling?](https://itchyshin.github.io/drmTMB/articles/which-scale.html),
  and [What can I fit today?](https://itchyshin.github.io/drmTMB/articles/model-map.html).
- **Extend or check a fit:** [Model workflow](https://itchyshin.github.io/drmTMB/articles/model-workflow.html),
  [bivariate Gaussian models with `rho12`](https://itchyshin.github.io/drmTMB/articles/bivariate-coscale.html),
  [meta-analysis](https://itchyshin.github.io/drmTMB/articles/meta-analysis.html), and
  [`check_drm()`](https://itchyshin.github.io/drmTMB/reference/check_drm.html).

## Experimental release preview

This site is built from the `0.6.0` release candidate (`DESCRIPTION` reads
`0.6.0`), the version being prepared for a first CRAN submission. It is not yet
on CRAN or tagged. The package is still
intentionally bounded: use it for the documented one-response and two-response
workflows, and treat unsupported model classes as roadmap work
rather than hidden features.

The `0.x` version reflects an intentionally bounded and evolving inference
surface. For an unfamiliar random-effect or structured-effect route, read
[What can I trust?](https://itchyshin.github.io/drmTMB/articles/capability-and-limits.html)
before relying on it; the linked model and implementation maps distinguish
fitted, recovery-grade, and planned work.

## Install

`drmTMB` is not on CRAN yet. Install the current development version (the
`0.6.0` line) from GitHub with `pak`:

```r
install.packages("pak")
pak::pak("itchyshin/drmTMB")
```

The earlier `v0.5.0` tag predates the current line and is not a supported
install target; a `0.6.0` release will be tagged when it reaches CRAN.

You need R 4.1.0 or newer and a working compiler toolchain because TMB models
are compiled during installation. If installation fails while compiling C++,
install the usual R build tools for your platform: Rtools on Windows, Xcode
Command Line Tools on macOS, or the R development toolchain on Linux.

See [Getting started](https://itchyshin.github.io/drmTMB/articles/drmTMB.html)
if installation or compilation needs troubleshooting.

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

## Choose a route

For a one-response analysis, start with [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
It covers continuous, count, proportion, binary, and ordinal responses, while
the [model map](https://itchyshin.github.io/drmTMB/articles/model-map.html)
answers whether a particular formula is available today.

For random or structured effects, use the [structural dependence overview](https://itchyshin.github.io/drmTMB/articles/structural-dependence.html)
before choosing `phylo()`, `spatial()`, `animal()`, or `relmat()`. For two
Gaussian responses, use [the `rho12` tutorial](https://itchyshin.github.io/drmTMB/articles/bivariate-coscale.html);
for known sampling variance or covariance, use [the meta-analysis route](https://itchyshin.github.io/drmTMB/articles/meta-analysis.html).
When some values are missing, [handling missing data](https://itchyshin.github.io/drmTMB/articles/missing-data.html)
covers the two separate axes: which response families marginalise a missing
response, and which predictors can be modelled with `mi()`.

## Keep the boundary visible

The model map is the shortest answer to “can I fit this?”; the
[implementation map](https://itchyshin.github.io/drmTMB/articles/implementation-map.html)
records the narrower fitted-versus-planned surface. The
[capabilities and limits guide](https://itchyshin.github.io/drmTMB/articles/capability-and-limits.html)
explains which fitted routes have recovery or interval evidence. Do not infer
support for a neighbouring formula from syntax that happens to parse.

`drmTMB` supports one-response and two-response models. Higher-dimensional
multivariate models, richer unsupported random-effect structures, and the
optional Julia engine are not hidden alternatives to the documented R/TMB
workflows.

## What has evidence today

Tier and tested domain differ by family and by route, so treat this as an index,
not a warranty. Every fitted univariate
non-Gaussian family has at least recovery-grade ordinary `mu` random-intercept
and independent numeric-slope evidence. Read
[What can I trust?](https://itchyshin.github.io/drmTMB/articles/capability-and-limits.html)
for the row-specific tiers, floors, and caveats.

- **Asymmetric and semicontinuous responses.** Tweedie and
  skew-normal both fit ordinary unlabelled `mu` random intercepts and
  independent numeric slopes. Their exact independent-slope cells are
  `inference_ready_with_caveats` for true slope SD 0.50 and `M >= 16`; that is
  not a `supported` or all-design claim.
- **Bounded proportions.** For `zero_one_beta()`, `zoi` is the probability of an
  exact boundary outcome and `coi` is the probability that a boundary outcome
  is exactly 1. Ordinary
  unlabelled `mu` random intercepts and independent numeric slopes are
  recovery-grade, under generator-qualified evidence. Correlated or labelled
  slopes and `sigma`/`zoi`/`coi` random effects remain planned.
- **Structured counts.** Ordinary Poisson and NB2 fit q=1 `phylo()`,
  `spatial()`, `animal()`, and `relmat()` `mu` intercept-plus-one-slope routes;
  the exact q=1 NB2 structured `sigma` intercept-plus-one-slope routes are
  fitted at recovery grade, with intervals and coverage planned.
- **Diagnostic-only spatial gates.** Poisson slope-only `mu ~ spatial(0 + x | site, coords = coords)`,
  Poisson labelled-scalar `mu ~ spatial(1 | p | site, coords = coords)`, and
  Poisson `mu ~ spatial(1 | site, coords = coords) + (1 | id)` are single-smoke
  diagnostic-only. Two fixed-zero-inflation spatial-`mu` routes are also exact
  diagnostic-only gates: Poisson with
  `bf(count ~ x + spatial(1 | site, coords = coords), zi ~ 1)` and NB2 with
  `bf(count ~ x + spatial(1 | site, coords = coords), sigma ~ 1, zi ~ 1)`.
  These gates keep zero inflation fixed; they confirm local fit/extractor
  feasibility but do not establish point-estimate recovery, intervals, or
  coverage.

Mesh/SPDE fields, multiple spatial slopes, spatial slope correlations, direct
spatial SD surfaces, predictor-dependent spatial `corpair()` regression, and
non-Gaussian spatial effects outside the
exact ordinary Poisson/NB2 q1 spatial `mu` intercept-plus-one-slope,
recovery-grade NB2 q1 spatial `sigma`, Student-t spatial `mu`, Poisson spatial
`zi`, fixed-`zi` Poisson spatial `mu`, and fixed-`zi` NB2 spatial `mu` gates
remain planned rather than landing-page workflows. The same applies to
non-Gaussian phylogenetic slopes outside the exact unlabelled Poisson/NB2 q1 intercept-plus-one-slope gates.

## Project status

The package is under active development. See the
[roadmap](https://itchyshin.github.io/drmTMB/ROADMAP.html), the
[reference index](https://itchyshin.github.io/drmTMB/reference/index.html), and
the articles above for the current fitted workflows.
