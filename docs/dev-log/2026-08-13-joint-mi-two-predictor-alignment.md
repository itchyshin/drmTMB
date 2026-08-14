# Two correlated missing predictors: symbolic alignment

## Proposed first route

For a univariate Gaussian response with two continuous predictors, let

\[
  y_i \mid x_{1i}, x_{2i} \sim N(\beta_0 + z_i^T\beta_z +
    \beta_1 x_{1i} + \beta_2 x_{2i}, \sigma_y^2),
\]

and model the two predictors jointly as

\[
  \begin{pmatrix}x_{1i}\\x_{2i}\end{pmatrix} \mid w_i
  \sim N\left(
    \begin{pmatrix}w_i^T\alpha_1\\w_i^T\alpha_2\end{pmatrix},
    \begin{pmatrix}
      \sigma_{x1}^2 & \rho_x\sigma_{x1}\sigma_{x2}\\
      \rho_x\sigma_{x1}\sigma_{x2} & \sigma_{x2}^2
    \end{pmatrix}
  \right).
\]

The objective is the observed-data likelihood, integrating each missing
component of \(x_i\) while retaining the appropriate Gaussian marginal density
for each of the four observed-predictor patterns. The Gaussian TMB/Laplace
calculation is exact for this latent Gaussian block. Response masks are outside
this first route.

## Alignment table

| Symbol | Proposed user surface | TMB data / parameter | Recovery target |
| --- | --- | --- | --- |
| \(\beta_1, \beta_2\) | `mi(x1) + mi(x2)` | two `mu` columns | response coefficients |
| \(\alpha_1, \alpha_2\) | `impute_joint(cbind(x1, x2) ~ z)` | two predictor design blocks | predictor-model coefficients |
| \(\sigma_{x1}, \sigma_{x2}\) | joint Gaussian imputation model | two log-SD parameters | predictor scales |
| \(\rho_x\) | joint Gaussian imputation model | unconstrained transform | predictor correlation |
| missingness pattern | observed `x1`, `x2`, and `y` masks | pattern indicators | row accounting and sentinel invariance |

## First-route boundary

Exactly two distinct continuous bare `mi()` terms; common fixed-effect
predictor-model right-hand side; Gaussian response with `sigma ~ 1`; no response
random/structured effects, offsets, sparse matrices, aggregation, REML, or
non-Gaussian predictor families.

## Poisson proof route

The separate Poisson route uses the same `mi(x1) + mi(x2)` and
`impute_joint(cbind(x1, x2) ~ z)` grammar. It retains the continuous joint
Gaussian latent block and evaluates the Poisson response conditional on that
block through TMB/Laplace. Its boundary is complete Poisson responses, no zero
inflation, response mask, random/structured response terms, or REML. It is
tested independently from the Gaussian route and should not be read as support
for other non-Gaussian responses.
