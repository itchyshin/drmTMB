# Check log — 2026-11-21 — fix #1729 lognormal non-finite design guard

## Change

- `R/drmTMB.R`: call `drm_abort_if_nonfinite_fit_design()` for lognormal `mu` and `sigma` fixed-effect designs (parity with Gaussian / Student-t / skew-normal).

## Verification

- `devtools::test(filter = "fix-1729-lognormal-nonfinite")`