# Distribution Roadmap

This roadmap orders response families by scientific value, implementation risk,
and how well they support the identity of `drmTMB`.

## Tier 1: Continuous MVP

These establish the formula parser, family registry, TMB pipeline, prediction,
simulation, and recovery tests.

- `gaussian()`: `mu`, `sigma`.
- `student()`: `mu`, `sigma`, `nu`; fixed-effect univariate path and ordinary
  unlabelled `mu` random intercepts plus independent numeric slopes
  implemented.
- `lognormal()`: `mu`, `sigma` on the log response scale; fixed-effect
  univariate path and ordinary unlabelled `mu` random intercepts plus
  independent numeric slopes implemented for positive responses.
- `Gamma(link = "log")`: `mu`, `sigma` as coefficient of variation;
  fixed-effect univariate path and ordinary unlabelled `mu` random intercepts
  plus independent numeric slopes implemented for positive responses.
- `beta()`: `mu`, `sigma` for strict continuous proportions; fixed-effect
  univariate path and ordinary unlabelled `mu` random intercepts plus
  independent numeric slopes implemented with `phi = 1 / sigma^2` internally.

## Tier 2: Bivariate Coscale

These are the package-defining families.

- `c(gaussian(), gaussian())`: public direction for `mu1`, `mu2`,
  `sigma1`, `sigma2`, and `rho12`.
- `biv_gaussian()`: retained helper for the implemented all-Gaussian
  fixed-effect model.
- `c(student(), student())`: later robust bivariate model with `nu`.
- `c(gaussian(), poisson())` and other mixed ecological responses: later only
  after the joint likelihood and meaning of `rho12` are designed.

`rho12 ~ predictors` is the signature feature and is now implemented for the
Gaussian fixed-effect path. It should be hardened before the package grows a
large family list. This is the key extension of phylogenetic location-scale
thinking: after modelling trait means and variances, `drmTMB` lets users ask
whether the covariance or correlation itself changes with biology,
environment, lineage, treatment, or lifestyle.

## Tier 3: Meta-Analytic Gaussian Regression

Meta-analysis is treated as Gaussian regression with known sampling covariance,
not as a separate family. The syntax uses `family = gaussian()` plus a known
covariance marker:

```r
bf(
  yi ~ x1 + x2 + meta_V(V = V),
  sigma ~ x1
)
```

The current implementation supports a column/vector of known sampling
variances, a diagonal matrix, a dense block-diagonal matrix, or a dense full
covariance matrix. Sparse covariance storage is planned later. In meta-analysis
language, `sigma` is the extra heterogeneity SD traditionally called `tau`.

Important extensions:

- location-scale meta-regression for heterogeneous heterogeneity;
- robust Student-t residuals after Gaussian meta-analysis is stable;
- bivariate meta-analysis with known within-study covariance, where
  `meta_V(V = V)` supplies sampling covariance and fitted `rho12`
  remains the residual covariance component after known sampling covariance has
  been included;
- `meta_vcov_bivariate()` now constructs bivariate row-paired dense sampling
  covariance matrices from `v1`, `v2`, and either `cov12` or `cor12`;
  complete-row bivariate Gaussian models can fit with this known `V`;
- sensitivity workflows for unknown within-study correlations;
- multiple unknown variance components when study, species, lab, or effect-size
  type require them.

## Tier 4: Counts

Counts need location-scale thinking because dispersion is often biological.
They also require the family-link contract in
`docs/design/19-family-link-contract.md`, because `mu` should use a log link
rather than the identity-link behaviour used by the first Gaussian-like
families.

- `poisson(link = "log")`: `mu`, with optional `zi`; implemented with fixed
  effects plus ordinary unlabelled `mu` random intercepts, independent numeric
  slopes, and one q1 structured `mu` intercept or unlabelled intercept-plus-one-
  slope route from the exact admitted provider set when `zi` is absent. The
  exact `zi ~ spatial(1 | id, coords = coords)` q1 intercept is a separate
  diagnostic-only gate; other zero-inflated Poisson random effects remain
  blocked. The `mu` formula supports standard R exposure offsets such as
  `offset(log(trap_nights))`. The `mu` parameter is the conditional Poisson
  mean when `zi` is present.
- `nbinom2()`: `mu`, `sigma`; implemented path with
  `Var(y) = mu + sigma^2 * mu^2`, so larger `sigma` means greater
  overdispersion. The `mu` formula supports standard R exposure offsets such as
  `offset(log(trap_nights))`, ordinary random intercepts, and independent
  numeric random slopes for non-zero-inflated NB2 models. It also admits one q1
  structured `mu` intercept or unlabelled intercept-plus-one-slope route, the
  first ordinary `sigma` random intercept, and exact q1 structured `sigma`
  recovery gates. Adding `zi ~ predictors` fits zero-inflated NB2; one exact
  fixed-`zi` local-fit gate admits `mu ~ spatial(1 | id, coords = coords)`, while
  other zero-inflated NB2 random effects remain blocked.
