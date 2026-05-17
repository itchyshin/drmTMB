# Meta-Analysis Design

Meta-analysis in `drmTMB` is regression with known sampling covariance. It is
not a separate response family.

## Current Status

The current Gaussian location-scale MVP fits meta-analysis models with known
sampling covariance supplied as a variance vector, diagonal matrix, dense
block-diagonal matrix, or dense full covariance matrix. Sparse covariance
storage remains planned for larger phylogenetic and spatial workloads.
Dense matrix support is therefore a small-to-moderate data path, not evidence
that `drmTMB` can already scale arbitrary full `V` matrices to large
meta-analyses. `check_drm()` reports dense known-covariance fits as notes with
matrix dimension, storage, density, size, rank, and conditioning so users see
this boundary before interpretation.

Williams et al. (2026) introduce `glmmTMB::equalto()` for meta-analysis with
known sampling error variance-covariance matrices. That paper is an important
planned comparator and positioning reference for `drmTMB`, but `equalto()` is
not currently part of the package test suite. `glmmTMB` supplies a
general-purpose GLMM route, whereas `drmTMB` should make known covariance one
part of a distributional-regression grammar where `mu`, `sigma`, and later
shape or `rho12` can each have their own formula.

The phylogenetic-spatial meta-analysis tutorial reinforces a useful principle:
meta-analysis is ordinary Gaussian regression plus known sampling covariance
and, when needed, structured random effects. Sampling error uses `V`;
phylogenetic dependence uses a tree-derived matrix `A`; spatial dependence uses
a distance-derived matrix `M`.

For bivariate and multivariate meta-analysis, Mavridis and Salanti (2013)
emphasize that studies contribute effect-size vectors and a within-study
variance-covariance matrix. The same distinction is central for `drmTMB`:
known within-study sampling covariance belongs in `V`, whereas estimated
residual covariance belongs in `sigma1`, `sigma2`, and `rho12`. In a model
where the residual component represents between-study heterogeneity, this
fitted covariance can be interpreted as between-study residual heterogeneity.

## Slice 95 Source Anchors

This section records the paper and local-note sources used to polish the
meta-analysis tutorial. It is not a new API claim.

- Nakagawa et al. (2025, Global Change Biology) motivates the core biological
  question: ecological and evolutionary meta-analyses should model how both the
  average effect size and the heterogeneity of effect sizes change with
  environmental, methodological, hierarchical, and phylogenetic moderators.
- Yang and Nakagawa's distributional-regression meta-analysis manuscript frames
  random-effects, multilevel, multivariate, location-scale, and robust
  meta-analysis as special cases of a broader distributional-regression idea:
  location, scale, and shape parameters can each have predictors.
- Rodriguez et al. (2023) motivates the categorical-moderator teaching rule:
  assuming one common between-study variance across moderator levels can distort
  Type I error and power when group sizes and heterogeneity differ, whereas a
  mixed-effects location-scale model estimates group-specific heterogeneity.
  The paper also notes a small-data caution, especially when there are very few
  studies.
- `../unifying_model/R/unifying.html` motivates the API boundary between
  additive known sampling covariance and proportional sampling-variance
  components. Top-level `weights = w` remains ordinary likelihood weighting;
  a proportional sampling-error component would instead be a modelled variance
  term such as `pi_i ~ Normal(0, phi_pi / w_i)`.

The tutorial should therefore keep four objects separate: known sampling
variance or covariance `V`, residual heterogeneity `sigma`, study-level or
structured random-effect SDs such as `sd(study)` or `phylo()`, and ordinary
likelihood weights `weights = w`.

## Implemented Syntax

```r
drmTMB(
  bf(
    yi ~ x1 + x2 + meta_V(V = V),
    sigma ~ x1
  ),
  family = gaussian(),
  data = dat
)
```

The response is on the left-hand side. `meta_V(V = V)` supplies known sampling
covariance and should not repeat the response name. `meta_known_V(V = V)`
remains a compatibility alias for the same additive likelihood path.

## Known Covariance Input

The fitting implementation supports:

- `V = vi`, where `vi` is a data column or vector of known sampling variances;
- one non-negative variance per retained response row;
- a diagonal matrix, where the diagonal is extracted;
- a dense block-diagonal matrix;
- a dense full covariance matrix for correlated sampling errors.

Sparse matrix storage is not implemented yet. This is especially important for
large block-diagonal meta-analyses: those matrices may be mathematically
block-sparse, but the current direct `meta_known_V(V = V)` matrix route stores
them as dense R matrices after row filtering. Use dense full `V` for small to
moderate fits, likelihood-comparator checks, and unusual dependence structures
where the full covariance is scientifically required. Do not treat it as the
large-data route until sparse or block-sparse storage has implementation,
tests, diagnostics, and benchmark evidence.

