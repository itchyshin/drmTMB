# Twin contract: `convergence_status` predicates

## Reader and purpose

For the next drmTMB / DRModels.jl reviewer implementing or checking
`convergence_status()`. The original three-valued status (FX3b, 16 October
2026) was extended to four values by the adopted convergence rule below. The numeric cuts must
be identical in `R/check.R` and `DRModels.jl/src/convergence_status.jl`.

## Values

`convergence_status()` returns one of `"converged"`, `"not_converged"`,
`"boundary"`, or `"degenerate"` (Julia: the matching `Symbol`s).

**Converged rule (adopted by Shinichi, SHINICHI-1753-1118, for all four
packages, Heywood folded into boundary).** `converged` means an interior
optimum with usable standard errors: the optimiser finished with a finite
log-likelihood; the gradient is near zero on a relative, unit-free test; no
parameter is at a boundary; the Hessian is positive definite and every
standard error is finite and not inflated. The statuses below are warnings,
never errors. An error is reserved for a fit with no finite likelihood at
all.

`is_converged(fit)` and `converged(fit)` are the same boolean: they are
`TRUE` exactly when the status is `"converged"`. A boundary MLE is a valid
estimate, labelled but not treated as an interior optimum; summaries and
ledgers must filter on status, not drop boundary fits (dropping them biases
variance recovery upward). The raw optimiser flag (`opt$convergence == 0` in
R; `fit.converged` in Julia) is a predicate input, not the public answer.

## Fields

`convergence_info(fit)` (R) returns `converged`, `convergence_status`,
`boundary_params` (a data frame with `name` and `kind`; kinds `"re_sd"`,
`"rho12"`, `"heywood"`, `"temporal"`), `pd_hessian`, `max_gradient`,
`optimizer_code` and `optimizer_message`. `max_gradient` reports the Newton step
in SE units (below), not the raw gradient; it is `NA` when no positive-definite
Hessian is stored. `summary()`
carries the same fields.

## Numeric predicates

Evaluated in this order. The first matching row wins. Boundary is tested
before any Hessian step, so a boundary fit never reads `"degenerate"`.

| Step | Predicate | Cut | Status |
| --- | --- | --- | --- |
| 1 | Optimiser gate | integer code `0` (R) / `fit.converged` (Julia); a finite log-likelihood strictly above the sentinel `-1e15`; Newton step in SE units `max_i \|(H^-1 g)_i\| / SE_i <= 1e-3`, `SE_i = sqrt((H^-1)_ii)` (decided 19 Nov 2026, CONV-GRADIENT-CUT; R, when the gradient and a positive-definite Hessian are stored, otherwise the test is skipped and steps 5-9 screen the fit) | else `"not_converged"` |
| 2 | Residual correlation | any fitted `rho12` with `\|rho12\| > 0.98` | `"boundary"` (kind `rho12`) |
| 3 | Random-effect SD | any fitted random-effect SD, divided by its reference scale, `< 1e-4`. The reference scale is the response SD for identity-link location terms (`mu`, `mu1`, `mu2`) and 1 for link-scale terms, so the cut does not depend on the units of `y` (drmTMB #1751) | `"boundary"` (kind `re_sd`) |
| 4 | Heywood and temporal | residual SD below 1e-3 of the response SD in a temporal model (kind `heywood`); OU decay or AR1 persistence at its limit (kind `temporal`) | `"boundary"` |
| 5 | Geometry screen | R: `drm_mle_nonexistent()` (binomial cone; Poisson/NB2 cone with `s = 1{y > 0}`, `ntr = 1 + s`; unbounded location-scale). Julia: the same Poisson/NB2 cone (`_count_mle_existence_guard`) plus the Gaussian all-sigma collapse already in `_nondegenerate_fit`. | `"degenerate"` |
| 6 | Covariance | `vcov` is a square matrix, every entry finite, and positive definite (R: `sdr$pdHess` when SEs were requested; Julia: `isposdef(Symmetric(V))`) | else `"degenerate"` |
| 7 | Finite SEs | every diagonal SE `sqrt(diag(V))` is finite | else `"degenerate"` |
| 8 | Inflated SE | a finite SE is inflated when, with `SE_i* = SE_i / s_i` (`s_i = sd(y)` for identity-link location coefficients `mu`, `mu1`, `mu2`; `s_i = 1` for link-scale coefficients, so the rule is unit-free under `y -> c y`), `SE* >= 50` **and** `SE* >= 1000 x median(SE* that are < 50)`. If every finite SE* is `>= 50`, the reference is `min(SE*)` (the min-SE fallback). | `"degenerate"` |
| 9 | Design rank | any fixed-effect block with `qr(X, tol = 1e-8)$rank < ncol(X)` (R). Julia uses the same `1e-8` absolute tolerance on the stored mean design when it is available. | `"degenerate"` |
| 10 | otherwise | interior, identified, finite-SE optimum | `"converged"` |

Earlier draft (18 Nov 2026) used an uncalibrated relative gradient with cut 1e-3; replaced by the Newton step in SE units, which is unit-free by construction.

For an R prior fit, the gradient and covariance used for this check belong to
the penalized objective. If either is unavailable, an interior fit is labeled
`"degenerate"`; boundary classification takes precedence. The unpenalized
curvature remains a separate diagnostic. This prior-specific rule requires
separate verification in DRModels.jl.

Previous table (before 18 November 2026): optimiser failure returned
`"degenerate"`, boundary rows came after the Hessian and SE steps (so a
boundary fit with a flat Hessian read `"degenerate"`), the RE-SD cut was an
absolute `1e-4`, and `check_drm()` showed `"boundary"` as a note.

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

For an `engine = "julia"` fit, R applies the same table to what crosses
the bridge. Step 1 reads the bridge `converged` key, which DRModels.jl
sets from `fit.converged`, its non-degeneracy test, and
`fit.geometry === :ok` (DRModels.jl #1129); a `:boundary` fit still sends
`true`. Step 5 reads the bridge `convergence_status` key: the bridge does
not ship `fit.geometry` on its own, so a Julia `"degenerate"` fills the
geometry slot. That string also reflects Julia's steps 6 to 8 on the full
bridge covariance, which includes variance-component coordinates (for
example a log phylogenetic SD) that the R object's fixed-effect `vcov`
drops. Step 9 is not applied. A bridge `"not_converged"` is read as `"not_converged"`, and a bridge `"boundary"` outranks an R-side `"degenerate"`. A DRModels.jl without the key leaves step 5
empty, as before drmTMB #1564. For a bridge fit the response is not stored, so the random-effect SD cut keeps reference scale 1 until DRModels.jl ships the same unit-free rule.

Dispersion or shape parameters that run to a limit (NB2 Poisson limit,
Student `nu -> infinity`) are still classified by the covariance steps (6 to
8), not by a boundary kind. The adopted rule lists "dispersion at its limit"
under boundary; that part is not implemented yet and is tracked in #1535.

## Print, summary, and `check_drm()`

Both engines print `convergence_status` on `print()` / `show()`, store it
on `summary()`, and include it in `check_drm()`. In R the
`convergence_status` row is `ok` for `"converged"` and `warning` for
`"not_converged"`, `"boundary"` and `"degenerate"`.

## References

Albert and Anderson (1984); Konis (2007); Haberman (1974); Santos Silva
and Tenreyro (2010). Issues: drmTMB #1554, #1333; DRModels.jl #731,
#1109.
