# Arc 1b-S1 symbolic alignment: spatial q2 bivariate-Gaussian REML

**Date:** 2026-07-14
**Base:** `29a4458addb550c9d82a9dc8c4324c15702e0591` (`main` after PR #782)
**Scope:** one native-TMB, bivariate-Gaussian, location-only, coordinate-spatial
q2 random-intercept block under `REML = TRUE`
**Status:** equation/API/DGP/oracle contract frozen before implementation

This document is the Noether alignment gate for Arc 1b-S1. It does not admit
the model by itself. Implementation and promotion remain conditional on the
test-of-test, exact objective comparisons, recovery campaign, and independent
review in the approved ultra-plan.

## Exact accepted cell

```r
fit <- drmTMB(
  bf(
    mu1 = y1 ~ x1 + spatial(1 | p | site, coords = coords),
    mu2 = y2 ~ x2 + spatial(1 | p | site, coords = coords),
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  ),
  family = biv_gaussian(),
  data = dat,
  REML = TRUE
)
```

Here `sigma1`, `sigma2`, and `rho12` are constant **estimated** residual
parameters. “Fixed-covariance spatial” refers to the coordinate kernel and its
range, not to holding the two residual SDs or either correlation at their truth.
The label `p` joins exactly the two location intercepts into one q2 spatial
covariance block.

## Symbolic model and ordering

Let there be $n$ complete paired observations at $m$ observed sites. Let
$s(i)\in\{1,\ldots,m\}$ identify the site for observation $i$, and let
$Z\in\mathbb R^{n\times m}$ be the corresponding one-hot incidence matrix.
For response $r\in\{1,2\}$,

\[
y_r = X_r\beta_r + Za_r + \epsilon_r.
\]

Freeze all stacked objects in **response-major order**:

\[
y=\begin{bmatrix}y_1\\y_2\end{bmatrix},\qquad
\beta=\begin{bmatrix}\beta_1\\\beta_2\end{bmatrix},\qquad
X_b=\begin{bmatrix}X_1&0\\0&X_2\end{bmatrix},\qquad
a=\begin{bmatrix}a_1\\a_2\end{bmatrix},\qquad
Z_b=\begin{bmatrix}Z&0\\0&Z\end{bmatrix}.
\]

Within each coefficient block, the order is the R model-matrix order. For the
formula above this is `beta = c(beta_mu1["(Intercept)"], beta_mu1["x1"],
beta_mu2["(Intercept)"], beta_mu2["x2"])`. The TMB latent vector is already
endpoint-major: `u_phylo[1:m]` is the `mu1` spatial field and
`u_phylo[(m + 1):(2 * m)]` is the `mu2` field. The existing ML dense helper uses
an interleaved response representation; that is a permutation-equivalent
calculation, not the order to use in the REML oracle.

The spatial and residual covariance matrices are

\[
G = \begin{bmatrix}
\tau_1^2 & \rho_{sp}\tau_1\tau_2\\
\rho_{sp}\tau_1\tau_2 & \tau_2^2
\end{bmatrix},\qquad
R = \begin{bmatrix}
\sigma_1^2 & \rho_{12}\sigma_1\sigma_2\\
\rho_{12}\sigma_1\sigma_2 & \sigma_2^2
\end{bmatrix}.
\]

Then

\[
a\sim N(0,G\otimes K_{sp}),\qquad
\epsilon\sim N(0,R\otimes I_n),
\]

and the response-major marginal covariance is

\[
V(\theta)=Z_b(G\otimes K_{sp})Z_b^\top + R\otimes I_n
=G\otimes (ZK_{sp}Z^\top)+R\otimes I_n.
\]

This ordering implies the upper-right $n\times n$ block of $V$ is
$\rho_{sp}\tau_1\tau_2 ZK_{sp}Z^\top+
\rho_{12}\sigma_1\sigma_2I_n$. A sign or permutation error here can exchange
the latent spatial correlation with residual `rho12`; the oracle must inspect
the two blocks separately.

## Exact coordinate covariance contract

The production path is `drm_spatial_coords_precision()` in `R/drmTMB.R`, used
by `build_spatial_mu_structure()`. For the first two coordinate columns, in
first-observed site order (or row-name-matched site order), define

\[
d_{jk}=\lVert c_j-c_k\rVert_2,\qquad
r_* = \operatorname{median}\{d_{jk}:d_{jk}>0\},
\]

with the production fallback to the maximum positive distance if the median is
not finite or positive. The fixed covariance is

\[
(K_{sp})_{jk}=\exp(-d_{jk}/r_*),\qquad
K_{sp}\leftarrow K_{sp}+10^{-6}I_m,
\]

and `Q_phylo = Q_sp = solve(K_sp)`. If the first Cholesky factorization fails,
production adds a further `sqrt(1e-6)` to the diagonal before inversion. The
ordinary deterministic fixtures must be chosen so that this fallback does not
fire.

There is **no subsequent unit-diagonal normalization**. Consequently the
reported `tau1` and `tau2` multiply a base kernel whose diagonal is `1.000001`
under the ordinary path. This negligible numerical distinction must still be
preserved in exact objective tests. The oracle helper should construct
$K_{sp}$ independently from coordinates and assert parity with
`solve(as.matrix(fit$model$structured$phylo_mu$precision$precision))`; it must
not silently substitute a correlation matrix with diagonal exactly one.

## DGP contract

The deterministic fixture and the later recovery runner must draw the same
model that is fitted. With $L_K=\operatorname{t}(\operatorname{chol}(K_{sp}))$
and mutually independent standard-normal vectors $z_1,z_2,e_1,e_2$, draw

\[
\begin{aligned}
a_1 &= \tau_1 L_Kz_1,\\
a_2 &= \tau_2 L_K\{\rho_{sp}z_1+
\sqrt{1-\rho_{sp}^2}z_2\},\\
\epsilon_1 &= \sigma_1e_1,\\
\epsilon_2 &= \sigma_2\{\rho_{12}e_1+
\sqrt{1-\rho_{12}^2}e_2\},\\
y_1 &= X_1\beta_1+Za_1+\epsilon_1,\\
y_2 &= X_2\beta_2+Za_2+\epsilon_2.
\end{aligned}
\]

Use distinct `x1` and `x2` columns in the oracle fixture. This prevents the
identical-regressor seemingly-unrelated-regression shortcut from concealing a
response or coefficient stacking error. Use replication within site so the
latent $G$ and residual $R$ components are separately informed.

## Restricted-likelihood contract

Let $N=2n$, $p=p_1+p_2$, and

\[
\widehat\beta(\theta)=
(X_b^\top V^{-1}X_b)^{-1}X_b^\top V^{-1}y,
\qquad r=y-X_b\widehat\beta.
\]

The independent dense oracle minimizes the same full restricted negative log
likelihood convention already used by the native phylogenetic bivariate REML
reference:

\[
\operatorname{nll}_R(\theta)=\frac12\left[
(N-p)\log(2\pi)+\log|V|+
\log|X_b^\top V^{-1}X_b|+r^\top V^{-1}r
\right].
\]

Equivalently, the quadratic is $y^\top P_Vy$, where

\[
P_V=V^{-1}-V^{-1}X_b(X_b^\top V^{-1}X_b)^{-1}X_b^\top V^{-1}.
\]

No `0.5 * log|X_b'X_b|` comparator shift belongs in this drmTMB-to-drmTMB
oracle. Unit observation weights, complete response pairs, no known `V`, and a
full-rank dense $(X_1,X_2)$ are part of this first-cell contract.

Use the exact production link guards:

\[
\tau_r=\exp(\lambda_r),\quad
\sigma_r=\exp(\gamma_r),\quad
\rho_{sp}=0.999999\tanh(\eta_{sp}),\quad
\rho_{12}=0.999999\tanh(\eta_{12}).
\]

The outer TMB parameter set for this location-only REML cell is therefore

```text
lambda1, lambda2  <-> log_sd_phylo[1], log_sd_phylo[2]
eta_sp            <-> eta_cor_phylo
gamma1, gamma2    <-> beta_sigma1[1], beta_sigma2[1]
eta_12            <-> beta_rho12[1]
```

`u_phylo`, `beta_mu1`, and `beta_mu2` are in
`fit$model$tmb_random_names` and are marginalized by TMB. Because the model is
linear Gaussian, that Laplace calculation is exact. `beta_sigma1`,
`beta_sigma2`, and `beta_rho12` remain outer parameters because there is no
scale-side random component in this cell. The internal names remain
`Q_phylo`, `u_phylo`, `log_sd_phylo`, and `eta_cor_phylo` even when
`structured_mu$type == "spatial"`; the public extractor layer supplies the
spatial names.

## Alignment table

| Symbol | R syntax / object | DGP draw | TMB parameter or data | Public recovery extractor | Frozen truth |
| --- | --- | --- | --- | --- | --- |
| \(\beta_1\) | `mu1 = y1 ~ x1 + ...`; `X_mu1` | `c(beta10, beta11)` | `beta_mu1`, marginalized under REML | `coef(fit, "mu1")`; `fit$par$mu1` | both entries recovered |
| \(\beta_2\) | `mu2 = y2 ~ x2 + ...`; `X_mu2` | `c(beta20, beta21)` | `beta_mu2`, marginalized under REML | `coef(fit, "mu2")`; `fit$par$mu2` | both entries recovered |
| \(K_{sp}\) | shared `coords = coords` | independent exponential-distance kernel with production jitter | `Q_phylo = solve(K_sp)`; `log_det_Q_phylo` | `fit$model$structured$phylo_mu$precision`; `range` | exact matrix and site order |
| \(a_1\) | first labelled spatial endpoint in `mu1` | `tau1 * L_K %*% z1` | `u_phylo[1:m]`; `phylo_mu_response[1] = 1` | `ranef(fit, "spatial_mu")`; conditional `predict()` decomposition | correlation/projection diagnostic only |
| \(a_2\) | second labelled spatial endpoint in `mu2` | `tau2 * L_K %*% (rho_sp*z1 + sqrt(1-rho_sp^2)*z2)` | `u_phylo[(m+1):(2*m)]`; `phylo_mu_response[2] = 2` | same `spatial_mu` block; conditional `predict()` decomposition | correlation/projection diagnostic only |
| \(\tau_1\) | SD of `mu1` spatial intercept | positive scalar | `exp(log_sd_phylo[1])` | `fit$sdpars$mu[["mu1:spatial(1 | p | site)"]]`; summary target `sd:mu:mu1:spatial(1 | p | site)` | recovery target |
| \(\tau_2\) | SD of `mu2` spatial intercept | positive scalar | `exp(log_sd_phylo[2])` | `fit$sdpars$mu[["mu2:spatial(1 | p | site)"]]`; summary target `sd:mu:mu2:spatial(1 | p | site)` | recovery target |
| \(\rho_{sp}\) | common label `p` | latent standardized-field correlation | `0.999999 * tanh(eta_cor_phylo)` | `fit$corpars$spatial[["cor(mu1:(Intercept),mu2:(Intercept) | p | site)"]]`; `corpairs(fit, level = "spatial")`; target `cor:spatial:cor(mu1:(Intercept),mu2:(Intercept) | p | site)` | recovery target |
| \(\sigma_1\) | `sigma1 = ~ 1` | residual SD for response 1 | `exp(beta_sigma1[1])` | `sigma(fit)$sigma1`; summary parameter `sigma1` | recovery target |
| \(\sigma_2\) | `sigma2 = ~ 1` | residual SD for response 2 | `exp(beta_sigma2[1])` | `sigma(fit)$sigma2`; summary parameter `sigma2` | recovery target |
| \(\rho_{12}\) | `rho12 = ~ 1` | within-observation residual correlation | `0.999999 * tanh(beta_rho12[1])` | `rho12(fit)`; summary parameter `rho12` | recovery target |

The spatial q2 `corpairs()` row must report `level = "spatial"` and its stored
class `mean-mean` (`location-location` is the accepted filter alias); it must
not be confused with the residual `rho12` row.

## Optimum and displaced-vector proof

Convergence is necessary but not sufficient. The deterministic proof must use
one frozen fixture and satisfy all of the following.

1. The pre-change test-of-test reaches the current bivariate REML validator and
   rejects this exact spatial q2 cell.
2. The production and independently constructed $K_{sp}$, site order, $Z$,
   $X_b$, and response-major $y$ are identical.
3. The dense oracle and TMB converge at an interior optimum. Compare all six
   outer covariance parameters on their response scales, both fixed-effect
   blocks at the GLS mode, and the absolute restricted objective. The target
   tolerance is `1e-5` for the objective and a separately justified numerical
   tolerance for fitted parameters.
4. Recover a canonical named outer vector
   `c(lambda1, lambda2, eta_sp, gamma1, gamma2, eta_12)` from each TMB vector by
   parameter block and endpoint identity, not by assuming the raw optimizer
   vector order.
5. At no fewer than two predeclared interior displacements, compare normalized
   objective changes:

   ```text
   [TMB(displaced) - TMB(base)] ==
   [oracle(displaced) - oracle(base)]
   ```

   One acceptable frozen pair in canonical order is
   `c(+0.06, -0.04, +0.05, +0.03, -0.02, -0.04)` and
   `c(-0.05, +0.07, -0.04, -0.03, +0.05, +0.03)`. Reject a displacement if it
   creates a boundary or non-positive-definite covariance; do not silently
   shrink it after seeing results.
6. Deliberately permute one endpoint or swap `rho_sp` with `rho12` in a negative
   oracle control and show that the displaced-vector equality fails. This is
   the test of the test for stacking and covariance-layer identity.

The absolute-objective equality is expected from the existing Arc 1a exact
Gaussian convention but remains a gate to prove, not an assumption to waive.
If only a parameter-independent constant differs, stop and localize it before
changing the assertion; do not accept optimum-only parity as a substitute.

## Explicit negative space

This alignment does **not** admit or provide evidence for:

- unlabelled, unmatched, partial, or differently labelled bivariate spatial
  endpoint pairs;
- `spatial(0 + x | p | site, ...)`, `spatial(1 + x | p | site, ...)`, any
  other slope, or any multiple spatial term;
- an estimated spatial range, alternative kernels, meshes, SPDEs, or a
  no-jitter covariance convention;
- spatial structure in `sigma1` or `sigma2`, scale-only q2, mean-scale q2,
  q2-plus-q2, q4, q6, q8, or q12 blocks;
- animal, `relmat()`, phylogenetic generalization, or simultaneous structured
  providers;
- ordinary-plus-spatial mixtures beyond existing separately tested contracts;
- a random or predictor-dependent `rho12`;
- known sampling covariance, missing response pairs, non-unit weights, sparse
  fixed-effect matrices, or Gaussian row aggregation;
- non-Gaussian REML, AI-REML, Julia bridge expansion, direct-`sd()` models, the
  banked Beta location-scale-scale candidate, intervals, coverage,
  `inference_ready_with_caveats`, or `supported`.

The maximum outcome of Arc 1b-S1 is `point_fit_recovery` for this exact cell.

## Repo evidence and unresolved empirical question

The existing ML contract is in `tests/testthat/test-spatial-gaussian.R`; the
coordinate kernel is in `R/drmTMB.R` at `drm_spatial_coords_precision()`; the
q2 prior and endpoint dispatch are in the `model_type == 2` branch of
`src/drmTMB.cpp`; the existing exact bivariate phylogenetic REML reference is in
`tests/testthat/test-reml-bivariate.R`; and the current blocking validator is
`drm_validate_reml_spec_biv()`.

No mathematical or ordering blocker was found. The unresolved question is
empirical identifiability across site count and within-site replication. That
must be answered by the predeclared local-to-Totoro/DRAC recovery ladder; it
cannot be inferred from this derivation or from the existing ML fit alone.
