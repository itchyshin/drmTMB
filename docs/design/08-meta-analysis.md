# Meta-Analysis Design

Meta-analysis in `drmTMB` is regression with known sampling covariance. It is
not a separate response family.

## Current Status

The current Gaussian location-scale MVP fits meta-analysis models with known
sampling covariance supplied as a variance vector, diagonal matrix, dense
block-diagonal matrix, or dense full covariance matrix. Sparse covariance
storage remains planned for larger phylogenetic and spatial workloads.

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
residual or between-study covariance belongs in `sigma1`, `sigma2`, and
`rho12`.

## Implemented Syntax

```r
drmTMB(
  bf(
    yi ~ x1 + x2 + meta_known_V(V = V),
    sigma ~ x1
  ),
  family = gaussian(),
  data = dat
)
```

The response is on the left-hand side. `meta_known_V(V = V)` supplies known
sampling covariance and should not repeat the response name.

## Known Covariance Input

The fitting implementation supports:

- `V = vi`, where `vi` is a data column or vector of known sampling variances;
- one non-negative variance per retained response row;
- a diagonal matrix, where the diagonal is extracted;
- a dense block-diagonal matrix;
- a dense full covariance matrix for correlated sampling errors.

Sparse matrix storage is not implemented yet.

Known-covariance Gaussian models can also be combined with implemented
ordinary `mu` random intercepts and the intercept-only phylogenetic `mu` path.
These combinations are covered by dense likelihood-comparator tests. Random-
effect scale formulas such as `sd(study) ~ x1` in known-covariance meta-
analysis still need explicit validation before they are documented as routine.

The parser should treat `meta_known_V()` as a covariance marker, not as an
ordinary predictor column.

The API should be explicit that vector inputs contain variances. If users have
standard errors, they should supply squared values.

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
atanh(rho12_i) = X_rho12[i, ] beta_rho12
```

Here `S_i` is known and supplied through `meta_known_V(V = V)`. The fitted
`rho12_i` is the residual or between-study correlation after the known
within-study covariance has already been included. This prevents `rho12` from
being asked to explain sampling correlation.

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
practical route for large meta-analyses.

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

Example interpretation: if the `sigma` slope for a binary moderator `x1` is `-0.4`,
then the extra heterogeneity SD is multiplied by `exp(-0.4) = 0.67` for the
moderator group, after adding the known sampling variance `vi`.

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

Ordinary random-intercept meta-regression is implemented. Random-effect scale
components in known-covariance meta-analysis remain a separate validation task.

## Implementation Caveats

- Do not introduce `meta_gaussian()`; meta-analysis remains
  `family = gaussian()`.
- Do not introduce `tau ~` grammar; document the translation from `sigma` to
  meta-analysis terminology instead.
- Row alignment matters: `V` must be subset in the same way as the response and
  model matrices after missing-data handling. For full matrices, rows and
  columns are subset together.
- In bivariate meta-analysis, `V` is known sampling covariance and `rho12` is
  estimated residual or between-study correlation. These quantities should not
  be conflated.
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
