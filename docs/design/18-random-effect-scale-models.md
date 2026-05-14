# Random-Effect Scale Models

This note is the design contract for random-effect scale formulae such as
`sd(id) ~ x_group`. The univariate Gaussian implementation supports one or
more distinct unlabelled `mu` random-intercept targets; the same document also
records future extensions so math, R syntax, tests, and user explanations stay
aligned.

## Core Distinction

`drmTMB` has several scale quantities. They must not be collapsed into one
word.

| Quantity | Meaning | Example syntax | Implementation status |
|---|---|---|---|
| `sigma_i` | residual or within-observation standard deviation | `sigma ~ x1` | implemented for Gaussian |
| `a_g` | residual-scale random effect added to `log(sigma_i)` | `sigma ~ x1 + (1 | id)` or `sigma ~ x1 + (0 + w | id)` | implemented for univariate Gaussian random intercepts and independent random slopes |
| `sd_mu_id` | standard deviation of a `mu` random effect | `sd(id) ~ x_group` | implemented for one or more distinct unlabelled Gaussian `mu` random intercepts |
| `sd_mu1_id`, `sd_mu2_id` | response-specific standard deviations of bivariate location random effects | `sd1(id) ~ x_group`, `sd2(id) ~ x_group` | implemented for labelled bivariate Gaussian `mu1`/`mu2` location random intercepts |
| `rho_re` | group-level random-effect correlation | `(1 + x1 | id)` | implemented for one `mu` slope |
| `rho12_i` | residual correlation between two responses | `rho12 ~ x1` | implemented for fixed-effect bivariate Gaussian |

## Sigma And Variance Reporting

The public drmTMB grammar uses `sigma` for residual scale:

```r
bf(y ~ x, sigma ~ z)
```

Keep that public syntax. It matches brms-style distributional formulas and the
project's stable terminology. For individual-difference summaries of
predictability and malleability, the scientific interpretation often concerns
residual variance. Report that as a derived quantity, `sigma^2`, rather than
changing the model grammar to a variance formula.

For log-scale Gaussian models:

```text
log(sigma_i) = eta_sigma_i
sigma_i = exp(eta_sigma_i)
variance_i = sigma_i^2 = exp(2 eta_sigma_i)
```

Thus a coefficient in a log-`sigma` model doubles when expressed on the
log-variance scale. A random-effect variance component on the log-`sigma` scale
is multiplied by four when expressed on the log-variance scale. This conversion
is needed when comparing drmTMB or brms-style `sigma` models with paper-facing
summaries that are written for residual variances.

## Implemented Residual Scale

The implemented fixed-effect Gaussian location-scale model is:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
sigma_i = exp(X_sigma[i, ] beta_sigma)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

The `sigma` formula always targets residual or within-observation scale. If
`x2` is treatment, a positive `sigma` coefficient means observations in that
treatment have larger residual standard deviation after accounting for the
mean model.

## Implemented Residual-Scale Random Intercepts

Residual-scale random intercepts enter the log residual standard deviation:

```text
y_ij | mu_ij, sigma_ij, a_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_j
log(sigma_ij) = X_sigma[ij, ] beta_sigma + a_j

b_j = sd_mu_id u_j
u_j ~ Normal(0, 1)

a_j = sd_sigma_id v_j
v_j ~ Normal(0, 1)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2 + (1 | id) + (0 + w | id)),
  family = gaussian(),
  data = dat
)
```

Here `sd_sigma_id` is the standard deviation of group-to-group deviations on
the log residual SD scale. It answers a residual-scale heterogeneity question:
do some groups have consistently larger or smaller within-group residual
variation than others?

It does not answer whether the among-group variation in the mean-model random
intercepts changes with a predictor. That is the role of `sd(id) ~ x`.

## Implemented Random-Effect Scale Formula

The simplest random-effect scale model targets one existing unlabelled
univariate Gaussian `mu` random intercept:

```text
y_ij | mu_ij, sigma_ij, b_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_j
log(sigma_ij) = X_sigma[ij, ] beta_sigma

b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
```