Known-covariance Gaussian models can also be combined with implemented
ordinary `mu` random intercepts and the intercept-only phylogenetic `mu` path.
These combinations are covered by dense likelihood-comparator tests. Random-
effect scale formulas such as `sd(study) ~ x1` are also supported for
univariate Gaussian known-covariance models and are covered by an independent
dense marginal-likelihood test.

The parser should treat `meta_known_V()` as a covariance marker, not as an
ordinary predictor column. It should treat `meta_V(V = V)` the same way.

The API should be explicit that vector inputs contain variances. If users have
standard errors, they should supply squared values.

## `meta_V()` Umbrella and Proportional Boundary

The implemented additive known-covariance syntax is:

```r
bf(
  yi ~ x1 + meta_V(V = V),
  sigma ~ x1
)
```

It means that a known sampling-error term enters the marginal covariance
additively:

```text
y ~ MVN(mu, V + Omega_estimated)
```

Slice 205 implements `meta_V(V = V)` as the preferred public spelling for
additive known sampling variance or covariance. The current
`meta_known_V(V = V)` marker remains as a compatibility alias, not as a
separate likelihood path.

The implemented and reserved spelling split is:

```r
meta_V(V = V)
meta_V(w = w, scale = "proportional")
```

The response is already the left-hand side of the model formula, so the marker
does not need a positional response or value argument. `V` may be a column,
numeric vector, diagonal matrix, block-diagonal matrix, or dense matrix, just
as the current additive `meta_known_V(V = V)` path accepts after model-row
filtering.

The proportional case is not implemented and is not a CRAN-blocking requirement
for `0.1.2`. It is distinct from ordinary likelihood weights and would model a
sampling-error component such as:

```text
pi_i ~ Normal(0, phi_pi / w_i)
```

or, for correlated sampling errors, a weighted covariance matrix. This follows
the unifying-model idea that a weight-like quantity can define a variance
component, rather than merely multiplying the row log likelihood. Current
`weights = w` remains a top-level likelihood-weight argument:

```text
ell(theta) = sum_i w_i ell_i(theta)
```

Coexistence rule: diagonal or vector `meta_V(V = V)` may be combined with
top-level `weights =`, but those weights remain ordinary likelihood weights.
They do not create a proportional sampling-variance model. Full dense
matrix-`V` fits reject non-unit top-level weights until joint-block weighting
has a separate likelihood design, diagnostics, and tests. Likewise,
`meta_V(w = w, scale = "proportional")` should not be implemented as a wrapper
around top-level `weights =`.

## Interval Safety

Known sampling covariance `V` is supplied data, not an estimated model
parameter. It should therefore not appear as a Wald or profile confidence-
interval target. Interval tooling should instead expose estimated quantities:
fixed effects, residual heterogeneity such as `sigma`, ordinary random-effect
SDs, structured-effect SDs, and residual correlations such as `rho12`.

The practical rule is:

- `summary(fit, conf.int = TRUE, method = "wald")` may add Wald intervals for
  fixed effects, but response-scale direct parameters such as `sigma` keep an
  explicit unavailable status unless a direct profile interval is requested.
- `profile_targets(fit)` should include estimated `sigma`, random-effect SD,
  structured-effect SD, and `rho12` targets where those quantities exist.
- `profile_targets(fit)` should not add a row for `V`, `meta_V()`, or
  `meta_known_V()` because those are known inputs.
- Dense univariate and bivariate matrix-`V` fits should keep the same estimated
  target inventory as their diagonal/vector-`V` counterparts while respecting
  their separate weighting boundary.

## Unknown Heterogeneity

The public API uses `sigma` consistently:

```r
bf(
  yi ~ x1 + x2 + meta_known_V(V = V),
  sigma ~ x1
)
```

In meta-analysis writing, this `sigma` corresponds to the extra heterogeneity
SD often called `tau`. We should explain that translation in documentation but
avoid a second `tau ~` grammar.

For diagonal `V`, the likelihood is:

```text
yi_i ~ Normal(mu_i, vi_i + sigma_i^2)
mu_i = X_mu beta_mu
log(sigma_i) = X_sigma beta_sigma
```

Here `Normal(a, b)` uses variance as the second argument.

For full `V`, the likelihood is:

```text
y ~ MVN(mu, V + diag(sigma_i^2))
```

For a two-level categorical moderator, the tutorial should define the
heterogeneous-heterogeneity parameterization explicitly:

