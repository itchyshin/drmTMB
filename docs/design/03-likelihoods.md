# Likelihoods

Likelihoods are implemented in TMB templates and called from R wrappers.

## Parameter Scales

- Positive parameters use log links.
- Unit-interval parameters use logit links.
- Residual correlations use a Fisher-z-like linear predictor and a guarded
  `0.99999999 * tanh()` response transform.
- Shape parameters use family-specific stable links.

## Variability Orientation

The public scale slot is `sigma` when the parameter controls modelled
variability. The user-facing orientation is:

```text
larger sigma -> larger variability, dispersion, or heterogeneity
```

This is a user-interface contract, not a claim that every likelihood is written
with a standard deviation parameter internally. Some likelihoods are naturally
expressed with precision or size parameters. In those cases, the TMB objective
may use a transformed internal quantity, but extractors and tutorials should
report the public `sigma` direction unless a comparator check explicitly needs
the original parameterization.

Current examples:

| Family | Public scale | Internal or comparator scale | Direction |
| --- | --- | --- | --- |
| `gaussian()` | `sigma` | residual SD | larger `sigma` means larger residual variance |
| `Gamma(link = "log")` | `sigma` | shape `1 / sigma^2` | larger `sigma` means larger coefficient of variation |
| `beta()` | `sigma` | beta precision `phi = 1 / sigma^2` | larger `sigma` means lower precision and larger variance |
| `beta_binomial()` | `sigma` | beta precision `phi = 1 / sigma^2` | larger `sigma` means more extra-binomial variation |
| `nbinom2()` | `sigma` | NB2 size `theta = 1 / sigma^2` | larger `sigma` means more extra-Poisson variation |
| `student()` | `sigma`, `nu` | scale plus degrees of freedom | larger `sigma` means wider core scale; larger `nu` means lighter tails |

Names that are not scale slots should stay specific. For example, ordinal
`theta` values are cutpoints, not a precision or variability parameter, and
Student-t `nu` is a shape parameter rather than an alias for `sigma`.
In bivariate Gaussian models, `rho12` is the residual coscale parameter:
coscale means modelling residual correlation after the location and scale
predictors have been accounted for. This term should not be collapsed with
ordinary group-level, phylogenetic, or spatial correlations.

The guard on residual correlations is purely numerical. In teaching material,
describe the model as the standard transform `rho = tanh(eta)`, then note that
the implementation multiplies by `0.99999999` so covariance matrices stay
strictly positive definite in floating-point arithmetic near `rho = -1` or
`rho = 1`.

## Notation

In mathematical prose, `Normal(a, b)` uses variance as the second argument.
The corresponding R density call uses standard deviation, as in
`dnorm(y, mean = a, sd = sqrt(b), log = TRUE)`.

## Implemented TMB Routing

The R builders use descriptive model labels, such as `"gaussian"`,
`"student"`, `"lognormal"`, `"gamma"`, `"beta"`, `"beta_binomial"`,
`"poisson"`, `"zi_poisson"`, `"cumulative_logit"`, `"nbinom2"`, `"truncated_nbinom2"`,
`"hurdle_nbinom2"`, `"zi_nbinom2"`, and `"biv_gaussian"`. Before calling
the TMB template, `make_tmb_data()` turns
those labels into integer branches in `src/drmTMB.cpp`. Unknown labels are
rejected before they can fall through to a wrong likelihood branch. This table
is the current routing contract:

| TMB `model_type` | User-facing route | R builder | TMB branch purpose |
|---:|---|---|---|
| `1` | `family = gaussian()` | `drm_build_gaussian_ls_spec()` | Univariate Gaussian location-scale models, including ordinary `mu` random effects, residual-scale `sigma` random effects, `sd(group) ~ ...` random-effect scale models, `meta_known_V(V = V)`, the implemented intercept-only `phylo()` location effect, the first coordinate-based `spatial()` location effect, and the first opt-in fixed-effect Gaussian aggregation path. |
| `2` | `family = biv_gaussian()`, `family = c(gaussian(), gaussian())`, or `family = list(gaussian(), gaussian())` | `drm_build_biv_gaussian_spec()` | Bivariate Gaussian location-scale-coscale models with `mu1`, `mu2`, `sigma1`, `sigma2`, and residual `rho12`, including complete-row dense known sampling covariance, matching labelled `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept covariance blocks, one same-response `mu`/`sigma` random-intercept covariance pair, intercept-only ordinary q=4 covariance blocks across all four bivariate distributional parameters, bivariate location random-effect SD formulas `sd1(group)` / `sd2(group)`, matching intercept-only phylogenetic random intercepts in `mu1` and `mu2`, and constant all-four phylogenetic location-scale blocks in either full q=4 or block-diagonal two-q2 form. |
| `3` | `family = student()` | `drm_build_student_ls_spec()` | Univariate Student-t location-scale-shape models with `mu`, `sigma`, and `nu = 2 + exp(eta_nu)`. |
| `4` | `family = lognormal()` | `drm_build_lognormal_ls_spec()` | Univariate fixed-effect lognormal location-scale models for positive responses, with `mu` and `sigma` defined on the log-response scale. |
| `5` | `family = Gamma(link = "log")` | `drm_build_gamma_ls_spec()` | Univariate fixed-effect Gamma mean-CV models for positive responses, with `mu` as the response mean and `sigma` as the coefficient of variation. |
| `6` | `family = poisson(link = "log")` | `drm_build_poisson_spec()` | Univariate fixed-effect Poisson mean models for non-negative integer counts, with `mu` as the count mean. |
| `7` | `family = nbinom2()` | `drm_build_nbinom2_spec()` | Univariate negative-binomial 2 models for overdispersed counts, with `mu` as the count mean, `sigma` as an overdispersion scale, and optional ordinary `mu` random intercepts or independent numeric slopes on the log-mean predictor. |
| `8` | `family = poisson(link = "log")` plus `zi ~ ...` | `drm_build_poisson_spec()` | Univariate fixed-effect zero-inflated Poisson models, with `mu` as the conditional count mean and `zi` as the structural-zero probability. |
| `9` | `family = nbinom2()` plus `zi ~ ...` | `drm_build_nbinom2_spec()` | Univariate fixed-effect zero-inflated negative-binomial 2 models, with `mu` as the conditional count mean, `sigma` as the NB2 overdispersion scale, and `zi` as the structural-zero probability. |
| `10` | `family = beta()` | `drm_build_beta_ls_spec()` | Univariate fixed-effect beta mean-scale models for strict continuous proportions, with `mu` as the mean proportion and public `sigma` mapped internally to `phi = 1 / sigma^2`. |
| `11` | `family = truncated_nbinom2()` | `drm_build_truncated_nbinom2_spec()` | Univariate fixed-effect zero-truncated negative-binomial 2 models for positive counts, with `mu` and `sigma` describing the untruncated NB2 component. |
| `12` | `family = truncated_nbinom2()` plus `hu ~ ...` | `drm_build_truncated_nbinom2_spec()` | Univariate fixed-effect hurdle negative-binomial 2 models, with `hu` as the hurdle-zero probability and nonzero counts drawn from the zero-truncated NB2 component. |
| `13` | `family = cumulative_logit()` | `drm_build_cumulative_logit_spec()` | Univariate fixed-effect cumulative-logit ordinal location models, with ordered cutpoints and fixed latent logistic scale. |
| `14` | `family = beta_binomial()` | `drm_build_beta_binomial_spec()` | Univariate fixed-effect beta-binomial models for counted successes out of known trials, with `mu` as success probability and `sigma` as extra-binomial variation. |
| `93` | no public route | direct test construction only | Hidden q=4 phylogenetic precision-prior parity branch using `theta_phylo` and `log_sd_phylo`. |
| `94` | no public route | direct test construction only | Hidden q=4 correlated phylogenetic precision-prior parity branch used to test the matrix-normal sparse augmented A-inverse objective in isolation. |
| `95` | no public route | direct test construction only | Hidden q=4 bivariate Gaussian likelihood probe for labelled covariance-block contributions. |
| `96` | no public route | direct test construction only | Hidden univariate Gaussian likelihood probe for labelled covariance-block contributions. |
| `97` | no public route | direct test construction only | Hidden contribution-map probe for labelled covariance-block blocks and members. |
| `98` | no public route | direct test construction only | Hidden non-centred unstructured-correlation transform probe. |
| `99` | no public route | direct test construction only | Hidden phylogenetic precision-prior parity branch used to test the sparse augmented A-inverse objective in isolation. |

The hidden `model_type = 93` through `model_type = 99` branches are not families
and should not appear in user examples. Public phylogenetic Gaussian fits stay
on `model_type = 1` or `model_type = 2`; the hidden branches exist only so
tests can compare isolated sparse phylogenetic prior objectives, labelled
covariance-block contribution maps, and non-centred covariance transforms
against the R algebra helpers. The C++ modularization source map in
`docs/design/36-cpp-modularization-source-map.md` records how to keep those
hidden probes separate during future file-splitting work.

## Gaussian Aggregation Branch

When `drm_control(aggregate_gaussian = TRUE)` is used for the first supported
univariate Gaussian fixed-effect path, `model_type = 1` follows a
sufficient-statistic sub-branch. The R builder groups rows after model-row
filtering by the processed `mu` design row, processed `sigma` design row, and
offset state. TMB receives one row per aggregation cell:

```text
n_g, sum_y_g, sum_y2_g, X_mu_g, X_sigma_g
```

For cell `g`,

```text
mu_g = X_mu_g beta_mu
log(sigma_g) = X_sigma_g beta_sigma
```

and the negative log-likelihood contribution is:

```text
0.5 n_g log(2 pi)
  + n_g log(sigma_g)
  + 0.5 (sum_y2_g - 2 mu_g sum_y_g + n_g mu_g^2) / sigma_g^2
