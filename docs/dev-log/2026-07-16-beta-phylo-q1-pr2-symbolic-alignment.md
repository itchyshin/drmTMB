# PR 2 symbolic alignment: Beta q1 phylogenetic direct-SD regression

**Frozen:** 2026-07-16, before implementation or PR 2 simulation
**Base:** `0bdfda144c976824bed604be2cfae22b33bd8fe0` (PR #786 merge)
**Scope:** ML, univariate `beta()`, one unlabelled intercept-only
`phylo(1 | spp_id, tree = tree)` location term, fixed effects in family
`sigma`, and `sd(spp_id, level = "phylogenetic") ~ 1 + x` for that location
term
**Claim ceiling:** `point_fit_recovery`

PR 2 changes the SD of the one admitted phylogenetic location effect. It does
not add a phylogenetic effect to Beta precision, general `sd()` support for
Beta, or another random effect.

## Accepted formula and rejected neighbours

```r
drmTMB(
  bf(
    y ~ 1 + x_mu + phylo(1 | spp_id, tree = tree),
    sigma ~ 1 + x_sigma,
    sd(spp_id, level = "phylogenetic") ~ 1 + x_tau
  ),
  family = beta(), data = dat
)
```

The direct-SD group must identify the same `spp_id` as the sole q1
phylogenetic location term. Its fixed-effect predictors must be constant within
species. PR 2 rejects REML, labels or slopes in `phylo()`, phylogeny in family
`sigma`, ordinary random effects, RHS random effects in `sd()`, a mismatched
target group, within-species-varying SD predictors, q2/q4 or bivariate models,
missing response or predictor routes, `zero_one_beta()`, and other non-Gaussian
families. The existing
Gaussian direct-SD routes remain unchanged.

## Symbolic model

For observation `i` in species `s(i)`, let `A` be the unit-diagonal tip
correlation matrix induced by the tree and let `Q_aug` be the precision of its
augmented unit field:

```text
y_i | v ~ Beta(mu_i phi_i, (1 - mu_i) phi_i)
logit(mu_i) = beta_0 + beta_1 x_mu,i + a_s(i)
log(sigma_i) = gamma_0 + gamma_1 x_sigma,i
phi_i = sigma_i^(-2) = exp{-2(gamma_0 + gamma_1 x_sigma,i)}
log(tau_s) = alpha_0 + alpha_1 x_tau,s
v_aug ~ N(0, Q_aug^(-1))
a_s = tau_s v_tip,s
```

With `D_tau = diag(tau_1, ..., tau_g)`, the observed-tip effect satisfies

```text
a_tip ~ N(0, D_tau A D_tau).
```

Only observed tips receive `tau_s`. Internal augmented-tree nodes remain the
unit field used by the sparse Gaussian prior and never receive user covariates.
Family `sigma` remains a separate fixed-effect submodel that determines
`phi = sigma^(-2)`; it is not the conditional response SD and is not `tau_s`.

## Term-by-term alignment

| Symbol or object | R formula / DGP | Builder and TMB representation | Public evidence target |
| --- | --- | --- | --- |
| `beta` | fixed `mu` intercept and slope | `X_mu`, `beta_mu` | `coef(fit, "mu")`; recovery |
| `gamma` | fixed family-`sigma` intercept and slope | `X_sigma`, `beta_sigma`; `phi = exp(-2 * log_sigma)` | `coef(fit, "sigma")`; `predict(..., dpar = "sigma")`; wrong-`phi` sentinel |
| `alpha` | fixed log-`tau` intercept and slope | one species-row design `X_sd_phylo`; `beta_sd_mu`; `tau = exp(X_sd_phylo * beta_sd_mu)` | `coef(fit, "sd_phylo(spp_id)")`; `predict(..., dpar = "sd_phylo(spp_id)")`; recovery |
| `v_aug` | draw from `N(0, Q_aug^(-1))` | `u_phylo` under the unit augmented-field prior | latent nuisance field; fixed-parameter NLL and gradient oracle |
| `a_s` | `tau_s * v_tip,s` | multiply only `u_phylo[phylo_mu_node_index]` by the species-aligned `tau_s` before adding to `eta_mu` | conditional `ranef()` and link prediction |
| `D_tau A D_tau` | covariance of scaled tip draws | `Q_aug` prior plus observed-tip scaling rows | empirical covariance oracle and algebraic unit test |

The implementation must reuse the existing Gaussian direct-SD data contract:
one row per species in `X_sd_phylo`, observation-to-species rows for the
location predictor, and tip-node rows for scaling. It must remain a Beta-only
admission in the Beta model builder.

## Intercept-only equivalence to PR 1

When `alpha_1 = 0`, `tau_s = exp(alpha_0) = tau` for every species. PR 1 uses
the scaled field `a_aug = tau v_aug` and its density

```text
0.5 [n_aug log(2 pi) + 2 n_aug log(tau) - log|Q_aug|
     + tau^(-2) a_aug' Q_aug a_aug].
```

PR 2 uses the unit field `v_aug`, its density

```text
0.5 [n_aug log(2 pi) - log|Q_aug| + v_aug' Q_aug v_aug],
```

and adds `tau v_tip` to the location predictor. The change of variables
`a_aug = tau v_aug`, including its Jacobian, makes the marginal likelihoods
identical. Tests must compare displaced fixed-parameter objectives after that
change of variables and compare fitted log likelihoods, fixed coefficients,
and `log(tau)` estimates from the two public parameterizations.

## Independent likelihood and gradient contract

At a displaced complete parameter vector, reconstruct the non-marginal joint
NLL independently from `dbeta()` and the unit augmented-field prior. Compare
it with a non-marginalized `MakeADFun` objective and compare every fixed and
latent AD derivative with central finite differences.

Two deliberately wrong reconstructions must remain detectably different:

1. `phi = sigma^2` instead of `phi = sigma^(-2)`;
2. the exact double-scaling error
   `a_s^wrong = tau_s^2 v_tip,s` under the unchanged unit augmented-field
   prior, instead of `a_s = tau_s v_tip,s`.

An independent covariance check must draw the unit tip field and verify both
the diagonal `tau_s^2` and off-diagonal `tau_s tau_t A_st` entries of
`D_tau A D_tau`.

## Prospective recovery ladder

PR 1 showed that `g = 256` and `g = 512` are informative practical HOLD
boundaries for the latent-SD estimand, while the exact `g = 1024, m = 4` cell
passed. PR 2 therefore preserves, rather than erases, those boundaries and
predeclares a 12-cell information ladder before any PR 2 campaign:

```text
g = {256, 512, 1024}
m = {2, 4}
predictor design = {three distinct species-level predictors; one shared species-level predictor}
```

Suggested truths remain `beta = (0, 0.35)`,
`gamma = (log(0.25), 0.20)`, and
`alpha = (log(0.30), 0.25)`. In the distinct arm, generate three independent
species vectors, centre and scale each within the attempt, and broadcast each
species value to its `m` observations. In the shared arm, generate one centred
and scaled species vector and use it identically in `mu`, family `sigma`, and
log-`tau`, again broadcast within species. Generate predictors independently
of the tree and unit phylogenetic field. Holding predictor grain constant makes
the arm contrast a separation stress test rather than a grain confound, and
centring keeps the three intercept truths defined at `x = 0`.

Run exactly 400 retained attempts per cell, 4,800 fits total. Number cells in
lexicographic order of design (`distinct`, `shared`), `g` (`256`, `512`,
`1024`), and `m` (`2`, `4`). The certification seed for cell `c` and replicate
`r` is the frozen integer

```text
seed(c, r) = 2100000000 - 10000 c - r,  c = 1,...,12; r = 1,...,400.
```

The one-attempt-per-cell smoke uses
`seed_smoke(c) = 2090000000 - 10000 c - 1` and is not evidence. Before every
attempt, set `RNGkind("L'Ecuyer-CMRG", "Inversion", "Rejection")` and then
`set.seed(seed)`. Consume randomness in the frozen order: tree, predictor
vector(s), unit phylogenetic field, then Beta responses in data-row order.
Every stochastic DGP component must come from that attempt seed; no worker,
tree, or response RNG may escape this contract. The runner must prove current
seed uniqueness and zero overlap with all PR 1 and PR 2 smoke seeds before it
can launch.

The launch sequence is one local fit, then the 12-cell retained smoke, then the
full campaign on Totoro with BLAS pinned to one and at most 32 workers. Source
commit, package build, input manifest, seed audit, and retained outputs must be
authenticated before promotion scoring.

The exact promotion cells are the two `g = 1024, m = 4` designs. Each must
reach convergence at least 95%, `pdHess` at least 95%, and contain finite
estimates for all six fixed coefficients in every retained attempt. Every
attempt remains in the denominator: do not filter on convergence, Hessian,
warnings, boundaries, or estimate magnitude. Require absolute mean bias at
most 0.10 separately for `beta_0`, `beta_1`, `gamma_0`, and `gamma_1`. For the
new primary estimands `alpha_0` and `alpha_1`, require the 95% Monte Carlo
interval `mean_error +/- 1.96 * MCSE` to lie wholly inside `[-0.10, 0.10]`.
The `0.10` margin is the predeclared practical tolerance on the log-SD scale;
this Monte Carlo interval quantifies uncertainty in simulation bias and is not
a model interval or coverage claim. Report RMSE and error quantiles for all six
coefficients, plus the fixed-Hessian condition number and estimate correlations
among `beta_1`, `gamma_1`, and `alpha_1` in the shared-predictor cells.

Both `g = 1024, m = 4` designs must pass separately. Either HOLD prevents PR 2
ledger promotion; the designs may never be pooled. The `g = 256/512` cells and
all `m = 2` cells are retained information/stress boundaries regardless of
their outcomes and may not be omitted or silently pooled. PR 2 uses a varying-
SD DGP, so none of its outcomes may rescore, erase, or relabel PR 1's constant-
SD `g = 256/512` HOLDs.
No result licenses a claim for `g >= 1024`, a universal sample-size threshold,
intervals, or coverage. A method-development arc is considered only if an
independent higher-accuracy diagnostic attributes residual bias to the
Laplace approximation rather than finite information.

## Required public-path checks

Before any capability promotion, exercise `coef()`, `predict()` for all three
submodels, `sdpars()`, `summary()`, conditional predictions or `ranef()`, and
profile-target discovery. If a profile target cannot be supported without
widening this PR, reject it explicitly and document that boundary. The final
ledger row, formula grammar, likelihood/design documents, check log, rendered
pkgdown surfaces, and after-task report must all state the same exact
`point_fit_recovery` scope.
