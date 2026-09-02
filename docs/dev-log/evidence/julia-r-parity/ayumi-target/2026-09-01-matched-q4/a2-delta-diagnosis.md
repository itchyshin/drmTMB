# A2 delta diagnosis — which engine is at the better optimum, and why

Repo/fixture/formula: identical to the matched V2 run (`/private/tmp/drmtmb-control-audit`,
`biv-q4-phylo-reml` fixture, `bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…)`, REML=TRUE, TMB
default control, Julia bridge). Script: `a2-delta-diagnosis.R` (this dir); full output in
`a2-delta-diagnosis-run.log`.

## Step 1 — cross-starting

`drmTMB()` has no `start=`/warm-start argument at all (only `formula, family, data, weights,
control, impute, missing, engine, REML, penalty, estimator, ...`), and `drm_control()`'s own
error message for `optimizer` names it explicitly as unimplemented: *"future start, warm-start,
map, fixed-parameter, and fallback-optimizer controls will use explicit drmTMB arguments after
their contract is implemented."* Cross-starting one engine from the other's solution is **not
feasible through the R surface** — confirmed by reading `R/drmTMB.R:244-256` and
`R/control.R:126-142`, not attempted.

Each engine's own reported objective (step 1b, still done — cheap):
```
TMB  nll (opt$objective) = 219.613986305
logLik(ft) = -219.613986305
logLik(fj, default g_tol) = -219.630231177
ll_delta = -0.0162448722  (TMB logLik is HIGHER, i.e. TMB is at the better optimum)
```

## Step 2 — tighten Julia tolerance (control #1112: `optimizer = list(g_tol = 1e-10)`)

```
Q4_DELTA_DIAG_TIGHT conv_tmb=TRUE conv_julia_tight=TRUE
  logLik_tmb=-219.613986305 logLik_julia_tight=-219.632707864
  ll_delta=0.0187215589 max_coef_delta=0.0158428421 julia_tight_s=6.092 n_common=7
```

Tightening `g_tol` from the route default (this is the q4/sparse-phylo route, whose generic
`g_tol` is silently remapped to `q4_g_tol`, per `R/julia-bridge.R:1137-1139`) to `1e-10` did
**not** shrink the gap — `ll_delta` grew slightly (0.0162 → 0.0187) and `max_coef_delta` grew
slightly too (0.01506 → 0.01584). Both fits report `converged = TRUE`. A tolerance artifact
would show the gap shrinking toward zero as `g_tol` tightens; it did the opposite (noise-level
movement, not convergence toward TMB's optimum).

## Step 3 — convergence diagnostics

**TMB** (`check_drm(ft)`): 18/19 checks `ok`, 1 `note` (interval-reliability scope note, not a
defect), 0 warnings/errors. Key facts: `optimizer_convergence` ok (`nlminb` code 0, "relative
convergence (4)"); `fixed_gradient` ok, max abs fixed gradient `0.00008483` (component
`log_sd_phylo[2]`); `hessian_positive_definite` ok, `sdr$pdHess = TRUE`.

**Julia**: the returned `fj$bridge` object carries no `diagnostic` field and no gradient-norm
field at all — its names are `nobs, bic, family, loglik, iterations, fitted, dpars, corpairs,
coef, converged, vcov, residuals, coef_names, sigma, vcov_names, aic, q4_point_export, df,
coefficients`. `fj$bridge$diagnostic` is `NULL` for both the default-tolerance and the
`g_tol=1e-10` fit — the R bridge does not surface a gradient norm to check against TMB's
`0.00008483`, so a like-for-like gradient-norm comparison is not available through this surface
without deeper (Julia-side) instrumentation, which is out of scope for the 20-minute budget.
`converged=TRUE` is reported by the Julia side but is a solver-internal flag, not a gradient
number.

## Verdict

**Different optimum, not a tolerance artifact.** TMB's reported logLik (−219.613986) is higher
than Julia's at both the route-default tolerance (−219.630231, Δ=0.0162) and at a substantially
tighter `g_tol=1e-10` (−219.632708, Δ=0.0187 — slightly *worse*, not better); TMB's own
diagnostics show a converged, well-behaved fit (positive-definite Hessian, max fixed-gradient
8.5e-5, all `check_drm()` checks passing except a routine interval-reliability note), so the gap
is not a case of TMB looking unreliable either. Since tightening the Julia optimizer's gradient
tolerance by six orders of magnitude did not close (and marginally widened) the gap, the
discrepancy is not caused by the Julia solver stopping early on a loose tolerance — it is
sitting at a genuinely different (and, on the evidence available, slightly worse) point in
parameter space than TMB's optimum for this REML q4 phylo bivariate-Gaussian cell. Root cause
(local optimum vs. identifiability vs. a systematic q4/REML translation difference) is not
distinguishable from this R-side surface alone, since neither cross-starting nor a Julia-side
gradient norm is exposed; that would need Julia-side instrumentation, which is out of the
20-minute bound for this pass.