```

This is algebraically identical to summing independent Gaussian row
log-likelihoods within the cell. The first implementation rejects non-unit
likelihood weights, random effects, direct-SD formulas, structured effects,
known sampling covariance, bivariate models, non-Gaussian families, and
combined sparse fixed-effect matrices before TMB is called.

## Likelihood Weights

The top-level `weights =` argument supplies row log-likelihood multipliers,
not sampling variances. For independent-row likelihood branches, the TMB
template evaluates:

```text
nll = sum_i w_i {-log f(y_i | theta_i)}
```

where `w_i` is the processed weight after model-row filtering. For the
implemented bivariate Gaussian independent-row path, `w_i` belongs to the
complete response pair:

```text
nll = sum_i w_i {-log f([y1_i, y2_i]' | theta_i)}
```

Known sampling variances or sampling covariance still belong in
`meta_known_V(V = V)`. When `meta_known_V(V = V)` supplies a full dense
covariance matrix, `weights =` is rejected for now because the likelihood is a
joint multivariate block rather than a sum of independent row contributions.

## Implemented Gaussian Location-Scale

Gaussian location-scale is implemented for fixed-effect models and for
univariate Gaussian location random intercepts, labelled random intercepts,
independent numeric random slopes, and labelled or unlabelled ordinary
correlated random intercept-slope blocks, residual-scale random intercepts and
independent numeric random slopes in the univariate Gaussian `sigma` formula,
and random-effect scale models for one or more distinct unlabelled `mu` random
intercepts:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

With one or more simple random-effect terms in the location model:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + sum_j z_j[i] b_{j, g_j[i]}
sigma_i = exp(X_sigma[i, ] beta_sigma)
b_{j, g} = sd_j * u_{j, g}
u_{j, g} ~ Normal(0, 1)
sd_j = exp(theta_j)
```

For a random intercept, `z_j[i] = 1`. For a simple random slope written as
`(0 + x | id)`, `z_j[i] = x_i`.

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | site) + (0 + x1 | observer), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

For an ordinary correlated random intercept-slope block:

```text
mu_i = X_mu[i, ] beta_mu + b_0,g[i] + x_i b_1,g[i]

[b_0,g, b_1,g]' ~ MVN(0, Sigma_g)
Sigma_g =
  [sd0^2,          rho_re sd0 sd1;
   rho_re sd0 sd1, sd1^2]

u_g ~ Normal([0, 0]', I)
b_0,g = sd0 * u_0,g
b_1,g = sd1 * (rho_re * u_0,g + sqrt(1 - rho_re^2) * u_1,g)
rho_re = 0.999999 * tanh(eta_cor)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

or, with an explicit covariance-block label:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

Here `rho_re` is a group-level random-effect correlation. It is extracted via
`corpars$mu` and is not residual `rho12`. In the current univariate Gaussian
implementation, the middle label `p` is retained for naming and future
cross-formula covariance matching; the likelihood is otherwise the same as the
unlabelled `(1 + x1 | id)` block.

For coordinate-based spatial location models:

```text
mu_i = X_mu[i, ] beta_mu + s_site[i]
s ~ Normal(0, sd_spatial^2 K_coords)
K_coords[l, m] = exp(-d_lm / r)
r = median positive pairwise site distance
Q_coords = K_coords^{-1}
```

The TMB likelihood uses the same sparse-precision prior shape as the
phylogenetic random intercept path, with `Q_coords` replacing the tree-derived
precision and `log_sd_phylo` internally holding the spatial SD for the
single-field intercept implementation. The public output labels the term as
`spatial(1 | site)` and returns conditional effects in the `spatial_mu`
`ranef()` block. This is a small-data coordinate covariance foundation, not the
planned scalable SPDE/GMRF mesh implementation.

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + spatial(1 | site, coords = coords), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

For first-slice animal and lower-level relatedness location models:

```text
mu_i = X_mu[i, ] beta_mu + a_group[i]
a ~ Normal(0, sd_related^2 K)
Q = K^{-1}
```

`animal(1 | id, A = A)` and `relmat(1 | id, K = K)` accept covariance or
relatedness matrices. `animal(1 | id, Ainv = Ainv)` and
`relmat(1 | id, Q = Q)` accept inverse relatedness or precision matrices. The
matrix row and column names define the latent structured-effect levels, and
the observed grouping column must match those names. These routes reuse the
same sparse-precision TMB prior shape as the phylogenetic and spatial
intercept paths; the public output labels the conditional effects as
`animal_mu` or `relmat_mu`, even though the internal TMB parameter names remain
the generic structured-field names for this first slice.

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + animal(1 | id, Ainv = Ainv), sigma ~ x2),
  family = gaussian(),
  data = dat
)

drmTMB(
  bf(y ~ x1 + relmat(1 | line, Q = Q), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

Matching labelled bivariate `mu1`/`mu2` terms now use the same known precision
route to fit the first q=2 location covariance. Pedigree-to-Ainv construction,
structured slopes, `sigma` relatedness models, q=4 location-scale blocks,
predictor-dependent relatedness `corpair()` regression, and generic direct-SD
grammar remain planned until their likelihood, diagnostics, profile or
bootstrap interval story, simulation recovery tests, and examples exist.

The first spatial slope path keeps that covariance but uses two independent
fields:

```text
mu_i = X_mu[i, ] beta_mu + s0_site[i] + x_i s1_site[i]
s0 ~ Normal(0, sd_spatial_intercept^2 K_coords)
s1 ~ Normal(0, sd_spatial_slope^2 K_coords)
Cov(s0, s1) = 0 in this phase
```

The matching syntax is:

```r
drmTMB(
  bf(y ~ x1 + spatial(1 + depth | site, coords = coords), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

The public SD labels are `spatial(1 | site)` for the spatial intercept field and
`spatial(0 + depth | site)` for the spatial slope field. There is no
intercept-slope `corpair()` row for this slice.

Residual-scale random intercepts and independent numeric random slopes are
implemented on the log-`sigma` scale:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma + sum_j z_j[i] a_{j, g_j[i]}
a_jg = sd_sigma_j * v_jg
v_jg ~ Normal(0, 1)
sd_sigma_j = exp(theta_sigma_j)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2 + (1 | id) + (0 + w | id)),
  family = gaussian(),
  data = dat
)
```

This is residual-scale heterogeneity. It is distinct from random-effect scale
models such as `sd(id) ~ x_group`.

The implemented random-effect scale grammar can target one or more distinct
unlabelled univariate Gaussian `mu` random intercepts. For one target:

```text
y_ij | mu_ij, sigma_ij, b_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_j
log(sigma_ij) = X_sigma[ij, ] beta_sigma

b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
sd_mu_id,j = exp(W_id[j, ] alpha_id)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2, sd(id) ~ x_group),
  family = gaussian(),
  data = dat
)
```

The right-hand side of `sd(id) ~ x_group` is evaluated once per `id` level.
Predictors must be constant within `id` after missing-row filtering. This
models among-group variation in the location random intercept; it is not a
residual-scale model and it is not a second `sigma` formula.

The implemented bivariate Gaussian direct-SD model uses response-specific
location random-effect SD formulas:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
mu1_i = X_mu1[i, ] beta_mu1 + b1[id_i]
mu2_i = X_mu2[i, ] beta_mu2 + b2[id_i]
[u1_j, u2_j]' ~ Normal([0, 0]', R_group)
b1_j = sd_mu1_id,j u1_j
b2_j = sd_mu2_id,j u2_j
log(sd_mu1_id,j) = W1_id[j, ] alpha1
log(sd_mu2_id,j) = W2_id[j, ] alpha2
```

