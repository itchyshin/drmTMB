# After Task: Bernoulli probit and cloglog correlated q2 SD bridge

## 1. Goal

Verify that selector-specific SD formulas for an ordinary correlated intercept-and-slope block marshal and fit through the R-to-Julia bridge for probit and complementary log-log Bernoulli responses.

## 2. Implemented

No new model code was needed after the q3 serializer change. The existing opt-in q2 bridge test now passes against the paired general-SD Julia candidate for both links. The NEWS, Julia capability inventory, and formula-grammar vignette were updated to state the supported q2 probit/cloglog and q3 probit cells precisely.

## 3a. Decisions and Rejected Alternatives

- Reused the existing synthetic q2 fixtures and candidate; did not add a second near-duplicate test.
- Treated the results as fixture-specific point recovery and cross-engine comparison, not interval evidence.
- Coverage validation remains deferred under the user's direction.
- Assumption: the current admission contract remains one correlated q2 intercept-and-slope block with one selected SD formula per coefficient.

## 4. Files Touched

- `NEWS.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `vignettes/formula-grammar.Rmd`
- `docs/dev-log/check-log.d/2026-10-26-julia-binomial-nonlogit-correlated-q2-sd-bridge.md`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-nonlogit-correlated-q2-sd-bridge-20261026/receipt.md`

## 5. Checks Run

- The opt-in `test-julia-binomial-nonlogit-correlated-sd-bridge.R` test passed one live block covering probit and cloglog. Thirty live expectations passed without warnings, failures, or skips.
- The test used native TMB and the paired DRM.jl general-SD candidate on R 4.6.0 and Julia 1.10.0, with one Julia, BLAS, and OMP thread.
- The prior q3 vignette render used the version before this q2 status sentence was added. The updated vignette requires a fresh render, listed below.

## 6. Tests of the Tests

The fit-free test rejects a missing SD member, mismatched grouping factors, extra blocks, ambiguous targets, and random effects inside an SD predictor. The live q2 test checks known-DGP SD-trend and correlation recovery, same-data TMB comparisons, convergence, and group-specific SD predictions for both links.

## 7a. Issue Ledger

No matching open issue was found in the targeted search during the preceding q3 slice. No issue action was taken here.

## 8. Consistency Audit

The capability inventory and NEWS now report q2 probit and cloglog live checks separately from the q3 probit bridge test. The formula-grammar vignette no longer says all correlated non-logit blocks are unavailable. The q3 warning about a singular Hessian and lack of interval calibration remains explicit. The user-facing README still describes Julia SD routes as development candidates.

## 9. What Did Not Go Smoothly

The earlier q3 route showed that the bridge must use the paired candidate checkout. This q2 test was rerun with that path and completed quickly. The full pkgdown site render remains partial from the preceding q3 closeout.

## 10. Known Residuals

These are two fixed-seed fixtures. They do not establish interval calibration, coverage, general recovery across group counts and sample sizes, q3 cloglog, structured effects, or support in released DRM.jl builds. The q3 fixture still has its documented singular-Hessian warning.

## 11. Team Learning

The q3 serializer change also unlocks q2 coefficient-specific ordinary SD formulas. Run the adjacent q2 test after changing shared formula marshalling, even when q3 is the main target.

## 12. Cross-Product Coverage

The live tests cover Bernoulli probit and cloglog, native TMB and the paired Julia candidate, one ordinary correlated q2 block, coefficient-specific SD targets, and group-SD predictions. They do NOT cover intervals, calibrated uncertainty, coverage, q3 cloglog, structured effects, other families, or released Julia support. This slice does NOT cover those broader cells.

## Next Actions

Render the updated formula-grammar vignette, then select the next Bernoulli random-effect type from the capability inventory and inspect its native and Julia prerequisites.
