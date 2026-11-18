# 2026-10-20: skew-normal random-intercept SD likelihood oracle

- Focused command: `Rscript -e 'devtools::test(filter = "skew-normal-sd-integration-oracle")'` passed 3 assertions in 4.3 seconds.
- The test compares the fitted Laplace log likelihood with separate per-group adaptive integration over the standard-normal random intercept. The reference uses the existing skew-normal public-moment density helper.
- Reversing the group-SD mapping gives a worse marginal likelihood, providing an indexing negative control.
- Scope: one seeded 48-group, 9-observation-per-group ordinary location-intercept case. The check covers that numerical case only; broader likelihood and interval-coverage validation remain open. Julia parity also remains open.