Matching R syntax:

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

`sd1(id)` targets the `mu1` location random-effect SD and `sd2(id)` targets
the `mu2` location random-effect SD. These are Family B direct
variance-component scale models, not residual `sigma1` / `sigma2` models and
not SD regressions for random effects inside the scale formulas.

For several distinct random-intercept targets, the likelihood uses the same
non-centered construction for each component:

```text
mu_i = X_mu[i, ] beta_mu + b_id[id_i] + b_site[site_i]
b_id[j] = sd_mu_id,j u_id,j
b_site[k] = sd_mu_site,k u_site,k
u_id,j, u_site,k ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
log(sd_mu_site,k) = W_site[k, ] alpha_site
```

Matching R syntax:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | id) + (1 | site),
    sigma ~ x2,
    sd(id) ~ x_group,
    sd(site) ~ site_type
  ),
  family = gaussian(),
  data = dat
)
```

Residuals are not part of the formula grammar. They are computed downstream
from the fitted likelihood.

Implementation notes:

- TMB template: `src/drmTMB.cpp`.
- R builder: `R/drmTMB.R`.
- Positive `sigma` uses `log(sigma_i) = X_sigma beta_sigma`.
- Simulation recovery tests live in
  `tests/testthat/test-gaussian-location-scale.R`.
- Random-effect recovery tests live in
  `tests/testthat/test-gaussian-random-intercepts.R`.
- Random-effect scale recovery tests live in
  `tests/testthat/test-gaussian-random-effect-scale.R`.
- Comparator tests against `lme4` for overlapping Gaussian ML random-effect
  models live in `tests/testthat/test-comparators.R`.
- The univariate likelihood supports optional known sampling covariance via
  `meta_known_V(V = V)`. It has no residual correlation parameter.

## Implemented Meta-Analytic Gaussian Regression

Meta-analysis uses the ordinary Gaussian family plus known sampling covariance.
It is not a separate family.

```text
y ~ MVN(mu, V_known + Sigma_unknown)
```

For diagonal `V`, written as `meta_known_V(V = vi)` in the location formula:

```text
y_i ~ Normal(mu_i, vi_i + sigma_i^2)
log(sigma_i) = X_sigma beta_sigma
```

For dense full or block-diagonal `V`, the implemented likelihood is:

```text
y ~ MVN(mu, V + diag(sigma_i^2))
```

Implementation notes:

- `vi` means known sampling variances, not known standard errors.
- A vector or data column supplies diagonal known sampling variances.
- A matrix supplies dense known sampling covariance and must be symmetric
  positive semidefinite after retained-row subsetting.
- `sigma_i` is the extra heterogeneity SD after known sampling error is added.
- `meta_known_V()` must be treated as a covariance marker, not as an ordinary
  fixed-effect predictor.
- The marker is removed before model-matrix construction.
- `predict(fit, dpar = "sigma")` returns the unknown heterogeneity SD;
  likelihood, Pearson residuals, and simulation include the known covariance.
- Simulation, missing-row, and likelihood-agreement tests with known `vi` and
  full `V` live in
  `tests/testthat/test-meta-known-v.R`.
- Sparse known covariance is planned for larger phylogenetic and spatial
  workloads.

In meta-analysis prose, `sigma` is the extra heterogeneity SD traditionally
called `tau`. The public API still uses `sigma` for consistency.

## Implemented Student-t Location-Scale-Shape

The first robust continuous likelihood is fixed-effect Student-t regression:

```text
y_i | mu_i, sigma_i, nu_i ~ Student-t(mu_i, sigma_i, nu_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_nu_i = X_nu[i, ] beta_nu
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
nu_i = 2 + exp(eta_nu_i)
```

The TMB likelihood includes all Student-t normalizing constants:

```text
z_i = (y_i - mu_i) / sigma_i
log f(y_i) =
  lgamma((nu_i + 1) / 2) - lgamma(nu_i / 2)
  - 0.5 log(nu_i pi) - log(sigma_i)
  - 0.5 (nu_i + 1) log(1 + z_i^2 / nu_i)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3),
  family = student(),
  data = dat
)
```

This first implementation deliberately rejects random effects, known sampling
covariance, phylogenetic terms, and bivariate Student-t families until the
fixed-effect likelihood and recovery tests remain stable.

For applied examples, the runnable Student-t question is a sensitivity question:
do conclusions about the location `mu` and scale `sigma` change when the
likelihood estimates the tail-shape parameter `nu` rather than assuming
Gaussian residual tails? The fitted fallback for planned skew-normal models is
this Student-t comparison plus the Gaussian location-scale model; it is not
evidence for residual asymmetry.

## Planned Skew-Normal Location-Scale-Shape Gate

The future skew-normal path is for continuous responses where residual
asymmetry is part of the scientific question. It is not implemented yet. The
candidate first implementation uses the Azzalini-style skew-normal density,
with drmTMB's first shape parameter `nu` mapped to the native asymmetry shape:

```text
y_i | mu_i, sigma_i, nu_i ~ SkewNormal(mu_i, sigma_i, nu_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_nu_i = X_nu[i, ] beta_nu
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
nu_i = eta_nu_i
z_i = (y_i - mu_i) / sigma_i
log f(y_i) = log(2) - log(sigma_i) + log phi(z_i) + log Phi(nu_i z_i)
```

Here `phi()` and `Phi()` are the standard normal density and distribution
function. The sign convention is part of the proposed public contract:
`nu_i = 0` gives the Gaussian location-scale likelihood, `nu_i > 0` gives
right-skewed residuals, and `nu_i < 0` gives left-skewed residuals. This sign
mapping must be checked against the trusted comparator before implementation.

The native `mu_i` above is the skew-normal location parameter, not the
arithmetic response mean when `nu_i != 0`. If the family returns arithmetic
means from `fitted()`, the implementation must use:

```text
delta_i = nu_i / sqrt(1 + nu_i^2)
E[y_i] = mu_i + sigma_i delta_i sqrt(2 / pi)
Var[y_i] = sigma_i^2 * (1 - 2 delta_i^2 / pi)
```

Matching future R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3),
  family = skew_normal(),
  data = dat
)
```

The first implementation should be fixed-effect and univariate. It should
start with intercept-only or simple fixed-effect `nu` formulas, reject random
effects in `sigma` or `nu`, and reject bivariate, `rho12`,
`meta_V(V = V)`/`meta_known_V(V = V)`, `phylo()`, and `spatial()` paths until
separate recovery, normal-limit, false-positive heteroscedasticity, and
comparator tests exist. Treat this section as an implementation gate for issue
#3, not as evidence that `skew_normal()` is available.

Until that gate is complete, user examples should use only planned syntax:

```r
# Planned, not fitted yet:
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3),
  family = skew_normal(),
  data = dat
)
```

The next fitted action is to run Gaussian and Student-t sensitivity models,
then state that skewness remains unmodelled. Do not present `nu ~ x` under
`skew_normal()` as runnable until the density branch, prediction contract,
profile targets, diagnostics, and recovery tests exist.

## Planned Skew-T Shape Gate

The future skew-t path should come after the skew-normal gate because it has
two shape dimensions that can trade off: residual asymmetry and tail weight.
`tau` is reserved for a second shape parameter but is not current formula
syntax. Before implementation, choose one skew-t density, name its native
parameters, and decide whether `nu` controls asymmetry and `tau` controls tail
thickness:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3, tau ~ x4),
  family = skew_t(),
  data = dat
)
```

This example is planned syntax only. A fitted skew-t route needs density
comparators, skew-normal or Student-t limit checks, recovery for `sigma ~ x`,
`nu ~ x`, and `tau ~ x`, and false-positive checks showing that skewness,
tail thickness, heteroscedasticity, outliers, and ordinary random effects are
not being conflated.

## Implemented Lognormal Location-Scale

The first positive continuous likelihood is fixed-effect lognormal regression:

```text
log(y_i) | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
```

The TMB likelihood is evaluated on the original positive response scale with
the log-Jacobian term:

```text
log_y_i = log(y_i)
log f(y_i) =
  log Normal(log_y_i | mu_i, sigma_i^2) - log_y_i
