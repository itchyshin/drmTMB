# drmTMB <a href="https://itchyshin.github.io/drmTMB/"><img src="man/figures/drmTMB-logo.png" align="right" height="138" alt="drmTMB hex logo" /></a>

<!-- badges: start -->
[![R-CMD-check](https://github.com/itchyshin/drmTMB/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/itchyshin/drmTMB/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/itchyshin/drmTMB/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/itchyshin/drmTMB/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

> **Warning — experimental software.** `drmTMB` is experimental and should be
> used at your own risk. A successful fit, a green diagnostic, or package
> availability is not enough on its own: independently check data preparation,
> model specification, convergence, and scientific conclusions. See
> [Capabilities and limits](https://itchyshin.github.io/drmTMB/articles/capability-and-limits.html)
> for the documented workflows and their current evidence; anything beyond
> those stated boundaries remains provisional.

`drmTMB` 0.7.1 is an experimental pre-CRAN release. The guides below describe
the workflows that can be fitted today; they do not turn an internal release
ledger into evidence for a scientific conclusion.

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

## Start with your scientific question

Choose one route. Each begins with a runnable example and tells you what to
check before interpreting the result.

| If your data and question are... | Start here | Important limit |
| --- | --- | --- |
| One response, and predictors may change its average or residual variability | [Distributional regression with drmTMB](https://itchyshin.github.io/drmTMB/articles/drmTMB.html) | Begin with the simplest response family that matches the data; a successful fit still needs `check_drm()`. |
| A trait or response measured across related species, with a tree | [Phylogenetic mixed models](https://itchyshin.github.io/drmTMB/articles/phylogenetic-models.html) | The first worked route is Gaussian and needs repeated observations within species to separate phylogenetic from residual variation. |
| One Gaussian response measured at named sites with coordinates | [Coordinate-spatial structured effects](https://itchyshin.github.io/drmTMB/articles/spatial-models.html) | Start with a coordinate-spatial location intercept. Repeated observations within sites are needed to separate site-level spatial variation from residual variation; range and interval claims are not established by this first route. |
| Effect sizes with known sampling variances or covariance | [Mean effects and residual heterogeneity](https://itchyshin.github.io/drmTMB/articles/meta-analysis.html) | This is a Gaussian known-variance route, not a response-family choice for raw observations. |

For a count, proportion, zero-heavy, robust, bivariate, spatial, pedigree, or
known-matrix analysis, use [What can I fit today?](https://itchyshin.github.io/drmTMB/articles/model-map.html)
to find the relevant guide. Before reporting an estimate or interval, read
[Can I fit and report this model?](https://itchyshin.github.io/drmTMB/articles/capability-and-limits.html).

`DRModels.jl` is an optional Julia companion; it is not required to use this R
package.

## Install

`drmTMB` is not on CRAN yet. Install the current development source from
GitHub with `pak`:

```r
install.packages("pak")
pak::pak("itchyshin/drmTMB")
```

After CRAN accepts the package, install the released version with
`install.packages("drmTMB")`.

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
  Gaussian, Student-t, skew-normal, lognormal, Gamma, Tweedie, or beta
  location-scale regression with `drm_formula(y ~ x, sigma ~ x)`. The first
  Tweedie route uses `bf(y ~ x, sigma ~ z, nu ~ 1)` for non-negative
  semicontinuous responses with exact zeros; the first skew-normal route uses
  `bf(y ~ x, sigma ~ z, nu ~ w)` for residual asymmetry. Tweedie and
  skew-normal both fit ordinary unlabelled `mu` random intercepts and
  independent numeric slopes at recovery grade. Predictor-dependent Tweedie
  `nu`, correlated or labelled `mu` slopes, distributional-parameter random
  effects, and structured effects remain planned. Read
  [Which scale are you modelling?](https://itchyshin.github.io/drmTMB/articles/which-scale.html).
  Student-t, skew-normal, lognormal, Gamma, Tweedie, beta, and zero-one-beta
  location formulas also support
  ordinary repeated-measure random intercepts such as
  `bf(y ~ x + (1 | id), sigma ~ z)`; beta uses this syntax only for strict
  `(0, 1)` proportions.
- **Event indicators or successes out of known trials.** Use native TMB
  `stats::binomial(link = "logit")` for event-probability models
  with 0/1 responses or `cbind(successes, failures)` counts when ordinary
  binomial sampling variation is enough. Ordinary mean-model random intercepts
  and independent slopes are available for a limited set of models. Use `beta_binomial()` with
  `cbind(successes, failures)` when the data need extra-binomial variation
  through `sigma`. Use ML for scientific reporting. `REML = TRUE` is otherwise
  a Gaussian-model option. The optional Julia engine currently covers only
  fixed-effect binomial examples, so keep the native R engine for binomial
  random effects or structured dependence. A beta-binomial repeated-measures
  model can use `bf(cbind(successes, failures) ~ x + (1 | id), sigma ~ z)`.
  Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Continuous proportions with structural exact 0 or 1 values.** Use
  `zero_one_beta()` with fixed-effect `mu`, `sigma`, `zoi`, and `coi`
  formulas. Here `zoi` is the probability of an exact boundary outcome and
  `coi` is the probability that a boundary outcome is exactly 1. Ordinary
  unlabelled `mu` random intercepts and independent numeric slopes are
  recovery-grade. Exact ordinary ML point-fit-only atom-side gates also admit
  one `zoi` random intercept, one same-raw-symbol `zoi` slope such as
  `zoi ~ x + (0 + x | id)`, the exact `coi ~ 1 + (1 | id)` random
  intercept, or the same-raw-symbol `coi` slope
  `coi ~ x + (0 + x | id)`; none is profile-ready. Both `coi` routes have
  population-level point-recovery evidence at `M = 64` with 50 observations
  per group. Sparse observed atoms or weak boundary-row predictor spread can
  weaken conditional group modes, so inspect both before interpreting them.
  Exact q1 structured-intercept gates also have point-recovery evidence for
  `mu` and `sigma` under `phylo()`, `animal()`, `relmat()`, `spatial()`, and
  `phylo_interaction()`, and for selected `zoi` and `coi` provider cells. The
  `sigma`-`relmat()` and `sigma`-`spatial()` profile targets are
  interval-feasible, not coverage-calibrated. Other atom shapes, transformed
  or mismatched slope symbols, correlated or labelled atom effects, remaining
  structured atom-provider combinations, structured slopes or q2-plus blocks,
  denominator syntax, and bivariate bounded responses remain planned or
  blocked. Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Overdispersed, zero-heavy, truncated, or hurdle counts.** Use
  `poisson()`, `nbinom2()`, `truncated_nbinom2()`, `zi ~`, or `hu ~`.
  Ordinary Poisson and NB2 `mu` random intercepts and independent numeric
  random slopes such as `bf(count ~ x + (1 | id) + (0 + x | id))` are the first
  non-Gaussian random-effect slices. Ordinary Poisson and NB2 also have q=1
  structured `mu` intercept slices, such as
  `bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z)` or
  `bf(count ~ x + spatial(1 | site, coords = coords), sigma ~ z)` for NB2,
  or `bf(count ~ x + phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree), sigma ~ z)`
  for two partner phylogenies, when exactly one structured effect belongs on
  the log-mean scale. Ordinary NB2 also fits the first grouped overdispersion
  slice, `bf(count ~ x, sigma ~ z + (1 | id))`; the Q-Series v1.0 surface
  also has exact local fit-only gates for a scalar labelled spatial count tag,
  `bf(count ~ x + spatial(1 | p | site, coords = coords))`, and a hurdle
  route, `bf(count ~ x, sigma ~ 1, hu ~ relmat(1 | id, Q = Q))`.
  Two fixed-zero-inflation spatial-`mu` routes are also exact diagnostic-only
  gates: Poisson with
  `bf(count ~ x + spatial(1 | site, coords = coords), zi ~ 1)` and NB2 with
  `bf(count ~ x + spatial(1 | site, coords = coords), sigma ~ 1, zi ~ 1)`.
  These two gates keep zero inflation fixed; they confirm local fit/extractor
  feasibility but do not establish point-estimate recovery, intervals, or
  coverage.
  A simultaneous two-provider NB2 count `mu` route,
  `bf(count ~ x + spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q))`,
  now builds and surfaces both structured fields on a crossed `site x id`
  design as recovery-only evidence: both fixed-covariance variance components
  recover with a positive-definite Hessian on the crossed ladder, joint
  identifiability rests on the crossed design (a non-crossed control confounds
  the two fields), and intervals and coverage remain unsupported. This is a
  row-accounting recovery capability, not a broader support claim.
  Correlated ordinary count slope blocks, zero-inflation random effects outside
  the exact Poisson q=1 spatial-`zi` gate, fixed-`zi` spatial-`mu` routes beyond
  the exact diagnostic-only Poisson and NB2 intercept gates, pure,
  multiple, or labelled structured count slopes, labelled q=2/q=4 count
  covariance, plain NB2 `sigma` slopes, structured `sigma` routes beyond the
  exact q=1 intercept-plus-one-slope gate, richer hurdle structured effects,
  and other simultaneous structured count routes remain planned.
  Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Ordered categories.** Use `cumulative_logit()` for cumulative-logit
  ordinal regression with ordered cutpoints and a fixed latent logistic scale.
  Ordinary unlabelled `mu` random intercepts and independent numeric slopes
  are recovery-grade. The Q-Series v1.0 surface also has one narrow local-fit
  gate for `phylo(1 | species, tree = tree)` in `mu`; other structured ordinal
  effects and scale/discrimination formulas remain planned. Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Two Gaussian responses with changing residual correlation.** Use bivariate
  Gaussian location-coscale regression with `mu1`, `mu2`, `sigma1`,
  `sigma2`, and `rho12`. Matching labelled random intercepts in `mu1` and
  `mu2`, such as `(1 | p | id)` in both formulas, fit the first bivariate
  group-level covariance block; matching location slope blocks such as
  `(0 + x | p | id)` or `(1 + x | p | id)` in both formulas fit the first
  slope-only and Q4 location slices. Read
  [Changing residual coupling with `rho12`](https://itchyshin.github.io/drmTMB/articles/bivariate-coscale.html).
- **Known sampling variance or covariance.** Use Gaussian meta-analysis with
  `meta_V(V = V)`; deprecated `meta_known_V(V = V)` remains supported only as a
  compatibility alias. Read
  [Mean effects and residual heterogeneity](https://itchyshin.github.io/drmTMB/articles/meta-analysis.html).
- **Structured Gaussian effects.** Use ordinary random effects,
  residual-scale random intercepts or independent random slopes in `sigma`,
  `sd(group) ~ x`, and fitted Gaussian structured routes for `phylo()`,
  `spatial()`, `animal()`, and `relmat()`. For Gaussian structured effects,
  those markers fit documented `mu` and `sigma` intercept routes, one numeric
  `mu` slope, q=2 bivariate mean-mean intercept and slope-only blocks, and
  constant q=4 location-scale blocks where marked. Artifact routing is narrower
  than fitted syntax:
  `phylo_mu_slope`, `spatial_mu_slope`, `animal_mu_slope`, and
  `relmat_mu_slope` are manual opt-in Actions tasks, excluded from
  `task = "all"`, and do not by themselves establish recovery, coverage, or
  power. Read
  [Phylogenetic and spatial structured effects](https://itchyshin.github.io/drmTMB/articles/phylogenetic-spatial.html).

For strict `(0, 1)` Beta responses, one narrower phylogenetic exception has
point-fit recovery evidence: an unlabelled q1 intercept-only `phylo()` effect in
`mu`, with fixed-effect family `sigma`. Recovery passed only in the exact tested
`g = 1024, m = 4` cell; `g = 256` and `g = 512` remain HOLD, and this is not a
claim about every `g >= 1024`. Here family `sigma` controls
`phi = sigma^(-2)` and is distinct from the latent phylogenetic location-effect
SD. Phylogeny in family `sigma`, phylogenetic slopes or labels, direct
latent-`sd()` regression, REML, intervals, and coverage remain unsupported.

## What can I fit today?

Start with the smallest model that answers your scientific question. The links
below lead to complete worked examples; the detailed technical limits belong
in those guides, not on this landing page.

For a full list of supported routes and their boundaries, use the linked model
map rather than treating a long status table as a tutorial.
| Surface | Current status | Interval and diagnostic status | Main boundary |
| --- | --- | --- | --- |
| One-response families | Start with the documented family examples | Use the response-family guide before adding random or structured effects |
| Gaussian random effects | Established starting point for repeated measurements | Use the relevant model guide for random slopes and uncertainty |
| Random-effect scale models | Available for the documented Gaussian examples | Do not infer support for every scale model |
| Known sampling covariance | Gaussian meta-analysis route | See the meta-analysis guide for supported inputs |
| Missing data | Limited, documented workflows | This is not a general missing-data framework |
| Bivariate Gaussian residual correlation | Documented two-response Gaussian route | Residual correlation is not group or spatial correlation |
| Ordinary bivariate covariance | Limited documented models | Use the bivariate guide before adding covariance terms |
| Phylogenetic structured effects | Begin with a documented Gaussian example | Other family and inference combinations need separate support |
| Coordinate spatial effects | Begin with a documented Gaussian example | Do not extend the example by analogy |
| Animal and relatedness effects | Begin with a documented Gaussian example | Complex covariance structures need separate support |
| Intervals and diagnostics | Available for documented targets | Inspect diagnostics before interpreting uncertainty |
| Large-data controls | Available for documented Gaussian workflows | They are not a general performance guarantee |
| Planned neighbours | Not ready for applied use | Use a simpler documented model or another package |

## Current boundaries
`drmTMB` supports one-response and two-response models. For a first analysis,
use the examples linked above. Gaussian models are the best established starting
point for random effects and structured dependence.
The package deliberately does not treat a model that happens to fit as proof
that its uncertainty is reliable. In particular, do not assume that a family
example extends automatically to multiple random effects, a new structured
source, missing data, or a different interval method. The
[capability-and-limits guide](https://itchyshin.github.io/drmTMB/articles/capability-and-limits.html)
is the decision page for those cases.
Residual `rho12` describes correlation between the two responses within an
observation. It is different from correlation between groups, species, or
locations. Use the [model map](https://itchyshin.github.io/drmTMB/articles/model-map.html)
when your question involves more than one kind of dependence.
Use maximum likelihood (the default) to compare models with different fixed
effects. Restricted likelihood is primarily for the documented Gaussian
workflows. Always inspect `check_drm()` and the interval output before
reporting a complex model.
## Project status

The package is under active development. See
[Can I fit and report this model?](https://itchyshin.github.io/drmTMB/articles/capability-and-limits.html), the
[reference index](https://itchyshin.github.io/drmTMB/reference/index.html), and
the articles above for the current fitted workflows.
