# MR-T5 truncated-NB2 missing responses

## Outcome

MR-T5 adds G3 recovery-verified missing-response handling for the non-hurdle
`truncated_nbinom2()` route. The generated board now records 15 verified and
three G0 routes. Hurdle and zero-inflated mixtures remain MR-T6 work.

## Contract

Missing positive-count responses remain in the model matrices with sentinel
value 1. Starts and response validation use observed counts only. A plain
data-time TMB guard skips the NB2 density and the zero-truncation normalization
together, while fitted positive-count means and distributional predictions
remain full length. Response and Pearson residuals are `NA` on masked rows.

The shared truncated/hurdle builder rejects `response = "include"` whenever a
`hu` formula is present, so the base-family tick does not admit MR-T6 early.

## Evidence

- Direct retapes compare positive sentinels 1 and 7 at objective/gradient
  tolerance `1e-8` and reoptimized parameter/log-likelihood tolerance `1e-6`.
- Exact fixed-seed 25% within-group MCAR reuses the 34 groups x 8 observations
  random-intercept DGP and its existing recovery tolerances for `mu`, `sigma`,
  the ordinary `mu` random-intercept SD, and random-effect correlation.
- The focused MR-T5 suite passed 49 assertions. The combined missing-data suite
  passed 1,148 assertions in 29.1 seconds with two existing beta-binomial
  optimizer warnings and four existing skips.
- Six generator unit tests, deterministic generation, and live runtime
  reconciliation pass at 18 routes, 15 verified, and three G0.
- `devtools::document()` and the live-source missing-data article render pass.
- Independent likelihood and contract review returned DONE with no blocker.

## Boundary

This evidence does not promote hurdle NB2, zero-inflated counts, `sigma` random
effects, structured effects, response plus `mi()`, REML, intervals, or coverage.
G4/G5 remain outside the missing-response arc.
