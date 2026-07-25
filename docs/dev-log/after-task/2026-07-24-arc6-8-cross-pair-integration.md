# After Task: Arc 6.8 cross-pair integration gate

## 1. Goal

Verify that the admitted Arc 6 post-fit latent-normal pairs share one honest
object contract without converting exact-special `rho12` models into `eta`
models or altering the Arc 6.5 recovery HOLD.

## 2. Implemented

Added one five-row integration matrix for Gaussian×Bernoulli, Gaussian×NB2,
Bernoulli×Bernoulli, Bernoulli×NB2, and NB2×NB2. It constructs each pair in
both orders and checks frozen margins, symmetric likelihood/association,
response-labelled extractors, deterministic simulation, and common fences.

## 3. Mathematical Contract

Every matrix row retains the pair-specific likelihood established in its
individual Arc. The common estimand is latent-normal `eta` conditional on
frozen margins. Exact `biv_lognormal()` remains a separate likelihood with
rowwise residual `rho12`; it has no `association()` extractor.

## 3a. Decisions and Rejected Alternatives

The integration layer is a test-only contract gate, not a common likelihood
engine. It does not refactor `associate_pairs()` into exact-special models,
replace `rho12` with `eta`, or rescore the failed Arc 6.5 recovery cell.

## 4. Files Touched

- `tests/testthat/test-associate-pairs-arc6-integration.R`.
- Design 238, the Arc 6 overview, check log, and this report.

## 5. Checks Run

- Arc 6.8 integration test: 62 pass, 0 fail/warn/skip.
- The complete focused Arc 6 suite and hosted CI remain required before merge.

## 6. Tests of the Tests

The test deliberately reverses each input pair, compares frozen snapshot
coefficients against standalone margins, sets a deterministic seed twice, and
calls each unsupported method rather than merely checking object fields.

## 7a. Issue Ledger

No overlapping issue was changed. Arc 6.8 is a bounded integration closeout,
not a new capability or research claim.

## 8. Consistency Audit

The Arc 6 overview now calls 6.8 a source integration gate and retains the
individual limits for all pair classes. Exact-special docs continue to use
`rho12`; post-fit docs continue to use `eta`.

## 9. What Did Not Go Smoothly

The first test compared `fitted()` names with internal margin-list labels
rather than response-variable names and treated the vector-valued exact
`rho12()` extraction as scalar. Both assertions were corrected; no model code
changed.

## 10. Known Residuals

This source gate does NOT cover recovery, intervals, coverage, standard
errors, association slopes, random/structured effects, generic discrete pairs,
missingness, weights, offsets, REML, Julia, CRAN, or a new direct kernel. Arc
6.5 remains HOLD from its retained all-attempt recovery evidence.

## 11. Team Learning

A common interface is credible only when it preserves response names and fails
in the same explicit ways across pair classes. Exact-special models need a
negative integration check so a shared word such as “correlation” cannot erase
their different estimand.

## 12. Cross-Product Coverage

The matrix covers all five admitted post-fit pair classes and the boundary to
one exact-special lognormal model. It does NOT cover Student-t extraction,
new family combinations, inference, random-effect providers, missing data,
REML, or any public capability tier.
