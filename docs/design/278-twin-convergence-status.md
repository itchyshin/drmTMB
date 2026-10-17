# Twin contract: `convergence_status` predicates

## Reader and purpose

For the next drmTMB / DRModels.jl reviewer implementing or checking
`convergence_status()`. Shinichi chose this shared three-valued status on
16 October 2026 (FX3b). The numeric cuts below are the contract: they must
be identical in `R/check.R` and `DRModels.jl/src/convergence_status.jl`.

## Values

`convergence_status()` returns one of `"converged"`, `"boundary"`, or
`"degenerate"` (Julia: `Symbol` `:converged`, `:boundary`, `:degenerate`).

`is_converged(fit)` and `converged(fit)` are the same boolean: they are
`TRUE` exactly when the status is `"converged"`. A boundary MLE is
labelled, not treated as a usable interior optimum. The raw optimiser flag
(`opt$convergence == 0` in R; `fit.converged` in Julia) is a predicate
input, not the public answer.

## Numeric predicates (identical on both engines)

Evaluated in this order. The first matching row wins.

| Step | Predicate | Cut | Status |
| --- | --- | --- | --- |
| 1 | Optimiser gate | integer code `0` (R) / `fit.converged` (Julia) and a finite log-likelihood strictly above the sentinel `-1e15` | else `"degenerate"` |
| 2 | Geometry screen | R: `drm_mle_nonexistent()` (binomial cone; Poisson/NB2 cone with `s = 1{y > 0}`, `ntr = 1 + s`; unbounded location-scale). Julia: the same Poisson/NB2 cone (`_count_mle_existence_guard`) plus the Gaussian all-sigma collapse already in `_nondegenerate_fit`. | `"degenerate"` |
| 3 | Covariance | `vcov` is a square matrix, every entry finite, and positive definite (R: `sdr$pdHess` when SEs were requested; Julia: `isposdef(Symmetric(V))`) | else `"degenerate"` |
| 4 | Finite SEs | every diagonal SE `sqrt(diag(V))` is finite | else `"degenerate"` |
| 5 | Inflated SE | a finite SE is inflated when `SE >= 50` **and** `SE >= 1000 × median(SEs that are < 50)`. If every finite SE is `>= 50`, the reference is `min(SE)` (the min-SE fallback). | `"degenerate"` |
| 6 | Design rank | any fixed-effect block with `qr(X, tol = 1e-8)$rank < ncol(X)` (R). Julia uses the same `1e-8` absolute tolerance on the stored mean design when it is available. | `"degenerate"` |
| 7 | Residual correlation | any fitted `rho12` with `\|rho12\| > 0.98` | `"boundary"` |
| 8 | Random-effect SD | any fitted random-effect SD `< 1e-4` | `"boundary"` |
| 9 | otherwise | interior, identified, finite-SE optimum | `"converged"` |

Constants, named the same way in both packages:

```
rank_tol              = 1e-8
inflated_se_floor     = 50
inflated_se_ratio     = 1000
re_sd_boundary        = 1e-4
rho12_boundary        = 0.98
sentinel_loglik       = -1e15
```

When `drm_control(se = FALSE)` or the stored uncertainty status is
`"skipped"`, steps 3–5 are not applied: a successful optimiser with a
finite log-likelihood is `"converged"` unless a geometry screen already
fired. `is_converged(fit, include_hessian = TRUE)` still requires a
positive-definite Hessian.

Dispersion or shape parameters that run to a limit (NB2 Poisson limit,
Student `ν → ∞`) are classified by steps 3–5, not by a separate shape
boundary. That is the present shared rule; #1535 remains a follow-up if
those cases should read `"boundary"` instead of `"degenerate"`.

## Print, summary, and `check_drm()`

Both engines print `convergence_status` on `print()` / `show()`, store it
on `summary()`, and include it in `check_drm()`. In R the
`convergence_status` row is `ok` / `note` / `warning` for
`"converged"` / `"boundary"` / `"degenerate"`.

## References

Albert and Anderson (1984); Konis (2007); Haberman (1974); Santos Silva
and Tenreyro (2010). Issues: drmTMB #1554, #1333; DRModels.jl #731,
#1109.
