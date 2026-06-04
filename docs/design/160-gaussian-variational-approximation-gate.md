# Gaussian Variational Approximation (Accuracy-Oriented) Pre-Code Gate

This note is the pre-code design gate for adding a **Gaussian variational
approximation (GVA)** to `drmTMB` as an alternative latent-variable integration
method, chosen for **accuracy where the Laplace approximation is biased**. It
does not add fitted support; it records the motivation, the objective, where it
plugs into the existing TMB machinery, the parameterization, the engine API, the
first-slice scope, and the validation plan, so a local-R/TMB session can
implement it turnkey.

The reader is the contributor implementing the inference engine with TMB
available, plus the project owner deciding scope. This is an
architecturally significant addition: `drmTMB`'s entire current inference path
is TMB's Laplace approximation, so the gate is deliberately conservative and
defines a small first slice.

## Why (Motivation)

`drmTMB` integrates random effects with TMB's Laplace approximation: it expands
the joint negative log-likelihood around the conditional mode of the latent
vector `u` and uses the curvature there. That is fast and accurate when the
conditional posterior of `u` is close to Gaussian, but it is known to be
**biased — not merely imprecise —** when it is not. The dominant, well-documented
case is **non-Gaussian random effects with little information per group**:
Bernoulli/binomial and low-count Poisson random-intercept models with small
cluster sizes, where Laplace systematically underestimates the random-effect
variance (e.g. Ormerod & Wand 2012; Breslow & Lin's PQL bias literature).

A GVA replaces the mode-based expansion with a Gaussian `q(u) = N(m, S)` chosen
to **maximize the evidence lower bound (ELBO)** — i.e. to minimize
`KL(q || p(u | y, theta))` — rather than to match the mode and local curvature.
For these models GVA is provably closer to the true marginal likelihood and
reduces the variance-component bias. It is also the **natural extension of the
existing TMB objective**, because the ELBO is built from the same joint density
TMB already forms.

Honest boundary: a Gaussian `q` still cannot represent genuine **skewness** of
the latent posterior. GVA improves on Laplace by optimizing the whole Gaussian
in KL rather than reading off the mode, but a skew-normal or higher-order `q` is
a separate, harder **Tier-2** extension (see "Out of Scope"). This gate claims
accuracy gains for the non-Gaussian-random-effect bias, not for arbitrary
skewness.

## What (Objective)

The current joint negative log-likelihood TMB forms is

```text
-log p(y, u | theta) = -log p(y | u, theta) - log p(u | theta)
```

with `p(u | theta) = N(0, Sigma(theta))` and TMB integrating `u` out by Laplace.

GVA instead introduces a variational distribution `q(u) = N(m, S)` and maximizes
the ELBO (equivalently, minimizes the negative ELBO as the objective):

```text
ELBO(theta, m, S) = E_q[ log p(y | u, theta) ]
                  + E_q[ log p(u | theta) ]
                  + H(q)
```

- `H(q) = 0.5 * log|S| + (d/2)(1 + log 2*pi)` is the Gaussian entropy
  (`d = dim u`).
- `E_q[ log p(u | theta) ]` is **closed form** for the Gaussian prior:
  `-0.5 ( tr(Sigma^{-1} S) + m' Sigma^{-1} m + log|Sigma| + d log 2*pi )`.
- `E_q[ log p(y | u, theta) ]` is the only term needing approximation. Because
  the data likelihood factorizes over observations and `u` enters through the
  per-group linear predictor, this reduces to **low-dimensional expectations per
  group**, evaluated by **adaptive Gauss-Hermite (GH) quadrature** over the
  per-group marginal of `q` (one or few dimensions per group for the first
  slice). GH quadrature is cheap and accurate for random-intercept models.

The negative ELBO is minimized jointly over the fixed parameters `theta` and the
variational parameters `(m, S)`. `nlminb`/TMB's optimizer can be reused; the
variational parameters are declared as ordinary `PARAMETER`s (not `random`),
because GVA does **not** use TMB's Laplace integration.

## Where It Plugs Into The TMB Machinery

`src/drmTMB.cpp` already declares the latent vectors as `PARAMETER_VECTOR`s
(`u_*`) and adds `-log p(u | theta)` and `-log p(y | u, theta)` to the joint
`nll`, with `R/drmTMB.R` passing `random = spec$random_names` to
`TMB::MakeADFun` so TMB Laplace-integrates them.

The GVA path adds, behind a method switch, an alternative objective in the same
template:

1. New `PARAMETER`s for the variational means `m` (same length as the latent
   vector) and a parameterization of `S` (see below). These are **not** passed
   in `random=`.
2. A `DATA_INTEGER` method flag (`inference_method`: 0 = Laplace, 1 = GVA) and GH
   quadrature nodes/weights as `DATA_VECTOR`s.
3. When GVA is selected, the template returns the **negative ELBO** assembled
   from the closed-form prior expectation + entropy + the GH-quadrature data-term
   expectation, instead of the joint nll integrated by Laplace.
4. `R/drmTMB.R` builds the variational parameter blocks, omits the latent vector
   from `random=` (GVA optimizes it as a fixed parameter), and routes
   post-fit extraction (`coef`, `sdpars`, `ranef`, `vcov`) from the variational
   solution. Standard errors for `theta` come from the ELBO Hessian; the
   reader-facing contract must state these are **variational** SEs.

Keeping both paths in one template (method flag) avoids duplicating the
likelihood and keeps Laplace as the default.

## Parameterization Of S

`S` must stay positive-definite and tractable:

- **First slice:** block-diagonal `S` by grouping factor, each block
  parameterized by a log-Cholesky factor (so `S = L L'`, `log` of the diagonal of
  `L` is free). For a single scalar random intercept per group this is one
  positive variational SD per group.
- Exploit the same group-block sparsity the prior `Sigma(theta)` already has;
  do not form a dense `d x d` `S`.
- Structured/low-rank `S` for many correlated random effects is a later
  extension, not the first slice.

## Engine API

- `drm_control(inference = c("laplace", "gva"))`, default `"laplace"`. No change
  to default behaviour.
- GVA-specific controls (GH nodes, variational-optimizer tolerances) live in
  `drm_control()`.
- `summary(fit)`/`confint(fit)` must label intervals as **variational** when
  `inference = "gva"`, and `check_drm()` should add a GVA convergence/ELBO
  diagnostic row. Do not present variational SEs as if they were Laplace +
  `sdreport` SEs.

## First-Slice Scope

Deliberately one model class where Laplace is most biased and GH quadrature is
simplest:

- **Univariate `mu` random-intercept GLMM** for `poisson(log)` and a
  Bernoulli/binomial route, `y ~ x + (1 | id)`, fixed-effect `sigma`/other dpars.
- Scalar latent per group; 1-D adaptive GH quadrature per group.
- Output parity with the Laplace path: `coef`, `sdpars$mu`, `ranef`,
  `check_drm()`, plus a GVA flag in the fitted object.

## Out Of Scope (First Slice)

Skew-normal or higher-order `q` (the genuine-skewness case); mean-field VB over
fixed effects and variance components; structured/low-rank `S`; bivariate and
structured-dependence models; stochastic/minibatch ELBO for large data;
non-`mu` distributional-parameter random effects. Each is a separate later gate.

## Validation Plan (ADEMP)

- **Aim.** Show GVA reduces the Laplace variance-component bias for non-Gaussian
  random-intercept models, recovering fixed effects and the random-effect SD
  more accurately, without harming the Gaussian case.
- **Data-generating model.** Bernoulli and low-count Poisson random-intercept
  data with small cluster sizes (the regime where Laplace is biased), across a
  grid of true random-effect SD and observations-per-group.
- **Estimands.** Fixed effects, random-effect SD, and (for reporting) the
  marginal-likelihood / ELBO gap.
- **Methods.** Three engines on identical data: Laplace (current), GVA (new),
  and a gold standard (high-order adaptive GH or `tmbstan`/MCMC) as the accuracy
  reference.
- **Performance measures.** Bias and RMSE of the random-effect SD and fixed
  effects, with Monte Carlo standard error; GVA-vs-Laplace bias difference;
  runtime. The headline claim is reduced SD bias relative to Laplace, verified
  against the gold standard.
- **Reporting.** A recovery lane (mirroring the existing Phase 18 lanes) plus a
  focused comparison table; keep the variational-SE caveat explicit.

## Standing Review

| Perspective | Decision for this gate |
| --- | --- |
| Fisher | The accuracy claim must be backed by a gold-standard comparison, not asserted; variational SEs are labelled as such and not conflated with Laplace + `sdreport`. |
| Noether | The ELBO terms (closed-form prior expectation, entropy, GH data term) must match the symbolic objective and the C++ exactly; the prior covariance `Sigma(theta)` is the same one the Laplace path uses. |
| Emmy | One TMB template with a method flag; Laplace stays default; extractors route by method without duplicating the likelihood. |
| Gauss | GVA bypasses TMB's Laplace; the variational parameters are ordinary `PARAMETER`s and the data-term quadrature must be numerically stable on the log scale. |
| Grace | New control surface, tests, and CI must keep the default Laplace path untouched and green. |
| Pat/Darwin | Tell users when to prefer GVA (binary/low-count random intercepts with small clusters) and that it is an accuracy option, not the default. |
| Rose | Do not let any doc imply GVA captures skewness or is implemented before recovery evidence exists. |

## Status

Design-only. No inference code, no engine switch, and no fitted GVA support
exist yet. This gate is the prerequisite for the local-R/TMB implementation
tracked in the capability worklist and the local-R handoff issue.
