# Student SD oracle check, 2026-10-18

`tests/testthat/test-student-sd-integration.R` now compares the fitted Student-t
random-intercept Laplace log likelihood with a separate one-dimensional group
integration calculation. Reversing the group-to-SD-predictor mapping changes the
oracle value, checking that it uses the group-level predictor labels. The
focused test passed with 15 expectations. This is likelihood and workflow
evidence, not interval calibration.
