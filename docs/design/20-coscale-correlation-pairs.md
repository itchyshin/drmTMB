# Coscale Correlation-Pair Plan

This note defines the planned correlation-pair namespace for `drmTMB`. It
exists because the package should eventually estimate more than residual
`rho12`, but those correlations must not collapse into one ambiguous symbol.

## Current Boundary

Implemented now for the bivariate residual correlation:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)

Omega_i[1,1] = sigma1_i^2
Omega_i[2,2] = sigma2_i^2
Omega_i[1,2] = rho12_i sigma1_i sigma2_i

rho12_i = 0.99999999 * tanh(X_rho12[i, ] beta_rho12)
```

Matching implemented R syntax:

```r
drmTMB(
  drm_formula(
    mu1 = y1 ~ x1 + x2,
    mu2 = y2 ~ x1,
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

Here `rho12` is a residual or within-row response-response correlation. It is
not a phylogenetic correlation, not a spatial correlation, and not a
group-level random-effect correlation.

The helper `corpairs(fit)` is implemented for fitted correlations that already
exist: residual bivariate `rho12` summaries, ordinary univariate Gaussian `mu`
random-effect correlations from `corpars$mu`, and the first bivariate
`mu1`/`mu2` labelled random-intercept correlation. It is intentionally a
reporting helper, not a new likelihood. Future rows can be added as
phylogenetic, spatial, study-level, and richer double-hierarchical correlation
likelihoods become implemented.

## Why Named Correlation Pairs Are Needed

Double-hierarchical and structured bivariate models can contain several
scientifically different correlations:

```text
mu1_ij = X1[ij, ] beta1 + b_mu1_0j + x_ij b_mu1_1j
mu2_ij = X2[ij, ] beta2 + b_mu2_0j + x_ij b_mu2_1j

log(sigma1_ij) = W1[ij, ] gamma1 + a_sig1_0j + x_ij a_sig1_1j
log(sigma2_ij) = W2[ij, ] gamma2 + a_sig2_0j + x_ij a_sig2_1j

u_j =
  [b_mu1_0j, b_mu1_1j, b_mu2_0j, b_mu2_1j,
   a_sig1_0j, a_sig1_1j, a_sig2_0j, a_sig2_1j]'

u_j ~ MVN(0, Sigma_ID)
```

The covariance matrix `Sigma_ID` contains many interpretable correlation
pairs. The same fitted model can ask whether individual differences in average
response, mean-model slopes, residual scale, and scale-model slopes are
correlated within or between responses. These are group-level covariance
parameters, not residual `rho12`.

## Correlation-Pair Table

Future extractors should return a long table rather than only nested matrices.
A row should identify the full pair:

| Column | Meaning |
|---|---|
| `level` | residual, ordinary group, phylogenetic, non-phylogenetic species, spatial, study, site, or another structured level |
| `group` | grouping factor or structured-effect label, such as `ID`, `species`, `site`, or `phylo` |
| `block` | covariance-block label, such as `p`; `NA` for residual `rho12` |
| `from_dpar`, `to_dpar` | distributional parameters such as `mu1`, `mu2`, `sigma1`, or `sigma2` |
| `from_coef`, `to_coef` | random-effect coefficients such as `(Intercept)` or `x` |
| `from_response`, `to_response` | response index or name when relevant |
| `class` | residual, mean-mean, slope-slope, scale-scale, mean-scale, or other documented class |
| `estimate` | response-scale correlation |
| `link_estimate` | unconstrained optimizer-scale value when available |

Implemented extractor:

```r
corpairs(fit)
corpairs(fit, level = "ID")
corpairs(fit, class = "mean-scale")
```

The existing `rho12(fit)` helper should remain a narrow convenience extractor
for residual response-response correlation only.

## Reader-Facing Interpretations

The package should not hard-code one field's terminology into the model, but it
can teach common interpretations:

| Correlation class | Example pair | Common interpretation |
|---|---|---|
| mean-mean intercept | `cor(mu1:(Intercept), mu2:(Intercept) | ID)` | between-response association in individual averages |
| slope-slope mean | `cor(mu1:x, mu2:x | ID)` | association between individual mean-model slopes |
| scale-scale intercept | `cor(sigma1:(Intercept), sigma2:(Intercept) | ID)` | association between individual baseline residual scales |
| scale-scale slope | `cor(sigma1:x, sigma2:x | ID)` | association between individual changes in residual scale |
| mean-slope | `cor(mu1:(Intercept), mu1:x | ID)` | individual average response versus mean-model slope |
| mean-scale | `cor(mu1:(Intercept), sigma1:(Intercept) | ID)` | individual average response versus residual scale |
| slope-scale | `cor(mu1:x, sigma1:(Intercept) | ID)` | mean-model slope versus residual scale |

These names are interpretation aids. The extractor should always report the
formal pair so users can interpret other designs without guessing.

## Planned Syntax

The likely user-facing route is labelled covariance blocks:

```r
drmTMB(
  formula = drm_formula(
    mu1 = y1 ~ x1 + x2 + (1 + x2 | p | ID),
    mu2 = y2 ~ x1      + (1 + x2 | p | ID),
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

In a later double-hierarchical model, the same block label could span location
and residual-scale formulas:

```r
drm_formula(
  mu1 = y1 ~ x + (1 + x | p | ID),
  mu2 = y2 ~ x + (1 + x | p | ID),
  sigma1 = ~ x + (1 + x | p | ID),
  sigma2 = ~ x + (1 + x | p | ID),
  rho12 = ~ x
)
```

This syntax is not implemented. The current `drmTMB()` path must reject it
clearly until the likelihood, positive-definite covariance parameterization,
simulation recovery, and extractor tests are implemented.

The full endpoint and its staged implementation map are recorded in
`docs/design/28-double-hierarchical-endpoint.md`.

## Structured Correlation Pairs

Phylogenetic and spatial models use the same naming principle. For example:

```text
[a_mu1, a_mu2, a_sigma1, a_sigma2]' ~ MVN(0, Sigma_phylo kron A)
```

This can yield:

```text
cor(a_mu1, a_mu2)       phylogenetic mean-mean correlation
cor(a_sigma1, a_sigma2) phylogenetic scale-scale correlation
cor(a_mu1, a_sigma2)    phylogenetic cross-trait mean-scale correlation
```

Analogous non-phylogenetic species, site, study, and spatial field
correlations should have their own `level` labels. They should not be reported
as residual `rho12`, even in bivariate models.

The first structured two-response target should keep three layers visible at
the same time: phylogenetic correlation, non-phylogenetic species or individual
correlation, and residual `rho12`. This is a modelling requirement, not a
display preference, because each layer answers a different biological question.

## Implementation Order

1. Keep fixed-effect residual `rho12 ~ predictors` stable.
2. Keep univariate ordinary random-effect correlations under `corpars$mu`.
3. Add a `corpairs()` design table for existing fitted correlations, including
   residual `rho12` and univariate `mu` intercept-slope correlations. Done for
   the currently fitted correlation classes.
4. Add bivariate group-level random intercept covariance blocks. Done for
   matching labelled `mu1`/`mu2` random intercepts.
5. Add bivariate random intercept-slope covariance blocks.
6. Add residual-scale random-effect covariance blocks.
7. Add cross-parameter mean-scale covariance blocks.
8. Add bivariate phylogenetic covariance blocks with matching non-phylogenetic
   species or individual covariance blocks.
9. Add spatial bivariate covariance blocks.
10. Only after simulation evidence: consider predictor-dependent group-level or
   structured-effect correlation formulas.

For covariance blocks with more than two random-effect coefficients, use a
positive-definite Cholesky or partial-correlation parameterization. Do not fit
separate unconstrained pairwise `tanh()` correlations because that does not
guarantee a valid correlation matrix.

## Testing Requirements

Every implemented correlation-pair phase needs:

- symbolic equations paired with R syntax;
- simulation recovery for SDs and correlations;
- a comparator where possible, such as `lme4` for ordinary Gaussian overlap;
- tests that residual `rho12` and group-level correlations are extracted under
  different names;
- boundary checks for correlations near zero and near `+/-0.8`;
- weak-identification warnings when an SD is close to zero;
- an after-task report recording unsupported pair classes.