```

The arithmetic response mean is:

```text
E[y_i] = exp(mu_i + sigma_i^2 / 2)
```

Matching R syntax:

```r
drmTMB(
  bf(biomass ~ habitat, sigma ~ treatment),
  family = lognormal(),
  data = dat
)
```

For lognormal fits, `predict(fit, dpar = "mu")` returns the log-scale
location parameter, `sigma(fit)` returns the log-scale standard deviation, and
`fitted(fit)` returns `E[y_i]` on the original response scale. The response
must be positive and finite after missing-row filtering. Random effects, known
sampling covariance, phylogenetic terms, and bivariate lognormal models are
later phases.

## Implemented Gamma Mean-CV

The first Gamma path is fixed-effect mean-CV regression:

```text
y_i | mu_i, sigma_i ~ Gamma(shape_i, scale_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
shape_i = 1 / sigma_i^2
scale_i = mu_i * sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i^2 sigma_i^2
```

The TMB likelihood is:

```text
log f(y_i) =
  (shape_i - 1) log(y_i) - y_i / scale_i -
  log Gamma(shape_i) - shape_i log(scale_i)
```

Matching R syntax:

```r
drmTMB(
  bf(biomass ~ habitat, sigma ~ treatment),
  family = Gamma(link = "log"),
  data = dat
)
```

For Gamma fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the
response mean. `sigma(fit)` returns the coefficient of variation, not the
residual standard deviation; the fitted residual standard deviation is
`mu_i * sigma_i`. The response must be positive and finite after missing-row
filtering. Random effects, known sampling covariance, phylogenetic terms, and
bivariate or mixed Gamma models are later phases.

## Planned Tweedie Mean-Scale-Shape Gate

The future Tweedie path is for non-negative semicontinuous responses with exact
zeros and positive continuous values. It is not implemented yet. The current
working public-scale contract is:

```text
y_i | mu_i, sigma_i, nu_i ~ Tweedie(mu_i, phi_i, nu_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_nu_i = X_nu[i, ] beta_nu
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
phi_i = sigma_i^2
nu_i = 1 + exp(eta_nu_i) / (1 + exp(eta_nu_i))
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

The likelihood must include the Tweedie density normalizing terms, not only the
mean-variance relationship. The first comparator should be
`glmmTMB::tweedie(link = "log")`, which reports Tweedie dispersion `phi`; tests
against that scale should compare `sigma_i^2` with `phi_i` and name the
transform explicitly.

Matching future R syntax:

```r
drmTMB(
  bf(biomass ~ habitat, sigma ~ habitat, nu ~ 1),
  family = tweedie(),
  data = dat
)
```

The first implementation should be fixed-effect and univariate, with
intercept-only `nu ~ 1` before predictor-dependent power models. It should
reject negative responses, random effects in `sigma` or `nu`, bivariate
Tweedie families, `rho12`, `meta_known_V(V = V)`, and phylogenetic or spatial
terms until separate recovery and comparator tests exist. The implementation
gate is in `docs/design/27-tweedie-family-plan.md`.

## Implemented Beta Mean-Scale

The first beta path is fixed-effect mean-scale regression for strict
continuous proportions:

```text
y_i | mu_i, sigma_i ~ Beta(alpha_i, beta_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = logit^{-1}(eta_mu_i)
sigma_i = exp(eta_sigma_i)
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i] = mu_i
Var[y_i] = mu_i (1 - mu_i) sigma_i^2 / (1 + sigma_i^2)
```

The TMB likelihood is:

```text
log f(y_i) =
  log Gamma(phi_i) - log Gamma(alpha_i) - log Gamma(beta_i) +
  (alpha_i - 1) log(y_i) + (beta_i - 1) log(1 - y_i)
```

Matching R syntax:

```r
drmTMB(
  bf(prop ~ habitat, sigma ~ treatment),
  family = beta(),
  data = dat
)
```

For beta fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the mean
proportion. `sigma(fit)` returns the public scale parameter, not beta
precision; internally `phi_i = 1 / sigma_i^2`. The response must be finite and
strictly between 0 and 1 after missing-row filtering. Boundary responses,
random effects, known sampling covariance, phylogenetic terms, and bivariate
or mixed beta models are later phases.

## Implemented Beta-Binomial Mean-Overdispersion

Beta-binomial models keep the denominator in the likelihood:

```text
y_i | n_i, p_i ~ Binomial(n_i, p_i)
p_i | mu_i, sigma_i ~ Beta(alpha_i, beta_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = logit^{-1}(eta_mu_i)
sigma_i = exp(eta_sigma_i)
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i / n_i] = mu_i
Var(y_i / n_i) =
  mu_i (1 - mu_i) (1 + n_i sigma_i^2) /
  (n_i (1 + sigma_i^2))
```

The TMB likelihood is:

```text
log Pr(y_i | n_i, mu_i, sigma_i) =
  log Gamma(n_i + 1) - log Gamma(y_i + 1) -
  log Gamma(n_i - y_i + 1) +
  log Gamma(phi_i) - log Gamma(n_i + phi_i) +
  log Gamma(y_i + alpha_i) - log Gamma(alpha_i) +
  log Gamma(n_i - y_i + beta_i) - log Gamma(beta_i)
```

Matching R syntax:

```r
drmTMB(
  bf(cbind(successes, failures) ~ habitat, sigma ~ treatment),
  family = beta_binomial(),
  data = dat
)
```

For beta-binomial fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return
the success probability. `sigma(fit)` returns the public extra-binomial
variation scale; internally `phi_i = 1 / sigma_i^2`. The response counts must
be finite non-negative integers with positive row totals after missing-row
filtering. Random effects, known sampling covariance, phylogenetic terms,
bivariate or mixed beta-binomial models, and a possible successes/trials
response alias are later phases.

## Implemented Cumulative-Logit Ordinal Location

The first ordinal path is fixed-effect, univariate, and location-only:

```text
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
mu_i = X_mu[i, ] beta_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

The response is represented internally by integer category scores
`1, ..., K`. Ordered factor labels are retained on the fitted object so
simulation can return ordered categories with the original labels. The
location intercept is removed before fitting because a free intercept and free
cutpoints are not jointly identifiable; factor predictors keep ordinary
treatment-contrast columns after the intercept column is dropped.

For category `k`, the TMB branch evaluates:

```text
Pr(y_i = 1) = F(theta_1 - mu_i)
Pr(y_i = k) = F(theta_k - mu_i) - F(theta_{k-1} - mu_i), 1 < k < K
Pr(y_i = K) = 1 - F(theta_{K-1} - mu_i)
```

where `F(a) = logit^{-1}(a)`. The middle-category log probabilities use a
`log(1 - exp(x))` helper on the log-CDF scale so close cutpoints do not lose
the likelihood contribution to cancellation.

Matching R syntax:

```r
drmTMB(
  bf(score ~ habitat),
  family = cumulative_logit(),
  data = dat
)
```

For cumulative-logit fits, `predict(fit, dpar = "mu")` returns the latent
ordinal location. `fitted(fit)` returns the expected ordered-category score
`sum_k k * Pr(y_i = k)`, which is useful as a fitted response summary but is
not a measured continuous outcome. `sigma(fit)` returns a fixed unit vector
because this MVP fixes the latent logistic scale. Ordinal scale or
discrimination formulas, random effects, known sampling covariance,
phylogenetic terms, bivariate ordinal models, and mixed-response ordinal
models are later phases.

## Implemented Poisson Mean

The first count path is fixed-effect mean regression:

```text
y_i | mu_i ~ Poisson(mu_i)
eta_mu_i = o_i + X_mu[i, ] beta_mu
mu_i = exp(eta_mu_i)
E[y_i] = Var[y_i] = mu_i
```

For exposure or effort models, `o_i` is the known offset supplied by standard
R syntax such as `offset(log(trap_nights))`. If no offset is present,
`o_i = 0`.

The TMB likelihood is:

```text
log f(y_i) = y_i log(mu_i) - mu_i - log(y_i!)
```

Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat + offset(log(trap_nights))),
  family = poisson(link = "log"),
  data = dat
)
```

For Poisson fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the
count mean. There is no fitted `sigma` distributional parameter; `sigma(fit)`
returns a fixed unit dispersion vector for compatibility with base-R method
expectations. The response must contain non-negative integer counts after
missing-row filtering. Random effects, known sampling covariance,
overdispersion, phylogenetic terms, and bivariate or mixed Poisson models are
later phases.

## Implemented Zero-Inflated Poisson Mean

Zero-inflated Poisson models reuse the ordinary Poisson family route and add a
formula for the structural-zero probability:

```text
y_i | mu_i, zi_i ~ zero-inflated Poisson(mu_i, zi_i)
eta_mu_i = o_i + X_mu[i, ] beta_mu
eta_zi_i = X_zi[i, ] beta_zi
mu_i = exp(eta_mu_i)
zi_i = logit^{-1}(eta_zi_i)
```

The probability mass is:

```text
Pr(y_i = 0) = zi_i + (1 - zi_i) exp(-mu_i)
Pr(y_i = y > 0) = (1 - zi_i) Poisson(y | mu_i)
E[y_i] = (1 - zi_i) mu_i
Var[y_i] = (1 - zi_i) mu_i (1 + zi_i mu_i)
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat + offset(log(trap_nights)), zi ~ treatment),
  family = poisson(link = "log"),
  data = dat
)
```

Here `mu` is the conditional count mean among observations that are not
structural zeros. The structural-zero probability is `zi`, not a scale
parameter. Consequently, `predict(fit, dpar = "mu")` returns the conditional
mean, `predict(fit, dpar = "zi")` returns the zero-inflation probability, and
`fitted(fit)` returns the unconditional response mean `(1 - zi) * mu`.
`sigma(fit)` returns a fixed unit dispersion vector because no residual scale
parameter is fitted.

## Implemented Negative Binomial 2 Mean-Dispersion

The first overdispersed count path is fixed-effect NB2 regression:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
eta_mu_i = o_i + X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
size_i = 1 / sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i + sigma_i^2 * mu_i^2
```

The TMB likelihood matches the `stats::dnbinom(mu = mu_i, size = size_i)`
mean parameterization:

```text
log f(y_i) =
  log Gamma(y_i + size_i) - log Gamma(size_i) - log Gamma(y_i + 1) +
  size_i [log(size_i) - log(size_i + mu_i)] +
  y_i [log(mu_i) - log(size_i + mu_i)]
```

The C++ template evaluates an algebraically equivalent form that cancels the
unstable `size_i = 1 / sigma_i^2` terms. With
`alpha_i = sigma_i^2`, it uses

```text
log f(y_i) =
  y_i eta_mu_i - log Gamma(y_i + 1)
  + C(y_i, alpha_i)
  - y_i log(1 + alpha_i mu_i)
  - log(1 + alpha_i mu_i) / alpha_i
```

where

```text
C(y_i, alpha_i) =
  sum_{j = 0}^{y_i - 1} log(1 + alpha_i j)
```

The template evaluates `C(y_i, alpha_i)` without an observed-count loop. For
ordinary count and overdispersion values it uses the closed form

```text
C(y_i, alpha_i) =
  log Gamma(y_i + 1 / alpha_i) -
  log Gamma(1 / alpha_i) +
  y_i log(alpha_i).
```

When `alpha_i y_i` is very small, the template uses the matching power-sum
series for `sum log(1 + alpha_i j)` to preserve the Poisson limit.

This form has the correct Poisson limit as `alpha_i` approaches zero and avoids
overflow from computing very large `size_i` or looping over very large observed
counts.

Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat + offset(log(trap_nights)), sigma ~ treatment),
  family = nbinom2(),
  data = dat
)
```

For `nbinom2()` fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the
count mean. `sigma(fit)` returns the overdispersion scale in the variance
equation, not a residual standard deviation. Larger `sigma` means greater
extra-Poisson variation. Ordinary `mu` random intercepts and independent
numeric slopes are fitted for non-zero-inflated NB2 models. Correlated NB2
slope blocks, labelled covariance blocks, NB2 `sigma` random effects,
zero-inflated NB2 random effects, known sampling covariance, phylogenetic terms,
and bivariate or mixed negative-binomial models are later phases.

## Implemented Zero-Truncated Negative Binomial 2

The positive-count NB2 path is fixed-effect zero-truncated regression:

```text
y_i | y_i > 0, mu_i, sigma_i ~ NB2(mu_i, size_i) truncated at zero
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
size_i = 1 / sigma_i^2
Z_i = 1 - NB2(0 | mu_i, size_i)
Pr(y_i = k | y_i > 0) = NB2(k | mu_i, size_i) / Z_i
E[y_i | y_i > 0] = mu_i / Z_i
```

The TMB branch reuses the AD-stable NB2 log-density and subtracts the
normalising constant:

```text
log f_trunc(y_i) = log f_NB2(y_i) - log(Z_i)
```

where `log(Z_i) = log(1 - exp(log Pr_NB2(0)))` is evaluated with a small
`log(1 - exp(x))` helper to avoid cancellation when almost all mass is at
zero. Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat, sigma ~ treatment),
  family = truncated_nbinom2(),
  data = dat
)
```

For `truncated_nbinom2()` fits, `predict(fit, dpar = "mu")` returns the
untruncated NB2 component mean, `sigma(fit)` returns the NB2 overdispersion
scale, and `fitted(fit)` returns the observed positive-count mean
`mu / (1 - Pr_NB2(0))`. The response must contain positive integer counts
after missing-row filtering unless a hurdle formula is supplied.

## Implemented Hurdle Negative Binomial 2

Hurdle NB2 models reuse `truncated_nbinom2()` and add a formula for the
hurdle-zero probability:

```text
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_hu_i = X_hu[i, ] beta_hu
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
hu_i = logit^{-1}(eta_hu_i)
size_i = 1 / sigma_i^2
Z_i = 1 - NB2(0 | mu_i, size_i)
```

The probability mass is:

```text
Pr(y_i = 0) = hu_i
Pr(y_i = k > 0) = (1 - hu_i) NB2(k | mu_i, size_i) / Z_i
E[y_i] = (1 - hu_i) mu_i / Z_i
```

The response variance used by Pearson residuals is the mixture variance:

```text
m_i = mu_i / Z_i
v_i = Var_NB2(y_i | y_i > 0, mu_i, sigma_i)
Var(y_i) = (1 - hu_i) v_i + hu_i (1 - hu_i) m_i^2
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat, sigma ~ treatment, hu ~ survey_method),
  family = truncated_nbinom2(),
  data = dat
)
```

Here `mu` and `sigma` continue to describe the untruncated NB2 component.
`predict(fit, dpar = "hu")` returns the hurdle-zero probability. `fitted(fit)`
returns the unconditional response mean `(1 - hu) * mu / (1 - Pr_NB2(0))`.
Zeros are allowed only when the `hu` formula is present, and at least one
positive count must remain after missing-row filtering.

## Implemented Zero-Inflated Negative Binomial 2

Zero-inflated NB2 models reuse `nbinom2()` and add a formula for the
structural-zero probability:

```text
y_i | mu_i, sigma_i, zi_i ~ zero-inflated NB2(mu_i, sigma_i, zi_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_zi_i = X_zi[i, ] beta_zi
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
zi_i = logit^{-1}(eta_zi_i)
size_i = 1 / sigma_i^2
```

The probability mass is:

```text
Pr(y_i = 0) = zi_i + (1 - zi_i) NB2(0 | mu_i, size_i)
Pr(y_i = y > 0) = (1 - zi_i) NB2(y | mu_i, size_i)
E[y_i] = (1 - zi_i) mu_i
Var[y_i] = (1 - zi_i) (mu_i + sigma_i^2 mu_i^2) + zi_i (1 - zi_i) mu_i^2
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat, sigma ~ treatment, zi ~ survey_method),
  family = nbinom2(),
  data = dat
)
```

Here `mu` is the conditional NB2 mean among observations that are not
structural zeros, `sigma` is the conditional NB2 overdispersion scale, and `zi`
is the structural-zero probability. Consequently, `predict(fit, dpar = "mu")`
returns the conditional mean, `sigma(fit)` returns the conditional
overdispersion scale, `predict(fit, dpar = "zi")` returns the zero-inflation
probability, and `fitted(fit)` returns `(1 - zi) * mu`.

## Implemented Bivariate Meta-Analytic Gaussian Regression

Bivariate meta-analysis must add known sampling covariance to the bivariate
Gaussian location-coscale likelihood. For observation or study `i`:

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
```