```text
log(sigma_i) = gamma_0 + gamma_1 forest_i
sigma_grassland = exp(gamma_0)
sigma_forest = exp(gamma_0 + gamma_1)
sigma_forest / sigma_grassland = exp(gamma_1)
sigma_forest^2 / sigma_grassland^2 = exp(2 * gamma_1)
```

This is the `drmTMB` analogue of subgroup-specific between-study
heterogeneity. It uses the public `sigma` grammar even when a meta-analysis
paper would call the same unknown SD `tau`.

## Bivariate Meta-Analysis

Bivariate meta-analysis should use the same Gaussian bivariate family as other
bivariate location-coscale models. It should not introduce a
`meta_gaussian()` family.

The key model separates known within-study sampling covariance from unknown
residual heterogeneity covariance:

```text
y_i = [y1_i, y2_i]'
mu_i = [mu1_i, mu2_i]'

y_i | mu_i, S_i, Omega_i ~ MVN(mu_i, S_i + Omega_i)

S_i =
  [v1_i,   c12_i;
   c12_i, v2_i]

Omega_i =
  [sigma1_i^2,                  rho12_i sigma1_i sigma2_i;
   rho12_i sigma1_i sigma2_i,   sigma2_i^2]

log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = tanh(eta_rho12_i)
```

Here `S_i` is known and supplied through `meta_known_V(V = V)`. The fitted
`rho12_i` is the estimated residual correlation after the known within-study
covariance has already been included. In a model where the residual component
represents between-study heterogeneity, this is the between-study residual
correlation. This prevents `rho12` from being asked to explain sampling
correlation.

The TMB likelihood applies a small numerical boundary guard before evaluating
the covariance matrix so that optimization does not land exactly at `-1` or
`1`. User-facing equations should show the statistical transform above; tests
and likelihood notes can document the guard separately.

The implemented complete-row syntax is:

```r
drmTMB(
  formula = drm_formula(
    mu1 = y1 ~ x1 + meta_known_V(V = V),
    mu2 = y2 ~ x1 + x2,
    sigma1 = ~ x1,
    sigma2 = ~ x1,
    rho12 = ~ x1
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

The `meta_known_V(V = V)` marker is still a model-level known-covariance marker
even if it appears in one location formula. The parser rejects duplicate
markers across `mu1` and `mu2`.

For direct matrix input, `V` should be a `2n` by `2n` matrix using row-paired
stacking:

```text
y_stack = [y1_1, y2_1, y1_2, y2_2, ..., y1_n, y2_n]'
```

For the common study-level case, `V` will usually be block diagonal with one
`2` by `2` block per study. Dense full matrices should remain possible for
unusual dependence structures, but sparse block-diagonal storage should be the
practical route for large meta-analyses. Until that route exists, bivariate
known-`V` examples should stay small to moderate and should show
`check_drm()` output before interpretation.

The user-facing helper `meta_vcov_bivariate()` reduces user error when
constructing the common block-diagonal, row-paired matrix:

```r
V <- meta_vcov_bivariate(v1 = v1, v2 = v2, cov12 = cov12)
V <- meta_vcov_bivariate(v1 = v1, v2 = v2, cor12 = r12)
```

The helper should treat `v1` and `v2` as known sampling variances, not standard
errors. If users have standard errors, they should square them before passing
them or use an explicit helper argument that does the squaring visibly.

The helper is implemented as a matrix constructor, and the complete-row
bivariate Gaussian fitting path now adds this known `V` to the fitted residual
covariance before evaluating the row-paired multivariate normal density.

If within-study correlations are unknown, `drmTMB` should not estimate them
silently in the first implementation. Instead, documentation should encourage
sensitivity analysis over plausible sampling correlations:

```r
fits <- meta_cor_sensitivity(
  formula = ...,
  family = c(gaussian(), gaussian()),
  sampling_cor12 = c(0, 0.3, 0.6, 0.9),
  data = dat
)
```

Missing single outcomes need a separate design decision. The current
implementation is complete bivariate rows only. Later, missing outcomes can be
handled by row/column dropping in the stacked vector or by the large-variance
device used in some multivariate meta-analysis software, but that should not
be implicit until tests show the behaviour is clear.

## Heterogeneous Heterogeneity

Location-scale meta-analysis is a central use case:

```r
bf(
  yi ~ x1 + x2 + meta_known_V(V = V),
  sigma ~ x1
)
```

This follows the idea that categorical and continuous moderators can explain
between-study heterogeneity, not only average effect size.

Example interpretation: if the `sigma` slope for a binary moderator `x1` is
`-0.4`, then the unknown residual heterogeneity SD is multiplied by
`exp(-0.4) = 0.67` for the moderator group. The marginal observation-level
variance remains `vi_i + sigma_i^2`; the multiplier applies only to
`sigma_i`, not to the known sampling variance `vi_i`.

## Multiple Variance Components

Some meta-analyses require more than one unknown scale component:

```r
bf(
  yi ~ x1 + x2 + meta_known_V(V = V) + (1 | study) + (1 | species),
  sd(study) ~ x1,
  sd(species) ~ 1
)
```

This is not a residual `sigma` model with random effects inside it. It is a
model with separate random-effect scale components.

The implemented univariate Gaussian known-covariance path supports ordinary
`mu` random intercepts and random-effect scale formulae for unlabelled random
intercepts. The mathematical contract is:

```text
y_i = mu_i + b_study[j[i]] + b_species[k[i]] + e_i
mu_i = X_mu[i, ] beta_mu
b_study,j ~ Normal(0, omega_study,j^2)
b_species,k ~ Normal(0, omega_species,k^2)
log(omega_study,j) = X_sd_study[j, ] alpha_study
log(omega_species,k) = X_sd_species[k, ] alpha_species
e ~ MVN(0, V + diag(sigma_i^2))
```

Equivalently, after integrating over the random effects:

```text
y ~ MVN(mu, Omega)
Omega = V + diag(sigma_i^2) +
  Z_study diag(omega_study,j^2) Z_study' +
  Z_species diag(omega_species,k^2) Z_species'
