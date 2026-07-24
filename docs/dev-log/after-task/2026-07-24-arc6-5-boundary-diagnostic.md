# After Task: Arc 6.5 boundary-seed diagnostic

## 1. Goal

Diagnose the retained Arc 6.5 interior HOLD at seed 650016 without changing the
historical campaign, its denominator, its source receipt, or its capability
boundary.

## 2. Implemented

Replayed the exact deterministic seed at the frozen campaign source and current
merged source, profiled the association link, and compared each profile point
with an independent `mvtnorm` oracle. Added a regression test that requires
the exact seed to remain fail-closed.

## 3. Mathematical Contract

The diagnostic evaluates the existing frozen-margin Bernoulli x Bernoulli
latent-normal rectangle likelihood. It retains the scientific transform
`eta = tanh(alpha)` and treats the implementation guard as numerical only. It
does not change the staged estimand or turn `eta` into joint-model `rho12`.

## 3a. Decisions and Rejected Alternatives

The observed `(y_1 = 1, y_2 = 0)` response cell is empty, and the profile is
flat toward the positive boundary. Therefore no numerical repair, optimizer
change, sample-size-floor change, campaign top-up, or reclassification was
made. Those would answer a different question after seeing the result.

## 4. Files Touched

- `tests/testthat/test-associate-pairs-bernoulli-bernoulli.R`
- `docs/dev-log/2026-07-24-arc6-5-boundary-diagnostic.md`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

- Frozen source `51647467` and current source `01818cfc` both replayed seed
  650016 as `boundary_unresolved` with identical link, likelihood, score,
  curvature, and multistart disagreement.
- Production and independent `mvtnorm::pmvnorm()` likelihoods agree throughout
  the fitted plateau.
- `devtools::test(filter = "associate-pairs-bernoulli-bernoulli", reporter =
  "stop")`: PASS.
- `git diff --check`: PASS.

## 6. Tests of the Tests

The regression test rebuilds the exact historical data from seed 650016,
fits both frozen Bernoulli margins, and asserts the withheld status, missing
estimate, multistart disagreement, finite optimizer diagnostics, and the four
response-pattern counts. This checks the failure mode rather than merely
checking that a fit returns.

## 7a. Issue Ledger

No issue, PR, remote campaign, or historical artifact was changed. The
diagnostic confirms the existing HOLD rather than creating a new capability
claim.

## 8. Consistency Audit

The stored campaign row, deterministic replay, response table, likelihood
profile, independent oracle, test, check-log entry, and diagnostic report all
support the same conclusion: weak/boundary identification, not a numerical
integration defect. `eta` remains distinct from `rho12`.

## 9. What Did Not Go Smoothly

The first test compared a table with dimnames to an unnamed matrix. The values
were correct; the assertion was revised to compare the ordered four counts.

## 10. Known Residuals

Arc 6.5 remains HOLD. This diagnostic does not establish recovery, inference,
intervals, coverage, random effects, generic pair support, Julia, or CRAN
readiness. The retained 220-attempt Totoro receipt remains the only recovery
evidence.

## 11. Team Learning

An unresolved fit should be separated into numerical failure and data geometry
before a repair is proposed. An independent profile oracle made that distinction
possible here and prevented an unnecessary campaign or estimator change.

## 12. Cross-Product Coverage

Only the exact literal-Bernoulli, fixed-effect, complete-pair,
intercept-only seed was diagnosed. This diagnostic does NOT cover other
prevalences, sample sizes, pair classes, covariate-dependent associations,
direct bivariate `rho12` models, REML, random effects, missing data,
aggregation, Julia, or CRAN.
