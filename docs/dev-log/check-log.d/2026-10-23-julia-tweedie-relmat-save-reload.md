# Julia Tweedie related-matrix SD save/reload

The focused Julia Tweedie related-matrix test passed 39/39 assertions, including new checks for serialization of SD coefficients, kernel-adjusted marginal SDs, and predictions. The paired TMB/Julia bridge test passed 24/24 expectations in 507.4 seconds with the known non-fatal JuliaCall extension warning. The added checks cover one q1 Tweedie related-matrix mean-intercept cell; they do not establish interval calibration or programme-wide parity. See `docs/dev-log/after-task/2026-10-23-julia-tweedie-relmat-save-reload.md`.
