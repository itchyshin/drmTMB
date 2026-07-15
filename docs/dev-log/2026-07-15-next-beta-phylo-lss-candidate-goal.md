# Queued candidate GOAL: Beta phylogenetic LSS pilot

Status: **QUEUED, NOT ACTIVE**. Ultra-plan this candidate only after the current
relmat-K REML arc is fully closed and separately merged. Do not implement it
until Shinichi approves the new ultra-plan.

## Goal

Deliver one bounded Beta phylogenetic location-scale-scale (LSS) lane in two
small PRs, capped at `point_fit_recovery`, before any broad all-family `sd()`
arc.

```r
fit <- drmTMB(
  bf(
    Male_plumage_prop ~
      1 + Dale_mating_system_z + phylo(1 | spp_id, tree = tree),
    sigma ~ 1 + Dale_mating_system_z,
    sd(spp_id, level = "phylogenetic") ~
      1 + Dale_mating_system_z
  ),
  family = beta(),
  data = data
)
```

The three submodels are distinct. Location models the conditional Beta mean
`mu`. Family scale models drmTMB's public Beta variability parameter `sigma`,
where `phi_i = 1 / sigma_i^2` and
`log(phi_i) = -2 log(sigma_i)`; `sigma` is not literally the conditional
response SD. The `sd(spp_id, level = "phylogenetic")` model controls the
species-specific SD of the phylogenetic **location** effect. It is not a second
phylogenetic random effect in Beta precision.

## Exact symbolic target

For observation `i` in species `s(i)`:

```text
y_i | v_s(i) ~ Beta(mu_i phi_i, (1 - mu_i) phi_i)
logit(mu_i) = beta_0 + beta_1 x_i + a_s(i)
log(sigma_i) = gamma_0 + gamma_1 x_i
phi_i = sigma_i^(-2) = exp{-2(gamma_0 + gamma_1 x_i)}
log(tau_s) = alpha_0 + alpha_1 x_s
v_aug ~ N(0, Q_aug^(-1))
a_s = tau_s v_tip,s
```

Thus `a ~ N(0, D_tau A D_tau)` for unit-diagonal phylogenetic correlation
matrix `A`. The implementation must use a unit-scale augmented phylogenetic
field and multiply observed-tip effects by `tau_s`; internal nodes do not
receive user covariates. Do not estimate a scalar phylogenetic SD and a direct-
SD model simultaneously.

This is not a direct translation of Xi's brms model with separate
phylogenetic effects in `mu` and `phi`. The estimands differ. For coefficient
comparison only, a brms log-`phi` slope `delta` corresponds to drmTMB
`gamma = -delta / 2`, absent all other model differences.

## Two-PR implementation lane

### PR 1: constant-SD Beta phylogenetic location

Publicly admit only univariate `beta()`, ML, one intercept-only
`phylo(1 | spp_id, tree = tree)` term on `mu`, fixed effects in `sigma`, and one
constant phylogenetic SD. Treat this as admission/regression testing over the
existing Beta C++ likelihood, not a new likelihood.

Required evidence: replace the current rejection test with exact admission;
independently verify the leaf likelihood under `phi = 1 / sigma^2`; retain a
wrong-parameterization `phi = sigma^2` sentinel; check fixed-parameter joint
NLL and gradients; run constant-SD recovery; and test extraction/prediction.

### PR 2: direct phylogenetic-SD regression

Implement the exact Beta target
`sd(spp_id, level = "phylogenetic") ~ 1 + x`. Reuse the Gaussian non-centred
direct-SD architecture without generalizing to other families. Implement
intercept-only first, then the slope. The intercept-only direct-SD form must be
likelihood- and estimate-equivalent to PR 1's scalar constant-SD model.

Required evidence: intercept-only parity; exact `D_tau A D_tau` algebra; a
wrong-scaling sentinel; finite-difference gradients; simulated recovery;
`coef()`, `predict(dpar = ...)`, `sdpars()`, `summary()`, and profile-target
handling or explicit documented rejection; and malformed/mismatched-target
tests.

R/TMB remains authoritative. DRM.jl may be an optional comparator for PR 1,
but evidence does not transfer between packages.

## Fail-closed boundary

Reject or defer REML; phylogenetic random effects in `sigma`/`phi`;
phylogenetic slopes or labels; q2/q4 and bivariate models; ordinary random
effects combined with this target; RHS random effects inside `sd()`;
within-species-varying direct-SD predictors; `zero_one_beta()` and beta-binomial;
missing-response/predictor combinations; posterior-tree aggregation; and any
broad claim that `sd()` works for Beta or all families.

## ADEMP and compute

Predeclare 12 cells: `g = {64,256,1024}`, `m = {1,2}`, crossed with distinct
versus shared standardized predictors across `mu`, `sigma`, and `tau`. Run the
distinct-predictor design first; the shared-predictor design is the harder
separation stress test. Suggested truths are
`beta = (0,0.35)`, `gamma = (log(0.25),0.20)`, and
`alpha = (log(0.30),0.25)`.

Subject to a toy benchmark, attempt about 400 replicates per cell (4,800 fits)
on Totoro with at most 32 workers and BLAS threads pinned to one. Use the launch
ladder one fit -> one replicate per cell -> full campaign. Retain every attempt.
For high-information `m=2` cells, provisional point gates are convergence at
least 95%, `pdHess` at least 90%, absolute slope bias at most 0.10 for
`beta_1`, `gamma_1`, and `alpha_1`, and no material RMSE worsening from
`g=256` to `g=1024`. Treat `m=1` as an identifiability/information stress test,
not necessarily a promotion gate. No interval or coverage claim follows.

## Xi external smoke

Use Xi's repository only as an optional `external_real_data_smoke`, pinned to
commit `7d1f4befaddaccdd7c8ef37030c9a648495243f8`. The male+Dale strict-interior
dataset has 3,436 tree-matched species and no exact-zero/one responses. It can
check tree alignment, Beta response handling, runtime, fitting, extraction,
and diagnostics, but not recovery: truth is unknown, there is generally one
male observation per species, and the mating-system categories are imbalanced.

No licence file was found. Do not vendor Xi's CSV, tree, RDS, or a derived
fixture without explicit permission/licensing. Package tests must use
independently simulated data. The repository contains one MCC tree, not the
proposed 50 posterior trees; multi-tree biological analysis remains a later
external application.

## Documentation and closeout

Update formula grammar, the Beta `phi`/`sigma` likelihood documentation, stale
design-document-18 wording about the already parsed `sd(..., level = ...)`
syntax, the exact Beta ledger/Mission Control cells, check log, rejected
neighbours, and after-task report. The maximum claim is
`point_fit_recovery` for the exact univariate Beta ML q1 phylogenetic LSS cell.
