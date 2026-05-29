# drmTMB <a href="https://itchyshin.github.io/drmTMB/"><img src="man/figures/drmTMB-logo.png" align="right" height="138" alt="drmTMB hex logo" /></a>

`drmTMB` fits fast distributional regression models for one or two responses
using Template Model Builder. Use it when predictors may affect not only the
expected response `mu`, but also residual scale `sigma`, shape such as
Student-t `nu`, zero or hurdle probabilities, random-effect scales, or
bivariate residual correlation `rho12`.

The first examples are motivated by ecology, evolution, and environmental
science, but the package is general-purpose. The public scale parameter is
`sigma`. For Gaussian residual-variance or meta-analytic heterogeneity
summaries, report fitted `sigma^2`; for Gamma, Tweedie, beta, count,
zero-inflated, hurdle, Student-t, and bivariate models, use the family-specific
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

This site is built from preview version `0.1.3`. The package is still
pre-CRAN and intentionally bounded: use it for the implemented one-response and
two-response workflows listed below, and treat unsupported model classes as
roadmap work rather than hidden features.

## Install

`drmTMB` is not on CRAN yet. Install the tagged `0.1.3` preview from GitHub
with `pak`:

```r
install.packages("pak")
pak::pak("itchyshin/drmTMB@v0.1.3")
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
  Gaussian, Student-t, lognormal, Gamma, Tweedie, or beta location-scale
  regression with `drm_formula(y ~ x, sigma ~ x)`. The first Tweedie route uses
  `bf(y ~ x, sigma ~ z, nu ~ 1)` for non-negative semicontinuous responses with
  exact zeros; Tweedie random effects and predictor-dependent `nu` remain
  planned. Read
  [Which scale are you modelling?](https://itchyshin.github.io/drmTMB/articles/which-scale.html).
  Student-t, lognormal, Gamma, and beta location formulas also support
  ordinary repeated-measure random intercepts such as
  `bf(y ~ x + (1 | id), sigma ~ z)`; beta uses this syntax only for strict
  `(0, 1)` proportions.
- **Successes out of known trials.** Use `beta_binomial()` with
  `cbind(successes, failures)`. Ordinary repeated-measure random intercepts in
  `mu` are fitted as a first slice with syntax such as
  `bf(cbind(successes, failures) ~ x + (1 | id), sigma ~ z)`. Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Continuous proportions with structural exact 0 or 1 values.** Use
  `zero_one_beta()` with fixed-effect `mu`, `sigma`, `zoi`, and `coi`
  formulas. Here `zoi` is the probability of an exact boundary outcome and
  `coi` is the probability that a boundary outcome is exactly 1. Random
  effects, denominator syntax, structured effects, and bivariate bounded
  responses remain planned or blocked. Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Overdispersed, zero-heavy, truncated, or hurdle counts.** Use
  `poisson()`, `nbinom2()`, `truncated_nbinom2()`, `zi ~`, or `hu ~`.
  Ordinary Poisson and NB2 `mu` random intercepts and independent numeric
  random slopes such as `bf(count ~ x + (1 | id) + (0 + x | id))` are the first
  non-Gaussian random-effect slices. Ordinary Poisson and NB2 also have q=1
  structured `mu` intercept slices, such as
  `bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z)` or
  `bf(count ~ x + spatial(1 | site, coords = coords), sigma ~ z)` for NB2,
  when exactly one structured effect belongs on the log-mean scale. Ordinary NB2 also fits
  the first grouped overdispersion slice, `bf(count ~ x, sigma ~ z + (1 | id))`.
  Correlated count slope blocks, zero-inflation random effects, structured count
  slopes, labelled q=2/q=4 count blocks, NB2 `sigma` slopes or structured
  `sigma` effects, and simultaneous structured count routes remain planned.
  Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Ordered categories.** Use `cumulative_logit()` for fixed-effect
  cumulative-logit ordinal regression with ordered cutpoints and a fixed
  latent logistic scale. Ordinal random effects and scale/discrimination
  formulas remain planned. Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Two Gaussian responses with changing residual correlation.** Use bivariate
  Gaussian location-coscale regression with `mu1`, `mu2`, `sigma1`,
  `sigma2`, and `rho12`. Matching labelled random intercepts in `mu1` and
  `mu2`, such as `(1 | p | id)` in both formulas, fit the first bivariate
  group-level covariance block. Read
  [Changing residual coupling with `rho12`](https://itchyshin.github.io/drmTMB/articles/bivariate-coscale.html).
- **Known sampling variance or covariance.** Use Gaussian meta-analysis with
  `meta_V(V = V)`; deprecated `meta_known_V(V = V)` remains supported only as a
  compatibility alias. Read
  [Mean effects and residual heterogeneity](https://itchyshin.github.io/drmTMB/articles/meta-analysis.html).
- **Structured Gaussian effects.** Use ordinary random effects,
  residual-scale random intercepts or independent random slopes in `sigma`,
  `sd(group) ~ x`, the implemented intercept-only phylogenetic path
  `phylo(1 | species, tree = tree)`, or the first coordinate-spatial path
  `spatial(1 | site, coords = coords)` plus one numeric spatial slope,
  `spatial(1 + x | site, coords = coords)`, for univariate Gaussian `mu`.
  Matching `phylo()` or `spatial()` terms in bivariate `mu1` and `mu2` fit the
  first structured mean-mean correlation slices, and matching labelled all-four
  `phylo()` or `spatial()` terms fit the first constant q=4 location-scale
  covariance blocks. Read
  [Phylogenetic and spatial structured effects](https://itchyshin.github.io/drmTMB/articles/phylogenetic-spatial.html).

## Stable-core matrix

Use this table when you need a quick status check before fitting a model.
"Stable" means a routine fitted surface with tests and user-facing docs. "First
slice" means fitted but intentionally narrow. "Opt-in control" means a
hardening or large-data path, not a general modelling guarantee.
The evidence and debt ledger behind these rows lives in
`docs/design/34-validation-debt-register.md`.

Read status words consistently:

| Status word | Meaning for a user |
| --- | --- |
| Stable | Routine fitted path with tests, diagnostics or interval status, and a reader-facing example or guide. |
| First slice | Fitted and tested, but intentionally narrow; stay inside the named formula, family, and data-shape boundary. |
| Opt-in control | Available for hardening, scalability, or memory control, but not a modelling guarantee for neighbouring surfaces. |
| Planned or reserved | Public grammar or roadmap wording may exist, but `drmTMB()` should reject it or treat it as design-only until likelihood, tests, docs, and after-task evidence land. |
| Unsupported or blocked | Do not use as analysis syntax; fit the nearest implemented model or check the roadmap before interpreting a richer structure. |

| Surface | Current status | Interval and diagnostic status | Main boundary |
| --- | --- | --- | --- |
| One-response families | Stable for Gaussian, Student-t, lognormal, Gamma, Tweedie, beta, zero-one beta, beta-binomial, Poisson, NB2, truncated NB2, hurdle NB2, zero-inflated Poisson, zero-inflated NB2, and cumulative-logit ordinal location; ordinary Poisson and NB2 `mu` random intercepts and independent numeric slopes are the first count random-effect slices; ordinary Student-t, zero-truncated NB2, lognormal, Gamma, beta, and beta-binomial `mu` random intercepts now have Phase 18 artifact lanes and independent numeric `mu` slopes have focused recovery tests; ordinary NB2 now has the first log-`sigma` random-intercept slice; and ordinary Poisson/NB2 now have q=1 structured `mu` intercept first slices for `phylo()`, `spatial()`, `animal()`, and `relmat()` | Wald fixed-effect intervals by default; explicit direct profile targets are listed by `profile_targets()`; Tweedie fixed-effect coefficients use the fixed-effect interval path; ordinary Poisson, NB2, Student-t, zero-truncated NB2, lognormal, Gamma, beta, and beta-binomial `mu` random-effect SDs are direct `log_sd_mu` profile targets; the bounded-response, positive-continuous, Student-t, and zero-truncated NB2 artifact lanes record fixed-effect Wald rows and direct-SD profile rows for ordinary `(1 | id)` in `mu`; independent selected non-Gaussian `mu` slopes have CRAN-safe smoke recovery checks; NB2 ordinary `sigma` random-intercept SDs are direct `log_sd_sigma` targets; Poisson/NB2 structured SDs are direct `log_sd_phylo` profile targets | Random effects are otherwise mostly Gaussian-only; Tweedie random effects, predictor-dependent Tweedie `nu`, non-Gaussian `sigma` random effects outside the ordinary NB2 intercept gate, correlated bounded-response, positive-continuous, Student-t, and zero-truncated NB2 random slopes, Student-t `nu` random effects, correlated count slopes, zero-inflated count random effects, structured count slopes, simultaneous count structured effects, ordinal scale, zero-one beta random effects, and bivariate bounded-response families remain planned |
| Gaussian ordinary random effects | Stable for `mu` intercepts, independent slopes, one-slope correlated blocks, and ordinary q > 2 numeric multi-slope blocks; stable for `sigma` intercepts and multiple independent `sigma` slopes | `check_drm()` reports replication, weak-slope, boundary, and Hessian diagnostics; q > 2 `mu` block SDs and independent `sigma` slope SDs are direct profile targets, while q > 2 `mu` correlations are derived-unavailable for direct profiling | Larger q blocks can be sample-size hungry; correlated residual-scale slope blocks and coefficient-specific `sd()` slope models remain planned |
| Random-effect scale models | First slice fitted for `sd(group) ~ x_group` on unlabelled Gaussian `mu` random intercepts | Fixed SD-surface coefficients are direct targets; row-specific group SD summaries are derived | Slope-specific `sd(id, dpar = "mu", coef = "x") ~ ...` is reserved and rejected |
| Known sampling covariance | Stable for Gaussian `meta_V(V = V)`, including diagonal, dense, and row-paired bivariate known covariance; deprecated `meta_known_V(V = V)` remains supported only as a compatibility alias | `check_drm()` reports dense full `V` as a note with dimension, density, size, rank, and conditioning; fixed effects and response-scale residual summaries use the usual interval routes | Dense covariance is small-to-moderate unless sparse or block-sparse evidence is added; full dense known `V` with non-unit likelihood weights is rejected |
| Bivariate Gaussian residual `rho12` | Stable for fixed-effect `mu1`, `mu2`, `sigma1`, `sigma2`, and predictor-dependent residual `rho12` | `rho12()` extracts response-scale residual correlations; row-specific profile intervals use `confint(..., parm = "rho12", newdata = ...)` | Residual `rho12` is not a group-level, phylogenetic, or spatial correlation |
| Ordinary bivariate covariance and `corpairs()` | First slice fitted for matching labelled random intercepts in `mu1`/`mu2`, `sigma1`/`sigma2`, one or more same-response `mu`/`sigma` blocks, all-four q=4 intercept blocks, matching slope-only `mu1`/`mu2` blocks, and q=2 `corpair(..., level = "group") ~ x` | Constant q=2 SD/correlation targets and the slope-slope `mu1`/`mu2` row are profile-ready; same-response mean-scale blocks report one row per response-specific label/group pair; predictor-dependent `corpair()` values use `newdata`; q=4 unstructured-correlation rows are derived and report unavailable derived intervals | Intercept-plus-slope q=4 location blocks, residual-scale slope blocks, all-four p8/q8 location-scale slope endpoints, and predictor-dependent slope `corpair()` regressions remain planned |
| Phylogenetic structured effects | First slices fitted for Gaussian univariate `mu` and `sigma` intercepts, matching univariate `mu`/`sigma` structured correlations, one numeric `mu` slope, bivariate `mu1`/`mu2`, labelled q=4 location-scale blocks, `sd_phylo*()` direct-SD surfaces, q=2 phylogenetic `corpair()` regression, and ordinary Poisson/NB2 q=1 `mu` intercepts | Direct phylogenetic SD and constant q=2 correlation targets are profile-ready; predictor-dependent `corpair()` values use `newdata`; full q=4 correlations are derived-only, while block-diagonal q=4 fallback correlations are direct targets but still need fit-specific profile diagnostics; the Poisson/NB2 q=1 routes are smoke-level with direct `log_sd_phylo` targets | Multiple phylogenetic slopes, residual-scale structured slopes, structured `rho12`, zero-inflated phylogenetic effects, direct-SD formulas combined with structured `sigma`, and predictor-dependent q=4 correlations remain planned |
| Coordinate spatial structured effects | First slices fitted for Gaussian `mu` and `sigma`: `spatial(1 | site, coords = coords)` can enter univariate location, residual scale, or matching location-scale blocks; one numeric `spatial(1 + x | site, coords = coords)` slope is fitted for univariate `mu`; matching bivariate `mu1`/`mu2` and all-four q=4 spatial blocks are fitted. Ordinary Poisson/NB2 also fit q=1 `spatial(1 | site, coords = coords)` in `mu` on the log-mean scale. | `sdpars$mu`, `sdpars$sigma`, `ranef("spatial_mu")`, `ranef("spatial_sigma")`, `profile_targets()`, `check_drm()`, `corpairs(level = "spatial")`, and `summary()$covariance` expose the coordinate fields, the univariate mean-scale row, the q=2 spatial mean-mean row, and the six derived q=4 spatial rows; q=4 is fitted extractor/diagnostic smoke, not formal coverage evidence | Mesh/SPDE, multiple spatial slopes, residual-scale structured slopes, spatial slope correlations, direct-SD surfaces, spatial `corpair()` regression, count spatial slopes, labelled count covariance, and zero-inflated spatial effects remain planned |
| Animal and lower-level relatedness structured effects | Gaussian `mu` and `sigma` intercepts are fitted for `animal(1 | id, pedigree/A/Ainv = ...)` and `relmat(1 | id, K/Q = ...)`; one numeric `mu` slope is fitted for animal and `relmat()` routes; matching labelled `mu1`/`mu2` terms fit q=2 bivariate location covariance, and matching all-four terms fit constant q=4 location-scale covariance. Ordinary Poisson/NB2 also fit q=1 `animal()` and `relmat()` `mu` intercepts on the log-mean scale. | `sdpars$mu`, `sdpars$sigma`, `corpars$animal` / `corpars$relmat`, `ranef("animal_mu")`, `ranef("animal_sigma")`, `ranef("relmat_mu")`, `ranef("relmat_sigma")`, `corpairs()`, `summary()$covariance`, `profile_targets()`, and `check_drm()` expose the fitted structured fields; q=4 correlations are derived-only | Large-pedigree sparse precision construction, multiple structured slopes, residual-scale structured slopes, slope correlations, predictor-dependent `corpair()` regressions, animal/`relmat()` count slopes or labelled count covariance, and generic direct-SD grammar remain planned |
| Profile intervals and diagnostics | First slice for fixed effects, direct SD/correlation targets, row-specific `sigma`, `sigma1`, `sigma2`, `rho12`, fitted q=2 `corpair()` values, and `confint(..., method = "bootstrap")` simulate/refit intervals for direct targets | `confint()` defaults to fast direct Wald intervals when `sdreport()` is available; SD Wald intervals use the log-SD scale, correlation Wald intervals use a guarded Fisher-z/atanh scale, `profile_precision = "fast"` gives a quicker first-pass profile, `profile_maxit` caps each `TMB::tmbprofile()` target, `parallel = "multicore"` can split profile or bootstrap refits on Unix, and interval output uses `conf.status`, `profile.boundary`, `profile.message`, and bootstrap success/failure counts | Profile and bootstrap support is target-specific; derived q=4 rows report `derived_interval_unavailable` |
| Large-data fit controls | Opt-in controls for memory-light fitted objects, sparse fixed-effect `mu` matrices, and Gaussian sufficient-statistic aggregation | `check_drm()` reports sparse design and aggregation diagnostics where fitted | These controls are first univariate Gaussian paths, not broad scalability claims |
| Reserved or planned neighbours | Reserved/rejected or design-only for coefficient-specific `sd()` slopes, random effects in `rho12`, shape random effects, ID-level skewness such as future `skew(id) ~ x`, phylogenetic slopes, mesh/SPDE, spatial `corpair()`, broader bivariate random slopes, and mixed composed families | Planned-feature errors should fire before fitting; no interval target is advertised | These need likelihood code, recovery tests, diagnostics, documentation, and after-task evidence before use |

## Current boundaries

`drmTMB` currently supports one-response and two-response models. Higher
dimensional multivariate models belong in a different tool.

Random effects are strongest in the Gaussian routes. The non-Gaussian mixed
surface is still deliberately small: ordinary Poisson/NB2 `mu` random effects,
ordinary Student-t/zero-truncated NB2/lognormal/Gamma/beta/beta-binomial `mu`
random intercepts, and the first ordinary Poisson/NB2 q=1 structured `mu`
intercepts are fitted for `phylo()`, `spatial()`, `animal()`, and `relmat()`.
The beta/beta-binomial, lognormal/Gamma, Student-t, and
zero-truncated NB2 ordinary `mu` random intercepts now have small Phase 18
artifact lanes, not broad bounded-response, positive-continuous, Student-t, or
count random-effect claims.
Ordinary NB2 also has a first grouped overdispersion path in `sigma`, limited
to independent random intercepts on the log-`sigma` scale. Most other
non-Gaussian random-effect and structured-dependence combinations remain
planned after fixed-effect likelihoods, diagnostics, and simulations are
stable.

Residual `rho12` is a within-observation bivariate Gaussian correlation. It is
not the same as a group-level correlation among individual intercepts, slopes,
or residual-scale random effects. Univariate Gaussian `sigma` formulas now
fit residual-scale random intercepts and independent random slopes, while
`drmTMB` fits the first ordinary group-level covariance slices: univariate
labelled `mu`/`sigma` random-intercept correlations from matching
`(1 | p | id)` terms, bivariate labelled `mu1`/`mu2` and `sigma1`/`sigma2`
random-intercept correlations, and one or more same-response bivariate
`mu`/`sigma` random-intercept correlations such as `mu1` with `sigma1` using
label `p` and `mu2` with `sigma2` using label `q`.

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
The
[implementation map](https://itchyshin.github.io/drmTMB/articles/implementation-map.html)
gives the finer ledger by family, distributional parameter, dependence layer,
q, random-slope support, `corpairs()`, `zi`, and `hu`.

Spatial syntax is part of the structured-effect design. The fitted coordinate
path supports a univariate Gaussian location random intercept,
`spatial(1 | site, coords = coords)`, one numeric location slope,
`spatial(1 + x | site, coords = coords)`, and the first bivariate q=2
`mu1`/`mu2` location covariance from matching
`spatial(1 | p | site, coords = coords)` terms. The fitted spatial SDs appear in
`sdpars$mu`/`sdpars$sigma`, conditional effects in `ranef("spatial_mu")` and
`ranef("spatial_sigma")`, direct SD and
correlation targets in `profile_targets()`, and the q=2 mean-mean row in
`corpairs(level = "spatial")` and `summary()$covariance`. Matching labelled
spatial terms across `mu1`, `mu2`, `sigma1`, and `sigma2` now fit the constant
q=4 location-scale block and report six derived spatial covariance rows.
Mesh/SPDE fields, multiple spatial slopes, residual-scale structured slopes,
spatial slope correlations, direct spatial SD surfaces,
predictor-dependent spatial `corpair()` regression, and non-Gaussian spatial
effects are still planned rather than landing-page workflows.

For uncertainty, `confint()` defaults to the fast path when `TMB::sdreport()`
has been computed: Wald intervals for fixed-effect coefficients plus direct
constant scale, random-effect SD, random-effect correlation, and constant
`rho12` targets. SD intervals are formed on the fitted log-SD scale and
exponentiated; correlation intervals are formed on the guarded Fisher-z/atanh
scale and transformed back to correlations. For long phylogenetic or spatial
fits, start with a narrow target set such as
`confint(fit, parm = "variance_components")` or the specific
`sd:mu:phylo(...)` row from `profile_targets(fit)`. Use `method = "profile"`
only for selected direct targets when likelihood shape matters;
`profile_precision = "fast"` supplies quicker `TMB::tmbprofile()` controls for
a first-pass interval. `method = "bootstrap"` runs simulate/refit percentile
intervals and reports successful and failed refits for cases where refit-based
uncertainty is needed; positive scale and SD bootstrap intervals take
percentiles on the fitted log scale and exponentiate the endpoints.

## Project status

The package is under active development. See the
[roadmap](https://itchyshin.github.io/drmTMB/ROADMAP.html), the
[reference index](https://itchyshin.github.io/drmTMB/reference/index.html), and
the articles above for the current fitted workflows.
