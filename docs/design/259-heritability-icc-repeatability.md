# 259 — `heritability()` / `icc()` / `repeatability()` port (issue #1115)

Status: **implemented, first slice**. Delta-method Wald intervals only;
`method = "profile"` is accepted for signature parity but aborts (not
implemented). Gaussian, homoscedastic-residual, fixed-effect-free-of-the-ratio
fits only (see "Gate" below).

## 1. Symbolic alignment table

Source: `DRM.jl` `src/heritability.jl` at the pinned clone
`drmjl-objat/src/heritability.jl` (366 lines, no separate `icc.jl`/
`repeatability.jl`).

| Quantity | DRM.jl formula (file:line) | drmTMB quantity supplying each term | Scale |
|---|---|---|---|
| `icc()` / `repeatability()` | `ICC = sigma^2_focal / (sigma^2_focal + sigma^2_resid)`, `src/heritability.jl:305-306,312,326-330` | numerator: one entry of `object$sdpars$mu` (an SD, squared); denominator adds the constant residual SD from `drm_constant_residual_sigma(object)` (`R/methods.R:4592-4610`), squared | working log-SD scale; `sigma_k = exp(theta_k)`, `sigma_k^2 = exp(2*theta_k)` |
| `heritability()` | `h2 = sigma^2_focal / (sum_k sigma^2_k + sigma^2_resid)`, `src/heritability.jl:286,328-334` | numerator: same one entry of `object$sdpars$mu`; denominator sums **every** entry of `object$sdpars$mu` plus the constant residual SD, squared | same |
| delta SE / Wald CI | `bias_correct` epsilon-method, `src/heritability.jl:92-118` | numeric central-difference gradient of the ratio w.r.t. the working-scale parameters (`log_sd_mu`/`log_sd_phylo`/`beta_sigma`), quadratic form against the matching block of `object$sdr$cov.fixed` (fetched via `drm_sdreport_cov_fixed()`, `R/methods.R:2394-2402`), Wald interval clamped to `[0, 1]` | working scale in, `[0, 1]` ratio out |

### Where each working-scale parameter lives on the fitted object

- `object$sdpars$mu` (built by `split_tmb_sdpars()`, `R/drmTMB.R:21779`) is a
  named numeric vector of **SDs** (not variances), keyed by the random-effect
  term label. It already merges two different underlying TMB parameters into
  one vector, in this order when both are present:
  1. Ordinary unmodelled `(1 | group)` terms: `exp(par$log_sd_mu[...])`,
     `R/drmTMB.R:21828-21832`.
  2. Structured terms (`phylo(...)`, `animal(...)`, `relmat(...)`,
     `spatial(...)`, `phylo_interaction(...)`) on the closed-form / non-LSS
     path: `exp(par$log_sd_phylo[...])`, `R/drmTMB.R:21917-21929` (the `else`
     branch — the univariate, non-`biv_gaussian`, non-random-scale case).
  Both were verified directly: a two-`(1 | group)` fit produces
  `names(object$opt$par) == c("beta_mu","beta_sigma","log_sd_mu","log_sd_mu")`
  with `object$sdpars$mu` holding two SD entries in the same order (probe run
  2026-09-02, worktree `wt-n2`); a phylo/animal/relmat/spatial fit routes
  through the same `structured$phylo_mu$has` branch and lands in `out$mu` too
  (`R/drmTMB.R:21906,21916,21926`), confirming the "wherever it lives" open
  question from the alignment-inputs scout: **`log_sd_phylo` surfaces inside
  `object$sdpars$mu`** on this path, named with the structured marker text
  (e.g. `"phylo(1 | species, tree = tree)"`), not as a separate list element.
  A term modelled with `sd(group) ~ ...` (location-scale-scale / LSS) is
  routed to a *different*, dpar-named block instead
  (`R/drmTMB.R:21813-21826,21888-21896`) and never appears in `sdpars$mu` —
  so the component locator below excludes those routes structurally, without
  a separate check, matching DRM.jl's explicit rejection of `:sd`/`:sd_phylo`
  blocks (`src/heritability.jl:44-46`).
- Residual SD: `drm_constant_residual_sigma(object)` (`R/methods.R:4592-4610`,
  reused unmodified) returns `exp(beta_sigma)` when `sigma ~ 1`, log link, and
  no known-dispersion override; `NA_real_` otherwise. `beta_sigma` is the
  matching TMB `opt$par` name (verified: a `sigma ~ 1` fit has exactly one
  `"beta_sigma"` entry in `names(object$opt$par)`).
- Parameter **positions** for the delta method: each name in `sdpars$mu` is
  mapped back to its position in `object$opt$par` by counting occurrences —
  names matching a structured-marker prefix
  (`phylo(`/`animal(`/`relmat(`/`spatial(`/`phylo_interaction(`) consume
  `log_sd_phylo` positions in order; all other names consume `log_sd_mu`
  positions in order. This reproduces the assignment order in
  `split_tmb_sdpars()` without depending on internal field names beyond what
  is already public via `object$opt$par` and `object$sdpars$mu`.
  `beta_sigma`'s position is the (single, gate-guaranteed) match of
  `names(object$opt$par) == "beta_sigma"`.
