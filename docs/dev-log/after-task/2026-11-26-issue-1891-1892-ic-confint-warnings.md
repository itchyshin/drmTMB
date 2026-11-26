# After-task: extractor warnings for non-converged fits (#1891, #1892)

Shinichi (2026-11-26): `logLik` / `AIC` / `BIC` stay finite but warn when `convergence_status()` is not `converged`; Wald `confint()` warns and sets `conf.status = "wald_nonfinite"` when limits are non-finite on a degenerate or boundary fit.

Implementation: `drm_warn_ic_convergence_status()` in `R/methods.R`; Wald non-finite guard in `drm_wald_confint()` in `R/profile.R`. Regression tests mirror issue reproducers.

Claim tag: cursor-cloud-1126fx