- `truncated_nbinom2()`: `mu`, `sigma`; implemented zero-truncated NB2 path for
  positive counts. The parameters describe the
  untruncated NB2 component, and `fitted()` returns the conditional
  positive-count mean. Ordinary `mu` random intercepts and independent numeric
  slopes are implemented for the non-hurdle path. Adding `hu ~ predictors`
  fits hurdle NB2, where `hu` is the hurdle-zero probability and nonzero counts
  come from the zero-truncated NB2 component. The exact
  `hu ~ relmat(1 | id, K/Q = ...)` q1 intercept is diagnostic-only; other
  hurdle-side and count-side random effects remain blocked when `hu` is active.
- `truncated_poisson()` for positive counts without overdispersion.
- hurdle Poisson models, using `hu ~ predictors` as the hurdle-zero
  probability on a future truncated Poisson family.
- `compois()`: `mu`, `nu`; handles underdispersion and overdispersion.
- `genpois()`: `mu`, `sigma` or family-specific `nu`; useful alternative for
  count dispersion.
- `nbinom1()`: `mu`, `sigma` or family-specific `nu`; variance increases
  linearly with the mean.

Priority order after the Poisson, zero-inflated Poisson, NB2,
zero-inflated NB2, zero-truncated NB2, and hurdle NB2 seeds:

1. add `truncated_poisson()` and hurdle Poisson if examples show they are useful
   beyond NB2;
2. add univariate ordinal models with an explicit cutpoint contract;
3. defer `compois()` and `genpois()` until the mean/dispersion contract and
   comparator strategy are designed.

The implemented NB2 hurdle grammar keeps the response family focused on the
positive count component and uses `hu ~ predictors` for the hurdle component,
parallel to the current `zi ~ predictors` route. Do not add separate
`hurdle_nbinom2()` or `hurdle_poisson()` public constructors without a design
decision.

## Tier 5: Proportions, Percentages, and Bounded Continuous Responses

Percent data should be represented according to how the data were generated.
Continuous proportions require a logit-linked `mu`; public scale naming should
remain consistent with the rest of `drmTMB`.

- `beta()`: implemented for continuous proportions in `(0, 1)` with `mu` and
  public `sigma`; ordinary unlabelled random intercepts and independent numeric
  slopes may enter the logit-`mu` predictor. One exact recovery-grade
  `animal()` gate admits a `mu` intercept or one-slope, or a `sigma` intercept,
  one endpoint at a time. Internally `sigma` maps to beta precision
  through `phi = 1 / sigma^2`, so larger `sigma` means more variance, not more
  precision.
- `zero_one_beta()`: implemented for continuous proportions on `[0, 1]` with
  exact structural zeroes or ones, using `zoi` for boundary probability and
  `coi` for the probability of an exact one conditional on the boundary;
  ordinary unlabelled `mu` random intercepts and independent numeric slopes are
  recovery-grade, while `sigma`/`zoi`/`coi` random effects remain planned.
- `ordbeta()`: continuous bounded responses including exact 0 and 1.
- `beta_binomial()`: implemented for counts of successes out of trials with
  overdispersion, including ordinary recovery-grade `mu` random intercepts and
  independent numeric slopes.
- `stats::binomial(link = "logit")`: implemented `drmTMB#569` route for 0/1
  event data and `cbind(successes, failures)` counts, with fixed effects plus
  ordinary recovery-grade `mu` random intercepts and independent numeric
  slopes; there is no public `sigma` and no Julia bridge claim.

Recommended user guidance:

- Use `stats::binomial()` for event probabilities with
  ordinary binomial sampling variation.
- Use `beta_binomial()` for success counts with known denominators and
  extra-binomial variation.
- Use `beta()` for continuous rates strictly between 0 and 1.
- Use `zero_one_beta()` when continuous rates include structural exact 0 or 1
  values.

The implemented `beta()`, `zero_one_beta()`, `beta_binomial()`,
`truncated_nbinom2()`, hurdle NB2, and cumulative-logit seeds give users
strict-proportion, zero-one bounded, denominator-aware proportion,
positive-count, hurdle-count, and ordered-score routes while keeping every new
family within a clear parameter-link contract.

## Tier 6: Positive Continuous Responses

Useful for body size, biomass, time, concentration, and rates.

- `lognormal()`: implemented for positive multiplicative responses, including
  ordinary unlabelled `mu` random intercepts and independent numeric slopes, or
  a separate ordinary `sigma` random intercept. The exact sigma-intercept ledger
  domain is inference-ready with caveats; combined `mu`/`sigma` random effects,
  `sigma` slopes, known covariance, phylogenetic terms, and bivariate extensions
  are later phases.
- `Gamma(link = "log")`: implemented first contract is mean-CV, with
  `log(mu)`, `log(sigma)`, `E[y] = mu`, and `Var[y] = mu^2 sigma^2`.
  Ordinary unlabelled `mu` random intercepts and independent numeric slopes, a
  separate ordinary `sigma` random intercept, and one recovery-grade
  `mu ~ relmat()` intercept or one-slope route are implemented; combined
  `mu`/`sigma` random effects, `sigma` slopes, other structured providers, and
  bivariate extensions are later phases.
