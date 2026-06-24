# Bridge Route Rejection Messages

Slice S037 hardens the intentional R-to-Julia bridge rejections. The target is
not broader support; it is clearer failure when the R grammar can express a
model that the current Julia bridge does not carry.

## Contract

Each intentional gate should satisfy three conditions:

- the row is listed in `drm_julia_intentional_gates()`;
- the R call errors before `JuliaCall` setup;
- the message includes the registered pattern plus route guidance, such as the
  native `engine = "tmb"` path, a complete-data requirement, a dropped formula,
  or the latent-engine boundary.

The dashboard table `bridge-rejection-messages.tsv` mirrors the gate ids and
marks each message as covered by `tests/testthat/test-julia-gate-vs-engine.R`.

## Boundary

This slice intentionally keeps every row at `intentional_error`. It does not
change which models are routed to Julia, does not add user-selectable optimizer
controls, and does not promote q4, non-Gaussian, cross-family, or structured
bridge inference.