- Covariance source: `drm_sdreport_cov_fixed(object)` (`R/methods.R:2394-2402`)
  — this is `object$sdr$cov.fixed`, indexed by the same `object$opt$par`
  positions used above, and it already aborts with the house-style
  "refit with `se = TRUE`" message when unavailable
  (`drm_has_sdreport_covariance()`, `R/methods.R:2429-2438`). Both `log_sd_mu`/
  `log_sd_phylo`/`beta_sigma` are true TMB fixed parameters (not ADREPORTed
  derived quantities), so `cov.fixed` covers them under both ML and REML —
  verified directly for a REML random-intercept fit (`beta_mu` drops out of
  `opt$par` under REML but `beta_sigma`/`log_sd_mu` remain with a 2x2
  `cov.fixed`).

## 2. Gate

Matches the twin's structured-Gaussian gate (`src/heritability.jl:44-79`):

1. `object$model$model_type == "gaussian"` (univariate only — `biv_gaussian`
   is out of scope here, same as the existing `summary()` derived rows).
2. `drm_constant_residual_sigma(object)` is finite (constant `sigma ~ 1`
   residual, log link, no known-dispersion override).
3. `object$sdpars$mu` has at least one entry (at least one structured/random
   mean component; LSS `sd(group) ~ ...` terms are structurally excluded, see
   above).
4. `method == "delta"`; `method == "profile"` is accepted as an argument but
   aborts naming that it is not implemented yet (`use method = "delta"`).
5. `component` must name one entry of `object$sdpars$mu` when supplied;
   when omitted, there must be exactly one entry, else `cli_abort` names the
   available choices.

Each failure aborts via `cli::cli_abort()` naming the reason, following the
house style already used by `ranef.drmTMB()`/`drm_sdreport_cov_fixed()`.

## 3. Twin differences (recorded, not silently resolved)

1. **Component naming.** DRM.jl selects a component with a bare grouping-
   factor `Symbol` (e.g. `:species`). drmTMB has no such symbol — the stable
   public handle for a structured mean component is the random-effect term
   label already used throughout the package (`"(1 | grp)"`,
   `"phylo(1 | species, tree = tree)"`), so `component` in the R port takes
   that label string instead of a bare grouping-factor name. This is a
   necessary, not cosmetic, deviation: drmTMB does not carry a
   `Dict{Symbol,Int}` component registry the way `DrmFit.blocks` does.
2. **Delta gradient.** DRM.jl differentiates the ratio through ForwardDiff
   (exact AD). This port uses a numeric central-difference gradient over the
   (small, 2-4 element) working-scale parameter subvector, matching the
   `DECISIONS ALREADY TAKEN` note that a numeric gradient is acceptable for
   the first slice. Both compute the same analytic quantity; only the
   differentiation mechanism differs.
3. **`method = "profile"`.** DRM.jl re-optimizes all nuisance parameters at
   each trial ratio and inverts the LRT (`_ratio_profile`,
   `src/heritability.jl:120-220`). drmTMB has no equivalent infrastructure for
   a derived nonlinear ratio target yet (see alignment-inputs open question
   3); the R port accepts `method = "profile"` in its signature for call-site
   parity but aborts rather than silently falling back to delta.
4. **Bias-corrected estimate.** DRM.jl's `bias_correct` also reports a
   bias-corrected point estimate (`corrected`, second-order delta correction)
   alongside the plug-in estimate. This port reports only the plug-in
   estimate; `corrected`/`bias` columns are not populated (documented, not
   silently dropped — a future slice can add them from the same Hessian
   quadrature already computed for the SE).
5. **`summary()`'s existing derived rows are unchanged.** `R/methods.R`'s
   `drm_derived_summary_rows()` (~L4499-4564) already prints rows labelled
   `"repeatability"` and `"phylogenetic_signal"` in `summary()` output, but
   its formula is `re_variance / (total_re_var + residual_variance)` for
   **every** row — i.e. it uses the heritability-style *total*-variance
   denominator even for rows it calls `"repeatability"`. The new `icc()` /
   `repeatability()` accessors follow DRM.jl's *focal-vs-residual* definition
   instead, so they will disagree with the `summary()` row of the same name
   whenever a fit has two or more structured mean components. This is a
   genuine naming collision between the pre-existing `summary()` surface and
   the newly ported accessors, not a bug in either; it is not resolved here
   (see the after-task note's question for the owner: rename one of the two,
   or document the difference in both places). No `summary()` code changed.

## 4. Not covered by this slice

- `method = "profile"` (aborts).
- Non-Gaussian families (Julia itself excludes non-Gaussian Laplace routes
  and the q4 PLSM from this file's scope, `src/heritability.jl:1-27,280-284`).
- Heteroscedastic residual `sigma ~ x` (gated out).
- `sd(group) ~ ...` location-scale-scale mean components (structurally
  excluded — never appear in `sdpars$mu`).
- `biv_gaussian` fits.
- Bias-corrected point estimate (`corrected`/`bias` from `bias_correct`).
- Any coverage claim for the delta-method interval: it is a Wald interval on
  a nonlinear ratio via a numeric-gradient delta method, checked in tests
  only as a small-N sanity pass rate across 5 seeds, not a calibrated
  coverage study.