Matching implemented R syntax:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | id),
    sigma ~ x2,
    sd(id) ~ x_group
  ),
  family = gaussian(),
  data = dat
)
```

The right-hand side of `sd(id) ~ x_group` is group-level. Each predictor in
`W_id` must be constant within levels of `id` after missing-row filtering. If a
predictor varies within `id`, the user should use `sigma ~ predictor` for
residual scale or aggregate/define a group-level predictor before fitting
`sd(id) ~ predictor`.

Ecology/evolution interpretation:

```r
drmTMB(
  bf(
    boldness ~ habitat + (1 | id),
    sigma ~ habitat,
    sd(id) ~ habitat
  ),
  family = gaussian(),
  data = dat
)
```

Symbolically:

```text
boldness_ij ~ Normal(mu_ij, sigma_ij^2)
mu_ij = beta_0 + beta_1 habitat_ij + b_j
log(sigma_ij) = gamma_0 + gamma_1 habitat_ij
b_j = sd_id,j u_j
u_j ~ Normal(0, 1)
log(sd_id,j) = alpha_0 + alpha_1 habitat_j
```

This model has two biologically different scale regressions:

- `sigma ~ habitat`: habitat changes within-individual residual
  variability, or predictability.
- `sd(id) ~ habitat`: habitat changes among-individual differences in the
  expected response, or the spread of individual-level intercepts.

This distinction also matches the logic of phylogenetic location-scale models:
a residual scale equation models log residual SD, whereas a random-factor scale
equation models the SD of a structured or unstructured group effect. Box 1 of
the Nakagawa et al. phylogenetic location-scale model paper is the bridge for
future `drmTMB` work: separate scale equations can be written for different
random factors, such as phylogenetic and non-phylogenetic species effects,
without treating all of them as residual `sigma`.

That bridge defines a second model family. In Family A, random effects may
enter `sigma` formulas directly, and future `corpair()` work will describe
correlations among latent location and scale effects. In Family B,
`sd(group)`, `sd1(group)`, and `sd2(group)` model the SD of location random
effects directly. Do not combine both ideas for the same latent layer; for
example, `sigma1 = ~ z + (1 | p | id)` and `sd_sigma1(id) ~ w` are not a valid
first target.

For bivariate Gaussian models, the same boundary also applies to ordinary q=4
Family A blocks. If `(1 | p | id)` is present in `mu1`, `mu2`, `sigma1`, and
`sigma2`, the likelihood already estimates one joint covariance matrix for
the four latent effects. Adding `sd1(id) ~ z` or `sd2(id) ~ z` would try to
make the location-effect SDs predictor-dependent while keeping the four-way
covariance block constant. That hybrid is not an implemented model family, so
the builder rejects it before fitting.

## Structured Direct-SD Targets

Names such as `sd_phylo(species)`, `sd_phylo1(species)`,
`sd_phylo2(species)`, and `sd_spatial(site)` are planned Family B targets, but
they are not scalar replacements for the fitted `log_sd_phylo` parameters. In
the current phylogenetic likelihood, the latent species effects are coupled by
a Brownian-motion tree precision:

```text
a ~ MVN(0, sigma_phylo^2 A)
```

For a predictor-dependent structured SD, the design must first choose the
covariance being modelled. A candidate construction is:

```text
a = D(z) v
v ~ MVN(0, A)
Cov(a) = D(z) A D(z)
```

where `D(z)` is a diagonal matrix of species-level SDs. That construction has
different determinant and quadratic terms from the current scalar
`sigma_phylo^2 A` model, and it raises a practical question for sparse
augmented A-inverse implementations: predictors are observed at tips, whereas
the computational latent state also includes internal nodes. Until that
tip/internal-node contract is explicit and tested, `sd_phylo()` remains a
planned syntax rather than fitted code.

## Multiple Random-Effect Scale Components

When there are several random-effect components, each scale formula must name
its target:

```text
mu_i = X_mu[i, ] beta_mu + b_site[site_i] + b_species[species_i]
b_site[k] = sd_mu_site,k u_site,k
b_species[l] = sd_mu_species,l u_species,l
log(sd_mu_site,k) = W_site[k, ] alpha_site
log(sd_mu_species,l) = W_species[l, ] alpha_species
```

Implemented R syntax:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | site) + (1 | species),
    sigma ~ x2,
    sd(site) ~ x3,
    sd(species) ~ 1
  ),
  family = gaussian(),
  data = dat
)
```

The parser must reject ambiguous shorthand. For example, if `id` has both a
random intercept and a random slope, then `sd(id) ~ x1` is ambiguous because it
does not say whether the intercept SD or slope SD is being modelled.

Explicit coefficient-specific syntax is now reserved but not fitted:

```r
sd(id, dpar = "mu", coef = "(Intercept)") ~ x1
sd(id, dpar = "mu", coef = "x1") ~ x2
```

`drm_formula()` parses that grammar and stores the target, but `drmTMB()`
rejects it before fitting. The likelihood still needs a covariance contract for
predictor-dependent intercept and slope SDs, and tests must cover how constant
or predictor-dependent correlations are handled when the SDs vary by group.

