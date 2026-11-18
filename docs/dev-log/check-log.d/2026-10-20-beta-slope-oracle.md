# 2026-10-20: Beta independent-slope SD likelihood oracle

- Focused command: `Rscript -e 'devtools::test(filter = "beta-sd-slope-integration")'` passed 12 assertions (57.4 seconds).
- The test compares the fitted Beta random-slope Laplace log likelihood with independent per-group adaptive integration over the standard-normal slope, using fitted location, residual precision and predictor-dependent SD coefficients.
- Reversing the group-SD mapping worsens the oracle likelihood, providing an indexing negative control.
- Scope: one seeded ordinary Beta location-slope case. The check covers that numerical case only; broader likelihood validation and interval-coverage evidence remain open. Julia parity also remains open.
