# PR #1595 refreshed against current main

## 1. Task goal

Refresh the non-finite `mi()` quadrature guard PR against the current drmTMB main
branch while preserving its change and existing evidence.

## 2. Files changed

The branch now merges current main at `7820315cc904358edbf3635515ebd3a73dbb7f31`.
The generated skip census and C17 current-source pointer were regenerated. A new
C17 receipt, check-log entry, and this report record the refresh. Earlier receipt
folders remain present.

## 3. Checks run

The C17 runner completed 12/12 attempts across `mc-0568`, `mc-0569`, and
`mc-0576`; all three cell summaries matched exactly, with absolute change
`0.000e+00`. The receipt records source SHA
`3e282a88b991559369ad32daea12f0f5c3fe1489` and the current file hashes. The run
lasted 2m05s. Focused `devtools::test()` passed 243 expectations with two existing
labelled skips and no failures or warnings. The census generator reported 902
call sites. Capability ledger checks passed, and 81 ledger unit tests passed.

## 4. Consistency audit

The merged branch keeps the PR's classed non-finite guard and Beta `skip_on_cran()`
change. The regenerated census reflects the merged test files. The C17 ledger
points to the new receipt and records that the `mi()` change is outside its
model-15 anchors. The existing #1532 Gamma-CV and Poisson limitations remain
separate and unchanged.

## 5. Tests of the tests

The three added non-finite guard blocks were previously shown to fail against the
unchanged helper and pass with the guard. This refresh reran the complete MI
quadrature, MI weights, and census files. The two skipped assertions remain the
existing labelled Beta low-mean and Gamma high-CV limitations.

## 6. What did not go smoothly

The current-main merge produced conflicts in the generated C17 pointer table and
environment skip census. The census was regenerated from the merged test tree.
For the C17 runner, the repository's fixed output directory was temporarily moved
aside and restored after the run; the tracked original directory is clean.
The receipt took 24 seconds longer than the measured 1m41s estimate, and completed
without an overrun requiring intervention.

## 7. Team learning

When a PR refresh conflicts in generated records, resolve the source inputs and
rerun the repository generator. Keep prior receipts intact and make the new current
receipt identify the exact merged source.

## 8. Design documentation

No design contract changed. The existing `docs/design/03-likelihoods.md` wording
continues to describe the non-finite guard.

## 9. Package documentation

No pkgdown page or rendered documentation changed. The branch remains open for
CI on its updated exact head.

## 10. GitHub issue maintenance

Issue #1532 remains open for the independently documented Gamma CV and Poisson
limitations. No issue comment or state change was needed for this source refresh.

## 11. Limitations and next action

The full package suite was not rerun. The C17 receipt establishes only the stated
current-source compatibility check, not broader model recovery or interval
coverage. Do not merge the PR until required checks pass on the pushed exact head.
