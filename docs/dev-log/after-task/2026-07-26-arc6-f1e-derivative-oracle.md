# After-task report — Arc 6 F1E derivative-oracle redesign

## 1. Goal

Determine, privately and test-only, whether independent analytic
moving-endpoint derivatives can adjudicate the fixed-effect complete-pair
Bernoulli x ordinary-NB2 staged-alpha negative tail without reusing the
production finite-difference ladder.

## 2. Implemented

Added an independent CDF-scale conditional-normal oracle to the focused staged
sandwich test harness. It includes analytic NB2 CDF endpoint derivatives,
Leibniz first/second derivatives, a 512/1024/2048 Gauss--Legendre ladder,
coordinate-wise production comparisons, and a fail-closed test-only taxonomy.

## 3a. Decisions and Rejected Alternatives

The bounded NB2 CDF scale was retained. A guard-only workaround, clipping,
tolerance relaxation, production-helper reuse, and numerical differentiation
through the production ladder were rejected. F1D is retained as negative
evidence; F1E does not relabel it.

## 4. Files Touched

- `tests/testthat/test-associate-pairs-staged-sandwich.R`
- `docs/dev-log/2026-07-26-arc6-f1e-derivative-oracle-receipt.md`
- `docs/dev-log/after-task/2026-07-26-arc6-f1e-derivative-oracle.md`
- `docs/dev-log/plan-actual/2026-07-26-arc6-f1e-derivative-oracle.md`

## 5. Checks Run

Ran the package-aware focused staged-sandwich test using `devtools::test()`.
It passed. Direct-file and bare `test_dir()` attempts were rejected as invalid
for this repository because they do not load the package test helper; their
missing-object errors were not treated as F1E results. `git diff --check` was
also clean.

## 6. Tests of the Tests

The suite checks finite NB2 CDF values against `pnbinom`, keeps the zero lower
endpoint at minus infinity, exercises each normal/tail fixture through two
adjacent node comparisons, independently checks the `a = -4` point against
Genz, retains `a = -7` as unavailable, and deliberately exercises an endpoint
unresolved status. The final taxonomy test checks every precedence branch.

## 7a. Issue Ledger

No issue, capability-ledger, or public status was changed. F1D remains a
negative deterministic result. F1E supplies only a potential input to a future
fresh F1 review.

## 8. Consistency Audit

Only a private test file and private development records changed. No production
kernel, runtime status, public API, documentation, `vcov()`, `confint()`,
profile route, capability ledger, Arc D/F5, or direct-rho route changed.

## 9. What Did Not Go Smoothly

The first two direct test invocations omitted this package's helper/namespace
loading and therefore produced missing-object errors. The package-aware runner
was used instead. Fisher also caught a status-assembly flaw that would have
collapsed independent failures into production instability; it was repaired
before the final review.

## 10. Known Residuals

The evidence is deterministic and test-only. It does not establish sandwich
SE validity, interval validity, recovery, coverage, F1 completion, F3
eligibility, or public readiness. The `a = -7` fixture remains unavailable.

## 11. Team Learning

For tail rectangles, point agreement is insufficient: an independent
derivative route must separately establish endpoint sensitivity and retain the
source of every failure. A suite-level readiness label is meaningful only if
it preserves production, oracle, and route-disagreement causes.

## 12. Cross-Product Coverage

No cross-product transfer is claimed. This result applies only to the exact
fixed-effect, complete-pair Bernoulli x ordinary-NB2 intercept-only staged
association candidate and does NOT cover REML, penalty paths, alternate
engines, missing data, aggregation, other pair adapters, association slopes,
random effects, public inference, or direct `rho12`.
