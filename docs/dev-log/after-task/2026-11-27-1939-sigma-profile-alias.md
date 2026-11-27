# After-task: #1939 — `parm = "sigma"` profile on `sigma ~ x`

**Reader:** Applied user hitting `confint(..., method = "profile")` after a location-scale Gaussian fit.

**Outcome:** Bare `parm = "sigma"` and `summary(..., ci_parm = "sigma", method = "profile")` now raise `drmTMB_confint_scale_alias_error` with `fixef:sigma:<term>` and `newdata` guidance instead of a misleading unknown-target message. Constant `sigma ~ 1` profiling is unchanged.

**Evidence:** `docs/dev-log/check-log.d/2026-11-27-1939-sigma-profile-alias.md`