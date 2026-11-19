# After-task: internal response rescaling, first slice (#1751, #936)

Goal: make the log-sigma clamp and optimizer tolerances independent of the units of y.
Done: Gaussian and Student-t, fixed effects plus ordinary `(1 | g)` mean intercepts, default clamp on, sd(y) outside [0.01, 100]: fit on y / sd(y), rebuild the TMB object on the original data at the mapped optimum (clamp off), Hessian mapped from the standardised fit, stored gradient standardised. Code: `R/rescale-response.R`, hooks in `R/drm_fit_spec()`.
Tests: `tests/testthat/test-rescale-response-1751.R` (80 expectations); Gaussian / Student / lognormal / convergence / clamp / check-drm / simulate / residual / location-scale files (6262 expectations) and method / profile / predict / confint / offset / weights files (5184) pass, no moved expectations.
Not covered: every other model shape; lognormal (scale only shifts log y); `is_converged()` still reads two absolute check.R rules (SE floor, RE-SD 1e-4 boundary), owned by #1781.
Next: DRModels.jl #936 flags; widen the slice shape by shape.
