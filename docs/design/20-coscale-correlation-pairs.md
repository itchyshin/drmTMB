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
random-effect correlations from `corpars$mu`, the first univariate labelled
`mu`/`sigma` random-intercept covariance from `corpars$mu_sigma`, the first
bivariate `mu1`/`mu2` and `sigma1`/`sigma2` labelled random-intercept
correlations, and one same-response bivariate `mu`/`sigma` random-intercept
covariance row, the ordinary q=4 all-four bivariate random-intercept block,
plus the first bivariate phylogenetic `mu1`/`mu2` mean-mean correlation from
`corpars$phylo`. It is intentionally a reporting helper, not a new likelihood.
Future rows can be added as phylogenetic scale, phylogenetic mean-scale,
spatial, study-level, and richer double-hierarchical correlation likelihoods
become implemented.

The singular formula marker
`corpair(group, level = "phylogenetic", block = "...", from = "mu1", to = "mu2") ~ x`
is reserved for future predictor-dependent latent random-effect correlations.
`drm_formula()` parses it, but `drmTMB()` rejects it until the likelihood,
diagnostics, and recovery tests exist. Use `rho12 = ~ x` for residual
within-observation correlation, and use `corpairs(fit)` to extract fitted
constant latent correlations.

## Route Decision: Predictor-Dependent `corpair()`

Slice 11 chooses an endpoint-specific design for predictor-dependent ordinary
`corpair()` models. The singular formula marker remains `corpair()`, not
`cor12()`, because this layer is a latent random-effect covariance layer rather
than the residual two-response parameter `rho12`.

The planned endpoint-specific syntax is:

```r
corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ w
corpair(id, level = "group", block = "p", from = "mu1", to = "sigma1") ~ w
corpair(id, level = "group", block = "p", from = "mu1", to = "sigma2") ~ w
corpair(id, level = "group", block = "p", from = "mu2", to = "sigma1") ~ w
corpair(id, level = "group", block = "p", from = "mu2", to = "sigma2") ~ w
corpair(id, level = "group", block = "p", from = "sigma1", to = "sigma2") ~ w
```

The same grammar extends to future structured levels:

```r
corpair(species, level = "phylogenetic", block = "p",
        from = "mu1", to = "mu2") ~ ecology
corpair(site, level = "spatial", block = "p",
        from = "mu1", to = "mu2") ~ habitat
```

This keeps one `corpair()` function family while making the covariance level
explicit. Do not introduce `corpair_phylo()` unless this grammar proves too
awkward in use.

The `class` argument remains useful for extraction and for future shorthand
when a class maps to one unique pair. It should not be the first fitted q=4
modelling target. In an ordinary q=4 block, `class = "location-scale"` names
four distinct latent correlations: `mu1`-`sigma1`, `mu1`-`sigma2`,
`mu2`-`sigma1`, and `mu2`-`sigma2`. A class-wide formula such as
`corpair(id, block = "p", class = "location-scale") ~ w` would therefore mean
"share one predictor model across all four pairs", which is a different model
from choosing one endpoint pair. That shared-class model stays later.