The current implementation accepts `sd(id) ~ x1` only when there is exactly one
matching univariate Gaussian `mu` random-intercept term for `id`, but it can
accept several distinct targets in the same model, such as `sd(site) ~ x3` and
`sd(species) ~ 1`.

## Random Slopes

Random slopes add separate group-level scale quantities:

```text
mu_ij = X_mu[ij, ] beta_mu + b_0j + x1_ij b_1j
[b_0j, b_1j]' ~ MVN(0, Sigma_id)
Sigma_id =
  [sd0_j^2,          rho_re sd0_j sd1_j;
   rho_re sd0_j sd1_j, sd1_j^2]
```

In early implementations, `rho_re` should remain a constant group-level
correlation. Predictor-dependent correlation formulae should be reserved for
residual `rho12` until simulation evidence supports more complex group-level
correlation models.

Planned explicit scale syntax for random slopes:

```r
drmTMB(
  bf(
    y ~ x1 + (1 + x1 | id),
    sigma ~ x2,
    sd(id, dpar = "mu", coef = "(Intercept)") ~ x3,
    sd(id, dpar = "mu", coef = "x1") ~ x3
  ),
  family = gaussian(),
  data = dat
)
```

This is not the first implementation target.

## Bivariate Boundary

For bivariate models:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
Omega_i[1,2] = rho12_i sigma1_i sigma2_i
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = 0.99999999 * tanh(eta_rho12_i)
```

Matching implemented fixed-effect syntax:

```r
drmTMB(
  bf(
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

`rho12` is residual response-response correlation. It is not the correlation
between random intercepts, random slopes, or random scale effects. Those
belong to group-level covariance blocks and should be extracted separately.

The implemented bivariate direct-SD syntax targets location random effects
only:

```text
mu1_i = X_mu1[i, ] beta_mu1 + b1[id_i]
mu2_i = X_mu2[i, ] beta_mu2 + b2[id_i]
[u1_j, u2_j]' ~ Normal([0, 0]', R_group)
b1_j = sd_mu1_id,j u1_j
b2_j = sd_mu2_id,j u2_j
log(sd_mu1_id,j) = W1_id[j, ] alpha1
log(sd_mu2_id,j) = W2_id[j, ] alpha2
```

Matching implemented R syntax:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x + (1 | p | id),
    mu2 = y2 ~ x + (1 | p | id),
    sigma1 = ~ z1,
    sigma2 = ~ z2,
    rho12 = ~ w,
    sd1(id) ~ x_group1,
    sd2(id) ~ x_group2
  ),
  family = biv_gaussian(),
  data = dat
)
```

`sd1(id)` targets the `mu1` location random-intercept SD and `sd2(id)` targets
the `mu2` location random-intercept SD. Their predictors must be constant
within `id`, just like univariate `sd(id)`. They do not target residual
`sigma1`, residual `sigma2`, or random effects inside the scale formulas.

## Implementation Rules

The implemented `sd(group) ~ x` and bivariate `sd1(group) ~ x` / `sd2(group) ~
x` paths should:

1. support Gaussian models first;
2. target one or more distinct unlabelled univariate `mu` random intercepts
   such as `(1 | id)` and `(1 | site)`;
3. target labelled bivariate Gaussian location random intercepts through
   `sd1(group)` for `mu1` and `sd2(group)` for `mu2`;
4. reject random slopes, duplicate targets, mismatched grouping factors, and
   names such as `sd_sigma1()` / `sd_sigma2()`;
5. require right-hand-side predictors to be constant within target groups;
6. use a non-centered TMB parameterization with standardized `u_j`;
7. replace each targeted scalar `log_sd_mu` with a group-level linear
   predictor such as `W_id alpha_id`;
8. keep residual `sigma` and residual-scale random effects independent of the
   `sd(group)` scale model;
9. add simulation recovery and malformed-input tests before user docs call the
   syntax implemented.

## Test Contract

Tests for the first implementation should include:

- a moderate recovery case for `log(sd_id,j) = alpha_0 + alpha_1 x_j`;
- a multi-target case such as `sd(id) ~ x_id` plus `sd(site) ~ x_site`;
- a near-constant scale case with `alpha_1 = 0`;
- a large scale-slope case that checks positivity and convergence;
- a factor predictor on the `sd(id)` right-hand side;
- rejection when the target random effect is absent;
- rejection when the target is ambiguous because `id` has multiple random
  coefficients;
- rejection when an `sd(id)` predictor varies within `id`;
- a comparator smoke test against `lme4` when `alpha_1 = 0`, because that case
  reduces to a homoscedastic random-intercept model.

Long simulations should explore group count, within-group replication,
unbalanced sampling, sparse groups, and boundary standard deviations.
