# After task: engine = "julia" offset() refusal (#1572)

Reader: a drmTMB user who passes `offset()` with `engine = "julia"`.

- Problem: the bridge cannot express a fixed (non-estimated) coefficient, so
  DRM.jl rejected `offset()` with a Julia `ArgumentError` after Julia started.
- Fix: `drm_julia_refuse_offset_unsupported()` in `R/julia-bridge.R` refuses
  every `offset()` in any dpar formula in R, before any Julia setup, with class
  `drmTMB_julia_offset_unsupported` and a next step (`engine = "tmb"`).
- Tests: `tests/testthat/test-julia-offset-refusal.R` (refusal class and message;
  native log-2 intercept-shift identity on `engine = "tmb"`).
- Not done: passing offsets through to DRM.jl. That needs a fixed-coefficient
  payload in the bridge and DRModels.jl work; issue stays a refusal. Refs #1572.
