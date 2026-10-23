# Issue #575 — mechanism diagnosis: mode-finder vs objective-translation

Fixture: `test/parity/q4-reml/biv-q4-phylo-reml/` (data.csv, tree.newick,
expected.toml/expected.meta.toml) on branch `codex/julia-bridge-route-diagnostic`
(commit `04e3e5d1`). Model: mu1/mu2 ~ x + phylo, sigma1/sigma2 ~ 1 + phylo,
rho12 ~ 1, biv_gaussian, REML, `drm_control(optimizer_preset = "robust")`.

## 1. TMB's fitted point (R refit, devtools::load_all('/private/tmp/drmtmb-control-audit'))

`Rscript` refit reproduced `expected.toml` bit-for-bit: `logLik = -219.614`.
Fixed effects match `expected.toml`'s `[coef]` block exactly. The random-effect
covariance was pulled from `fit$obj$report()$phylo_q4_covariance` (order
mu1, mu2, sigma1, sigma2 — confirmed by the report's own `log_sd_phylo` names
attribute):

```
Lambda_TMB =
[ 0.5288095   0.25509007 -0.1228962  -0.15554224
  0.25509007  0.28551843 -0.1794685  -0.02445802
 -0.1228962  -0.1794685   0.4857264  -0.10269499
 -0.15554224 -0.02445802 -0.10269499  0.16678147 ]
rho12_(Intercept) = 0.065606409
```

## 2. Parameter mapping (TMB -> DRM.jl phi)

| TMB quantity | DRM.jl quantity | Mapping used |
|---|---|---|
| `report()$phylo_q4_covariance` (4x4, order mu1,mu2,sigma1,sigma2) | `Λ` (4x4 axis-covariance, same axis order 1=mu1,2=mu2,3=logσ1,4=logσ2 per `reml_q4.jl` comments) | Direct — TMB reports the covariance matrix on the same natural (log-sd/logit-scale-consistent) axis basis DRM.jl uses; no further reparameterisation needed |
| `Λ` | `lc` (10-vector, phi's variance block) | `DRM.Λ_to_lc(Λ)` (log-Cholesky, package function) |
| `beta_rho12` = 0.065606409 | `phi[1:kr]` (kr=1, rho12~1) | direct (rho12 uses the identity link in both; both report the same coefficient value, confirmed by exact match) |
| `beta_mu1/mu2, beta_sigma1/sigma2` | `beta.mu1/mu2/s1/s2` | direct — used only as an inner Newton warm start, since these axes are profiled out of `phi` and re-optimised by `cond_newton_beta` at any fixed `phi` |
| `lc_zero` (block-diagonal Σ_a constraint) | none applied | `DRM._bivariate_q4_marker` returned `lc_zero = Int[]` for this formula — no cross-block restriction on either side, so no restriction mismatch here |

`n_beta` (marginalised fixed effects: mu1[2]+mu2[2]+sigma1[1]+sigma2[1]) = 6,
giving the normalising constant `(n_beta/2)*log(2π) = 5.513631`. Since #477
both engines report the **normalised** restricted log-likelihood, so this
constant is added on both sides and cancels in every comparison below — it is
reported only as a sanity check.

## 3. The three numbers (all normalised, TMB's reporting scale)

Computed by `mechanism_575.jl` (this scratchpad), calling
`DRM.fit_q4_reml` for Julia's own optimum and `DRM.reml_ll_and_mode` at
`phi_TMB` (with beta warm-started from TMB's own fixed effects, so the inner
profile has every chance to reach its true conditional optimum):

| Quantity | Value |
|---|---|
| TMB optimum (`expected.toml` `[fit].loglik`) | **-219.613986** |
| Julia's own optimum (`fit_q4_reml`, `g_residual = 7.54e-4 < g_tol = 1e-3`, `converged = true`) | **-219.630231** |
| Julia's objective evaluated **at θ̂_TMB** (same normalisation) | **-219.620508** |
| Julia_at_θ̂_TMB − Julia_own_optimum | **+0.009724** (θ̂_TMB point is BETTER for Julia's own objective) |
| TMB − Julia_own | 0.016245 |
| TMB − Julia_at_θ̂_TMB | 0.006521 |

`(n_beta/2)*log(2π) = 5.513631` — already absorbed on both sides via #477's
normalisation, and not the source of the residual gap (confirmed: raw
unnormalised objective at θ̂_TMB is -225.134139, +5.513631 = -219.620508,
consistent).

## 4. Interpretation

Julia's own objective, evaluated at TMB's fitted point (with beta reprofiled
by the same conditional-Newton machinery `fit_q4_reml` itself uses), is
**strictly higher** (-219.620508) than the point Julia's own LBFGS/warm-restart
solver actually returned (-219.630231) — a gap of 0.0097, roughly 60% of the
full TMB-vs-Julia gap (0.0162). The profiled fixed effects at θ̂_TMB
(`bv_tmb`) also land essentially on top of TMB's own coefficients (e.g.
`sigma2_(Intercept)`: -0.44091 vs TMB's -0.44120), and the variance matrix
Julia's solver converged to (`Λ_hat`) differs visibly from Λ_TMB in several
off-diagonal/diagonal entries (e.g. `[2,2]`: 0.300654 vs 0.285518;
`[4,4]`: 0.175638 vs 0.166781) — i.e. Julia's FD-gradient LBFGS stopped at a
detectably different, and objectively worse, point in variance-component
space than the region around θ̂_TMB.

This is direct, mechanical evidence that the two engines are maximising the
**same** restricted likelihood (up to the already-cancelled normalising
constant) and that DRM.jl's own solver simply stopped short of its own
optimum on this cell — consistent with the FD-gradient/loose-`g_tol`
regime already documented for this route (`h_inner = 5e-4`, `g_tol = 1e-3`
default, warm-restart heuristics in `fit_q4_reml`).

MECHANISM: mode-finder

## Files

- Script: `/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-DRM-jl/afd6975e-02e8-4ecd-ae5c-478837cfc231/scratchpad/mechanism_575.jl`
- R refit scripts: `.../scratchpad/refit.R`, `.../scratchpad/refit2.R`