`S_i` is known within-study sampling covariance supplied by
`meta_known_V(V = V)`. `Omega_i` is the unknown residual heterogeneity
covariance after known sampling covariance has been included. The fitted
`rho12_i` is not the known within-study sampling correlation; it should only be
called study-level if a separate study-level random effect is fitted.

Equivalently, with row-paired stacking:

```text
y_stack = [y1_1, y2_1, y1_2, y2_2, ..., y1_n, y2_n]'
y_stack ~ MVN(mu_stack, V_stack + Omega_stack)
```

where `V_stack` is the supplied known sampling covariance and `Omega_stack`
contains the fitted `sigma1`, `sigma2`, and `rho12` blocks.

The current implementation:

- requires complete bivariate rows;
- accepts a `2n` by `2n` dense or block-diagonal `V` in row-paired order;
- rejects duplicate `meta_known_V()` markers across `mu1` and `mu2`;
- provides `meta_vcov_bivariate()` to build the common block-diagonal `V` from
  `v1`, `v2`, and
  either `cov12` or `cor12`;
- documents sensitivity analysis when within-study correlations are unknown.

## Implemented Bivariate Gaussian Location-Coscale

Bivariate Gaussian location-coscale:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
mu1_i = X_mu1[i, ] beta_mu1 + b1_group[i]
mu2_i = X_mu2[i, ] beta_mu2 + b2_group[i]
log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = tanh(eta_rho12_i)
Omega_i[1,1] = sigma1_i^2
Omega_i[2,2] = sigma2_i^2
Omega_i[1,2] = rho12_i * sigma1_i * sigma2_i
```

For fixed-effect models, `b1_group[i]` and `b2_group[i]` are zero. With matching
labelled random-intercept terms in `mu1` and `mu2`, they come from a
group-level covariance block:

```text
[b1_j, b2_j]' = diag(sd_mu1_id, sd_mu2_id) L_group [u1_j, u2_j]'
[u1_j, u2_j]' ~ Normal([0, 0]', I)
L_group =
  [1,          0;
   rho_group, sqrt(1 - rho_group^2)]
