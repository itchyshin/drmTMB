# Distribution Roadmap

This roadmap orders response families by scientific value, implementation risk,
and how well they support the identity of `drmTMB`.

## Tier 1: Continuous MVP

These establish the formula parser, family registry, TMB pipeline, prediction,
simulation, and recovery tests.

- `gaussian()`: `mu`, `sigma`.
- `student()`: `mu`, `sigma`, `nu`; fixed-effect univariate path
  implemented.
- `lognormal()`: `mu`, `sigma` on the log response scale; fixed-effect
  univariate path implemented for positive responses.
- `Gamma(link = "log")`: `mu`, `sigma` as coefficient of variation;
  fixed-effect univariate path implemented for positive responses.
- `beta()`: `mu`, `sigma` for strict continuous proportions; fixed-effect
  univariate path implemented with `phi = 1 / sigma^2` internally.

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
  yi ~ x1 + x2 + meta_known_V(V = V),
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
  `meta_known_V(V = V)` supplies sampling covariance and fitted `rho12`
  remains residual or between-study correlation;
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

- `poisson(link = "log")`: `mu`, with optional `zi`; implemented as the
  fixed-effect baseline count model and fixed-effect zero-inflated Poisson
  model. The `mu` formula supports standard R exposure offsets such as
  `offset(log(trap_nights))`. The `mu` parameter is the conditional Poisson
  mean when `zi` is present.
- `nbinom2()`: `mu`, `sigma`; implemented fixed-effect path with
  `Var(y) = mu + sigma^2 * mu^2`, so larger `sigma` means greater
  overdispersion. The `mu` formula supports standard R exposure offsets such as
  `offset(log(trap_nights))`. Adding `zi ~ predictors` fits the implemented
  fixed-effect zero-inflated NB2 path.
- `truncated_nbinom2()`: `mu`, `sigma`; implemented fixed-effect
  zero-truncated NB2 path for positive counts. The parameters describe the
  untruncated NB2 component, and `fitted()` returns the conditional
  positive-count mean. Adding `hu ~ predictors` fits the implemented
  fixed-effect hurdle NB2 path, where `hu` is the hurdle-zero probability and
  nonzero counts come from the zero-truncated NB2 component.
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
  public `sigma`. Internally `sigma` maps to beta precision through
  `phi = 1 / sigma^2`, so larger `sigma` means more variance, not more
  precision.
- zero-inflated beta: extra zeros, using `zi ~ predictors` with `beta()`
  rather than a separate public constructor unless a later design decision says
  otherwise.
- `zoibeta()` or `zero_one_inflated_beta()`: extra zeros and ones with `zoi`
  and `coi`.
- `ordbeta()`: continuous bounded responses including exact 0 and 1.
- `beta_binomial()`: counts of successes out of trials with overdispersion.
- `binomial()`: successes out of trials, with optional random effects.

Recommended user guidance:

- Use `beta_binomial()` for percentages derived from counts with known
  denominators.
- Use `beta()` for continuous rates strictly between 0 and 1.
- Use zero/one-inflated beta or ordered beta when exact boundaries occur.

Priority order after the implemented `beta()`, `truncated_nbinom2()`, and
hurdle NB2 seeds is therefore univariate ordinal models, then
denominator-aware count proportions. This gives users the positive-count,
hurdle-count, and bounded-score routes after the strict proportion path, while
keeping every new family within a clear parameter-link contract.

## Tier 6: Positive Continuous Responses

Useful for body size, biomass, time, concentration, and rates.

- `lognormal()`: implemented fixed-effect path for positive multiplicative
  responses; random effects, known covariance, phylogenetic terms, and
  bivariate extensions are later phases.
- `Gamma(link = "log")`: implemented first contract is mean-CV, with
  `log(mu)`, `log(sigma)`, `E[y] = mu`, and `Var[y] = mu^2 sigma^2`.
- `weibull()`: scale and shape.
- `exgaussian()`: location, scale, and positive-tail parameter.
- `gengamma()`: flexible positive continuous family, later only.

## Tier 7: Shape and Asymmetry Families

These connect directly to location-scale-shape modelling.

- `skew_normal()`: `mu`, `sigma`, `nu`, where `nu` is the skewness/shape
  parameter.
- `skew_t()`: `mu`, `sigma`, `nu`, `tau`, where one shape controls asymmetry
  and the other controls tail shape.
- `asym_laplace()`: quantile-focused distributional regression.

Start with `skew_normal()` after Student-t is stable, and keep shape random
effects out of the first implementation. Shape models are more fragile than
scale models because asymmetry can trade off with location, residual scale,
tail shape, outliers, and unmodelled heteroscedasticity. Phylogenetic
location-scale-shape models should be staged only after Gaussian phylogenetic
location-scale models pass simulation recovery.

Shape naming follows the GAMLSS convention: `nu` for the first shape parameter
and `tau` for the second. Aliases such as `skew` or `df` may be helpful later,
but package examples should teach the canonical names first.

For skew-normal-like families, document precisely how `nu` maps to the native
asymmetry parameter. For skew-t-like families, document which of `nu` and `tau`
controls asymmetry and which controls tail shape; do not assume users can infer
that from the parameter name alone.

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

Initial ordinal scope should be univariate only. The first implementation
should probably use a cumulative logit model with ordered cutpoints and an
optional `sigma` formula interpreted as ordinal scale:

```text
Pr(y_i <= k) = logit^{-1}((theta_k - mu_i) / sigma_i)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
theta_1 < theta_2 < ... < theta_{K-1}
```

With this convention, larger `sigma_i` means more diffuse ordinal outcomes and
lower consistency. A native discrimination or consistency quantity can be
reported as `zeta_i = 1 / sigma_i`, matching the interpretation in the seabird
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