```

Predictors in `sd(study) ~ ...` and `sd(species) ~ ...` must be constant within
the named group after missing-data filtering. The validation test compares the
fitted log likelihood with an independent dense marginal Gaussian likelihood.

## Implementation Caveats

- Do not introduce `meta_gaussian()`; meta-analysis remains
  `family = gaussian()`.
- Do not introduce `tau ~` grammar; document the translation from `sigma` to
  meta-analysis terminology instead.
- Do not implement the proportional `meta_V(w = w, scale = "proportional")`
  branch before it has a likelihood design, identifiable parameters,
  diagnostics, examples, row-alignment tests, and comparator checks. The
  additive `meta_V(V = V)` branch is implemented.
- Row alignment matters: `V` must be subset in the same way as the response and
  model matrices after missing-data handling. For full matrices, rows and
  columns are subset together.
- In bivariate meta-analysis, `V` is known sampling covariance and `rho12` is
  estimated residual correlation after known within-study sampling covariance
  has been included. When the residual component represents between-study
  heterogeneity, `rho12` may be reported as a between-study residual
  correlation.
- The implemented paths have simulation recovery, missing-row, and
  likelihood-agreement tests with known `V`.
- Comparator checks should use `metafor` for implemented established
  meta-analysis agreement. `glmmTMB::equalto()` remains a planned comparator for
  overlap with a TMB-based mixed-model implementation.

## Initial Implementation Order

1. Diagonal known sampling variance plus unknown residual `sigma`.
2. Dense full known covariance matrix plus unknown diagonal `sigma`.
3. Random intercept meta-regression.
4. Intercept-only phylogenetic `mu` meta-regression.
5. Multiple random-effect scale components.
6. Bivariate meta-analysis with dense row-paired known sampling covariance.
7. Sensitivity helpers for unknown within-study correlations.

## Phylogenetic And Spatial Meta-Analysis

Phylogenetic and spatial meta-analyses should use the same structured-effect
grammar as non-meta-analytic models.

Teaching notation:

```text
yi_i = mu_i + u_study[j[i]] + p_species[k[i]] + q_species[k[i]] + e_i
p_species ~ MVN(0, sigma_phylo^2 A)
q_species ~ MVN(0, sigma_species^2 I)
e ~ MVN(0, V)
```

Spatial notation:

```text
yi_i = mu_i + l_location[h[i]] + m_location[h[i]] + e_i
l_location ~ MVN(0, sigma_space^2 M)
m_location ~ MVN(0, sigma_location^2 I)
e ~ MVN(0, V)
```

Here `A` and `M` are structured correlation matrices, and `I` is the
unstructured counterpart at the same level. The tutorial cautions that
separating structured and unstructured variance components requires replication
and should be checked carefully before interpretation.

The implemented intercept-only phylogenetic `mu` path already supports this
Gaussian syntax:

```r
drmTMB(
  formula = drm_formula(
    mu = yi ~ x1 + meta_known_V(V = V) +
      phylo(1 | species, tree = tree) + (1 | study),
    sigma = ~ x1
  ),
  family = gaussian(),
  data = dat
)
```

No `meta_gaussian()` family is needed.