rho_group = 0.999999 * tanh(eta_cor_mu)
```

With matching `phylo(1 | species, tree = tree)` terms in `mu1` and `mu2`,
the two phylogenetic mean deviations use the same augmented tree precision and
a two-state covariance matrix:

```text
a = [a_mu1, a_mu2]
a ~ MatrixNormal(0, Q_A^{-1}, Sigma_phylo)
Sigma_phylo =
  [sd_phylo_mu1^2, rho_phylo * sd_phylo_mu1 * sd_phylo_mu2;
   rho_phylo * sd_phylo_mu1 * sd_phylo_mu2, sd_phylo_mu2^2]
rho_phylo = 0.999999 * tanh(eta_cor_phylo)

mu1_i = X_mu1[i, ] beta_mu1 + a_mu1[species_i]
mu2_i = X_mu2[i, ] beta_mu2 + a_mu2[species_i]
```

Here `rho_phylo` is a phylogenetic mean-mean correlation, not residual
`rho12`. In this first fitted slice, `sigma1`, `sigma2`, and `rho12` remain
ordinary fixed-effect distributional parameters.

With labelled all-four phylogenetic terms, the same augmented tree precision
can carry four endpoint deviations:

```text
a = [a_mu1, a_mu2, a_sigma1, a_sigma2]
a ~ MatrixNormal(0, Q_A^{-1}, Sigma_phylo_q4)

