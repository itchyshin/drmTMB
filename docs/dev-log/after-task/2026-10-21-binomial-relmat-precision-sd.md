# After Task: Binomial relatedness precision SD regression

## 1. Goal

Check whether the existing native Binomial `relmat()` SD route handles a
precision matrix with a different node order from the covariance input.

## 2. Implemented

Added a seeded regression test comparing equivalent fits using covariance
`K` and precision `Q = solve(K)`. The precision matrix has a deliberately
permuted order. No model source changed.

## 3. Mathematical Contract

The two fits represent the same latent covariance, `D K D`, with `Q = K^{-1}`
provided through the precision route. The test compares fitted group SDs by
their group labels because each fit returns predictions in its matrix node
order.

## 3a. Decisions and Rejected Alternatives

Keep the existing matrix-node output order and compare values by group name.
Reordering public outputs would risk misalignment with latent-coordinate and
precision indexes, and no documented contract requires factor-level order.

## 4. Files Touched

- `tests/testthat/test-binomial-relmat-precision-sd.R` adds a synthetic recovery and equivalence test.
- `tests/testthat/test-binomial-relmat-sd.R` now aligns returned SD values by group labels instead of assuming factor-level order.
- `docs/dev-log/general-sd-regression/inventory.md` records this evidence cell.
- `.unlazy/general-sd-regression/GATES.md` adds the result to partial G3 evidence.
- `docs/dev-log/check-log.d/2026-10-21-binomial-relmat-precision-sd.md` records the check.
- This report records the test result and limits.

## 5. Checks Run

- Estimated test runtime: about one minute.
- `Rscript --no-init-file -e 'devtools::test(filter = "binomial-relmat-precision-sd|binomial-relmat-sd")'`: 31 assertions passed, with no failures, warnings, or skips, in 31.5 seconds.
- A fit-only smoke check before the test also matched likelihood and SD coefficients. Its first prediction comparison was positional and therefore wrong for differently ordered matrices. Repeating it with name alignment gave a maximum group-SD difference of `6.1e-16`.
- Julia was not exercised.
- `check-after-task.R` passed the report structure check. It warned that the
  acceptance ledger is present but not runnable because its gate-check entry
  point is missing; gate state remains unknown rather than satisfied.

## 6. Tests of the Tests

The first test run failed before fitting because `K` and `Q` were available only
inside the fixture result, while the formula resolves matrix names in the
calling environment. Binding both matrices in the test fixed the setup. The
first combined run exposed three stale assertions in the K-input test that
compared returned values by position. Since structured output follows matrix
node order and carries group names, I changed those assertions to compare by
name. The combined test then passed. An independent API review confirmed that
matrix order is the latent-coordinate order and that extraction preserves it.

## 7. GitHub Issue Maintenance

Open issue searches for Binomial `relmat()` SD regression found no directly
matching issue. The broader simulation-framework issue does not track this
implementation slice, so it was left unchanged.

## 7a. Issue Ledger

No directly matching open issue was found. The broader simulation-framework
issue remains unrelated to this focused test and was not changed.

## 8. Consistency Audit

The tests match the existing `K` and `Q` formula inputs and do not change
kernel scaling. Returned SD vectors preserve matrix node order and carry group
names. The inventory and G3 ledger describe this as one native precision-input
evidence cell. They do not claim Julia parity, broad provider support, or
calibrated intervals.

## 9. What Did Not Go Smoothly

The fixture lookup error was corrected. A separate exploratory comparison
initially compared prediction vectors by position; the matrices return
different node orders, so the comparison was rerun by group name and then
matched to numerical precision.

## 10. Known Residuals

This covers one native Binomial/logit q1 `relmat()` precision-input case. It
does not cover other families, providers, effect shapes, Julia, missing-data
routes, or interval calibration. The full general-SD goal remains open.

## 11. Team Learning

Tests that compare covariance and precision inputs must align all group-level
outputs by matrix labels, not vector position.

## 12. Cross-Product Coverage

This is one native TMB Binomial/logit q1 relatedness-matrix precision-input
cell. It does NOT cover other response families, effect types, endpoints,
providers, engines, missing-data routes, or interval calibration. The wider
family, effect-type, endpoint, provider, and engine cross-product remains open.

## 13. Next Actions

Continue with another unverified required capability cell after refreshing the
ownership map. Keep cross-engine parity and calibrated uncertainty as separate
open requirements.

## 14. Prose Assessment

Style and factual support were reviewed against the test output and source
inventory. `slop_check.py` reported 0 findings across 557 words.
