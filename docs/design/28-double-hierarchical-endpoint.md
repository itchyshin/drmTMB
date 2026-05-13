# Double-Hierarchical Individual-Difference Endpoint

This note turns the full individual-difference location-scale model into a
phase map. The reader is an applied ecology, evolution, or environmental
science user working with repeated measurements, plus the package contributor
who has to implement the likelihood without blurring parameter meanings.

## Current Boundary

`drmTMB` currently fits several pieces that are needed for the final model, but
it does not yet fit the complete double-hierarchical covariance model.

| Piece | Status | Current user-facing surface |
|---|---|---|
| Univariate Gaussian location-scale fixed effects | Implemented | `bf(y ~ x, sigma ~ z)` |
| Univariate Gaussian `mu` random intercepts and simple slopes | Implemented | `(1 | id)`, `(0 + x | id)`, `(1 + x | id)` |
| Residual-scale random intercepts and independent slopes | Implemented | `sigma ~ x + (1 | id) + (0 + w | id)` |
| Random-effect scale models for `mu` intercept SDs | Implemented | `sd(id) ~ x_group` |
| Bivariate Gaussian residual coscale | Implemented | `rho12 ~ x` |
| `corpairs()` for fitted correlations | Partly implemented | residual `rho12`, ordinary `mu` intercept-slope correlations, first univariate and same-response bivariate `mu`/`sigma` mean-scale rows, and bivariate `mu1`/`mu2` and `sigma1`/`sigma2` intercept rows |
| Cross-formula covariance blocks | Implemented first slice | matching labelled univariate `(1 | p | id)` terms across `mu` and `sigma` |
| Bivariate `mu1`/`mu2` random-intercept covariance blocks | Implemented first slice | matching labelled `(1 | p | id)` terms in both location formulas |
| Bivariate `sigma1`/`sigma2` random-intercept covariance blocks | Implemented first slice | matching labelled `(1 | p | id)` terms in both scale formulas |
| Same-response bivariate `mu`/`sigma` random-intercept covariance blocks | Implemented first slice | one matching labelled pair in `mu1`/`sigma1` or `mu2`/`sigma2` |
| Bivariate random-slope and full cross-parameter covariance blocks | Planned | richer shared labelled blocks across `mu1`, `mu2`, `sigma1`, and `sigma2` |
| Profile-likelihood intervals for covariance summaries | Partly implemented | direct profile intervals for first univariate and same-response bivariate `mu`/`sigma`, bivariate `mu1`/`mu2`, and bivariate `sigma1`/`sigma2` covariance rows; derived summaries planned |

## Target Model

For one response measured repeatedly on individuals, a complete
double-hierarchical Gaussian location-scale model can be written as:

```text
y_ij ~ Normal(mu_ij, sigma_ij^2)

mu_ij = X_mu[ij, ] beta_mu + b_0j + x_ij b_1j

log(sigma_ij) = X_sigma[ij, ] beta_sigma + a_0j + x_ij a_1j

u_j = [b_0j, b_1j, a_0j, a_1j]'
u_j ~ MVN(0, Sigma_ID)
```

Matching future R syntax should use one formula per distributional parameter:

```r
bf(
  y ~ x + (1 + x | p | id),
  sigma ~ x + (1 + x | p | id)
)
```

The block label `p` says that the location and scale random effects belong to
one individual-level covariance block. That block contains the correlations
among individual differences in average response, mean-model slopes, residual
scale, and scale-model slopes. These are group-level correlations; they are not
residual `rho12`.

For two responses, the endpoint extends the same idea:

```text
u_j =
  [b_mu1_0j, b_mu1_1j, b_mu2_0j, b_mu2_1j,
   a_sigma1_0j, a_sigma1_1j, a_sigma2_0j, a_sigma2_1j]'

u_j ~ MVN(0, Sigma_ID)
```

and the residual covariance still has its own row-level term:

```text
Omega_ij[1,2] = rho12_ij sigma1_ij sigma2_ij
rho12_ij = 0.99999999 * tanh(X_rho12[ij, ] beta_rho12)
```

This separation is the core design rule: group-level covariance blocks answer
questions about persistent individual differences, while residual `rho12`
answers whether two responses remain coupled within an observation after the
location and scale predictors have been accounted for.

## Correlation-Pair Output

The endpoint should not expose only a covariance matrix. Users need a long
table that says what each correlation means:

| Example pair | Formal class | Reader-facing interpretation |
|---|---|---|
| `cor(mu:(Intercept), mu:x | id)` | mean-slope | average response versus mean-model slope |
| `cor(sigma:(Intercept), sigma:x | id)` | scale-scale | baseline residual scale versus change in residual scale |
| `cor(mu:(Intercept), sigma:(Intercept) | id)` | mean-scale | average response versus residual scale |
| `cor(mu:x, sigma:(Intercept) | id)` | slope-scale | mean-model slope versus residual scale |
| `cor(mu1:(Intercept), mu2:(Intercept) | id)` | cross-response mean-mean | individual averages for response 1 versus response 2 |
| `rho12` | residual | within-observation residual coupling between two responses |

