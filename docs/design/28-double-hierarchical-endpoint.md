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
| Residual-scale random intercepts and slopes | Implemented ordinary unlabelled blocks | `sigma ~ x + (1 | id)`, `sigma ~ x + (1 + x | id)` |
| Random-effect scale models for `mu` intercept SDs | Implemented | `sd(id) ~ x_group` |
| Bivariate Gaussian residual coscale | Implemented | `rho12 ~ x` |
| `corpairs()` for fitted correlations | Partly implemented | residual `rho12`, ordinary `mu` and `sigma` intercept-slope correlations, univariate labelled `mu`/`sigma` intercept and one-slope covariance blocks, first bivariate `mu1`/`mu2` correlation |
| Cross-formula covariance blocks | Implemented univariate one-slope slice | shared labelled random intercepts or one-slope blocks across univariate `mu` and `sigma` |
| Bivariate `mu1`/`mu2` random-intercept covariance blocks | Implemented first slice | matching labelled `(1 | p | id)` terms in both location formulas |
| Bivariate random-slope, residual-scale, and cross-parameter covariance blocks | Planned | shared labelled blocks across `mu1`, `mu2`, `sigma1`, and `sigma2` |
| Profile-likelihood intervals for covariance summaries | Planned | see `docs/design/12-profile-likelihood-cis.md` |

## Target Model

For one response measured repeatedly on individuals, a complete
double-hierarchical Gaussian location-scale model can be written as:

\[
y_{ij} \sim \operatorname{Normal}(\mu_{ij}, \sigma_{ij}^2)
\]

\[
\mu_{ij} = X_{\mu}[ij,]\beta_{\mu} + b_{0j} + x_{ij}b_{1j}
\]

\[
\log(\sigma_{ij}) =
X_{\sigma}[ij,]\beta_{\sigma} + a_{0j} + x_{ij}a_{1j}
\]

\[
u_j =
\begin{bmatrix}
b_{0j} \\
b_{1j} \\
a_{0j} \\
a_{1j}
\end{bmatrix},
\qquad
u_j \sim \operatorname{MVN}(0, \Sigma_{\mathrm{ID}})
\]

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

\[
u_j =
\begin{bmatrix}
b_{\mu1,0j} \\
b_{\mu1,1j} \\
b_{\mu2,0j} \\
b_{\mu2,1j} \\
a_{\sigma1,0j} \\
a_{\sigma1,1j} \\
a_{\sigma2,0j} \\
a_{\sigma2,1j}
\end{bmatrix},
\qquad
u_j \sim \operatorname{MVN}(0, \Sigma_{\mathrm{ID}})
\]

and the residual covariance still has its own row-level term:

\[
\Omega_{ij}[1,2] = \rho_{12,ij}\sigma_{1,ij}\sigma_{2,ij}
\]

\[
\rho_{12,ij} =
\tanh\left(X_{\rho12}[ij,]\beta_{\rho12}\right)
\]

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
| `cor(sigma:(Intercept), sigma:x | id)` | scale-slope | baseline residual scale versus change in residual scale |
| `cor(mu:(Intercept), sigma:(Intercept) | id)` | mean-scale | average response versus residual scale |
| `cor(mu:x, sigma:(Intercept) | id)` | slope-scale | mean-model slope versus residual scale |
| `cor(mu1:(Intercept), mu2:(Intercept) | id)` | cross-response mean-mean | individual averages for response 1 versus response 2 |
| `rho12` | residual | within-observation residual coupling between two responses |

The table returned by `corpairs()` should always keep `level`, `group`, `block`,
`from_dpar`, `to_dpar`, `from_coef`, `to_coef`, `from_response`,
`to_response`, `class`, `estimate`, and `link_estimate` separate. A future
confidence-interval column can then attach uncertainty without changing the
meaning of the row.

## Implementation Order

1. Keep the current fixed-effect bivariate `rho12` path and ordinary univariate
   `mu` covariance blocks green in CI.
2. Add the first cross-formula univariate block:
   `bf(y ~ x + (1 | p | id), sigma ~ x + (1 | p | id))`.
   Done for matching labelled random intercepts.
3. Add ordinary unlabelled residual-scale random slopes:
   `bf(y ~ x, sigma ~ z + (1 + z | id))`.
   Done for unlabelled Gaussian `sigma` intercept-slope blocks.
4. Add the univariate four-effect labelled cross-formula block:
   `bf(y ~ x + (1 + x | p | id), sigma ~ x + (1 + x | p | id))`.
   Done for one-slope labelled Gaussian blocks using a positive-definite
   partial-correlation Cholesky parameterization.
5. Extend `corpairs()` to report each fitted group-level pair from the shared
   block and keep those rows distinct from residual `rho12`. Done for the first
   `mu`/`sigma` mean-scale random-intercept pair, ordinary unlabelled
   `sigma` scale-slope pairs, the six correlations in the univariate labelled
   `mu`/`sigma` one-slope block, bivariate `mu1`/`mu2` and `sigma1`/`sigma2`
   random-intercept pairs, and the first bivariate phylogenetic mean-mean pair.
6. Add bivariate `mu1`/`mu2` group-level blocks without scale random effects.
   Done for matching labelled random intercepts.
7. Add bivariate `sigma1`/`sigma2` group-level blocks only after the univariate
   scale-block recovery tests are stable. Done for matching labelled random
   intercepts.
8. Combine bivariate group-level covariance blocks with residual `rho12 ~ x`.
   Done for matching `mu1`/`mu2` and `sigma1`/`sigma2` random intercepts.
9. Add bivariate phylogenetic and non-phylogenetic species covariance blocks.
   Done for matching intercept-only phylogenetic `mu1`/`mu2` terms and
   matching labelled ordinary random intercepts; phylogenetic scale, mean-scale,
   and spatial layers remain planned. These blocks should report phylogenetic
   correlation, non-phylogenetic species correlation, and residual `rho12` as
   separate layers.
10. Add spatial double-hierarchical blocks only after the phylogenetic and
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

Point estimates should land before profile-likelihood intervals. Direct
two-dimensional correlations can use direct profile targets. The univariate
four-effect block reports ordinary pairwise correlations derived from a
positive-definite partial-correlation Cholesky parameterization, so those
correlation rows are point-estimate summaries until derived profile intervals
are designed. Phase 13 can then add intervals for quantities such as
repeatability, total variance, and correlation-pair summaries.

For variance-facing science summaries, keep the public model parameter as
`sigma` and report `sigma^2` only as a derived quantity when the interpretation
is variance, individual residual variation, or change in residual variation.