- `tweedie()`: implemented route for non-negative
  semicontinuous responses such as biomass, cover, CPUE-like indices, and
  other eco-evo measurements with exact zeros plus positive continuous values;
  ordinary unlabelled `mu` random intercepts and independent numeric slopes are
  recovery-grade.
  The first route uses `log(mu)`, `log(sigma)`, intercept-only `nu ~ 1`,
  `phi = sigma^2`, `1 < nu < 2`, and
  `Var[y] = sigma^2 * mu^nu`. Comparator tests should explicitly transform
  `sigma^2` back to software that reports Tweedie dispersion `phi`.
  [glmmTMB's family documentation](https://glmmtmb.github.io/glmmTMB/reference/nbinom2.html)
  is the first comparator source because it already exposes
  `tweedie(link = "log")` and treats the power parameter as a family-specific
  parameter. The implementation gate is in
  `docs/design/27-tweedie-family-plan.md`.
- `weibull()`: scale and shape.
- `exgaussian()`: location, scale, and positive-tail parameter.
- `gengamma()`: flexible positive continuous family, later only.

## Tier 7: Shape and Asymmetry Families

These connect directly to location-scale-shape modelling.

- `skew_normal()`: implemented `mu`, `sigma`, `nu`, where `nu` is the
  skewness/shape parameter; ordinary unlabelled `mu` random intercepts and
  independent numeric slopes are recovery-grade.
- `skew_t()`: `mu`, `sigma`, `nu`, `tau`, where one shape controls asymmetry
  and the other controls tail shape.
- `asym_laplace()`: quantile-focused distributional regression.

The current `skew_normal()` route keeps `sigma`/`nu` random effects, correlated
or labelled `mu` slopes, and structured effects outside its recovery-grade
ordinary `mu` gate. Shape models are more fragile than scale models because
asymmetry can trade off with location, residual scale, tail shape, outliers,
and unmodelled heteroscedasticity. The exact Student-t
`nu ~ phylo(1 | id, tree = tree)` gate is diagnostic-grade; other phylogenetic
location-scale-shape models need their own recovery evidence.

Shape naming follows the GAMLSS convention: `nu` for the first shape parameter
and `tau` for the second. Aliases such as `skew` or `df` may be helpful later,
but package examples should teach the canonical names first.

For skew-normal-like families, use public moment parameters for the first
fitted lane: `mu = E[y]`, `sigma = SD[y]`, and `nu` as the slant or shape
parameter. Document the transform to native skew-normal `xi`, `omega`, and
`alpha` before adding a constructor. For skew-t-like families, document which
of `nu` and `tau` controls asymmetry and which controls tail shape; do not
assume users can infer that from the parameter name alone.

## Tier 8: Ordinal and Categorical Responses

Ordinal models are valuable, but they are not the first identity of `drmTMB`.
The motivating ecology/evolution example is nest success recorded as ordered
fledging categories, as in Ortega et al. (2026), where the location model
describes expected reproductive success and the ordinal scale or discrimination
model describes the consistency of reproductive outcomes.

- `cumulative_logit()`: ordered categories with thresholds.
- `cumulative_probit()`: ordered categories with probit link.
- `adjacent_category()` or `continuation_ratio()`: later if needed.
- Distributional extensions: threshold scale or discrimination models.

Initial ordinal scope is univariate only. The implemented `cumulative_logit()`
path uses ordered cutpoints, a location formula, a fixed latent logistic scale,
and ordinary recovery-grade `mu` random intercepts or independent numeric
slopes:

```text
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
mu_i = X_mu[i, ] beta_mu + Z_mu[i, ] b_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

The exact q1 `mu ~ phylo(1 | id, tree = tree)` intercept has local
point-fit/extractor evidence only. Other structured providers, ordinal scale or
discrimination models, and interval/coverage promotion for that phylogenetic
gate remain planned.

The next ordinal extension is a scale or discrimination formula. One candidate
is `Pr(y_i <= k) = logit^{-1}((theta_k - mu_i) / sigma_i)` with
`log(sigma_i) = X_sigma[i, ] beta_sigma`. With this convention, larger
`sigma_i` means more diffuse ordinal outcomes and lower consistency. A native
discrimination or consistency quantity can be reported as
`zeta_i = 1 / sigma_i`, matching the interpretation in the seabird
nest-success example where higher `zeta` means clearer separation among
fledging categories. If the implementation instead exposes `zeta` directly,
that should be an explicit formula-grammar decision, not a silent reuse of
`sigma`. The main rule is that the direction of the scale effect must be stated
in the family-link contract before coding starts.

Bivariate ordinal correlation is a later research project because latent
residual correlations are harder to identify and test.

## Explicitly Out of Scope at First

- More than two responses.
- Full copula distribution zoo.
- Arbitrary user-defined TMB likelihoods.
- High-dimensional latent-variable ordination models.
- Full Bayesian prior syntax.
