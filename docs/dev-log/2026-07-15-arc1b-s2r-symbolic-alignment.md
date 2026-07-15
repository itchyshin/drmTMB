# Arc 1b-S2R symbolic alignment

## Frozen model

For `n` complete response pairs on `g` ordered relatedness levels, let `S` be
the `n x g` incidence matrix and let `K` be the supplied named, positive-
definite covariance in exactly that level order. Stack responses response-major:

\[
y=(y_1^T,y_2^T)^T,\quad X_b=\operatorname{diag}(X_1,X_2),\quad
Z_b=\operatorname{diag}(S,S).
\]

The fitted model is

\[
y=X_b\beta+Z_bu+\varepsilon,\qquad
u\sim N(0,G\otimes K),\qquad
\varepsilon\sim N(0,R\otimes I_n),
\]

with

\[
G=\begin{pmatrix}
\tau_1^2&\rho_K\tau_1\tau_2\\
\rho_K\tau_1\tau_2&\tau_2^2
\end{pmatrix},\qquad
R=\begin{pmatrix}
\sigma_1^2&\rho_{12}\sigma_1\sigma_2\\
\rho_{12}\sigma_1\sigma_2&\sigma_2^2
\end{pmatrix}.
\]

Let `N=2n`, `p=ncol(X_b)`, and
`V=Z_b(G \otimes K)Z_b^T + R \otimes I_n`. The independent negative
restricted log likelihood is

\[
-\ell_R(\theta)=\frac12\left[
\log|V|+\log|X_b^TV^{-1}X_b|+y^TP_Vy+(N-p)\log(2\pi)
\right],
\]

where

\[
P_V=V^{-1}-V^{-1}X_b(X_b^TV^{-1}X_b)^{-1}X_b^TV^{-1}.
\]

The response order, Kronecker order, and constant term are part of the oracle
contract, not presentation choices.

The canonical outer-parameter order is

```text
(log_tau1, log_tau2, eta_rhoK, log_sigma1, log_sigma2, eta_rho12)
```

The exact production transforms are `tau_j = exp(log_tauj)`,
`sigma_j = exp(log_sigmaj)`,
`rho_K = 0.999999 * tanh(eta_rhoK)`, and
`rho12 = 0.999999 * tanh(eta_rho12)`.

## DGP

With `L_K L_K^T = K` and independent standard-normal `z1,z2`:

\[
u_1=\tau_1L_Kz_1,\qquad
u_2=\tau_2L_K\{\rho_Kz_1+\sqrt{1-\rho_K^2}z_2\}.
\]

Freeze the numerical truth as

```text
beta1 = (intercept = 0.30, x1 = 0.50)
beta2 = (intercept = -0.20, x2 = -0.25)
tau1 = 0.80; tau2 = 0.65; rho_K = 0.35
sigma1 = 0.30; sigma2 = 0.35; rho12 = -0.20
```

Draw distinct `x1` and `x2` independently from standard normals. For
independent standard-normal residual draws `e1_raw,e2_raw`, use
`e1=e1_raw` and
`e2=rho12*e1_raw+sqrt(1-rho12^2)*e2_raw` before multiplying by the endpoint
residual SDs.

For `g` levels named `id_001`, ..., construct
`K[i,j] = 0.4^abs(i-j)`. This correlation matrix is deterministic and shared
across all replicates and both `m` values at a fixed `g`; only latent,
covariate, and residual draws change by replicate. `K` has unit diagonal,
identical row/column names, and the same ordered names as the factor levels
used by both endpoints. The package converts supplied covariance `K` to
internal precision `solve(K)`; a supplied precision `Q` is not admitted by
this arc.

## Term-by-term alignment

| Symbol | Public syntax | DGP | TMB/internal target | Extractor | Stored truth |
| --- | --- | --- | --- | --- | --- |
| `beta_1` | `mu1 = y1 ~ x1 + ...` | `X1 beta_1` | randomized `beta_mu1` under REML | `coef(fit, "mu1")` | coefficient vector |
| `beta_2` | `mu2 = y2 ~ x2 + ...` | `X2 beta_2` | randomized `beta_mu2` under REML | `coef(fit, "mu2")` | coefficient vector |
| `tau_1` | first `relmat(1 | p | id, K=K)` | first Cholesky draw | first `log_sd_phylo`, exponentiated | first `fit$sdpars$mu` row | positive scalar |
| `tau_2` | second matching term | correlated second draw | second `log_sd_phylo`, exponentiated | second `fit$sdpars$mu` row | positive scalar |
| `rho_K` | shared label `p` | cross-endpoint correlation in `G` | first `eta_cor_phylo`, transformed | `fit$corpars$relmat`; `corpairs(level="relmat")` | interior scalar |
| `sigma_1` | `sigma1 = ~1` | residual SD 1 | `beta_sigma1`, exponentiated | `sigma(fit)$sigma1` | positive scalar |
| `sigma_2` | `sigma2 = ~1` | residual SD 2 | `beta_sigma2`, exponentiated | `sigma(fit)$sigma2` | positive scalar |
| `rho12` | `rho12 = ~1` | residual correlation in `R` | transformed `beta_rho12` | `rho12(fit)` | interior scalar |
| `K` | identical `K=K` in both terms | fixed covariance | `type="relmat"`, `structure="K"`; precision `solve(K)` | fitted structured precision read-back | matrix, names, hash |

## Stop rule

Implementation stops if the fitted random vector is not response-major, the
two SD/correlation slots do not follow this order, the reconstructed package
covariance differs from `K`, or the dense objective fails at either the optimum
or displaced vectors. No relabelling after the recovery run is allowed.

## Frozen oracle checks

Optimize the dense oracle from the numerical truth with BFGS, relative
tolerance `1e-12`, and at most 2,000 iterations. Require convergence zero,
absolute objective equality at the production optimum within `1e-5`, maximum
absolute common-parameter disagreement from the independently optimized oracle
within `2e-3`, and fixed-coefficient disagreement within `5e-5`.

Evaluate objective differences from the common optimum at these exact outer-
parameter displacements:

```text
d1 = (+0.06, -0.04, +0.05, +0.03, -0.02, -0.04)
d2 = (-0.05, +0.07, -0.04, -0.03, +0.05, +0.03)
```

Each TMB/oracle difference must agree within `1e-5`. The test-of-test replaces
covariance `K` with precision-oriented `solve(K)` inside the oracle while
leaving the production fit unchanged; for `d1`, its objective difference must
miss the correct difference by more than `1e-3`.
