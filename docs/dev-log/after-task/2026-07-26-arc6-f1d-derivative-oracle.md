# After-task report — Arc 6 F1D derivative oracle

## 1. Goal

Determine whether the repaired Bernoulli × ordinary-NB2 `a = -4` rectangle has a certifiable full mixed derivative matrix for the private staged sandwich.

## 2. Implemented

Added a test-only local NB2 endpoint oracle, latent-`z` Gauss--Legendre route, centred full-Hessian stencils, a 256/512/1024 node ladder, retained Genz point diagnostics, and an ordered F1D fail-closed taxonomy.

## 3a. Decisions and Rejected Alternatives

Retained K1's point-kernel correction. Rejected treating correct point probability as derivative evidence, production-as-oracle, and loosening the elementwise node contract to manufacture a pass.

## 4. Files Touched

- `tests/testthat/test-associate-pairs-staged-sandwich.R`
- `docs/dev-log/2026-07-26-arc6-f1d-derivative-oracle-ultra-plan.md`
- `docs/dev-log/2026-07-26-arc6-f1d-derivative-oracle-receipt.md`
- This report.

## 5. Checks Run

Focused staged-sandwich tests: 101 passing, 0 failures/skips. Focused Bernoulli-NB2 tests: 113 passing, 0 failures/skips.

## 6. Tests of the Tests

The test proves taxonomy precedence synthetically, requires `statmod` rather than skipping, retains Genz error/message attributes, and checks every node coordinate separately.

## 7a. Issue Ledger

No capability-ledger change. The retained issue is derivative non-certification at `a = -4` and its `a = +4`, `B = 0` mirror.

## 8. Consistency Audit

Plan, test, and receipt agree: interior passes; both tail rows are test-only `independent_step_unstable`; `a = -7` remains production-unavailable; F1/F3 remain closed.

## 9. What Did Not Go Smoothly

Noether found that an initial global-scale node check could mask a small coordinate. The corrected elementwise contract exposed the tail failure.

## 10. Known Residuals

K1's point likelihood is correct at the checked tail, but no certified full derivative oracle exists for the two tail rows. This is negative numerical evidence, not inference evidence.

## 11. Team Learning

Correct rectangle probabilities and broad derivative agreement do not establish a tail derivative contract. Node convergence must be coordinate-wise.

## 12. Cross-Product Coverage

This does NOT cover F3 refits or smoke, F4, interval/SE validity, public APIs, other pair classes, slopes, random effects, missingness, Arc D/F5, or direct `biv_lognormal()` `rho12` inference.