The first fitted ordinary implementation should be q=2 only: one selected
latent pair in a covariance block whose dimension is exactly two. That keeps
the likelihood on the familiar Fisher-z scale,
`rho_j = tanh(eta_j)`, while preserving positive definiteness. Full q=4
predictor-dependent correlations need a separate positive-definite correlation
matrix parameterization; fitting six independent `tanh()` regressions would not
guarantee a valid q=4 correlation matrix.

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
corpairs(fit, level = "group")
corpairs(fit, group = "ID")
corpairs(fit, block = "p")
corpairs(fit, class = "mean-mean")
corpairs(fit, class = "location-location")
corpairs(fit, class = "location-scale")
corpairs(fit, level = "phylogenetic")
```

The fitted table currently reports `mean-mean` and `mean-scale` because that
vocabulary is already used in older random-effect summaries. The endpoint-
specific formula syntax uses distributional-parameter names and a covariance
level, such as
`corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ z`.
To keep those two surfaces compatible while avoiding a broad output rename,
`corpairs()` accepts `location-location`, `location-scale`, `location-slope`,
and `slope-location` as filter aliases for the existing `mean-*` rows. The
older `class` argument remains a planned shorthand, but it is not the first
fitted q=4 modelling target.

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

## Source Map: CRNs, EGA+GNM, and `gllvmTMB`

Two Martin papers are useful design anchors, but they point to different parts
of the package boundary.

The covariance reaction norm paper (Martin, 2025) motivates the `drmTMB`
coscale direction. Its main lesson for this package is to predict marginal
variation and standardized association separately: variance terms use a
positive link, while correlations use Fisher's z scale, `atanh(r)`. In
`drmTMB` syntax this maps to separate formula surfaces such as `sigma1`,
`sigma2`, and `rho12`, rather than a direct covariance formula. Because the
public package interface is `sigma`, not `sigma^2`, documentation should keep
the fitted model on the `sigma` scale and report `sigma^2` explicitly when the
scientific target is variance, predictability, or malleability.

The EGA+GNM paper (Martin et al., 2019) is mainly a `gllvmTMB` lesson. It
starts from repeatability, among-individual trait correlations, and graphical
model comparisons that distinguish latent common causes from pairwise or
partial trait associations. That is the many-trait behavioural-syndrome
problem: latent factors, unique trait variance, between-individual covariance,
and within-individual covariance all need separate interpretation.

The current `gllvmTMB` algorithm follows that split. Its covariance article and
`extract_Sigma()` implementation use:

```text
Sigma_level = Lambda_level Lambda_level' + S_level
R_level = D^(-1/2) Sigma_level D^(-1/2)
```

where `Lambda Lambda'` is the shared latent component and `S` is the
trait-specific unique variance. The important warning for `drmTMB` is that
correlations are only interpretable after the diagonal of `Sigma` is complete.
Dropping a scale or unique component keeps the off-diagonal but shrinks the
denominator, inflating correlations.

`drmTMB` should not copy the full latent-factor machinery from `gllvmTMB`.
Instead, it should provide direct, readable two-response covariance components:
residual `rho12`, selected group-level mean-mean, scale-scale, and mean-scale
correlations, and later structured phylogenetic or spatial correlation pairs.
When a user needs many traits, low-rank latent structure, or a full
`Lambda Lambda' + S` decomposition, the correct package is `gllvmTMB`.

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
cor(a_mu1, a_sigma1)    phylogenetic within-trait mean-scale correlation
cor(a_mu1, a_sigma2)    phylogenetic cross-trait mean-scale correlation
cor(a_mu2, a_sigma1)    phylogenetic cross-trait mean-scale correlation
cor(a_mu2, a_sigma2)    phylogenetic within-trait mean-scale correlation
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
   matching labelled `mu1`/`mu2` and `sigma1`/`sigma2` random intercepts.
5. Add bivariate random intercept-slope covariance blocks.
6. Add residual-scale random-effect covariance blocks. Started for bivariate
   matching labelled `sigma1`/`sigma2` random intercepts; residual-scale
   slopes remain planned.
7. Add cross-parameter mean-scale covariance blocks. Started for the
   one-response labelled `mu`/`sigma` random-intercept bridge and one
   same-response bivariate `mu`/`sigma` random-intercept bridge.
8. Route labelled group-level covariance through the block assembler in
   `docs/design/30-labelled-covariance-block-assembler.md` before exposing
   bivariate random slopes. Done for the ordinary q=4 all-four bivariate
   random-intercept block.
9. Extend the first bivariate phylogenetic mean-mean block toward full
   phylogenetic location-scale covariance, with matching non-phylogenetic
   species or individual covariance blocks.
10. Add spatial bivariate covariance blocks.
11. Reserve `corpair()` formula syntax, but keep fitting disabled. Done for
    parser and error messaging.
12. Add the endpoint-specific `level` plus `from` / `to` grammar for
    predictor-dependent ordinary, phylogenetic, and spatial `corpair()`
    formulas, while still rejecting fitting until the likelihood and tests
    exist.
13. Fit predictor-dependent ordinary q=2 `corpair()` formulas first. The q=2
    restriction keeps the correlation matrix positive definite through a single
    Fisher-z regression.
14. Design a full q=4 positive-definite correlation-regression parameterization
    before fitting endpoint-specific or class-wide q=4 `corpair()` formulas.

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
