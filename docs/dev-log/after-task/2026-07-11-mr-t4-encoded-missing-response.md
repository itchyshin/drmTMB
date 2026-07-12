# MR-T4 encoded missing-response routes

## Outcome

MR-T4 adds G3 recovery-verified missing-response handling for beta-binomial and
cumulative-logit responses. The board now records 14 verified and four G0
routes. No MR-T5 family was implemented.

## Contracts

A beta-binomial row contributes only when both success and failure counts are
observed. Missing either masks the whole row and its derived trials; coordinated
retapes compare `(success, trials) = (0, 1)` with `(2, 5)`. Missing-denominator
simulation rows return `NA`.

Cumulative-logit masking requires an ordered factor with declared levels. The
TMB guard precedes category conversion/indexing, first- and last-category
sentinels are invariant, and an observed subset with any empty declared
category rejects rather than silently deleting a cutpoint.

## Evidence

- Exact fixed-seed 25% MCAR recovery reuses the 52 x 10 beta-binomial random-
  intercept DGP and the `n = 900` ordinal DGP with their existing tolerances.
- Focused MR-T4, original family, whole missing-response, and combined
  missing-data suites passed; only the existing beta-binomial predictor-model
  optimizer warnings remained.
- Generator checks, six Python tests, and live reconciliation pass at 18 routes,
  14 verified, and four G0.
- `devtools::document()` and the live-source missing-data article build passed.
- `git diff --check` passed.

## Boundary

The ordinal claim is fixed-effect ordered-factor only; the phylogenetic route
is not promoted. Beta-binomial claims only the ordinary `mu` random intercept,
not `sigma` random effects or structured effects. G4/G5 and response plus
`mi()` remain outside this arc.
