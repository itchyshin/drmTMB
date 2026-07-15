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
- Want the current status before choosing syntax? Use
  [What can I fit today?](https://itchyshin.github.io/drmTMB/articles/model-map.html)
  for the user-facing model map and the
  [implementation map](https://itchyshin.github.io/drmTMB/articles/implementation-map.html)
  when you need the fitted-versus-planned ledger. Contributor-facing promotion
  decisions use the
  [finish capability matrix](https://github.com/itchyshin/drmTMB/blob/main/docs/design/168-r-julia-finish-capability-matrix.md),
  and the stricter row wins whenever status ledgers disagree.
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

This site is built from the `0.5.0` development version. The package is still
pre-CRAN and intentionally bounded: use it for the implemented one-response and
two-response workflows listed below, and treat unsupported model classes as
roadmap work rather than hidden features.

The first CRAN release is numbered **0.5.0**, not 1.0 — an honest reflection
that much of the family and inference surface is still scaffolded or
recovery-grade. "v1.0" throughout the dev-log denotes the later
complete-capability maturity milestone. The contributor-facing
[Q-Series release status](https://github.com/itchyshin/drmTMB/blob/main/docs/dev-log/release-audits/q-series-v1-release-status.md)
ledger tracks that milestone: it separates implemented/basic-working Gaussian
structured-effect rows and basic-distribution recovery rows from post-v1.0
`inference_ready` and `supported` validation. It is a release-planning ledger,
not a broader support claim.

## Install

`drmTMB` is not on CRAN yet. Install the tagged `v0.5.0` release from GitHub
with `pak`:

```r
install.packages("pak")
pak::pak("itchyshin/drmTMB@v0.5.0")
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
  binomial sampling variation is enough. Ordinary `mu` random intercepts and
  independent numeric slopes are fitted first slices; only the exact
  independent-slope design recorded in the capability ledger has
  `inference_ready_with_caveats` coverage evidence. Use `beta_binomial()` with
  `cbind(successes, failures)` when the data need extra-binomial variation
  through `sigma`. Correlated or labelled binomial random slopes, structured
  effects, `sigma` formulas, bivariate or mixed responses, and non-phylogenetic
  `engine = "julia"` binomial fits remain unsupported. Ordinary
  repeated-measure beta-binomial random intercepts in `mu` are fitted as a
  first slice with syntax such as
  `bf(cbind(successes, failures) ~ x + (1 | id), sigma ~ z)`.
  Read
  [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
- **Continuous proportions with structural exact 0 or 1 values.** Use
  `zero_one_beta()` with fixed-effect `mu`, `sigma`, `zoi`, and `coi`
  formulas. Here `zoi` is the probability of an exact boundary outcome and
  `coi` is the probability that a boundary outcome is exactly 1. Ordinary
  unlabelled `mu` random intercepts and independent numeric slopes are
  recovery-grade. Correlated or labelled `mu` slopes, `sigma`/`zoi`/`coi`
  random effects, denominator syntax, structured effects, and bivariate
  bounded responses remain planned or blocked. Read
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

Every fitted univariate family now has an ordinary `mu` random intercept and
an independent numeric `mu` slope at recovery grade. Thus, in the compact row
below, “Tweedie random effects”, “skew-normal random effects”, and “ordinal
random effects” in the boundary column mean richer, correlated, labelled,
scale/shape, or structured neighbours beyond those ordinary `mu` gates. The
exact row-specific structured exceptions retain their named diagnostic-only or
point/recovery tier; none implies interval or coverage promotion.

| Surface | Current status | Interval and diagnostic status | Main boundary |
| --- | --- | --- | --- |
| One-response families | Stable for Gaussian, Student-t, lognormal, Gamma, Tweedie, beta, zero-one beta, beta-binomial, Poisson, NB2, truncated NB2, hurdle NB2, zero-inflated Poisson, zero-inflated NB2, and cumulative-logit ordinal location; skew-normal fits fixed-effect residual asymmetry plus ordinary recovery-grade `mu` random intercepts and independent numeric slopes; binomial has fixed effects plus ordinary `mu` random intercepts and independent numeric slopes as fitted first slices; ordinary Poisson and NB2 `mu` random intercepts and independent numeric slopes are the first count random-effect slices; ordinary Student-t, skew-normal, zero-truncated NB2, lognormal, Gamma, Tweedie, beta, zero-one beta, beta-binomial, and cumulative-logit `mu` random intercepts and independent numeric slopes have focused recovery evidence; ordinary NB2, lognormal, and Gamma now have first log-`sigma` random-intercept slices; ordinary Poisson/NB2 now have q=1 structured `mu` intercept first slices for `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, and `relmat()`; ordinary Poisson/NB2 now have unlabelled q=1 structured `mu` one-slope point-fit/extractor cells for `phylo()`, `spatial()`, `animal()`, and `relmat()`; exact q=1 NB2 structured `sigma` intercept-plus-one-slope routes for those four providers are fitted at recovery grade; the Q-Series v1.0 surface includes diagnostic-only single-smoke cells for cumulative-logit ordinal `mu ~ phylo(1 | id, tree = tree)`, truncated-NB2 hurdle `hu ~ relmat(1 | id, Q = Q)`, zero-inflated Poisson `zi ~ spatial(1 | id, coords = coords)`, zero-inflated Poisson fixed-`zi` `mu ~ spatial(1 | id, coords = coords)`, Student-t `nu ~ phylo(1 | id, tree = tree)`, Student-t intercept-only `mu ~ spatial(1 | id, coords = coords)`, Poisson slope-only `mu ~ spatial(0 + x | site, coords = coords)`, Poisson labelled-scalar `mu ~ spatial(1 | p | site, coords = coords)`, Poisson `mu ~ spatial(1 | site, coords = coords) + (1 | id)`, and zero-inflated NB2 fixed-`zi` `mu ~ spatial(1 | id, coords = coords)`; and non-count structured recovery cells for Arc 3a Gamma `phylo(1 | id, tree = tree)`, lognormal `phylo(1 | id, tree = tree)`/`relmat(1 | id, K/Q = ...)`, Gamma `relmat(1 + x | id, K = K)`, Student-t `spatial(1 + x | id, coords = coords)`, and beta `animal(1 + x | id, pedigree = ped)` | Wald fixed-effect intervals by default; explicit direct profile targets are listed by `profile_targets()`; binomial and Tweedie fixed-effect coefficients use the fixed-effect interval path; skew-normal fixed-effect coefficients have interval output, but slant `nu` and tail-stress inference remain diagnostic when `check_drm()`, Hessian, or fixed-gradient warnings appear; ordinary Poisson, NB2, Student-t, zero-truncated NB2, lognormal, Gamma, beta, and beta-binomial `mu` random-effect SDs are direct `log_sd_mu` profile targets; the bounded-response, positive-continuous, Student-t, and zero-truncated NB2 artifact lanes record fixed-effect Wald rows and direct-SD profile rows for ordinary `(1 | id)` in `mu`; independent selected non-Gaussian `mu` slopes have CRAN-safe smoke recovery checks; NB2, lognormal, and Gamma ordinary `sigma` random-intercept SDs are direct `log_sd_sigma` targets; Poisson/NB2 structured SDs are direct `log_sd_phylo` profile targets; the exact q=1 NB2 structured `sigma` routes remain recovery-only, with intervals and coverage planned; the named ordinal, hurdle, spatial-inflation, Student-t intercept/shape, and Poisson slope-only, labelled-scalar, and structured-plus-ordinary rows are diagnostic-only, while the exact Gamma, Student-t slope, and beta routes retain recovery evidence; all row-specific exceptions have intervals unsupported and no coverage promotion | Random effects are otherwise mostly Gaussian-only; correlated or labelled binomial slopes, binomial structured effects, Tweedie random effects outside the ordinary unlabelled `mu` gates, predictor-dependent Tweedie `nu`, skew-normal random effects outside the ordinary unlabelled `mu` gates, non-Gaussian `sigma` random effects outside the ordinary NB2, lognormal, and Gamma intercept gates and the exact q=1 NB2 structured recovery routes, correlated bounded-response, positive-continuous, Student-t, and zero-truncated NB2 random slopes, Student-t `nu` random effects outside the exact row-specific `nu ~ phylo(1 | id, tree = tree)` local-fit gate, ordinal random effects outside the ordinary unlabelled `mu` intercept/slope recovery gate and the exact row-specific `mu ~ phylo(1 | id, tree = tree)` local-fit gate, correlated count slopes, zero-inflated count random effects outside the exact row-specific Poisson `zi ~ spatial(1 | id, coords = coords)`, Poisson fixed-`zi` spatial `mu`, and NB2 fixed-`zi` spatial `mu` gates, hurdle random effects outside the exact row-specific truncated-NB2 `hu ~ relmat(1 | id, Q = Q)` local-fit gate, pure, multiple, or labelled structured count slopes, richer or labelled NB2 structured `sigma`, structured-sigma intervals/coverage, labelled q2/q4 count covariance, simultaneous count structured effects beyond the admitted two-provider NB2 `mu` recovery cell, non-count structured `mu` slopes beyond the admitted Gamma/Student-t/beta one-slope recovery cells, ordinal scale/discrimination formulas, zero-one-beta random effects outside the ordinary unlabelled `mu` gates, other shape or inflation random effects, and bivariate bounded-response families remain planned |
| Gaussian ordinary random effects | Stable for `mu` intercepts, independent slopes, one-slope correlated blocks, and ordinary q > 2 numeric multi-slope blocks; stable for `sigma` intercepts, independent slopes, and unlabelled correlated intercept-slope or multi-slope blocks on log-`sigma`; `REML = TRUE` fits the first ordinary univariate Gaussian mixed-model slice for dense `mu` fixed effects, ordinary `mu` random intercepts or slopes, diagonal or dense known sampling covariance through `meta_V(V = V)`, predictor-dependent (heteroscedastic) `sigma`, and ordinary `sigma` random intercepts, independent or correlated slopes, and matched mean-scale `(1 | p | id)` blocks | `check_drm()` reports replication, weak-slope, boundary, and Hessian diagnostics; q=3 recovery and q=4 output-contract checks cover the ordinary `mu` multi-slope path; q > 2 `mu` block SDs and ordinary `sigma` slope SDs are direct profile targets, while q > 2 correlations are derived-unavailable for direct profiling; REML random-intercept and correlated random-slope comparators match `lme4::lmer(..., REML = TRUE)`; known-`V` REML estimates match `metafor` and the restricted log likelihood matches a manual full Gaussian calculation | Larger q blocks can be sample-size hungry; REML for missing-data routes, row aggregation, non-phylogenetic mean-side structured effects outside the Arc 1a unlabelled intercept or independent-one-slope `sigma ~ 1` routes, all bivariate non-phylogenetic structured effects, ordinary direct-`sd()` scale formulae, and q > 2 labelled residual-scale covariance blocks remains planned (univariate phylogenetic mean-side, scale-side, and matched q2 REML, all bivariate phylogenetic covariance layouts including dense q4, univariate spatial/animal/relmat scale-side REML, predictor-dependent heteroscedastic `sigma`, ordinary `sigma` random intercepts/slopes/matched blocks, q > 2 labelled location covariance blocks, and phylogenetic direct-SD scale `sd_phylo(...) ~ x` are admitted); labelled univariate residual-scale slope covariance, labelled cross-formula `mu`-`sigma` slope covariance, and coefficient-specific `sd()` slope models remain planned |
| Random-effect scale models | First slice fitted for `sd(group) ~ x_group` on unlabelled Gaussian `mu` random intercepts | Fixed SD-surface coefficients are direct targets; row-specific group SD summaries are derived | Slope-specific `sd(id, dpar = "mu", coef = "x") ~ ...` is reserved and rejected |
| Known sampling covariance | Stable for Gaussian `meta_V(V = V)`, including diagonal, dense, and row-paired bivariate known covariance; deprecated `meta_known_V(V = V)` remains supported only as a compatibility alias; `REML = TRUE` is fitted for univariate Gaussian known-`V` models, including predictor-dependent (heteroscedastic) `sigma` | `check_drm()` reports dense full `V` as a note with dimension, density, size, rank, and conditioning; fixed effects and response-scale residual summaries use the usual interval routes only when Hessian diagnostics are clean. Some `meta_V(V = V)` fits with predictor-dependent `sigma` can return plausible point estimates while reporting `pdHess = FALSE`; treat their Wald SEs and intervals as unreliable until a profile, bootstrap, or simpler `sigma` model supports the target | Dense covariance is small-to-moderate unless sparse or block-sparse evidence is added; full dense known `V` with non-unit likelihood weights is rejected |
| Missing data | Bounded `miss_control()` preview: complete-case dropping remains the default; `response = "include"` is G3 recovery-verified for all 18 fitted response routes, including beta-binomial whole-row masks, ordered-factor cumulative logit, non-hurdle truncated NB2, and the three fixed-effect count mixtures; one `mi()` missing predictor at a time is modelled for the implemented predictor-family catalogue in Gaussian responses, and Poisson/binomial/NB2/beta responses accept one binary `mi()` predictor | Every response-mask route has direct sentinel, observed-row parity, row/extractor, malformed-input, and fixed-seed 25% MCAR recovery evidence. Mixtures additionally separate missing zeros from missing positive counts. Beta-binomial and truncated NB2 include ordinary random-intercept recovery; cumulative logit and the count mixtures are fixed-effect masking slices. Missing-predictor routes retain their focused likelihood tests and `imputed()` summaries | This is not a general missing-data framework. Multiple missing predictors, response plus `mi()`, broader random/structured-route masking claims, EM/profile engines, REML for explicit missing-data routes, simulation-based imputation summaries, response imputation, measurement-error models, and pigauto interoperability remain planned |
| Bivariate Gaussian residual `rho12` | Stable for fixed-effect `mu1`, `mu2`, `sigma1`, `sigma2`, and predictor-dependent residual `rho12` | `rho12()` extracts response-scale residual correlations; row-specific profile intervals use `confint(..., parm = "rho12", newdata = ...)` | Residual `rho12` is not a group-level, phylogenetic, or spatial correlation |
| Ordinary bivariate covariance and `corpairs()` | First slice fitted for matching labelled random intercepts in `mu1`/`mu2`, `sigma1`/`sigma2`, one or more same-response `mu`/`sigma` intercept or slope-only blocks, all-four q=4 intercept blocks, matching slope-only `mu1`/`mu2` blocks, matching q=4 and q=6 `mu1`/`mu2` location blocks with smoke artifact routing, matching slope-only `sigma1`/`sigma2` scale blocks, the first q8 all-endpoint block with matching `(1 + x | p | id)` terms in `mu1`, `mu2`, `sigma1`, and `sigma2`, and q=2 `corpair(..., level = "group") ~ x` | Constant q=2 SD/correlation targets, the slope-slope `mu1`/`mu2` row, the scale-slope `sigma1`/`sigma2` row, and same-response q2 `mu`/`sigma` rows are profile-ready; same-response mean-scale blocks report one row per response-specific label/group pair; predictor-dependent `corpair()` values use `newdata`; q > 2 location-block and q8 endpoint SDs are direct `log_sd_re_cov` targets, while q > 2 unstructured-correlation rows are derived and report unavailable derived intervals | Same-response q2 `mu`/`sigma` slope covariance now has opt-in Phase 18 smoke and recovery artifact writers plus a local 500-replicate diagnostic audit, but the audit held power use because convergence/positive-Hessian rates were 0.856 and 0.884 and all-replicate fixed-effect Wald coverage was 0.796-0.850; a follow-up robust-refit pass did not rescue the 130 weak fits, while interval-available converged fits had fixed-effect Wald coverage of 0.930-0.972 and two clean representative fits produced endpoint profile intervals for `rho12`, both slope SDs, and the same-response correlation; q8 now has opt-in Phase 18 smoke/recovery/staged-diagnostic artifact tasks, and a 2026-06-07 local two-cell audit over 20 replicates per cell wrote diagnostic artifacts with 38/40 completed manifests, model-convergence rates of 0.263 and 0.158, zero positive-Hessian fits, two leading-minor optimization errors, and no usable Wald intervals; q8 coverage and power remain closed; predictor-dependent slope `corpair()` regressions and supportive broad simulation recovery for q > 2 bivariate location or q8 blocks remain planned; the 2026-06-05 q4/q6 formal artifacts are weak evidence, not promotion evidence |
| Phylogenetic structured effects | First slices fitted for Gaussian univariate `mu` and `sigma` intercepts, matching univariate `mu`/`sigma` structured correlations, one numeric `mu` slope, the first sigma-only and matched `mu+sigma` one-slope location-scale cells, bivariate `mu1`/`mu2` intercept and slope-only q=2 blocks, labelled q=4 location-scale blocks, the exact shared-label all-four `phylo(1 + x | p | species, tree = tree)` point-fit/extractor cell, the labelled two-slope `phylo(1 + x + z | p | species, tree = tree)` q=6 `mu1`/`mu2` location and q=12 all-four point-fit/recovery cells, `sd_phylo*()` direct-SD surfaces, q=2 phylogenetic `corpair()` regression, ordinary Poisson/NB2 q=1 `mu` intercept and unlabelled one-slope count cells for `phylo()`, and `phylo_interaction(1 | partner1:partner2, tree1 = tree1, tree2 = tree2)` for one pair-level Kronecker phylogenetic field | Direct phylogenetic SD and constant q=2 correlation targets are profile-ready; predictor-dependent `corpair()` values use `newdata`; full q=4 correlations are derived-only, while block-diagonal q=4 fallback correlations are direct targets but still need fit-specific profile diagnostics; the exact slope-only q=2 `mu1:x`/`mu2:x` phylo SD row is `inference_ready` for intervals and coverage under the default small-sample `confint()` correction; the exact q1 sigma one-slope phylo row is `inference_ready` under the raw uncorrected log-SD Wald-z channel, with near-nominal asymmetric intercept coverage and conservative sigma:x coverage; matched `mu+sigma` and exact all-four one-slope phylo rows otherwise have native point-fit/extractor evidence plus deterministic same-target fixture evidence; the labelled two-slope q=6 `mu1`/`mu2` location and q=12 all-four phylo covariance cells have recovery evidence only, with derived correlations routing through profile/bootstrap and intervals/coverage planned (q=12 recovers a known 66-correlation Sigma with `pdHess=FALSE` by design); the Poisson/NB2 q=1 intercept routes are smoke-level with direct `log_sd_phylo` targets, while the count one-slope cells have point-fit/extractor evidence only | Gaussian multiple phylogenetic slopes beyond the labelled shared-label two-slope q=6 location and q=12 all-four covariance cells, block-diagonal or partial-endpoint two-slope layouts, block-diagonal all-four one-slope structured covariance, pure, multiple, or labelled non-Gaussian phylogenetic count slopes, structured `rho12`, zero-inflated phylogenetic effects, binary/Bernoulli incidence models, additive partner main phylogenies plus `phylo_interaction()`, direct-SD formulas combined with structured `sigma`, broad bridge support beyond deterministic same-target fixtures, `supported` q2 or sigma wording, REML for structured q8 and AI-REML, and predictor-dependent q=4 correlations remain planned or blocked until miss asymmetry and g-dependence are solved |
| Coordinate spatial structured effects | First slices fitted for Gaussian `mu` and `sigma`: `spatial(1 | site, coords = coords)` can enter univariate location, residual scale, or matching location-scale blocks; one numeric `spatial(1 + x | site, coords = coords)` slope is fitted for univariate `mu`, sigma-only residual scale, and matched `mu+sigma` location-scale cells; matching bivariate `mu1`/`mu2` intercept and slope-only q=2 blocks, all-four q=4 spatial intercept blocks, the exact shared-label fixed-covariance all-four `spatial(1 + x | p | site, coords = coords)` point-fit/extractor cell, and the labelled two-slope `spatial(1 + x + z | p | site, coords = coords)` q=6 `mu1`/`mu2` location and q=12 all-four point-fit/recovery cells are fitted. Ordinary Poisson/NB2 also fit q=1 `spatial(1 | site, coords = coords)` and unlabelled `spatial(1 + x | site, coords = coords)` in `mu` on the log-mean scale, plus three row-specific diagnostic-only spatial-inflation gates: Poisson `zi ~ spatial(1 | ...)`, fixed-`zi` Poisson `mu ~ spatial(1 | ...)`, and fixed-`zi` NB2 `mu ~ spatial(1 | ...)`. Three additional Poisson spatial `mu` variants are diagnostic-only: slope-only `spatial(0 + x | ...)`, scalar-labelled `spatial(1 | p | ...)`, and `spatial(1 | ...)` combined with an ordinary `(1 | id)` random intercept. | `sdpars$mu`, `sdpars$sigma`, `ranef("spatial_mu")`, `ranef("spatial_sigma")`, `profile_targets()`, `check_drm()`, `corpairs(level = "spatial")`, and `summary()$covariance` expose the coordinate fields, the univariate mean-scale row, the sigma-only and matched one-slope rows, the q=2 spatial mean-mean intercept and slope-only rows, the six derived q=4 spatial intercept rows, and the exact all-four one-slope q8-shaped spatial row; sigma-only, matched one-slope, slope-only q=2, and exact all-four one-slope spatial rows have deterministic fixed-covariance same-target fixture evidence; the labelled two-slope q=6 `mu1`/`mu2` location and q=12 all-four spatial covariance cells have recovery evidence only, with derived correlations routing through profile/bootstrap and intervals/coverage planned; count one-slope spatial rows retain their recorded tier, while all six named Poisson/NB2 spatial diagnostic variants are single-smoke diagnostic-only | Mesh/SPDE, range-estimating spatial support, multiple spatial slopes beyond the labelled shared-label two-slope q=6 location and q=12 all-four covariance cells, block-diagonal or partial-endpoint two-slope layouts, block-diagonal or broader intercept-plus-slope spatial covariance, direct-SD surfaces, spatial `corpair()` regression, pure, multiple, or labelled count spatial slopes, labelled count covariance, zero-inflated spatial effects outside the exact Poisson spatial `zi`, Poisson fixed-`zi` spatial `mu`, and NB2 fixed-`zi` spatial `mu` local-fit gates, broad bridge support beyond deterministic same-target fixtures and AI-REML remain planned; mean-side REML outside the pure-`mu`, unlabelled intercept or independent-one-slope `sigma ~ 1` Arc 1a routes remains planned (those routes have discrete-domain recovery and endpoint-profile evidence; univariate scale-side `sigma ~ spatial(...)` REML is also admitted) |
| Animal and lower-level relatedness structured effects | Gaussian `mu` and `sigma` intercepts are fitted for `animal(1 | id, pedigree/A/Ainv = ...)` and `relmat(1 | id, K/Q = ...)`; one numeric `mu`, sigma-only, and matched `mu+sigma` slope cells are fitted for A-matrix `animal()` and K/Q `relmat()` routes; matching labelled `mu1`/`mu2` intercept or slope-only terms fit q=2 bivariate location covariance, matching all-four intercept terms fit constant q=4 location-scale covariance, the exact shared-label A-matrix animal and K/Q relmat all-four one-slope cells fit as q8-shaped point/extractor cells, and the labelled two-slope `animal(1 + x + z | p | id, ...)` and `relmat(1 + x + z | p | id, ...)` q=6 `mu1`/`mu2` location and q=12 all-four cells fit as point-fit/recovery cells. Ordinary Poisson/NB2 also fit q=1 `animal()` and `relmat()` `mu` intercept and unlabelled one-slope terms on the log-mean scale. | `sdpars$mu`, `sdpars$sigma`, `corpars$animal` / `corpars$relmat`, `ranef("animal_mu")`, `ranef("animal_sigma")`, `ranef("relmat_mu")`, `ranef("relmat_sigma")`, `corpairs()`, `summary()$covariance`, `profile_targets()`, and `check_drm()` expose the fitted structured fields; q=4/q8-shaped correlations are derived-only; the exact relmat slope-only q=2 `mu1:x`/`mu2:x` SD row is `inference_ready` for intervals and coverage under the default small-sample `confint()` correction; the exact q1 animal A-matrix and relmat K/Q sigma one-slope rows are `inference_ready` under the raw uncorrected log-SD Wald-z channel, with asymmetric one-sided misses and conservative sigma:x coverage; animal q2, matched one-slope, and exact all-four one-slope animal/relmat rows otherwise have native point-fit/extractor evidence plus deterministic same-target fixture evidence; the labelled two-slope q=6 `mu1`/`mu2` location and q=12 all-four animal/relmat covariance cells have recovery evidence only, with derived correlations routing through profile/bootstrap and intervals/coverage planned; count one-slope animal/relmat rows have point-fit/extractor evidence only | Large-pedigree sparse precision construction, multiple structured slopes beyond the labelled shared-label two-slope q=6 location and q=12 all-four covariance cells, broader intercept-plus-slope structured covariance beyond the exact shared-label all-four one-slope and two-slope cells, block-diagonal or partial-endpoint two-slope layouts, predictor-dependent `corpair()` regressions, pure, multiple, or labelled animal/`relmat()` count slopes, generic direct-SD grammar, broad bridge support beyond deterministic same-target fixtures, animal q2 interval promotion, q2 or sigma `supported`, and neighbouring intervals or coverage remain planned or blocked; mean-side REML outside the pure-`mu`, unlabelled intercept or independent-one-slope `sigma ~ 1` Arc 1a routes remains planned (those routes have discrete-domain recovery and endpoint-profile evidence; univariate scale-side `sigma ~ animal(...)`/`relmat(...)` REML is also admitted) |
| Profile intervals and diagnostics | First slice for fixed effects, direct SD/correlation targets, row-specific `sigma`, `sigma1`, `sigma2`, `rho12`, fitted q=2 `corpair()` values, and `confint(..., method = "bootstrap")` simulate/refit intervals for direct targets | `confint()` defaults to fast direct Wald intervals when `sdreport()` is available; SD Wald intervals use the log-SD scale, correlation Wald intervals use a guarded Fisher-z/atanh scale, and location-axis structured SD targets use a default t(g - 1) width plus simulation-calibrated `log(g/(g - 1))` centre shift; `profile_precision = "fast"` gives a quicker first-pass profile, `profile_maxit` caps each `TMB::tmbprofile()` target, `parallel = "multicore"` can split profile or bootstrap refits on Unix, and interval output uses `conf.status`, `profile.boundary`, `profile.message`, and bootstrap success/failure counts | Profile and bootstrap support is target-specific; derived q=4 rows report `derived_interval_unavailable`; the default location-axis small-sample correction promotes five rows to `inference_ready`: phylo, spatial, and relmat q1 `mu:(Intercept)`, plus phylo and relmat q2 `mu1:x`/`mu2:x` slope SDs; phylo, animal, and relmat q1 sigma one-slope rows are separately `inference_ready` under raw uncorrected log-SD Wald-z intervals, with profile diagnostic-only at g=8; `supported` is withheld because miss asymmetry, overcoverage, and g-dependence remain measured defects |
| Large-data fit controls | Opt-in controls for memory-light fitted objects, sparse fixed-effect `mu` matrices, and Gaussian sufficient-statistic aggregation | `check_drm()` reports sparse design and aggregation diagnostics where fitted | These controls are first univariate Gaussian paths, not broad scalability claims |
| Reserved or planned neighbours | Reserved/rejected or design-only for coefficient-specific `sd()` slopes, random effects in `rho12`, shape random effects beyond the row-specific Student-t phylo `nu` local-fit gate, inflation random effects beyond the row-specific Poisson spatial `zi` local-fit gate, ID-level skewness such as future `skew(id) ~ x`, multiple phylogenetic slopes beyond the labelled shared-label two-slope q=6 location and q=12 all-four covariance cells, non-Gaussian phylogenetic slopes outside the exact unlabelled Poisson/NB2 q1 intercept-plus-one-slope gates, phylogenetic slope correlations, mesh/SPDE, spatial `corpair()`, residual-scale or location-scale endpoint bivariate slope covariance beyond the labelled shared-label q=6 location and q=8/q=12 all-four cells, and mixed composed families | Planned-feature errors should fire before fitting; no interval target is advertised | These need likelihood code, recovery tests, diagnostics, documentation, and after-task evidence before use |

## Current boundaries

`drmTMB` currently supports one-response and two-response models. Higher
dimensional multivariate models belong in a different tool.

Random effects are strongest in the Gaussian routes. Every fitted univariate
non-Gaussian family has an ordinary recovery-grade `mu` random intercept and
independent numeric slope: Student-t, skew-normal, lognormal, Gamma, Tweedie,
beta, zero-one beta, beta-binomial, binomial, Poisson, NB2, zero-truncated NB2,
and cumulative logit. Beyond that universal ordinary gate, the mixed surface
is deliberately small: ordinary
Poisson/NB2 q=1 structured `mu` intercept-plus-one-slope routes are fitted for
`phylo()`, `spatial()`, `animal()`, and `relmat()`. The beta/beta-binomial,
lognormal/Gamma, Student-t, and zero-truncated NB2 ordinary `mu` random
intercepts have small Phase 18 artifact lanes, while their independent numeric
`mu` slopes have focused source tests; neither path is a broad bounded-response,
positive-continuous, Student-t, or count random-effect claim.
Ordinary NB2, lognormal, and Gamma also have first grouped dispersion paths in
`sigma`, limited to independent random intercepts on the log-`sigma` scale;
ordinary NB2 separately has recovery-grade q=1 structured `sigma`
intercept-plus-one-slope routes for the same four providers.
Only the exact lognormal Arc 4a domain (true SD 0.4, `n_each=12`, and
`M={16,32,64}`) has coverage-backed `inference_ready_with_caveats` evidence;
Gamma remains point-recovery only. Most other
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
random-intercept correlations, bivariate labelled `sigma1`/`sigma2`
scale-slope correlations from matching `(0 + x | p | id)` terms, and one or
more same-response bivariate `mu`/`sigma` correlations such as `mu1` with
`sigma1` using label `p` and `mu2` with `sigma2` using label `q`; these
same-response pairs can now be intercept-only or matching slope-only terms such
as `(0 + x | p | id)`.

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

For phylogenetic location-scale models, read "balanced" row by row. Native ML
has fitted univariate Gaussian `mu`, `sigma`, and matched `mu+sigma`
intercept cells, plus diagnostic q4 location-scale cells. Native REML now
admits univariate phylogenetic `mu` mean-side, `sigma` scale-side, and the
matched q2 mean-and-scale block, plus bivariate phylogenetic structured
effects in every covariance layout, including the dense (unstructured) q4
location-scale block, subject to sample-size requirements; AI-REML and REML
for the labelled two-slope q8-shaped cell remain rejected. Direct DRM.jl q4
profile/bootstrap machinery is separate from the R bridge and does not by
itself establish calibrated Ayumi-scale intervals.

Spatial syntax is part of the structured-effect design. The fitted coordinate
path supports univariate Gaussian `mu` and `sigma` intercepts with
`spatial(1 | site, coords = coords)`, one numeric `mu` slope with
`spatial(1 + x | site, coords = coords)`, first sigma-only and matched
`mu+sigma` one-slope native point-fit/extractor cells for the same fixed
coordinate covariance route, q=2 `mu1`/`mu2` location covariance, and constant
q=4 location-scale blocks from matching all-four labelled spatial terms. The
fitted spatial SDs appear in `sdpars$mu`/`sdpars$sigma`,
conditional effects in `ranef("spatial_mu")` and `ranef("spatial_sigma")`,
direct SD and correlation targets in `profile_targets()`, and the q=2
mean-mean row in `corpairs(level = "spatial")` and
`summary()$covariance`. Mesh/SPDE fields, multiple spatial slopes,
block-diagonal or broader intercept-plus-slope spatial covariance, broad bridge/inference beyond
deterministic same-target fixtures,
spatial slope correlations, direct spatial SD surfaces, predictor-dependent
spatial `corpair()` regression, and non-Gaussian spatial effects outside the
exact ordinary Poisson/NB2 q1 spatial `mu` intercept-plus-one-slope,
recovery-grade NB2 q1 spatial `sigma`, Student-t spatial `mu`, Poisson spatial
`zi`, fixed-`zi` Poisson spatial `mu`, and fixed-`zi` NB2 spatial `mu` gates are still planned rather than
landing-page workflows.

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
