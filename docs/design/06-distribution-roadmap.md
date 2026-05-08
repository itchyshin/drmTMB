# Distribution Roadmap

This roadmap orders response families by scientific value, implementation risk,
and how well they support the identity of `drmTMB`.

## Tier 1: Continuous MVP

These establish the formula parser, family registry, TMB pipeline, prediction,
simulation, and recovery tests.

- `gaussian()`: `mu`, `sigma`.
- `student()`: `mu`, `sigma`, `nu`.
- `lognormal()`: `mu`, `sigma` on the log response scale.

## Tier 2: Bivariate Coscale

These are the package-defining families.

- `c(gaussian(), gaussian())`: public direction for `mu1`, `mu2`,
  `sigma1`, `sigma2`, and `rho12`.
- `biv_gaussian()`: retained helper for the implemented all-Gaussian
  fixed-effect model.
- `c(student(), student())`: later robust bivariate model with `nu`.
- `c(gaussian(), poisson())` and other mixed ecological responses: later only
  after the joint likelihood and meaning of `rho12` are designed.

`rho12 ~ predictors` is the flagship feature and is now implemented for the
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
- bivariate meta-analysis with known within-study covariance;
- multiple unknown variance components when study, species, lab, or effect-size
  type require them.

## Tier 4: Counts

Counts need location-scale thinking because dispersion is often biological.

- `poisson()`: `mu`, mostly for baseline comparisons.
- `nbinom2()`: `mu`, `sigma` or family-specific `nu`; variance increases
  quadratically with the mean.
- `nbinom1()`: `mu`, `sigma` or family-specific `nu`; variance increases
  linearly with the mean.
- `compois()`: `mu`, `nu`; handles underdispersion and overdispersion.
- `genpois()`: `mu`, `sigma` or family-specific `nu`; useful alternative for
  count dispersion.
- `truncated_nbinom2()` and `truncated_poisson()` for positive counts.
- `zi_poisson()` and `zi_nbinom2()` with `zi ~ predictors`.
- `hurdle_poisson()` and `hurdle_nbinom2()` with `hu ~ predictors`.

Priority order: `nbinom2`, `compois`, zero-inflated negative binomial, hurdle
negative binomial.

## Tier 5: Proportions, Percentages, and Bounded Continuous Responses

Percent data should be represented according to how the data were generated.

- `beta()`: continuous proportions in `(0, 1)` with `mu` and `sigma` in the
  canonical GAMLSS-style grammar; documentation can translate to precision
  `phi` where useful.
- `zi_beta()`: extra zeros.
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

## Tier 6: Positive Continuous Responses

Useful for body size, biomass, time, concentration, and rates.

- `gamma()`: `mu`, `shape` or `sigma`.
- `weibull()`: scale and shape.
- `exgaussian()`: location, scale, and positive-tail parameter.
- `gengamma()`: flexible positive continuous family, later only.

## Tier 7: Shape and Asymmetry Families

These connect directly to location-scale-shape modelling.

- `skew_normal()`: `mu`, `sigma`, `nu`, where `nu` is the skewness/shape
  parameter.
- `skew_t()`: `mu`, `sigma`, `nu`, `tau`, where one shape controls asymmetry
  and the other controls tail weight.
- `asym_laplace()`: quantile-focused distributional regression.

Start with `skew_normal()` after Student-t is stable.

Shape naming follows the GAMLSS convention: `nu` for the first shape parameter
and `tau` for the second. Aliases such as `skew` or `df` may be helpful later,
but package examples should teach the canonical names first.

## Tier 8: Ordinal and Categorical Responses

Ordinal models are valuable, but they are not the first identity of `drmTMB`.

- `cumulative_logit()`: ordered categories with thresholds.
- `cumulative_probit()`: ordered categories with probit link.
- `adjacent_category()` or `continuation_ratio()`: later if needed.
- Distributional extensions: threshold scale or discrimination models.

Initial ordinal scope should be univariate only. Bivariate ordinal correlation is
a later research project because latent residual correlations are harder to
identify and test.

## Explicitly Out of Scope at First

- More than two responses.
- Full copula distribution zoo.
- Arbitrary user-defined TMB likelihoods.
- High-dimensional latent-variable ordination models.
- Full Bayesian prior syntax.