The table returned by `corpairs()` should always keep `level`, `group`, `block`,
`from_dpar`, `to_dpar`, `from_coef`, `to_coef`, `from_response`,
`to_response`, `class`, `estimate`, and `link_estimate` separate. Direct
profile intervals already work for the first fitted `mu`/`sigma`,
`mu1`/`mu2`, and `sigma1`/`sigma2` covariance parameters through the
`profile_targets()` namespace, but future `corpairs()` interval columns should
keep the same row meaning and mark derived intervals separately.

## Implementation Order

1. Keep the current fixed-effect bivariate `rho12` path and ordinary univariate
   `mu` covariance blocks green in CI.
2. Add the first cross-formula univariate block:
   `bf(y ~ x + (1 | p | id), sigma ~ x + (1 | p | id))`.
   Done for matching labelled random intercepts.
3. Add the labelled covariance block assembler in
   `docs/design/30-labelled-covariance-block-assembler.md`, and route the
   current pairwise bridges through that registry before exposing larger
   shared labels. Done for current two-member pairwise bridges, including
   registry-backed `corpairs()`, `check_drm()`, `profile_targets()`, and a
   no-op C++ visibility path for the dormant block data contract.
4. Add a guarded three-member scaffold and a positive-definite `q > 2`
   parameterization before exposing larger shared labels. Done for internal
   registry pair enumeration and hidden TMB algebra probes for q=3
   positive-definite correlations plus a non-centered `sqrt_cov_scale()`
   transform. A hidden registry-shaped contribution probe now maps q=3
   group-level latent vectors from a dormant TMB parameter back through member
   design columns, the hidden probe can register that parameter as a TMB random
   effect, and a hidden Gaussian prototype can route q=3 transformed member
   contributions into `mu` and `log_sigma`. Simulation recovery and user-facing
   q > 2 support remain next.
5. Add the univariate four-effect block:
   `bf(y ~ x + (1 + x | p | id), sigma ~ x + (1 + x | p | id))`.
6. Extend `corpairs()` to report each fitted group-level pair from the shared
   block and keep those rows distinct from residual `rho12`.
7. Add bivariate `mu1`/`mu2` group-level blocks without scale random effects.
   Done for matching labelled random intercepts.
8. Add bivariate `sigma1`/`sigma2` group-level blocks only after the univariate
   scale-block recovery tests are stable.
   Done for matching labelled random intercepts.
9. Combine bivariate group-level covariance blocks with residual `rho12 ~ x`.
   Done for matching labelled random intercepts in both `mu1`/`mu2` and
   `sigma1`/`sigma2`.
10. Add one same-response bivariate `mu`/`sigma` random-intercept covariance
   pair, such as `mu1` with `sigma1`. Done for one matching labelled pair; the
   full shared block across `mu1`, `mu2`, `sigma1`, and `sigma2` remains
   planned.
11. Add bivariate phylogenetic and non-phylogenetic species covariance blocks
   only after ordinary grouped models have recovery evidence and clear
   diagnostics. These blocks should report phylogenetic correlation,
   non-phylogenetic species correlation, and residual `rho12` as separate
   layers.
12. Add spatial double-hierarchical blocks only after the phylogenetic and
   ordinary grouped covariance paths have clear diagnostics.

Each step should add only one covariance expansion. If a step cannot recover
SDs and correlations in small simulation tests, the next step should wait.

## Tests Required

Every implemented slice needs:

- symbolic equations, R syntax, and interpretation in the design docs;
- simulation recovery for fixed effects, SDs, and correlations;
- malformed-syntax tests that reject unsupported covariance sharing clearly;
- `corpairs()` tests showing residual `rho12` and group-level correlations in
  separate rows;
- boundary tests for near-zero SDs and correlations near zero, positive, and
  negative values;
- `check_drm()` diagnostics for weak group counts, singleton groups, and
  correlations that are poorly identified because one SD is close to zero.

The first implementation should prefer small Gaussian models with many repeated
measurements per individual. Large phylogenetic, spatial, or non-Gaussian
versions are research extensions, not the first production target.

For structured two-response models, the same caution applies to interpretation:
phylogenetic correlation answers whether evolutionary shared history explains
coordinated response components, non-phylogenetic species or individual
correlation answers whether remaining group-level deviations are coupled, and
residual `rho12` answers whether the two responses are coupled within an
observation after those higher-level effects have been accounted for.

## Reporting And Inference

Point estimates should land before profile-likelihood intervals. For the first
implemented `mu`/`sigma` and bivariate `mu1`/`mu2` random-intercept covariance
rows, Phase 6 can now profile the direct internal correlation parameters.
Phase 13 is still the place for derived intervals for quantities such as
repeatability, total variance, and correlation-pair summaries.

For variance-facing science summaries, keep the public model parameter as
`sigma` and report `sigma^2` only as a derived quantity when the interpretation
is variance, individual residual variation, or change in residual variation.
