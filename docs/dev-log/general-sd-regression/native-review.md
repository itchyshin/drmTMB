# Native SD-regression review

Independent read-only review of the native Bernoulli random-intercept SD-regression slice and its pilot harness. This review excludes `tests/testthat/test-binomial-sd-profile.R`, which I authored in an earlier task. No fits or tests were run for this review.

## Findings

The earlier clamp-diagnostic blocker is resolved. `drm_active_logsigma_clamp_fields()` adds the reported latent group-scale predictor when the fitted model has a direct SD submodel, and the new empty-selection guard in `drm_logsigma_clamp_active()` returns `NULL` for reports that do not contain selected fields. The default field selection remains residual-scale-only, so residual-sigma accessors do not treat a latent SD as residual sigma. Fit warnings and `check_drm()` distinguish the latent-SD case in their messages and severity. The clamp tests cover empty reports, residual-only selection, upper/lower latent bounds, no-SD binomial models, start values, and frozen-optimum reporting.

The pilot now binds its record to the R/C++ implementation, profile code, fixture, design, runner, loaded DLL, package version, and installed R database files. It explicitly requests a 95% profile interval and retains endpoints, status, boundary/message fields, validity, health diagnostics, warnings, errors, and timing. The independent scalar calculation is a hard `1e-6` objective-agreement gate; it is correctly framed as an independent Laplace implementation check, not an exact marginal-likelihood oracle. Calibration remains open.

One small receipt ambiguity remains: `profile_failures` excludes status `not_attempted`, but a thrown error during `confint()` leaves that initial status unchanged. The generic `errors` count preserves the event, and `valid_interval` remains false, so the all-attempt denominator is not silently lost. To make the profile-failure subtotal accurate, record the failure stage or set a distinct profile-error status when the profile call throws. This is a reporting fix, not a blocker for the bounded native slice.

## Scope and limits

The reviewed native slice is ordinary binomial random-intercept SD regression, with the current supported link/trial paths and its methods integration. This review does not certify every response-family, latent-endpoint, provider, dimension, or engine combination in the broader programme. It does not assess the broader recovery/calibration campaign, and does not claim profile interval coverage. The native slice is acceptable for continued bounded validation once the parent’s compiled checks pass; programme completion remains gated on the planned calibration and reconciliation evidence.
