# AOI-1 Bernoulli × NB2 public-uncertainty boundary audit

## 1. Goal

Ensure the full fixed-effect Bernoulli × ordinary-NB2 association route remains
point-and-prediction only while AOI-3 uncertainty remains unvalidated.

## 2. Implemented

Added behavioral regression assertions that `vcov()`, `confint()`, and
`profile()` error for a real full-formula Bernoulli × ordinary-NB2 association
fit, alongside the existing `se.fit` rejection test.

## 3a. Decisions and Rejected Alternatives

No uncertainty API was added and no private sandwich result was exposed. The
test targets the public S3 boundary directly rather than treating the existence
of private sandwich helpers as evidence of eligible inference.

## 4. Files Touched

- `tests/testthat/test-associate-pairs-bernoulli-nb2.R`
- `docs/dev-log/after-task/2026-07-31-aoi1-bnb-public-uncertainty-boundary.md`

## 5. Checks Run

- `Rscript -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-associate-pairs-bernoulli-nb2.R")'` — PASS, 79 reported expectations.
- `git diff --check` — PASS.

## 6. Tests of the Tests

The regression invokes each public S3 method on an actual fitted full-formula
object. If any method begins returning a covariance, interval, or profile
instead of its unavailable error, the focused test fails.

## 7a. Issue Ledger

- Missing Bernoulli × ordinary-NB2 public uncertainty assertions — fixed.
- AOI-3 uncertainty validation — deferred; not represented as complete.

## 8. Consistency Audit

The implementation methods still abort unconditionally for all frozen-margin
association objects. Existing association tests already cover unavailable
methods for several other pair classes; this audit fills the exact AOI-1 route.

## 9. What Did Not Go Smoothly

An initial direct `test_file()` invocation loaded an older installed package
rather than this source checkout and produced stale-parser errors. Re-running
after `devtools::load_all(".")` was the valid local test and passed.

## 10. Known Residuals

This proves only the public fail-closed boundary. It does not validate private
multi-parameter covariance, point recovery, intervals, or coverage.

## 11. Team Learning

Memory receipt: the repository association/Lane-B split and AOI-3 HOLD shaped
this audit; the test was run from the loaded worktree rather than the installed
package. Golden Set: not in scope; no release or public capability change was
made.

## 12. Cross-Product Coverage

This audit covers ✓ public uncertainty rejection for the fixed-effect
Bernoulli × ordinary-NB2 association route, including multi-column association
formulae. It does NOT cover ✗ private sandwich validity, local smoke, DRAC,
coverage, other pair classes, random/structured association effects,
missingness, weights, offsets, REML, capability-ledger changes, or a public
association-inference claim.
