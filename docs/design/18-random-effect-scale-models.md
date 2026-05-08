# Random-Effect Scale Models

This note is the design contract for future random-effect scale formulae such
as `sd(id) ~ x`. It exists before implementation so the math, R syntax, tests,
and user explanations can be checked against one another.

## Core Distinction

`drmTMB` has several scale quantities. They must not be collapsed into one
word.

| Quantity | Meaning | Example syntax | Implementation status |
|---|---|---|---|
| `sigma_i` | residual or within-observation standard deviation | `sigma ~ x1` | implemented for Gaussian |
| `a_g` | residual-scale random effect added to `log(sigma_i)` | `sigma ~ x1 + (1 | id)` | implemented for univariate Gaussian random intercepts |
| `sd_mu_id` | standard deviation of a `mu` random effect | `sd(id) ~ x1` | planned |
| `rho_re` | group-level random-effect correlation | `(1 + x1 | id)` | implemented for one `mu` slope |
| `rho12_i` | residual correlation between two responses | `rho12 ~ x1` | implemented for fixed-effect bivariate Gaussian |

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
  bf(y ~ x1 + (1 | id), sigma ~ x2 + (1 | id)),
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

## Planned Random-Effect Scale Formula

The first planned random-effect scale model should target exactly one existing
univariate Gaussian `mu` random intercept:

```text
y_ij | mu_ij, sigma_ij, b_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_j
log(sigma_ij) = X_sigma[ij, ] beta_sigma

b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
```

Matching planned R syntax:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | id),
    sigma ~ x2,
    sd(id) ~ x3
  ),
  family = gaussian(),
  data = dat
)
```

The right-hand side of `sd(id) ~ x3` is group-level. In the MVP, each predictor
in `W_id` must be constant within levels of `id` after missing-row filtering.
If `x3` varies within `id`, the user should use `sigma ~ x3` for residual
scale or aggregate/define a group-level predictor before fitting `sd(id) ~ x3`.

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

Planned R syntax:

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

Future explicit syntax should be considered:

```r
sd(id, dpar = "mu", coef = "(Intercept)") ~ x1
sd(id, dpar = "mu", coef = "x1") ~ x2
```

The first implementation can accept `sd(id) ~ x1` only when there is exactly
one matching univariate Gaussian `mu` random-intercept term for `id`.

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
atanh(rho12_i) = X_rho12[i, ] beta_rho12
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
  family = biv_gaussian(),
  data = dat
)
```

`rho12` is residual response-response correlation. It is not the correlation
between random intercepts, random slopes, or random scale effects. Those
belong to group-level covariance blocks and should be extracted separately.

## MVP Implementation Rules

The first `sd(id) ~ x` implementation should:

1. support only univariate Gaussian models;
2. target only one unlabelled `mu` random intercept `(1 | id)`;
3. reject bivariate models, random slopes, labelled blocks, duplicate targets,
   and mismatched grouping factors;
4. require right-hand-side predictors to be constant within target groups;
5. use a non-centered TMB parameterization with standardized `u_j`;
6. replace the scalar `log_sd_mu` for that target with a group-level linear
   predictor `W_id alpha_id`;
7. keep residual `sigma` and residual-scale random effects independent of the
   `sd(id)` scale model;
8. add simulation recovery and malformed-input tests before user docs call the
   syntax implemented.

## Test Contract

Tests for the first implementation should include:

- a moderate recovery case for `log(sd_id,j) = alpha_0 + alpha_1 x_j`;
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
