# PR 1 symbolic alignment: Beta q1 phylogenetic location

**Frozen:** 2026-07-16, before the recovery campaign  
**Base:** `b8aa6d701389aad617a4ad8203bdfa3dc1f01495`  
**Scope:** ML, univariate `beta()`, one unlabelled intercept-only `phylo(1 | spp_id, tree = tree)` location term, fixed-effect `sigma`, and a constant latent phylogenetic SD  
**Claim ceiling:** `point_fit_recovery`

This PR admits a prerequisite only; it does not admit direct-SD regression.

## Accepted formula

```r
drmTMB(
  bf(y ~ 1 + x + phylo(1 | spp_id, tree = tree), sigma ~ 1 + x),
  family = beta(), data = dat
)
```

`REML = TRUE`, labels, phylogenetic slopes, phylogeny in `sigma`, direct-SD formulas, ordinary random effects, missing-data routes, `zero_one_beta()`, and all non-Beta families remain rejected or deferred.

## Symbolic model

For observation `i` in species `s(i)`, `x_i` is an observation-level predictor, `A` is the unit-diagonal tip covariance from the tree, and `v` is a unit-scale augmented phylogenetic field:

```text
y_i | v ~ Beta(mu_i phi_i, (1 - mu_i) phi_i)
logit(mu_i) = beta_0 + beta_1 x_i + a_s(i)
log(sigma_i) = gamma_0 + gamma_1 x_i
phi_i = sigma_i^(-2) = exp{-2(gamma_0 + gamma_1 x_i)}
a_s = tau v_s,  v_aug ~ N(0, Q_aug^(-1)),  tau = exp(lambda)
a_tip ~ N(0, tau^2 A)
```

The public family parameter `sigma` is not the conditional response SD. The latent `tau` is the SD of the phylogenetic **location** effect; it is neither a Beta precision effect nor a second phylogenetic random effect.

## Alignment table

| Symbol | Formula / DGP | TMB representation | Public target | Status |
| --- | --- | --- | --- | --- |
| beta | fixed `mu` intercept and `x` slope | `beta_mu`, `X_mu` | `coef(fit, "mu")` | recovery target |
| gamma | fixed `sigma` intercept and `x` slope | `beta_sigma`, `X_sigma` | `coef(fit, "sigma")` | recovery target |
| phi_i | `sigma_i^(-2)` | `exp(-2 * log_sigma)` | `fit$obj$report()$phi` | likelihood sentinel |
| v_aug | unit augmented phylogenetic field | `u_phylo`, `Q_phylo`, `log_det_Q_phylo` | conditional `ranef()` / prediction contribution | latent nuisance field |
| tau | constant location SD | `exp(log_sd_phylo)` | `sdpars(fit)$mu` | recovery target |
| a_s | `tau v_s` at observed tips | `u_phylo[phylo_mu_node_index]` | conditional `predict(..., dpar = "mu", type = "link")` | extraction check |

The R builder passes the phylogenetic marker through `build_structured_mu_structure()`. Existing Beta C++ adds the field only to `eta_mu`, gives it the scalar augmented-GMRF prior, and separately forms `phi = exp(-2 * log_sigma)`. PR 1 is therefore a narrow R admission and evidence change, not a likelihood rewrite.

## Independent fixed-parameter contract

At a displaced full parameter vector, reconstruct the joint NLL from the Beta `dbeta()` terms and the augmented-field prior `0.5 * [n_aug log(2 pi) + 2 n_aug lambda - log|Q_aug| + exp(-2 lambda) v_aug' Q_aug v_aug]`. Compare it with a non-marginalized `MakeADFun` objective, and compare every AD derivative with a central finite difference at that same displaced vector. A leaf-only `dbeta()` check verifies `phi = sigma^(-2)`; `phi = sigma^2` must give a materially different likelihood.

## DGP and retained rejection boundary

Use `beta = c(0, 0.35)`, `gamma = c(log(0.25), 0.20)`, and `tau = 0.30`; draw tips as `tau * t(chol(A)) %*% z`. The standardized predictor is independent of the tree and enters both fixed-effect submodels. PR 1 has no direct-SD predictor.

Keep labelled/sloped phylogeny, phylogeny on `sigma`, simultaneous ordinary `mu` random effects, structured `mu` plus `animal()` on `sigma`, direct-SD syntax, missing-response/predictor combinations, and `zero_one_beta()` closed.

Passing this contract and the recovery campaign supports only the exact PR 1 ML q1 location cell at `point_fit_recovery`: never intervals, coverage, `inference_ready`, `supported`, direct-SD, or broad family-level language.
