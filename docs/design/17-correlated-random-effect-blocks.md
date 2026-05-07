# Correlated Random-Effect Blocks

This note records the design target for ordinary correlated Gaussian `mu`
random-effect blocks. It is not implemented yet. The current implementation
supports independent random-effect terms such as `(1 | id)` and
`(0 + x | id)`.

## User Grammar

Keep ordinary mixed-model syntax familiar:

```r
bf(y ~ x + (1 + x | id), sigma ~ z)
```

This should mean a correlated random intercept and random slope for `x` within
`id`, matching the usual `lme4` and `glmmTMB` meaning.

Keep the current independent syntax unchanged:

```r
bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z)
```

This means two independent variance components: one random intercept SD and one
random slope SD, with no intercept-slope correlation.

Labelled blocks should later support cross-formula or cross-parameter
covariance:

```r
bf(
  mu = y ~ x + (1 + x | p | id),
  sigma = ~ z + (1 | p | id)
)
```

Here `p` is a covariance-block label. It is not a grouping variable and it is
not residual `rho12`.

## Symbolic Model

For the first correlated block:

```text
y_ij | mu_ij, sigma_ij ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_0j + x_ij b_1j
log(sigma_ij) = X_sigma[ij, ] beta_sigma

[b_0j, b_1j]' ~ MVN(0, Sigma_id)
Sigma_id =
  [sd0^2,             rho_re sd0 sd1;
   rho_re sd0 sd1,    sd1^2]
```

Use `rho_re` or a group-level correlation name internally and in docs. Do not
use `rho12`, which is reserved for residual response-response correlation in
bivariate likelihoods.

## TMB Parameterization

Keep the non-centered strategy:

```text
u_j ~ Normal([0, 0]', I)
b_j = diag(sd0, sd1) L_corr u_j
```

For `q = 2`:

```text
rho_re = 0.999999 * tanh(eta_cor)
L_corr =
  [1,      0;
   rho_re, sqrt(1 - rho_re^2)]
```

Then:

```text
b_0j = sd0 * u_0j
b_1j = sd1 * (rho_re u_0j + sqrt(1 - rho_re^2) u_1j)
```

The random-effect likelihood contribution remains:

```text
sum_j log Normal(u_j | 0, I)
```

No log determinant or Jacobian term is added for the deterministic transform
from standardized random effects to conditional random effects.

## Proposed Internal Data

The current `q = 1` terms can be represented as one-coefficient blocks. The
correlated block machinery should be able to express both old and new terms:

```text
n_mu_re_blocks
mu_re_block_ncoef[B]        # q_b
mu_re_block_coef_start[B]   # offset into coefficient/SD arrays
mu_re_block_re_start[B]     # offset into u_mu
mu_re_block_cor_start[B]    # offset into eta_cor_mu
mu_re_group_index[n, B]     # 0-based group index per block
mu_re_index[n, K]           # optional global u index per observation/coefficient
mu_re_value[n, K]           # random-effect design values; intercept column is 1
mu_re_coef_block[K]         # coefficient column to block
mu_re_coef_pos[K]           # coefficient position within block
```

Here `K = sum_b q_b`. Existing `(1 | id)` and `(0 + x | id)` become separate
`q = 1` blocks. New `(1 + x | id)` becomes one `q = 2` block with columns
`(Intercept)` and `x`.

Parameters:

```text
log_sd_mu[K]
eta_cor_mu[M]
u_mu[sum_b n_group_b q_b]
```

Map out `eta_cor_mu` when no block has `q > 1`.

## Extractors

Fitted objects should expose:

- `sdpars$mu`: group-level standard deviations by block coefficient;
- `corpars$mu`: group-level correlations, for example intercept-slope
  correlations;
- `random_effects$mu`: conditional modes for each block coefficient.

Do not place group-level correlations under `rho12`.

## Initial Implementation Boundary

The first implementation should support only ordinary unlabelled `q = 2`
Gaussian `mu` blocks:

```r
bf(y ~ x + (1 + x | id), sigma ~ z)
```

Defer:

- `q > 2` blocks;
- factor or multi-column random slopes;
- labelled `(1 + x | p | id)` blocks;
- correlated blocks spanning `mu` and `sigma`;
- bivariate `mu1`/`mu2` random-effect covariance blocks;
- phylogenetic and spatial correlated slope blocks.

For `q > 2`, use a positive-definite Cholesky or partial-correlation
parameterization. Do not use unconstrained pairwise `tanh()` correlations
directly because they do not guarantee a valid correlation matrix.

## Comparator Tests

The first ordinary correlated block should match:

```r
lme4::lmer(y ~ x + (1 + x | id), data = dat, REML = FALSE)
```

Compare:

- fixed effects;
- residual SD;
- random-effect SDs;
- intercept-slope correlation;
- marginal log-likelihood.

Use `glmmTMB` later as an additional comparator for the same Gaussian overlap.
Use `brms` as a syntax and code-generation reference, not as a routine runtime
comparator.

## Simulation Tests

CRAN-safe tests should cover:

- moderate positive group-level correlation;
- moderate negative group-level correlation;
- near-zero group-level correlation;
- large positive and negative correlation with finite estimates;
- near-zero random-slope SD boundary behavior;
- weak replication warnings;
- missingness in response, slope, and grouping variables;
- malformed or ambiguous syntax, such as duplicate blocks or mixing
  `(1 + x | id)` with `(0 + x | id)` for the same group.

Optional non-CRAN simulations should sweep over group count, within-group
replication, random-slope SD, residual SD, and group-level correlation.

## Numerical Risks

- Near-zero random-effect SDs make the correlation weakly identified.
- Correlations near `+/-1` can produce unstable gradients.
- Random slopes are sensitive to poorly scaled or uncentered predictors.
- Sparse groups and low within-group variation in the slope predictor can make
  the covariance block nearly unidentified.
- Dense known sampling covariance plus correlated random effects may stress the
  Laplace optimization and should be tested only after the simpler path is
  stable.
