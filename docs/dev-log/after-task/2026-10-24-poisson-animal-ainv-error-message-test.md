# After Task: Correct the Poisson animal Ainv bridge expectation

## 1. Goal

Make the R-to-Julia bridge test expect the current guard message after the
bridge admitted both Poisson and Binomial animal-intercept SD models with
`Ainv`.

## 2. Implemented

Updated the negative-path expectation in
`tests/testthat/test-julia-poisson-animal-ainv-sd-parity.R`. The bridge code was
not changed. Its current guard says that `Ainv` is admitted for Poisson or
Binomial animal-intercept SD models.

## 3a. Decisions and Rejected Alternatives

No model or covariance calculation changed. This test checks that the bridge
rejects an animal precision-matrix formula when it lacks the required SD
formula. I changed the stale expectation only. I did not weaken the test or
change the runtime guard.

## 4. Files Touched

- `tests/testthat/test-julia-poisson-animal-ainv-sd-parity.R`: synchronized the
  expected error text.
- This report and the corresponding check-log entry.

## 5. Checks Run

- `devtools::test(filter = "julia-poisson-animal-ainv-sd-parity", reporter = "summary", stop_on_failure = TRUE)` exited 0. One live Julia bridge test ran; testthat reported `DONE` with no failures.
- `git diff --check -- tests/testthat/test-julia-poisson-animal-ainv-sd-parity.R` passed.
- `rg -n "only for a Poisson animal-intercept SD model" tests R docs` returned
  no matches.
- `gh issue list --state open --search 'Poisson animal Ainv SD regression' --json number,title,url --limit 10` returned `[]`.
- `tools/check-after-task.R` reported `after-task structure check passed`. It
  also noted that the wider acceptance ledger is not runnable in this
  environment, so its gate state remains unknown.

The updated test SHA-256 is
`2359553fdfbe39340562ae5feaab9fb45f55a590ad1122a521c9ffcaaf7328c2`; the
unchanged `R/julia-bridge.R` SHA-256 is
`25551cecd5cde337627bb2fff466a905cf565b0443294a9d0bc1b1fcd6c7e03c`. These
hashes identify only the inspected files in this candidate worktree.

## 6. Tests of the Tests

Before the edit, the focused test failed because it expected the old
Poisson-only message. After changing that one expectation, the same focused
test passed with a live Julia bridge. The negative case still verifies that
the bridge rejects `Ainv` when no matching SD formula is supplied.

## 7a. Issue Ledger

The focused search found no open issue for this test-message mismatch; no issue
was opened or changed.

## 8. Consistency Audit

The test message now matches the guard in `R/julia-bridge.R`. The search for
the obsolete Poisson-only wording across `tests`, `R`, and `docs` found no
remaining matches. This test-only repair adds no capability and closes no
programme gate.

## 9. What Did Not Go Smoothly

The registry-based lease claim took longer than expected while other lanes
were active. The test-file claim eventually succeeded, and no competing edit
was found on the two report paths.

## 10. Known Residuals

This repair verifies one error message only. It provides no additional
Poisson, Binomial, or general SD-regression capability and does not validate
interval coverage.

## 11. Team Learning

When a bridge guard expands its admitted family set, update the negative-path
expectation in the same slice and retain the live bridge check. Next, continue
with a required family/effect/backend row after reviewing its implementation
and file ownership. Keep this test result separate from the programme-wide
completion claim.

## 12. Cross-Product Coverage

This test covers the R-to-Julia bridge rejection when a Poisson animal
precision-matrix formula omits its required SD formula. It does NOT cover a
Binomial Ainv fit, other families or effect types, other downstream bridge
surfaces, or interval calibration. The source implementation and public API
were unchanged; no product or package gate closes.

## Prose Assessment

Style: 2/10, medium confidence. Genre/coverage: short technical after-task
report, fully reviewed. Evidence/repair: the purpose, exact test outcome, and
scope limit are named directly; no prose change was needed. Gates: science =
pass for the stated test-only scope; facts = pass against the test output and
source hashes; references = not applicable because no external sources are
cited. Provenance: self-review, draft 1, 2026-10-24; relevant test and guard
were inspected.