mu1_i = X_mu1[i, ] beta_mu1 + a_mu1[species_i]
mu2_i = X_mu2[i, ] beta_mu2 + a_mu2[species_i]
log(sigma1_i) = X_sigma1[i, ] beta_sigma1 + a_sigma1[species_i]
log(sigma2_i) = X_sigma2[i, ] beta_sigma2 + a_sigma2[species_i]
```

If all four endpoints use the same label, `Sigma_phylo_q4` is one
unstructured four-endpoint covariance matrix and `corpairs()` reports six
phylogenetic rows. If `mu1`/`mu2` share one label and `sigma1`/`sigma2` share
another label for the same tree, `Sigma_phylo_q4` is block diagonal:

```text
Sigma_phylo_q4 =
  blockdiag(Sigma_phylo_location, Sigma_phylo_scale)
```

The block-diagonal fallback reports only the mean-mean and scale-scale
phylogenetic correlations. It deliberately omits mean-scale phylogenetic rows,
which is useful when a full q=4 block is too weakly identified but the protocol
still needs a phylogenetic scale-scale check.

The TMB implementation uses tiny boundary guards around `tanh()` for numerical
positive definiteness; the clean transforms above are the statistical model.

Location formulas for the two responses may differ. `rho12` is residual
response-response correlation, not a group-level random-effect correlation.

Implemented fixed-effect syntax:

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

Implemented bivariate group-level random-intercept syntax:

```r
drmTMB(
  formula = bf(
    mu1 = y1 ~ x1 + x2 + (1 | p | ID),
    mu2 = y2 ~ x1      + (1 | p | ID),
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

Here the shared `p` label says that the two response-specific random intercepts
belong to one group-level covariance block. The model reports
`sdpars$mu["mu1:(1 | p | ID)"]`, `sdpars$mu["mu2:(1 | p | ID)"]`, and
`corpars$mu["cor(mu1:(Intercept),mu2:(Intercept) | p | ID)"]`.

Planned double-hierarchical bivariate syntax with random slopes and scale
random effects:

```r
drmTMB(
  formula = bf(
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

Here `sigma1` and `sigma2` are residual scales. Random-intercept and
random-slope standard deviations from the mean block are group-level scale
components and should be exposed separately.

For example, a future correlated random-intercept and random-slope block in
the two mean formulas would add:

```text
mu1_ij = X_mu1[ij, ] beta_mu1 + b_0_1j + b_x_1j x_ij
mu2_ij = X_mu2[ij, ] beta_mu2 + b_0_2j + b_x_2j x_ij
[b_0_1j, b_x_1j, b_0_2j, b_x_2j]' ~ MVN(0, Sigma_mu_ID)
```

The correlations inside `Sigma_mu_ID` are group-level correlations among
random effects. They are not residual `rho12`, and the first implementation
should estimate them as constant covariance-block quantities rather than
predictor-dependent `rho12` formulae.

Implementation notes:

- TMB template: `src/drmTMB.cpp`.
- R builder: `R/drmTMB.R`.
- Positive `sigma1` and `sigma2` use log links.
- `rho12` uses `eta_rho12 = X_rho12 beta_rho12` and a bounded tanh transform
  `rho12 = 0.99999999 * tanh(eta_rho12)` on the response scale so the
  covariance matrix stays positive definite even for extreme linear predictors.
- Simulation recovery tests live in `tests/testthat/test-biv-gaussian.R`.
- `mvbind(y1, y2) ~ x` is implemented as a formula shorthand that creates
  identical `mu1` and `mu2` design matrices.
- Dense known sampling covariance is implemented for complete-row bivariate
  Gaussian models through `meta_known_V(V = V)`, where `V` is a row-paired
  `2n` by `2n` matrix added to the fitted residual covariance.
- Matching labelled random intercepts in `mu1`/`mu2` and `sigma1`/`sigma2` are
  implemented as same-parameter group-level covariance blocks. They cannot yet
  be combined with `meta_known_V(V = V)`.
- One same-response `mu`/`sigma` random-intercept covariance pair is implemented
  for `mu1` with `sigma1` or `mu2` with `sigma2`.
- Reusing the same label in all four `mu1`, `mu2`, `sigma1`, and `sigma2`
  random-intercept formulas fits one ordinary q=4 latent covariance block:

  ```text
  u_j = [b_mu1_j, b_mu2_j, a_sigma1_j, a_sigma2_j]'
  u_j ~ MVN(0, Sigma_id)
  ```

  The `a_sigma*` entries enter `log(sigma*)`, so their SDs and correlations
  live on the residual-scale linear-predictor scale. The six correlations in
  `Sigma_id` are group-level latent correlations and remain separate from
  residual `rho12`.
- Family B direct location-SD formulas such as `sd1(id) ~ x_group` and
  `sd2(id) ~ x_group` are rejected for the same group when this q=4 block is
  present. Combining them would require a predictor-dependent q=4 covariance
  model, not the current constant q=4 block.
- The univariate Family B `sd_phylo(species) ~ x_species` model uses a
  non-centred tip-scaling contract. A unit phylogenetic base effect `v_aug`
  follows the sparse augmented tree precision, while the observed tip
  contribution is multiplied by `tau_l = exp(W_l alpha)`. The implied tip
  covariance is `D_tip A_tip D_tip`; internal nodes do not receive
  user-facing SD predictors. This direct-SD formula replaces the scalar
  `log_sd_phylo` target for the univariate location `phylo()` effect rather
  than adding a second SD layer.
- The implemented bivariate Family B direct-SD extension uses
  `sd_phylo1(species) ~ z1` for the `mu1` phylogenetic location-effect SD and
  `sd_phylo2(species) ~ z2` for the `mu2` phylogenetic location-effect SD. With
  a constant latent phylogenetic location-location correlation `rho_phylo`, the
  cross-response tip covariance is
  `Cov(a1_l, a2_m) = rho_phylo tau1_l A_lm tau2_m`. These formulas replace
  endpoint location SD parameters only; they do not target residual `sigma1`,
  residual `sigma2`, q=4 location-scale endpoint SDs, or residual `rho12`.
- Bivariate random slopes, `rho12` random effects, phylogenetic random slopes,
  predictor-dependent q=4 phylogenetic correlations, and spatial q=4 blocks
  remain planned. The first constant intercept-only bivariate phylogenetic q=4
  block is implemented for matching labelled `phylo()` terms in `mu1`, `mu2`,
  `sigma1`, and `sigma2`. It supports the full one-label q=4 block and the
  two-label block-diagonal fallback with one location block and one scale
  block.
- The selected q=2 predictor-dependent phylogenetic `corpair()` contract uses
  two independent unit tree fields and species-specific loadings. For each
  species `l`, `rho_l = tanh_guard(W_l alpha)`,
  `c_l = sqrt((1 + rho_l) / 2)`, and
  `d_l = sqrt((1 - rho_l) / 2)`, with
  `a1_l = tau1(c_l z1_l + d_l z2_l)` and
  `a2_l = tau2(c_l z1_l - d_l z2_l)`. This guarantees a positive-definite
  full phylogenetic covariance and reduces to the implemented constant
  bivariate phylogenetic covariance when `rho_l` is constant. The fitted
  implementation uses two independent unit augmented-tree effects and applies
  the loading transformation at observed tip nodes. This contract targets
  `mu1`-`mu2` only; predictor-dependent phylogenetic location-scale and
  scale-scale correlations require a q=4 contract.

## Review Requirements

Every likelihood must have simulation recovery tests before being treated as
implemented.
